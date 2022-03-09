pragma solidity ^0.6.0;
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {LendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/protocol/configuration/LendingPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./PrizePool.sol";

contract LotteryPool {
    address owner;
    mapping(address => address[]) contractList;
    event LogAddress(address _address);

    constructor() public {
        owner = msg.sender;
    }

    function InitiateNewPool(string memory desc) public returns (address) {
        PrizePool receiverPool = new PrizePool(desc);
        address newProjectAddress = address(receiverPool);
        contractList[msg.sender].push(newProjectAddress);
        emit LogAddress(newProjectAddress);
        return newProjectAddress;
    }

    function GetContractList(address _userAddress)
        public
        view
        returns (address[] memory)
    {
        return contractList[_userAddress];
    }
}
