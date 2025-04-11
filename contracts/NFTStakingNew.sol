

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPrecompileContract.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../library/Ln.sol";
import "../interfaces/IStateContract.sol";
import "../interfaces/ILogic.sol";
import "../interfaces/IMachineInfos.sol";

/// @custom:oz-upgrades-from NFTStakingOld
contract NFTStaking is  OwnableUpgradeable, ReentrancyGuardUpgradeable {

    struct StakeInfo {
        address holder;
        uint256 startAtBlockNumber;
        uint256 lastClaimAtBlockNumber;
        uint256 endAtBlockNumber;
        uint256 calcPoint;
        uint256 reservedAmount;
        uint256 rentId;
        uint256 lnResultNumerator;
        uint256 lnResultDenominator;
        uint256 claimedAmount;
        uint rewardForStake;
        bool isStaking;

    }

    struct LockedRewardDetail {
        uint256 amountReleaseDaily;
        uint256 lockStartBlock;
        uint claimedDay;
    }

    struct RewardInfo {
        uint releaseRate;
        uint lastClaimAt;
        uint rewardUnlockAmount;
        uint rewardLockedAmount;
    }
      

    
    ILogic public logic;
    IERC20 public rewardToken;
    IERC1155 public nftToken;
    IMachineInfos public machineInfos;
  
    uint public token1155Id;
    string public projectName;
    uint256 public startAt;
    uint8 public  secondsPerBlock ;

    uint256 public rewardAmountPerSecond;
    uint256 public  baseReserveAmount ;

    uint256 public nonlinearCoefficientNumerator;
    uint256 public nonlinearCoefficientDenominator;

    string[] public machineIds;
    uint256 public totalReservedAmount;
    mapping (string => bool) public isMachineStaked;
    mapping(address => mapping (string => uint)) public stakeholder2Reserved;
    
    mapping(string => address) public machineId2Address;

    mapping (string => mapping (address => uint)) public nftStakeIds;

    mapping(string =>uint) public machineIdx;

    mapping(address => uint8) public walletAddress2StakingMachineCount;

    mapping(address => bool) public addressInStaking;

    mapping(string => mapping (string => mapping (address => StakeInfo))) public machineId2StakeInfos;

    mapping(string =>mapping (address => LockedRewardDetail[])) public machineId2LockedRewardDetails;

    uint8 public  MAX_NFTS_PER_MACHINE ;
    
    uint public dailyRewardBase;
    mapping (string  => uint) public rewardRateBase;
    mapping (string => uint) public lastUpdateTime;
    mapping (string => uint) public rewardPerBasePointStored;
    
    uint public totalGpuCount;
    mapping (string  => uint) public totalBasePoint;
    //dockerId -> model 
    mapping(string => mapping (string => mapping (address => uint))) public machineRewardPerBasePointPaid;
    mapping(string => mapping (string => mapping (address => uint))) public rewardsBase;
    mapping(string => mapping (string => mapping (address => uint))) public balanceBasePoint;

    uint public periodFinish;
    uint public gpuCountStartRequired;

    uint public stakingThresholdAmount;
    uint256 public  REWARD_DURATION ; 

    uint256 public  LOCK_PERIOD_DAY ;
    uint8 public  DAILY_UNLOCK_RATE ; // 10000
    uint256 public  SECONDS_PER_DAY ;
    uint public numberPerDay;

    uint8 public phaseLevel;

    uint256 public addressCountInStaking;

    mapping (string => uint) public modelWeights;


    event nonlinearCoefficientChanged(uint256 nonlinearCoefficientNumerator, uint256 nonlinearCoefficientDenominator);

    event staked(address indexed stakeholder, string dockerId, uint256 stakeAtBlockNumber);
    event unStaked(address indexed stakeholder, string dockerId, uint256 unStakeAtBlockNumber);
    event claimed(
        address indexed stakeholder,
        string dockerId,
        uint256 rewardAmount,
        uint256 claimAtBlockNumber
    );
    event claimedAll(address indexed stakeholder, uint256 claimAtBlockNumber);
    event rewardTokenSet(address indexed addr);
    event nftTokenSet(address indexed addr);
 
    function initialize(
        address _nftToken,
        address _rewardToken,
        uint8 _phase_level,
        address _logic,
        address _machineInfos,
        string[] memory _models,
        uint[] memory _weights
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        token1155Id = 0;
        projectName = "gpt";
        secondsPerBlock = 6;
        baseReserveAmount = 10_000 * 10 ** 18;
        MAX_NFTS_PER_MACHINE = 10;
        REWARD_DURATION = 60 days;
        LOCK_PERIOD_DAY = 180;
        DAILY_UNLOCK_RATE = 50;
        SECONDS_PER_DAY = 1 days;
        numberPerDay = 86400/secondsPerBlock;
           
        nftToken = IERC1155(_nftToken);
        machineInfos = IMachineInfos(_machineInfos);
        
        phaseLevel = _phase_level;
        nonlinearCoefficientNumerator = 1;
        nonlinearCoefficientDenominator = 10;
        stakingThresholdAmount = 100000e18;

        logic = ILogic(_logic);
        if (phaseLevel == 1) {
            
            dailyRewardBase = 86400e18; //250000000e18;
            for(uint i;i<_models.length;i++){
                rewardRateBase[_models[i]] = dailyRewardBase * _weights[i]/10000/1 days;
            }
           
            gpuCountStartRequired = 2; // 200;
        }
        if (phaseLevel == 2) {
            
            dailyRewardBase = 500000000e18;
            
            for(uint i;i<_models.length;i++){
                rewardRateBase[_models[i]] = dailyRewardBase * _weights[i]/10000/1 days;
            }
           
            gpuCountStartRequired = 400;
        }
  

        
        rewardToken = IERC20(_rewardToken);
        

        
    }

    function updateReward(string memory _machine,string memory _model,address _account) private {
        if(startAt ==0){
            return;
        }


        rewardPerBasePointStored[_model] = rewardPerBasePoint(_model);


        rewardsBase[_machine][_model][_account] = earnedBase(_machine,_model,_account);

        machineRewardPerBasePointPaid[_machine][_model][_account] = rewardPerBasePointStored[_model];

        lastUpdateTime[_model] = lastTimeRewardApplicable();
    }

    function rewardPerBasePoint(string memory _model) public view returns (uint256) {
        if (lastUpdateTime[_model] == 0 ) {
            return rewardPerBasePointStored[_model];
        }
        if(totalBasePoint[_model] > 0){
            return rewardPerBasePointStored[_model] + ( (lastTimeRewardApplicable()- lastUpdateTime[_model]) *rewardRateBase[_model] * 1e18 /totalBasePoint[_model]);

        }

        return rewardPerBasePointStored[_model];
    }



    function earnedBase(string memory _machine,string memory _model,address _account) public view returns (uint256) {
        if(lastUpdateTime[_model] == 0){
            return 0;
        }
        return
            balanceBasePoint[_machine][_model][_account]*(rewardPerBasePoint(_model) - machineRewardPerBasePointPaid[_machine][_model][_account])/1e18 + rewardsBase[_machine][_model][_account] ;
    }


    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp > periodFinish ? periodFinish : block.timestamp;
    }



    function claimLeftRewardTokens() external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, balance);
    }

    function setRewardToken(address token) external onlyOwner {
        rewardToken = IERC20(token);
        emit rewardTokenSet(token);
    }

    function setNftToken(address token) external onlyOwner {
        nftToken = IERC1155(token);
        emit nftTokenSet(token);
    }

    function setNonlinearCoefficient(uint256 numerator, uint256 denominator) public onlyOwner {
        nonlinearCoefficientNumerator = numerator;
        nonlinearCoefficientDenominator = denominator;

        emit nonlinearCoefficientChanged(numerator, denominator);
    }

    function updateModelRewardRate(   string[] calldata _models,uint[] calldata _weights) external onlyOwner {
        for(uint i;i<_models.length;i++){
                rewardRateBase[_models[i]] = dailyRewardBase * _weights[i]/10000/1 days;
        }
           
    }

   


    function stake(
        string calldata machineId,
        string calldata dockerId,
        uint256 amountDgc,
        uint256 amountNft,
        uint256 rentId
    ) external nonReentrant {
        
       
        require(logic.getOwnerRentEndAt(machineId,rentId) > block.number,"not rent");
        // uint gpuCount = logic.getMachineGPUCount(machineId);   
        IMachineInfos.MachineInfo memory _infos = machineInfos.getMachineInfoTotal(dockerId,false);
         require(_infos.machineOwner  == msg.sender,"not owner");
        uint gpuCount = _infos.gpuCount;

        totalGpuCount += gpuCount;
        if (startAt > 0 ) {
            require(block.timestamp < periodFinish, "staking ended");
          
        }else {
            if(totalGpuCount >= gpuCountStartRequired){
                startAt = block.timestamp;
                periodFinish = startAt + REWARD_DURATION;
            }
        }


        address stakeholder = msg.sender;


        string memory _model = _infos.model;
        StakeInfo storage stakeInfo = machineId2StakeInfos[dockerId][_model][msg.sender];

        require(stakeholder != address(0), "invalid stakeholder address");
        require(!stakeInfo.isStaking, "machine already staked");
        require(amountNft > 0 && amountNft <= MAX_NFTS_PER_MACHINE, "nft len error");
        uint256 calcPoint = _infos. calcPoint  * amountNft;
        require(calcPoint > 0, "machine calc point not found");

         //update last reward

        updateReward(dockerId,_model,msg.sender);
     
     
        // *ln
        (uint _lnFactor,) = lnResult(amountDgc > stakingThresholdAmount ? amountDgc : stakingThresholdAmount);

        totalBasePoint[_model] += calcPoint * _lnFactor;
        balanceBasePoint[dockerId][_model][msg.sender] += calcPoint * _lnFactor;

        if (amountDgc > 0) {
            stakeholder2Reserved[stakeholder][dockerId] += amountDgc;
            totalReservedAmount += amountDgc;
            rewardToken.transferFrom(stakeholder, address(this), amountDgc);
        }
        // for (uint256 i = 0; i < amountNft; i++) {
            nftToken.safeTransferFrom(msg.sender, address(this),token1155Id, amountNft,"");
        // }

        // for(uint i;i< nftTokenIds.length;i++){
            nftStakeIds[dockerId][msg.sender] += amountNft;
        // }
  
        uint256 currentTime = block.number;
        machineId2StakeInfos[dockerId][_model][msg.sender] = StakeInfo({
            startAtBlockNumber: currentTime,
            lastClaimAtBlockNumber: currentTime,
            endAtBlockNumber: 0,
            calcPoint: calcPoint,
            reservedAmount: amountDgc,
            rentId: rentId,
            holder: stakeholder,
            lnResultNumerator: _lnFactor,
            lnResultDenominator: 1e18,
            claimedAmount: 0,
            rewardForStake:0,
            isStaking:true
        });

        machineId2Address[dockerId] = stakeholder;


        uint256 stakedMachineCount = walletAddress2StakingMachineCount[stakeholder];
        if (stakedMachineCount == 0) {
            addressInStaking[stakeholder] = true;
            addressCountInStaking += 1;
        }
        
        walletAddress2StakingMachineCount[stakeholder] += 1;
        
        machineIdx[dockerId]= machineIds.length;
        machineIds.push(dockerId);
       
   
        isMachineStaked[dockerId] = true;
        
        emit staked(stakeholder, dockerId, currentTime);
    }


    function lnResult(uint _amount) public pure returns (uint,uint){
        return LogarithmLibrary.lnAsFraction(_amount, 1e18);

    }

 

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {

        return this.onERC1155Received.selector;
    }


    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {

        return this.onERC1155BatchReceived.selector;
    }

    function getRewardLocked(string memory dockerId,address _account) public view returns(uint){
         IMachineInfos.MachineInfo memory _infos = machineInfos.getMachineInfoTotal(dockerId,false);

        string memory _model = _infos.model;

        uint _reward = earnedBase(dockerId,_model,_account);


        (, uint256 lockedAmount) = _getRewardDetail(_reward);
        uint256 _amountLocked= _calculateLockedReward(dockerId);
        return lockedAmount + _amountLocked;
    }

    function _getRewardDetail(uint256 totalRewardAmount)
        internal
        pure
        returns (uint256 canClaimAmount, uint256 lockedAmount)
    {
        uint256 releaseImmediateAmount = totalRewardAmount / 10;
        uint256 releaseLinearLockedAmount = totalRewardAmount - releaseImmediateAmount;
        return (releaseImmediateAmount, releaseLinearLockedAmount);
    }

   
