pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    
    event newTokenIssuance(string token_id, uint totalamount, uint nominalvalue);
    
    mapping (address => uint) OwnerAmountCount;

    struct EquityToken {
      string token_name;
      string token_id;
      string token_ticker;
      uint totalamount;
      uint nominalvalue;
      uint marketvalue;
    }

    constructor() public {
		OwnerAmountCount[msg.sender] = 10000;
	}
}