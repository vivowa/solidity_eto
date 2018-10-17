pragma solidity ^0.4.24;

import "./ConvertLib.sol";
import "./SafeMath.sol";
//import "./ERC20.sol";
//import "./ERC777.sol";

contract EquityTokenFactory /* is ERC20Interface, ERC777 Interface */ {

    using SafeMath for uint;

    mapping (address => uint) OwnerToBalance; ///@notice Wallet of tokens and balances of an owner
    mapping (address => uint) AddressToIndex; ///@notice at wich index of distribution array address can be found
    mapping (address => bool) AddressExists; ///@notice required for check if address is already stakeholder, more efficient than iterating array
    mapping (address => mapping (address => uint)) allowed; ///@notice allowance for transfer from _owner to _receiver to withdraw (ERC20 & ERC777)
    
    modifier checkGranularity(uint _amount){
        require((_amount % granular == 0), "unable to modify token balances at this granularity");
        _;
    }
    
    modifier onlyOwnerOfCom() {
        require(msg.sender == companyOwner, "requirement onlyOwner of Company modifier");
        _;
    }


//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------  
      /* This structure allows a company to issue equity via token (quasi-shares) and determines the issuance process
          - the creating company is an administrator and can start various equity related processes (e.g. pay dividend, recapitalize)
          - 
          */


    ///@ToDo indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
    event newTokenIssuance(uint tokenId, bytes32 companyName, address companyOwner);

    ///@notice events for issuance of additional equity (recapitalization) and burning of existing capital
    ///@notice ERC777 mandatory
    event Minted(address operator, address to, uint amount, bytes userData, bytes operatorData);
    event Burned(address operator, address from, uint amount, bytes operatorData);

    ///@ToDo Ownable
    uint public tokenId;
    bytes32 private companyName;
    bytes32 private tokenTicker;
    uint private granular;
    uint private totalAmount;
    address private companyOwner;
    address[2] private defaultOperator;
  
    
    ///@notice the EquityToken
    ///EquityToken public ArtifactEquityToken;
        
    ///@notice array of all owner and amount of one equity token.
    address[] public TotalDistribution;
    
    ///@dev ensures, that tokenId is always 8 digits
    uint internal idModulus = 10 ** 8;

    ///@notice address of government, by default operator of any token
    ///@ToDo declare as 10th
    address public governmentAddress = 0x6b28229f311710b08b6fb3daa6f86a23bd2cbc10;

    ///@dev creates new token shell, creates unique id, safes information in storage
    ///@dev granularity ensures, that granularity of shares is always a positive natural figure, cannot be changed ever
    constructor(bytes32 _companyName, bytes32 _tokenTicker, uint _granularity) public {
        tokenId = _generateRandomTokenId(_companyName);
        companyName = _companyName;
        tokenTicker = _tokenTicker;
        totalAmount = 0;
        require((_granularity >= 1), "granularity has to be greater or equal 1");
        _granularity = _granularity;
        erc20compatible = true;
        companyOwner = msg.sender;
        defaultOperator = [msg.sender, governmentAddress];

        _toShareholderbook(msg.sender);

        emit newTokenIssuance(tokenId, companyName, msg.sender);

    ///setInterfaceImplementation("ERC20Token", this);
    ///setInterfaceImplementation("ERC777Token", this);
    }

  
    ///@notice process to mint new equity 
    function mint(address _companyOwner, uint _amount, bytes _userData, bytes _operatorData) public checkGranularity(_amount) onlyOwnerOfCom {
    ///@ToDo Approval Process (require)
        totalAmount = totalAmount.add(_amount);
        OwnerToBalance[_companyOwner] = OwnerToBalance[_companyOwner].add(_amount);
  
        emit Minted(msg.sender, _companyOwner, _amount, _userData, _operatorData);
        if (erc20compatible) {emit Transfer(0x0, _companyOwner, _amount);}
    }

    ///@notice process to burn equity
    function burn(address _companyOwner, uint _amount, bytes _operatorData) public checkGranularity(_amount) onlyOwnerOfCom {
        require((balanceOf(_companyOwner) >= _amount), "not enough funding to burn");
        ///@ToDo Approval Process (require)
        totalAmount = totalAmount.sub(_amount);
        OwnerToBalance[_companyOwner] = OwnerToBalance[_companyOwner].sub(_amount);
        
        emit Burned(msg.sender, _companyOwner, _amount, _operatorData);
        if (erc20compatible) {
            emit Transfer(_companyOwner, 0x0, _amount);}
    }

  

    ///@dev generates an unique 8 digit tokenId by hashing string and a nonce
    function _generateRandomTokenId(bytes32 _companyName) private view returns(uint) {
        uint randNonce = 0;
        uint random = uint(keccak256(abi.encodePacked(_companyName, randNonce)));
        randNonce.add(1);
        return random % idModulus;
    }

    ///@dev manage documents associated with token
    ///@notice ERC 1440 proposal
    function getDocument(bytes32 _name) external view returns(string, bytes32){

    }
  
    ///@dev manage documents associated with token
    ///@notice ERC 1440 proposal
    function setDocument(bytes32 _name, string _uir, bytes32 _documentHash) external {

    }

//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------


//-----EquityToken------------------------------------------------------------------------------------------------------------------------
    /* This structure determines the business logic of a token (i.e. quasi-share)
        - 
        */

    ///@dev adjustments and new length of shareholder book
    event newShareholder(address newShareholder, uint length);

    ///@notice string as bytes32 only has space for 32 characters
    event adHocMessage(string _message, address _company);
    ///@ToDo automatic quarterly update
    ///event quaterlyUpdate(uint _revenue, uint _revenueforecast);

    ///@notice ERC20 optional, ERC777 mandatory
    function name() public view returns(bytes32) {
        return companyName;
    }

    ///@notice ERC20 optional, ERC777 mandatory
    function symbol() public view returns(bytes32) {
        return tokenTicker;
    }

    ///@dev smallest part of token not divisible
    ///@notice ERC777 mandatory
    function granularity() public view returns(uint) {
        return granular;
    }

    function getBalanceOfInEth(address _addr) public view returns(uint) {
		    return ConvertLib.convert(balanceOf(_addr), 3);
    }

    ///@dev balance for any owner
    ///@notice ERC20 mandatory, ERC777 mandatory
    function balanceOf(address _addr) public view returns(uint) {
		    return OwnerToBalance[_addr];
	  }

    ///@ToDo totalSupply = sum all balances
    ///@dev total amount of a token 
    ///@notice ERC20 mandatory, ERC777 mandatory
    function totalSupply() public view returns(uint) {
        return totalAmount;
    }
    
    ///@dev returns Infos of equity token, as struct is not returnable in current solidity version
    function getInfosEquityToken() public view returns(uint, bytes32, bytes32, uint, uint) {
        return (tokenId, companyName, tokenTicker, granular, totalAmount);
    } 

    ///@dev iternal function to push new address to shareholder book, checks if address exists first
    function _toShareholderbook(address _addr) internal returns(bool success_) {
        if (_checkExistence(_addr)) return false;

    ///ToDo index necessary
        uint DistributionIndex = TotalDistribution.push(address(_addr)) - 1;
        AddressToIndex[_addr] = DistributionIndex;
        AddressExists[_addr] = true;

        emit newShareholder(_addr, TotalDistribution.length);
        return true;
    }

    ///@dev checks existence of address in shareholder book by using mapping (address => bool)
    function _checkExistence(address _addr) internal view returns(bool success_) {
        return AddressExists[_addr];
    }

    
    ///@dev getter for TotalDistribution array
    ///@return array with all addresses (owner)
    function getAllAddressesEquityToken() public view returns(address[]) {
        return TotalDistribution;
    }

    function getCompanyOwner() public view returns(address) {
        return companyOwner;
    }

    function setCompanyOwner(address _addr) public onlyOwnerOfCom {
        companyOwner = _addr;
    }
  

    ///@dev possible to broadcast adHocMessages for any size
    function sendAdHocMessage(string _message) public onlyOwnerOfCom {
        emit adHocMessage(_message, msg.sender);
    }
//-----EquityToken------------------------------------------------------------------------------------------------------------------------



//-----TokenTransactions------------------------------------------------------------------------------------------------------------------
  /* This section determines transaction protocolls of the issued equity token
        - 
        -
        */  

    ///@dev fires an event after percentage of dividend is determined and transfered    
    event Dividend(uint _txpercentage);

    ///@notice fires event of after regular token transfer defined by ERC777
    event Sent(address operator, address from, address to, uint amount, bytes data, bytes operatorData);

    ///@notice function actually performing the sending of tokens.
    ///@param _userData Data generated by the user to be passed to the recipient
    ///@param _operatorData Data generated by the operator to be passed to the recipient
    ///@param _preventLocking true if you want this function to throw when tokens are sent to or sent by a contract not implementing ERC777.
    /// ERC777 native Send functions MUST set this parameter to true, and backwards compatible ERC20 transfer functions SHOULD set this parameter to false.
    /// In this testing environment _preventLocking is by default true to maintain interoperability, but addresses are NEVER checked, 
    /// stick to official ERC777 for further information and implementation of this feature.
    function doSend(address _from, address _to, uint _txamount, bytes _userData, address _operator, bytes _operatorData, bool _preventLocking) 
    private checkGranularity(_txamount) {
        require((_to != address(0)), "_to address does not exist or is 0x0 (burning)");          
        require((OwnerToBalance[_from] >= _txamount), "not enough funding for transaction on account");

        OwnerToBalance[_from] = OwnerToBalance[_from].sub(_txamount);
        OwnerToBalance[_to] = OwnerToBalance[_to].add(_txamount);
        _toShareholderbook(_to);

        emit Sent(_operator, _from, _to, _txamount, _userData, _operatorData);
        if (erc20compatible) {
            emit Transfer(_from, _to, _txamount);}
    }
    
    ///@notice native ERC777 send function
    function send(address _to, uint _txamount) public {
        doSend(msg.sender, _to, _txamount, "", msg.sender, "", true);
    }
    function send(address _to, uint _txamount, bytes _userData) public {
        doSend(msg.sender, _to, _txamount, _userData, msg.sender, "", true);
    }
  
    ///@notice Send _amount of tokens on behalf of the address _from to the address _to.
    ///@param _userData Data generated by the user to be sent to the recipient
    ///@param _operatorData Data generated by the operator to be sent to the recipient
    ///@notice ERC77 mandatory
    function operatorSend(address _from, address _to, uint _amount, bytes _userData, bytes _operatorData) public {
        require((isOperatorFor(msg.sender, _from)), "sender is not authorized to operate with _from's account");
        doSend(_from, _to, _amount, _userData, msg.sender, _operatorData, true);
    }

    ///@dev transfers of security might fail to multiple reasons (e.g. identity of sender and receiver, trading limits, meta state of token)
    ///@dev relies on EIP1066 for Ethereum Standard Codes (ESC) and ERC770 for tranching
    ///@return ESC (byte), optional specific reason for failure (bytes32), destinantion tranche of the token beeing transfered (bytes32)
    ///@notice EIP1440 proposal
    function canSend(address _from, address _to, bytes32 _tranche, uint _amount, bytes _data) external view returns (byte, bytes32, bytes32) {

    }

    ///@dev pays a dividend to all owner of the shares depending on determined percentage of owners portfolio value
    ///@notice starts with index 1 in array, as 0 is contract deployer = companyowner in most cases
    ///@notice would be also possible with PAYABLE to pay in ether
    function payDividend(uint _txpercentage) public onlyOwnerOfCom {
        uint _totaldividend;
        for (uint i = 1; i < TotalDistribution.length; i++) {
            uint _temp = _txpercentage.mul(OwnerToBalance[TotalDistribution[i]]);
            _totaldividend = _totaldividend.add(_temp);
        }
        require((OwnerToBalance[msg.sender] >= _totaldividend), "insufficient funding to pay dividend");
        for (uint j = 1; j < TotalDistribution.length; j++) {
            uint _txamount = _txpercentage.mul(OwnerToBalance[TotalDistribution[j]]);
            transfer(TotalDistribution[j], _txamount);
        }
        emit Dividend(_txpercentage);
    }

    ///@notice check whether an address is a regular address or not. Suppress warning by "// solhint-disable-line no-inline-assembly"
    function isRegularAddress(address _addr) internal view returns(bool) {
        if (_addr == 0) { 
            return false; }
        uint size;
        assembly { size := extcodesize(_addr) }
        return size == 0;
    }


    uint private LockupPeriod = 1 years;
    
    /* modifier timelock() {
        require(now >= block.timestamp.add(LockupPeriod));
        _;
    }*/
    
    function _isReady() internal view returns(bool) {
        return (now >= block.timestamp.add(LockupPeriod));
    }

    function setLockup(uint adjustedLockup) public onlyOwnerOfCom {
        LockupPeriod = adjustedLockup;
    }
//-----TokenTransactions------------------------------------------------------------------------------------------------------------------    

//-----TokenGovernance-------------------------------------------------------------------------------------------------------------------- 
    ///@notice fires event if authorization of operator for an address
    ///@notice ERC777 mandatory
    event AuthorizedOperator(address operator, address tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    mapping(address => mapping(address => bool)) private mAuthorized;

    ///@notice ERC777 mandatory
    function defaultOperators() public view returns(address[2]) {
        return defaultOperator;
    }

    ///@notice Authorize a third party _operator to manage (send) msg.sender's tokens. msg.sender always operator himself, thus requirement
    ///@notice ERC777 mandatory
    function authorizeOperator(address _operator) public {
        require((_operator != msg.sender), "msg.sender cannot authorized himself");
        mAuthorized[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    ///@notice Revoke a third party _operator's rights to manage (send) msg.sender's tokens.
    ///@notice ERC777 mandatory
    function revokeOperator(address _operator) public {
        require((_operator != msg.sender), "msg.sender cannot revoke himself");
        mAuthorized[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    ///@notice Check whether the _operator address is allowed to manage the tokens held by _tokenHolder address.
    ///@return true if _operator is authorized for _tokenHolder
    ///@notice ERC777 mandatory
    function isOperatorFor(address _operator, address _tokenHolder) public view returns(bool) {
        return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
    }

//-----TokenGovernance-------------------------------------------------------------------------------------------------------------------- 



//-----Voting-----------------------------------------------------------------------------------------------------------------------------
    /* This structure allows a company to propose multiple proposals for an issue, voters can than choose one of the proposals 
        - the owning company works as an administrator and can start ballots
        - the number of votes are linked to the amount of shares a voter posseses (1:1)
        - voters can pass their right to vote
        - the winning proposal is calculated and broadcasted automatically
        */

    event votingSuccessful(bytes32 winnerName, uint countVotes); 
        
    mapping(address => Voter) AddressToVoter;

    struct Voter {
        uint weight; ///@notice weight is accumulated by # shares
        bool voted;  ///@notice if true, that person already voted
        address delegate; ///@notice person delegates right to vote to
        uint vote;   ///@notice index of the voted proposal
    }

    ///@dev this is a type for a single proposal
    struct Proposal {
        bytes32 name; 
        uint voteCount; // number of accumulated votes
    }
 
    ///@notice all proposals of that company
    Proposal[] public Proposals;

    ///@notice create a new ballot, only possible for owner of company
    function startBallot(bytes32[] proposalNames) public onlyOwnerOfCom {
        for (uint i = 0; i < proposalNames.length; i++) {
            Proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }

        ///@dev allocates voting weight = # of shares
        AddressToVoter[msg.sender].weight = OwnerToBalance[msg.sender];
        _giveRightToVote();
    }

    ///@dev give voter the right to vote on this ballot
    ///@notice starts with index 1 in array, as 0 is ballot starter = companyowner in most cases
    function _giveRightToVote() internal {
        for (uint j = 1; j < TotalDistribution.length; j++) {
            require(AddressToVoter[TotalDistribution[j]].weight == 0, "The right to vote already has been granted");
            AddressToVoter[TotalDistribution[j]].weight = OwnerToBalance[TotalDistribution[j]];
        }
    }

    ///@dev possibility to delegate your vote to another voter
    function delegate(address _to) public {
        Voter storage sender = AddressToVoter[msg.sender];
        require(!sender.voted, "You already voted");
        require(_to != msg.sender, "Self-delegation is disallowed");
        ///@dev forwards delegation as long as _to also forwarded his right to vote
        ///@security use careful, as could get looped -> high gas costs
        while (AddressToVoter[_to].delegate != address(0)) {
            _to = AddressToVoter[_to].delegate;

            require(_to != msg.sender, "Found self-delegation loop");
        }

        ///@notice since "sender" is a reference, this modifies AddressToVoter[msg.sender].voted
        sender.voted = true;
        sender.delegate = _to;
        Voter storage delegate_ = AddressToVoter[_to];
        
        ///@notice if delegate already voted, add sender weight to proposal, else add weight of sender and delegate
        if (delegate_.voted) {
            Proposals[delegate_.vote].voteCount = Proposals[delegate_.vote].voteCount.add(sender.weight);
        } else {
            delegate_.weight.add(sender.weight);
        }
    }

    ///@dev give your vote for specific proposal
    ///@security if proposal is out of range, this will automatically throw and revert changes
    function vote(uint _proposal) public {
        Voter storage sender = AddressToVoter[msg.sender];
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = _proposal;
        
        Proposals[_proposal].voteCount = Proposals[_proposal].voteCount.add(sender.weight);
    }

    ///@dev computes the winning proposal, gets proposal name from array and returns, fires event
    function winningProposal() public onlyOwnerOfCom returns(bytes32 winnerName_) {
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

    ///@ToAsk possible to work with memory array?
    ///@notice for EVM could be possible to work with fixed array e.g. 3 proposals
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




//-----ERC20BackwardCompatibility---------------------------------------------------------------------------------------------------------
    /* This section determines obsolete erc20 methods that are only implemented to maintain backwards compatibility.
       Further erc20 compatibility can be disabled, then the methods will fail 
        - 
        */


    ///@ToDo indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
    ///@notice ERC20 mandatory
    event Transfer(address _from, address _to, uint _txamount);
    event Approval(address _from, address _to, uint _txamount);

    modifier erc20() {
        require((erc20compatible), "erc20 compatibility has been disabled");
        _;
    }

    bool private erc20compatible;

    ///@notice disables the ERC20 interface. 
    function disableERC20() public onlyOwnerOfCom {
        erc20compatible = false;
        //setInterfaceImplementation("ERC20Token", 0x0);
    }

    ///@notice enables the ERC20 interface.
    function enableERC20() public onlyOwnerOfCom {
        erc20compatible = true;
        //setInterfaceImplementation("ERC20Token", this);
    }

    ///@dev number of decimals token uses, divide token amount by number of decimals to get user representation
    ///@notice ERC20 optional, ERC777 mandatory to be 18
    function decimals() public view erc20 returns(uint8) { 
        return uint8(18);
    }

    ///@dev transfers token from A to B and fires event, additionally updates the TotalDistribution array (shareholder book)
    ///@notice ERC20 mandatory
    function transfer(address _to, uint _txamount) public erc20 returns(bool success_) {
        doSend(msg.sender, _to, _txamount, "", msg.sender, "", false);
        return true;
    }

    ///@dev transfers token from A to B and fires event, additionally updates the TotalDistribution array (shareholder book); transferFrom should be used for withdrawing workflow
    ///@notice ERC20 mandatory
    function transferFrom(address _from, address _to, uint _txamount) public erc20 returns(bool success_) {
        require((_txamount <= allowed[_from][msg.sender]), "no approval for transaction");

        ///@security cannot be after doSend because of tokensReceived re-entry
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_txamount);
        doSend(_from, _to, _txamount, "", msg.sender, "", false);
        return true;
    }

    ///@dev sender can approve an amount to be withdrawn by spender
    ///@notice ERC20 mandatory
    function approve(address _spender, uint _txamount) public checkGranularity(_txamount) erc20 returns(bool success_) {
        allowed[msg.sender][_spender] = _txamount;
        emit Approval(msg.sender, _spender, _txamount);
        return true;
    }
  
    ///@notice ERC20 mandatory
    function allowance(address _owner, address _spender) public view erc20 returns(uint remaining) {
        return allowed[_owner][_spender];
    }

  //-----ERC20BackwardCompatibility---------------------------------------------------------------------------------------------------------    

}