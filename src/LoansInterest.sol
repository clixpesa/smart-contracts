//SPDX-License-Identifier: Apache 2.0
/**
@title Clixpesa P2PLoans Interest Rate Calculation
@author Dekan Kachi - @kachdekan
@notice Get the amount of interest to be paid on a loan
*/

pragma solidity ^0.8.19;

import {UD60x18, ud, convert} from "@prb/math/src/UD60x18.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LoanInterest {
    using SafeMath for uint256;

    function _getInterest(
        uint256 _amount,
        uint256 _rate,
        uint256 _duration
    ) internal pure returns (uint256) {
        UD60x18 thisAmt = convert(_amount); //AmountInEther*1e18
        UD60x18 thisRate = convert(_rate);
        UD60x18 rateAsec = thisRate.div(ud(10000e18)).div(ud(31536000e18));
        UD60x18 thisDuration = convert(_duration);
        UD60x18 thisInterest = (thisAmt.mul(rateAsec)).mul(thisDuration);
        uint256 _interest = convert(thisInterest);
        return _interest;
    }

    function _getNewBalance(
        uint256 _amount,
        uint256 _rate,
        uint256 _duration
    ) internal pure returns (uint256) {
        uint256 _interest = _getInterest(_amount, _rate, _duration);
        uint256 _newBalance = _amount.add(_interest);
        return _newBalance;
    }
}
