pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    
    event newTokenIssuance(uint indexed tokenId, uint totalamount, uint nominalvalue);
    
    mapping (address => uint) OwnerToAmount; // Depot of an owner
    mapping (uint => Ownership[]) TokenToOwner; // Shareholders list of a token
    mapping (uint => uint) IdToIndex; // At which index of equitytoken array tokenId can be found, can also be used for ownership array

    struct EquityToken {
      uint tokenId;
      string companyName;
      string tokenTicker;
      uint totalamount;
      uint nominalvalue;
      }

    struct Ownership {
      uint tokenId;
      address owner;
      uint amount;
    }

    Ownership[] public TotalDistribution;

    EquityToken[] public AllEquityToken;

    constructor() public {
		// OwnerAmountCount[msg.sender] = 10000;   
	}  

  // @dev: ensures, that tokenId is always 8 digits
  uint idModulus = 10 ** 8;

  // @dev: public issuance function, requires approval and creates unique id
  function createEquityToken(string _companyName, string _tokenTicker, uint _totalamount, uint _nominalvalue) public {
  uint tokenId = _generateRandomTokenId(_companyName);
  // Approval Process (require)
  _createEquityToken(tokenId, _companyName, _tokenTicker, _totalamount, _nominalvalue);
  }

  // @dev: creates new Token, safes information in public array, maps array index with tokenid and transfers ownership
  function _createEquityToken(uint _tokenId, string _companyName, string _tokenTicker, uint _totalamount, uint _nominalvalue) internal {
  uint arrayIndex = AllEquityToken.push(EquityToken(_tokenId, _companyName, _tokenTicker, _totalamount, _nominalvalue)) - 1;
  IdToIndex[_tokenId] = arrayIndex;
  
  TotalDistribution.push(Ownership(_tokenId, msg.sender, _totalamount));
  TokenToOwner[_tokenId] = TotalDistribution;

  OwnerToAmount[msg.sender] = _totalamount;
  
  emit newTokenIssuance(_tokenId, _totalamount, _nominalvalue);
  }

  // @dev: generates an unique 8 digit tokenId by hashing string and a nonce
  // @security: could error if uint + randNonce > 256 digits
  function _generateRandomTokenId(string _companyName) private view returns (uint) {
  uint randNonce = 0;
  uint random = uint(keccak256(abi.encodePacked(_companyName, randNonce)));
  randNonce++;
  return random % idModulus;
  }

  
}