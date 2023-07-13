// SPDX-License-Identifier: MIT
// File: contracts/ETHSToken.sol
pragma solidity = 0.8.11;
import "./utils/ERC20.sol";

contract QETHW is ERC20
{
    address public Presale;
    address public owner;
    address public ETHW;

    constructor() ERC20('QETHW', 'QETHW')
    {
        owner = msg.sender;
    }

    function setPresale(address _presale)public onlyOwner
    {
        Presale = _presale;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Only owner can set presale!");
        _;
    }

    modifier onlyPresale()
    {
        require(msg.sender == Presale, "Caller is not Presale!");
        _;
    }
    
    function mint(address _user, uint256 _amount)public onlyPresale
    {
        _mint(_user, _amount);
    }

    function burn(uint256 _amount)public onlyPresale
    {
        _burn(msg.sender, _amount);
    }
}

