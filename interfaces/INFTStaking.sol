// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface INFTStaking {
    struct Info {
        uint256 timeLen;
        uint256 rwdReleaseTotal;
        uint256 userTotalReleaseRwd;
        uint256 userAvailablRwd;
        uint256 userLockedRwd;
        uint256 userTotalRwd;
        LockedRewardDetail[] lockedRewardDetails;
    }

    struct LockedRewardDetail {
        uint256 amountReleaseDaily;
        uint256 lockStartBlock;
        uint256 claimedDay;
    }

    event Initialized(uint8 version);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event claimed(address indexed stakeholder, string machineId, uint256 rewardAmount, uint256 claimAtBlockNumber);
    event claimedAll(address indexed stakeholder, uint256 claimAtBlockNumber);
    event nftTokenSet(address indexed addr);
    event nonlinearCoefficientChanged(uint256 nonlinearCoefficientNumerator, uint256 nonlinearCoefficientDenominator);
    event rewardTokenSet(address indexed addr);
    event staked(address indexed stakeholder, string machineId, uint256 stakeAtBlockNumber);
    event unStaked(address indexed stakeholder, string machineId, uint256 unStakeAtBlockNumber);

    function DAILY_UNLOCK_RATE() external view returns (uint8);
    function LOCK_PERIOD_DAY() external view returns (uint256);
    function MAX_NFTS_PER_MACHINE() external view returns (uint8);
    function REWARD_DURATION() external view returns (uint256);
    function SECONDS_PER_DAY() external view returns (uint256);
    function addNFTs(string memory machineId, string memory _model, uint256[] memory nftTokenIds) external;
    function addressCountInStaking() external view returns (uint256);
    function addressInStaking(address) external view returns (bool);
    function balanceBasePoint(string memory, string memory, address) external view returns (uint256);
    function baseReserveAmount() external view returns (uint256);
    function claim(string memory machineId, string memory _model) external;
    function claimLeftRewardTokens() external;
    function dailyRewardBase() external view returns (uint256);
    function earnedBase(string memory _machine, string memory _model, address _account)
        external
        view
        returns (uint256);
    function getLeftGPUCountToStartReward() external view returns (uint256);
    function getMachineHolder(string memory machineId) external view returns (address);
    function getReward(string memory machineId, string memory _model, address _account)
        external
        view
        returns (uint256, uint256);
    function getRewardLocked(string memory machineId, string memory _model, address _account)
        external
        view
        returns (uint256);
    function getTotalCalcPointAndReservedAmount(string memory _model) external view returns (uint256, uint256);
    function getTotalGPUCountInStaking() external view returns (uint256);
    function gpuCountStartRequired() external view returns (uint256);
    function info(address _account, string memory machineId, string memory _model)
        external
        view
        returns (Info memory);
    function initialize(
        address _nftToken,
        address _rewardToken,
        uint8 _phase_level,
        address _logic,
        address _register,
        string[] memory _models,
        uint256[] memory _weights
    ) external;
    function isMachineStaked(string memory) external view returns (bool);
    function isMachineStaking(string memory machineId, string memory _model, address _account)
        external
        view
        returns (bool);
    function isStaking(string memory machineId) external view returns (bool);
    function lastTimeRewardApplicable() external view returns (uint256);
    function lastUpdateTime(string memory) external view returns (uint256);
    function lnResult(uint256 _amount) external pure returns (uint256, uint256);
    function logic() external view returns (address);
    function machineId2Address(string memory) external view returns (address);
    function machineId2LockedRewardDetails(string memory, address, uint256)
        external
        view
        returns (uint256 amountReleaseDaily, uint256 lockStartBlock, uint256 claimedDay);
    function machineId2StakeInfos(string memory, string memory, address)
        external
        view
        returns (
            address holder,
            uint256 startAtBlockNumber,
            uint256 lastClaimAtBlockNumber,
            uint256 endAtBlockNumber,
            uint256 calcPoint,
            uint256 reservedAmount,
            uint256 rentId,
            uint256 lnResultNumerator,
            uint256 lnResultDenominator,
            uint256 claimedAmount,
            uint256 rewardForStake,
            bool isStaking
        );
    function machineIds(uint256) external view returns (string memory);
    function machineIdx(string memory) external view returns (uint256);
    function machineLen() external view returns (uint256);
    function machineRewardPerBasePointPaid(string memory, string memory, address) external view returns (uint256);
    function modelWeights(string memory) external view returns (uint256);
    function nftStakeIds(string memory, address, uint256) external view returns (uint256);
    function nftToken() external view returns (address);
    function nonlinearCoefficientDenominator() external view returns (uint256);
    function nonlinearCoefficientNumerator() external view returns (uint256);
    function numberPerDay() external view returns (uint256);
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
        external
        returns (bytes4);
    function owner() external view returns (address);
    function periodFinish() external view returns (uint256);
    function phaseLevel() external view returns (uint8);
    function projectName() external view returns (string memory);
    function register() external view returns (address);
    function renounceOwnership() external;
    function reservedNFTs(string memory machineId, address _account)
        external
        view
        returns (uint256[] memory nftTokenIds);
    function rewardAmountPerSecond() external view returns (uint256);
    function rewardPerBasePoint(string memory _model) external view returns (uint256);
    function rewardPerBasePointStored(string memory) external view returns (uint256);
    function rewardRateBase(string memory) external view returns (uint256);
    function rewardToken() external view returns (address);
    function rewardsBase(string memory, string memory, address) external view returns (uint256);
    function secondsPerBlock() external view returns (uint8);
    function setNftToken(address token) external;
    function setNonlinearCoefficient(uint256 numerator, uint256 denominator) external;
    function setRewardToken(address token) external;
    function stake(string memory machineId, uint256 amount, uint256[] memory nftTokenIds, uint256 rentId) external;
    function stakeholder2Reserved(address, string memory) external view returns (uint256);
    function stakingThresholdAmount() external view returns (uint256);
    function startAt() external view returns (uint256);
    function totalBasePoint(string memory) external view returns (uint256);
    function totalGpuCount() external view returns (uint256);
    function totalReservedAmount() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function unStakeAndClaim(string memory machineId, string memory _model) external;
    function walletAddress2StakingMachineCount(address) external view returns (uint8);
}
