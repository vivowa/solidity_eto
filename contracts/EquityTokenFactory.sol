pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    
    event newTokenIssuance(uint tokenId, uint totalamount, uint nominalvalue);
    //ToDo: token_id should be indexed;

    mapping (address => mapping (uint => uint)) OwnerToTokenToBalance; //@notes: Wallet of tokens and balances of an owner
   //  mapping (uint => mapping (address => uint) TokenToDistribution; //@notes: Total distribution of a token
    // mapping (uint => address[]) //@notes: Shareholders list of a token
    mapping (uint => uint) IdToIndex; //@notes: at which index of equitytoken array tokenId can be found
    // mapping (address => uint) AddressToIndex; //@notes: at wich index of distribution array adress can be found

    struct EquityToken {
      uint tokenId;
      string companyName;
      string tokenTicker;
      uint totalamount;
      uint nominalvalue;
      }

    struct Distribution {
      uint tokenId;
      address owner;
      uint amount;
    }

    //@notes: array of all EquityToken
    EquityToken[] public AllEquityToken;
    
    
    //@notes: array of all owner and amount of one equity token.
    //@ToDo: test for multiple shares!!
    Distribution[] public TotalDistribution;

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
  
  TotalDistribution.push(Distribution(_tokenId, msg.sender, _totalamount));

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
		return ConvertLib.convert(balanceOf(_addr, _tokenId), 3);
	}
  
  //@dev: balance of owner and type of token
  //@notes: ERC2 mandatory
	function balanceOf(address _addr, uint _tokenId) public view returns(uint) {
		return OwnerToTokenToBalance[_addr][_tokenId];
	}

  //@dev: total amount of a token 
  //@notes: ERC20 mandatory
  function totalSupply(uint _tokenId) public view returns (uint totalSupply_){
  (,,totalSupply_,) = getInfosEquityTokenById(_tokenId);
    return totalSupply_;
  }

  	function getInfosEquityToken(uint _index) public view returns (uint a_, string b_, string c_, uint d_, uint e_) {
    	return (AllEquityToken[_index].tokenId, AllEquityToken[_index].companyName, AllEquityToken[_index].tokenTicker, 
    		AllEquityToken[_index].totalamount, AllEquityToken[_index].nominalvalue);
  }

  function getInfosEquityTokenById(uint _tokenId) public view returns (string b_, string c_, uint d_, uint e_) {
    	uint index = IdToIndex[_tokenId];
      return (AllEquityToken[index].companyName, AllEquityToken[index].tokenTicker, 
    		AllEquityToken[index].totalamount, AllEquityToken[index].nominalvalue);
  }
    //@dev: loops through TotalDistribution array and takes all addresses (owner) for defined tokenId
    //@return: Array with all addresses (owner) for specific tokenId
    function getAllAddressesEquityToken(uint _tokenId) external view returns (address[]) {
      address[] memory outArray_;
       for (uint i = 0; i < TotalDistribution.length; i++) {
         if (_tokenId == TotalDistribution[i].tokenId) {
           outArray_[i] = TotalDistribution[i].owner;
         }
        return outArray_; 
       }
     }
  

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