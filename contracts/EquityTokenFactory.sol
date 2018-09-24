pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    
    event newTokenIssuance(uint tokenId, uint totalamount, uint nominalvalue);
    //ToDo: token_id should be indexed;

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

    //@notes: array of all EquityToken
    EquityToken[] public AllEquityToken;

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


// --- EquityToken ---
  function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return OwnerToAmount[addr];
	}

	function getInfosEquityToken(uint index) public view returns (uint, string, string, uint, uint) {
    	return (AllEquityToken[index].tokenId, AllEquityToken[index].companyName, AllEquityToken[index].tokenTicker, 
    		AllEquityToken[index].totalamount, AllEquityToken[index].nominalvalue);
  }

  	function getDistributionEquityToken(uint index) public view returns (uint, address, uint) {
    	return (TotalDistribution[index].tokenId, TotalDistribution[index].owner, TotalDistribution[index].amount);
  }

// --- EquityTokenProcessing ---
  event Transfer(address indexed _from, address indexed _to, uint _value);

    function sendToken(address receiver, uint amount) public returns(bool sufficient) {
		if (OwnerToAmount[msg.sender] < amount) return false;
		OwnerToAmount[msg.sender] -= amount;
		OwnerToAmount[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
    }


}