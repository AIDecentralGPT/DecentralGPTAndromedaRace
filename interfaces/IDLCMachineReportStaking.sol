interface IDLCMachineReportStaking {
    function reportDlcStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external returns (bool success);
    function reportDlcEndStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external returns (bool success);
    function reportDlcNftStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId, uint256 phaseLevel) external returns (bool success);
    function reportDlcNftEndStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId, uint256 phaseLevel) external returns (bool success);
    function getValidRewardDuration(uint256 lastClaimAt,uint256 totalStakeDuration, uint256 phaseLevel) external view returns (uint256 validDuration);
    function getDlcNftStakingRewardStartAt(uint256 phaseLevel) external view returns (uint256);
    function getDlcStakingGPUCount(uint256 phaseLevel) external view returns (uint256,uint256);

}