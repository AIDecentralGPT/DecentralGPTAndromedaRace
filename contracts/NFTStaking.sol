

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPrecompileContract.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../library/Ln.sol";
import "../interfaces/IStateContract.sol";
import "../interfaces/ILogic.sol";

/// @custom:oz-upgrades-from NFTStakingOld
contract NFTStaking is  OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // IStateContract public stateContract;
    // IPrecompileContract public precompileContract;
    uint8 public  secondsPerBlock ;
    IERC20 public rewardToken;

    uint256 public rewardAmountPerSecond;
    uint256 public  baseReserveAmount ;

    uint256 public nonlinearCoefficientNumerator;
    uint256 public nonlinearCoefficientDenominator;

    string[] public machineIds;
    mapping (string => bool) public isMachineInclude;
    mapping (string => bool) public isMachineStaked;
    mapping(address => mapping (string => uint)) public stakeholder2Reserved;
    uint256 public totalReservedAmount;
    mapping(string => address) public machineId2Address;
    uint256 public startAt;
    mapping (string => mapping (address => uint[]) ) public nftStakeIds;

    uint256 public totalCalcPoint;

    ILogic public logic;

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

  
    mapping(address => uint8) public walletAddress2StakingMachineCount;

    mapping(address => bool) public addressInStaking;

    mapping(string => mapping (address => StakeInfo)) public machineId2StakeInfos;

    IERC721 public nftToken;

    struct LockedRewardDetail {
        uint256 amountReleaseDaily;
        uint256 lockStartBlock;
        uint claimedDay;
    }

    mapping(string =>mapping (address => LockedRewardDetail[])) public machineId2LockedRewardDetails;

    uint8 public  MAX_NFTS_PER_MACHINE ;
    // uint256 public daily_reward;
    uint public dailyRewardBase;
    // uint public dailyRewardNonlinear;
    uint public rewardRateBase;
    // uint public rewardRateNonlinear;
    uint public lastUpdateTime;
    uint public rewardPerBasePointStored;
    // uint public rewardPerNonliearPointStored;

    uint public totalGpuCount;

    struct RewardInfo {
            uint releaseRate;
            uint lastClaimAt;
            uint rewardUnlockAmount;
            uint rewardLockedAmount;
    }
      

    //   mapping (string => RewardInfo) public rewards;

    mapping(string => mapping (address => uint)) public machineRewardPerBasePointPaid;
    // mapping(address => uint) public userRewardPerNonlinearPointPaid;
    mapping(string => mapping (address => uint)) public rewardsBase;
    //  mapping(address => uint) public rewardsNonlinear;

    uint public totalBasePoint;
    mapping(string => mapping (address => uint)) public balanceBasePoint;
    // uint public totalNonlinearPoint;
    // mapping (address => uint) public balanceNonlinearPoint;
    uint public periodFinish;
    uint public gpuCountStartRequired;

    uint public stakingThresholdAmount;

    //    uint256 public constant REWARD_DURATION = 60 days;
    uint256 public  REWARD_DURATION ; //todo: change to 60 days

    uint256 public  LOCK_PERIOD_DAY ;
    uint8 public  DAILY_UNLOCK_RATE ; // 0.5% = 5/1000
    uint256 public  SECONDS_PER_DAY ;
    uint public numberPerDay;

   
    uint8 public phaseLevel;

    uint256 public addressCountInStaking;


    event nonlinearCoefficientChanged(uint256 nonlinearCoefficientNumerator, uint256 nonlinearCoefficientDenominator);

    event staked(address indexed stakeholder, string machineId, uint256 stakeAtBlockNumber);
    event unStaked(address indexed stakeholder, string machineId, uint256 unStakeAtBlockNumber);
    event claimed(
        address indexed stakeholder,
        string machineId,
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
        address _logic
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        secondsPerBlock = 6;
        baseReserveAmount = 10_000 * 10 ** 18;
         MAX_NFTS_PER_MACHINE = 20;
          REWARD_DURATION = 60 days;
          LOCK_PERIOD_DAY = 180;
           DAILY_UNLOCK_RATE = 5;
           SECONDS_PER_DAY = 1 days;
           numberPerDay = 86400/secondsPerBlock;
           
        nftToken = IERC721(_nftToken);
        // stateContract = IStateContract(_stateContract);
        phaseLevel = _phase_level;
        nonlinearCoefficientNumerator = 1;
        nonlinearCoefficientDenominator = 10;
        stakingThresholdAmount = 100000e18;

        logic = ILogic(_logic);
        if (phaseLevel == 1) {
            // daily_reward = 6000000 * 1e18;
            dailyRewardBase = 3000000e18;
            // dailyRewardNonlinear = 3000000e18;
            rewardRateBase = dailyRewardBase/1 days;
            // rewardRateNonlinear = dailyRewardNonlinear/ 1 days;
            gpuCountStartRequired = 2; // 200;
        }
        if (phaseLevel == 2) {
            // daily_reward = 8000000 * 1e18;
            dailyRewardBase = 4000000e18;
            // dailyRewardNonlinear = 4000000e18;
            rewardRateBase = dailyRewardBase/1 days;
            // rewardRateNonlinear = dailyRewardNonlinear/ 1 days;
            gpuCountStartRequired = 400;
        }
  

        
            rewardToken = IERC20(_rewardToken);
        

        
    }

      function updateReward(string memory _machine,address _account) private {
        if(startAt ==0){
            return;
        }

        // RewardInfo storage _reward = rewards[_machine];
        rewardPerBasePointStored = rewardPerBasePoint();
        // rewardPerNonliearPointStored = rewardPerNonlinearPoint();

       
        // if (_mechine != 0) {
            rewardsBase[_machine][_account] = earnedBase(_machine,_account);
            // uint _lastRelease = (block.timestamp - _reward.lastClaimAt)*_reward.releaseRate > _reward.rewardLockedAmount ? _reward.rewardLockedAmount : (block.timestamp - _reward.lastClaimAt)*_reward.releaseRate;
            // _reward.lastClaimAt = block.timestamp;
            // _reward.rewardLockedAmount = (_reward.rewardLockedAmount - _lastRelease) + _newReward * 9 /10;
            // _reward.rewardUnlockAmount += _lastRelease + _newReward / 10;

            // _reward.releaseRate = _reward.rewardLockedAmount/180 days;

            machineRewardPerBasePointPaid[_machine][_account] = rewardPerBasePointStored;

            // rewardsNonlinear[account] = earnedNonlinear(account);
            // userRewardPerNonlinearPointPaid[account] = rewardPerNonliearPointStored;
        // }

         lastUpdateTime = lastTimeRewardApplicable();
    }

    function rewardPerBasePoint() public view returns (uint256) {
        if (lastUpdateTime == 0 ) {
            return rewardPerBasePointStored;
        }
        return
            rewardPerBasePointStored + ( (lastTimeRewardApplicable()- lastUpdateTime) *rewardRateBase * 1e18 /totalBasePoint);
    }

