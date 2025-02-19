## 接口文档

### `NFTStaking` 接口

```solidity

```

## 函数

### 公共和外部函数

#### stake

```solidity
 function stake(
  
        string calldata machineId,
        uint256 amountDgc,
        uint256 amountNft,
        uint256 rentId
    ) external
```

**描述：** 质押挖矿,amountDgc:质押dgc的数量,amountNft:质押nft的数量,rentId:租用id

流程: rentId需要先去substrate上绑定owner地址,租用机器获得rent id

    1.machineId的信息在建康检测程序要先上报

---



```solidity
 function addNFTs(string calldata machineId, uint256 _amountNft) external
```

**描述：** 操作此步骤之前需要确保以下2步已经完成.

 1.先执行上面的stake操作,

2.machineId已经在建康检测程序中上报

说明:为已经执行stake的machineId添加nft,增加nft数量可以增加获取奖励的额度,


---

#### getReward

```solidity
 function getReward(string memory machineId,address _account) public view returns (uint256,uint)
```

**描述：** 查询已经获得的挖矿奖励和可领取的奖励,第一个返回值是已获得的所有奖励,第二个返回值是可领取的奖励

---

#### claim

```solidity
function claim(
  
        string memory machineId
    ) public
```

**描述：** 领取奖励

---

#### unStakeAndClaim

```solidity
 function unStakeAndClaim(
  
        string calldata machineId
    ) external 
```

**描述：** 解除质押并领取奖励

---
