// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AdvancedFinancialPlatform.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*

███████╗██╗   ██╗███████╗███████╗███████╗
██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝
█████╗  ██║   ██║█████╗  ███████╗███████╗
██╔══╝  ██║   ██║██╔══╝  ╚════██║╚════██║
███████╗╚██████╔╝███████╗███████║███████║
╚══════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝

*/

// AdvancedFinancialPlatformFuzzTest.sol
//
// This file contains comprehensive fuzz tests for the AdvancedFinancialPlatform to ensure robustness and correctness under a wide range of inputs.

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1e24); // Mint 1 million tokens with 18 decimals
    }
}

contract AdvancedFinancialPlatformFuzzTest is Test {
    AdvancedFinancialPlatform financialPlatform;
    MockToken stableCoin;
    MockToken rewardToken;
    MockToken collateralToken;

    address owner = address(0x1234);
    address user1 = address(0x5678);
    address user2 = address(0x9abc);

    event LogRevert(string reason);
    event LogGovernanceActionSuccess(address target, bytes data);
    event LogZeroInterest(uint256 amount, uint256 rate, uint256 timeElapsed, uint256 compoundingPeriods);


    function setUp() public {
        stableCoin = new MockToken("Stable Coin", "STC");
        rewardToken = new MockToken("Reward Token", "RWD");
        collateralToken = new MockToken("Collateral Token", "COL");

        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = owner;
        executors[0] = owner;

        vm.startPrank(owner);
        financialPlatform = new AdvancedFinancialPlatform(
            stableCoin,
            rewardToken,
            collateralToken,
            proposers,
            executors
        );
        financialPlatform.transferOwnership(owner);
        vm.stopPrank();

        stableCoin.transfer(user1, 1e22); // Transfer 10,000 tokens to user1
        stableCoin.transfer(user2, 1e22); // Transfer 10,000 tokens to user2
        rewardToken.transfer(owner, 1e22);  // Transfer 10,000 tokens to owner for rewards
        collateralToken.transfer(user1, 1e22); // Transfer 10,000 tokens to user1
        collateralToken.transfer(user2, 1e22); // Transfer 10,000 tokens to user2

        // Transfer sufficient stableCoins to the financialPlatform contract to allow loans
        stableCoin.transfer(address(financialPlatform), 5e23); // Transfer 500,000 tokens to the contract

        vm.startPrank(user1);
        stableCoin.approve(address(financialPlatform), type(uint256).max);
        collateralToken.approve(address(financialPlatform), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        stableCoin.approve(address(financialPlatform), type(uint256).max);
        collateralToken.approve(address(financialPlatform), type(uint256).max);
        vm.stopPrank();
    }


    function testFuzzTakeLoan(uint256 loanAmount, uint256 collateralAmount, uint256 interestRate) public {
        loanAmount = bound(loanAmount, 1, 1e20);
        collateralAmount = bound(collateralAmount, 1, 1e20);
        interestRate = bound(interestRate, 1, 1e18);

        // Ensure totalLent is greater than zero before performing the fuzz test
        vm.startPrank(user1);
        financialPlatform.depositCollateral(1);
        financialPlatform.takeLoan(1, 1, 1);
        vm.stopPrank();

        vm.startPrank(user1);
        financialPlatform.depositCollateral(collateralAmount);
        financialPlatform.takeLoan(loanAmount, collateralAmount, interestRate);
        vm.stopPrank();

        (uint256 loanedAmount,,,,) = financialPlatform.getLoanDetails(user1);
        assertEq(loanedAmount, loanAmount, "Loan amount mismatch");
    }


    function testFuzzRepayLoan(uint256 loanAmount, uint256 collateralAmount, uint256 interestRate, uint256 repayAmount) public {

        loanAmount = bound(loanAmount, 1, 1e20);
        collateralAmount = bound(collateralAmount, 1, 1e20);
        interestRate = bound(interestRate, 1, 1e18);
        repayAmount = bound(repayAmount, 1, loanAmount);

        vm.startPrank(user1);
        collateralToken.approve(address(financialPlatform), type(uint256).max);
        stableCoin.approve(address(financialPlatform), type(uint256).max);
        financialPlatform.depositCollateral(collateralAmount);
        financialPlatform.takeLoan(loanAmount, collateralAmount, interestRate);

        uint256 interest = MathLibrary.calculateComplexInterest(loanAmount, interestRate, 1, 12);
        uint256 totalRepayment = repayAmount + interest;
        stableCoin.approve(address(financialPlatform), totalRepayment);

        financialPlatform.repayLoan(repayAmount);
        vm.stopPrank();

        (uint256 remainingLoan,,,,) = financialPlatform.getLoanDetails(user1);
        uint256 expectedRemainingLoan = loanAmount > repayAmount ? loanAmount - repayAmount : 0;
        assertEq(remainingLoan, expectedRemainingLoan, "Remaining loan amount mismatch");
    }

    function testFuzzCalculateInterest(uint256 amount, uint256 rate, uint256 timeElapsed, uint256 compoundingPeriods) public {
        amount = bound(amount, 1, 1e22);
        rate = bound(rate, 1, 1e18);
        timeElapsed = bound(timeElapsed, 1, 365 days);
        compoundingPeriods = bound(compoundingPeriods, 1, 365);

        uint256 interest = MathLibrary.calculateComplexInterest(amount, rate, timeElapsed, compoundingPeriods);

        if (interest == 0) {
            emit LogZeroInterest(amount, rate, timeElapsed, compoundingPeriods);
            assertTrue(false, "Calculated interest is zero, indicating a potential precision vulnerability");
        } else {
            assertGt(interest, 0, "Calculated interest is zero");
        }
    }


    function testPrecisionLoss(uint256 principal, uint256 rate, uint256 timeElapsed, uint256 compoundingPeriods) public {
        principal = bound(principal, 1e18, 1e22); // 1 to 10,000 tokens with 18 decimals
        rate = bound(rate, 1, 1e18); // 0 to 100% interest rate
        timeElapsed = bound(timeElapsed, 1, 365 days); // 1 day to 1 year
        compoundingPeriods = bound(compoundingPeriods, 1, 365); // 1 to 365 compounding periods

        uint256 expectedInterest = (principal * rate * timeElapsed) / 365 days / 1e18;
        uint256 calculatedInterest = MathLibrary.calculateComplexInterest(principal, rate, timeElapsed, compoundingPeriods);

        assertEq(expectedInterest, calculatedInterest, "Precision loss detected");
    }

    function testFuzzDepositCollateral(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1, 1e20); // 1 to 100,000 tokens

        vm.startPrank(user1);
        collateralToken.approve(address(financialPlatform), depositAmount);
        financialPlatform.depositCollateral(depositAmount);
        vm.stopPrank();

        (uint256 amount,,) = financialPlatform.getCollateralDetails(user1);
        assertEq(amount, depositAmount, "Collateral deposit mismatch");
    }

    function testFuzzWithdrawCollateral(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1, 1e20); // 1 to 100,000 tokens
        withdrawAmount = bound(withdrawAmount, 1, depositAmount); // 1 to depositAmount tokens

        vm.startPrank(user1);
        collateralToken.approve(address(financialPlatform), depositAmount);
        financialPlatform.depositCollateral(depositAmount);
        financialPlatform.withdrawCollateral(withdrawAmount);
        vm.stopPrank();

        (uint256 amount,,) = financialPlatform.getCollateralDetails(user1);
        assertEq(amount, depositAmount - withdrawAmount, "Collateral withdrawal mismatch");
    }

    function testFuzzClaimCollateralInterest(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1, 1e20); // 1 to 100,000 tokens

        vm.startPrank(user1);
        collateralToken.approve(address(financialPlatform), depositAmount);
        financialPlatform.depositCollateral(depositAmount);

        // Advance time to accumulate interest
        vm.warp(block.timestamp + 30 days);

        financialPlatform.claimCollateralInterest();
        vm.stopPrank();

        (, uint256 lastUpdate, uint256 accumulatedInterest) = financialPlatform.getCollateralDetails(user1);
        assertEq(accumulatedInterest, 0, "Accumulated interest not reset");
    }

    function testFuzzDistributeRewards(uint256 reward) public {
        reward = bound(reward, 1, 1e20); // 1 to 100,000 tokens

        vm.startPrank(owner);
        rewardToken.approve(address(financialPlatform), reward);
        financialPlatform.distributeRewards(reward);
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(address(financialPlatform)), reward, "Reward distribution mismatch");
    }

    function testFuzzGovernanceAction(address target, bytes calldata data) public {
        target = address(uint160(bound(uint256(uint160(target)), 1, type(uint160).max)));

        vm.assume(data.length > 0);

        bytes32 proposerRole = financialPlatform.PROPOSER_ROLE();
        bytes32 executorRole = financialPlatform.EXECUTOR_ROLE();
        vm.prank(owner);
        financialPlatform.grantRole(proposerRole, owner);
        vm.prank(owner);
        financialPlatform.grantRole(executorRole, owner);

        vm.startPrank(owner);
        try financialPlatform.governanceAction(target, data) {

            emit LogGovernanceActionSuccess(target, data);
        } catch Error(string memory reason) {
            emit LogRevert(reason);
        } catch (bytes memory) {
            emit LogRevert("Low-level call failed");
        }
        vm.stopPrank();
    }

    function testFuzzTransferOwnership(address newOwner) public {
        vm.assume(newOwner != address(0));

        vm.startPrank(owner);
        financialPlatform.transferOwnership(newOwner);
        vm.stopPrank();

        assertEq(financialPlatform.owner(), newOwner, "Ownership transfer failed");
    }


    function testFuzzCalculateReward(uint256 loanAmount, uint256 totalRewards) public {
        loanAmount = bound(loanAmount, 1, 1e22);
        totalRewards = bound(totalRewards, 1, 1e22);

        uint256 reward = MathLibrary.calculateReward(loanAmount, totalRewards);
        console.log("Loan Amount:", loanAmount);
        console.log("Total Rewards:", totalRewards);
        console.log("Calculated Reward:", reward);
        assertGt(reward, 0, "Calculated reward is zero");
    }

    function testFuzzUpdateCollateralToken(address newCollateralToken) public {
        vm.assume(newCollateralToken != address(0));

        vm.startPrank(owner);
        financialPlatform.setCollateralToken(IERC20(newCollateralToken));
        vm.stopPrank();

        assertEq(address(financialPlatform.collateralToken()), newCollateralToken, "Collateral token update failed");
    }

    function testFuzzUpdateRewardToken(address newRewardToken) public {
        vm.assume(newRewardToken != address(0));

        vm.startPrank(owner);
        financialPlatform.setRewardToken(IERC20(newRewardToken));
        vm.stopPrank();

        assertEq(address(financialPlatform.rewardToken()), newRewardToken, "Reward token update failed");
    }
}
