// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;



interface IMachineInfos {

      struct MachineInfo {
    address machineOwner;
        uint256 calcPoint;
        uint256 cpuRate;
        string gpuType;
        uint256 gpuMem;
        string cpuType;
        uint256 gpuCount;
        string machineId;
        string longitude;
        string latitude;
        uint256 machineMem;
        string region;
        string model;
    }

    event Initialized(uint8 version);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERIFY_TYPEHASH() external view returns (bytes32);
    function getMachineInfo(string memory _id, bool _isDeepLink)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            string memory,
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            string memory,
            uint256
        );
function getMachineInfoTotal(string memory _id, bool _isDeepLink)
        external
        view
        returns (MachineInfo memory);
    function getMachineRegion(string memory _id) external view returns (string memory);
    function initialize() external;
    function machineInfos(string memory)
        external
        view
        returns (
            address machineOwner,
            uint256 calcPoint,
            uint256 cpuRate,
            string memory gpuType,
            uint256 gpuMem,
            string memory cpuType,
            uint256 gpuCount,
            string memory machineId,
            string memory longitude,
            string memory latitude,
            uint256 machineMem,
            string memory region,
            string memory model
        );
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function operators(address) external view returns (bool);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function setMachineInfo(string memory _Id,MachineInfo memory _info) external;
    function transferOwnership(address newOwner) external;
    function updateOperator(address _ope, bool _bool) external;
    function verify(address _signer, uint8 v, bytes32 r, bytes32 s, uint256 deadline) external;
    function version() external view returns (string memory);
}
