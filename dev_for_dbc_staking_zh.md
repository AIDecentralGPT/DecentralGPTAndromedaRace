## 接口文档

### `DbcAIStaking` 接口

```solidity
interface DbcAIStaking {
    function freeGpuAmount(string calldata _id) external view returns (uint);
}
```

## 函数

### 公共和外部函数

#### freeGpuAmount

```solidity
    function freeGpuAmount(string calldata _id) external view returns (uint);

```

**描述：** 根据machineId或者容器Id获取机器或容器可用的gpu的数量.

---
