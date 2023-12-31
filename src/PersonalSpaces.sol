//SPDX-License-Identifier: Apache 2.0
/**
@title Clixpesa Personal Spaces Contract
@author Dekan Kachi - @kachdekan
@notice Allow users to create saving goals and save towards them.
*/

pragma solidity 0.8.19;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract PersonalSpaces {
    using SafeMath for uint256;

    /// @notice Space currency
    // map immutable to token address and space id
    mapping(string => IERC20) public spaceCurrency;

    //Personal Space Enums
    enum FundsState {
        isFundable,
        isFullyFunded
    }
    enum ActivityState {
        isActive,
        isInActive
    }

    //Personal Space Structs
    struct SpaceDetails {
        IERC20 token;
        address payable owner;
        string spaceName;
        string imgLink;
        string spaceId;
        uint256 goalAmount;
        uint256 deadline;
    }
    struct SpaceStates {
        FundsState currentFundState;
        ActivityState currentActivityState;
    }

    struct PersonalDetails {
        SpaceDetails SD;
        SpaceStates SS;
        uint256 currentBalance;
    }

    //List of all Personal Spaces
    PersonalDetails[] allPersonalSpaces;
    mapping(string => uint256) personalSpaceIndex;
    mapping(address => PersonalDetails[]) myPersonalSpaces;
    mapping(address => mapping(string => uint256)) myPersonalSpaceIdx;

    //Personal Space events
    event CreatedPersonalSpace(address owner, SpaceDetails SD);
    event FundedPersonalSpace(address funder, string spaceId, uint256 amount);
    event WithdrawnPersonalSpace(
        address withdrawer,
        string spaceId,
        uint256 amount
    );
    event UpdatedPersonalSpace(PersonalDetails PD);
    event ClosedPersonalSpace(address owner, string spaceId);
    event DeletedPersonalSpace(address owner, string spaceId);

    constructor() {}

    function createPersonalSpace(SpaceDetails memory _SD) external {
        require(msg.sender == _SD.owner, "Must be owner");
        require(
            bytes(_SD.spaceName).length > 0 &&
                bytes(_SD.spaceName).length <= 40,
            "!Space Name"
        );
        require(
            bytes(_SD.spaceId).length > 0 && bytes(_SD.spaceId).length <= 15,
            "!Space Id"
        );
        require(personalSpaceIndex[_SD.spaceId] == 0, "SpaceId already exists");
        require(
            myPersonalSpaceIdx[msg.sender][_SD.spaceId] == 0,
            "SpaceId already exists"
        );
        require(_SD.owner != address(0), "Owner cannot be 0 address");
        require(_SD.token != IERC20(address(0)), "Token cannot be 0 address");
        require(_SD.deadline > block.timestamp, "Deadline must be in future");
        require(_SD.goalAmount > 0, "Goal must be greater than 0");
        SpaceStates memory _SS = SpaceStates(
            FundsState.isFundable,
            ActivityState.isActive
        );

        uint256 _currentBalance = 0;

        PersonalDetails memory _PD = PersonalDetails(_SD, _SS, _currentBalance);

        allPersonalSpaces.push(_PD);
        personalSpaceIndex[_SD.spaceId] = allPersonalSpaces.length;
        myPersonalSpaces[msg.sender].push(_PD);
        myPersonalSpaceIdx[msg.sender][_SD.spaceId] = myPersonalSpaces[
            msg.sender
        ].length;

        emit CreatedPersonalSpace(msg.sender, _SD);
    }

    function getAllPersonalSpaces()
        external
        view
        returns (PersonalDetails[] memory)
    {
        return allPersonalSpaces;
    }

    function getPersonalSpaceById(
        string memory _spaceId
    ) external view returns (PersonalDetails memory) {
        require(personalSpaceIndex[_spaceId] != 0, "Space does not exist");
        return allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)];
    }

    function getPersonalSpacesByOwner(
        address _owner
    ) external view returns (PersonalDetails[] memory) {
        return myPersonalSpaces[_owner];
    }

    function getMyPersonalSpaces()
        external
        view
        returns (PersonalDetails[] memory)
    {
        return myPersonalSpaces[msg.sender];
    }

    function doesPersonalSpaceExist(
        address owner,
        string memory _spaceId
    ) external view returns (bool isExistent) {
        if (personalSpaceIndex[_spaceId] == 0) {
            return false;
        }
        if (myPersonalSpaceIdx[owner][_spaceId] == 0) {
            return false;
        }
        return true;
    }

    function updatePersonalSpace(SpaceDetails memory _SD) external {
        require(msg.sender == _SD.owner, "Must be owner");
        require(personalSpaceIndex[_SD.spaceId] != 0, "SpaceId does not exist");
        require(
            myPersonalSpaceIdx[msg.sender][_SD.spaceId] != 0,
            "SpaceId does not exist"
        );
        require(_SD.owner != address(0), "Owner cannot be 0 address");
        require(
            _SD.token ==
                allPersonalSpaces[personalSpaceIndex[_SD.spaceId].sub(1)]
                    .SD
                    .token,
            "Token cannot be changed"
        );
        require(bytes(_SD.spaceName).length > 0, "Name cannot be empty");
        require(_SD.deadline > block.timestamp, "Deadline must be in future");
        require(_SD.goalAmount > 0, "Goal must be greater than 0");

        uint256 _balance = allPersonalSpaces[
            personalSpaceIndex[_SD.spaceId].sub(1)
        ].currentBalance;

        SpaceStates memory _CS = allPersonalSpaces[
            personalSpaceIndex[_SD.spaceId].sub(1)
        ].SS;

        PersonalDetails memory _PD = PersonalDetails(_SD, _CS, _balance);
        allPersonalSpaces[personalSpaceIndex[_SD.spaceId].sub(1)] = _PD;
        myPersonalSpaces[msg.sender][
            myPersonalSpaceIdx[msg.sender][_SD.spaceId].sub(1)
        ] = _PD;

        emit UpdatedPersonalSpace(
            allPersonalSpaces[personalSpaceIndex[_SD.spaceId].sub(1)]
        );
    }

    function fundPersonalSpace(
        string memory _spaceId,
        uint256 _amount
    ) external {
        require(personalSpaceIndex[_spaceId] != 0, "SpaceId does not exist");
        require(
            myPersonalSpaceIdx[msg.sender][_spaceId] != 0,
            "SpaceId does not exist"
        );
        PersonalDetails memory _PD = allPersonalSpaces[
            personalSpaceIndex[_spaceId].sub(1)
        ];
        require(
            _PD.SS.currentFundState == FundsState.isFundable,
            "Funding is not allowed / Fully funded"
        );
        require(
            _PD.SS.currentActivityState == ActivityState.isActive,
            "Space should be active"
        );
        require(
            _PD.SD.deadline > block.timestamp,
            "Deadline must be in future"
        );
        require(
            _PD.SD.token.allowance(msg.sender, address(this)) >= _amount,
            "You need to approve the token first"
        );
        require(
            _PD.SD.token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)]
            .currentBalance = _PD.currentBalance.add(_amount);
        myPersonalSpaces[msg.sender][
            myPersonalSpaceIdx[msg.sender][_spaceId].sub(1)
        ].currentBalance = _PD.currentBalance.add(_amount);

        emit FundedPersonalSpace(msg.sender, _spaceId, _amount);

        //check if current balance is greater than goal amount and change state
        if (
            allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)]
                .currentBalance >=
            allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)].SD.goalAmount
        ) {
            allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)]
                .SS
                .currentFundState = FundsState.isFullyFunded;
            myPersonalSpaces[msg.sender][
                myPersonalSpaceIdx[msg.sender][_spaceId].sub(1)
            ].SS.currentFundState = FundsState.isFullyFunded;
        }
    }

    function _withdrawFromPersonalSpace(
        string memory _spaceId,
        uint256 _amount
    ) internal {
        require(personalSpaceIndex[_spaceId] != 0, "SpaceId does not exist");
        require(
            myPersonalSpaceIdx[msg.sender][_spaceId] != 0,
            "SpaceId does not exist"
        );
        PersonalDetails memory _PD = allPersonalSpaces[
            personalSpaceIndex[_spaceId].sub(1)
        ];
        require(_PD.SD.owner == msg.sender, "Must be owner");
        require(
            _PD.SS.currentActivityState == ActivityState.isActive,
            "Space must be active"
        );
        require(_PD.SD.goalAmount > 0, "Goal must be greater than 0");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            _PD.currentBalance >= _amount,
            "Amount must be less than current balance"
        );
        allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)]
            .currentBalance = _PD.currentBalance.sub(_amount);
        myPersonalSpaces[msg.sender][
            myPersonalSpaceIdx[msg.sender][_spaceId].sub(1)
        ].currentBalance = _PD.currentBalance.sub(_amount);

        require(_PD.SD.token.transfer(msg.sender, _amount), "Transfer failed");
        emit WithdrawnPersonalSpace(msg.sender, _spaceId, _amount);

        //check if current balance is less than goal amount and change state
        if (
            allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)]
                .currentBalance <
            allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)].SD.goalAmount
        ) {
            allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)]
                .SS = SpaceStates(
                FundsState.isFundable,
                ActivityState.isActive
            );
            myPersonalSpaces[msg.sender][
                myPersonalSpaceIdx[msg.sender][_spaceId].sub(1)
            ].SS = SpaceStates(FundsState.isFundable, ActivityState.isActive);
        }
    }

    function withdrawFromPersonalSpace(
        string memory _spaceId,
        uint256 _amount
    ) external {
        _withdrawFromPersonalSpace(_spaceId, _amount);
    }

    function closePersonalSpace(string memory _spaceId) external {
        require(personalSpaceIndex[_spaceId] != 0, "SpaceId does not exist");
        require(
            myPersonalSpaceIdx[msg.sender][_spaceId] != 0,
            "SpaceId does not exist"
        );
        PersonalDetails memory _PD = allPersonalSpaces[
            personalSpaceIndex[_spaceId].sub(1)
        ];
        require(_PD.SD.owner == msg.sender, "Must be owner");
        require(
            _PD.SS.currentActivityState == ActivityState.isActive,
            "Space must be active"
        );

        if (_PD.currentBalance > 0) {
            _withdrawFromPersonalSpace(_spaceId, _PD.currentBalance);
        }

        allPersonalSpaces[personalSpaceIndex[_spaceId].sub(1)]
            .SS
            .currentActivityState = ActivityState.isInActive;
        myPersonalSpaces[msg.sender][
            myPersonalSpaceIdx[msg.sender][_spaceId].sub(1)
        ].SS.currentActivityState = ActivityState.isInActive;

        emit ClosedPersonalSpace(msg.sender, _spaceId);
    }
}
