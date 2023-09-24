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

    function getRoscaSpaces() public view returns (Rosca[] memory) {
        return roscaSpaces;
    }

    function getRoscaSpacesByOwner(
        address _owner
    ) public view returns (Rosca[] memory) {
        return myRoscas[_owner];
    }

    function getRoscaSpaceByOwnernAddress(
        address _owner,
        address _roscaAddress
    ) public view returns (Rosca) {
        return myRoscas[_owner][myRoscasIdx[_owner][_roscaAddress]];
    }

    function getRoscaSpaceByAddress(
        address _roscaAddress
    ) public view returns (Rosca) {
        return roscaSpaces[roscaSpacesIndex[_roscaAddress]];
    }
}
