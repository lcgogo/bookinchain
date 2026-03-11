# 快速开始

## 一分钟快速部署

### 方式1：使用自动化脚本（Linux/Mac）

```bash
chmod +x deploy.sh
./deploy.sh
```

按照提示完成部署，脚本会：
1. 配置合约地址
2. 安装前端依赖
3. 构建项目
4. 引导部署到托管平台

---

### 方式2：手动部署（Windows 或其他）

#### 1. 部署智能合约

**最简单方式：Remix IDE**
1. 访问 https://remix.ethereum.org
2. 创建文件 `InteractiveNovelDAO.sol`
3. 粘贴合约代码
4. 编译（Solidity 0.8.20）
5. 连接 MetaMask（Sepolia 测试网）
6. 部署，参数：`0.01 ether, 0.001 ether, 5000`
7. 复制合约地址

**获取测试币：** https://sepoliafaucet.com/

#### 2. 部署前端

```bash
cd frontend
npm install
```

编辑 `config.js`，填入合约地址：

```javascript
export const CONTRACT_ADDRESS = "你的合约地址";
```

构建并运行：

```bash
npm run dev
# 访问 http://localhost:3000
```

#### 3. 部署到线上（可选）

**Vercel（推荐）：**
```bash
npm run build
vercel --prod
```

**GitHub Pages：**
```bash
npm run build
# 将 dist/ 文件夹推送到 GitHub
# 在仓库设置中启用 GitHub Pages
```

---

## 测试流程

### 1. 原作者操作（MetaMask 连接后）

```javascript
// 发布第1章 + 3个分支选项
参数：
- 故事线ID: 1
- IPFS哈希: "QmHash..."
- 分支: ["A. 杀死恶龙", "B. 放走恶龙", "C. 与恶龙合作"]
- 投票期: 7天
```

### 2. 读者操作

```javascript
// 投票（支付 0.001 ETH）
选择分支A并投票

// 解锁章节（支付章节费）
购买前5章阅读权限

// 分叉授权（如果不喜欢胜出分支）
从某章开始自己的故事线
```

### 3. 查看结果

- 等待投票结束
- 原作者点击"结束投票"
- 查看获胜分支
- 根据分支继续创作

---

## 文件说明

```
├── InteractiveNovelDAO.sol      # 智能合约
├── NovelContract.sol             # 简化版合约（付费阅读）
├── deploy.sh                     # 自动化部署脚本
├── DEPLOYMENT_GUIDE.md           # 详细部署文档
├── QUICKSTART.md                 # 本文件
└── frontend/
    ├── config.js                 # 配置文件（需修改合约地址）
    ├── novelContract.js          # ethers.js 封装
    ├── App.jsx                   # React 主组件
    └── package.json
```

---

## 常见问题

### Q: MetaMask 无法连接？
```
解决：
1. 刷新页面
2. 确保切换到 Sepolia 测试网
3. 检查 MetaMask 是否安装
```

### Q: 部署失败？
```
检查：
1. 合约地址是否正确
2. 是否有足够的测试 ETH
3. 网络是否正常
```

### Q: 投票失败？
```
检查：
1. 投票费是否足够（0.001 ETH）
2. 是否在投票期内
3. 是否已投票过
```

---

## 下一步

- [ ] 阅读完整文档：`DEPLOYMENT_GUIDE.md`
- [ ] 部署到主网（测试成功后）
- [ ] 添加更多功能（NFT、代币激励等）
- [ ] 优化 UI/UX
