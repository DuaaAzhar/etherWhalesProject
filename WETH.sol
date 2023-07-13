// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/utils/Auth.sol

// SPDX-License-Identifier: MIT


// File: contracts/Auth.sol


pragma solidity = 0.8.11;

abstract contract Auth {
  address internal owner;
  mapping(address => bool) internal authorizations;

  constructor(address _owner) {
    owner = _owner;
    authorizations[_owner] = true;
  }

  /**
   * Function modifier to require caller to be contract owner
   */
  modifier onlyOwner() {
    require(isOwner(msg.sender), '!OWNER');
    _;
  }

  /**
   * Function modifier to require caller to be authorized
   */
  modifier authorized() {
    require(isAuthorized(msg.sender), '!AUTHORIZED');
    _;
  }

  /**
   * Authorize address. Owner only
   */
  function authorize(address adr) public onlyOwner {
    authorizations[adr] = true;
  }

  /**
   * Remove address' authorization. Owner only
   */
  function unauthorize(address adr) public onlyOwner {
    authorizations[adr] = false;
  }

  /**
   * Check if address is owner
   */
  function isOwner(address account) public view returns (bool) {
    return account == owner;
  }

  /**
   * Return address' authorization status
   */
  function isAuthorized(address adr) public view returns (bool) {
    return authorizations[adr];
  }

  /**
   * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
   */
  function transferOwnership(address payable adr) public onlyOwner {
    owner = adr;
    authorizations[adr] = true;
    emit OwnershipTransferred(adr);
  }

  event OwnershipTransferred(address owner);
}


// File contracts/interfaces/IBEP20.sol

// SPDX-License-Identifier: MIT

// File: contracts/interfaces/IBEP20.sol


pragma solidity = 0.8.11;

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IETHSToken.sol

// SPDX-License-Identifier: MIT


// File: contracts/interfaces/IETHSToken.sol

pragma solidity = 0.8.11;

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

}


// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity = 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/EtherstonesRewardManager.sol

// SPDX-License-Identifier: MIT
// File: contracts/EtherstonesRewardManager.sol

pragma solidity = 0.8.11;



