pragma solidity ^0.4.18;

import "./ConvertLib.sol";
import "./EquityTokenFactory.sol";

contract EquityToken is EquityTokenFactory {
		
	event Transfer(address indexed _from, address indexed _to, uint _value);

	function sendToken(address receiver, uint amount) public returns(bool sufficient) {
		if (balances[msg.sender] < amount) return false;
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}
	
	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}
}
