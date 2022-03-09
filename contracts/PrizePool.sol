pragma solidity ^0.6.0;
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {LendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/protocol/configuration/LendingPoolAddressesProvider.sol";
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
import  "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrizePool {
    address creator;
    enum PoolState{ OPEN, FINISHED }
    PoolState status;
    string name;
    string desc;
    player[] playerArray;
    uint256 totalReceived;
    mapping (address => uint256) public balances;
    address daiAddress = address(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD); // testnet DAI
    address aDaiAddress = address(0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8);
    address lendingPoolAddr = address(0x88757f2f99175387aB4C6a4b3067c77A695b0349);

    struct player {
        address payable playerAddress;
        uint256 amount;    
    }
    
    //initalize pool
    constructor(string memory dsc) public {
        creator = msg.sender;
        desc = dsc;
        status = PoolState.OPEN;
    }

    //update balances map
    function UpdatePlayIn(address playerAddress,  uint256 amount) public {
        for (uint i; i < playerArray.length; i++){
            if (playerArray[i].playerAddress == playerAddress) {
                playerArray[i].amount += amount;
            }
        }
    }

    //Receive money for prize pool
    function ReceivePlayIn() public payable {
        require(state == PoolState.OPEN);
        if (balances[msg.sender] == 0) {
            balances[msg.sender] = msg.value;
            player memory PlayInEntry = player(msg.sender, msg.value);
            playerArray.push(PlayInEntry);
        } else {
            balances[msg.sender] += msg.value;
            UpdatePlayIn(msg.sender, msg.value);
        }
        //Transfer Dai to this contract address
        IERC20(daiAddress).transferFrom(msg.sender, address(this), msg.value);
        totalReceived += msg.value;
        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(lendingPoolAddr);  // kovan address, for other addresses: https://docs.aave.com/developers/deployed-contracts/deployed-contracts
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        //have lending pool approve to spend dai
        IERC20(daiAddress).approve(provider.getLendingPool(), msg.value);
        //deposit to have interest bearing dai
        lendingPool.deposit(daiAddress, msg.value, address(this), 0);
    }

    // retrieve balance of total interest bearing DAI
    function GetBalance() public view returns(uint256) {
        uint256 balance = IERC20(aDaiAddress).balanceOf(address(this));
        return balance;
    }

    //Generate a random number using the player array and the block timestamp
    function random() private view returns(uint){ 
        return uint (keccak256(abi.encode(block.timestamp, playerArray)));
    }

    // determine winner for prize pool
    function pickWinner() public restricted{
        require(state == PoolState.OPEN);
        require(msg.sender == creator);
        uint index = random() % players.length;
        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(lendingPoolAddr);  // kovan address, for other addresses: https://docs.aave.com/developers/deployed-contracts/deployed-contracts
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        //Pay out user
        uint256 totalBalance = GetBalance();
        uint256 payout = totalBalance - totalReceived;
        lendingPool.withdraw(daiAddress, payout, player[index].address);
        //Set Pool to closed
        status = PoolState.CLOSED;
    }

    // Permit a player to withdraw there balance
    function WithdrawPlayerBalance() public payable {
        require(state == PoolState.CLOSED);
        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(lendingPoolAddr);  
        // kovan address, for other addresses: https://docs.aave.com/developers/deployed-contracts/deployed-contracts
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        uint256 withdrawlBalance = balances[msg.sender];
        //set balance of user as zero
        balances[msg.sender] = 0;
        delete playerArray[msg.sender];
        lendingPool.withdraw(daiAddress, withdrawlBalance, msg.sender);
    }

    function GetDesc() public view returns (string memory) {
        return desc;
    }
}