contract EtherstonesRewardManager is Auth {

    uint256 public ETHSDecimals = 10 ** 18;
    
    uint256 public totalBelugaWhale;
    uint256 public totalKillerWhale;
    uint256 public totalHumpbackWhale;
    uint256 public totalBlueWhale;

    uint256[2] public minMaxBelugaWhale = [3, 5];
    uint256[2] public minMaxKillerWhale = [12, 20];
    uint256[2] public minMaxHumpbackWhale = [72, 120];
    uint256[2] public minMaxBlueWhale = [480, 800];

    IETHSToken public ethsToken;

    address public rewardPool;

    // uint256 public nodeCooldown = 12*3600; //12 hours
    //---------------Setting dummy value for testing purpose---------------
    uint256 public nodeCooldown = 1 * 400; // 15 Minutes
    
    uint256 constant ONE_DAY = 86400; //seconds

    struct EtherstoneNode {
        string name;
        uint256 id;
        uint256 lastInteract;
        uint256 lockedETHS;
        uint256 nodeType;   // 0: BelugaWhale, 1: KillerWhale, 2: Humpback, 3: BlueWhale
        uint256 tier;      // 0: Emerald, 1: Sapphire, 2: Amethyst, 3: Ruby, 4: Golden
        uint256 timesCompounded;
        address owner;
    }

    // 0.85%, 0.97%, 1.11%, 1.27%
    uint256[4] public baseNodeDailyInterest = [8500, 9700, 11100, 12700];
    uint256 public nodeDailyInterestDenominator = 1000000;

    // 0.0004, 0.0006, 0.0008, 0.001
    uint256[4] public baseCompoundBoost = [4, 6, 8, 10];
    uint256 public baseCompoundBoostDenominator = 1000000;

    // 1x, 1.05x, 1.1x, 1.16x, 1.24x
    uint256[5] public tierMultipliers = [100, 105, 110, 116, 124];
    uint256 public tierMultipliersDenominator = 100;

    uint256[5] public tierCompoundTimes = [0, 4, 12, 42, 168];

    mapping(address => uint256[]) accountNodes;
    mapping(uint256 => EtherstoneNode) nodeMapping;

    bool public nodeMintingEnabled = true;

    constructor(address _ethsTokenAddress) Auth(msg.sender) {
        totalBelugaWhale = 0;
        totalKillerWhale = 0;
        totalHumpbackWhale = 0;
        totalBlueWhale = 0;
        ethsToken = IETHSToken(_ethsTokenAddress);
    }
    // default public function, making internal for referral connection...
    function mintNode(string memory _name, uint256 _amount, uint256 _nodeType) internal {

        require(nodeMintingEnabled, "Node minting is disabled");
        require(_nodeType >= 0 && _nodeType <= 3, "Node type is invalid");
        uint256 nameLen = utfStringLength(_name);
        require(utfStringLength(_name) <= 16 && nameLen > 0, "String name is invalid");

        uint256 nodeID = getNumberOfNodes() + 1;
        EtherstoneNode memory nodeToCreate;

        if(_nodeType == 0) {
            require(_amount >= minMaxBelugaWhale[0] * ETHSDecimals && _amount <= minMaxBelugaWhale[1]*ETHSDecimals, "BelugaWhale amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalBelugaWhale++;
        }
        if(_nodeType == 1) {
            require(_amount >= minMaxKillerWhale[0]*ETHSDecimals && _amount <= minMaxKillerWhale[1]*ETHSDecimals, "KillerWhale amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalKillerWhale++;
        }
        else if (_nodeType == 2) {
            require(_amount >= minMaxHumpbackWhale[0]*ETHSDecimals && _amount <= minMaxHumpbackWhale[1]*ETHSDecimals, "HumpbackWhale amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalHumpbackWhale++;
        }
        else if(_nodeType == 3) {
            require(_amount >= minMaxBlueWhale[0]*ETHSDecimals && _amount <= minMaxBlueWhale[1]*ETHSDecimals, "BlueWhale amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalBlueWhale++;
        }

        nodeMapping[nodeID] = nodeToCreate;
        accountNodes[msg.sender].push(nodeID);

        ethsToken.nodeMintTransfer(msg.sender, _amount);
    }
    function compoundAllAvailableEtherstoneReward() external {
        uint256 numOwnedNodes = accountNodes[msg.sender].length;
        require(numOwnedNodes > 0, "Must own nodes to claim rewards");
        uint256 totalCompound = 0;
        for(uint256 i = 0; i < numOwnedNodes; i++) {
            if(block.timestamp - nodeMapping[accountNodes[msg.sender][i]].lastInteract > nodeCooldown) {
                uint256 nodeID = nodeMapping[accountNodes[msg.sender][i]].id;
                totalCompound += calculateRewards(nodeID);
                updateNodeInteraction(nodeID, block.timestamp, true);
            }
        }
        ethsToken.vaultCompoundFromNode(msg.sender, totalCompound);
    }

    function compoundEtherstoneReward(uint256 _id) external {
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        require(msg.sender == etherstoneNode.owner, "Must be owner of node to compound");
        require(block.timestamp - etherstoneNode.lastInteract > nodeCooldown, "Node is on cooldown");
        uint256 amount = calculateRewards(etherstoneNode.id);
        updateNodeInteraction(etherstoneNode.id, block.timestamp, true);
        ethsToken.vaultCompoundFromNode(msg.sender, amount);
    }

    function claimAllAvailableEtherstoneReward() external {
        uint256 numOwnedNodes = accountNodes[msg.sender].length;
        require(numOwnedNodes > 0, "Must own nodes to claim rewards");
        uint256 totalClaim = 0;
        for(uint256 i = 0; i < numOwnedNodes; i++) {
            if(block.timestamp - nodeMapping[accountNodes[msg.sender][i]].lastInteract > nodeCooldown) {
                uint256 nodeID = nodeMapping[accountNodes[msg.sender][i]].id;
                if(!inCompounder[nodeID]) {
                    totalClaim += calculateRewards(nodeID);
                    updateNodeInteraction(nodeID, block.timestamp, false);
                }
            }
        }
        ethsToken.nodeClaimTransfer(msg.sender, totalClaim);
    }

    function claimEtherstoneReward(uint256 _id) external {
        require(!inCompounder[_id], "Node cannot be in autocompounder");
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        require(msg.sender == etherstoneNode.owner, "Must be owner of node to claim");
        require(block.timestamp - etherstoneNode.lastInteract > nodeCooldown, "Node is on cooldown");
        uint256 amount = calculateRewards(etherstoneNode.id);
        updateNodeInteraction(_id, block.timestamp, false);
        ethsToken.nodeClaimTransfer(etherstoneNode.owner, amount);
    }

    function calculateRewards(uint256 _id) public view returns (uint256) {
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        // (locked amount * daily boost + locked amount * daily interest) * days elapsed
        return ((((((etherstoneNode.lockedETHS
                                  * etherstoneNode.timesCompounded
                                  * baseCompoundBoost[etherstoneNode.nodeType]) / baseCompoundBoostDenominator)
                                  * tierMultipliers[etherstoneNode.tier]) / tierMultipliersDenominator)
                                  + (etherstoneNode.lockedETHS * baseNodeDailyInterest[etherstoneNode.nodeType]) / nodeDailyInterestDenominator)
                                  * (block.timestamp - etherstoneNode.lastInteract) / ONE_DAY);
    }

    function updateNodeInteraction(uint256 _id, uint256 _timestamp, bool _compounded) private {
        nodeMapping[_id].lastInteract = _timestamp;
        if(_compounded) {
            nodeMapping[_id].timesCompounded += nodeMapping[_id].timesCompounded != tierCompoundTimes[4] ? 1 : 0;
        } else {
            nodeMapping[_id].timesCompounded = 0;
        }
        nodeMapping[_id].tier = getTierByCompoundTimes(nodeMapping[_id].timesCompounded);
    }

    function getTierByCompoundTimes(uint256 _compoundTimes) private view returns (uint256) {
        if(_compoundTimes >= tierCompoundTimes[0] && _compoundTimes < tierCompoundTimes[1]) {
            return 0;
        } else if(_compoundTimes >= tierCompoundTimes[1] && _compoundTimes < tierCompoundTimes[2]) {
            return 1;
        } else if(_compoundTimes >= tierCompoundTimes[2] && _compoundTimes < tierCompoundTimes[3]) {
            return 2;
        } else if(_compoundTimes >= tierCompoundTimes[3] && _compoundTimes < tierCompoundTimes[4]) {
            return 3;
        } else {
            return 4;
        }
    }

    function getEtherstoneNodeById(uint256 _id) public view returns (EtherstoneNode memory){
        return nodeMapping[_id];
    }

    function getOwnedNodes(address _address) public view returns (EtherstoneNode[] memory) {
        uint256[] memory ownedNodesIDs = accountNodes[_address];
        EtherstoneNode[] memory ownedNodes = new EtherstoneNode[](ownedNodesIDs.length);
        for(uint256 i = 0; i < ownedNodesIDs.length; i++) {
            ownedNodes[i] = nodeMapping[ownedNodesIDs[i]];
        }
        return ownedNodes;
    }

    
    function getNumberOfNodes() public view returns (uint256) {
        return totalBelugaWhale + totalKillerWhale + totalHumpbackWhale + totalBlueWhale;
    }

    // used for dashboard display...
    function getDailyNodeEmission(uint256 _id) external view returns (uint256) {
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        return (((((etherstoneNode.lockedETHS
                                  * etherstoneNode.timesCompounded
                                  * baseCompoundBoost[etherstoneNode.nodeType]) / baseCompoundBoostDenominator)
                                  * tierMultipliers[etherstoneNode.tier]) / tierMultipliersDenominator)
                                  + (etherstoneNode.lockedETHS * baseNodeDailyInterest[etherstoneNode.nodeType]) / nodeDailyInterestDenominator);
    }

    function setBaseDailyNodeInterest(uint256 baseBelugaWhaleInterest, uint256 baseKillerWhaleInterest, uint256 baseHumpbackWhaleInterest, uint256 baseBlueWhaleInterest) external onlyOwner {
        require(baseBelugaWhaleInterest > 0 && baseKillerWhaleInterest > 0 && baseHumpbackWhaleInterest > 0 && baseBlueWhaleInterest > 0, "Interest must be greater than zero");
        baseNodeDailyInterest[0] = baseBelugaWhaleInterest;
        baseNodeDailyInterest[1] = baseKillerWhaleInterest;
        baseNodeDailyInterest[2] = baseHumpbackWhaleInterest;
        baseNodeDailyInterest[3] = baseBlueWhaleInterest;
    }

    function setBaseCompoundBoost(uint256 baseBelugaWhaleBoost, uint256 baseKillerWhaleBoost, uint256 baseHumpbackWhaleBoost, uint256 baseBlueWhaleBoost) external onlyOwner {
        require(baseBelugaWhaleBoost > 0 && baseKillerWhaleBoost > 0 && baseHumpbackWhaleBoost > 0 && baseBlueWhaleBoost > 0, "Boost must be greater than zero");
        baseCompoundBoost[0] = baseBelugaWhaleBoost;
        baseCompoundBoost[1] = baseKillerWhaleBoost;
        baseCompoundBoost[2] = baseHumpbackWhaleBoost;
        baseCompoundBoost[3] = baseBlueWhaleBoost;
    }

    function setBelugaWhaleMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid BelugaWhale minimum and maximum");
        minMaxBelugaWhale[0] = min;
        minMaxBelugaWhale[1] = max;
    }

    function setKillerWhaleMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid KillerWhale minimum and maximum");
        minMaxKillerWhale[0] = min;
        minMaxKillerWhale[1] = max;
    }

    function setHumpbackWhaleMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid HumpbackWhale minimum and maximum");
        minMaxHumpbackWhale[0] = min;
        minMaxHumpbackWhale[1] = max;
    }

    function setBlueWhaleMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid BlueWhale minimum and maximum");
        minMaxBlueWhale[0] = min;
        minMaxBlueWhale[1] = max;
    }
    
    function setNodeMintingEnabled(bool decision) external onlyOwner {
        nodeMintingEnabled = decision;
    }

    function setTierCompoundTimes(uint256 emerald, uint256 sapphire, uint256 amethyst, uint256 ruby, uint256 radiant) external onlyOwner {
        tierCompoundTimes[0] = emerald;
        tierCompoundTimes[1] = sapphire;
        tierCompoundTimes[2] = amethyst;
        tierCompoundTimes[3] = ruby;
        tierCompoundTimes[4] = radiant;
    }

    function setTierMultipliers(uint256 emerald, uint256 sapphire, uint256 amethyst, uint256 ruby, uint256 radiant) external onlyOwner {
        tierMultipliers[0] = emerald;
        tierMultipliers[1] = sapphire;
        tierMultipliers[2] = amethyst;
        tierMultipliers[3] = ruby;
        tierMultipliers[4] = radiant;
    }

    function transferNode(uint256 _id, address _owner, address _recipient) public authorized {
        require(_owner != _recipient, "Cannot transfer to self");
        require(!inCompounder[_id], "Unable to transfer node in compounder");
        uint256 len = accountNodes[_owner].length;
        bool success = false;
        for(uint256 i = 0; i < len; i++) {
            if(accountNodes[_owner][i] == _id) {
                accountNodes[_owner][i] = accountNodes[_owner][len-1];
                accountNodes[_owner].pop();
                accountNodes[_recipient].push(_id);
                nodeMapping[_id].owner = _recipient;
                success = true;
                break;
            }
        }
        require(success, "Transfer failed");
    }

    function massTransferNodes(uint256[] memory _ids, address[] memory _owners, address[] memory _recipients) external authorized {
        require(_ids.length == _owners.length && _owners.length == _recipients.length, "Invalid parameters");
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; i++) {
            transferNode(_ids[i], _owners[i], _recipients[i]);
        }
    }

    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }

    address[] usersInCompounder;
    mapping(address => uint256[]) nodesInCompounder;
    mapping(uint256 => bool) inCompounder;
    uint256 public numNodesInCompounder;

    function addToCompounder(uint256 _id) public {
        require(msg.sender == nodeMapping[_id].owner, "Must be owner of node");

        if(inCompounder[_id]) {
            return;
        }

        if(nodesInCompounder[msg.sender].length == 0) {
            usersInCompounder.push(msg.sender);
        }
        nodesInCompounder[msg.sender].push(_id);
        inCompounder[_id] = true;
        numNodesInCompounder++;
    }

    function removeFromCompounder(uint256 _id) public {
        require(msg.sender == nodeMapping[_id].owner, "Must be owner of node");
        require(inCompounder[_id], "Node must be in compounder");

        uint256 len = nodesInCompounder[msg.sender].length;
        for(uint256 i = 0; i < len; i++) {
            if(nodesInCompounder[msg.sender][i] == _id) {
                nodesInCompounder[msg.sender][i] = nodesInCompounder[msg.sender][len-1];
                nodesInCompounder[msg.sender].pop();
                break;
            }
        }
        inCompounder[_id] = false;
        numNodesInCompounder--;

        if(nodesInCompounder[msg.sender].length == 0) { // remove user
            removeCompounderUser(msg.sender);
        }
    }

    function removeCompounderUser(address _address) private {
        uint256 len = usersInCompounder.length;
        for(uint256 i = 0; i < len; i++) {
            if(usersInCompounder[i] == _address) {
                usersInCompounder[i] = usersInCompounder[len-1];
                usersInCompounder.pop();
                break;
            }
        }
    }

    function addAllToCompounder() external {
        uint256 lenBefore = nodesInCompounder[msg.sender].length;
        nodesInCompounder[msg.sender] = accountNodes[msg.sender];
        uint256 lenAfter = nodesInCompounder[msg.sender].length;
        require(lenAfter > lenBefore, "No nodes added to compounder");
        if(lenBefore == 0) {
            usersInCompounder.push(msg.sender);
        }
        for(uint256 i = 0; i < lenAfter; i++) {
            inCompounder[nodesInCompounder[msg.sender][i]] = true;
        }
        numNodesInCompounder += lenAfter - lenBefore;
    }

    function removeAllFromCompounder() external {
        uint256 len = nodesInCompounder[msg.sender].length;
        require(len > 0, "No nodes able to be removed");
        for(uint256 i = 0; i < len; i++) {
            inCompounder[nodesInCompounder[msg.sender][i]] = false;
        }
        delete nodesInCompounder[msg.sender];
        removeCompounderUser(msg.sender);
        numNodesInCompounder -= len;
    }

    function autoCompound() external {
        uint256 len = usersInCompounder.length;
        for(uint256 i = 0; i < len; i++) {
            compoundAllForUserInCompounder(usersInCompounder[i]);
        }
    }

    function compoundAllForUserInCompounder(address _address) private {
        uint256[] memory ownedInCompounder = nodesInCompounder[_address];
        uint256 totalCompound = 0;
        uint256 len = ownedInCompounder.length;
        for(uint256 i = 0; i < len; i++) {
            if(block.timestamp - nodeMapping[ownedInCompounder[i]].lastInteract > nodeCooldown) {
                uint256 nodeID = nodeMapping[ownedInCompounder[i]].id;
                totalCompound += calculateRewards(nodeID);
                updateNodeInteraction(nodeID, block.timestamp, true);
            }
        }
        if(totalCompound > 0) {
            ethsToken.vaultCompoundFromNode(_address, totalCompound);
        }
    }

    function getOwnedNodesInCompounder() external view returns (uint256[] memory) {
        return nodesInCompounder[msg.sender];
    }
}


