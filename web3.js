// --------------Configurations-------------------------
const Web3 = require('web3');
const json_file = require('./artifacts/contracts/FactoryFlat.sol/JoePair.json');
var web3, contract;
const contract_address = "0xA607f1284273569612e5315883BbE67f57A06443";
const owner_address = "0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce";

async function connectBlockchain()
{
    url = "https://api.avax-test.network/ext/bc/C/rpc";
    try
    {
        web3 = new Web3(url);
    }
    catch(error)
    {
        console.log(error.message)
    }

    // making contract instance...
    const contract_abi = json_file.abi;
    contract = new web3.eth.Contract(contract_abi, contract_address);
    
}

connectBlockchain();
const Accounts = ["0x18a2aaacDF719114CE72def6a66F0B1b5C969E9e", "0xCa06Bdc6F917FeF701c1D6c9f084Cfa74962AD2A","0x5B009F0EB8b46cDaF342E91BF9a155043480eA5f"];
const private_keys = ["9dc78782aba60e861363937857fd0e5338475cb8010fa2dd843e4f34ebbec6ce", "9325915ad8a8d398201ab8ddad38e734f854389256afe75394876e8d7c9b248f", "eb70a64c126e1fc1f040d87d5c87a2333365788fab1bfc3bb8ccee48a3492e3d"];
const Names = ["Bilal", "Ahmad", "Hamza"];
var Balances = [0,0,0];


//--------------Functions-------------------------------
async function Network_id()
{
    const network_id = await web3.eth.net.getId();
    return network_id;
}
function show_contract()
{
    console.log(contract);
    return true;
}
async function get_ether_balance(_account)
{
    return(await web3.eth.getBalance(_account)/Math.pow(10,18));
}
async function get_name()
{
    return(await contract.methods.name().call())
}
async function get_symbol()
{
    return(await contract.methods.symbol().call());
}
async function get_decimal()
{
    return(await contract.methods.decimals().call());
}
async function get_totalsupply()
{
    return(await contract.methods.totalSupply().call());
}

async function token0()
{
    t0 = await contract.methods.token0().call();
    console.log("Token0 Address",t0 );
}
async function getReserves()
{
    = await contract.methods.getReserves();
    console.log();
}
async function token1()
{
    console.log("Token1 Address", await contract.methods.token1().call());
}

//------------------Communicate----------------------

async function main_function()
{

    // var balance = await get_ether_balance(contract_address);
    // console.log("Ether Balance : ", balance);
    // await token0();
    // await token1();
    //await getReserves();
    
}

main_function();