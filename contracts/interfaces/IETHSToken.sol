// SPDX-License-Identifier: MIT


// File: contracts/interfaces/IETHSToken.sol

pragma solidity = 0.8.11;

import "../interfaces/IBEP20.sol";

interface IETHSToken is IBEP20 {
    function mintUser(address user, uint256 amount) external;

    function nodeMintTransfer(address sender, uint256 amount) external;

    function depositAll(address sender, uint256 amount) external;

    function nodeClaimTransfer(address recipient, uint256 amount) external;

    function vaultDepositNoFees(address sender, uint256 amount) external;

    function vaultCompoundFromNode(address sender, uint256 amount) external;

    function setInSwap(bool _inSwap) external;
    
    function transfer(address recipient, uint256 amount) external override returns (bool);

    function balanceOf(address account) external view override returns (uint256);

    function burn(uint256 _amount)external;
}