//  function rewardPerNonlinearPoint() public view returns (uint256) {
//         if (totalNonlinearPoint == 0 ) {
//             return rewardPerNonliearPointStored;
//         }
//         return
//             rewardPerNonliearPointStored + ( (lastTimeRewardApplicable()- lastUpdateTime) *rewardRateNonlinear * 1e18 /totalNonlinearPoint);
//     }

    function earnedBase(string memory _machine,address _account) public view returns (uint256) {
        if(lastUpdateTime == 0){
            return 0;
        }
        return
            balanceBasePoint[_machine][_account]*(rewardPerBasePoint() - machineRewardPerBasePointPaid[_machine][_account])/1e18 + rewardsBase[_machine][_account] ;
    }

    //   function earnedNonlinear(address account) public view returns (uint256) {
    //     return
    //         balanceNonlinearPoint[account]*(rewardPerNonlinearPoint() - userRewardPerNonlinearPointPaid[account])/1e18 +rewardsNonlinear[account];
    // }


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
        nftToken = IERC721(token);
        emit nftTokenSet(token);
    }

    function setNonlinearCoefficient(uint256 numerator, uint256 denominator) public onlyOwner {
        nonlinearCoefficientNumerator = numerator;
        nonlinearCoefficientDenominator = denominator;

        emit nonlinearCoefficientChanged(numerator, denominator);
    }



    function stake(
        
        string calldata machineId,
        uint256 amount,
        uint256[] calldata nftTokenIds,
        uint256 rentId
    ) external nonReentrant {
        
        require(logic.isMachineOwner(machineId,msg.sender),"not owner");
        require(logic.getOwnerRentEndAt(machineId,rentId) > block.number,"not rent");
        uint gpuCount = logic.getMachineGPUCount(machineId);   
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

         StakeInfo storage stakeInfo = machineId2StakeInfos[machineId][msg.sender];

        require(stakeholder != address(0), "invalid stakeholder address");
        require(!stakeInfo.isStaking, "machine already staked");
        require(nftTokenIds.length > 0 && nftTokenIds.length <= MAX_NFTS_PER_MACHINE, "nft len error");
        uint256 calcPoint =logic. getMachineCalcPoint(machineId) * nftTokenIds.length;
        require(calcPoint > 0, "machine calc point not found");

         //update last reward

         updateReward(machineId,msg.sender);
     
     
        // *ln
       ( uint _lnFactor,) = lnResult(amount > stakingThresholdAmount ? amount : stakingThresholdAmount);

        totalBasePoint += calcPoint * _lnFactor;
        balanceBasePoint[machineId][msg.sender] += calcPoint * _lnFactor;

 

        if (amount > 0) {
            stakeholder2Reserved[stakeholder][machineId] += amount;
            totalReservedAmount += amount;
            rewardToken.transferFrom(stakeholder, address(this), amount);
        }
        for (uint256 i = 0; i < nftTokenIds.length; i++) {
            nftToken.transferFrom(msg.sender, address(this), nftTokenIds[i]);
        }

        for(uint i;i< nftTokenIds.length;i++){
            nftStakeIds[machineId][msg.sender].push(nftTokenIds[i]);
        }
  
        uint256 currentTime = block.number;
        machineId2StakeInfos[machineId][msg.sender] = StakeInfo({
            startAtBlockNumber: currentTime,
            lastClaimAtBlockNumber: currentTime,
            endAtBlockNumber: 0,
            calcPoint: calcPoint,
            reservedAmount: amount,
            rentId: rentId,
            holder: stakeholder,
            lnResultNumerator: _lnFactor,
            lnResultDenominator: 1e18,
            claimedAmount: 0,
            rewardForStake:0,
            isStaking:true
        });

        machineId2Address[machineId] = stakeholder;

        // require(
        //     reportDlcNftStaking(msgToSign, substrateSig, substratePubKey, machineId) == true, "report staking failed"
        // );

        uint256 stakedMachineCount = walletAddress2StakingMachineCount[stakeholder];
        if (stakedMachineCount == 0) {
            addressInStaking[stakeholder] = true;
            addressCountInStaking += 1;
        }
        
        walletAddress2StakingMachineCount[stakeholder] += 1;
        if(!isMachineInclude[machineId]){
            machineIds.push(machineId);
            isMachineInclude[machineId] = true;
        }

        isMachineStaked[machineId] = true;
        
       
        // stateContract.addOrUpdateStakeHolder(stakeholder, machineId, calcPoint, amount);

        emit staked(stakeholder, machineId, currentTime);
    }

    // function getLnResult(uint256 reserveAmount) public view returns (uint256, uint256) {
    //     uint256 value = 0;
    //     if (reserveAmount >= baseReserveAmount) {
    //         value = reserveAmount - baseReserveAmount;
    //     }
    //     return LogarithmLibrary.lnAsFraction(value + baseReserveAmount, baseReserveAmount);
    // }

    function lnResult(uint _amount) public pure returns (uint,uint){
        return LogarithmLibrary.lnAsFraction(_amount, 1e18);

    }

 

      function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }



    function getRewardLocked(string memory machineId,address _account) public view returns(uint){
            uint _reward = earnedBase(machineId,_account);

        
         (, uint256 lockedAmount) = _getRewardDetail(_reward);
        uint256 _amountLocked= _calculateLockedReward(machineId);
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
//  * @param machineId 
//  * @param _account 
//  * @return all released
//  * @return available
//  */

    function getReward(string memory machineId,address _account) public view returns (uint256,uint) {
        StakeInfo memory stakeInfo = machineId2StakeInfos[machineId][_account];
    
       uint _reward = earnedBase(machineId,_account);

        
         (uint256 canClaimAmount, ) = _getRewardDetail(_reward);
        uint256 _dailyReleaseAmount= _calculateReleaseReward(machineId);
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
        
        string memory machineId
    ) public canClaim(machineId)  {
        address stakeholder = msg.sender;
        StakeInfo storage stakeInfo = machineId2StakeInfos[machineId][msg.sender];
      
            require(
                (block.number - stakeInfo.lastClaimAtBlockNumber) * secondsPerBlock >= 60,
                "last claim less than 1 day"
            );
    
        stakeInfo.lastClaimAtBlockNumber = block.number;

        updateReward(machineId,msg.sender);

        
         (uint256 canClaimAmount, uint256 lockedAmount) = _getRewardDetail(rewardsBase[machineId][msg.sender]);
        uint256 _dailyReleaseAmount= _calculateReleaseRewardAndUpdate(machineId);
  
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
        rewardsBase[machineId][msg.sender] = 0;

        
            machineId2LockedRewardDetails[machineId][msg.sender].push(
                LockedRewardDetail({amountReleaseDaily: lockedAmount/LOCK_PERIOD_DAY, lockStartBlock: block.number,claimedDay:0})
            );
        

        emit claimed(stakeholder, machineId, canClaimAmount, block.number);
    }

    modifier canClaim(string memory machineId) {
        require(startAt > 0,"not begin");
        // StakeInfo storage stakeInfo = machineId2StakeInfos[machineId][msg.sender];
        // require(stakeInfo.holder != address(0), "Invalid stakeholder address");
        // require(stakeInfo.holder == msg.sender, "not stakeholder");
        // require(stakeInfo.startAtBlockNumber > 0, "staking not found");
        // require(machineId2Address[machineId] != address(0), "machine not found");
        _;
    }

    function _calculateReleaseReward(string memory machineId)
        internal
        view
        returns (uint256 )
    {
        LockedRewardDetail[] memory lockedRewardDetails = machineId2LockedRewardDetails[machineId][msg.sender];
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



     function _calculateReleaseRewardAndUpdate(string memory machineId)
        internal
        returns (uint256 )
    {
        LockedRewardDetail[] memory lockedRewardDetails = machineId2LockedRewardDetails[machineId][msg.sender];
        uint256 _unlockAmount = 0;

        for (uint256 i = 0; i < lockedRewardDetails.length; i++) {
            uint _days = (block.number - lockedRewardDetails[i].lockStartBlock)/ numberPerDay;
            if(_days <= lockedRewardDetails[i].claimedDay || lockedRewardDetails[i].claimedDay >= LOCK_PERIOD_DAY){
                continue;
            }

            uint _dayUnclaim = _days >= LOCK_PERIOD_DAY  ? LOCK_PERIOD_DAY - lockedRewardDetails[i].claimedDay : _days - lockedRewardDetails[i].claimedDay;
            
            _unlockAmount += _dayUnclaim * lockedRewardDetails[i].amountReleaseDaily;
            
 
          machineId2LockedRewardDetails[machineId][msg.sender][i].claimedDay += _dayUnclaim;
                
        }
        return _unlockAmount;
    }


    function _calculateLockedReward(string memory machineId)
        internal
        view
        returns (uint256 )
    {
        LockedRewardDetail[] memory lockedRewardDetails = machineId2LockedRewardDetails[machineId][msg.sender];
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
        
        string calldata machineId
    ) public nonReentrant {
        address stakeholder = msg.sender;
        StakeInfo storage stakeInfo = machineId2StakeInfos[machineId][stakeholder];

        require(stakeInfo.isStaking, "no staking");
       
        _unStakeAndClaim( machineId, stakeholder);

        // stateContract.removeMachine(stakeholder, machineId);
    }

    function _unStakeAndClaim(
   
        string calldata machineId,
        address stakeholder
    ) internal {
        claim( machineId);
        StakeInfo storage stakeInfo = machineId2StakeInfos[machineId][stakeholder];


        uint256 reservedAmount = stakeholder2Reserved[stakeholder][machineId];
        uint rewardStaking = stakeInfo.rewardForStake;
        if (reservedAmount  + rewardStaking > 0) {
            stakeholder2Reserved[stakeholder][machineId] = 0;
            stakeInfo.rewardForStake = 0;
            rewardToken.transfer(stakeholder, reservedAmount + rewardStaking);
            
            totalReservedAmount -= reservedAmount;
           
        }

        uint256 currentTime = block.number;
        stakeInfo.endAtBlockNumber = currentTime;
        stakeInfo.isStaking = false;
        
        totalBasePoint -= stakeInfo.calcPoint;

        stakeInfo.calcPoint = 0;
        // machineId2Address[machineId] = address(0);

        for (uint256 i = 0; i < nftStakeIds[machineId][msg.sender].length; i++) {
           
            nftToken.transferFrom(address(this), msg.sender, nftStakeIds[machineId][msg.sender][i]);
        }

  
         delete  nftStakeIds[machineId][msg.sender];

        isMachineStaked[machineId] = false;

        uint256 stakedMachineCount = walletAddress2StakingMachineCount[stakeholder];
        
            if (stakedMachineCount == 1) {
                 addressInStaking[stakeholder] = false;
                addressCountInStaking -= 1;
            }
            walletAddress2StakingMachineCount[stakeholder] -= 1;
        

        emit unStaked(msg.sender, machineId, currentTime);
    }

    function getStakeHolder(string calldata machineId) external view returns (address) {
        return machineId2Address[machineId];
    }

    function isStaking(string calldata machineId,address _account) public view returns (bool) {
       return machineId2StakeInfos[machineId][_account].isStaking;
        
    }

    function addNFTs(string calldata machineId, uint256[] calldata nftTokenIds) external {
        StakeInfo storage stakeInfo = machineId2StakeInfos[machineId][msg.sender];
        require(stakeInfo.isStaking, "no staking");
        require(nftStakeIds[machineId][msg.sender].length + nftTokenIds.length <= MAX_NFTS_PER_MACHINE, "too many nfts, max is 20");
        for (uint256 i = 0; i < nftTokenIds.length; i++) {
            uint256 tokenID = nftTokenIds[i];
            nftToken.transferFrom(msg.sender, address(this), tokenID);
            nftStakeIds[machineId][msg.sender].push(tokenID);
        }

        updateReward(machineId,msg.sender);
    
 
        uint256 newCalcPoint =logic.getMachineCalcPoint(machineId) * nftStakeIds[machineId][msg.sender].length;

        totalBasePoint -= balanceBasePoint[machineId][msg.sender];

        totalBasePoint += newCalcPoint * stakeInfo.lnResultNumerator;
        balanceBasePoint[machineId][msg.sender] = newCalcPoint * stakeInfo.lnResultNumerator;


        stakeInfo.calcPoint = newCalcPoint;
    }

    function reservedNFTs(string calldata machineId,address _account) public view returns (uint256[] memory nftTokenIds) {
        // StakeInfo memory stakeInfo = machineId2StakeInfos[machineId][_account];
        // require(stakeInfo.holder == msg.sender, "not stakeholder");
        return nftStakeIds[machineId][_account];
    }





}
