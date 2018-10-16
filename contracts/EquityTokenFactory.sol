pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./ConvertLib.sol";

contract EquityTokenFactory {

    using SafeMath for uint;

    //@ToDo: indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
    event newTokenIssuance(uint tokenId, uint totalamount, address companyowner);

    mapping (address => uint) OwnerToBalance; //@notes: Wallet of tokens and balances of an owner
    mapping (address => uint) AddressToIndex; //@notes: at wich index of distribution array address can be found
    mapping (address => bool) AddressExists; //@notes: required for check if address is already stakeholder, more efficient than iterating array
    mapping (address => mapping (address => uint)) allowed; //@notes: allowance for transfer from _owner to _receiver to withdraw (ERC20)
    
    modifier checkGranularity(uint _amount){
    require((_amount % granularity == 0), "unable to modify token balances at this granularity");
    _;
    }
    
    modifier onlyOwnerOfCom() {
    require(msg.sender == ArtifactEquityToken.companyOwner, "requirement onlyOwner of Company modifier");
    _;
  }


//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------  

    struct EquityToken {
      uint tokenId;
      bytes32 companyName;
      bytes32 tokenTicker;
      uint totalamount;
      address companyOwner;
      }
    
    //@notes: the EquityToken
    EquityToken public ArtifactEquityToken;
        
    //@notes: array of all owner and amount of one equity token.
    address[] public TotalDistribution;
    
    //@dev: ensures, that tokenId is always 8 digits
    uint idModulus = 10 ** 8;

    //@dev: ensures, that granularity of shares is always natural figures
    uint granularity = 1;

  //@dev: public issuance function, requires approval and creates unique id
  function createEquityToken(bytes32 _companyName, bytes32 _tokenTicker, uint _totalamount) public {
  uint tokenId = _generateRandomTokenId(_companyName);
  
  //@ToDo: Approval Process (require)
  _createEquityToken(tokenId, _companyName, _tokenTicker, _totalamount);
  }

  //@ToDo: constructor, as contract w/o function
  //@dev: creates new Token, safes information in public array, maps array index with tokenid and transfers ownership
  function _createEquityToken(uint _tokenId, bytes32 _companyName, bytes32 _tokenTicker, uint _totalamount) internal {
  
  ArtifactEquityToken = EquityToken(_tokenId, _companyName, _tokenTicker, _totalamount, msg.sender);
  
  _toShareholderbook(msg.sender);

  OwnerToBalance[msg.sender] = _totalamount;

  emit newTokenIssuance(_tokenId, _totalamount, msg.sender);
  }

  //@dev: generates an unique 8 digit tokenId by hashing string and a nonce
  function _generateRandomTokenId(bytes32 _companyName) private view returns (uint) {
  uint randNonce = 0;
  uint random = uint(keccak256(abi.encodePacked(_companyName, randNonce)));
  randNonce.add(1);
  return random % idModulus;
  }

  //@dev: manage documents associated with token
  //@notes: ERC 1440 proposal
  function getDocument(bytes32 _name) external view returns (string, bytes32){

  }
  
  //@dev: manage documents associated with token
  //@notes: ERC 1440 proposal
  function setDocument(bytes32 _name, string _uir, bytes32 _documentHash) external {

  }

//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------


//-----EquityToken------------------------------------------------------------------------------------------------------------------------
    /* This structure allows a company to propose multiple proposals for an issue, voters can than choose one of the proposals 
        - the owning company works as an administrator and can start ballots
        - the number of votes are linked to the amount of shares a voter posseses (1:1)
        - voters can pass their right to vote
        - the winning proposal is calculated and broadcasted automatically
        */

  //@dev: adjustment and new length of shareholder book
  event newShareholder(address newShareholder, uint length);

  //@notes: string as bytes32 only has space for 32 characters
  event adHocMessage(string _message, address _company);
  //@ToDo: automatic quarterly update
  //event quaterlyUpdate(uint _revenue, uint _revenueforecast);

  function getBalanceOfInEth(address _addr) public view returns(uint){
		return ConvertLib.convert(balanceOf(_addr), 3);
	}

  //@dev: balance for any owner
  //@notes: ERC20 mandatory
	function balanceOf(address _addr) public view returns(uint) {
		return OwnerToBalance[_addr];
	}

  //@dev: total amount of a token 
  //@notes: ERC20 mandatory
  function totalSupply() public view returns (uint totalSupply_){
    return totalSupply_ = ArtifactEquityToken.totalamount;
  }
    //@dev: returns Infos of equity token, as struct is not returnable in current solidity version
  	function getInfosEquityToken() public view returns (uint, bytes32, bytes32, uint) {
    	return (ArtifactEquityToken.tokenId, ArtifactEquityToken.companyName, ArtifactEquityToken.tokenTicker, 
    		ArtifactEquityToken.totalamount);
  } 

    //@dev: iternal function to push new address to shareholder book, checks if address exists first
    function _toShareholderbook(address _addr) internal returns(bool success_) {
    if (_checkExistence(_addr)) return false;
    
    uint DistributionIndex = TotalDistribution.push(address(_addr)) - 1;
    AddressToIndex[_addr] = DistributionIndex;
    AddressExists[_addr] = true;

    emit newShareholder(_addr, TotalDistribution.length);
    return true;
    }

    //@dev: checks existence of address in shareholder book by using mapping (address => bool)
    function _checkExistence(address _addr) internal view returns(bool success_) {
      return AddressExists[_addr];
    }

    
    //@dev: getter for TotalDistribution array
    //@return: array with all addresses (owner)
       function getAllAddressesEquityToken() public view returns(address[]) {
       return TotalDistribution;
          }

       function getCompanyOwner() public view returns(address) {
        return ArtifactEquityToken.companyOwner; 
       }

       function setCompanyOwner(address _addr) public onlyOwnerOfCom() {
         ArtifactEquityToken.companyOwner = _addr;
       } 
  

  //@dev: possible to broadcast adHocMessages for any size
  function sendAdHocMessage(string _message) public onlyOwnerOfCom() {
    emit adHocMessage(_message, msg.sender);
  }
//-----EquityToken------------------------------------------------------------------------------------------------------------------------



//-----TokenTransactions------------------------------------------------------------------------------------------------------------------
  /* This structure allows a company to propose multiple proposals for an issue, voters can than choose one of the proposals 
        - the owning company works as an administrator and can start ballots
        - the number of votes are linked to the amount of shares a voter posseses (1:1)
        - voters can pass their right to vote
        - the winning proposal is calculated and broadcasted automatically
        */

  //@ToDo: indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
  //@notes: ERC20 mandatory
  event Transfer(address _from, address _to, uint _txamount);
  event Approval(address _from, address _to, uint _txamount);

  //@dev: fires an event after percentage of dividend is determined and transfered    
  event Dividend(uint _txpercentage);
  

    //@dev: transfers token from A to B and fires event, additionally updates the TotalDistribution array (shareholder book)
    //@notes: ERC20 mandatory
    function transfer(address _receiver, uint _txamount) public checkGranularity(_txamount) returns(bool success_) {
		if (OwnerToBalance[msg.sender] < _txamount) return false;
		OwnerToBalance[msg.sender] = OwnerToBalance[msg.sender].sub(_txamount);
		OwnerToBalance[_receiver] = OwnerToBalance[_receiver].add(_txamount);

    _toShareholderbook(_receiver);

    emit Transfer(msg.sender, _receiver, _txamount);
    return true;
    }

    //@dev: transfers token from A to B and fires event, additionally updates the TotalDistribution array (shareholder book); transferFrom should be used for withdrawing workflow
    //@notes: ERC20 mandatory
    function transferFrom(address _from, address _to, uint _txamount) public checkGranularity(_txamount) returns(bool success_) {
		uint allowance = allowed[_from][msg.sender];
    require((OwnerToBalance[_from] >= _txamount && allowance >= _txamount), "no approval for transaction");
		OwnerToBalance[_from] = OwnerToBalance[_from].sub(_txamount);
		OwnerToBalance[_to] = OwnerToBalance[_to].add(_txamount);

    _toShareholderbook(_to);

    emit Transfer(_from, _to, _txamount);
		return true;
    }

    //@dev: sender can approve an amount to be withdrawn by spender
    //@notes: ERC20 mandatory
    function approve(address _spender, uint _txamount) public checkGranularity(_txamount) returns(bool success_) {
    allowed[msg.sender][_spender] = _txamount;
    emit Approval(msg.sender, _spender, _txamount);
    return true;
    }

    //@notes: ERC20 mandatory
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
      return allowed[_owner][_spender];
    }

    //@dev: transfers of security might fail to multiple reasons (e.g. identity of sender and receiver, trading limits, meta state of token)
    //@dev: relies on EIP1066 for Ethereum Standard Codes (ESC) and ERC770 for tranching
    //@returns: ESC (byte), optional specific reason for failure (bytes32), destinantion tranche of the token beeing transfered (bytes32)
    //@notes: EIP1440 proposal
    function canSend(address _from, address _to, bytes32 _tranche, uint256 _amount, bytes _data) external view returns (byte, bytes32, bytes32) {

    }

    //@dev: pays a dividend to all owner of the shares depending on determined percentage of owners portfolio value
    //@note: starts with index 1 in array, as 0 is contract deployer = companyowner in most cases
    //@note: would be also possible with PAYABLE to pay in ether
  function payDividend(uint _txpercentage) public onlyOwnerOfCom() {
    uint _totaldividend;
     for (uint i = 1; i < TotalDistribution.length; i++) {
       uint _temp = _txpercentage.mul(OwnerToBalance[TotalDistribution[i]]);
       _totaldividend = _totaldividend.add(_temp);
     }

    require((OwnerToBalance[msg.sender] >= _totaldividend),"insufficient funding to pay dividend");
      
      for (uint j = 1; j < TotalDistribution.length; j++) {
      uint _txamount = _txpercentage.mul(OwnerToBalance[TotalDistribution[j]]);
      transfer(TotalDistribution[j], _txamount);
    }
   emit Dividend(_txpercentage);
  }

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
//-----TokenTransactions------------------------------------------------------------------------------------------------------------------    