// File contracts/interfaces/IDEXRouter.sol

// File: contracts/interfaces/IDEXRouter.sol
// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/interfaces/IVaultDistributor.sol

// File: contracts/interfaces/IVaultDistributor.sol
// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

interface IVaultDistributor {
  function setShare(address shareholder, uint256 amount) external;

  function deposit() external payable;

  function setMinDistribution(uint256 _minDistribution) external;
}


// File contracts/VaultDistributor.sol

// File: contracts/VaultDistributor.sol
// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;



contract VaultDistributor is IVaultDistributor {

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded; // excluded dividend
        uint256 totalRealised;
        uint256 excludedAtUpdates; // Every time someone deposits or withdraws, this number is recalculated.
    }                              // It is used as a base for each new deposit to cancel out the current dividend 
                                   // per share since the dividendPerShare value is always increasing. Every withdraw
                                   // will reduce this number by the same amount it was previously incremented.
                                   // Deposits are impacted by the current dividends per share.
                                   // Withdraws are impacted by past dividends per share, stored in shareholderDeposits.

    IETHSToken eths;
    IBEP20 WETH = IBEP20(0x32e5539Eb6122A5e32eE8F8D62b185BCc3c41483);
    address WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    IDEXRouter router;

    uint256 numShareholders;

    struct Deposit {
        uint256 amount;
        uint256 dividendPerShareSnapshot;
    }

    mapping(address => Deposit[]) shareholderDeposits; 
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed; // to be shown in UI
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**18;

    uint256 public minDistribution = 5 * (10**18);

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router, address _eths) {
        _token = msg.sender;
        router = IDEXRouter(_router);
        eths = IETHSToken(_eths);
    }

    // amount and shareholder.amount are equal the only difference will create when there is deposit/ withdrawn...
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount >= minDistribution && shares[shareholder].amount < minDistribution) {
            numShareholders++;
        } else if (amount < minDistribution && shares[shareholder].amount >= minDistribution) {
            numShareholders--;
        }
        if(amount >= minDistribution || shares[shareholder].amount >= minDistribution) {
            totalShares = totalShares - shares[shareholder].amount + amount;
            // deposit
            if(amount > shares[shareholder].amount) { // amount = shareholderAmount + newdeposit
                uint256 amountDeposited = amount - shares[shareholder].amount;
                uint256 unpaid = getUnpaidEarnings(shareholder); // get unpaid data, calculate excludedAtUpdates, then calculate totalExcluded
                shares[shareholder].excludedAtUpdates += (dividendsPerShare * amountDeposited) / dividendsPerShareAccuracyFactor; // calc changes
                shares[shareholder].amount = amount;
                shares[shareholder].totalExcluded = getCumulativeDividends(shareholder) - unpaid; // carry unpaid over

                shareholderDeposits[shareholder].push(Deposit({
                    amount: amountDeposited,
                    dividendPerShareSnapshot: dividendsPerShare
                }));
            }
            // withdraw
            else if(amount < shares[shareholder].amount) { // shareholder.amount = withdrawnAmount + amount, means some amount has withdrawn
                uint256 unpaid = getUnpaidEarnings(shareholder); // get unpaid data, calculate excludedAtUpdates, then calculate totalExcluded
                uint256 sharesLost = shares[shareholder].amount - amount;
                uint256 len = shareholderDeposits[shareholder].length - 1;

                for(uint256 i = len; i >= 0; i--) { // calculate changes
                    uint256 depositShares = shareholderDeposits[shareholder][i].amount;
                    uint256 snapshot = shareholderDeposits[shareholder][i].dividendPerShareSnapshot;
                    if(depositShares <= sharesLost) {
                        shares[shareholder].excludedAtUpdates -= (depositShares * snapshot) / dividendsPerShareAccuracyFactor;
                        sharesLost -= depositShares;
                        shareholderDeposits[shareholder].pop();
                        if(sharesLost == 0) {
                            break;
                        } 
                    } else {
                        shareholderDeposits[shareholder][i].amount = depositShares - sharesLost;
                        shares[shareholder].excludedAtUpdates -= (sharesLost * snapshot) / dividendsPerShareAccuracyFactor;
                        break;
                    }
                    if(i==0) {break;}
                }

                shares[shareholder].amount = amount;
                uint256 cumulative = getCumulativeDividends(shareholder);
                require(cumulative >= unpaid, "Claim pending rewards first"); // if withdrawing share while reward is pending for that share, Revert!
                shares[shareholder].totalExcluded = cumulative - unpaid; // carry unpaid over
            }
        } else {
            shares[shareholder].amount = amount;
        }
    }

    function deposit() external payable override { // debugging onlyToken
        uint256 balanceBefore = WETH.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(WETH);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amount = WETH.balanceOf(address(this)) - balanceBefore;

        totalDividends += amount;
        if(totalShares > 0) {
            dividendsPerShare += dividendsPerShareAccuracyFactor * amount / totalShares;
        }
    }
    
    // 0 is claim as WETH, 1 is compound to vault, 2 is claim as ETHS
    function claimDividend(uint256 action) external {
        require(action == 0 || action == 1 || action == 2, "Invalid action");
        uint256 amount = getUnpaidEarnings(msg.sender);
        require(amount > 0, "No rewards to claim");

        totalDistributed += amount;
        if(action == 0) {
            WETH.transfer(msg.sender, amount);
        } else {
            address[] memory path = new address[](3);
            path[0] = address(WETH);
            path[1] = WAVAX;
            path[2] = _token;

            uint256 amountBefore = eths.balanceOf(msg.sender);

            WETH.approve(address(router), amount);
            eths.setInSwap(true);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                msg.sender,
                block.timestamp
            );
            eths.setInSwap(false);

            if(action == 1) {
                uint256 amountCompound = eths.balanceOf(msg.sender) - amountBefore;
                eths.vaultDepositNoFees(msg.sender, amountCompound);
            }
        }
        shares[msg.sender].totalRealised += amount;
        shares[msg.sender].totalExcluded = getCumulativeDividends(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount < minDistribution) {
            return 0;
        }
        
        uint256 shareholderTotalDividends = getCumulativeDividends(shareholder);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded) { 
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(address shareholder) internal view returns (uint256) {
        if(((shares[shareholder].amount * dividendsPerShare) / dividendsPerShareAccuracyFactor) <= shares[shareholder].excludedAtUpdates) {
            return 0;
            // exclude at update is reward for all new deposits, which is present in shareholder.amount. 
            // so, if user has reward then cummulative reward must be greater than new reward...
        }
        return ((shares[shareholder].amount * dividendsPerShare) / dividendsPerShareAccuracyFactor) - shares[shareholder].excludedAtUpdates;
    }

    function getNumberOfShareholders() external view returns (uint256) {
        return numShareholders;
    }

    function setMinDistribution(uint256 _minDistribution) external onlyToken {
        minDistribution = _minDistribution;
    }
}


