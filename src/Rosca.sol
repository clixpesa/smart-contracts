//SPDX-License-Identifier: Apache 2.0
/**
@title Clixpesa Rosca Contract
@author Dekan Kachi - @kachdekan
@notice Allow users to save in group with a rotating pot. Deployed by RoscaSpaces.
*/

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CalcTime.sol";
import "hardhat/console.sol";

struct RoscaDetails {
    IERC20 token;
    string roscaName;
    string imgLink;
    uint256 goalAmount;
    uint256 ctbAmount;
    string ctbDay;
    string disbDay;
    string occurrence;
}

contract Rosca {
    using SafeMath for uint256;

    enum PotState {
        isOpen,
        isClosed,
        isPayedOut
    }

    enum RoscaState {
        isStarting,
        isLive,
        isEnded,
        isInActive
    }

    /// @notice Rosca structs
    struct Member {
        address memberAddress;
        uint256 memberBalance;
        uint256 memberSince;
        bool isPotted;
        bool isAdmin;
    }

    struct Contribution {
        address memberAddress;
        string contributionTxHash;
        uint256 contributionAmount;
        uint256 contributionDate;
    }

    struct PotDetails {
        address potOwner;
        uint256 potId;
        uint256 potAmount;
        uint256 potBalance;
        uint256 payoutDate;
        Contribution[] contributions;
    }
    /// @dev RoscaSpaceDetails struct for this Rosca
    struct RoscaSpaceDetails {
        RoscaDetails RD;
        address creator;
        RoscaState RS;
        PotState PS;
        Member[] members;
        uint256 roscaBalance;
        uint256 currentPotBalance;
        uint256 currentPotId;
    }

    /// @notice Rosca variables
    RoscaSpaceDetails RSD;
    string authCode;
    PotDetails currentPD;
    mapping(address => uint256) memberIndex; //maz members 255

    /// @notice Rosca events
    event JoinedRosca(address memberAddress, uint256 joinedAt);

    /// @notice Rosca Constructor
    constructor(
        RoscaDetails memory _RD,
        string memory _aCode,
        address _creator
    ) {
        RSD.RD = _RD;
        RSD.creator = _creator;
        authCode = _aCode;
        Member memory firstMember = Member({
            memberAddress: _creator,
            memberBalance: 0,
            isPotted: false,
            isAdmin: true,
            memberSince: block.timestamp
        });
        RSD.members.push(firstMember);
        memberIndex[_creator] = RSD.members.length;
    }

    /// @notice Rosca functions
    /// @notice Should join Rosca via invite/authCode code
    /// @param  _authCode the authCode of the RoscaSpace
    function joinRosca(string memory _authCode) external {
        require(
            keccak256(abi.encodePacked(_authCode)) ==
                keccak256(abi.encodePacked(authCode)),
            "Invalid authCode"
        );
        require(
            memberIndex[msg.sender] == 0,
            "You are already a member of this Rosca"
        );
        uint256 joinedAt = block.timestamp;

        Member memory newMember = Member({
            memberAddress: msg.sender,
            memberBalance: 0,
            isPotted: false,
            isAdmin: false,
            memberSince: joinedAt
        });
        RSD.members.push(newMember);
        memberIndex[msg.sender] = RSD.members.length;
        emit JoinedRosca(msg.sender, joinedAt);
    }

    /// @notice Rosca getters
    /// @dev should get the RoscaSpaceDetails struct
    function getRoscaDetails()
        external
        view
        returns (RoscaSpaceDetails memory)
    {
        return RSD;
    }

    /// @dev should get the current pot details
    function getCurrentPotDetails() external view returns (PotDetails memory) {
        return currentPD;
    }

    /// @dev should get the list of members
    function getMembers() external view returns (Member[] memory) {
        return RSD.members;
    }

    /// @notice Rosca utility functions
    /// @dev should return next timestamp from given schedule and day of week
    /// @param _schDay 1 Monday
    function _nextDayAndTime(
        string memory _schDay
    ) internal view returns (uint256 nextTimeStamp) {
        uint256 day;
        uint256 month;
        uint256 year;
        uint256 _ocurrance = _getOcurranceNo(RSD.RD.occurrence);
        if (_ocurrance == 1) {
            return block.timestamp.add(24 * 60 * 60);
        } else {
            uint256 _day = _getDayNo(_schDay);
            uint256 _days = block.timestamp / (24 * 60 * 60);
            uint256 dayOfWeek = ((_days + 3) % 7) + 1;
            (year, month, day) = CalcTime._daysToDate(_days);
            if (_ocurrance == 7) {
                uint256 nextDay = day + ((7 + _day - dayOfWeek) % 7);
                nextTimeStamp =
                    CalcTime._daysFromDate(year, month, nextDay) *
                    (24 * 60 * 60);
                if (nextTimeStamp <= block.timestamp) {
                    nextTimeStamp = nextTimeStamp.add(7 * (24 * 60 * 60));
                }
                return nextTimeStamp;
            } else if (_ocurrance == 28) {
                uint256 nextDay = day + ((28 + _day - dayOfWeek) % 28);
                nextTimeStamp =
                    CalcTime._daysFromDate(year, month, nextDay) *
                    (24 * 60 * 60);
                if (nextTimeStamp <= block.timestamp) {
                    nextTimeStamp = nextTimeStamp.add(28 * (24 * 60 * 60));
                }
                return nextTimeStamp;
            }
        }
    }

    /// @dev return number of day from given day of week
    /// @param _day 1. Monday
    function _getDayNo(
        string memory _day
    ) internal pure returns (uint256 dayNo) {
        string[7] memory weekList = [
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday"
        ];
        bytes32 encodedElement = keccak256(abi.encode(_day));
        for (uint256 i = 0; i < weekList.length; i++) {
            if (encodedElement == keccak256(abi.encode(weekList[i]))) {
                return i + 1;
            }
        }
    }

    /// @dev return number of ocurrance from given ocurrance
    /// @param _ocurrance 1. Daily 7. Weekly 30 Monthly
    function _getOcurranceNo(
        string memory _ocurrance
    ) internal pure returns (uint256 ocurranceNo) {
        string[3] memory ocurranceList = ["Daily", "Weekly", "Monthly"];
        uint8[3] memory ocurranceSize = [1, 7, 28];
        bytes32 encodedElement = keccak256(abi.encode(_ocurrance));
        for (uint256 i = 0; i < ocurranceList.length; i++) {
            if (encodedElement == keccak256(abi.encode(ocurranceList[i]))) {
                return ocurranceSize[i];
            }
        }
    }
}
