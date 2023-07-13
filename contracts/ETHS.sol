/**
 *Submitted for verification at snowtrace.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
// File: contracts/ETHSToken.sol


pragma solidity  = 0.8.11;

import "./interfaces/IBEP20.sol";
import "./utils/Auth.sol";
import "./EtherstonesRewardManager.sol";
import "./interfaces/IDEXRouter.sol";
import "./VaultDistributor.sol";
import "./interfaces/IDEXFactory.sol";
import "./libraries/SafeMath.sol";


interface iQethw
{
    function burn(uint256 _amount)external;
    function mint(address _user, uint256 _amount)external;
}

contract ETHSToken is IBEP20, Auth {
    using SafeMath for uint256;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

   // address public tokenAddress;
    uint256 public treasuryTax;
    uint256 public marketingTax;
    EtherstonesRewardManager public rewardManager;
    address private rewardManagerAddress = DEAD;

    uint256 public constant MASK = type(uint128).max;

    // TraderJoe router
    address constant ROUTER = 0xadcBe444619dE95aeDD82245d0B422288b27C895;
    address public WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    address public QETHW = 0xE53582ECAe2C0F3412410540c4ca9924E725fC68;
    address public liquidityFeeReceiver = 0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce;
    address public marketingFeeReceiver = 0x9d12687d1CC9b648904eD837983c51d68Be25656;
    address public treasuryFeeReceiver = 0xCa06Bdc6F917FeF701c1D6c9f084Cfa74962AD2A;
    address public charityWallet = 0x199032b89ebb35D7adA146eCFc2fb50295Fb52BE;
    address public teamWallet = 0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce;
    string constant _name = 'EtherWhales';
    string constant _symbol = 'ETHW';
    uint8 constant _decimals = 18;

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
    // uint256 vaultWithdrawCooldown = 3600 * 24*4;
    uint256 public vaultWithdrawCooldown = 3600 * 24 * 4;
    uint256 _totalSupply = 5_000_000 * (10 ** _decimals);


    

    address public rewardPool = DEAD;

    IDEXRouter public router;
    address public pair;

    VaultDistributor distributor;
    address public distributorAddress = DEAD;

    uint256 private lastSwap = block.timestamp;
    uint256 private swapInterval =  60 * 45; // 45 minutes
    uint256 private swapThreshold = 500 * (10 ** _decimals);

    bool private liquidityAdded = false;
    uint256 private sniperTimestampThreshold;

    uint256 private launchTaxTimestamp;  
    uint256 private launchTaxEndTimestamp;

    mapping(address => bool) blacklisted; 

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
        WAVAX = router.WAVAX();

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
        _approve(address(this), address(router), MAX);

    
        // totalLocked = 192_000 * 10 ** 18; // 192 crystals sold
        // _totalSupply = _totalSupply - (totalLocked / 10) - (496_161_7 * 10**17); // 10% of nodes costs burnt; 496,161.7 presale tokens sold
        // _balances[msg.sender] = _totalSupply;
        // emit Transfer(address(0), msg.sender, _totalSupply);
        // _basicTransfer(msg.sender, treasuryFeeReceiver, totalLocked / 10);
        // _basicTransfer(msg.sender, rewardPool, (2_750_000 * 10 ** 18) + ((totalLocked * 8) / 10));
        // _basicTransfer(msg.sender, liquidityFeeReceiver, 1_311_838_3 * 10 ** 17); // 2,000,000 - 496,161.7
        
        _balances[rewardPool] = 2750000 * (10 ** 18);
        _balances[teamWallet] = 250000 * (10 ** 18);
        // remaining 2M tokens...goes to treasury i.e. 2M-qETHWTotalSupply() goes to treasury wallet...
        // totalSupply = totalSupply - qETHW supply
    }

    function enableLaunch()public onlyOwner
    {
        launchStartTime = block.timestamp;
        launchEndTime = launchStartTime.add(2 days);
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
        charityCollectedTemp += (amount * 100) / claimFeeDenominator;
        charityCollected += (amount * 100) / claimFeeDenominator;
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

    function mintUser(address user, uint256 amount) external authorized{
        _mint(user, amount);
    }
    // custom burn function...
    function burn(uint256 _amount)external
    {
        _balances[msg.sender] -= _amount;
        _totalSupply -= _totalSupply;
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


}

