pragma solidity ^0.4.24;

import "./ConvertLib.sol";
import "./EquityTokenFactory.sol";

contract EquityToken is EquityTokenFactory {
	
	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return OwnerAmountCount[addr];
	}

	function getInfosEquityToken(uint index) public view returns (uint, string, string, uint, uint) {
    return (AllEquityToken[index].tokenId, AllEquityToken[index].companyName, AllEquityToken[index].tokenTicker, 
    AllEquityToken[index].totalamount, AllEquityToken[index].nominalvalue);
  }
	
}
