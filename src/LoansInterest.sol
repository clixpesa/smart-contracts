//SPDX-License-Identifier: Apache 2.0
/**
@title Clixpesa P2PLoans Interest Rate Calculation
@author Dekan Kachi - @kachdekan
@notice Get the amount of interest to be paid on a loan
*/

pragma solidity 0.8.19;

import {UD60x18, ud, convert} from "@prb/math/src/UD60x18.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LoanInterest {
    using SafeMath for uint256;

    /// @notice Get the accrued interest on a loan
    /// @param _amount The amount of the loan
    /// @param _rate The interest rate in basis points
    /// @param _duration The duration of the loan in seconds since the last loan update
    function _getInterest(
        uint256 _amount,
        uint256 _rate,
        uint256 _duration
    ) internal pure returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        //require rate is greater than 0 and less than 100 basis points
        require(
            _rate > 0 && _rate < 10000,
            "Rate must be > 0 and < 10000 basis points"
        );
        require(_duration > 0, "Duration must be greater than 0");
        UD60x18 thisAmt = convert(_amount); //AmountInEther*1e18
        UD60x18 thisRate = convert(_rate);
        UD60x18 rateAsec = thisRate.div(ud(10000e18)).div(ud(31536000e18));
        UD60x18 thisDuration = convert(_duration);
        UD60x18 thisInterest = (thisAmt.mul(rateAsec)).mul(thisDuration);
        uint256 _interest = convert(thisInterest);
        return _interest;
    }

    /// @notice Get the new balance of a loan
    /// @dev The new balance is the amount of the loan plus the accrued interest
    /// @param _amount The amount of the loan
    /// @param _rate The interest rate in basis points
    /// @param _duration The duration of the loan in seconds since the last loan update

    function _getNewBalance(
        uint256 _amount,
        uint256 _rate,
        uint256 _duration
    ) internal pure returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        //require rate is greater than 0 and less than 100 basis points
        require(
            _rate > 0 && _rate < 10000,
            "Rate must be > 0 and < 10000 basis points"
        );
        require(_duration > 0, "Duration must be greater than 0");
        uint256 _interest = _getInterest(_amount, _rate, _duration);
        uint256 _newBalance = _amount.add(_interest);
        return _newBalance;
    }
}
