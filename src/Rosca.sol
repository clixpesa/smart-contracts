//SPDX-License-Identifier: Apache 2.0
/**
@title Clixpesa Rosca Contract
@author Dekan Kachi - @kachdekan
@notice Allow users to save in group with a rotating pot. Deployed by RoscaSpaces.
*/

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct RoscaDetails {
    IERC20 token;
    string roscaName;
    string imgLink;
    string authCode;
    uint256 goalAmount;
    uint256 ctbAmount;
    string ctbDay;
    string ctbOccur;
    string disbDay;
    string disbOccur;
}

contract Rosca {
    using SafeMath for uint256;

    /// @notice Rosca structs
    struct Member {
        address memberAddress;
        uint256 memberBalance;
        bool isPotted;
        bool isMember;
    }

    struct Contribution {
        address memberAddress;
        uint256 contributionId;
        uint256 contributionAmount;
        uint256 contributionDate;
    }

    struct Payout {
        address memberAddress;
        uint256 payoutId;
        uint256 payoutAmount;
        uint256 payoutDate;
    }

    /// @notice Rosca variables
    RoscaDetails RD;
    address creator;

    /// @notice Rosca Constructor
    constructor(RoscaDetails memory _RD, address _creator) {
        RD = _RD;
        creator = _creator;
    }
}
