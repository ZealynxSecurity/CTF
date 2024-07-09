// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*

███╗   ███╗ █████╗ ████████╗██╗  ██╗
████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██╔████╔██║███████║   ██║   ███████║
██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

███╗   ███╗ █████╗ ████████╗██╗  ██╗
████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██╔████╔██║███████║   ██║   ███████║
██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

*/

// MathLibrary.sol
//
// Common mathematical functions used in advanced financial calculations.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Thrown when the resultant value in {mulDiv} overflows uint256.
error MathLibrary_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Thrown when the resultant value in {mulDiv18} overflows uint256.
error MathLibrary_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Thrown when one of the inputs passed to {mulDivSigned} is `type(int256).min`.
error MathLibrary_MulDivSigned_InputTooSmall();

/// @notice Thrown when the resultant value in {mulDivSigned} overflows int256.
error MathLibrary_MulDivSigned_Overflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The maximum value a uint256 number can have.
uint256 constant MAX_UINT256 = type(uint256).max;

/// @dev The maximum value a uint128 number can have.
uint128 constant MAX_UINT128 = type(uint128).max;

/// @dev The maximum value a uint40 number can have.
uint40 constant MAX_UINT40 = type(uint40).max;

/// @dev The maximum value a uint64 number can have.
uint64 constant MAX_UINT64 = type(uint64).max;

/// @dev The unit number, which the decimal precision of the fixed-point types.
uint256 constant UNIT = 1e18;

/// @dev The unit number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/// @dev The largest power of two that divides the decimal value of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library MathLibrary {
    uint256 private constant PRECISION = 1e18;

    /// @notice Adds two numbers.
    /// @param a The first number.
    /// @param b The second number.
    /// @return result The sum of the two numbers.
    function add(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a + b;
    }

    /// @notice Subtracts the second number from the first number.
    /// @param a The first number.
    /// @param b The second number.
    /// @return result The difference between the two numbers.
    function sub(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(b <= a, "MathLibrary: subtraction overflow");
        result = a - b;
    }

    /// @notice Multiplies two numbers.
    /// @param a The first number.
    /// @param b The second number.
    /// @return result The product of the two numbers.
    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        if (a == 0 || b == 0) {
            return 0;
        }
        result = a * b;
    }

    /// @notice Divides the first number by the second number.
    /// @param a The first number.
    /// @param b The second number.
    /// @return result The quotient of the two numbers.
    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(b > 0, "MathLibrary: division by zero");
        result = a / b;
    }

    /// @notice Calculates the interest for a given period.
    /// @param principal The principal amount.
    /// @param rate The interest rate.
    /// @param compoundingPeriods The number of compounding periods.
    /// @return result The interest for the period.
    function calculatePeriodInterest(uint256 principal, uint256 rate, uint256 compoundingPeriods) internal pure returns (uint256 result) {
        uint256 temp = principal * rate;
        result = temp / compoundingPeriods / PRECISION;
    }

    /// @notice Accumulates interest over multiple compounding periods.
    /// @param principal The principal amount.
    /// @param rate The interest rate.
    /// @param compoundingPeriods The number of compounding periods.
    /// @return result The total accumulated interest.
    function accumulateInterest(uint256 principal, uint256 rate, uint256 compoundingPeriods) internal pure returns (uint256 result) {
        uint256 base = principal;
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < compoundingPeriods; i++) {
            uint256 periodInterest = calculatePeriodInterest(base, rate, compoundingPeriods);
            base = base + periodInterest;
            totalInterest = totalInterest + periodInterest;
        }
        result = totalInterest;
    }

    /// @notice Adjusts interest for a given time elapsed.
    /// @param totalInterest The total accumulated interest.
    /// @param timeElapsed The time elapsed.
    /// @return result The adjusted interest.
    function adjustInterestForTime(uint256 totalInterest, uint256 timeElapsed) internal pure returns (uint256 result) {
        uint256 temp = totalInterest * timeElapsed;
        result = temp / 365 days;
    }

    /// @notice Calculates complex interest over time.
    /// @param principal The principal amount.
    /// @param rate The interest rate.
    /// @param timeElapsed The time elapsed.
    /// @param compoundingPeriods The number of compounding periods.
    /// @return result The total complex interest.
    function calculateComplexInterest(uint256 principal, uint256 rate, uint256 timeElapsed, uint256 compoundingPeriods) internal pure returns (uint256 result) {
        uint256 totalInterest = accumulateInterest(principal, rate, compoundingPeriods);
        uint256 adjustedInterest = adjustInterestForTime(totalInterest, timeElapsed);
        result = adjustedInterest;
    }

    /// @notice Calculates the reward based on the loan amount and total rewards.
    /// @param loanAmount The amount of the loan.
    /// @param totalRewards The total rewards.
    /// @return reward The calculated reward.
    function calculateReward(uint256 loanAmount, uint256 totalRewards) internal pure returns (uint256 reward) {
        reward = loanAmount * totalRewards / PRECISION;
    }

    /// @notice Multiplies two numbers and divides the result by a third number, rounding down.
    /// @param x The first number.
    /// @param y The second number.
    /// @param denominator The denominator.
    /// @return result The result of the multiplication and division.
    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        uint256 maxUint256 = MAX_UINT256; // Create a local variable for the constant
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(maxUint256, y)))))) {
                revert(0, 0)
            }
            result := div(mul(x, y), denominator)
        }
    }

    /// @notice Multiplies two numbers and divides the result by a third number, rounding up.
    /// @param x The first number.
    /// @param y The second number.
    /// @param denominator The denominator.
    /// @return result The result of the multiplication and division.
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        uint256 maxUint256 = MAX_UINT256; // Create a local variable for the constant
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(maxUint256, y)))))) {
                revert(0, 0)
            }
            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            result := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    /// @notice Calculates the square root of a number using the Babylonian method.
    /// @param x The number for which to calculate the square root.
    /// @return result The square root of the number.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }
        uint256 xAux = x;
        result = 1;
        if (xAux >= 2 ** 128) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 2 ** 64) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 2 ** 32) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 2 ** 16) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 2 ** 8) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 2 ** 4) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 2 ** 2) {
            result <<= 1;
        }
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            uint256 roundedResult = x / result;
            if (result >= roundedResult) {
                result = roundedResult;
            }
        }
    }

    /// @notice Calculates the power of a base number raised to an exponent.
    /// @param base The base number.
    /// @param exponent The exponent.
    /// @return result The result of the base raised to the exponent.
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256 result) {
        result = 1;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = result * base;
            }
            exponent = exponent >> 1;
            base = base * base;
        }
    }
}
