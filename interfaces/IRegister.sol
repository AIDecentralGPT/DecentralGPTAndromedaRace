// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IRegister {
    function machineIsRegistered(string memory machineId, string memory projectName) external view returns (bool);
    function register(string memory _machineId, string memory _project, string memory _aiType) external;
    function registerInfo2AIType(string memory, string memory) external view returns (string memory);
}
