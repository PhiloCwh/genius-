// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract geniustoken4{
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    address public pair;        // DEX 交易对
    address public taxReceiver; // 税收地址
    uint256 public fee;

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
        string memory _symbol,
        address receiver,
        uint256 _fee
    ) {

        require(_fee > 0 && _fee < 100,"require 0 - 100");
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        taxReceiver = msg.sender;

        uint256 supply = 1_000_000_000 * 1e18;
        totalSupply = supply;
        balanceOf[receiver] = supply;
        fee = _fee;

        // 默认白名单
        whiteList[msg.sender] = true;
        whiteList[receiver] = true;

        emit Transfer(address(0), receiver, supply);
    }

    // =====================
    // 管理函数
    // =====================

    function setPair(address _pair) external onlyOwner {
        pair = _pair;
    }

    function setTaxReceiver(address _receiver) external onlyOwner {
        taxReceiver = _receiver;
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
    // 核心逻辑：卖出税
    // =====================

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(!blackList[from], "SENDER_BLACKLISTED");
        require(!blackList[to], "RECEIVER_BLACKLISTED");
        require(balanceOf[from] >= amount, "BALANCE_LOW");

        uint256 taxAmount = 0;

        // ⭐ 卖给 DEX Pair 才收税
        if (to == pair && !whiteList[from]) {
            taxAmount = amount * fee / 100; // 50%
        }

        uint256 sendAmount = amount - taxAmount;

        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += sendAmount;

            if (taxAmount > 0) {
                balanceOf[taxReceiver] += taxAmount;
            }
        }

        emit Transfer(from, to, sendAmount);

        if (taxAmount > 0) {
            emit Transfer(from, taxReceiver, taxAmount);
        }
    }
}
