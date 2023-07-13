// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IDEXFactory.sol


pragma solidity = 0.8.11;

interface IDEXFactory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}