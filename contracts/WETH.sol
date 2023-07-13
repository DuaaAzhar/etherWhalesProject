// SPDX-License-Identifier: MIT
// File: contracts/ETHSToken.sol

pragma solidity = 0.8.11;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./utils/ERC20.sol";

contract WETH is ERC20
{
    constructor() ERC20("WETH", "WETH")
    {
        mint(msg.sender, 1000*10**18);
    }

    function mint(address _owner, uint256 _amount)public 
    {
        _mint(_owner, _amount);
    }

    function burn(uint256 _amount)public
    {
        _burn(msg.sender, _amount);
    }
}