// /**
//  * 
//  * @param dockerId 
//  * @param _account 
//  * @return all released
//  * @return available
//  */

    function getReward(string memory dockerId,address _account) public view returns (uint256,uint) {
         IMachineInfos.MachineInfo memory _infos = machineInfos.getMachineInfoTotal(dockerId,false);

        string memory _model = _infos.model;

        StakeInfo memory stakeInfo = machineId2StakeInfos[dockerId][_model][_account];

        uint _reward = earnedBase(dockerId,_model,_account);

        
        (uint256 canClaimAmount, ) = _getRewardDetail(_reward);
        uint256 _dailyReleaseAmount= _calculateReleaseReward(dockerId);
        canClaimAmount += _dailyReleaseAmount;
        uint rewardAvailable;

        if (stakeInfo.reservedAmount >= stakingThresholdAmount || stakeInfo.reservedAmount + stakeInfo.rewardForStake >= stakingThresholdAmount) {
    
            rewardAvailable = canClaimAmount;
        }else {
            uint _forStake = stakingThresholdAmount - stakeInfo.reservedAmount - stakeInfo.rewardForStake ;
            if(canClaimAmount > _forStake ){
          
                rewardAvailable = canClaimAmount - _forStake;
            }
        }

        return (canClaimAmount,rewardAvailable);

    }

     
    function claim(
        
        string memory dockerId
    ) public canClaim(dockerId)  {
        address stakeholder = msg.sender;
         IMachineInfos.MachineInfo memory _infos = machineInfos.getMachineInfoTotal(dockerId,false);

        string memory _model = _infos.model;

        StakeInfo storage stakeInfo = machineId2StakeInfos[dockerId][_model][msg.sender];
      
        require(
            (block.number - stakeInfo.lastClaimAtBlockNumber) * secondsPerBlock >= 60,
            "last claim less than 1 day"
        );
    
        stakeInfo.lastClaimAtBlockNumber = block.number;

        updateReward(dockerId,_model,msg.sender);

        
        (uint256 canClaimAmount, uint256 lockedAmount) = _getRewardDetail(rewardsBase[dockerId][_model][msg.sender]);
        uint256 _dailyReleaseAmount= _calculateReleaseRewardAndUpdate(dockerId);
  
        canClaimAmount += _dailyReleaseAmount;

        if (stakeInfo.reservedAmount >= stakingThresholdAmount || stakeInfo.reservedAmount + stakeInfo.rewardForStake >= stakingThresholdAmount) {
    
            rewardToken.transfer(stakeholder, canClaimAmount);
        }else {
            uint _forStake = stakingThresholdAmount - stakeInfo.reservedAmount - stakeInfo.rewardForStake ;
            
            if(canClaimAmount > _forStake ){
                rewardToken.transfer(stakeholder, canClaimAmount - _forStake);
                stakeInfo.rewardForStake += _forStake;
                
            }else{
                stakeInfo.rewardForStake += canClaimAmount;
            }
        }
         
        rewardsBase[dockerId][_model][msg.sender] = 0;

        
        machineId2LockedRewardDetails[dockerId][msg.sender].push(
            LockedRewardDetail({amountReleaseDaily: lockedAmount/LOCK_PERIOD_DAY, lockStartBlock: block.number,claimedDay:0})
        );
        

        emit claimed(stakeholder, dockerId, canClaimAmount, block.number);
    }

    modifier canClaim(string memory dockerId) {
        require(startAt > 0,"not begin");
        _;
    }

    function _calculateReleaseReward(string memory dockerId)
        internal
        view
        returns (uint256 )
    {
        LockedRewardDetail[] memory lockedRewardDetails = machineId2LockedRewardDetails[dockerId][msg.sender];
        uint256 _unlockAmount = 0;

        for (uint256 i = 0; i < lockedRewardDetails.length; i++) {
            uint _days = (block.number - lockedRewardDetails[i].lockStartBlock)/ numberPerDay;
            if(_days <= lockedRewardDetails[i].claimedDay || lockedRewardDetails[i].claimedDay >= LOCK_PERIOD_DAY){
                continue;
            }

            uint _dayUnclaim = _days >= LOCK_PERIOD_DAY  ? LOCK_PERIOD_DAY - lockedRewardDetails[i].claimedDay : _days - lockedRewardDetails[i].claimedDay;
            
            _unlockAmount += _dayUnclaim * lockedRewardDetails[i].amountReleaseDaily;
            
       
        }
        return _unlockAmount;
    }



    function _calculateReleaseRewardAndUpdate(string memory dockerId)
        internal
        returns (uint256 )
    {
        LockedRewardDetail[] memory lockedRewardDetails = machineId2LockedRewardDetails[dockerId][msg.sender];
        uint256 _unlockAmount = 0;

        for (uint256 i = 0; i < lockedRewardDetails.length; i++) {
            uint _days = (block.number - lockedRewardDetails[i].lockStartBlock)/ numberPerDay;
            if(_days <= lockedRewardDetails[i].claimedDay || lockedRewardDetails[i].claimedDay >= LOCK_PERIOD_DAY){
                continue;
            }

            uint _dayUnclaim = _days >= LOCK_PERIOD_DAY  ? LOCK_PERIOD_DAY - lockedRewardDetails[i].claimedDay : _days - lockedRewardDetails[i].claimedDay;
            
            _unlockAmount += _dayUnclaim * lockedRewardDetails[i].amountReleaseDaily;
            
 
            machineId2LockedRewardDetails[dockerId][msg.sender][i].claimedDay += _dayUnclaim;
                
        }
        return _unlockAmount;
    }


    function _calculateLockedReward(string memory dockerId)
        internal
        view
        returns (uint256 )
    {
        LockedRewardDetail[] memory lockedRewardDetails = machineId2LockedRewardDetails[dockerId][msg.sender];
        uint256 _lockedAmount = 0;

        for (uint256 i = 0; i < lockedRewardDetails.length; i++) {
            uint _days = (block.number - lockedRewardDetails[i].lockStartBlock)/ numberPerDay;
            if( _days >= LOCK_PERIOD_DAY){
                continue;
            }

            uint _dayUnclaim = LOCK_PERIOD_DAY - _days;
            
            _lockedAmount += _dayUnclaim * lockedRewardDetails[i].amountReleaseDaily;
            
            
        }
        return _lockedAmount;
    }

    function unStakeAndClaim(
        
        string calldata dockerId
    ) external nonReentrant {
        address stakeholder = msg.sender;
         IMachineInfos.MachineInfo memory _infos = machineInfos.getMachineInfoTotal(dockerId,false);

        string memory _model = _infos.model;

        StakeInfo storage stakeInfo = machineId2StakeInfos[dockerId][_model][stakeholder];

        require(stakeInfo.isStaking, "no staking");
       
        _unStakeAndClaim( dockerId, stakeholder,_model);

    }

    function _unStakeAndClaim(
   
        string calldata dockerId,
        address stakeholder,
        string memory _model
    ) internal {
        claim( dockerId);
        StakeInfo storage stakeInfo = machineId2StakeInfos[dockerId][_model][stakeholder];


        uint256 reservedAmount = stakeholder2Reserved[stakeholder][dockerId];
        uint rewardStaking = stakeInfo.rewardForStake;
        if (reservedAmount  + rewardStaking > 0) {
            stakeholder2Reserved[stakeholder][dockerId] = 0;
            stakeInfo.rewardForStake = 0;
            rewardToken.transfer(stakeholder, reservedAmount + rewardStaking);
            
            totalReservedAmount -= reservedAmount;
           
        }

        uint256 currentTime = block.number;
        stakeInfo.endAtBlockNumber = currentTime;
        stakeInfo.isStaking = false;
        
        totalBasePoint[_model] -= balanceBasePoint[dockerId][_model][stakeholder];

        balanceBasePoint[dockerId][_model][stakeholder] =0;

   
        nftToken.safeTransferFrom(address(this), msg.sender,token1155Id, nftStakeIds[dockerId][msg.sender],"");


        nftStakeIds[dockerId][msg.sender] =0;
  
        // delete  nftStakeIds[dockerId][msg.sender];

        uint _machineIdx = machineIdx[dockerId];
        string memory _lastOne = machineIds[machineIds.length - 1];
        machineIds[_machineIdx] = _lastOne;
        machineIdx[_lastOne]  = _machineIdx;

        machineIds.pop();

        isMachineStaked[dockerId] = false;


        uint256 stakedMachineCount = walletAddress2StakingMachineCount[stakeholder];
        
        if (stakedMachineCount == 1) {
            addressInStaking[stakeholder] = false;
            addressCountInStaking -= 1;
        }
        walletAddress2StakingMachineCount[stakeholder] -= 1;
        

        emit unStaked(msg.sender, dockerId, currentTime);
    }

    function getMachineHolder(string calldata dockerId) external view returns (address) {
        return machineId2Address[dockerId];
    }

    function isMachineStaking(string calldata dockerId,address _account) public view returns (bool) {
         IMachineInfos.MachineInfo memory _infos = machineInfos.getMachineInfoTotal(dockerId,false);

        string memory _model = _infos.model;

        return machineId2StakeInfos[dockerId][_model][_account].isStaking;
        
    }



     function isStaking(string calldata dockerId) external view returns (bool){
        return isMachineStaked[dockerId];
     }

    function getTotalCalcPointAndReservedAmount(string calldata _model) external view returns (uint256, uint256){
        return (totalBasePoint[_model],totalReservedAmount);
    }

    function machineLen() public view returns(uint){
        return machineIds.length;
    }

    function getTotalGPUCountInStaking() public view returns (uint){
        return totalGpuCount;
    }

    function getLeftGPUCountToStartReward() public view returns(uint){
        return totalGpuCount >= gpuCountStartRequired ? 0 : gpuCountStartRequired - totalGpuCount;
    }

    

    function addNFTs(string calldata dockerId, uint256 _amountNft) external {
         IMachineInfos.MachineInfo memory _infos = machineInfos.getMachineInfoTotal(dockerId,false);

        string memory _model = _infos.model;
        StakeInfo storage stakeInfo = machineId2StakeInfos[dockerId][_model][msg.sender];
        require(stakeInfo.isStaking, "no staking");
        require(nftStakeIds[dockerId][msg.sender] + _amountNft <= MAX_NFTS_PER_MACHINE, "too many nfts, max is 20");
  
        nftToken.safeTransferFrom(msg.sender, address(this),token1155Id,_amountNft, "");
        nftStakeIds[dockerId][msg.sender] += _amountNft;


        updateReward(dockerId,_model,msg.sender);
    
 
        uint256 newCalcPoint =_infos. calcPoint  * nftStakeIds[dockerId][msg.sender];

        totalBasePoint[_model] -= balanceBasePoint[dockerId][_model][msg.sender];

        totalBasePoint[_model] += newCalcPoint * stakeInfo.lnResultNumerator;
        balanceBasePoint[dockerId][_model][msg.sender] = newCalcPoint * stakeInfo.lnResultNumerator;


        stakeInfo.calcPoint = newCalcPoint;
    }

    function reservedNFTs(string calldata dockerId,address _account) public view returns (uint256) {

        return nftStakeIds[dockerId][_account];
    }

    



}
