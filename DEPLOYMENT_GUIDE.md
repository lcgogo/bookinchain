# 部署指南

## 一、智能合约部署

### 方式A：使用 Remix IDE（推荐新手）

#### 1. 打开 Remix
访问 https://remix.ethereum.org

#### 2. 创建合约文件
- 点击 "File Explorer" 左侧图标
- 右键 "contracts" 文件夹 → "New File"
- 命名：`InteractiveNovelDAO.sol`
- 粘贴合约代码

#### 3. 编译合约
```
1. 点击左侧 "Solidity Compiler" 图标
2. 选择版本: 0.8.20
3. 点击 "Compile InteractiveNovelDAO.sol"
4. 等待编译成功（绿色对勾）
```

#### 4. 部署到测试网
```
1. 点击左侧 "Deploy & Run Transactions" 图标
2. ENVIRONMENT: 选择 "Injected Provider - MetaMask"
3. 连接 MetaMask（确保切换到 Sepolia 测试网）
4. 在 "DEPLOY" 下输入构造函数参数：

   _baseChapterFee:    10000000000000000    (0.01 ETH)
   _voteFee:           1000000000000000     (0.001 ETH)
   _forkLicenseRate:   5000                  (50%)

5. 点击 "transact"
6. 在 MetaMask 中确认交易
7. 等待部署完成，复制合约地址
```

#### 5. 获取测试网 ETH
```
Sepolia 水龙头：
- https://sepoliafaucet.com/ (需要 Alchemy 账号)
- https://faucet.sepolia.dev/
```

---

### 方式B：使用 Hardhat（推荐开发者）

#### 1. 安装 Hardhat
```bash
mkdir novel-contract && cd novel-contract
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat init
# 选择 "Create a TypeScript project"
```

#### 2. 创建合约文件
```bash
mkdir contracts
cp /path/to/InteractiveNovelDAO.sol contracts/
```

#### 3. 配置 hardhat.config.ts
```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY",
      accounts: ["YOUR_PRIVATE_KEY"]
    }
  },
  etherscan: {
    apiKey: "YOUR_ETHERSCAN_API_KEY"
  }
};

export default config;
```

