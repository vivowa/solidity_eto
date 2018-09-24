pragma solidity ^0.4.4;

// @Dev converts Token in ETH
library ConvertLib{
	function convert(uint amount, uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}
