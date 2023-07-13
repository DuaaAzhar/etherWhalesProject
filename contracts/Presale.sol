// SPDX-License-Identifier: MIT
pragma solidity = 0.8.11;
import "./Referral.sol";
import "./interfaces/IERC20.sol";

interface iQethw
{
    function burn(uint256 _amount)external;
    function mint(address _user, uint256 _amount)external;
}

// This Contract is Selling QETHW tokens with DAI...
// Buying Presale Options using DAI and getting QEHTW...
// After Presale QETHW will be converted into ETHW...

contract preSale is Auth, Referral
{
    address public DAI;
    address public QETHW;
    uint256 public endTime;
    uint256 public nodes;
    bool public conversionAllowed;
    mapping(address => string)public presaleNode;
    mapping(address => uint256) public option1;

    constructor(address _DAI, address _QETHW) Referral()
    {
        DAI = _DAI;
        QETHW = _QETHW;
    }

    function startPresale()public onlyOwner
    {
        endTime = block.timestamp + 48 hours;
    }

    function stopPresale()public onlyOwner
    {
        endTime = 0;
    }

    modifier ifPresale()
    {
        require(block.timestamp < endTime, "Presale TimeOut!");
        _;
    }
    modifier isConversion()
    {
        require(conversionAllowed, "Presale Conversion Disabled!");
        _;
    }
    function enableConversion()public onlyOwner
    {
        conversionAllowed = true;
    }
    function disableConversion()public onlyOwner
    {
        conversionAllowed = false;
    }

    function convertTokens()public isConversion
    {
        uint256 _amount = IERC20(QETHW).balanceOf(msg.sender);
        IERC20(QETHW).transferFrom(msg.sender, address(this), _amount);
        ethsToken.mintUser(msg.sender, _amount);
        iQethw(QETHW).burn(_amount);
        option1[msg.sender] = 0;
    }
    
    function convertNode()public isConversion
    {
        // checking node is not created...
        require(bytes(presaleNode[msg.sender]).length > 0, "User have no Presale Node");
        nodes = nodes - 1;
        uint256 nodeID = getNumberOfNodes() + 1;
        ethsToken.mintUser(address(this), 800 * (10 ** 18));
        EtherstoneNode memory nodeToCreate = EtherstoneNode({
                name: presaleNode[msg.sender],
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: 800 * (10 ** 18),
                nodeType: 3,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalBlueWhale ++;
            nodeMapping[nodeID] = nodeToCreate;
        accountNodes[msg.sender].push(nodeID);
        ethsToken.nodeMintTransfer(address(this), 800 * (10 ** 18));
        presaleNode[msg.sender] = "";
        // converting  remaining 400 Tokens
        convertTokens();
    }

    // 0parm-option1   1parm-option2
    function purchaseQETHW(uint256 _qethw, uint256 _option, string memory _name)public ifPresale
    {
        if(_option == 0)
        {
            require(bytes(presaleNode[msg.sender]).length == 0, "Already Purchased other presale option!");
            require((option1[msg.sender] + _qethw) <= 1200 * (10 ** 18), "MAX purchase limit reached!");
            IERC20(DAI).transferFrom(msg.sender, address(this), (_qethw * (9 * (10 ** 17))) / (10 ** 18));
            iQethw(QETHW).mint(msg.sender, _qethw);
            option1[msg.sender] += _qethw;
        }
        if(_option == 1)
        {
            // option 1...
            require(option1[msg.sender] == 0, "Already purchased other presale option!");
            require(bytes(_name).length != 0, "Invalid Node Name!");
            require(bytes(presaleNode[msg.sender]).length == 0, "Option Already Purchased!");
            IERC20(DAI).transferFrom(msg.sender, address(this), 960 * (10 ** 18));
            iQethw(QETHW).mint(msg.sender, 400 * (10 ** 18));
            presaleNode[msg.sender] = _name;
            nodes = nodes + 1;
        }
    }

    function withdrawDAI(uint256 _amount, address _beneficiary)external onlyOwner
    {
        IERC20(DAI).transfer(_beneficiary, _amount);
    }

    function withdrawETHW(uint256 _amount, address _beneficiary)external onlyOwner
    {
        ethsToken.transfer(_beneficiary, _amount);
    }
}
