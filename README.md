# About Zealynx


Zealynx Security, founded in January 2024 by Bloqarl and Sergio, specializes in smart contract audits, development, and security testing using Solidity and Rust. Our services include comprehensive smart contract audits, smart contract fuzzing, and formal verification test suites to enhance security reviews and ensure robust contract functionality. We are trusted by clients such as Shieldify, AuditOne, Bastion Wallet, Side.xyz, Possum Labs, and Aurora (NEAR Protocol-based).

Our team believes in transparency and actively contributes to the community by creating educational content. This includes challenges for Foundry and Rust, security tips for Solidity developers, and fuzzing materials like Foundry and Echidna/Medusa. We also publish articles on topics such as preparing for an audit and battle testing smart contracts on our blog, Bloqarl's blog, and Sergio's blog.

Zealynx has achieved public recognition, including a Top 5 position in the Beanstalk Audit public contest, rewarded with $8k. Our ongoing commitment is to provide value through our expertise and innovative security solutions for smart contracts.

<img width="700" alt="image" src="image/zealynx.png">

---

# CTF Challenge: Decentralized Financial Platform

Welcome to the exciting CTF Challenge of the Decentralized Financial Platform! This challenge will immerse you in the fascinating world of decentralized finance (DeFi), testing your skills in smart contract auditing.

## What will you find in this CTF?

1. **Complex Smart Contracts:**
   - **Financial Platform:** A main contract that allows users to perform various financial operations such as taking loans, depositing collateral, receiving rewards, and participating in system governance.
   - **Mock ERC20 Tokens:** Simulated tokens representing stablecoins, rewards, and collateral.

2. **Mathematical Library:**
   - **MathLibrary:** A library implementing essential functions for calculating interests and rewards, fundamental to the financial operations of the main contract.

## Your Mission

The primary goal of this CTF is to analyze and audit the smart contracts of the platform, identifying potential vulnerabilities. During your audit, pay attention to:

- **Interest and Reward Calculation:** Ensure that the calculation functions return correct and precise values.
- **Loan and Collateral Management:** Verify that the contract properly handles loan and collateral operations.
- **Governance and Security:** Evaluate the security of governance functions and the correct implementation of roles and permissions.
- **Transaction Transparency:** Ensure all transactions are transparent and traceable.
- **Data Integrity:** Guarantee that the data stored and manipulated by the contracts is accurate and unalterable.
- **Scalability:** Examine how the contract handles a large volume of transactions and users.
- **Error Handling:** Ensure the contract appropriately handles errors and exceptions.
- **Gas Efficiency:** Verify that the contract functions are efficient in gas usage.
- **Attack Resilience:** Evaluate the contract's robustness against potential attacks such as reentrancy, overflow, and underflow.

This CTF is designed to challenge you and help you improve your skills in smart contract auditing. Enjoy exploring the Decentralized Financial Platform and demonstrate your expertise!

Remember, the key is in the details! 🚀

# Summary of the Tests

### `testFuzzTakeLoan`

- **Description:** Verifies that the loan amount taken matches the requested amount.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzRepayLoan`

- **Description:** Verifies that the remaining loan amount after a repayment matches the expected amount.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzCalculateInterest`

- **Description:** Verifies that the calculated interest is not zero.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** Yes.

### `testPrecisionLoss`

- **Description:** Compares the expected interest with the calculated interest to detect precision losses.
- **Expected Result:** Should not pass.
- **Vulnerability Demonstrated:** Yes.

### `testFuzzDepositCollateral`

- **Description:** Verifies that the amount of deposited collateral matches the expected amount.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzWithdrawCollateral`

- **Description:** Verifies that the amount of withdrawn collateral matches the expected amount.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzClaimCollateralInterest`

- **Description:** Verifies that the accumulated interest is reset to zero after being claimed.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzDistributeRewards`

- **Description:** Verifies that the amount of distributed rewards matches the expected amount.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzGovernanceAction`

- **Description:** Verifies that governance actions can be executed.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzTransferOwnership`

- **Description:** Verifies that the ownership transfer is executed correctly.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzCalculateReward`

- **Description:** Verifies that the calculated reward is not zero.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** Yes.

### `testFuzzUpdateCollateralToken`

- **Description:** Verifies that the collateral token update is executed correctly.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

### `testFuzzUpdateRewardToken`

- **Description:** Verifies that the reward token update is executed correctly.
- **Expected Result:** Should pass.
- **Vulnerability Demonstrated:** No.

With these changes, the tests `testFuzzCalculateInterest` and `testFuzzCalculateReward` appropriately reflect the vulnerabilities demonstrated in calculating interest and rewards.
