pragma solidity ^0.4.24;

///@dev converts Token in ETH
library ConvertLib{

	function convert(uint amount, uint conversionRate) public pure returns (uint convertedAmount)
		{
			return amount * conversionRate;
	}
}
