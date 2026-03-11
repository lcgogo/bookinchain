#!/bin/bash

# Interactive Novel DAO - 一键部署脚本

set -e

echo "====================================="
echo "  Interactive Novel DAO 部署脚本"
echo "====================================="
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "错误: 未安装 Node.js"
    echo "请访问 https://nodejs.org/ 安装"
    exit 1
fi

echo "✓ Node.js 版本: $(node --version)"

# 检查 npm
if ! command -v npm &> /dev/null; then
    echo "错误: 未安装 npm"
    exit 1
fi

echo "✓ npm 版本: $(npm --version)"
echo ""

# 询问部署类型
echo "选择部署方式:"
echo "  1) 只部署前端（需要现有合约地址）"
echo "  2) 完整部署（合约 + 前端）"
read -p "请输入选择 [1/2]: " deploy_type

if [ "$deploy_type" != "1" ] && [ "$deploy_type" != "2" ]; then
    echo "无效选择"
    exit 1
fi

# 部署合约
if [ "$deploy_type" == "2" ]; then
    echo ""
    echo "====================================="
    echo "  步骤 1/2: 部署智能合约"
    echo "====================================="
    echo ""
    echo "推荐使用 Remix IDE 部署合约（更简单）"
    echo "访问: https://remix.ethereum.org"
    echo ""
    echo "快速步骤："
    echo "  1. 将 InteractiveNovelDAO.sol 复制到 Remix"
    echo "  2. 编译（Solidity 0.8.20）"
    echo "  3. 连接 MetaMask（Sepolia 测试网）"
    echo "  4. 部署，参数：0.01 ether, 0.001 ether, 5000"
    echo "  5. 复制合约地址"
    echo ""
    read -p "部署完成后，请输入合约地址: " contract_address

    if [ -z "$contract_address" ]; then
        echo "错误: 合约地址不能为空"
        exit 1
    fi
else
    echo ""
    echo "====================================="
    echo "  步骤 1/2: 配置合约地址"
    echo "====================================="
    echo ""
    read -p "请输入现有合约地址: " contract_address

    if [ -z "$contract_address" ]; then
        echo "错误: 合约地址不能为空"
        exit 1
    fi
fi

# 检查前端目录
if [ ! -d "frontend" ]; then
    echo "错误: 找不到 frontend 目录"
    exit 1
fi

cd frontend

# 安装依赖
echo ""
echo "====================================="
echo "  步骤 2/2: 配置并部署前端"
echo "====================================="
echo ""

echo "安装依赖..."
npm install

# 更新配置
echo "更新合约地址..."
cat > config.js << EOF
// 配置文件 - 自动生成

// 合约部署地址
export const CONTRACT_ADDRESS = "$contract_address";

// RPC 节点
export const RPC_URL = "https://rpc.sepolia.org";

// IPFS 网关
export const IPFS_GATEWAY = "https://ipfs.io/ipfs/";

// 网络配置
export const NETWORK = {
  chainId: 11155111n, // Sepolia
  name: "Sepolia"
};
EOF

echo "✓ 配置已更新"
echo ""

# 构建项目
echo "构建项目..."
npm run build

echo "✓ 构建完成"
echo ""

# 询问部署平台
echo "选择前端部署平台:"
echo "  1) 本地预览"
echo "  2) Vercel (推荐)"
echo "  3) Netlify"
echo "  4) GitHub Pages"
read -p "请输入选择 [1/2/3/4]: " platform

case $platform in
    1)
        echo ""
        echo "启动本地预览..."
        npx serve dist
        ;;
    2)
        echo ""
        echo "部署到 Vercel:"
        echo "  1. 访问 https://vercel.com"
        echo "  2. 登录并导入项目"
        echo "  3. 上传 dist/ 文件夹"
        echo "  或使用 Vercel CLI: vercel --prod"
        echo ""
        echo "安装 Vercel CLI?"
        read -p "安装? [y/N]: " install_vercel
        if [ "$install_vercel" == "y" ] || [ "$install_vercel" == "Y" ]; then
            npm i -g vercel
            vercel login
            vercel --prod
        fi
        ;;
    3)
        echo ""
        echo "部署到 Netlify:"
        echo "  1. 访问 https://app.netlify.com/drop"
        echo "  2. 拖拽 dist/ 文件夹"
        ;;
    4)
        echo ""
        echo "部署到 GitHub Pages:"
        echo "  1. 将代码推送到 GitHub"
        echo "  2. 启用 GitHub Pages"
        echo "  3. 设置源目录为 dist"
        ;;
    *)
        echo "跳过部署"
        ;;
esac

echo ""
echo "====================================="
echo "  部署完成！"
echo "====================================="
echo ""
echo "合约地址: $contract_address"
echo "前端目录: frontend/dist"
echo ""
echo "下一步："
echo "  1. 确保 MetaMask 已安装并连接"
echo "  2. 获取 Sepolia 测试网 ETH"
echo "  3. 访问部署的前端地址"
echo ""
echo "测试网水龙头："
echo "  - https://sepoliafaucet.com/"
echo "  - https://faucet.sepolia.dev/"
echo ""
