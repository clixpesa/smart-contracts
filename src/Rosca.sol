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
        //string contributionTxHash;
        uint256 contributionAmount;
        uint256 contributionDate;
    }

    struct PotDetails {
        uint256 potId;
        address potOwner;
        uint256 potAmount;
        uint256 potBalance;
        uint256 payoutDate;
        uint256 deadline;
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
    event CreatedPot(
        address dueMember,
        uint256 ctbDeadline,
        uint256 disbDeadline
    );
    event PotFunded(address memberAddress, uint256 amount);
    event PotPayedOut(address memberAddress, uint256 amount);

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
        _createPot();
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

    /// @notice Should contribute to the current pot
    /// @param _amount the amount to contribute
    function contributeToPot(uint256 _amount) external {
        require(
            RSD.RS == RoscaState.isLive,
            "You can only contribute to a live Rosca"
        );
        require(
            RSD.PS == PotState.isOpen,
            "You can only contribute to an open pot"
        );
        require(
            RSD.RD.token.allowance(msg.sender, address(this)) >= _amount,
            "You need to approve the token first"
        );
        require(
            RSD.RD.token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        RSD.currentPotBalance = RSD.currentPotBalance.add(_amount);
        RSD.roscaBalance = RSD.RD.token.balanceOf(address(this));
        currentPD.potBalance = currentPD.potBalance.add(_amount);
        currentPD.contributions.push(
            Contribution({
                memberAddress: msg.sender,
                contributionAmount: _amount,
                contributionDate: block.timestamp
            })
        );
        if (currentPD.potBalance == RSD.RD.goalAmount) {
            RSD.PS = PotState.isClosed;
        }
        emit PotFunded(msg.sender, _amount);
    }

    /// @notice Should payout the current pot
    function payoutPot() external {
        require(
            RSD.RS == RoscaState.isLive,
            "You can only payout a live Rosca"
        );
        require(
            currentPD.potBalance == RSD.RD.goalAmount,
            "Pot is not fully funded"
        );
        require(
            RSD.currentPotId == memberIndex[msg.sender],
            "You are not due to payout"
        );
        require(
            RSD.RD.token.transfer(
                currentPD.potOwner,
                currentPD.potBalance.sub(RSD.RD.goalAmount)
            ),
            "Transfer failed"
        );
        RSD.currentPotBalance = 0;
        RSD.roscaBalance = RSD.RD.token.balanceOf(address(this));
        RSD.PS = PotState.isPayedOut;

        emit PotPayedOut(msg.sender, currentPD.potBalance);
        _createPot();
    }

    /// @notice Should create a new pot
    function _createPot() internal {
        if (RSD.RS == RoscaState.isStarting) {
            currentPD.potId = 1;
            currentPD.potOwner = RSD
                .members[memberIndex[RSD.creator].sub(1)]
                .memberAddress;
            RSD.RS = RoscaState.isLive;
        } else {
            if (currentPD.potId == RSD.members.length) {
                currentPD.potId = 0;
                // reset member isPotted to false
                for (uint256 i = 0; i < RSD.members.length; i++) {
                    RSD.members[i].isPotted = false;
                }
            }
            currentPD.potId = currentPD.potId + 1;
            currentPD.potOwner = RSD.members[currentPD.potId - 1].memberAddress;
        }
        currentPD.potAmount = RSD.RD.goalAmount;
        currentPD.potBalance = 0;
        currentPD.payoutDate = CalcTime._nextDayAndTime(
            RSD.RD.disbDay,
            RSD.RD.occurrence
        );
        currentPD.deadline = CalcTime._nextDayAndTime(
            RSD.RD.ctbDay,
            RSD.RD.occurrence
        );
        RSD.currentPotId = currentPD.potId;
        RSD.currentPotBalance = currentPD.potBalance;
        RSD.PS = PotState.isOpen;

        emit CreatedPot(
            currentPD.potOwner,
            currentPD.deadline,
            currentPD.payoutDate
        );
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

    /// @dev should return when next pot is due
    function nextPot() external view returns (uint256) {
        return CalcTime._nextDayAndTime(RSD.RD.disbDay, RSD.RD.occurrence);
    }
}