//-----Voting-----------------------------------------------------------------------------------------------------------------------------
    /* This structure allows a company to propose multiple proposals for an issue, voters can than choose one of the proposals 
        - the owning company works as an administrator and can start ballots
        - the number of votes are linked to the amount of shares a voter posseses (1:1)
        - voters can pass their right to vote
        - the winning proposal is calculated and broadcasted automatically
        */

     event votingSuccessful(bytes32 _winnerName, uint _countVotes); 
        
     mapping(address => Voter) AddressToVoter;

      struct Voter {
        uint weight; //@notes: weight is accumulated by # shares
        bool voted;  //@notes: if true, that person already voted
        address delegate; //@notes: person delegates right to vote to
        uint vote;   //@notes: index of the voted proposal
    }

    //@devs: This is a type for a single proposal
    struct Proposal {
        bytes32 name; 
        uint voteCount; // number of accumulated votes
    }
 
    //@notes: all proposals of that company
    Proposal[] public Proposals;

    //@notes: create a new ballot, only possible for owner of company
    function startBallot(bytes32[] proposalNames) public onlyOwnerOfCom() {
          //@dev: push proposal to public array
           for (uint i = 0; i < proposalNames.length; i++) {
                Proposals.push(Proposal({name: proposalNames[i], voteCount: 0
            }));
           }

        //@dev: allocates voting weight = # of shares
        AddressToVoter[msg.sender].weight = OwnerToBalance[msg.sender];
        _giveRightToVote();

    }

    //@dev: give voter the right to vote on this ballot
    //@note: starts with index 1 in array, as 0 is ballot starter = companyowner in most cases
        function _giveRightToVote() internal {
 
        for (uint j = 1; j < TotalDistribution.length; j++) {
                require(AddressToVoter[TotalDistribution[j]].weight == 0, "The right to vote already has been granted");
        AddressToVoter[TotalDistribution[j]].weight = OwnerToBalance[TotalDistribution[j]];
        }
    }

    //@dev: possibility to delegate your vote to another voter
    function delegate(address _to) public {
        
        Voter storage sender = AddressToVoter[msg.sender];
        require(!sender.voted, "You already voted");

        require(_to != msg.sender, "Self-delegation is disallowed");

        //@devs: forwards delegation as long as _to also forwarded his right to vote
        //@security: use careful, as could get looped -> high gas costs
        while (AddressToVoter[_to].delegate != address(0)) {
            _to = AddressToVoter[_to].delegate;

            require(_to != msg.sender, "Found self-delegation loop");
        }

        //@notes: since "sender" is a reference, this modifies AddressToVoter[msg.sender].voted`
        sender.voted = true;
        sender.delegate = _to;
        Voter storage delegate_ = AddressToVoter[_to];
        
        //@notes: if delegate already voted, add sender weight to proposal, else add weight of sender and delegate
        if (delegate_.voted) {
            Proposals[delegate_.vote].voteCount = Proposals[delegate_.vote].voteCount.add(sender.weight);
        } else {
            delegate_.weight.add(sender.weight);
        }
    }

    //@dev: give your vote for specific proposal
    //@security: if proposal is out of range, this will automatically throw and revert changes
    function vote(uint _proposal) public {
        Voter storage sender = AddressToVoter[msg.sender];
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = _proposal;
        
        Proposals[_proposal].voteCount = Proposals[_proposal].voteCount.add(sender.weight);
    }

    //@dev: computes the winning proposal, gets proposal name from array and returns, fires event
    function winningProposal() public onlyOwnerOfCom() returns(bytes32 winnerName_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < Proposals.length; p++) {
            if (Proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = Proposals[p].voteCount;
                uint winningProposal_ = p;
             }
        }

            winnerName_ = Proposals[winningProposal_].name;
            emit votingSuccessful(winnerName_, winningVoteCount);
            return winnerName_;
         
    }

    //@ToAsk: possible to work with memory array?
    //@notes: for EVM could be possible to work with fixed array e.g. 3 proposals
    function getProposals() public returns(bytes32[]){
    bytes32[] storage proposals_;
    for (uint i = 0; i < Proposals.length; i++){
        proposals_.push(bytes32(Proposals[i].name));
    }
    return proposals_;
    }

    function getVoteCount(uint _index) public view returns(uint voteCount_) {
        return voteCount_ = Proposals[_index].voteCount;
    }
//-----Voting-----------------------------------------------------------------------------------------------------------------------------


}