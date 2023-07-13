// File: contracts/interfaces/IVaultDistributor.sol
// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

interface IVaultDistributor {
  function setShare(address shareholder, uint256 amount) external;

  function deposit() external payable;

  function setMinDistribution(uint256 _minDistribution) external;
}