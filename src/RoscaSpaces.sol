//SPDX-License-Identifier: Apache 2.0
/**
@title Clixpesa RoSCA Spaces Contract
@author Dekan Kachi - @kachdekan
@notice Allow users to save in group with a rotating pot.
*/

pragma solidity 0.8.19;

import "./Rosca.sol";

contract RoscaSpaces {
    /// @notice RoscaSpaces structs

    /// @notice List of RoscaSpaces
    Rosca[] roscaSpaces;
    mapping(address => uint256) roscaSpacesIndex;
    mapping(address => Rosca[]) myRoscas;
    mapping(address => mapping(address => uint256)) myRoscasIdx;

    /// @notice RoscaSpaces events
    event RoscaSpaceCreated(
        address roscaAddress,
        address roscaCreator,
        string roscaName
    );

    /// @notice RoscaSpaces functions
    function createRoscaSpace(
        RoscaDetails memory _RD,
        string memory _aCode
    ) public {
        Rosca newRosca = new Rosca(_RD, _aCode, msg.sender);
        roscaSpaces.push(newRosca);
        roscaSpacesIndex[address(newRosca)] = roscaSpaces.length - 1;
        myRoscas[msg.sender].push(newRosca);
        myRoscasIdx[msg.sender][address(newRosca)] =
            myRoscas[msg.sender].length -
            1;
        emit RoscaSpaceCreated(address(newRosca), msg.sender, _RD.roscaName);
    }

    /// @notice Should end and archive RoscaSpace
    function endRoscaSpace(address _roscaAddress) public {
        Rosca rosca = Rosca(_roscaAddress);
        rosca.endRosca();
    }

    function getRoscaSpaces(
        uint _startIdx,
        uint _howMany
    ) public view returns (Rosca[] memory, uint newStartIdx) {
        uint length = _howMany;
        if (length > roscaSpaces.length - _startIdx) {
            length = roscaSpaces.length - _startIdx;
        }
        Rosca[] memory thisRoscaSpaces = new Rosca[](length);
        for (uint256 i = 0; i < length; i++) {
            thisRoscaSpaces[i] = roscaSpaces[_startIdx + i];
        }
        if (length < _howMany) {
            return (thisRoscaSpaces, 0);
        }
        return (thisRoscaSpaces, _startIdx + length);
    }

    function getRoscaSpacesByOwner(
        address _owner
    ) public view returns (Rosca[] memory) {
        //check if _owner is member of rosca
        Rosca[] memory roscaSpacesByOwner = myRoscas[_owner];
        for (uint256 i = 0; i < roscaSpacesByOwner.length; i++) {
            if (roscaSpacesByOwner[i].isMember(_owner) == false) {
                delete roscaSpacesByOwner[i];
            }
        }
        return roscaSpacesByOwner;
    }

    function getRoscaSpaceByOwnernAddress(
        address _owner,
        address _roscaAddress
    ) public view returns (Rosca) {
        require(
            myRoscasIdx[_owner][_roscaAddress] <= myRoscas[_owner].length - 1,
            "RoscaSpaces: RoscaSpace not found"
        );
        require(
            myRoscas[_owner][myRoscasIdx[_owner][_roscaAddress]] ==
                Rosca(_roscaAddress),
            "RoscaSpaces: RoscaSpace not found"
        );
        return myRoscas[_owner][myRoscasIdx[_owner][_roscaAddress]];
    }

    function getRoscaSpaceByAddress(
        address _roscaAddress
    ) public view returns (Rosca) {
        return roscaSpaces[roscaSpacesIndex[_roscaAddress]];
    }
}
