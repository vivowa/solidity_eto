pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    
    event newTokenIssuance(uint tokenId, uint totalamount, uint nominalvalue);
    
    mapping (address => uint) OwnerAmountCount; // Anzahl an Aktien eines Inhabers
    mapping (uint => address) EquityToOwner; // Liste mit Inhabern einer Aktie
    mapping (uint => uint) IdToIndex;

    struct EquityToken {
      uint tokenId;
      string tokenName;
      string tokenTicker;
      uint totalamount;
      uint nominalvalue;
      }

    EquityToken[] public AllEquityToken;

    constructor() public {
		// OwnerAmountCount[msg.sender] = 10000;   
	}  

  // ensures, that tokenId is always 8 digits
  uint idModulus = 10 ** 8;

  function createEquityToken(string _tokenName, string _tokenTicker, uint _totalamount, uint _nominalvalue) public {
  uint tokenId = _generateRandomTokenId(_tokenName);
  // Approval Process (require)
  _createEquityToken(tokenId, _tokenName, _tokenTicker, _totalamount, _nominalvalue);
  }

  function _createEquityToken(uint _tokenId, string _tokenName, string _tokenTicker, uint _totalamount, uint _nominalvalue) internal {
  uint arrayIndex = AllEquityToken.push(EquityToken(_tokenId, _tokenName, _tokenTicker, _totalamount, _nominalvalue)) - 1;
  OwnerAmountCount[msg.sender] = _totalamount;
  EquityToOwner[_tokenId] = msg.sender;
  IdToIndex[_tokenId] = arrayIndex;
  emit newTokenIssuance(_tokenId, _totalamount, _nominalvalue);
  }

  // @dev: generates an unique 8 digit tokenId by hashing string and a nonce
  // @security: could error if uint + randNonce > 256 digits
  function _generateRandomTokenId(string _tokenName) private view returns (uint) {
  uint randNonce = 0;
  uint random = uint(keccak256(abi.encodePacked(_tokenName, randNonce)));
  randNonce++;
  return random % idModulus;
  }

  
}