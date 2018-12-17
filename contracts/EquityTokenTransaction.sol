pragma solidity ^0.4.24;

import "./ConvertLib.sol";
import "./SafeMath.sol";
import "./EquityTokenFactory.sol";
import "./EquityToken.sol";

contract EquityTokenTransaction is EquityToken {

//-----TokenTransactions------------------------------------------------------------------------------------------------------------------
  /* This section determines transaction protocolls of the issued equity token
        - this section has the internal but executing send functions!
        -
        */  

    ///@notice fires event of after regular token transfer defined by ERC777 or EIP1410
    event Sent(address operator, address from, address to, uint amount, bytes userData, bytes operatorData);
    event SentByTranche(uint fromTranche, address operator, address from, address to, uint amount, bytes userData, bytes operatorData);

    ///@notice function actually performing the sending of tokens.
    ///@param _trancheId tranche for transfer
    ///@param _userData data generated by the user to be passed to the recipient. The rules determining if a security token can be sent may require off-chain inputs
    /// therefore functions accept an additional bytes _userData parameter which can be signed by an approved party and used to validate a transfer (e.g signature).
    ///@param _operatorData data generated by the operator to be passed to the recipient
    ///@dev _preventLocking true if you want this function to throw when tokens are sent to or sent by a contract not implementing ERC777.
    /// ERC777 native Send functions MUST set this parameter to true, and backwards compatible ERC20 transfer functions SHOULD set this parameter to false.
    /// In this testing environment _preventLocking is not implemented stick to official ERC777 for further information and implementation of this feature.
    function _doSend(uint _trancheId, address _from, address _to, uint _txamount, bytes _userData, address _operator, bytes _operatorData) 
    internal checkGranularity(_txamount) checkAccreditation(_to) returns(uint receiverTrancheId_) {
        require((_isRegularAddress(_to) == true), "_to address does not exist or is 0x0 (burning)");
        require((LevelOfAccreditation[_to] == 1), "_to address is not authorized or accredited");     
        require((OwnerToTrancheToBalance[_from][_trancheId] >= _txamount), "not enough tranche-specific funding for transaction on account");
        require((_isReady(_trancheId) == true),"lockup period not over for this tranche");
        require((TotalDistribution.length <= regulationMaximumInvestors), "max. amount of investors");
        
        OwnerToBalance[_from] = OwnerToBalance[_from].sub(_txamount);
        OwnerToBalance[_to] = OwnerToBalance[_to].add(_txamount);
        require((OwnerToBalance[_to] <= regulationMaximumSharesPerInvestor), "max. amount of shares by one investor (10%)");

        _toShareholderbook(_to);
        
        emit Sent(_operator, _from, _to, _txamount, _userData, _operatorData);
        
        receiverTrancheId_ = _generateRandomId();
        IdToMetaData[receiverTrancheId_] = (TrancheMetaData(_txamount, block.timestamp, defaultLockupPeriod));

        OwnerToTrancheToBalance[_from][_trancheId] = OwnerToTrancheToBalance[_from][_trancheId].sub(_txamount);
        OwnerToTrancheToBalance[_to][receiverTrancheId_] = OwnerToTrancheToBalance[_to][receiverTrancheId_].add(_txamount);
        OwnerToTranches[_to].push(uint(receiverTrancheId_));
        emit SentByTranche(_trancheId, _operator, _from, _to, _txamount, _userData, _operatorData);
        
        if(OwnerToBalance[_from] == 0) {_deleteShareholder(_from);}
        if(erc20compatible) {emit Transfer(_from, _to, _txamount);}

        return receiverTrancheId_;
    }

    ///@notice private send function used if no tranche is initially defined, then uses default tranche
    function _doSend(address _from, address _to, uint _txamount, bytes _userData, address _operator, bytes _operatorData) 
    internal {
        require((OwnerToBalance[_from] >= _txamount), "not enough general funding for transaction on account");
        uint[] memory tempSenderTranches = OwnerToTranches[_from];
        uint sentAmount = 0;
        uint counter = 1;
        
        while(sentAmount < _txamount) {
            uint tempTrancheId = tempSenderTranches[tempSenderTranches.length - counter];
                
            if(OwnerToTrancheToBalance[_from][tempTrancheId] >= _txamount.sub(sentAmount)) {
                _doSend(tempTrancheId, _from, _to, _txamount.sub(sentAmount), _userData, _operator, _operatorData);
                break;
            }
            else {
                uint sentTx = OwnerToTrancheToBalance[_from][tempTrancheId];
                _doSend(tempTrancheId, _from, _to, sentTx, _userData, _operator, _operatorData);
                sentAmount = sentAmount.add(sentTx);
                counter = counter.add(1);
            }
        } 
    }
    
    ///@notice gets the tranches of a token holder, in general the default tranche for a transaction is the latest issued tranche an owner posseses
    ///@dev mandatory for backward interoperability with ERC777 and ERC20
    function getDefaultTranches(address _from) public view returns(uint[]) {
        return tranchesOf(_from);
    }

//-----TokenTransactions------------------------------------------------------------------------------------------------------------------    

}