pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./ConvertLib.sol";
import "./EquityToken.sol";

contract EquityTokenTrading is EquityTokenFactory {
		
    uint private LockupPeriod = 1 years;
    
    /* modifier timelock() {
        require(now >= block.timestamp.add(LockupPeriod));
        _;
    }*/
    
    function _isReady() internal view returns(bool) {
        return (now >= block.timestamp.add(LockupPeriod));
    }

    function setLockup(uint adjustedLockup) public onlyOwnerOfCom() {
        LockupPeriod = adjustedLockup;
    }

    

}