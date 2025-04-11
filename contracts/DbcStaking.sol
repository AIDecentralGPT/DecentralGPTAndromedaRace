

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IMachineInfos.sol";


contract DbcStaking is  OwnableUpgradeable  {



    IMachineInfos public machineInfos;
// machineId or dockerId -> gpuCountUsed
    mapping (string => uint) public gpuUsed;

    mapping (address => bool) public operators;
    uint public dbcAmountForGpu;
    mapping (address => mapping (string => uint)) public amountStakeUsersForMachine;
    mapping (string => uint) public amountStakeMachines;
    mapping (address => uint) public amountStakeUsers;
    mapping (string => uint) public gpuAmounts;


 
    function initialize() public initializer {

        __Ownable_init();

        dbcAmountForGpu=1000e18;
        name = "gpt";
        version = "1";
    }

   
   function setMachineInfos(address _addr) external onlyOwner {
        machineInfos = IMachineInfos(_addr);
   }

   function  setDbcAmountForGpu(uint _amount) external onlyOwner {
        dbcAmountForGpu = _amount;
    }


    modifier onlyOperator(){
        require(operators[msg.sender],"not ope");
        _;
    }

    function updateOperator(address _ope,bool _bool) external onlyOwner {
        operators[_ope]=_bool;
    }

    
    function stakeDbc(string calldata _id,uint _amount) external payable {
        require(msg.value == _amount,"!eq");
        require(amountDbcCanStake(_id) >= _amount,"gt max");
        amountStakeUsersForMachine[msg.sender][_id] += _amount;
        amountStakeMachines[_id] += _amount;
        amountStakeUsers[msg.sender] += _amount;
        uint _newGpuAmount= amountStakeMachines[_id] / dbcAmountForGpu;
        if(gpuAmounts[_id] < _newGpuAmount){
            gpuAmounts[_id] = _newGpuAmount;
        }
    }

    function amountDbcCanStake(string calldata _id) public view returns(uint) {
       (,,,,,,uint gpuCount,,,,) =  machineInfos.getMachineInfo(_id,false);
       uint _total = gpuCount * dbcAmountForGpu;
       return _total <= amountStakeMachines[_id] ? 0 :_total - amountStakeMachines[_id];
    }

    function amountDbcStaked(string calldata _id) external view returns(uint){
        return amountStakeMachines[_id];
    }

    function amountUserStakedForMachine(string calldata _id,address _account) external view returns (uint){
        return amountStakeUsersForMachine[_account][_id];
    }

    function amountUserStaked(address _account) external view returns (uint){
        return amountStakeUsers[_account];
    }

    function canUnstake(string calldata _id) public view returns (bool){
        return gpuUsed[_id] ==0 ? true :false; 
    }

    function unstakeDbc(string calldata _id) external {
        require(canUnstake(_id),"!unstake");
        uint _amount =amountStakeUsersForMachine[msg.sender][_id];
        require(_amount > 0 ,"0");

        amountStakeUsersForMachine[msg.sender][_id]=0;
        amountStakeMachines[_id] -= _amount;
        amountStakeUsers[msg.sender] -= _amount;
         uint _newGpuAmount= amountStakeMachines[_id] / dbcAmountForGpu;
        if(gpuAmounts[_id] > _newGpuAmount){
            gpuAmounts[_id] = _newGpuAmount;
        }
        payable (msg.sender).transfer(_amount);



    }

    function reportStakingStatus(string calldata _id, uint256 gpuNum, bool isStake) external { //todo need Permissions
        require(operators[msg.sender],"not op");
        if(isStake){
            
            require(freeGpuAmount(_id) >= gpuNum,"insufficient");
            gpuUsed[_id] += gpuNum;
        }else {

            gpuUsed[_id] -= gpuNum;

           
        }

    }

    function freeGpuAmount(string calldata _id) public view returns (uint){
        
        return gpuAmounts[_id] - gpuUsed[_id];
            
        
    }

    //v2
    string public name;
    string public version;
    mapping(address => uint256) public nonces;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );


    bytes32 public constant VERIFY_TYPEHASH =
        keccak256(
            "Verify(address account,address signer,address wallet,string machineId,uint256 nonce,uint256 deadline)"
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
        string calldata _machineId,
        address _wallet,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint deadline
    ) external payable {
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
                address(_wallet),
                keccak256(bytes(_machineId)),
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
    //v3


      function stakeDbcForShortTerm(string calldata _id) external payable {
        require(msg.value == dbcAmountForGpu,"!eq");
        require(amountStakeMachines[_id] ==0,"staked");
        amountStakeUsersForMachine[msg.sender][_id] += dbcAmountForGpu;
        amountStakeMachines[_id] += dbcAmountForGpu;
        amountStakeUsers[msg.sender] += dbcAmountForGpu;
        uint _newGpuAmount= amountStakeMachines[_id] / dbcAmountForGpu;
        if(gpuAmounts[_id] < _newGpuAmount){
            gpuAmounts[_id] = _newGpuAmount;
        }
    }

 

}
