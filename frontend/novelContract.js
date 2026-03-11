// Interactive Novel DAO - Frontend using ethers.js v6

import { ethers } from 'ethers';

// ============ 配置 ============
const CONTRACT_ADDRESS = "0x..."; // 部署后填入
const RPC_URL = "https://sepolia.ethereum.org"; // 或其他网络

// ABI - 与合约方法对应
const CONTRACT_ABI = [
  // 读取函数
  "function author() view returns (address)",
  "function baseChapterFee() view returns (uint256)",
  "function voteFee() view returns (uint256)",
  "function forkLicenseRate() view returns (uint256)",
  "function chapterCount() view returns (uint256)",
  "function storyLineCount() view returns (uint256)",
  "function chapters(uint256) view returns (uint256 id, uint256 storyLineId, uint256 parentChapterId, string contentHash, uint256 createdAt, uint256 voteDeadline, uint256 winningBranchId, bool isPublished, bool isVoting)",
  "function storyLines(uint256) view returns (uint256 id, address creator, uint256 rootChapterId, uint256 latestChapterId, bool isActive, uint256 totalReaders, uint256 createdAt)",
  "function readerStates(address) view returns (uint256 lastReadChapter, uint256 unlockedChapterCount)",
  "function calculateForkFee(uint256 _chapterId) view returns (uint256)",
  
  // 写入函数
  "function publishChapterWithBranches(uint256 _storyLineId, string calldata _contentHash, string[] calldata _branchDescriptions, uint256 _votingDuration) returns (uint256)",
  "function finalizeVoting(uint256 _chapterId)",
  "function voteForBranch(uint256 _chapterId, uint256 _branchId) payable",
  "function unlockChapters(uint256 _storyLineId, uint256 _count) payable",
  "function requestForkLicense(uint256 _chapterId) payable",
  "function continueStoryLine(uint256 _storyLineId, string calldata _contentHash, string[] calldata _branchDescriptions, uint256 _votingDuration) returns (uint256)",
  "function withdraw()",
  "function updateFees(uint256 _baseChapterFee, uint256 _voteFee, uint256 _forkLicenseRate)",
  
  // 查询函数
  "function getChapterBranches(uint256 _chapterId) view returns (tuple(string description, uint256 voteCount, uint256 voteValue, bool isWinner)[])",
  "function getChapterForkLicenses(uint256 _chapterId) view returns (tuple(uint256 chapterId, address licensee, uint256 feePaid, uint256 timestamp, bool isActive)[])",
  
  // 事件
  "event ChapterPublished(uint256 indexed chapterId, uint256 indexed storyLineId, string contentHash)",
  "event VoteCast(uint256 indexed chapterId, uint256 indexed branchId, address voter, uint256 value)",
  "event BranchSelected(uint256 indexed chapterId, uint256 indexed winningBranchId)",
  "event ForkLicenseGranted(uint256 indexed chapterId, address indexed licensee, uint256 fee)",
  "event StoryLineCreated(uint256 indexed storyLineId, address indexed creator, uint256 rootChapterId)"
];

// ============ 工具函数 ============
const formatEther = (wei) => ethers.formatEther(wei);
const parseEther = (eth) => ethers.parseEther(eth);
const formatTime = (timestamp) => new Date(Number(timestamp) * 1000).toLocaleString();

// ============ Provider 管理 ============
class NovelContract {
  constructor() {
    this.provider = null;
    this.signer = null;
    this.contract = null;
  }

  // 连接钱包
  async connect() {
    if (typeof window.ethereum === 'undefined') {
      throw new Error('请安装 MetaMask!');
    }
    
    this.provider = new ethers.BrowserProvider(window.ethereum);
    await this.provider.send("eth_requestAccounts", []);
    this.signer = await this.provider.getSigner();
    
    this.contract = new ethers.Contract(
      CONTRACT_ADDRESS,
      CONTRACT_ABI,
      this.signer
    );
    
    return {
      address: await this.signer.getAddress(),
      network: (await this.provider.getNetwork()).name
    };
  }

  // 检查是否已连接
  isConnected() {
    return this.contract !== null;
  }

  // 获取合约基本信息
  async getContractInfo() {
    const [author, baseChapterFee, voteFee, forkLicenseRate, chapterCount, storyLineCount] = await Promise.all([
      this.contract.author(),
      this.contract.baseChapterFee(),
      this.contract.voteFee(),
      this.contract.forkLicenseRate(),
      this.contract.chapterCount(),
      this.contract.storyLineCount()
    ]);
    
    return {
      author,
      baseChapterFee: formatEther(baseChapterFee),
      voteFee: formatEther(voteFee),
      forkLicenseRate: Number(forkLicenseRate) / 100 + '%',
      chapterCount: Number(chapterCount),
      storyLineCount: Number(storyLineCount)
    };
  }

  // ============ 作者功能 ============

  // 发布章节（带分支）
  async publishChapter(storyLineId, contentHash, branchDescriptions, votingDurationDays) {
    const votingDuration = votingDurationDays * 24 * 60 * 60; // 转换为秒
    const tx = await this.contract.publishChapterWithBranches(
      storyLineId,
      contentHash,
      branchDescriptions,
      votingDuration
    );
    const receipt = await tx.wait();
    
    // 解析事件获取 chapterId
    const event = receipt.logs.find(
      log => log.fragment?.name === 'ChapterPublished'
    );
    const chapterId = event ? event.args.chapterId : null;
    
    return { tx, chapterId };
  }

  // 结束投票
  async finalizeVoting(chapterId) {
    const tx = await this.contract.finalizeVoting(chapterId);
    return await tx.wait();
  }

