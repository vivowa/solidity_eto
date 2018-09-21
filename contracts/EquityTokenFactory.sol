pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    mapping (address => uint) balances;

    constructor() public {
		balances[msg.sender] = 10000;
	}

struct EquityToken {
      string name;
      string ticker;
      uint amount;
    }

}