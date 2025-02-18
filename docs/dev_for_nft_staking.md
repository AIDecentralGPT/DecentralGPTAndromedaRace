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
        uint256 amount,
        uint256 amountNft,
        uint256 rentId
    ) external
```

**描述：** 质押挖矿,amount:质押gpt的数量,amountNft:质押nft的数量,rentId:租用id

---

#### getReward

```solidity
 function getReward(string memory machineId,string memory _model,address _account) public view returns (uint256,uint)
```

**描述：** 查询已经获得的挖矿奖励和可领取的奖励,_model:ai模型名称,第一个返回值是已获得的所有奖励,第二个返回值是可领取的奖励

---

#### claim

```solidity
function claim(
  
        string memory machineId,
        string memory _model
    ) public
```

**描述：** 领取奖励

---

#### unStakeAndClaim

```solidity
 function unStakeAndClaim(
  
        string calldata machineId,
        string calldata _model
    ) external 
```

**描述：** 解除质押并领取奖励

---
