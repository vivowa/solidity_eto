pragma solidity ^0.4.24;

import "./ConvertLib.sol";
import "./EquityTokenFactory.sol";
import "./EquityToken.sol";

contract TokenProcessingLayer is EquityToken {
    event Transfer(address indexed _from, address indexed _to, uint _value);

    function sendToken(address receiver, uint amount) public returns(bool sufficient) {
		if (OwnerAmountCount[msg.sender] < amount) return false;
		OwnerAmountCount[msg.sender] -= amount;
		OwnerAmountCount[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
    }
}