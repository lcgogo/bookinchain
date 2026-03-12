// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title InteractiveNovelDAO
 * @notice 互动小说DAO合约：读者投票决定剧情走向，支持分支授权创作
 */
contract InteractiveNovelDAO {
    
    // ============ 状态变量 ============
    address internal author;              // 原作者
    uint256 public baseChapterFee;      // 基础章节费用
    uint256 public voteFee;             // 投票费用
    uint256 public forkLicenseRate;     // 分叉授权费率 (基点 10000=100%)
    
    uint256 public chapterCount;        // 总章节数
    uint256 public storyLineCount;      // 故事线数量
    
    // ============ 数据结构 ============
    
    struct Branch {
        string description;             // 分支剧情描述
        uint256 voteCount;              // 票数
        uint256 voteValue;              // 总投票金额
        bool isWinner;                  // 是否获胜
    }
    
    struct Chapter {
        uint256 id;
        uint256 storyLineId;            // 所属故事线
        uint256 parentChapterId;        // 父章节ID（0表示起始）
        string contentHash;             // IPFS内容哈希
        uint256 createdAt;
        uint256 voteDeadline;           // 投票截止时间
        uint256 winningBranchId;        // 获胜分支ID
        bool isPublished;               // 是否已发布
        bool isVoting;                  // 是否正在投票
        mapping(uint256 => Branch) branches;  // 分支选项
        uint256 branchCount;            // 分支数量
    }
    
    struct StoryLine {
        uint256 id;
        address creator;                // 创建者（可能是原作者或授权者）
        uint256 rootChapterId;          // 起始章节
        uint256 latestChapterId;        // 最新章节
        bool isActive;                  // 是否活跃
        uint256 totalReaders;           // 总阅读人数
        uint256 createdAt;
    }
    
    struct ReaderState {
        uint256 lastReadChapter;        // 最后阅读章节
        uint256 unlockedChapterCount;   // 已解锁章节数
        mapping(uint256 => bool) hasVoted;  // 是否已在某章节投票
    }
    
    struct ForkLicense {
        uint256 chapterId;              // 从哪章开始分叉
        address licensee;               // 被授权人
        uint256 feePaid;                // 支付的费用
        uint256 timestamp;
        bool isActive;
    }
    
    // ============ 映射 ============
    mapping(uint256 => Chapter) public chapters;
    mapping(uint256 => StoryLine) public storyLines;
    mapping(address => ReaderState) public readerStates;
    mapping(uint256 => ForkLicense[]) public chapterForkLicenses;
    mapping(address => uint256[]) public userLicenses;
    
    // ============ 事件 ============
    event ChapterPublished(uint256 indexed chapterId, uint256 indexed storyLineId, string contentHash);
    event BranchesAdded(uint256 indexed chapterId, uint256 branchCount);
    event VoteCast(uint256 indexed chapterId, uint256 indexed branchId, address voter, uint256 value);
    event BranchSelected(uint256 indexed chapterId, uint256 indexed winningBranchId);
    event NextChapterStarted(uint256 indexed prevChapterId, uint256 indexed nextChapterId);
    event ForkLicenseGranted(uint256 indexed chapterId, address indexed licensee, uint256 fee);
    event StoryLineCreated(uint256 indexed storyLineId, address indexed creator, uint256 rootChapterId);
    
    // ============ 修饰器 ============
    modifier onlyAuthor() {
        require(msg.sender == author, "Not author");
        _;
    }
    
    modifier validChapter(uint256 _chapterId) {
        require(_chapterId > 0 && _chapterId <= chapterCount, "Invalid chapter");
        _;
    }
    
    // ============ 构造函数 ============
    constructor(
        uint256 _baseChapterFee,
        uint256 _voteFee,
        uint256 _forkLicenseRate
    ) {
        author = msg.sender;
        baseChapterFee = _baseChapterFee;
        voteFee = _voteFee;
        forkLicenseRate = _forkLicenseRate;
        
        // 初始化主线故事
        storyLineCount = 1;
        StoryLine storage mainLine = storyLines[1];
        mainLine.id = 1;
        mainLine.creator = msg.sender;
        mainLine.isActive = true;
        mainLine.createdAt = block.timestamp;
    }
    
    // ============ 作者功能 ============
    
    // 显式 getter，防止 immutable 导致的问题
    function getAuthor() public view returns (address) {
        return author;
    }
    
    /**
     * @notice 发布新章节（带分支选项）
     * @param _storyLineId 故事线ID
     * @param _contentHash 内容IPFS哈希
     * @param _branchDescriptions 分支剧情描述数组
     * @param _votingDuration 投票持续时间（秒）
     */
    function publishChapterWithBranches(
        uint256 _storyLineId,
        string calldata _contentHash,
        string[] calldata _branchDescriptions,
        uint256 _votingDuration
    ) external onlyAuthor returns (uint256 chapterId) {
        require(_branchDescriptions.length >= 2, "Need at least 2 branches");
        require(_votingDuration > 0, "Invalid voting duration");
        
        chapterCount++;
        chapterId = chapterCount;
        
        Chapter storage chapter = chapters[chapterId];
        chapter.id = chapterId;
        chapter.storyLineId = _storyLineId;
        chapter.contentHash = _contentHash;
        chapter.createdAt = block.timestamp;
        chapter.voteDeadline = block.timestamp + _votingDuration;
        chapter.isPublished = true;
        chapter.isVoting = true;
        
        // 添加上一章的关联（如果不是第一章）
        StoryLine storage storyLine = storyLines[_storyLineId];
        if (storyLine.latestChapterId > 0) {
            chapter.parentChapterId = storyLine.latestChapterId;
        } else {
            storyLine.rootChapterId = chapterId;
        }
        storyLine.latestChapterId = chapterId;
        
        // 添加分支选项
        for (uint256 i = 0; i < _branchDescriptions.length; i++) {
            chapter.branchCount++;
            chapter.branches[chapter.branchCount] = Branch({
                description: _branchDescriptions[i],
                voteCount: 0,
                voteValue: 0,
                isWinner: false
            });
        }
        
        emit ChapterPublished(chapterId, _storyLineId, _contentHash);
        emit BranchesAdded(chapterId, chapter.branchCount);
        
        return chapterId;
    }
    
    /**
     * @notice 结束投票，选择获胜分支
     * @param _chapterId 章节ID
     */
    function finalizeVoting(uint256 _chapterId) external onlyAuthor validChapter(_chapterId) {
        Chapter storage chapter = chapters[_chapterId];
        require(chapter.isVoting, "Not in voting phase");
        require(block.timestamp >= chapter.voteDeadline, "Voting not ended");
        
        // 找出获胜分支
        uint256 winningBranchId = 0;
        uint256 maxVotes = 0;
        
        for (uint256 i = 1; i <= chapter.branchCount; i++) {
            if (chapter.branches[i].voteCount > maxVotes) {
                maxVotes = chapter.branches[i].voteCount;
                winningBranchId = i;
            }
        }
        
        require(winningBranchId > 0, "No votes cast");
        
        chapter.winningBranchId = winningBranchId;
        chapter.branches[winningBranchId].isWinner = true;
        chapter.isVoting = false;
        
        emit BranchSelected(_chapterId, winningBranchId);
    }
    
    // ============ 读者功能 ============
    
    /**
     * @notice 为分支投票（支付费用）
     */
    function voteForBranch(uint256 _chapterId, uint256 _branchId) external payable validChapter(_chapterId) {
        Chapter storage chapter = chapters[_chapterId];
        require(chapter.isVoting, "Not in voting phase");
        require(block.timestamp < chapter.voteDeadline, "Voting ended");
        require(_branchId > 0 && _branchId <= chapter.branchCount, "Invalid branch");
        require(!readerStates[msg.sender].hasVoted[_chapterId], "Already voted");
        require(msg.value >= voteFee, "Insufficient vote fee");
        
        chapter.branches[_branchId].voteCount++;
        chapter.branches[_branchId].voteValue += msg.value;
        readerStates[msg.sender].hasVoted[_chapterId] = true;
        
        // 更新阅读统计
        StoryLine storage storyLine = storyLines[chapter.storyLineId];
        if (!hasReadStoryLine(msg.sender, chapter.storyLineId)) {
            storyLine.totalReaders++;
        }
        
        emit VoteCast(_chapterId, _branchId, msg.sender, msg.value);
    }
    
    /**
     * @notice 批量解锁章节（购买阅读权限）
     */
    function unlockChapters(uint256 _storyLineId, uint256 _count) external payable {
        StoryLine storage storyLine = storyLines[_storyLineId];
        require(storyLine.isActive, "Story line not active");
        
        ReaderState storage reader = readerStates[msg.sender];
        uint256 currentUnlocked = reader.unlockedChapterCount;
        
        // 计算从当前解锁位置开始的章节费用
        uint256 totalFee = 0;
        uint256 chapterPointer = storyLine.rootChapterId;
        uint256 unlocked = 0;
        
        for (uint256 i = 0; i < currentUnlocked && chapterPointer > 0; i++) {
            chapterPointer = chapters[chapterPointer].parentChapterId == 0 ? 
                0 : chapterPointer + 1; // 简化处理，实际需要遍历
        }
        
        // 简化计算：每章基础费用
        totalFee = baseChapterFee * _count;
        require(msg.value >= totalFee, "Insufficient fee");
        
        reader.unlockedChapterCount += _count;
        
        // 退款多余金额
        if (msg.value > totalFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalFee}("");
            require(success, "Transfer failed");
        }
    }
    
    // ============ 分叉授权功能 ============
    
    /**
     * @notice 计算分叉授权费用
     * @param _chapterId 从哪章开始分叉
     */
    function calculateForkFee(uint256 _chapterId) public view validChapter(_chapterId) returns (uint256) {
        Chapter storage chapter = chapters[_chapterId];
        StoryLine storage storyLine = storyLines[chapter.storyLineId];
        
        // 计算到该章节的所有前置章节费用
        uint256 ancestorCount = 0;
        uint256 currentId = _chapterId;
        
        while (currentId > 0) {
            ancestorCount++;
            currentId = chapters[currentId].parentChapterId;
        }
        
        // 基础费用 = 前置章节数 * 单章费用
        uint256 baseCost = ancestorCount * baseChapterFee;
        
        // 阅读量系数加成
        // 读者越多，分叉授权费越高
        uint256 readerMultiplier = 10000 + (storyLine.totalReaders * forkLicenseRate / 1000);
        
        return (baseCost * readerMultiplier) / 10000;
    }
    
    /**
     * @notice 申请分叉授权（从某章节开始自己的故事线）
     */
    function requestForkLicense(uint256 _chapterId) external payable validChapter(_chapterId) {
        uint256 fee = calculateForkFee(_chapterId);
        require(msg.value >= fee, "Insufficient fee");
        
        // 创建新的故事线
        storyLineCount++;
        uint256 newStoryLineId = storyLineCount;
        
        StoryLine storage newStoryLine = storyLines[newStoryLineId];
        newStoryLine.id = newStoryLineId;
        newStoryLine.creator = msg.sender;
        newStoryLine.rootChapterId = _chapterId; // 从分叉点开始
        newStoryLine.isActive = true;
        newStoryLine.createdAt = block.timestamp;
        
        // 记录授权
        ForkLicense memory license = ForkLicense({
            chapterId: _chapterId,
            licensee: msg.sender,
            feePaid: fee,
            timestamp: block.timestamp,
            isActive: true
        });
        
        chapterForkLicenses[_chapterId].push(license);
        userLicenses[msg.sender].push(_chapterId);
        
        emit ForkLicenseGranted(_chapterId, msg.sender, fee);
        emit StoryLineCreated(newStoryLineId, msg.sender, _chapterId);
        
        // 退款
        if (msg.value > fee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - fee}("");
            require(success, "Transfer failed");
        }
    }
    
    /**
     * @notice 在授权的故事线上继续创作
     */
    function continueStoryLine(
        uint256 _storyLineId,
        string calldata _contentHash,
        string[] calldata _branchDescriptions,
        uint256 _votingDuration
    ) external returns (uint256 chapterId) {
        StoryLine storage storyLine = storyLines[_storyLineId];
        require(storyLine.creator == msg.sender, "Not story line owner");
        require(storyLine.isActive, "Story line not active");
        
        // 类似 publishChapterWithBranches 的逻辑
        chapterCount++;
        chapterId = chapterCount;
        
        Chapter storage chapter = chapters[chapterId];
        chapter.id = chapterId;
        chapter.storyLineId = _storyLineId;
        chapter.contentHash = _contentHash;
        chapter.parentChapterId = storyLine.latestChapterId;
        chapter.createdAt = block.timestamp;
        chapter.voteDeadline = block.timestamp + _votingDuration;
        chapter.isPublished = true;
        chapter.isVoting = true;
        
        storyLine.latestChapterId = chapterId;
        
        for (uint256 i = 0; i < _branchDescriptions.length; i++) {
            chapter.branchCount++;
            chapter.branches[chapter.branchCount] = Branch({
                description: _branchDescriptions[i],
                voteCount: 0,
                voteValue: 0,
                isWinner: false
            });
        }
        
        emit ChapterPublished(chapterId, _storyLineId, _contentHash);
        
        return chapterId;
    }
    
    // ============ 查询功能 ============
    
    function getChapterBranches(uint256 _chapterId) external view returns (Branch[] memory) {
        Chapter storage chapter = chapters[_chapterId];
        Branch[] memory result = new Branch[](chapter.branchCount);
        
        for (uint256 i = 1; i <= chapter.branchCount; i++) {
            result[i-1] = chapter.branches[i];
        }
        
        return result;
    }
    
    function getChapterForkLicenses(uint256 _chapterId) external view returns (ForkLicense[] memory) {
        return chapterForkLicenses[_chapterId];
    }
    
    function hasReadStoryLine(address _reader, uint256 _storyLineId) public view returns (bool) {
        ReaderState storage reader = readerStates[_reader];
        return reader.unlockedChapterCount > 0;
    }
    
    // ============ 资金管理 ============
    
    function withdraw() external onlyAuthor {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        (bool success, ) = payable(author).call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    function updateFees(
        uint256 _baseChapterFee,
        uint256 _voteFee,
        uint256 _forkLicenseRate
    ) external onlyAuthor {
        baseChapterFee = _baseChapterFee;
        voteFee = _voteFee;
        forkLicenseRate = _forkLicenseRate;
    }
    
    receive() external payable {}
}