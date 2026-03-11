// React Component Example - Interactive Novel Frontend

import React, { useState, useEffect } from 'react';
import novelContract from './novelContract';
import { IPFS_GATEWAY } from './config'; // 如 'https://ipfs.io/ipfs/'

// ============ 主应用组件 ============
function App() {
  const [wallet, setWallet] = useState(null);
  const [contractInfo, setContractInfo] = useState(null);
  const [currentChapter, setCurrentChapter] = useState(null);
  const [isAuthor, setIsAuthor] = useState(false);
  const [loading, setLoading] = useState(false);

  // 初始化连接钱包
  const connectWallet = async () => {
    try {
      setLoading(true);
      const res = await novelContract.connect();
      setWallet(res);
      alert(`已连接钱包: ${res.address}`);
      await loadContractInfo();
      
      // 检查是否是作者
      const info = await novelContract.getContractInfo();
      setIsAuthor(info.author.toLowerCase() === res.address.toLowerCase());
    } catch (error) {
      alert(`连接失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 加载合约基本信息
  const loadContractInfo = async () => {
    if (!novelContract.isConnected()) return;
    try {
      const info = await novelContract.getContractInfo();
      setContractInfo(info);
      return info;
    } catch (error) {
      console.error('加载信息失败:', error);
    }
  };

  // ============ 页面组件 ============

  // 连接钱包页面
  if (!wallet) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50 p-4">
        <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
          <h2 className="text-2xl font-bold mb-6 text-center">互动小说DAO</h2>
          <p className="text-gray-600 mb-6 text-center">基于区块链的互动式创作平台</p>
          <button 
            className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg hover:bg-blue-700 transition-colors"
            onClick={connectWallet}
            disabled={loading}
          >
            {loading ? '连接中...' : '连接 MetaMask'}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 导航栏 */}
      <nav className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="flex items-center">
              <h1 className="text-xl font-bold text-gray-900">互动小说DAO</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-500">
                钱包: {wallet.address.slice(0, 6)}...{wallet.address.slice(-4)}
              </span>
              {isAuthor && (
                <span className="bg-green-100 text-green-800 text-xs px-2 py-1 rounded-full">
                  作者权限
                </span>
              )}
            </div>
          </div>
        </div>
      </nav>

      {/* 主内容 */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 合约信息卡片 */}
        {contractInfo && (
          <div className="bg-white rounded-lg shadow p-6 mb-8">
            <h3 className="text-lg font-semibold mb-4">合约信息</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-500">总章节数</p>
                <p className="font-medium">{contractInfo.chapterCount}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">故事线数量</p>
                <p className="font-medium">{contractInfo.storyLineCount}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">单章阅读费</p>
                <p className="font-medium">{contractInfo.baseChapterFee} ETH</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">投票费用</p>
                <p className="font-medium">{contractInfo.voteFee} ETH</p>
              </div>
            </div>
          </div>
        )}

        {/* 操作区 */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* 左侧：作者操作区（仅作者可见） */}
          {isAuthor && (
            <div className="lg:col-span-1">
              <AuthorPanel reload={loadContractInfo} />
            </div>
          )}

          {/* 右侧：章节展示与读者操作区 */}
          <div className={`${isAuthor ? 'lg:col-span-2' : 'lg:col-span-3'}`}>
            <ChapterView 
              currentChapter={currentChapter}
              setCurrentChapter={setCurrentChapter}
              reload={loadContractInfo}
            />
          </div>
        </div>
      </main>
    </div>
  );
}

// ============ 作者面板组件 ============
function AuthorPanel({ reload }) {
  const [form, setForm] = useState({
    storyLineId: 1,
    contentHash: '',
    branches: ['', ''],
    votingDays: 7
  });
  const [loading, setLoading] = useState(false);

  const handlePublish = async () => {
    try {
      setLoading(true);
      const { storyLineId, contentHash, branches, votingDays } = form;
      
      const filteredBranches = branches.filter(b => b.trim() !== '');
      if (filteredBranches.length < 2) {
        alert('至少需要两个分支');
        return;
      }
      
      const res = await novelContract.publishChapter(
        storyLineId,
        contentHash,
        filteredBranches,
        votingDays
      );
      
      alert(`章节发布成功！章节ID: ${res.chapterId}`);
      reload();
      
      // 重置表单
      setForm({
        storyLineId: 1,
        contentHash: '',
        branches: ['', ''],
        votingDays: 7
      });
    } catch (error) {
      alert(`发布失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const addBranch = () => {
    setForm(prev => ({
      ...prev,
      branches: [...prev.branches, '']
    }));
  };

  const removeBranch = (index) => {
    if (form.branches.length <= 2) return;
    setForm(prev => ({
      ...prev,
      branches: prev.branches.filter((_, i) => i !== index)
    }));
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-semibold mb-4">作者操作区</h3>
      
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            故事线ID
          </label>
          <input
            type="number"
            min="1"
            className="w-full border rounded-lg px-3 py-2"
            value={form.storyLineId}
            onChange={(e) => setForm(prev => ({ ...prev, storyLineId: Number(e.target.value) }))}
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            内容IPFS哈希
          </label>
          <input
            type="text"
            className="w-full border rounded-lg px-3 py-2"
            placeholder="Qm..."
            value={form.contentHash}
            onChange={(e) => setForm(prev => ({ ...prev, contentHash: e.target.value }))}
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            分支选项
          </label>
          {form.branches.map((branch, index) => (
            <div key={index} className="flex gap-2 mb-2">
              <input
                type="text"
                className="flex-1 border rounded-lg px-3 py-2"
                placeholder={`分支 ${index + 1}`}
                value={branch}
                onChange={(e) => {
                  const newBranches = [...form.branches];
                  newBranches[index] = e.target.value;
                  setForm(prev => ({ ...prev, branches: newBranches }));
                }}
              />
              {form.branches.length > 2 && (
                <button
                  type="button"
                  className="px-2 py-1 bg-red-100 text-red-600 rounded"
                  onClick={() => removeBranch(index)}
                >
                  删除
                </button>
              )}
            </div>
          ))}
          <button
            type="button"
            className="mt-2 text-sm text-blue-600 hover:text-blue-800"
            onClick={addBranch}
          >
            + 添加分支
          </button>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            投票持续时间（天）
          </label>
          <input
            type="number"
            min="1"
            max="30"
            className="w-full border rounded-lg px-3 py-2"
            value={form.votingDays}
            onChange={(e) => setForm(prev => ({ ...prev, votingDays: Number(e.target.value) }))}
          />
        </div>

        <button
          className="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
          onClick={handlePublish}
          disabled={loading}
        >
          {loading ? '发布中...' : '发布章节'}
        </button>
      </div>
    </div>
  );
}

// ============ 章节展示组件 ============
function ChapterView({ currentChapter, setCurrentChapter, reload }) {
  const [chapterId, setChapterId] = useState('');
  const [chapter, setChapter] = useState(null);
  const [loading, setLoading] = useState(false);

  const loadChapter = async () => {
    if (!chapterId) return;
    try {
      setLoading(true);
      const chap = await novelContract.getChapter(chapterId);
      setChapter(chap);
    } catch (error) {
      alert(`加载章节失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleVote = async (branchId) => {
    try {
      setLoading(true);
      await novelContract.vote(chapter.id, branchId);
      alert('投票成功！');
      loadChapter();
      reload();
    } catch (error) {
      alert(`投票失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleFork = async () => {
    try {
      setLoading(true);
      const fee = await novelContract.calculateForkFee(chapter.id);
      if (window.confirm(`分叉授权需要 ${fee} ETH，确认支付？`)) {
        const res = await novelContract.requestForkLicense(chapter.id);
        alert(`分叉成功！新故事线ID: ${res.storyLineId}`);
        reload();
      }
    } catch (error) {
      alert(`分叉失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleFinalizeVoting = async () => {
    try {
      setLoading(true);
      await novelContract.finalizeVoting(chapter.id);
      alert('投票已结束，已确定获胜分支！');
      loadChapter();
      reload();
    } catch (error) {
      alert(`结束投票失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center gap-4 mb-6">
        <input
          type="number"
          min="1"
          className="flex-1 border rounded-lg px-3 py-2"
          placeholder="输入章节ID"
          value={chapterId}
          onChange={(e) => setChapterId(e.target.value)}
        />
        <button
          className="bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
          onClick={loadChapter}
          disabled={loading || !chapterId}
        >
          加载章节
        </button>
      </div>

      {loading && <div className="text-center py-8">加载中...</div>}

      {chapter && (
        <div className="space-y-6">
          {/* 章节头信息 */}
          <div className="border-b pb-4">
            <h3 className="text-xl font-bold mb-2">
              第 {chapter.id} 章
            </h3>
            <div className="flex flex-wrap gap-4 text-sm text-gray-500">
              <span>故事线ID: {chapter.storyLineId}</span>
              <span>发布时间: {chapter.createdAt}</span>
              <span>投票截止: {chapter.voteDeadline}</span>
              <span>状态: {chapter.isVoting ? '投票中' : '投票已结束'}</span>
            </div>
          </div>

          {/* 内容预览 */}
          <div>
            <h4 className="text-sm font-medium text-gray-700 mb-2">内容预览</h4>
            <div className="bg-gray-50 rounded-lg p-4 border">
              <p className="text-gray-700">
                <a
                  href={`${IPFS_GATEWAY}${chapter.contentHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:underline"
                >
                  查看完整内容 (IPFS: {chapter.contentHash.slice(0, 10)}...)
                </a>
              </p>
            </div>
          </div>

          {/* 分支选项 */}
          <div>
            <h4 className="text-sm font-medium text-gray-700 mb-3">分支选项</h4>
            <div className="space-y-3">
              {chapter.branches.map((branch) => (
                <div
                  key={branch.id}
                  className={`border rounded-lg p-4 ${
                    branch.isWinner ? 'border-green-500 bg-green-50' : ''
                  }`}
                >
                  <div className="flex justify-between items-start mb-2">
                    <div className="font-medium">
                      {branch.description}
                      {branch.isWinner && (
                        <span className="ml-2 text-xs bg-green-600 text-white px-2 py-0.5 rounded-full">
                          获胜分支
                        </span>
                      )}
                    </div>
                    <div className="text-sm text-gray-500">
                      {branch.voteCount} 票 ({branch.voteValue} ETH)
                    </div>
                  </div>
                  {chapter.isVoting && (
                    <button
                      className="mt-2 bg-blue-600 text-white py-1 px-3 text-sm rounded hover:bg-blue-700 transition-colors disabled:opacity-50"
                      onClick={() => handleVote(branch.id)}
                      disabled={loading}
                    >
                      投此分支
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* 操作按钮区 */}
          <div className="flex flex-wrap gap-3 pt-4 border-t">
            <button
              className="bg-purple-600 text-white py-2 px-4 rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50"
              onClick={handleFork}
              disabled={loading}
            >
              从此分叉创作
            </button>
            
            {/* 作者可见操作 */}
            {chapter.isVoting && (
              <button
                className="bg-yellow-600 text-white py-2 px-4 rounded-lg hover:bg-yellow-700 transition-colors disabled:opacity-50"
                onClick={handleFinalizeVoting}
                disabled={loading}
              >
                结束投票
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
