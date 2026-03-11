# Interactive Novel DAO - 互动小说区块链应用

一个基于以太坊的互动小说创作平台，支持分支剧情投票和衍生创作授权。

## 项目结构

```
├── InteractiveNovelDAO.sol    # 智能合约
├── frontend/
│   ├── config.js              # 配置
│   ├── novelContract.js       # ethers.js 封装
│   ├── App.jsx                # React 主组件
│   ├── package.json
│   └── ...
├── NovelContract.sol          # 简单版合约（付费阅读）
└── README.md
```

## 快速开始

### 1. 部署智能合约

使用 Remix IDE 或 Hardhat 部署 `InteractiveNovelDAO.sol`

构造函数参数：
- `_baseChapterFee`: 0.01 ether (单章阅读费)
- `_voteFee`: 0.001 ether (投票费)
- `_forkLicenseRate`: 5000 (分叉费率，50%)

### 2. 配置前端

编辑 `frontend/config.js`：

```js
export const CONTRACT_ADDRESS = "你的合约地址";
```

### 3. 安装依赖并运行

```bash
cd frontend
npm install
npm run dev
```

### 4. 使用流程

1. **连接钱包** - 点击"连接 MetaMask"
2. **作者操作** - (仅合约部署者)
   - 发布新章节（含分支选项）
   - 设定投票持续时间
   - 投票结束后选择获胜分支
3. **读者操作**
   - 查看章节和分支
   - 付费投票给喜欢的分支
   - 购买章节阅读权限
   - 申请分叉授权，从某章开始自己的故事

## 功能说明

### 分支投票
- 每章节发布时可添加多个分支选项
- 读者支付投票费选择喜欢的分支
- 投票结束后票数最多的分支成为主线

### 分叉授权
- 读者可以付费从任意章节分叉
- 费用 = 前置章节费用 × 阅读量系数
- 分叉后创建新故事线，可继续创作

### 收益模型
- 章节阅读费 → 作者
- 投票费 → 作者
- 分叉授权费 → 作者

## 技术栈

- **智能合约**: Solidity 0.8.20
- **前端框架**: React 18
- **Web3 库**: ethers.js v6
- **样式**: Tailwind CSS
- **构建工具**: Vite

## 扩展建议

1. **NFT 集成** - 每章铸造 NFT，允许交易
2. **代币激励** - 投票/创作获得代币奖励
3. **版税分成** - 衍生作品收益与原作者分成
4. **多链支持** - 部署到 Polygon/Arbitrum 降低 Gas
5. **IPFS _pinata** - 使用 Pinata SDK 上传内容

## 注意事项

1. 需要 MetaMask 或其他 Web3 钱包
2. 测试网推荐 Sepolia
3. IPFS 内容需要先上传到网关可访问的节点
4. 分叉授权费用会随读者数量增加而上涨
