//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LoansInterest.sol";
import "hardhat/console.sol";

contract TestInterest {
    using SafeMath for uint256;

    function getInterest(
        uint256 _amount,
        uint256 _rate,
        uint256 _lastUpdated
    ) public view returns (uint256) {
        uint256 _duration = block.timestamp.sub(_lastUpdated);
        return LoanInterest._getInterest(_amount, _rate, _duration);
    }
}
