# InteractiveNovelDAO 使用示例

## 部署合约

```solidity
// 部署时设置参数
// baseChapterFee: 0.01 ETH (10000000000000000 wei)
// voteFee: 0.001 ETH (1000000000000000 wei)
// forkLicenseRate: 5000 (50%)

InteractiveNovelDAO novel = new InteractiveNovelDAO(
    0.01 ether,
    0.001 ether,
    5000
);
```

## 流程示例

### 第1步：作者发布第1章（带分支）

```solidity
// 故事线ID=1（主线）
// 分支描述：["A. 杀死恶龙", "B. 放走恶龙", "C. 与恶龙合作"]
// 投票期：7天

uint256 chapter1 = novel.publishChapterWithBranches(
    1,  // 故事线ID
    "QmHash...第1章内容IPFS哈希",  // 内容
    ["A. 杀死恶龙", "B. 放走恶龙", "C. 与恶龙合作"],
    7 days
);

// 输出：chapter1 = 1
```

### 第2步：读者投票

```solidity
// 读者Alice投票选择分支A
novel.voteForBranch{value: 0.001 ether}(1, 1);  // 章节1，分支1

// 读者Bob投票选择分支B
novel.voteForBranch{value: 0.001 ether}(1, 2);  // 章节1，分支2

// 假设最终A分支获胜
```

### 第3步：作者结束投票

```solidity
// 7天后，作者结束投票
novel.finalizeVoting(1);  // 章节1

// winningBranchId = 1 (A分支获胜)
```

### 第4步：作者继续写第2章

```solidity
// 根据A分支继续创作
uint256 chapter2 = novel.publishChapterWithBranches(
    1,
    "QmHash...第2章内容（杀了恶龙之后）",
    ["A. 拿走宝藏", "B. 留下宝藏"],
    7 days
);
```

### 第5步：读者解锁章节权限

```solidity
// 读者Charlie购买前5章的阅读权限
novel.unlockChapters{value: 0.05 ether}(1, 5);  // 故事线1，5章
```

### 第6步：衍生创作（分叉授权）

```solidity
// 读者Dave喜欢第1章的B分支，想从那里开始创作
// 首先计算费用
uint256 forkFee = novel.calculateForkFee(1);  // 章节1

// 假设：前置章节=0（因为是第1章）
// 阅读量系数取决于总读者数
// forkFee ≈ 0.01 * 阅读量系数

// 申请授权
novel.requestForkLicense{value: forkFee}(1);

// 返回：创建新的故事线ID=2
// Dave成为故事线2的"作者"
```

### 第7步：在新的故事线上继续创作

```solidity
// Dave在自己的故事线上创作
uint256 chapter3 = novel.continueStoryLine(
    2,  // 故事线2
    "QmHash...放走恶龙后的故事",
    ["A. 恶龙回来报恩", "B. 恶龙毁灭村庄"],
    7 days
);
```

## 查询功能

### 查看章节的分支情况

```solidity
Branch[] memory branches = novel.getChapterBranches(1);
// 返回：[A分支, B分支, C分支]
for (uint i = 0; i < branches.length; i++) {
    console.log(branches[i].description);
    console.log(branches[i].voteCount);
    console.log(branches[i].isWinner);
}
```

### 查看某章节的分叉授权情况

```solidity
ForkLicense[] memory licenses = novel.getChapterForkLicenses(1);
// 返回：所有从第1章分叉出去的授权
for (uint i = 0; i < licenses.length; i++) {
    console.log(licenses[i].licensee);  // 被授权人
    console.log(licenses[i].feePaid);   // 支付的费用
    console.log(licenses[i].timestamp); // 授权时间
}
```

## 完整故事树结构

```
故事线1（主线）
├── 第1章 (author)
│   ├── 分支A: 杀死恶龙 ✅ 获胜
│   ├── 分支B: 放走恶龙
│   └── 分支C: 与恶龙合作
└── 第2章 (author，基于分支A)
    ├── 分支A: 拿走宝藏
    └── 分支B: 留下宝藏

故事线2（Dave的分支线）
├── 第1章 (引用主线的第1章)
│   └── 分支B: 放走恶龙 ✓ 起点
└── 第3章 (Dave，基于分支B)
    ├── 分支A: 恶龙回来报恩
    └── 分支B: 恶龙毁灭村庄
```

## 收益流

```
投票费 (0.001 ETH × 100人) → 0.1 ETH → 作者
阅读费 (0.01 ETH × 50人 × 10章) → 5 ETH → 作者
分叉费 (0.05 ETH × 3个衍生线) → 0.15 ETH → 作者

总收入 → 5.25 ETH
```

## 高级用法

### 修改费用参数

```solidity
// 作者可以调整费用
novel.updateFees(
    0.02 ether,   // 新的章节费
    0.002 ether,  // 新的投票费
    8000          // 新的分叉费率（80%）
);
```

### 提取收益

```solidity
// 作者提取合约中的所有资金
novel.withdraw();
```

## 注意事项

1. **投票机制**：当前用票数统计，可以改为金额加权
2. **时间锁**：可以添加 `require(chapter.isVoting == false)` 在分叉时
3. **收益分成**：可以给衍生故事线自动分账给原作者
4. **NFT集成**：每章可以铸造NFT，增加资产价值
