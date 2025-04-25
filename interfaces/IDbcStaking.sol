// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IDbcStaking {
    event Initialized(uint8 version);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERIFY_TYPEHASH() external view returns (bytes32);
    function amountDbcCanStake(string memory _id) external view returns (uint256);
    function amountDbcStaked(string memory _id) external view returns (uint256);
    function amountStakeMachines(string memory) external view returns (uint256);
    function amountStakeUsers(address) external view returns (uint256);
    function amountStakeUsersForMachine(address, string memory) external view returns (uint256);
    function amountUserStaked(address _account) external view returns (uint256);
    function amountUserStakedForMachine(string memory _id, address _account) external view returns (uint256);
    function canUnstake(string memory _id) external view returns (bool);
    function dbcAmountForGpu() external view returns (uint256);
    function freeGpuAmount(string memory _id) external view returns (uint256);
    function gpuAmounts(string memory) external view returns (uint256);
    function gpuUsed(string memory) external view returns (uint256);
    function initialize() external;
    function machineInfos() external view returns (address);
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function operators(address) external view returns (bool);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function reportStakingStatus(string memory _id, uint256 gpuNum, bool isStake) external;
    function setDbcAmountForGpu(uint256 _amount) external;
    function setMachineInfos(address _addr) external;
    function stakeDbc(string memory _id, uint256 _amount) external payable;
    function stakeDbcForShortTerm(string memory _id) external payable;
    function transferOwnership(address newOwner) external;
    function unstakeDbc(string memory _id) external;
    function updateOperator(address _ope, bool _bool) external;
    function verify(
        address _signer,
        string memory _machineId,
        address _wallet,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) external payable;
    function version() external view returns (string memory);
}
