# 自动部署合约脚本

一键自动部署 InteractiveNovelDAO 合约，支持本地网络和测试网。

## 快速开始

### 1. 运行部署脚本

```bash
./auto-deploy.sh
```

### 2. 选择部署方式

脚本会提示你选择：

| 选项 | 网络 | 用途 |
|------|------|------|
| 1 | 🏠 本地 Hardhat 网络 | 快速测试，自动创建临时网络 |
| 2 | 🔗 本地节点（Ganache） | 连接已运行的本地节点 |
| 3 | 🧪 Sepolia 测试网 | 正式测试，需要测试 ETH |

### 3. 自动完成

脚本会自动：
- ✅ 检查并安装 Hardhat
- ✅ 创建配置文件
- ✅ 复制合约文件
- ✅ 部署合约
- ✅ 更新前端配置
- ✅ 保存部署信息

## 部署示例

### 本地快速测试

```bash
./auto-deploy.sh
# 选择: 1 (本地 Hardhat 网络)
```

输出示例：
```
=====================================
  自动部署 InteractiveNovelDAO
=====================================

📦 检查依赖...
⚙️  创建 Hardhat 配置...
📁 创建项目结构...
📝 创建部署脚本...

✅ 初始化完成！

=====================================
  选择部署方式
=====================================

1) 🏠 本地 Hardhat 网络
2) 🔗 连接到本地节点
3) 🧪 部署到 Sepolia 测试网

请选择 [1/2/3]: 1

🚀 部署到本地 Hardhat 网络...

=====================================
部署账户: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额: 10000.0 ETH
=====================================

🚀 开始部署合约...
   基础章节费用: 0.01 ETH
   投票费用: 0.001 ETH
   分叉授权费率: 50 %

✅ 合约部署成功！

=====================================
📋 部署信息
=====================================
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
部署账户: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
交易哈希: 0x...
区块高度: 1
=====================================

💾 部署信息已保存到 deployment.json
⚙️  前端配置已更新: frontend/config.js

🎉 部署完成！

下一步:
  1. 在前端目录运行: npm run dev
  2. 在浏览器中打开页面并连接钱包
  3. 开始创作你的互动小说！
```

## 连接到本地钱包

### Hardhat Network (推荐)

脚本会自动创建本地网络，使用 Hardhat 内置的测试账户。

内置测试账户（前几个）：
```
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (余额: 10000 ETH)
0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (余额: 10000 ETH)
...
```

### MetaMask 连接本地网络

1. 打开 MetaMask
2. 点击网络下拉菜单 → 添加网络
3. 添加以下配置：
   - **网络名称**: Hardhat Local
   - **RPC URL**: http://127.0.0.1:8545
   - **链 ID**: 31337
   - **货币符号**: ETH

4. 导入测试账户私钥：
   ```
   0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```

### Ganache

1. 启动 Ganache（图形界面或 CLI）
2. 选择 "Quickstart"
3. RPC Server 通常为: `HTTP://127.0.0.1:7545`
4. 运行脚本，选择选项 2

## 部署到测试网/主网

### Sepolia 测试网

1. 获取测试 ETH：
   - [Sepolia Faucet](https://sepoliafaucet.com/)
   - [Alchemy Faucet](https://sepoliafaucet.com/)

2. 准备私钥（测试用途）：
   ```bash
   # 编辑 .env 文件
   PRIVATE_KEY=0x你的私钥
   ```

3. 运行部署：
   ```bash
   ./auto-deploy.sh
   # 选择: 3 (Sepolia 测试网)
   ```

## 文件结构

```
workspace/
├── auto-deploy.sh          # 主部署脚本
├── deploy.sh               # 原来的部署脚本
├── InteractiveNovelDAO.sol # 合约源码
├── contracts/              # Hardhat 合约目录
│   └── InteractiveNovelDAO.sol
├── scripts/
│   └── deploy.js           # Hardhat 部署脚本
├── hardhat.config.js       # Hardhat 配置
├── deployment.json         # 部署信息（自动生成）
├── frontend/
│   └── config.js           # 前端配置（自动更新）
└── .env                    # 环境变量（可选）
```

## 常用命令

```bash
# 手动运行 Hardhat 命令
npx hardhat compile          # 编译合约
npx hardhat test             # 运行测试
npx hardhat node             # 启动本地节点

# 部署到特定网络
npx hardhat run scripts/deploy.js --network hardhat
npx hardhat run scripts/deploy.js --network localhost
npx hardhat run scripts/deploy.js --network sepolia

# 查看 Hardhat 帮助
npx hardhat help
```

## 故障排除

### 问题："Cannot find module 'hardhat'"

解决：重新安装依赖
```bash
npm install
```

### 问题："Network connection error"

解决：检查本地节点是否运行
```bash
# 检查端口
lsof -i :8545

# 启动本地节点
npx hardhat node
```

### 问题："Insufficient funds"

本地网络：确保使用的是 Hardhat 内置账户
测试网：从水龙头获取测试 ETH

### 问题：MetaMask 无法连接

1. 确保 MetaMask 切换到正确的网络
2. 尝试重置账户：MetaMask → 设置 → 高级 → 重置账户
3. 清除浏览器缓存

## 注意事项

⚠️ **安全警告**：
- 不要在 `.env` 文件中存储主网私钥
- 不要将包含真实资金的账户用于测试
- 定期清理 `deployment.json` 中的敏感信息

## 下一步

部署成功后：
1. 查看 `deployment.json` 获取合约地址
2. 前端配置已自动更新
3. 运行前端：`cd frontend && npm run dev`
4. 在浏览器中连接钱包并开始创作

---

有问题？查看原部署指南：`DEPLOYMENT_GUIDE.md`
