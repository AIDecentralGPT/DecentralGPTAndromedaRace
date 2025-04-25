interface IMachineInfo {
    function getMachineCalcPoint(string memory machineId) external view returns (uint256 calcPoint);
    function getRentDuration(uint256 lastClaimAt,uint256 slashAt,uint256 endAt, string memory machineId) external view returns (uint256 rentDuration);
    function getDlcMachineRentDuration(uint256 lastClaimAt,uint256 slashAt, string memory machineId) external view returns (uint256 rentDuration);
    function getRentingDuration(string memory msgToSign,string memory substrateSig,string memory substratePubKey, string memory machineId, uint256 rentId) external view returns (uint256 duration);
}