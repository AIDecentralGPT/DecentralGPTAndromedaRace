interface IAIProjectRegister {
    function machineIsRegistered(string memory machineId,string memory projectName) external view returns (bool isRegistered);
    function addMachineRegisteredProject(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId,string memory projectName) external returns (bool success);
    function removalMachineRegisteredProject(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId,string memory projectName) external returns (bool success);
    function isRegisteredMachineOwner(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId,string memory projectName) external view returns (bool isOwner);
}