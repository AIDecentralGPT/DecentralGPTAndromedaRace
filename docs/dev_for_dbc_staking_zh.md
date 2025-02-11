## 接口文档

### `DbcAIStaking` 接口

```solidity
interface DbcAIStaking {
    function freeGpuAmount(string calldata _id) external view returns (uint);
}
```

## 函数

### 公共和外部函数


#### reportStakingStatus

```solidity
function reportStakingStatus(string calldata _id, uint256 gpuNum, bool isStake) external
```

**描述：** 质押和解除质押的时候上报状态

---

#### freeGpuAmount

```solidity
    function freeGpuAmount(string calldata _id) external view returns (uint);

```

**描述：** 根据machineId或者容器Id获取机器或容器可用的gpu的数量.

---

#### stakeDbc

```solidity
    function stakeDbc(string calldata _id,uint _amount) external payable;
```

**描述：** 为_id 容器或machine质押dbc,_amount为质押的dbc数量.

---

#### amountDbcCanStake

```solidity
function amountDbcCanStake(string calldata _id) external view returns(uint)
```

**描述：** 查询 `_id` 对应的容器或机器当前可以质押的 DBC 数量。返回值为可质押的 DBC 数量。

---

#### stakeDbc

```solidity
    function stakeDbc(string calldata _id,uint _amount) external payable;
```

**描述：** 为_id 容器或machine质押dbc,_amount为质押的dbc数量.

---

#### amountDbcStaked

```solidity
function amountDbcStaked(string calldata _id) external view returns(uint)
```

**描述：** 查询 `_id` 对应的容器或机器当前已经质押的 DBC 数量。返回值为已质押的 DBC 数量。

---

#### canUnstake

```solidity
function canUnstake(string calldata _id) external view returns (bool)
```

**描述：** 检查 `_id` 对应的容器或机器是否满足解除质押的条件。返回值为 `true` 表示可以解除质押，`false` 表示不能解除质押。

---

#### unstakeDbc

```solidity
function unstakeDbc(string calldata _id) external
```

**描述：** 解除 `_id` 对应的容器或机器的 DBC 质押。调用此方法后，质押的 DBC 将退回到用户的账户中。

---
