// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @author JPKP-Kuhn
contract KipuBank {
    /// @notice Total count of deposits and withdraws
    uint public depositCount;
    uint public withdrawCount;

    // Global limit or deposit
    uint public immutable bankCap;
    uint public immutable withdrawLimit;

    uint public constant minimumDeposit = 1 ether;

    mapping (address => uint) private accountsBalance;
    address public immutable owner;


    /// @dev Custom error for zero-value deposits or withdrawals
    error ZeroAmount();

    /// @dev Custom error when deposit would exceed global bank cap
    error ExceedsBankCap();

    /// @dev Custom error when user has insufficient balance
    error InsufficientBalance();

    /// @dev Custom error when withdrawal exceeds per-transaction limit
    error ExceedsWithdrawLimit();

    /// @dev Custom error for failed ETH transfer
    error TransferFailed();

    /// @dev Custom error for reentrancy attempt
    error ReentrancyDetected();
    
    // @notice Flag to prevent reentrancy attacks
    bool private locked;
    modifier noReentrancy(){
        if (locked) revert ReentrancyDetected();
        locked = true;
        _;
        locked = false;
    }

    event DepositOk(address indexed user, uint value, bytes feedback);
    event WithdrawOk(address indexed user, uint value, bytes feedback);
    
    constructor(uint _bankcap, uint _withdrawlimit) {
        owner = msg.sender;
        bankCap = _bankcap * 1e18;
        withdrawLimit = _withdrawlimit * 1e18;
    }

    function _incrementDeposit() private {
        depositCount++;
    }

    function getDepositCount() external view returns (uint) {
        return depositCount;
    }

    function _incrementWithdraw() private {
        withdrawCount++;
    }

    function getWithdrawCount() external view returns (uint) {
        return withdrawCount;
    }

     function getAccountBalance() external view returns (uint) {
        return accountsBalance[msg.sender];
    }
    // Fazer o padrão Checks-Effects-Interactions

    // Deposit tokens, usar um evento pra isso
    function deposit() external payable{
        if (msg.value == 0) revert ZeroAmount();
        if (accountsBalance[msg.sender] + msg.value > bankCap) revert ExceedsBankCap();
        
        accountsBalance[msg.sender] += msg.value;
        emit DepositOk(msg.sender, msg.value, "Deposit Success!");
        _incrementDeposit();
    }

    // Withdraw funds usar um evento pra isso
    function withdraw(uint _value) external noReentrancy {
        if (_value == 0) revert ZeroAmount();
        if (_value > withdrawLimit) revert ExceedsWithdrawLimit();
        if (_value > accountsBalance[msg.sender]) revert InsufficientBalance();

        accountsBalance[msg.sender] -= _value;
        _incrementWithdraw();
        (bool withdrawSuccess, ) = msg.sender.call{value: _value}("");
        if (!withdrawSuccess) revert TransferFailed();
        emit WithdrawOk(msg.sender, _value, "Withdraw Success!");

    }

   
    fallback() external { 
        revert("Invalid Call");
    }
}
