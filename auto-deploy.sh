# 自动部署脚本 - 使用本地钱包
# 此脚本自动部署 InteractiveNovelDAO 合约到本地网络

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  自动部署 InteractiveNovelDAO${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# 检查是否安装了 Hardhat
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}⚡ 初始化 Hardhat 项目...${NC}"
    npm init -y
fi

# 安装依赖
echo -e "${YELLOW}📦 检查依赖...${NC}"
if ! npm list hardhat &>/dev/null; then
    echo "正在安装 Hardhat..."
    npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv
fi

# 创建 Hardhat 配置
echo -e "${YELLOW}⚙️  创建 Hardhat 配置...${NC}"
cat > hardhat.config.js << 'HHC'
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // 本地 Hardhat 网络（默认）
    hardhat: {
      chainId: 31337
    },
    // 本地节点（如 Ganache）
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337
    },
    // Sepolia 测试网
    sepolia: {
      url: process.env.SEPOLIA_RPC || "https://rpc.sepolia.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },
  paths: {
    sources: "./contracts",
    artifacts: "./artifacts"
  }
};
HHC

# 创建 contracts 目录
echo -e "${YELLOW}📁 创建项目结构...${NC}"
mkdir -p contracts
mkdir -p scripts

# 复制合约文件（如果不存在）
if [ -f "InteractiveNovelDAO.sol" ] && [ ! -f "contracts/InteractiveNovelDAO.sol" ]; then
    cp InteractiveNovelDAO.sol contracts/
    echo "✓ 复制合约文件"
fi

# 创建部署脚本
echo -e "${YELLOW}📝 创建部署脚本...${NC}"
cat > scripts/deploy.js << 'DEPLOY'
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  console.log("=====================================");
  console.log("部署账户:", deployer.address);
  console.log("账户余额:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH");
  console.log("=====================================");
  console.log("");

  // 部署参数
  const baseChapterFee = hre.ethers.parseEther("0.01");     // 0.01 ETH
  const voteFee = hre.ethers.parseEther("0.001");           // 0.001 ETH
  const forkLicenseRate = 5000;                             // 50%

  console.log("🚀 开始部署合约...");
  console.log("   基础章节费用:", hre.ethers.formatEther(baseChapterFee), "ETH");
  console.log("   投票费用:", hre.ethers.formatEther(voteFee), "ETH");
  console.log("   分叉授权费率:", forkLicenseRate / 100, "%");
  console.log("");

  const NovelDAO = await hre.ethers.getContractFactory("InteractiveNovelDAO");
  const novel = await NovelDAO.deploy(baseChapterFee, voteFee, forkLicenseRate);

  await novel.waitForDeployment();

  const address = await novel.getAddress();
  
  console.log("✅ 合约部署成功！");
  console.log("");
  console.log("=====================================");
  console.log("📋 部署信息");
  console.log("=====================================");
  console.log("合约地址:", address);
  console.log("部署账户:", deployer.address);
  console.log("交易哈希:", novel.deploymentTransaction().hash);
  console.log("区块高度:", await hre.ethers.provider.getBlockNumber());
  console.log("=====================================");
  console.log("");
  
  // 保存部署信息
  const fs = require("fs");
  const deploymentInfo = {
    contractAddress: address,
    deployer: deployer.address,
    transactionHash: novel.deploymentTransaction().hash,
    network: hre.network.name,
    chainId: Number(await hre.ethers.provider.getNetwork().then(n => n.chainId)),
    timestamp: new Date().toISOString(),
    constructorArgs: {
      baseChapterFee: baseChapterFee.toString(),
      voteFee: voteFee.toString(),
      forkLicenseRate: forkLicenseRate
    }
  };
  
  fs.writeFileSync("deployment.json", JSON.stringify(deploymentInfo, null, 2));
  console.log("💾 部署信息已保存到 deployment.json");
  console.log("");
  
  // 生成前端配置文件
  const configContent = `// 配置文件 - 自动生成
// 生成时间: ${new Date().toLocaleString()}

// 合约部署地址
export const CONTRACT_ADDRESS = "${address}";

// RPC 节点
export const RPC_URL = "${hre.network.name === 'hardhat' || hre.network.name === 'localhost' ? 'http://127.0.0.1:8545' : 'https://rpc.sepolia.org'}";

// IPFS 网关
export const IPFS_GATEWAY = "https://ipfs.io/ipfs/";

// 网络配置
export const NETWORK = {
  chainId: ${Number(await hre.ethers.provider.getNetwork().then(n => n.chainId))}n,
  name: "${hre.network.name === 'hardhat' ? 'Hardhat Local' : hre.network.name}"
};
`;
  
  fs.writeFileSync("frontend/config.js", configContent);
  console.log("⚙️  前端配置已更新: frontend/config.js");
  console.log("");
  
  console.log("🎉 部署完成！");
  console.log("");
  console.log("下一步:");
  console.log("  1. 在前端目录运行: npm run dev");
  console.log("  2. 在浏览器中打开页面并连接钱包");
  console.log("  3. 开始创作你的互动小说！");
}

main().catch((error) => {
  console.error("❌ 部署失败:", error);
  process.exitCode = 1;
});
DEPLOY

# 创建 .env 模板
if [ ! -f ".env" ]; then
    cat > .env << 'ENV'
# 本地开发不需要设置
# 部署到测试网/主网时取消注释并填写

# Sepolia 测试网 RPC（可选，默认使用公共节点）
# SEPOLIA_RPC=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# 部署账户私钥（用于测试网/主网部署）
# ⚠️ 警告: 不要将包含真实资金的私钥放在这里！
# PRIVATE_KEY=0x...
ENV
fi

echo ""
echo -e "${GREEN}✅ 初始化完成！${NC}"
echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  选择部署方式${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""
echo "1) 🏠 本地 Hardhat 网络（自动创建临时网络）"
echo "2) 🔗 连接到本地节点（如 Ganache，需先启动）"
echo "3) 🧪 部署到 Sepolia 测试网（需要测试 ETH）"
echo ""
read -p "请选择 [1/2/3]: " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}🚀 部署到本地 Hardhat 网络...${NC}"
        npx hardhat run scripts/deploy.js --network hardhat
        ;;
    2)
        echo ""
        echo -e "${YELLOW}🔗 连接到本地节点...${NC}"
        echo "请确保你的本地节点已启动（如 Ganache 或 hardhat node）"
        echo ""
        read -p "按 Enter 继续..."
        npx hardhat run scripts/deploy.js --network localhost
        ;;
    3)
        echo ""
        echo -e "${YELLOW}🧪 部署到 Sepolia 测试网...${NC}"
        echo ""
        
        # 检查私钥
        if ! grep -q "PRIVATE_KEY=0x" .env; then
            echo "⚠️ 请先配置私钥到 .env 文件"
            echo ""
            echo "格式: PRIVATE_KEY=0x你的私钥"
            echo ""
            echo "或者现在输入（不会显示）:"
            read -s private_key
            echo ""
            if [ -n "$private_key" ]; then
                echo "PRIVATE_KEY=$private_key" >> .env
                echo "✓ 私钥已保存到 .env"
            else
                echo "❌ 没有私钥无法部署"
                exit 1
            fi
        fi
        
        npx hardhat run scripts/deploy.js --network sepolia
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 脚本执行完成！${NC}"
