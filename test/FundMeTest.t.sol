// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FundMe } from "../src/FundMe.sol";
import { Test } from "forge-std/Test.sol";
import { DeployFundMe } from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
  FundMe fundMe;
  address USER = makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;

  function setUp() external {
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER, STARTING_BALANCE);
  }

  function testMinimumDollarIsFive() public {
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  function testOwnerIsMsgSender() public {
    assertEq(fundMe.getOwner(), msg.sender);
  }

  function testPriceFeedIsAccurate() public {
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
  }

  function testFundFailsWithoutEnoughETH() public {
    vm.expectRevert();
    fundMe.fund/*{value: } */(); // sending 0 value
  }

  function testFundUpdatesFundedDataStructure() public {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();

    uint256 amountFunded = fundMe.getAddresstoAmountFunded(USER);
    assertEq(amountFunded, SEND_VALUE);
  }

  function testAddsFunderToArrayOfFunders() public {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    address funder = fundMe.getFunder(0);

    assertEq(funder, USER);
  }


  modifier funded() {
    // https://twitter.com/PaulRBerg/status/1682346315806539776
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    _;
  }

  function testOnlyOwnerCanWithdraw() public funded {
    /* *replaced by funded modifier* */
    // vm.prank(USER);
    // fundMe.fund{value: SEND_VALUE}();

    vm.prank(USER);
    vm.expectRevert();
    fundMe.withdraw();
  }

  function testWithdrawWithASingleFunder() public funded {
    // Arrange-Act-Assert approach for testing

    // Arrange (setup the test)
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();

    // Assert
    uint256 finalOwnerBalance = fundMe.getOwner().balance;
    uint256 finalFundMeBalance = address(fundMe).balance;
    assertEq(finalFundMeBalance, 0);
    assertEq(startingFundMeBalance + startingOwnerBalance, finalOwnerBalance);
  }

  function testWithdrawWithMultipleFunders() external funded {

    // Arrange
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;

    for (uint160 i=startingFunderIndex; i<numberOfFunders; i++) {
      hoax(address(i), SEND_VALUE); // vm.prank + vm.deal
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();

    // Assert
    assertEq(address(fundMe).balance, 0);
    assertEq(fundMe.getOwner().balance, startingOwnerBalance + startingFundMeBalance);
  }

  function testWithdrawWithMultipleFundersCheaper() external funded {

    // Arrange
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;

    for (uint160 i=startingFunderIndex; i<numberOfFunders; i++) {
      hoax(address(i), SEND_VALUE); // vm.prank + vm.deal
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.prank(fundMe.getOwner());
    fundMe.withdrawCheaper();

    // Assert
    assertEq(address(fundMe).balance, 0);
    assertEq(fundMe.getOwner().balance, startingOwnerBalance + startingFundMeBalance);
  }



}