#### 4. 创建部署脚本 scripts/deploy.ts
```typescript
import { ethers } from "hardhat";

async function main() {
  const NovelDAO = await ethers.getContractFactory("InteractiveNovelDAO");
  
  const novel = await NovelDAO.deploy(
    ethers.parseEther("0.01"),    // baseChapterFee
    ethers.parseEther("0.001"),   // voteFee
    5000                           // forkLicenseRate
  );

  await novel.waitForDeployment();

  console.log(`Contract deployed to: ${await novel.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

#### 5. 部署
```bash
# 编译
npx hardhat compile

# 部署到 Sepolia
npx hardhat run scripts/deploy.ts --network sepolia

# 验证合约
npx hardhat verify --network sepolia DEPLOYED_CONTRACT_ADDRESS 0.01 0.001 5000
```

---

## 二、前端部署

### 方式A：Vercel（推荐）

#### 1. 准备前端代码
```bash
cd frontend
npm install
```

#### 2. 修改配置
编辑 `config.js`：
```javascript
export const CONTRACT_ADDRESS = "你的合约地址";
export const RPC_URL = "https://rpc.sepolia.org";
```

#### 3. 构建
```bash
npm run build
# 生成 dist/ 文件夹
```

#### 4. 部署到 Vercel
```bash
# 安装 Vercel CLI
npm i -g vercel

# 登录
vercel login

# 部署
vercel --prod

# 按提示选择：
# - 设置项目名称
# - 选择目录：frontend/dist
# - 确认部署
```

或者使用 GitHub + Vercel 自动部署：
1. 将代码推送到 GitHub
2. 在 Vercel 导入项目
3. 设置构建命令：`npm run build`
4. 输出目录：`dist`
5. 点击 Deploy

---

### 方式B：GitHub Pages（免费）

#### 1. 修改 vite.config.js
```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: '/your-repo-name/',  // 添加这行
  build: {
    outDir: 'dist'
  }
});
```

#### 2. 创建部署脚本
```bash
npm install gh-pages --save-dev
```

在 `package.json` 添加：
```json
{
  "scripts": {
    "deploy": "gh-pages -d dist"
  }
}
```

#### 3. 部署
```bash
npm run build
npm run deploy
```

---

### 方式C：Netlify

#### 1. 拖拽部署
```bash
npm run build
# 打开 https://app.netlify.com/drop
# 拖拽 dist/ 文件夹
```

#### 2. 或连接 GitHub 自动部署
1. 登录 Netlify
2. "Add new site" → "Import an existing project"
3. 选择 GitHub 仓库
4. 构建设置：
   - Build command: `npm run build`
   - Publish directory: `dist`
5. Deploy

---

## 三、完整部署检查清单

### 智能合约
- [ ] 选择部署网络（Sepolia 测试网 / 主网）
- [ ] 设置合理的构造函数参数
- [ ] 确保钱包有足够 ETH 支付 Gas
- [ ] 记录合约地址
- [ ] 在 Etherscan 上验证合约（可选）

### 前端
- [ ] 更新 `config.js` 中的合约地址
- [ ] 测试所有功能正常
- [ ] 构建生产版本
- [ ] 部署到托管平台
- [ ] 测试生产环境功能

---

## 四、测试流程

### 部署后测试步骤

#### 1. 原作者操作
```javascript
// 发布第1章
novel.publishChapter(
  1,  // 主线
  "QmHash...",  // IPFS哈希
  ["分支A: 杀死恶龙", "分支B: 放走恶龙"],
  7  // 投票7天
);

// 等待7天后结束投票
novel.finalizeVoting(1);

// 继续写第2章
novel.publishChapter(
  1,
  "QmHash...第2章",
  ["拿走宝藏", "留下宝藏"],
  7
);
```

#### 2. 读者操作
```javascript
// 投票
novel.vote(1, 1);  // 给第1章的分支1投票

// 解锁章节
novel.unlockChapters(1, 5);  // 解锁主线前5章

// 分叉授权
const fee = await novel.calculateForkFee(1);
novel.requestForkLicense(1);

// 在新故事线创作
novel.continueStoryLine(
  2,  // 新故事线ID
  "QmHash...我的分支",
  ["新分支1", "新分支2"],
  7
);
```

---

## 五、常见问题

### Q1: MetaMask 连接失败
```
解决：
1. 确保安装了 MetaMask 扩展
2. 切换到 Sepolia 测试网
3. 刷新页面重试
```

### Q2: 交易失败 (Gas 不足)
```
解决：
1. 在 MetaMask 增加 Gas Limit
2. 确保钱包有足够测试 ETH
```

### Q3: IPFS 内容无法访问
```
解决：
1. 使用 Pinata 或 nft.storage 上传
2. 或使用公共网关：https://ipfs.io/ipfs/
```

### Q4: 合约调用失败
```
检查：
1. 合约地址是否正确
2. ABI 是否与合约匹配
3. 调用者是否有权限
```

---

## 六、推荐配置

### 测试网配置（Sepolia）
```javascript
// config.js
export const CONTRACT_ADDRESS = "0x...";
export const RPC_URL = "https://rpc.sepolia.org";
export const IPFS_GATEWAY = "https://ipfs.io/ipfs/";
export const NETWORK = {
  chainId: 11155111n,
  name: "Sepolia"
};
```

### 主网配置（正式使用）
```javascript
export const RPC_URL = "https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY";
export const NETWORK = {
  chainId: 1n,
  name: "Ethereum Mainnet"
};
```

### Polygon 配置（低 Gas）
```javascript
export const RPC_URL = "https://polygon-rpc.com";
export const NETWORK = {
  chainId: 137n,
  name: "Polygon"
};
```

---

## 七、IPFS 内容上传

### 方式1：Pinata（推荐）
1. 注册 https://www.pinata.cloud/
2. 上传小说章节内容（JSON 格式）
3. 复制 CID 作为 contentHash

### 方式2：nft.storage
```bash
npm install nft.storage
```

```javascript
import { NFTStorage, File } from 'nft.storage';

const client = new NFTStorage({ token: 'YOUR_API_KEY' });

const metadata = await client.store({
  name: 'Chapter 1',
  description: 'The beginning of the story',
  content: 'Once upon a time...'
});

console.log(metadata.url); // ipfs://...
```
