// SPDX-License-Identifier: MIT
pragma solidity = 0.8.11;

interface IRefferal
{
    function mintNodewithReferral(string memory _name, uint256 _amount, uint256 _nodeType, address _referral)external;
}