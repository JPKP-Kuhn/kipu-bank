// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @author JPKP-Kuhn
contract KipuBank {
    /// @notice Total count of deposits and withdraws
    uint256 public depositCount;
    uint256 public withdrawCount;

    /// @notice Global limit or deposit
    uint256 public immutable bankCap;
    uint256 public immutable withdrawLimit;

    uint256 public totalBalance;

    uint256 public constant minimumDeposit = 0.01 ether;

    mapping (address => uint256) private accountsBalance;

    /// @dev Custom error for zero-value deposits or withdrawls
    error ZeroAmount();

    /// @dev Custom error for minimun deposit value
    error MinimunDepositRequired();

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
    
    /// @dev Modifier to prevent reentrancy attacks in functions that perform externall calls
    bool private locked;
    modifier noReentrancy(){
        if (locked) revert ReentrancyDetected();
        locked = true;
        _;
        locked = false;
    }

    /// @notice Event emmitted on successful deposit and withdraw
    event DepositOk(address indexed user, uint value, bytes feedback);
    event WithdrawOk(address indexed user, uint value, bytes feedback);
    
    /// @dev bankcap and withdrawlimit are in ETH
    constructor(uint _bankcap, uint _withdrawlimit) {
        bankCap = _bankcap * 1 ether;
        withdrawLimit = _withdrawlimit * 1 ether;
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

    /// @dev Deposit
    function deposit() external payable{
        if (msg.value == 0) revert ZeroAmount();
        if (msg.value < minimumDeposit) revert MinimunDepositRequired();
        if (totalBalance + msg.value > bankCap) revert ExceedsBankCap();
        
        accountsBalance[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit DepositOk(msg.sender, msg.value, "Deposit Success!");
        _incrementDeposit();
    }

    /// @dev Withdraw, Follows CEI: checks conditions, effects state, then interacts with transfer
    function withdraw(uint _value) external noReentrancy {
        if (_value == 0) revert ZeroAmount();
        if (_value > withdrawLimit) revert ExceedsWithdrawLimit();
        if (_value > accountsBalance[msg.sender]) revert InsufficientBalance();

        accountsBalance[msg.sender] -= _value;
        totalBalance -= _value;
        _incrementWithdraw();
        (bool success, ) = msg.sender.call{value: _value}("");
        if (!success) revert TransferFailed();
        emit WithdrawOk(msg.sender, _value, "Withdraw Success!");
    }

   
    fallback() external { 
        revert("Invalid Call");
    }
}
