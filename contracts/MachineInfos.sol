

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";



contract MachineInfos is  OwnableUpgradeable  {


    struct MachineInfo {
        address machineOwner;
        uint calcPoint;
        uint cpuRate;
        string gpuType;
        uint gpuMem;
        string cpuType;
        uint gpuCount;
        string machineId;
        string longitude;
        string latitude;
        uint machineMem;
        string region;
        string model;
 

    }

    mapping (string => MachineInfo) public machineInfos;
    string public name;
    string public version;
    mapping(address => uint256) public nonces;
    mapping (address => bool) public operators;

 
    function initialize(

    ) public initializer {

        __Ownable_init();

        name = "gpt";
        version = "1";
     
        
    }


    modifier onlyOperator(){
        require(operators[msg.sender],"not ope"); 
        _;
    }

    function updateOperator(address _ope,bool _bool) external onlyOwner {
        operators[_ope]=_bool;
    }

    function getMachineInfo(string calldata _id,bool _isDeepLink) external view returns 
    (address machineOwner,uint256 calcPoint,uint256 cpuRate,
        string memory gpuType, uint256 gpuMem,string memory cpuType,uint gpuCount,string memory machineId,string memory longitude,string memory latitude,uint machineMem)
    {

        MachineInfo memory _info = machineInfos[_id];
        return (_info.machineOwner,_info.calcPoint,_info.cpuRate,_info.gpuType,_info.gpuMem,_info.cpuType,_info.gpuCount,_info.machineId,_info.longitude,_info.latitude,_info.machineMem);
    }

    function setMachineInfo(string calldata _Id,MachineInfo calldata _info) external onlyOperator {
        machineInfos[_Id] = MachineInfo({
            machineOwner:_info.machineOwner,
            calcPoint:_info.calcPoint,
            cpuRate:_info.cpuRate,
            gpuType:_info.gpuType,
            gpuMem:_info.gpuMem,
            cpuType:_info.cpuType,
            gpuCount:_info.gpuCount,
            machineId:_info.machineId,
            longitude:_info.longitude,
            latitude:_info.latitude,
            machineMem:_info.machineMem,
            region:_info.region,
            model:_info.model
        });


    }


   bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );


    bytes32 public constant VERIFY_TYPEHASH =
        keccak256(
            "Verify(address account,address signer,uint256 nonce,uint256 deadline)"
        );

  function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }




    function verify(
        address _signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint deadline
    ) external {
        require(block.timestamp <= deadline, "signature expired");

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                VERIFY_TYPEHASH,
                address(msg.sender),
                address(_signer),
                nonces[msg.sender]++,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "invalid signature");
        require(signatory == _signer, "unauthorized");
        
   
    }

    function getMachineRegion(string calldata _id) public view returns(string memory) {
         MachineInfo memory _info = machineInfos[_id];
         if(bytes(_info.region).length == 0){
            BandWidthMintInfo memory _infoBand = machineBandWidthInfos[_id];
            return _infoBand.region;
         }
         return _info.region;
    }


    function getMachineInfoTotal(string calldata _id,bool _isDeepLink) external view returns  (MachineInfo memory)
    {

        MachineInfo memory _info = machineInfos[_id];
        return _info;
    }


// v2
    struct BandWidthMintInfo {

        address machineOwner;
        string machineId;
        uint cpuCores;
  
        uint machineMem;
        string region;
        uint hdd;
        uint bandwidth;

    }

    mapping (string => BandWidthMintInfo) public machineBandWidthInfos;


    function setBandWidthInfos(string calldata _id,BandWidthMintInfo calldata _info) external onlyOperator {
        machineBandWidthInfos[_id] = _info;
    }

}
