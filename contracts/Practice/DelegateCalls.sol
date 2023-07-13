// File: contracts/VaultDistributor.sol
// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

interface iB
{
    function setValue(uint256 _amount)external returns(bool _success);
    function getValue()external view returns(uint256 _value);
}
contract A
{
    B b;
    address public B_Address;
    address public A_Address;
    bytes public caller;
    address public callerAddress;
    uint256 public value;
    bool public success;
    constructor()
    {
        A_Address = address(this);
    }
    function setValuewithDelegation(uint256 _amount)public
    {
        b = new B();
        B_Address = address(b);
        (bool _success, bytes memory _caller ) = B_Address.delegatecall(abi.encodeWithSelector(b.setValue.selector, _amount));
        success = _success;
        caller = _caller;
    }
    function getValue() public returns(uint256 _value)
    {
       value = iB(B_Address).getValue();
       return value;
    }

    function setValue(uint256 _amount)public
    {
        b = new B();
        B_Address = address(b);
        callerAddress = b.setValue(_amount);
        value = b.getValue();
    }
}

contract B
{
    uint256 public value;
    function setValue(uint256 _amount)public returns(address _caller)
    {
        value = _amount;
        _caller = msg.sender;
        return _caller;
    }
    function getValue()public view returns(uint256 _value)
    {
        return value;
    }
}

/**
* USE OF DELEGATE CALL IN SOLIDITY....
* When User calls ContractA then msg.sender is User
* When ContractA further Calls ContractB then msg.sender in ContractB is ContractA
* In Delegation Call, When ContractA further Calls ContractB then msg.sender in ContractB is also User, which is msg.sender of ContractA
* With Delegate Call cannot Read/Write its data into contractB.
* With Delegate Call ContractA can only use ContractB for calculations(giving some input and output in "bytes")
* Delegation Call is Core Concept of upgradeable Contracts.
* If any ambiguity occurs in ContractB then A can delegate its call to new Contract C and maintaing the previous state in it...
*/