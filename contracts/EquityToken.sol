pragma solidity ^0.4.24;

import "./ConvertLib.sol";
import "./EquityTokenFactory.sol";

contract EquityToken is EquityTokenFactory {
		
	event Transfer(address indexed _from, address indexed _to, uint _value);

    function sendToken(address receiver, uint amount) public returns(bool sufficient) {
		if (OwnerAmountCount[msg.sender] < amount) return false;
		OwnerAmountCount[msg.sender] -= amount;
		OwnerAmountCount[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}
	
	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return OwnerAmountCount[addr];
	}

	function getInfosEquityToken(uint index) public view returns (uint, string, string, uint, uint) {
    return (AllEquityToken[index].tokenId, AllEquityToken[index].tokenName, AllEquityToken[index].tokenTicker, 
    AllEquityToken[index].totalamount, AllEquityToken[index].nominalvalue);
  }
	
}
