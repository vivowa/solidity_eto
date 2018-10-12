pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract EquityTokenFactory {
    
    event newTokenIssuance(uint tokenId, uint totalamount, uint nominalvalue);
    //ToDo: token_id should be indexed;

    mapping (address => uint) OwnerToBalance; //@notes: Wallet of tokens and balances of an owner
    // mapping (address => EquityToken) OwnerToArtifact; //@notes: maps company address with EquityToken
    // mapping (uint => Distribution[]) TokenToAddress; //@notes: Shareholders list of a token
    // mapping (uint => uint) TokenToIndex; //@notes: at which index of equitytoken array tokenId can be found
    mapping (address => uint) AddressToIndex; //@notes: at wich index of distribution array address can be found
    mapping (address => bool) AddressExists;
    mapping (address => mapping (address => uint)) allowed; //@notes: allowance for transfer from _owner to _receiver to withdraw


    
    modifier checkGranularity(uint _amount){
    require((_amount % granularity == 0), "unable to modify token balances at this granularity");
    _;
    }
      
    modifier onlyOwnerOfCom() {
    require(msg.sender == ArtifactEquityToken.companyowner, "requirement onlyOwner of Company modifier");
    _;
  }  

    struct EquityToken {
      uint tokenId;
      string companyName;
      string tokenTicker;
      uint totalamount;
      uint nominalvalue;
      address companyowner;
      }

    
    // @notes: the EquityToken
    EquityToken public ArtifactEquityToken;
        
    //@notes: array of all owner and amount of one equity token.
    address[] public TotalDistribution;

    

    // @dev: ensures, that tokenId is always 8 digits
    uint idModulus = 10 ** 8;

    // @dev: ensures, that granularity of shares is always natural figures
    uint granularity = 10 ** 0;

  // @dev: public issuance function, requires approval and creates unique id
  function createEquityToken(string _companyName, string _tokenTicker, uint _totalamount, uint _nominalvalue) public {
  uint tokenId = _generateRandomTokenId(_companyName);
  
  //@ToDo: Approval Process (require)
  _createEquityToken(tokenId, _companyName, _tokenTicker, _totalamount, _nominalvalue);
  }

  // @ToDo: constructor, as contract w/o function
  // @dev: creates new Token, safes information in public array, maps array index with tokenid and transfers ownership
  function _createEquityToken(uint _tokenId, string _companyName, string _tokenTicker, uint _totalamount, uint _nominalvalue) internal {
  
  ArtifactEquityToken = EquityToken(_tokenId, _companyName, _tokenTicker, _totalamount, _nominalvalue, msg.sender);
    
  _toShareholderbook(msg.sender);

  OwnerToBalance[msg.sender] = _totalamount;

  emit newTokenIssuance(_tokenId, _totalamount, _nominalvalue);
  emit newShareholder(msg.sender, TotalDistribution.length);
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

  event newShareholder(address newShareholder, uint length);

  function getBalanceOfInEth(address _addr) public view returns(uint){
		return ConvertLib.convert(balanceOf(_addr), 3);
	}

  //@dev: balance for owner and type of token
  //@notes: ERC2 mandatory
	function balanceOf(address _addr) public view returns(uint) {
		return OwnerToBalance[_addr];
	}

  //@dev: total amount of a token 
  //@notes: ERC20 mandatory
  function totalSupply() public view returns (uint totalSupply_){
    return totalSupply_ = ArtifactEquityToken.totalamount;
  }
    //@dev: returns Infos of equity token, as struct is not returnable in current solidity version
  	function getInfosEquityToken() public view returns (uint, string, string, uint, uint) {
    	return (ArtifactEquityToken.tokenId, ArtifactEquityToken.companyName, ArtifactEquityToken.tokenTicker, 
    		ArtifactEquityToken.totalamount, ArtifactEquityToken.nominalvalue);
  } 

    function _toShareholderbook(address _addr) internal returns(bool success_) {
    if (_checkExistence(_addr)) return false;
    
    uint DistributionIndex = TotalDistribution.push(address(_addr)) - 1;
    AddressToIndex[_addr] = DistributionIndex;
    AddressExists[_addr] = true;

    emit newShareholder(_addr, TotalDistribution.length);
    return true;
    }

    function _checkExistence(address _addr) internal view returns(bool success_) {
      return AddressExists[_addr];
    }

    
    //@dev: loops through TotalDistribution array and takes all addresses (owner) for defined tokenId
    //@return: Array with all addresses (owner) for specific tokenId
    /*@notes: for later reference: address[] memory outArray_ = new address[](TotalDistribution.length);
       for (uint i = 0; i < TotalDistribution.length; i++) {
            outArray_[i] = TotalDistribution[i];
         }
        return outArray_; */
    function getAllAddressesEquityToken() public view returns(address[]) {
       return TotalDistribution;
          }
     

// --- EquityTokenBusiness --- 
  
  //@dev: fires an event after percentage of dividend is determined and transfered    
  event Dividend(uint _txpercentage);

  //@dev: pays a dividend to all owner of the shares depending on determined percentage of owners portfolio value
  function payDividend(uint _txpercentage) public onlyOwnerOfCom() {
    
  //@ToDo: pay dividend in eth, timer -> pay every year auto; a) gesamt kosten b) unternehmen überweist ETH c) 
  // payable function d) wer sind stakeholder, wieviel bekommt, transfer // Nominalvalue
  //@ToDo: require to have enough shares at account of company
    for (uint i = 1; i < TotalDistribution.length; i++) {
      uint _txamount = _txpercentage * balanceOf(TotalDistribution[i]);
      transfer(TotalDistribution[i] , _txamount);
    }

    emit Dividend(_txpercentage);
  }



// --- EquityTokenProcessing ---

  // @notes: indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
  //@notes: ERC20 mandatory
  event Transfer(address _from, address _to, uint _txamount);
  event Approval(address _from, address _to, uint _txamount);

    //@dev: transfers token from A to B and fires event, additionally updates the TotalDistribution array (shareholder book)
    //@notes: ERC20 mandatory
    function transfer(address _receiver, uint _txamount) public returns(bool success_) {
		if (OwnerToBalance[msg.sender] < _txamount) return false;
		OwnerToBalance[msg.sender] -= _txamount;
		OwnerToBalance[_receiver] += _txamount;

    _toShareholderbook(_receiver);

    emit Transfer(msg.sender, _receiver, _txamount);
    return true;
    }

    //@dev: transfers token from A to B and fires event, additionally updates the TotalDistribution array (shareholder book); transferFrom should be used for withdrawing workflow
    //@notes: ERC20 mandatory
    function transferFrom(address _from, address _to, uint _txamount) public returns(bool success_) {
		uint allowance = allowed[_from][msg.sender];
    require ((OwnerToBalance[_from] >= _txamount && allowance >= _txamount), "no approval for transaction");
		OwnerToBalance[_from] -= _txamount;
		OwnerToBalance[_to]+= _txamount;

    _toShareholderbook(_to);

    emit Transfer(_from, _to, _txamount);
		return true;
    }

    //@dev: sender can approve an amount to be withdrawn by spender
    //@notes: ERC20 mandatory
    function approve(address _spender, uint _txamount) public returns(bool success_) {
    allowed[msg.sender][_spender] = _txamount;
    emit Approval(msg.sender, _spender, _txamount);
    return true;
    }

    //@notes: ERC20 mandatory
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
      return allowed[_owner][_spender];
    }


}