// File contracts/interfaces/IDEXFactory.sol

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IDEXFactory.sol


pragma solidity = 0.8.11;

interface IDEXFactory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


// File contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/ETHS.sol

/**
 *Submitted for verification at snowtrace.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
// File: contracts/ETHSToken.sol


pragma solidity  = 0.8.11;







// Testing Purpose //

contract ETHSToken is IBEP20, Auth {
    using SafeMath for uint256;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    address public tokenAddress;
    uint256 public treasuryTax;
    uint256 public marketingTax;

    EtherstonesRewardManager public rewardManager;
    address private rewardManagerAddress = DEAD;

    uint256 public constant MASK = type(uint128).max;

    // TraderJoe router
    address constant ROUTER = 0xadcBe444619dE95aeDD82245d0B422288b27C895;  
    address public WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;

    string constant _name = 'EtherWhales';
    string constant _symbol = 'ETHW';
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 5_000_000 * (10 ** _decimals);

    uint256 public _maxTxAmount = 2500 * (10 ** _decimals);
    uint256 public _maxWallet = 10000 * (10 ** _decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isMaxWalletExempt;

    mapping(address => uint256) localVault;
    mapping(address => uint256) public localVaultCooldowns;

    mapping(address => bool) lpPairs;
    
    uint256 public charityCollected = 0;
    uint256 charityCollectedTemp = 0;
    uint256 public liquidityFee = 0;
    // TRANSFER/ CLAIM/ COMPOUND/ SELL Tax...
    uint256 reflectionFee = 2240; // 80%
    uint256 treasuryFee = 280; // 10%
    uint256 marketingFee = 280; // 10%
    uint256 totalFee = 2800;  // 100%
    // CLAIM/ COMPOUND Tax...
    uint256 depositFee = 2500; // 24% + 1% charity
    uint256 claimFee = 2500; // 24% + 1% charity
    uint256 claimFeeDenominator = 10000; 
    uint256 vaultDepositFeeDenominator = 10000; 
    uint256 vaultWithdrawFeeDenominator = 0; // 0% on every vault withdrawal
    uint256 compoundFeeDenominator = 10000; 
    // defualt -->15556; // 18% on every etherstone->vault compound
    uint256 compoundFee = 1600; // 15% + 1% charity
    uint256 sellFee = 11; // 10% + 1% charity
    uint256 sellFeeDenominator = 100;
    uint256 amountToLiquify = 0;


    // NODE CREATION Tax...
    uint256 burnAllocation = 10;
    uint256 treasuryAllocation = 10;
    uint256 marketingAllocation = 5;
    uint256 rewardPoolAllocation = 75;
    uint256 nodeCreationDenominator = 100;

    //uint256 vaultWithdrawCooldown = 3600*24*4; // 4 days
    uint256 vaultWithdrawCooldown = 900;

    address public liquidityFeeReceiver = 0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce;
    address public marketingFeeReceiver = 0x9d12687d1CC9b648904eD837983c51d68Be25656;
    address public treasuryFeeReceiver = 0xCa06Bdc6F917FeF701c1D6c9f084Cfa74962AD2A;
    address public rewardPool = DEAD;

    IDEXRouter public router;
    address public pair;

    VaultDistributor distributor;
    address public distributorAddress = DEAD;

    uint256 private lastSwap = block.timestamp;
    uint256 private swapInterval =  60; // 60*45; // 45 minutes
    uint256 private swapThreshold = 2 * (10 ** _decimals);

    bool private liquidityAdded = false;
    uint256 private sniperTimestampThreshold;

    uint256 private launchTaxTimestamp;  
    uint256 private launchTaxEndTimestamp;

    mapping(address => bool) blacklisted; 
    address public charityWallet = 0x199032b89ebb35D7adA146eCFc2fb50295Fb52BE;

    // statistics
    uint256 public totalLocked = 0;
    uint256 public totalCompoundedFromNode = 0;
    uint256 public launchStartTime;
    uint256 public launchEndTime;

    bool private inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyVaultDistributor() {
        require(msg.sender == distributorAddress);
        _;
    }

    modifier onlyRewardsManager() {
        require(msg.sender == rewardManagerAddress);
        _;
    }

    constructor() Auth(msg.sender) {

        uint256 MAX = type(uint256).max;
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));

        _allowances[address(this)][address(router)] = MAX;
        //WAVAX = router.WAVAX();

        distributor = new VaultDistributor(address(router), address(this));
        distributorAddress = address(distributor);
        
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[treasuryFeeReceiver] = true;
        isFeeExempt[liquidityFeeReceiver] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[liquidityFeeReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[treasuryFeeReceiver] = true;

        isMaxWalletExempt[pair] = true;
        isMaxWalletExempt[address(router)] = true;

        lpPairs[pair] = true;

        _approve(msg.sender, address(router), MAX);
        // _approve(address(this), address(router), MAX);

        totalLocked = 192_000 * 10**18; // 192 crystals sold

        _totalSupply =  _totalSupply = _totalSupply - (totalLocked / 10) - (496_161_7 * 10**17); // 10% of nodes costs burnt; 496,161.7 presale tokens sold

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        _basicTransfer(msg.sender, treasuryFeeReceiver, totalLocked / 10);
        _basicTransfer(msg.sender, rewardPool, (2_750_000 * 10 ** 18) + ((totalLocked * 8) / 10));
        _basicTransfer(msg.sender, liquidityFeeReceiver, 1_311_838_3 * 10 ** 17); // 2,000,000 - 496,161.7
    }

    function enableLaunch()public onlyOwner
    {
        launchStartTime = block.timestamp;
        launchEndTime = launchStartTime.add(1 days);
    }

    function setEtherstonesRewardManager(address _rewardManager) external onlyOwner {
        require(_rewardManager != address(0), "Reward Manager must exist");
        isFeeExempt[_rewardManager] = true;
        isTxLimitExempt[_rewardManager] = true;
        rewardManager = EtherstonesRewardManager(_rewardManager);
        rewardManagerAddress = _rewardManager;
    }

    function setLpPair(address _pair, bool _enabled) external onlyOwner {
        lpPairs[_pair] = _enabled;
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    // Handles all trades and applies sell fee
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0) && recipient != address(0), "Error: transfer to or from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!blacklisted[sender], "Sender is blacklisted");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if(hasLimits(sender, recipient)) {
            require(liquidityAdded, "Liquidity not yet added");
            if(sniperTimestampThreshold > block.timestamp) {
                revert("Sniper caught");
            }

            if(lpPairs[sender] || lpPairs[recipient]) {
                require(amount <= _maxTxAmount, 'Transaction Limit Exceeded');
            }

            if(recipient != address(router) && !lpPairs[recipient] && !isMaxWalletExempt[recipient]) {
                require((_balances[recipient] + amount) < _maxWallet, 'Max wallet has been triggered');
            }
        }

        uint256 amountReceived = amount;
        
        // sells & transfers
        if(!lpPairs[sender]) {
            if(shouldSwapBack()) {
                swapBack();
            }
            amountReceived = !isFeeExempt[sender] ? takeSellFee(sender, amount) : amount;
        }

        require(_balances[sender] >= amount, "Not enough tokens");

        _balances[sender] =_balances[sender]- amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function hasLimits(address sender, address recipient) private view returns (bool) {
        return !isOwner(sender)
            && !isOwner(recipient)
            && !isOwner(tx.origin)
            && !isTxLimitExempt[sender]
            && !isTxLimitExempt[recipient]
            && recipient != DEAD
            && recipient != address(0)
            && sender != address(this);
    }

    function nodeMintTransfer(address sender, uint256 amount) external onlyRewardsManager
    {
        uint256 burnAmount = (amount * burnAllocation) / nodeCreationDenominator;
        uint256 treasuryAmount = (amount * treasuryAllocation) / nodeCreationDenominator;
        uint256 rewardPoolAmount = (amount * rewardPoolAllocation) / nodeCreationDenominator;
        uint256 marketingAmount = (amount * marketingAllocation) / nodeCreationDenominator;
        _basicTransfer(sender, address(this), amount);
        _basicTransfer(address(this), rewardPool, rewardPoolAmount);
        treasuryTax += treasuryAmount;
        marketingTax += marketingAmount;
        _burn(burnAmount);
        totalLocked += amount;
    }

    function nodeClaimTransfer(address recipient, uint256 amount) external onlyRewardsManager {
        require(amount > 0, "Cannot claim zero rewards");
        uint256 claimAmount = amount - ((amount * claimFee) / claimFeeDenominator);
        charityCollectedTemp += (amount * 100)/claimFeeDenominator;
        charityCollected += (amount * 100)/claimFeeDenominator;
        _basicTransfer(rewardPool, address(this), amount);
        _basicTransfer(address(this), recipient, claimAmount);
    }

    function vaultDepositTransfer(uint256 amount) external {
        _basicTransfer(msg.sender, address(this), amount);

        localVaultCooldowns[msg.sender] = block.timestamp;

        uint256 amountDeposited =
                vaultDepositFeeDenominator == 0 
                ? amount 
                : amount - ((amount * depositFee) / vaultDepositFeeDenominator);
        require(amountDeposited > 0, "Cannot deposit or compound zero tokens into the vault");
        localVault[msg.sender] += amountDeposited;
        charityCollectedTemp += (amount * 100) / vaultDepositFeeDenominator;
        charityCollected += (amount * 100)/ vaultDepositFeeDenominator;
        distributor.setShare(msg.sender, localVault[msg.sender]);
        _burn(amountDeposited);
    }

    function vaultDepositNoFees(address sender, uint256 amount) external onlyVaultDistributor {
        require(amount > 0, "Cannot compound zero tokens into the vault");

        _basicTransfer(sender, address(this), amount);
        localVault[sender] += amount;
        distributor.setShare(sender, localVault[sender]);
        _burn(amount);
    }

    function vaultCompoundFromNode(address sender, uint256 amount) external onlyRewardsManager {
        require(amount > 0, "Cannot compound zero tokens into the vault");
    
        _basicTransfer(rewardPool, address(this), amount);

        localVaultCooldowns[sender] = block.timestamp;

        uint256 amountDeposited =
                vaultDepositFeeDenominator == 0
                ? amount 
                : amount - ((amount * compoundFee) / compoundFeeDenominator);

        localVault[sender] += amountDeposited;
        totalCompoundedFromNode += amountDeposited;
        distributor.setShare(sender, localVault[sender]);
        charityCollectedTemp += (amount * 100) / compoundFeeDenominator;
        charityCollected += (amount * 100) / compoundFeeDenominator;
        _burn(amountDeposited);
    }

    function vaultWithdrawTransfer(uint256 amount) external {
        require(block.timestamp - localVaultCooldowns[msg.sender] > vaultWithdrawCooldown, "Withdrawing is on cooldown");
        require(localVault[msg.sender] >= amount, "Cannot withdraw more than deposited");

        uint256 amountWithdrawn = 
            vaultWithdrawFeeDenominator == 0 
            ? amount 
            : amount - ((amount * totalFee) / vaultWithdrawFeeDenominator);
            
        require(amountWithdrawn > 0, "Cannot withdraw zero tokens from the vault");
        localVault[msg.sender] -= amount;
        distributor.setShare(msg.sender, localVault[msg.sender]);
        _mint(msg.sender, amountWithdrawn);
        if(vaultWithdrawFeeDenominator > 0) {
            _mint(address(this), amount - amountWithdrawn);
        }
    }

    function getPersonalVaultCooldown() public view returns (uint256) {
        return localVaultCooldowns[msg.sender] + vaultWithdrawCooldown;
    }

    function getPersonalAmountInVault() public view returns (uint256) {
        return localVault[msg.sender];
    }

    function _mint(address recipient, uint256 amount) private {
        _balances[recipient] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), recipient, amount);
    }

    function _burn(uint256 amount) internal { // default  private
        _balances[address(this)] -= amount;
        _totalSupply -= amount;
        emit Transfer(address(this), address(0), amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Not enough tokens to transfer");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeSellFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * sellFee) / sellFeeDenominator;
        charityCollectedTemp += (amount * 100) / 10000;
        charityCollected += (amount * 100) / 10000;
        if(block.timestamp < launchTaxEndTimestamp) {
            feeAmount += ((amount * 10 * (7 days - (block.timestamp - launchTaxTimestamp))) / (7 days)) / sellFeeDenominator;
        }
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        if(block.timestamp >= lastSwap + swapInterval && liquidityAdded) {
            return (_balances[address(this)] - (treasuryTax + marketingTax + charityCollectedTemp)) >= swapThreshold;
        }
        return false;
    }

    function ETHwToAVAX(uint256 _amounttoswap)private returns(bool)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;
        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            _amounttoswap,
            0,
            path,
            address(this),
            block.timestamp
        );
        return true;
    }

    modifier islaunchTime()
    {
        if(block.timestamp > launchEndTime)
        {
            reflectionFee = 2240; // 80%
            treasuryFee = 280;   //  10%
            marketingFee = 280; //   10%
            liquidityFee = 0;  //    0%
            _;
        }
        else
        {
            reflectionFee = 1120;  // 40%
            treasuryFee = 560;    //  20%
            marketingFee = 840;  //   30%
            liquidityFee = 280; //    10%
            _;
        }
    }
    function swapBack() internal swapping islaunchTime
    {   
        lastSwap = block.timestamp;
        amountToLiquify = ((swapThreshold * liquidityFee) / totalFee) / 2;  // half tokens and half AVAX for adding liquidity...
        uint256 amountToSwap = swapThreshold - amountToLiquify;
        uint256 percentageTreasuryTax = (treasuryTax * 10**18) / (amountToSwap + treasuryTax + marketingTax + charityCollectedTemp);
        uint256 percentageMarketingTax = (marketingTax * 10**18) / (amountToSwap + treasuryTax + marketingTax + charityCollectedTemp);
        uint256 charityPercentage = (charityCollectedTemp * (10**18)) / (amountToSwap + treasuryTax + marketingTax + charityCollectedTemp);
        uint256 balanceBefore = address(this).balance;
        if(_allowances[address(this)][address(router)] != type(uint256).max) {
            _allowances[address(this)][address(router)] = type(uint256).max;
        }

        ETHwToAVAX(amountToSwap + treasuryTax + marketingTax + charityCollectedTemp);
        uint256 amountAVAX = address(this).balance - balanceBefore;

        // Seperating Node Minting Tax from amountToSwap...
        uint256 treasuryShare = (amountAVAX * percentageTreasuryTax) / (10**18);
        uint256 marketingShare = (amountAVAX * percentageMarketingTax) / (10**18);
        uint256 charityShare = (amountAVAX * charityPercentage) / (10**18);
        uint256 otherTaxesAVAX = amountAVAX - (treasuryShare + marketingShare + charityShare);
        uint256 amountAVAXLiquidity = (otherTaxesAVAX * liquidityFee) / (totalFee * 2);
        uint256 amountAVAXReflection = (otherTaxesAVAX * reflectionFee) / totalFee;
        uint256 amountAVAXMarketing = (otherTaxesAVAX * marketingFee) / totalFee;
        uint256 amountAVAXTreasury = (otherTaxesAVAX * treasuryFee) / totalFee;

        if(amountAVAXReflection > 0) {
            distributor.deposit{ value: amountAVAXReflection }();
        }
        bool a;
        bytes memory b;
        (a, b) = payable(marketingFeeReceiver).call{ value: amountAVAXMarketing + marketingShare }('');
        (a, b) = payable(treasuryFeeReceiver).call{ value: amountAVAXTreasury + treasuryShare }('');
        (a, b) = payable(charityWallet).call{value: charityShare}('');

        if (amountToLiquify > 0) {
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
        }

        // Re-Initializing node creation Taxes...
        treasuryTax = 0;
        marketingTax = 0;
        charityCollectedTemp = 0;
    }
    

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= 100 * 10 ** 18);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= 100 * 10 ** 18);
        _maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setMaxWalletExempt(address holder, bool exempt) external onlyOwner {
        isMaxWalletExempt[holder] = exempt;
    }

    function setWalletFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _treasuryFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        treasuryFee = _treasuryFee;
        totalFee = liquidityFee + reflectionFee + marketingFee + treasuryFee;
    }

    function setVaultFees(
        uint256 _claimFeeDenominator,
        uint256 _compoundFeeDenominator,
        uint256 _vaultDepositFeeDenominator,
        uint256 _vaultWithdrawFeeDenominator
    ) external onlyOwner {
        require(totalFee * 3 < claimFeeDenominator && 
                totalFee * 3 < compoundFeeDenominator &&
                totalFee * 3 < _vaultDepositFeeDenominator &&
                totalFee * 3 < _vaultWithdrawFeeDenominator, "Fees cannot exceed 33%");
        claimFeeDenominator = _claimFeeDenominator;
        compoundFeeDenominator = _compoundFeeDenominator;
        vaultDepositFeeDenominator = _vaultDepositFeeDenominator;
        vaultWithdrawFeeDenominator = _vaultWithdrawFeeDenominator;
    }

    function setSellFees(uint256 _sellFee, uint256 _sellFeeDenominator) external onlyOwner {
        require(_sellFee * 3 < _sellFeeDenominator, "Sell fee must be lower than 33%");
        sellFee = _sellFee;
        sellFeeDenominator = _sellFeeDenominator;
    }

    function setFeeReceivers(address _liquidityFeeReceiver, address _marketingFeeReceiver, address _treasuryFeeReceiver) external onlyOwner {
        liquidityFeeReceiver = _liquidityFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        treasuryFeeReceiver = _treasuryFeeReceiver;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply - balanceOf(rewardPool);
    }

    function setSwapBackSettings(uint256 _swapInterval, uint256 _swapThreshold) external onlyOwner {
        swapInterval = _swapInterval;
        swapThreshold = _swapThreshold;
    }

    function setTransferEnabled(uint256 _sniperCooldown) external onlyOwner {
        liquidityAdded = true;
        sniperTimestampThreshold = block.timestamp + _sniperCooldown;
    }

    function initiateLaunchTaxes() external onlyOwner {
        launchTaxTimestamp = block.timestamp;
        launchTaxEndTimestamp = block.timestamp + 7 days;
    }

    function setBlacklistUser(address _user, bool _decision) external onlyOwner {
        blacklisted[_user] = _decision;
    }

    function mintUser(address user, uint256 amount) external onlyOwner authorized{
        _mint(user, amount);
    }

    function setVaultWithdrawCooldown(uint256 _vaultWithdrawCooldown) external onlyOwner {
        vaultWithdrawCooldown = _vaultWithdrawCooldown;
    }

    function setVaultMinDistribution(uint256 _minDistribution) external onlyOwner {
        distributor.setMinDistribution(_minDistribution);
    }

    function setInSwap(bool _inSwap) external onlyVaultDistributor { 
        inSwap = _inSwap;
    }

    event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);

    /* -------------------- PRESALE -------------------- */

    // IERC20 presaleToken;
    // uint256 presaleMax = 1500*10**18;

    // function setPresaleToken(address _presaleToken) external onlyOwner {
    //     presaleToken = IERC20(_presaleToken);
    // }

    // function convertPresaleToReal() external {
    //     require(address(presaleToken) != address(0), "Presale token not set");
    //     uint256 balance = presaleToken.balanceOf(msg.sender);
    //     require(balance > 0 && balance <= presaleMax, "Invalid balance");

    //     presaleToken.transferFrom(msg.sender, address(this), balance);
    //     require(presaleToken.balanceOf(msg.sender) == 0, "Error with conversion");
        
    //     _mint(msg.sender, balance);
    // }
}


