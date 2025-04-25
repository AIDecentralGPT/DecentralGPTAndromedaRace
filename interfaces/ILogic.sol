// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILogic {
    event Initialized(uint8 version);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function addMachineRegisteredProject(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId,
        string memory projectName
    ) external returns (bool);
    function getDlcMachineRentDuration(uint256 lastClaimAt, uint256 slashAt, string memory machineId)
        external
        view
        returns (uint256 rentDuration);
    function getDlcMachineSlashedAt(string memory machineId) external view returns (uint256);
    function getDlcMachineSlashedReportId(string memory machineId) external view returns (uint256);
    function getDlcMachineSlashedReporter(string memory machineId) external view returns (address);
    function getDlcNftStakingRewardStartAt(uint256 phaseLevel) external view returns (uint256);
    function getDlcStakingGPUCount(uint256 phaseLevel) external view returns (uint256, uint256);
    function getMachineCalcPoint(string memory machineId) external view returns (uint256);
    function getMachineGPUCount(string memory machineId) external view returns (uint256);
    function getOwnerRentEndAt(string memory machineId, uint256 rentId) external view returns (uint256);
    function getRentDuration(uint256 lastClaimAt, uint256 slashAt, uint256 endAt, string memory machineId)
        external
        view
        returns (uint256 rentDuration);
    function getRentingDuration(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId,
        uint256 rentId
    ) external view returns (uint256 duration);
    function getValidRewardDuration(uint256 lastClaimAt, uint256 totalStakeDuration, uint256 phaseLevel)
        external
        view
        returns (uint256 valid_duration);
    function initialize() external;
    function isMachineOwner(string memory machineId, address evmAddress) external view returns (bool);
    function isRegisteredMachineOwner(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId,
        string memory projectName
    ) external view returns (bool);
    function isSlashed(string memory machineId) external view returns (bool slashed);
    function machineIsRegistered(string memory machineId, string memory projectName) external view returns (bool);
    function owner() external view returns (address);
    function removalMachineRegisteredProject(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId,
        string memory projectName
    ) external returns (bool);
    function renounceOwnership() external;
    function reportDlcEndStaking(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId
    ) external returns (bool);
    function reportDlcNftEndStaking(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId,
        uint256 phaseLevel
    ) external returns (bool);
    function reportDlcNftStaking(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId,
        uint256 phaseLevel
    ) external returns (bool);
    function reportDlcStaking(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId
    ) external returns (bool);
    function transferOwnership(address newOwner) external;
}
