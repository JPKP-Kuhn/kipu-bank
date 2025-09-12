# KipuBank
Final project from the second module of ETH Kipu.

This contract acts like a personal vault with limits. Basicaly implementing two simple functions to deposit and withdraw ether
and protection with reentrancy attacks.

## How it works
### Function:
- Deposit ether
```solidity
function deposit() external payable{
    if (msg.value == 0) revert ZeroAmount();
    if (accountsBalance[msg.sender] + msg.value > bankCap) revert ExceedsBankCap();
    
    accountsBalance[msg.sender] += msg.value;
    emit DepositOk(msg.sender, msg.value, "Deposit Success!");
    _incrementDeposit();
}
```

- Withdraw ether
```solidity
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
```

### Custom errors
For gas-efficient error handling
- ZeroAmount
- ExceedsBankCap
- InsufficientBalance
- ExceedsWithdrawLimit
- TransferFailed
- ReentrancyDetected

## Deployment
You can use [Remix IDE](https://remix-project.org/?lang=en) to test the contract.
1. Create a new file called KipuBank.sol
2. Compile it and Deploy
3. The constructor needs two parameters, bankcap (max deposit allowed) and withdrawlimit (max amount of withdraw per transaction)
4. To test, just use in the Remix IDE an account and a value in ether that is already in the Remix VM