  // ============ 读者功能 ============

  // 投票
  async vote(chapterId, branchId) {
    const fee = await this.contract.voteFee();
    const tx = await this.contract.voteForBranch(chapterId, branchId, {
      value: fee
    });
    return await tx.wait();
  }

  // 解锁章节
  async unlockChapters(storyLineId, count) {
    const baseFee = await this.contract.baseChapterFee();
    const totalFee = baseFee * BigInt(count);
    
    const tx = await this.contract.unlockChapters(storyLineId, count, {
      value: totalFee
    });
    return await tx.wait();
  }

  // 计算分叉费用
  async calculateForkFee(chapterId) {
    const fee = await this.contract.calculateForkFee(chapterId);
    return formatEther(fee);
  }

  // 申请分叉授权
  async requestForkLicense(chapterId) {
    const fee = await this.contract.calculateForkFee(chapterId);
    const tx = await this.contract.requestForkLicense(chapterId, {
      value: fee
    });
    const receipt = await tx.wait();
    
    // 解析事件获取新故事线ID
    const event = receipt.logs.find(
      log => log.fragment?.name === 'StoryLineCreated'
    );
    const storyLineId = event ? event.args.storyLineId : null;
    
    return { tx, storyLineId };
  }

  // 在自己的故事线上继续创作
  async continueStoryLine(storyLineId, contentHash, branchDescriptions, votingDurationDays) {
    const votingDuration = votingDurationDays * 24 * 60 * 60;
    const tx = await this.contract.continueStoryLine(
      storyLineId,
      contentHash,
      branchDescriptions,
      votingDuration
    );
    const receipt = await tx.wait();
    
    const event = receipt.logs.find(
      log => log.fragment?.name === 'ChapterPublished'
    );
    const chapterId = event ? event.args.chapterId : null;
    
    return { tx, chapterId };
  }

  // ============ 查询功能 ============

  // 获取章节信息
  async getChapter(chapterId) {
    const [chapter, branches] = await Promise.all([
      this.contract.chapters(chapterId),
      this.contract.getChapterBranches(chapterId)
    ]);
    
    return {
      id: Number(chapter.id),
      storyLineId: Number(chapter.storyLineId),
      parentChapterId: Number(chapter.parentChapterId),
      contentHash: chapter.contentHash,
      createdAt: formatTime(chapter.createdAt),
      voteDeadline: formatTime(chapter.voteDeadline),
      winningBranchId: Number(chapter.winningBranchId),
      isPublished: chapter.isPublished,
      isVoting: chapter.isVoting,
      branches: branches.map((b, i) => ({
        id: i + 1,
        description: b.description,
        voteCount: Number(b.voteCount),
        voteValue: formatEther(b.voteValue),
        isWinner: b.isWinner
      }))
    };
  }

  // 获取故事线信息
  async getStoryLine(storyLineId) {
    const storyLine = await this.contract.storyLines(storyLineId);
    
    return {
      id: Number(storyLine.id),
      creator: storyLine.creator,
      rootChapterId: Number(storyLine.rootChapterId),
      latestChapterId: Number(storyLine.latestChapterId),
      isActive: storyLine.isActive,
      totalReaders: Number(storyLine.totalReaders),
      createdAt: formatTime(storyLine.createdAt)
    };
  }

  // 获取读者的解锁状态
  async getReaderState(walletAddress) {
    const state = await this.contract.readerStates(walletAddress);
    return {
      lastReadChapter: Number(state.lastReadChapter),
      unlockedChapterCount: Number(state.unlockedChapterCount)
    };
  }

  // 获取章节的分叉授权记录
  async getForkLicenses(chapterId) {
    const licenses = await this.contract.getChapterForkLicenses(chapterId);
    return licenses.map(l => ({
      chapterId: Number(l.chapterId),
      licensee: l.licensee,
      feePaid: formatEther(l.feePaid),
      timestamp: formatTime(l.timestamp),
      isActive: l.isActive
    }));
  }

  // ============ 资金管理 ============

  // 提取收益（仅作者）
  async withdraw() {
    const tx = await this.contract.withdraw();
    return await tx.wait();
  }

  // 更新费用（仅作者）
  async updateFees(baseChapterFeeEth, voteFeeEth, forkLicenseRate) {
    const tx = await this.contract.updateFees(
      parseEther(baseChapterFeeEth.toString()),
      parseEther(voteFeeEth.toString()),
      forkLicenseRate
    );
    return await tx.wait();
  }

  // ============ 事件监听 ============

  // 监听新章节发布
  onChapterPublished(callback) {
    this.contract.on("ChapterPublished", (chapterId, storyLineId, contentHash) => {
      callback({ chapterId: Number(chapterId), storyLineId: Number(storyLineId), contentHash });
    });
  }

  // 监听投票
  onVoteCast(callback) {
    this.contract.on("VoteCast", (chapterId, branchId, voter, value) => {
      callback({ 
        chapterId: Number(chapterId), 
        branchId: Number(branchId), 
        voter, 
        value: formatEther(value) 
      });
    });
  }

  // 监听分支选定
  onBranchSelected(callback) {
    this.contract.on("BranchSelected", (chapterId, winningBranchId) => {
      callback({ chapterId: Number(chapterId), winningBranchId: Number(winningBranchId) });
    });
  }

  // 监听分叉授权
  onForkLicenseGranted(callback) {
    this.contract.on("ForkLicenseGranted", (chapterId, licensee, fee) => {
      callback({ chapterId: Number(chapterId), licensee, fee: formatEther(fee) });
    });
  }
}

export const novelContract = new NovelContract();
export default novelContract;
