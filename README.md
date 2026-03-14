# 📚 InteractiveNovelDAO

一个基于区块链的互动小说 DAO 平台，让读者参与故事走向的决策，并支持创作者进行衍生授权创作。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Solidity](https://img.shields.io/badge/solidity-0.8.20-green.svg)
![Hardhat](https://img.shields.io/badge/hardhat-✓-yellow.svg)

## ✨ 核心特性

- **🗳️ 读者投票决策** - 读者通过投票决定故事走向
- **🌿 分叉授权机制** - 支持创作者基于现有章节创作衍生故事线
- **💰 付费解锁模式** - 章节付费解锁，创作者获得收益
- **⛓️ 去中心化存储** - 内容存储于 IPFS，永久可用
- **🎨 现代化前端** - React + Vite 构建的响应式界面

## 🚀 快速开始

### 一键部署（推荐）

```bash
# 克隆仓库
git clone https://github.com/lcgogo/bookinchain.git
cd bookinchain

# 运行自动部署脚本
./auto-deploy.sh
```

脚本会自动安装依赖、编译合约、部署并更新配置。

### 手动部署

#### 1. 智能合约部署

**方式 A：Remix IDE（适合新手）**
1. 访问 [Remix](https://remix.ethereum.org)
2. 新建文件 `InteractiveNovelDAO.sol`，粘贴合约代码
3. 编译（Solidity 0.8.20）
4. 使用 MetaMask 连接到 Sepolia 测试网
5. 部署，构造函数参数：
   - `_baseChapterFee`: 10000000000000000 (0.01 ETH)
   - `_voteFee`: 1000000000000000 (0.001 ETH)
   - `_forkLicenseRate`: 5000 (50%)

**方式 B：Hardhat（适合开发者）**

```bash
# 安装依赖
npm install

# 编译合约
npx hardhat compile

# 部署到本地网络
npx hardhat run scripts/deploy.js --network hardhat

# 或部署到 Sepolia 测试网
npx hardhat run scripts/deploy.js --network sepolia
```

#### 2. 前端部署

```bash
cd frontend

# 安装依赖
npm install

# 更新配置（config.js 中的合约地址）
# 然后构建
npm run build

# 本地预览
npm run dev

# 或部署到 Vercel
vercel --prod
```

## 📖 使用指南

### 原作者发布章节

```solidity
// 发布第1章，提供2个分支选项
novel.publishChapter(
    1,                          // 主线ID
    "QmHash...",               // IPFS 内容哈希
    ["分支A: 杀死恶龙", "分支B: 放走恶龙"],  // 分支选项
    7                           // 投票期7天
);

// 投票结束后，结束投票并继续写第2章
novel.finalizeVoting(1);
```

### 读者投票

```solidity
// 给第1章的第1个分支投票
novel.vote(1, 1);  // 支付 voteFee (0.001 ETH)
```

### 分叉授权（衍生创作）

```solidity
// 计算授权费用
uint256 fee = novel.calculateForkFee(1);

// 申请授权
novel.requestForkLicense{value: fee}(1);

// 创建新故事线并继续创作
novel.continueStoryLine(
    2,                          // 新故事线ID
    "QmHash...",               // 内容
    ["新分支1", "新分支2"],
    7                           // 投票期
);
```

## 🏗️ 项目结构

```
bookinchain/
├── 📄 InteractiveNovelDAO.sol      # 智能合约源码
├── 📄 NovelContract.sol            # 简化版合约
├── 📁 contracts/                   # Hardhat 合约目录
├── 📁 scripts/
│   └── deploy.js                   # 部署脚本
├── 📁 frontend/                    # React 前端
│   ├── src/
│   │   ├── App.jsx                 # 主应用
│   │   └── ...
│   ├── config.js                   # 合约配置
│   └── package.json
├── 📄 auto-deploy.sh               # 一键部署脚本
├── 📄 hardhat.config.js            # Hardhat 配置
├── 📄 deployment.json              # 部署信息（自动生成）
└── 📄 README.md                    # 本文件
```

## 🔧 配置说明

### 合约参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `baseChapterFee` | uint256 | 单章阅读费用（wei）|
| `voteFee` | uint256 | 投票费用（wei）|
| `forkLicenseRate` | uint256 | 分叉授权费率（基点，10000 = 100%）|

### 前端配置 (`frontend/config.js`)

```javascript
export const CONTRACT_ADDRESS = "0x...";  // 部署后的合约地址
export const RPC_URL = "https://rpc.sepolia.org";
export const NETWORK = {
  chainId: 11155111n,  // Sepolia
  name: "Sepolia"
};
```

## 🌐 网络配置

### 本地开发（Hardhat）
- **RPC**: `http://127.0.0.1:8545`
- **Chain ID**: 31337
- **特点**: 自动创建，无需真实 ETH

### Sepolia 测试网
- **RPC**: `https://rpc.sepolia.org`
- **Chain ID**: 11155111
- **水龙头**: [Sepolia Faucet](https://sepoliafaucet.com/)

### 主网
- **Chain ID**: 1
- **注意**: 需要真实 ETH，部署前请充分测试

## 📝 合约功能

### 核心函数

| 函数 | 说明 |
|------|------|
| `publishChapter()` | 原作者发布章节 |
| `vote()` | 读者投票 |
| `finalizeVoting()` | 结束投票 |
| `continueStoryLine()` | 创作者继续故事线 |
| `requestForkLicense()` | 申请分叉授权 |
| `unlockChapters()` | 读者解锁章节 |
| `calculateForkFee()` | 计算分叉授权费 |
| `withdraw()` | 创作者提现收益 |

### 事件

| 事件 | 说明 |
|------|------|
| `ChapterPublished` | 章节发布 |
| `Voted` | 投票发生 |
| `VotingFinalized` | 投票结束 |
| `ForkLicenseGranted` | 分叉授权 |
| `StoryLineContinued` | 故事线继续 |

## 🧪 测试

```bash
# 运行 Hardhat 测试
npx hardhat test

# 运行特定网络测试
npx hardhat test --network hardhat
```

## 📚 文档

- [功能说明](./INTERACTIVE_NOVEL_README.md) - 详细功能介绍
- [部署指南](./DEPLOYMENT_GUIDE.md) - 完整部署教程
- [使用示例](./USAGE_EXAMPLES.md) - 代码示例
- [快速开始](./QUICKSTART.md) - 快速上手指南
- [自动部署说明](./AUTO_DEPLOY_README.md) - auto-deploy.sh 使用说明

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](./LICENSE) 文件

## 🙏 致谢

- [Hardhat](https://hardhat.org/) - 以太坊开发环境
- [React](https://react.dev/) - 前端框架
- [Vite](https://vitejs.dev/) - 构建工具
- [Ethers.js](https://docs.ethers.org/) - Web3 库

## 📮 联系方式

- GitHub Issues: [提交问题](https://github.com/lcgogo/bookinchain/issues)
- 项目主页: https://github.com/lcgogo/bookinchain

---

⭐ 如果这个项目对你有帮助，请给它一个 Star！
