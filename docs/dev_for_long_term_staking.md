## 接口文档

### Degpt 自由挖矿接口

```solidity

```

### 相关合约地址


"MachineInfos": "0xF9335c71583132d58E5320f73713beEf6da5257D",

"DbcStaking": "0x8CD8F5517ab18edfA7c121140B03229cD0771B83",

"nft(erc1155)": "0xC40ba6AC7Fcd11B8E0Dc73c86b0F8D63714F6494"


### 公共和外部函数

#### stake

```solidity
function stake(
    
        string calldata dockerId,
        uint256 amountDgc,
        uint256 amountNft
    ) external
```

**描述：** 质押挖矿,amountDgc:质押dgc的数量,amountNft:质押nft的数量,

流程: 

要质押的dockerId要先在建康检测中心上报到MachineInfos合约(不需要用户操作),然后用户去DbcStaking合约质押DBC token,之后才能在自由挖矿中质押.

**参数：** 

    dockerId:容器id,

    amountDgc:质押dgc的数量,

    amountNft:质押nft的数量(erc1155),

---



```solidity
 function addNFTs(string calldatadockerId, uint256 _amountNft) external
```

**描述：** 操作此步骤之前需要确保以下2步已经完成.

 1.先执行上面的stake操作,

2.dockerId已经在建康检测程序中上报

说明:为已经执行stake的dockerId添加nft,增加nft数量可以增加获取奖励的额度,


---

#### getReward

```solidity
 function getReward(string memory dockerId,address _account) public view returns (uint256,uint)
```

**描述：** 查询已经获得的挖矿奖励和可领取的奖励,第一个返回值是已获得的所有奖励,第二个返回值是可领取的奖励

---

#### claim

```solidity
function claim(
  
        string memory dockerId
    ) public
```

**描述：** 领取奖励

---

#### unStakeAndClaim

```solidity
 function unStakeAndClaim(
  
        string calldata dockerId
    ) external 
```

**描述：** 解除质押并领取奖励

---
