// SPDX-License-Identifier: MIT
pragma solidity = 0.8.11;

import "./EtherstonesRewardManager.sol";

contract Referral is EtherstonesRewardManager
{
    address public charityWallet = 0x199032b89ebb35D7adA146eCFc2fb50295Fb52BE;
    struct ReferalInfo
    {
        uint256 count;
        uint256 commission;
    }
    // referralAcccout => NodeType => ReferralInfo...
    mapping(address => mapping(uint256 => ReferalInfo)) public referrals;

    // userAccount => referralAccount => type => bool;
    mapping(address => mapping(address => mapping(uint256 => bool)))public isReferral;

    // userAccount => NodeType => ReferralAccount...
    // mapping(address => mapping(uint256 => address))public isReferral;

    constructor() EtherstonesRewardManager()
    {}

    function mintNodewithReferral(string memory _name, uint256 _amount, uint256 _nodeType, address _referral)public
    {   
        require(msg.sender != _referral, "User cannot refer itself!");
        // if address is ZERO
        if(_referral == address(0))
        {
            mintNode(_name, _amount, _nodeType);
        }
        else
        {
        // checking if referral owned the same node...
        require(nodeExists(_referral, _nodeType), "ReferralAccount has no owned Node!");
        // updating commission for referral...
        referrals[_referral][_nodeType].count++;
        referrals[_referral][_nodeType].commission += _amount * 5/1000;
        // referralAccount will be used once...
        require(!(isReferral[msg.sender][_referral][_nodeType]), "Cannot use Referral more than once!");
        // after all checks, minting the node...
        mintNode(_name, _amount, _nodeType);
        isReferral[msg.sender][_referral][_nodeType] = true;
        }
        
    }
    function nodeExists(address _account, uint256 _nodeType)public view returns(bool _exists)
    {
        uint256[] memory ownedNodesIDs = accountNodes[_account];
        for(uint256 i = 0; i < ownedNodesIDs.length; i++) {
            if(nodeMapping[ownedNodesIDs[i]].nodeType == _nodeType)
            {
                return true;
            }
        }
        return false;
    }

    // 0-ClaimAll, 1-donateOcean, 2-50/50...
    function claimEarnings(uint256 _option, uint256 _nodeType)public
    {
        if(_option == 0)
        {
            ethsToken.mintUser(msg.sender, referrals[msg.sender][_nodeType].commission);
        }
        if(_option == 1)
        {
            ethsToken.mintUser(charityWallet, referrals[msg.sender][_nodeType].commission);
        }
        if(_option == 2)
        {
            ethsToken.mintUser(charityWallet, (referrals[msg.sender][_nodeType].commission * 50) / 100);
            ethsToken.mintUser(msg.sender, (referrals[msg.sender][_nodeType].commission * 50) / 100);
        }
        referrals[msg.sender][_nodeType].commission = 0;
    }

    // 0-ClaimAll, 1-donateOcean, 2-50/50...
    function claimAllearnings(uint256 _option)public
    {
        uint256 commission = 0;
        commission += referrals[msg.sender][0].commission;
        referrals[msg.sender][0].commission = 0;
        commission += referrals[msg.sender][1].commission;
        referrals[msg.sender][1].commission = 0;
        commission += referrals[msg.sender][2].commission;
        referrals[msg.sender][2].commission = 0;
        commission += referrals[msg.sender][3].commission;
        referrals[msg.sender][3].commission = 0;
        
        if(_option == 0)
        {
            ethsToken.mintUser(msg.sender, commission);
        }
        if(_option == 1)
        {
            ethsToken.mintUser(charityWallet, commission);
        }
        if(_option == 2)
        {
            ethsToken.mintUser(charityWallet, (commission * 50) / 100);
            ethsToken.mintUser(msg.sender, (commission * 50) / 100);
        }
        commission = 0; 
    }
}
