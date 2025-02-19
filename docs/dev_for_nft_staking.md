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
