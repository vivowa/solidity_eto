pragma solidity ^0.4.24;

import "./ConvertLib.sol";
import "./SafeMath.sol";
//import "./ERC20.sol";
//import "./ERC777.sol";
//import "./EIP1410.sol";
//import "./EIP1400.sol";

contract EquityTokenFactory /* is ERC20Interface, ERC777Interface, EIP1410Interface, EIP1400Interface */ {

    using SafeMath for uint;

    mapping (address => uint) OwnerToBalance; ///@notice wallet of tokens and balances of an owner
    mapping (address => mapping (uint => uint)) OwnerToTrancheToBalance; ///@notice wallet of tokens and balances of an owner depending on tranche
    mapping (address => uint[]) OwnerToTranches; ///@notice tranches array of an owner
    mapping (uint => TranchesMetaData) IdToMetaData; ///@notice mapping of metadata belonging to a token tranche
    mapping (address => bool) AddressExists; ///@notice required for check if address is already stakeholder, more efficient than iterating array
    mapping (address => mapping (address => uint)) allowed; ///@notice allowance for transfer from _owner to _receiver to withdraw (ERC20 & ERC777)

    mapping (address => uint) LevelOfAccreditation; ///@notice maps an address if it passed KYC protocol; 0 = not accredited, 1 = investor, 2 = advocate)
    
    modifier checkGranularity(uint _amount){
        require((_amount % granular == 0), "unable to modify token balances at this granularity");
        _;
    }
    
    modifier onlyOwnerOfCom() {
        require(msg.sender == companyOwner, "requirement onlyOwner of Company modifier");
        _;
    }

    modifier onlyOwner(address _from) {
        require((msg.sender == _from), "requirement onlyOwner");
        _;
    }

    modifier checkAccreditation(address _to) {
        require((LevelOfAccreditation[_to] == 1),"requirement of successful KYC protocol");
        _;
    }


//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------  
      /* This structure allows a company to issue equity via token (quasi-shares) and determines the issuance process
          - the creating company is an administrator and can start various equity related processes (e.g. pay dividend, recapitalize, ...)
          - in general the contracts tracks and calculates two seperate balances, first the overall balance of a token holder and second
            the tranche-specific balance of a token holder (e.g. if minting, sending, burning tokens)
          - ERC20 is a de facto standard for trading of tokens
          - ERC777 introduces operators (higher level administration), in order to e.g prepare for governmental control
          - EIP1410 proposes tranching of a token (partial fungible tokens)
          - EIP1400 proposes in-depth token management (e.g. transfer restrictions and regulation)
          */


    //@ToDo indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
    event newTokenIssuance(bytes32 companyName, bytes32 tokenTicker, address companyOwner);

    ///@notice events for issuance of additional equity (recapitalization) and burning of existing capital
    ///@notice ERC777 and EIP1410 mandatory
    event Minted(address operator, address to, uint amount, bytes userData, bytes operatorData);
    event Burned(address operator, address from, uint amount, bytes operatorData);
    event MintedByTranche(uint trancheId, address operator, address to, uint amount, bytes userData, bytes operatorData);
    event BurnedByTranche(uint trancheId, address operator, address from, uint amount, bytes operatorData);

    ///@notice the core data of a issued token
    ///@param granular for explanation see constructor
    ///@param defaultOperator every token has two higher level administrators by default -> issuing company and government; can be changed
    bytes32 private companyName;
    bytes32 private tokenTicker;
    uint private granular;
    uint private totalAmount;
    address private companyOwner;
    address[2] private defaultOperator;
  
    ///@notice array of all owner of one equity token, thus the shareholder book
    address[] public TotalDistribution;

    ///@notice array of all tranches of one equity token and struct with metadata of every tranche.
    uint[] public AllTranches;
    struct TranchesMetaData {
        uint trancheAmount;
        byte categoryShare;
        uint mintedTimeStamp;
        uint regulationMaximumInvestors;
        uint regulationMaximumSharesPerInvestor;
    }

    ///@notice token issuer can specify to stop token issuance, cannot be reverted
    bool public isIssuable = true;
    
    ///@dev declares a random nonce which increases every time random number generator is used
    ///@dev ensures, that randomId is always 8 digits
    uint internal randNonce = 0;
    uint internal idModulus = 10 ** 8;

    ///@dev solidity declares a variable by default to 0, thus in the test environment we have to simulate regulation requirements
    uint internal regulationMaxInvest = 10 ** 4;
    uint internal regulationMaxSharesPInvest = 10 ** 6;

    ///@notice address of government, by default operator of any token; can be changed by companyOwner
    address public governmentAddress;

    ///@notice fee in order to get KYC/AML process
    uint public accreditationFee = 1 ether;

    ///@dev creates new token shell, safes information in storage
    ///@param _granularity ensures, that granularity of shares is always a positive natural figure, cannot be changed ever
    function createToken(bytes32 _companyName, bytes32 _tokenTicker, uint _granularity) public {
        companyName = _companyName;
        tokenTicker = _tokenTicker;
        totalAmount = 0;
        assert(_granularity >= 1); // "granularity has to be greater or equal 1"
        granular = _granularity;
        erc20compatible = true;
        companyOwner = msg.sender;
        defaultOperator = [msg.sender, governmentAddress];

        _toShareholderbook(msg.sender);

        emit newTokenIssuance(companyName, tokenTicker, msg.sender);
    }
  
    ///@notice process to mint new equity
    ///@notice compliant with ERC777 & EIP1410
    function mint(address _companyOwner, uint _amount, bytes _userData, bytes _operatorData) public checkGranularity(_amount) onlyOwnerOfCom {
    require((isIssuable == true), "token issuance is finished");
   
        ///@notice creates random Id for new tranche of equity, stores only Id in array and metadata in metadata struct
        uint trancheId = _generateRandomId(companyName);
        AllTranches.push(uint(trancheId));
        IdToMetaData[trancheId] = (TranchesMetaData(_amount, "A", block.timestamp, regulationMaxInvest, regulationMaxSharesPInvest));

        ///@notice increase balance in two ways, first overall balance of owner, second tranche-specific balanche of owner
        totalAmount = totalAmount.add(_amount);
        OwnerToBalance[_companyOwner] = OwnerToBalance[_companyOwner].add(_amount);
        OwnerToTrancheToBalance[_companyOwner][trancheId] = OwnerToTrancheToBalance[_companyOwner][trancheId].add(_amount);

        OwnerToTranches[_companyOwner].push(uint(trancheId));

        emit Minted(msg.sender, _companyOwner, _amount, _userData, _operatorData);
        emit MintedByTranche(trancheId, msg.sender, _companyOwner, _amount, _userData, _operatorData);
        if (erc20compatible) {emit Transfer(0x0, _companyOwner, _amount);}
    }
        
    ///@notice process to burn equity
    ///@notice _burn function can be used by Company AND private token holder, burn is a shell and important to fullfil onlyOwner requirement
    ///@notice compliant with ERC777 & EIP1410
    function burn(address _from, uint _amount, bytes _operatorData) public onlyOwner(_from) {
        _burn(_from, _amount, _operatorData);
    }
    function _burn(address _from, uint _amount, bytes _operatorData) private checkGranularity(_amount) {
        require((OwnerToBalance[_from] >= _amount), "not enough funding to burn");
        
        uint burnedAmount = 0;
        uint counter = 1;

        ///@dev this loop and its break requirement is either fullfiled if a single tranche balance is > _amount, or the sum of different tranche balances > _amount
        ///@dev if not otherwise stated all functions use the latest tranche first to send/burn tokens (First In First Out), this can be changed in detail by owners
        while(burnedAmount < _amount) {
            uint trancheId = AllTranches[AllTranches.length - counter];
                
            if(OwnerToTrancheToBalance[_from][trancheId] >= _amount.sub(burnedAmount)) {
                totalAmount = totalAmount.sub((_amount.sub(burnedAmount)));
                OwnerToBalance[_from] = OwnerToBalance[_from].sub((_amount.sub(burnedAmount)));
                OwnerToTrancheToBalance[_from][trancheId].sub((_amount.sub(burnedAmount)));
                emit BurnedByTranche(trancheId, msg.sender, _from, _amount, _operatorData);
                break;
            }
            else {
                uint burnTx = OwnerToTrancheToBalance[_from][trancheId];
                totalAmount = totalAmount.sub(burnTx);
                OwnerToBalance[_from] = OwnerToBalance[_from].sub(burnTx);
                OwnerToTrancheToBalance[_from][trancheId].sub(burnTx);

                burnedAmount = burnedAmount.add(burnTx);
                counter = counter.add(1);
                emit BurnedByTranche(trancheId, msg.sender, _from, _amount, _operatorData);
            }
        }
        emit Burned(msg.sender, _from, _amount, _operatorData);
        if (erc20compatible) {emit Transfer(_from, address(0x0), _amount);}
    }

    ///@notice burn function can be used by Company AND private token holder, important to fullfil onlyOwner requirement
    function burnByTranche(uint _trancheId, address _from, uint _amount, bytes _operatorData) public onlyOwner(_from) {
        _burnByTranche(_trancheId, _from, _amount, _operatorData);
    }
    function _burnByTranche(uint _trancheId, address _from, uint _amount, bytes _operatorData) private checkGranularity(_amount) {
        require((OwnerToTrancheToBalance[_from][_trancheId] >= _amount), "not enough tranche-specific funding to burn");
                
                totalAmount = totalAmount.sub(_amount);
                OwnerToBalance[_from] = OwnerToBalance[_from].sub(_amount);
                OwnerToTrancheToBalance[_from][_trancheId].sub(_amount);

                emit BurnedByTranche(_trancheId, msg.sender, _from, _amount, _operatorData);
                emit Burned(msg.sender, _from, _amount, _operatorData);
                if (erc20compatible) {emit Transfer(_from, address(0x0), _amount);}
    }

    ///@notice ERC777 mandatory
    function operatorBurn(address _from, uint _amount, bytes _operatorData) public {
        require((isOperatorFor(msg.sender, _from)), "sender is not authorized to operate with _from's account");
        _burn(_from, _amount, _operatorData);
    }

    ///@notice EIP1400 mandatory
    function operatorBurnByTranche(uint _trancheId, address _from, uint _amount, bytes _operatorData) public {
        require((isOperatorFor(msg.sender, _from)), "sender is not authorized to operate with _from's account");
        _burnByTranche(_trancheId, _from, _amount, _operatorData);
    }

    ///@dev generates an unique 8 digit tokenId by hashing string and a nonce
    function _generateRandomId(bytes32 _companyName) private view returns(uint) {
        uint random = uint(keccak256(abi.encodePacked(_companyName, randNonce)));
        randNonce.add(1);
        return random % idModulus;
    }

    /*
    ///@dev manage documents associated with token
    ///@notice EIP1400 proposal
    function setDocument(bytes32 _name, string _url, bytes32 _documentHash) external {

    }
    function getDocument(bytes32 _name) external view returns(string, bytes32){
        return (url_, documentHash_);
    }
    */

//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------


//-----EquityToken------------------------------------------------------------------------------------------------------------------------
    /* This structure determines the business logic of a token (i.e. quasi-share)
        - 
        */

    ///@dev adjustments and new length of shareholder book
    event newShareholder(address newShareholder, uint length);

    ///@notice string as bytes32 only has space for 32 characters
    event adHocMessage(string _message, address _company);
    //////////////////////////////////ToDo automatic quarterly update
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

    ///@notice convert balance of token in ETH or other currencies
    function getBalanceOfInEth(address _addr) public view returns(uint) {
		return ConvertLib.convert(balanceOf(_addr), 3);
    }

    ///@dev balance for any owner
    ///@notice ERC20 mandatory, ERC777 mandatory
    function balanceOf(address _addr) public view returns(uint) {
		return OwnerToBalance[_addr];
	}

    ///@dev balance for any owner for specific tranche
    ///@notice EIP1410 proposal
    function balanceOfByTranche(address _addr, uint _tranche) public view returns(uint) {
		return OwnerToTrancheToBalance[_addr][_tranche];
	}

    
    ///@dev tranches of a tokenholder
    ///@notice EIP1410 proposal
    function tranchesOf(address _addr) public view returns(uint[]) {
        return OwnerToTranches[_addr];
    }

    ///@dev total amount of a token 
    ///@notice ERC20 mandatory, ERC777 mandatory
    function totalSupply() public view returns(uint) {
        return totalAmount;
    }
    
    ///@dev returns Infos of equity token, as struct is not returnable in current solidity version
    function getInfosEquityToken() public view returns(bytes32, bytes32, uint, uint, uint[]) {
        return (companyName, tokenTicker, granular, totalAmount, AllTranches);
    } 

    ///@dev iternal function to push new address to shareholder book, checks if address exists first
    function _toShareholderbook(address _addr) private returns(bool success_) {
        if (_checkExistence(_addr)) return false;

        TotalDistribution.push(address(_addr));
        AddressExists[_addr] = true;

        emit newShareholder(_addr, TotalDistribution.length);
        return true;
    }

    ///@dev checks existence of address in shareholder book by using mapping (address => bool)
    function _checkExistence(address _addr) private view returns(bool success_) {
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
  

    ///@dev possibiliy to broadcast adHocMessages for any size
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
    private checkGranularity(_txamount) checkAccreditation(_to) returns(bool success_) {
        require((_to != address(0x0)), "_to address does not exist or is 0x0 (burning)");
        require((OwnerToBalance[_from] >= _txamount), "not enough general funding for transaction on account");         
        require((OwnerToTrancheToBalance[_from][_trancheId] >= _txamount), "not enough tranche-specific funding for transaction on account");

        OwnerToBalance[_from] = OwnerToBalance[_from].sub(_txamount);
        OwnerToBalance[_to] = OwnerToBalance[_to].add(_txamount);
        _toShareholderbook(_to);
        emit Sent(_operator, _from, _to, _txamount, _userData, _operatorData);

        OwnerToTrancheToBalance[_from][_trancheId] = OwnerToTrancheToBalance[_from][_trancheId].sub(_txamount);
        OwnerToTrancheToBalance[_to][_trancheId] = OwnerToTrancheToBalance[_to][_trancheId].add(_txamount);
        OwnerToTranches[_to].push(uint(_trancheId));
        emit SentByTranche(_trancheId, _operator, _from, _to, _txamount, _userData, _operatorData);
                
        if (erc20compatible) {
            emit Transfer(_from, _to, _txamount);}

        return true;
    }

    ///@notice private send function used if no tranche is initially defined, then uses default tranche
    function _doSend(address _from, address _to, uint _txamount, bytes _userData, address _operator, bytes _operatorData) 
    private {
        uint[] memory SenderTranches = getDefaultTranches(_from);
        uint sentAmount = 0;
        uint counter = 1;
        
        while(sentAmount < _txamount) {
            uint trancheId = SenderTranches[SenderTranches.length - counter];
                
            if(OwnerToTrancheToBalance[_from][trancheId] >= _txamount.sub(sentAmount)) {
                _doSend(trancheId, _from, _to, _txamount.sub(sentAmount), _userData, _operator, _operatorData);
                break;
            }
            else {
                uint sentTx = OwnerToTrancheToBalance[_from][trancheId];
                _doSend(trancheId, _from, _to, sentTx, _userData, _operator, _operatorData);
                sentAmount = sentAmount.add(sentTx);
                counter = counter.add(1);
            }
        } 
    }
    
    ///@notice native ERC777 send function
    function send(address _to, uint _txamount) public {
        _doSend(msg.sender, _to, _txamount, "", msg.sender, "");
    }
    function send(address _to, uint _txamount, bytes _userData) public {
        _doSend(msg.sender, _to, _txamount, _userData, msg.sender, "");
    }
  
    ///@notice Send _amount of tokens on behalf of the address _from to the address _to.
    ///@param _userData Data generated by the user to be sent to the recipient
    ///@param _operatorData Data generated by the operator to be sent to the recipient
    ///@notice ERC777 mandatory
    function operatorSend(address _from, address _to, uint _txamount, bytes _userData, bytes _operatorData) public {
        require((isOperatorFor(msg.sender, _from)), "sender is not authorized to operate with _from's account");
        _doSend(_from, _to, _txamount, _userData, msg.sender, _operatorData);
    }

    ///@return (NOT IN SCOPE) returning a trancheId allows to further distinct equity-tranches into sub-tranches by token holder
    /// this enables token governance on company AND on token holder level (sub-tranches)
    ///@notice native EIP1410 send function
    function sendByTranche(uint _trancheId, address _to, uint _txamount) external returns(uint) {
        _doSend(_trancheId, msg.sender, _to, _txamount, "", msg.sender, "");
        return _trancheId;
    }
    function sendByTranche(uint _trancheId, address _to, uint _txamount, bytes _userData) external returns(uint) {
        _doSend(_trancheId, msg.sender, _to, _txamount, _userData, msg.sender, "");
        return _trancheId;
    }

    ///@notice Send _amount of tokens on behalf of the address _from to the address _to
    ///@notice EIP1410 mandatory for backward interoperability with ERC777
    function operatorSendByTranche(uint _trancheId, address _from, address _to, uint _txamount, bytes _userData, bytes _operatorData) external returns(uint) {
        require((isOperatorFor(msg.sender, _from)), "sender is not authorized to operate with _from's account");
        _doSend(_trancheId, _from, _to, _txamount, _userData, msg.sender, _operatorData);
        return _trancheId;
    }

    ///@notice gets the tranches of a token holder, in general the default tranche for a transaction is the latest issued tranche an owner posseses
    ///@dev mandatory for backward interoperability with ERC777 and ERC20
    function getDefaultTranches(address _from) public view returns(uint[]) {
        return tranchesOf(_from);
    }

    ///@dev transfers of security might fail to multiple reasons (e.g. identity of sender and receiver, trading limits, meta state of token)
    ///@dev relies on EIP1066 for Ethereum Standard Codes (ESC) and ERC770 for tranching
    ///@dev only possible to read error code of 'doSend -> require' statement with assembly { call } for more elaborated error messages (see Ethereum documentation)
    ///@return ESC (byte), optional specific reason for failure (bytes32), (NOT IMPLEMENTED) destinantion tranche of the token beeing transfered (uint)
    ///@notice EIP1400 proposal
    function canSend(uint _trancheId, address _from, address _to, uint _txamount, bytes _userData) external returns(byte, bytes32, uint) {
        if (_doSend(_trancheId, _from, _to, _txamount, _userData, msg.sender, "")) {
        return (hex"01", "success", _trancheId); }
        else {
        return (hex"00", "failure", _trancheId); }
    }

    ///@dev pays a dividend to all owner of the shares depending on determined percentage of owners portfolio value
    ///@notice starts with index 1 in array, as 0 is contract deployer = companyowner in most cases
    ///@notice would be also possible with PAYABLE to pay in ether
    ///@notice uses default tranches to pay for dividend
    function payDividend(uint _txpercentage) external onlyOwnerOfCom {
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
    function _isRegularAddress(address _addr) private view returns(bool) {
        if (_addr == 0x0) { 
            return false; }
        uint size;
        assembly { size := extcodesize(_addr) }
        return size == 0;
    }


    uint private LockupPeriod = 365 days;
    
    /* modifier timelock() {
        require(block.timestamp >= block.timestamp.add(LockupPeriod));
        _;
    }*/
    
    function _isReady() internal view returns(bool) {
        return (block.timestamp >= block.timestamp.add(LockupPeriod));
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

    ///@notice authorize a third party _operator to manage (send) msg.sender's tokens. msg.sender always operator himself, thus requirement
    ///@notice ERC777 mandatory
    function authorizeOperator(address _operator) public {
        require((_operator != msg.sender), "msg.sender cannot authorized himself");
        mAuthorized[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    ///@notice revoke a third party _operator's rights to manage (send) msg.sender's tokens.
    ///@notice ERC777 mandatory, EIP1400 & EIP1410 in discussion
    ///@notice it may be that regulations require an issuer or a trusted third party to retain the power thus it can be that revoking an operator
    /// MUST NOT be allowed
    function revokeOperator(address _operator) public {
        require((_operator != msg.sender), "msg.sender cannot revoke himself");
        mAuthorized[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    ///@notice check whether the _operator address is allowed to manage the tokens held by _tokenHolder address.
    ///@return true if _operator is authorized for _tokenHolder
    ///@notice ERC777 mandatory
    function isOperatorFor(address _operator, address _tokenHolder) public view returns(bool) {
        return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
    }

    function setGovernmentAddress(address _addr) external onlyOwnerOfCom {
        require((_addr != address(0x0)), "_addr address does not exist or is 0x0 (burning)");
        governmentAddress = _addr;
    }

    ///@notice owner can stop issuance, not revertable!
    ///@notice EIP1400 mandatory
    function stopIssuance() external onlyOwnerOfCom {
        isIssuable = false;
    }

    ///@notice provides transparency wether defaultOperators can be adjusted by company: if government address is set company changed it and is thus not controllable (return false)
    function isControllable() external view returns(bool) {
        if(governmentAddress != address(0x0)) {  return false; }
                return true;   
    }
    /*
    ///@dev manage documents associated with investor
    function uploadDocument(bytes32 _name, string _url, bytes32 _documentHash) payable external {
        require(msg.value == accreditationFee);
    }

    function checkDocument(bytes32 _name) external view returns(string, bytes32) {
        return (url_, documentHash_);
    } */

    ///@notice advocate can approve investor to another level of accreditation; 0 = no investor, 1 = approved investor, 2 = advocate
    function approveAccreditation(address _address) external {
        require(LevelOfAccreditation[msg.sender] == 2);
        LevelOfAccreditation[_address] = 1;
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
        //@security use careful, as could get looped -> high gas costs
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
    //@security if proposal is out of range, this will automatically throw and revert changes
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

    //@ToAsk possible to work with memory array?
    ///@notice for EVM could be possible to work with fixed array e.g. 3 proposals
    function getProposals() public view returns(bytes32[]){
        bytes32[] memory proposals_;
        for (uint i = 0; i < Proposals.length; i++){
            proposals_[i] = Proposals[i].name;
        }
        return proposals_;
    }

    function getVoteCount(uint _index) public view returns(uint voteCount_) {
        return voteCount_ = Proposals[_index].voteCount;
    }
//-----Voting-----------------------------------------------------------------------------------------------------------------------------

//-----ERC20BackwardCompatibility---------------------------------------------------------------------------------------------------------
    /* This section determines obsolete erc20 methods that are only implemented to maintain backwards compatibility.
       Further erc20 compatibility can be disabled, then the methods will fail.
        - 
        */


    //@ToDo indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
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
    ///@dev with _preventLocking parameter, should return _doSend(msg.sender, _to, _txamount, "", msg.sender, "", false) false here!
    function transfer(address _to, uint _txamount) public erc20 returns(bool success_) {
        _doSend(msg.sender, _to, _txamount, "", msg.sender, "");
        return true;
    }

    ///@dev transfers token from A to B and fires event, additionally updates the TotalDistribution array (shareholder book); transferFrom should be used for withdrawing workflow
    ///@notice ERC20 mandatory
    function transferFrom(address _from, address _to, uint _txamount) public erc20 returns(bool success_) {
        require((_txamount <= allowed[_from][msg.sender]), "no approval for transaction");

        //@security cannot be after doSend because of tokensReceived re-entry
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_txamount);
        _doSend(_from, _to, _txamount, "", msg.sender, "");
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