// File contracts/interfaces/IERC20Metadata.sol

// SPDX-License-Identifier: MIT




// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity = 0.8.11;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/libraries/Address.sol

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity = 0.8.11;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File contracts/libraries/SafeERC20.sol

// SPDX-License-Identifier: MIT




// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity = 0.8.11;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/utils/Context.sol

// SPDX-License-Identifier: MIT



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity = 0.8.11;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/PaymentSplitter.sol

// SPDX-License-Identifier: MIT



// File: @openzeppelin/contracts/finance/PaymentSplitter.sol


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity = 0.8.11;




/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}


// File contracts/Presale.sol

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.11;


// General ICO Contract...
contract preSale is Auth
{
    address public ETHW;
    address public DAI;
    uint256 public discountCounter;
    constructor(address _ETHW, address _DAI) Auth(msg.sender)
    {
        ETHW =_ETHW;
        DAI = _DAI;
    }
    function purchaseETHW(uint256 _dai)public
    {
        require((_dai > 0) && (_dai <= 1500 * ( 10 ** 18 )), "Invalid Amount of Tokens!");

        if(_dai == 1500 * ( 10**18 ))
        {
            // 10% discount apply...
            IERC20(DAI).transferFrom(msg.sender, address(this), 1350 * (10**18));
            IERC20(ETHW).transfer(msg.sender, 1500 * (10**18));
            discountCounter ++;
        }
        else
        {
            IERC20(DAI).transferFrom(msg.sender, address(this), _dai);
            IERC20(ETHW).transfer(msg.sender, _dai);
        }
    }

}


