// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NovelContract {
    address public owner;
    uint256 public accessFee;
    mapping(uint256 => Chapter) public chapters;
    mapping(address => uint256) public userPaymentTimes;
    uint256 public chapterCount;

    struct Chapter {
        string ipfsHash;
        uint256 timestamp;
    }

    event ChapterAdded(uint256 indexed chapterId, string ipfsHash);
    event PaymentReceived(address indexed user, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _accessFee) {
        owner = msg.sender;
        accessFee = _accessFee;
        chapterCount = 0;
    }

    function addChapter(string calldata _ipfsHash) external onlyOwner {
        chapterCount++;
        chapters[chapterCount] = Chapter(_ipfsHash, block.timestamp);
        emit ChapterAdded(chapterCount, _ipfsHash);
    }

    function payAccessFee() external payable {
        require(msg.value == accessFee, "Incorrect fee amount");
        userPaymentTimes[msg.sender] = block.timestamp;
        emit PaymentReceived(msg.sender, block.timestamp);
    }

    function getAccessibleChapters() external view returns (Chapter[] memory) {
        uint256 userPaymentTime = userPaymentTimes[msg.sender];
        require(userPaymentTime > 0, "No payment made");
        uint256 accessibleCount = 0;
        for (uint256 i = 1; i <= chapterCount; i++) {
            if (chapters[i].timestamp <= userPaymentTime) {
                accessibleCount++;
            }
        }
        Chapter[] memory result = new Chapter[](accessibleCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= chapterCount; i++) {
            if (chapters[i].timestamp <= userPaymentTime) {
                result[index] = chapters[i];
                index++;
            }
        }
        return result;
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(owner, balance);
    }
}
