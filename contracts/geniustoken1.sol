// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract  Genius1{
    // --------------------
    // --------------------
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --------------------
    // --------------------
    mapping(address => bool) public blackList;
    // --------------------
    // Events
    // --------------------
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address receiver
    ) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;

        uint256 supply = 1000000 * 1e18;
        totalSupply = supply;
        balanceOf[receiver] = supply;

        emit Transfer(address(0), receiver, supply);
    }

    // =========================
    // =========================
    function setBlackList(address user, bool status) external onlyOwner {
        blackList[user] = status;
    }

    function batchSetBlackList(address[] calldata users, bool status)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            blackList[users[i]] = status;
        }
    }

    // =========================
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
    // =========================
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(!blackList[from], "SENDER_BLACKLISTED");
        require(!blackList[to], "RECEIVER_BLACKLISTED");
        require(balanceOf[from] >= amount, "BALANCE_LOW");

        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}