// File contracts/Referral.sol

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.11;

contract Referral is EtherstonesRewardManager
{
    address public charityWallet = 0x199032b89ebb35D7adA146eCFc2fb50295Fb52BE;
    struct ReferalInfo
    {
        uint256 count;
        uint256 commission;
    }
    // referralAcccout => NodeType => ReferralInfo
    mapping(address => mapping(uint256 => ReferalInfo)) public referrals;
    // userAccount => NodeType => ReferralAccount
    mapping(address => mapping(uint256 => address))public isReferral;

    constructor(address _ethsTokenAddress) EtherstonesRewardManager(_ethsTokenAddress)
    {}

    function mintNodewithReferral(string memory _name, uint256 _amount, uint256 _nodeType, address _referral)public
    {   
        // checking if referral owned the same node...
        require(nodeExists(_referral, _nodeType), "ReferralAccount has no owned Node!");
        // updating commission for referral...
        referrals[_referral][_nodeType].count++;
        referrals[_referral][_nodeType].commission += _amount * 5/1000;
        // minting Tokens and storing in referral contract...
        ethsToken.mintUser(address(this), _amount * 5 / 1000);
        // referralAccount will be used once...
        require(!(isReferral[msg.sender][_nodeType] == _referral), "Cannot use Referral more than once!");
        // after all checks, minting the node...
        mintNode(_name, _amount, _nodeType);
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
    function claimEarnings(uint256 _option, address _referral, uint256 _nodeType)public
    {
        if(_option == 0)
        {
            ethsToken.transfer(_referral, referrals[_referral][_nodeType].commission);
            referrals[_referral][_nodeType].commission = 0;
        }
        if(_option == 1)
        {
            ethsToken.transfer(charityWallet, referrals[_referral][_nodeType].commission);
            referrals[_referral][_nodeType].commission = 0;
        }
        else
        {
            ethsToken.transfer(charityWallet, (referrals[_referral][_nodeType].commission * 50) / 100);
            ethsToken.transfer(_referral, (referrals[_referral][_nodeType].commission * 50) / 100);
            referrals[_referral][_nodeType].commission = 0;
        }
        
    } 

}


// File contracts/utils/ERC20.sol

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity = 0.8.11;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/WETH.sol

// SPDX-License-Identifier: MIT
// File: contracts/ETHSToken.sol

pragma solidity = 0.8.11;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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


// File contracts/FactoryFlat.sol

/**
 *Submitted for verification at snowtrace.io on 2021-11-05
*/

// File: contracts/traderjoe/interfaces/IJoeFactory.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// File: contracts/traderjoe/libraries/SafeMath.sol


pragma solidity = 0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// File: contracts/traderjoe/JoeERC20.sol


pragma solidity =0.6.12;


contract JoeERC20 {
    using SafeMathJoe for uint256;

    string public constant name = "Joe LP Token";
    string public constant symbol = "JLP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Joe: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Joe: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// File: contracts/traderjoe/libraries/Math.sol


pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/traderjoe/libraries/UQ112x112.sol


pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// File: contracts/traderjoe/interfaces/IERC20.sol


pragma solidity >=0.5.0;

interface IERC20Joe {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts/traderjoe/interfaces/IJoeCallee.sol


pragma solidity >=0.5.0;

interface IJoeCallee {
    function joeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// File: contracts/traderjoe/JoePair.sol


pragma solidity =0.6.12;







interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract JoePair is JoeERC20 {
    using SafeMathJoe for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "Joe: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Joe: TRANSFER_FAILED"
        );
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Joe: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(-1) && balance1 <= uint112(-1),
            "Joe: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = IJoeFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20Joe(token0).balanceOf(address(this));
        uint256 balance1 = IERC20Joe(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = IJoeFactory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(
                    liquidity > 0 && liquidity != uint256(-1),
                    "Bad desired liquidity"
                );
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(
                    MINIMUM_LIQUIDITY
                );
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "Joe: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20Joe(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20Joe(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "Joe: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Joe(_token0).balanceOf(address(this));
        balance1 = IERC20Joe(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "Joe: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Joe: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Joe: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                IJoeCallee(to).joeCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20Joe(_token0).balanceOf(address(this));
            balance1 = IERC20Joe(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "Joe: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(_reserve0).mul(_reserve1).mul(1000**2),
                "Joe: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(
            _token0,
            to,
            IERC20Joe(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20Joe(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20Joe(token0).balanceOf(address(this)),
            IERC20Joe(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}

// File: contracts/traderjoe/JoeFactory.sol


pragma solidity =0.6.12;



contract JoeFactory is IJoeFactory {
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(JoePair).creationCode);
    }

    function createPair(address tokenA, address tokenB)
        external
        override
        returns (address pair)
    {
        require(tokenA != tokenB, "Joe: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Joe: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Joe: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(JoePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        JoePair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "Joe: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, "Joe: FORBIDDEN");
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "Joe: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}


// File contracts/Practice/DelegateCalls.sol

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


// File contracts/Practice/Events.sol

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

contract Events
{
    event event1Created(address, uint256);
    event event2Created(address, uint256);
    function hitEvent()public
    {
        emit event1Created(0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce, 34);
        emit event2Created(0x9d12687d1CC9b648904eD837983c51d68Be25656, 78);
    }
}


// File contracts/RouterFlat.sol

/**
 *Submitted for verification at snowtrace.io on 2021-11-05
*/

// File: contracts/traderjoe/interfaces/IJoePair.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/traderjoe/libraries/SafeMath.sol

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// File: contracts/traderjoe/libraries/JoeLibrary.sol

pragma solidity >=0.5.0;

library JoeLibrary {
    using SafeMathJoe for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"80d3905f9b5bc1e70bedc9c6a593d00ebf843811030611c28243b15f78f4b025"
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "JoeLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "JoeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "JoeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/traderjoe/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending AVAX that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: AVAX_TRANSFER_FAILED");
    }
}

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}
// File: contracts/traderjoe/interfaces/IJoeRouter01.sol

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/traderjoe/interfaces/IJoeRouter02.sol

pragma solidity >=0.6.2;

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/traderjoe/interfaces/IJoeFactory.sol

pragma solidity >=0.5.0;

interface IERC20Joe {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts/traderjoe/interfaces/IWAVAX.sol

pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: contracts/traderjoe/JoeRouter02.sol

pragma solidity =0.6.12;

contract JoeRouter02 is IJoeRouter02 {
    using SafeMathJoe for uint256;

    address public immutable override factory;
    address public immutable override WAVAX;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "JoeRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WAVAX) public {
        factory = _factory;
        WAVAX = _WAVAX;
    }

    receive() external payable {
        assert(msg.sender == WAVAX); // only accept AVAX via fallback from the WAVAX contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IJoeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IJoeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = JoeLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = JoeLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "JoeRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = JoeLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "JoeRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = JoeLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IJoePair(pair).mint(to);
    }

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        )
    {
        (amountToken, amountAVAX) = _addLiquidity(
            token,
            WAVAX,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountAVAXMin
        );
        address pair = JoeLibrary.pairFor(factory, token, WAVAX);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWAVAX(WAVAX).deposit{value: amountAVAX}();
        assert(IWAVAX(WAVAX).transfer(pair, amountAVAX));
        liquidity = IJoePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountAVAX)
            TransferHelper.safeTransferAVAX(msg.sender, msg.value - amountAVAX);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = JoeLibrary.pairFor(factory, tokenA, tokenB);
        IJoePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IJoePair(pair).burn(to);
        (address token0, ) = JoeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "JoeRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "JoeRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountAVAX)
    {
        (amountToken, amountAVAX) = removeLiquidity(
            token,
            WAVAX,
            liquidity,
            amountTokenMin,
            amountAVAXMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWAVAX(WAVAX).withdraw(amountAVAX);
        TransferHelper.safeTransferAVAX(to, amountAVAX);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = JoeLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IJoePair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        virtual
        override
        returns (uint256 amountToken, uint256 amountAVAX)
    {
        address pair = JoeLibrary.pairFor(factory, token, WAVAX);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IJoePair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountAVAX) = removeLiquidityAVAX(
            token,
            liquidity,
            amountTokenMin,
            amountAVAXMin,
            to,
            deadline
        );
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountAVAX) {
        (, amountAVAX) = removeLiquidity(
            token,
            WAVAX,
            liquidity,
            amountTokenMin,
            amountAVAXMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(
            token,
            to,
            IERC20Joe(token).balanceOf(address(this))
        );
        IWAVAX(WAVAX).withdraw(amountAVAX);
        TransferHelper.safeTransferAVAX(to, amountAVAX);
    }

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountAVAX) {
        address pair = JoeLibrary.pairFor(factory, token, WAVAX);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IJoePair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        amountAVAX = removeLiquidityAVAXSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountAVAXMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = JoeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? JoeLibrary.pairFor(factory, output, path[i + 2])
                : _to;
            IJoePair(JoeLibrary.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        amounts = JoeLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "JoeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            JoeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        amounts = JoeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "JoeRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            JoeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WAVAX, "JoeRouter: INVALID_PATH");
        amounts = JoeLibrary.getAmountsOut(factory, msg.value, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "JoeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWAVAX(WAVAX).deposit{value: amounts[0]}();
        assert(
            IWAVAX(WAVAX).transfer(
                JoeLibrary.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WAVAX, "JoeRouter: INVALID_PATH");
        amounts = JoeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "JoeRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            JoeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWAVAX(WAVAX).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferAVAX(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WAVAX, "JoeRouter: INVALID_PATH");
        amounts = JoeLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "JoeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            JoeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWAVAX(WAVAX).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferAVAX(to, amounts[amounts.length - 1]);
    }

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WAVAX, "JoeRouter: INVALID_PATH");
        amounts = JoeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "JoeRouter: EXCESSIVE_INPUT_AMOUNT");
        IWAVAX(WAVAX).deposit{value: amounts[0]}();
        assert(
            IWAVAX(WAVAX).transfer(
                JoeLibrary.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0])
            TransferHelper.safeTransferAVAX(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = JoeLibrary.sortTokens(input, output);
            IJoePair pair = IJoePair(
                JoeLibrary.pairFor(factory, input, output)
            );
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20Joe(input).balanceOf(address(pair)).sub(
                    reserveInput
                );
                amountOutput = JoeLibrary.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? JoeLibrary.pairFor(factory, output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            JoeLibrary.pairFor(factory, path[0], path[1]),
            amountIn
        );
        uint256 balanceBefore = IERC20Joe(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Joe(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >=
                amountOutMin,
            "JoeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WAVAX, "JoeRouter: INVALID_PATH");
        uint256 amountIn = msg.value;
        IWAVAX(WAVAX).deposit{value: amountIn}();
        assert(
            IWAVAX(WAVAX).transfer(
                JoeLibrary.pairFor(factory, path[0], path[1]),
                amountIn
            )
        );
        uint256 balanceBefore = IERC20Joe(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Joe(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >=
                amountOutMin,
            "JoeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WAVAX, "JoeRouter: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            JoeLibrary.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20Joe(WAVAX).balanceOf(address(this));
        require(
            amountOut >= amountOutMin,
            "JoeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWAVAX(WAVAX).withdraw(amountOut);
        TransferHelper.safeTransferAVAX(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return JoeLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return JoeLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return JoeLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return JoeLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return JoeLibrary.getAmountsIn(factory, amountOut, path);
    }
}


// File contracts/Testing.sol

// SPDX-License-Identifier: MIT
// File: contracts/EtherstonesRewardManager.sol

pragma solidity = 0.8.11;

interface iPair
{
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}
interface iRouter
{
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}
contract Testing
{
    address public Router = 0xadcBe444619dE95aeDD82245d0B422288b27C895;
    address public Pair;
    address public token0 = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    address public token1 = 0xc8BCb185cBA6A3eC0E509646F2B0D2fFcF668209;
    
    function setPair(address _pair)public
    {
        Pair = _pair;
    }

    function getAVAX(uint256 _tokens)public view returns(uint256 _AVAX)
    {
        (uint256 reserve0, uint256 reserve1, ) = iPair(Pair).getReserves();
        // reserve0 = AVAX
        // reserve1 = ETHW
        uint256 avax = iRouter(Router).quote(_tokens, reserve1, reserve0);
        return avax;
    }
    
}
