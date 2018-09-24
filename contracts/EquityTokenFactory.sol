pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    
    event newTokenIssuance(uint tokenId, uint totalamount, uint nominalvalue);
    //ToDo: token_id should be indexed;

    mapping (address => mapping (uint => uint)) OwnerToTokenToBalance; // Wallet of tokens and balances of an owner
    mapping (uint => Distribution) TokenToDistribution; // Shareholders list of a token
    mapping (uint => uint) IdToIndex; // At which index of equitytoken array tokenId can be found, can also be used for ownership array

    struct EquityToken {
      uint tokenId;
      string companyName;
      string tokenTicker;
      uint totalamount;
      uint nominalvalue;
      }

    struct Distribution {
      address owner;
      uint amount;
    }  

    //@notes: array of all EquityToken
    EquityToken[] public AllEquityToken;

    address[] public TotalDistribution;

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
  uint EquityArrayIndex = AllEquityToken.push(EquityToken(_tokenId, _companyName, _tokenTicker, _totalamount, _nominalvalue)) - 1;
  IdToIndex[_tokenId] = EquityArrayIndex;
   
  TokenToDistribution[_tokenId].owner = msg.sender;
  TokenToDistribution[_tokenId].amount = _totalamount;

  OwnerToTokenToBalance[msg.sender][_tokenId] = _totalamount; 
    
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
  function getBalanceInEth(address _addr, uint _tokenId) public view returns(uint){
		return ConvertLib.convert(getBalance(_addr, _tokenId), 3);
	}

	function getBalance(address _addr, uint _tokenId) public view returns(uint) {
		return OwnerToTokenToBalance[_addr][_tokenId];
	}

  	function getInfosEquityToken(uint index) public view returns (uint, string, string, uint, uint) {
    	return (AllEquityToken[index].tokenId, AllEquityToken[index].companyName, AllEquityToken[index].tokenTicker, 
    		AllEquityToken[index].totalamount, AllEquityToken[index].nominalvalue);
  }

  /*	function getDistributionEquityToken(uint index) public view returns (uint, address, uint) {
    	return (TotalDistribution[index].tokenId, TotalDistribution[index].owner, TotalDistribution[index].amount);
  } */

// --- EquityTokenProcessing ---
  event Transfer(address indexed from, address indexed to, uint tokenId, uint txamount);

    function sendToken(address _receiver, uint _tokenId, uint _txamount) public returns(bool sufficient) {
		if (OwnerToTokenToBalance[msg.sender][_tokenId] < _txamount) return false;
		OwnerToTokenToBalance[msg.sender][_tokenId] -= _txamount;
		OwnerToTokenToBalance[_receiver][_tokenId] += _txamount;
		emit Transfer(msg.sender, _receiver, _tokenId, _txamount);
		return true;
    }


}