// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "./MathLibrary.sol";

/*
██████╗ ███████╗ █████╗ ██╗     ███████╗██╗  ██╗ █████╗ ██╗███╗   ██╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔════╝██╔══██╗██║     ██╔════╝██║  ██║██╔══██╗██║████╗  ██║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝█████╗  ███████║██║     █████╗  ███████║███████║██║██╔██╗ ██║███████║   ██║   ███████║
██╔═══╝ ██╔══╝  ██╔══██║██║     ██╔══╝  ██╔══██║██╔══██║██║██║╚██╗██║██╔══██║   ██║   ██╔══██║
██║     ███████╗██║  ██║███████╗███████╗██║  ██║██║  ██║██║██║ ╚████║██║  ██║   ██║   ██║  ██║
╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
*/

// AdvancedFinancialPlatform.sol
//
// This contract demonstrates a example of using the MathLibrary
// to perform complex financial operations such as lending, borrowing, collateral management,
// reward distribution, and governance actions.

contract AdvancedFinancialPlatform is Ownable, ReentrancyGuard, TimelockController {
    using SafeERC20 for IERC20;
    using MathLibrary for uint256;

    IERC20 public stableCoin;
    IERC20 public rewardToken;
    IERC20 public collateralToken;

    uint256 public totalLent;
    uint256 public totalBorrowed;
    uint256 public totalCollateral;
    uint256 public totalRewards;
    uint256 private constant PRECISION = 1e18;

    struct Loan {
        uint256 amount;
        uint256 interestRate;
        uint256 collateralAmount;
        uint256 rewardDebt;
        uint256 startTimestamp;
    }

    struct Collateral {
        uint256 amount;
        uint256 lastUpdate;
        uint256 accumulatedInterest;
    }

    mapping(address => Loan) public loans;
    mapping(address => Collateral) public collaterals;
    mapping(address => uint256) public rewards;

    event LoanTaken(address indexed user, uint256 amount, uint256 collateralAmount, uint256 interestRate);
    event LoanRepaid(address indexed user, uint256 amount, uint256 reward);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event GovernanceActionExecuted(address indexed target, bytes data);

    constructor(
        IERC20 _stableCoin,
        IERC20 _rewardToken,
        IERC20 _collateralToken,
        address[] memory proposers,
        address[] memory executors
    )
        Ownable(msg.sender)
        TimelockController(
            2 days, // minDelay before an operation can be executed
            proposers,
            executors,
            msg.sender
        )
    {
        stableCoin = _stableCoin;
        rewardToken = _rewardToken;
        collateralToken = _collateralToken;
    }

    /// @notice Deposits collateral into the platform.
    /// @param amount The amount of collateral to deposit.
    function depositCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot deposit 0");
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);

        Collateral storage userCollateral = collaterals[msg.sender];
        updateCollateralInterest(msg.sender);

        userCollateral.amount = userCollateral.amount.add(amount);
        userCollateral.lastUpdate = block.timestamp;

        totalCollateral = totalCollateral.add(amount);
        emit CollateralDeposited(msg.sender, amount);
    }

    /// @notice Withdraws collateral from the platform.
    /// @param amount The amount of collateral to withdraw.
    function withdrawCollateral(uint256 amount) external nonReentrant {
        Collateral storage userCollateral = collaterals[msg.sender];
        require(userCollateral.amount >= amount, "Insufficient collateral");

        updateCollateralInterest(msg.sender);

        userCollateral.amount = userCollateral.amount.sub(amount);
        collateralToken.safeTransfer(msg.sender, amount);

        totalCollateral = totalCollateral.sub(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    /// @notice Takes a loan from the platform.
    /// @param amount The amount of stablecoins to borrow.
    /// @param collateralAmount The amount of collateral to deposit.
    /// @param interestRate The interest rate for the loan.
    function takeLoan(uint256 amount, uint256 collateralAmount, uint256 interestRate) external nonReentrant {
        require(amount > 0 && collateralAmount > 0, "Invalid amounts");
        require(interestRate > 0 && interestRate <= PRECISION, "Invalid interest rate");

        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        stableCoin.safeTransfer(msg.sender, amount);

        Loan storage userLoan = loans[msg.sender];
        userLoan.amount = amount;
        userLoan.interestRate = interestRate;
        userLoan.collateralAmount = collateralAmount;
        userLoan.rewardDebt = totalLent > 0 ? userLoan.amount.mul(totalRewards).div(totalLent) : 0;
        userLoan.startTimestamp = block.timestamp;

        totalLent = totalLent.add(amount);
        totalBorrowed = totalBorrowed.add(amount);
        totalCollateral = totalCollateral.add(collateralAmount);

        emit LoanTaken(msg.sender, amount, collateralAmount, interestRate);
    }

    /// @notice Repays a loan.
    /// @param amount The amount of stablecoins to repay.
    function repayLoan(uint256 amount) external nonReentrant {
        Loan storage userLoan = loans[msg.sender];
        require(userLoan.amount >= amount, "Repay amount exceeds loan");

        uint256 interest = MathLibrary.calculateComplexInterest(userLoan.amount, userLoan.interestRate, block.timestamp.sub(userLoan.startTimestamp), 12); // 12 compounding periods for monthly compounding
        uint256 reward = MathLibrary.calculateReward(userLoan.amount, totalRewards).sub(userLoan.rewardDebt);

        stableCoin.safeTransferFrom(msg.sender, address(this), amount + interest);
        rewardToken.safeTransfer(msg.sender, reward);
        collateralToken.safeTransfer(msg.sender, userLoan.collateralAmount);

        userLoan.amount = userLoan.amount.sub(amount);
        userLoan.rewardDebt = userLoan.amount.mul(totalRewards).div(totalLent);
        userLoan.startTimestamp = block.timestamp;

        totalLent = totalLent.sub(amount);
        totalBorrowed = totalBorrowed.sub(amount);
        totalCollateral = totalCollateral.sub(userLoan.collateralAmount);

        emit LoanRepaid(msg.sender, amount, reward);
        emit RewardPaid(msg.sender, reward);
    }

    /// @notice Distributes rewards to the platform.
    /// @param reward The amount of rewards to distribute.
    function distributeRewards(uint256 reward) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        totalRewards = totalRewards.add(reward);
    }

    /// @notice Updates the collateral interest for a user.
    /// @param user The address of the user.
    function updateCollateralInterest(address user) internal {
        Collateral storage userCollateral = collaterals[user];
        uint256 timeElapsed = block.timestamp - userCollateral.lastUpdate;
        uint256 interest = MathLibrary.calculateComplexInterest(userCollateral.amount, 5e16, timeElapsed, 12); // 5% annual interest compounded monthly
        userCollateral.accumulatedInterest = userCollateral.accumulatedInterest.add(interest);
        userCollateral.lastUpdate = block.timestamp;
    }

    /// @notice Claims the accumulated collateral interest.
    function claimCollateralInterest() external {
        Collateral storage userCollateral = collaterals[msg.sender];
        updateCollateralInterest(msg.sender);
        uint256 interest = userCollateral.accumulatedInterest;
        userCollateral.accumulatedInterest = 0;
        collateralToken.safeTransfer(msg.sender, interest);
    }

    /// @notice Gets the loan details of a user.
    /// @param user The address of the user.
    /// @return amount The loan amount.
    /// @return interestRate The loan interest rate.
    /// @return collateralAmount The collateral amount.
    /// @return rewardDebt The reward debt.
    /// @return startTimestamp The loan start timestamp.
    function getLoanDetails(address user) external view returns (uint256 amount, uint256 interestRate, uint256 collateralAmount, uint256 rewardDebt, uint256 startTimestamp) {
        Loan storage loan = loans[user];
        return (loan.amount, loan.interestRate, loan.collateralAmount, loan.rewardDebt, loan.startTimestamp);
    }

    /// @notice Calculates the total debt of a user.
    /// @param user The address of the user.
    /// @return The total debt including interest.
    function calculateTotalDebt(address user) external view returns (uint256) {
        Loan storage loan = loans[user];
        uint256 interest = MathLibrary.calculateComplexInterest(loan.amount, loan.interestRate, block.timestamp - loan.startTimestamp, 12);
        return loan.amount.add(interest);
    }

    /// @notice Gets the collateral details of a user.
    /// @param user The address of the user.
    /// @return amount The collateral amount.
    /// @return lastUpdate The last update timestamp.
    /// @return accumulatedInterest The accumulated interest.
    function getCollateralDetails(address user) external view returns (uint256 amount, uint256 lastUpdate, uint256 accumulatedInterest) {
        Collateral storage collateral = collaterals[user];
        return (collateral.amount, collateral.lastUpdate, collateral.accumulatedInterest);
    }

    /// @notice Executes a governance action.
    /// @param target The target address for the action.
    /// @param data The data for the action.
    function governanceAction(address target, bytes calldata data) external onlyRole(PROPOSER_ROLE) {
        require(hasRole(EXECUTOR_ROLE, msg.sender), "Caller is not an executor");
        require(target != address(0), "Invalid target address");
        require(data.length > 0, "Data cannot be empty");

        (bool success, ) = target.call(data);
        require(success, "Governance action failed");

        emit GovernanceActionExecuted(target, data);
    }

    /// @notice Updates the loan interest rate for a user.
    /// @param user The address of the user.
    /// @param newInterestRate The new interest rate for the loan.
    function updateLoanInterestRate(address user, uint256 newInterestRate) external onlyOwner {
        Loan storage userLoan = loans[user];
        userLoan.interestRate = newInterestRate;
    }

    /// @notice Sets a new collateral token.
    /// @param newCollateralToken The address of the new collateral token.
    function setCollateralToken(IERC20 newCollateralToken) external onlyOwner {
        collateralToken = newCollateralToken;
    }

    /// @notice Sets a new reward token.
    /// @param newRewardToken The address of the new reward token.
    function setRewardToken(IERC20 newRewardToken) external onlyOwner {
        rewardToken = newRewardToken;
    }
}
