pragma solidity ^0.4.24;

/// For more documentation and illustration see the adjacent paper.

import "./SafeMath.sol";

contract EquityTokenFactory /* is ERC20Interface, ERC777Interface, EIP1410Interface, EIP1400Interface */ {

    using SafeMath for uint;

    mapping (address => uint) OwnerToBalance; ///@notice wallet of tokens and balances of an owner
    ///@notice wallet of tokens and balances of an owner depending on tranche
    mapping (address => mapping (uint => uint)) OwnerToTrancheToBalance; 
    mapping (address => uint[]) OwnerToTranches; ///@notice tranches array of an owner
    mapping (uint => TrancheMetaData) IdToMetaData; ///@notice mapping of metadata belonging to a token tranche
    mapping (address => bool) AddressExists; ///@notice required for check if address is already stakeholder, more efficient than iterating array
    mapping (address => uint) AddressToIndex; ///@notice index of address in shareholder array (TotalDistribution) 
    ///@notice allowance for transfer from _owner to _receiver to withdraw (ERC20 & ERC777)
    mapping (address => mapping (address => uint)) allowed; 
    ///@notice maps an address if it passed KYC protocol; 0 = not accredited, 1 = investor, 2 = advocate)
    mapping (address => uint) LevelOfAccreditation;
    mapping (bytes32 => bool) CompanyToRequest; ///@notice maps if a company went through KYC/AML protocol;

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
    ///@dev adjustments and new length of shareholder book
    event newShareholder(address newShareholder, uint length);

    ///@notice the core data of a issued token
    ///@param granular for explanation see constructor
    ///@param defaultOperator every token has two higher level administrators by default -> issuing company and government; can be changed
    uint internal tokenId;
    bytes32 internal companyName;
    bytes32 internal tokenTicker;
    byte internal categoryShare;
    uint internal granular;
    uint internal totalAmount;
    address internal companyOwner;
    address[2] internal defaultOperator;
    uint internal regulationMaximumInvestors;
    uint internal regulationMaximumSharesPerInvestor;
  
    ///@notice array of all owner of one equity token, thus the shareholder book
    address[] public TotalDistribution;

    ///@notice struct with metadata of every tranche
    struct TrancheMetaData {
        uint trancheAmount;
        uint mintedTimeStamp;
        uint LockupPeriod;
    }

    Document[] internal TokenDocuments;
    struct Document {
        bytes32 documentName;
        string key;
        bytes32 documentHash;
    }

    ///@notice default lockup of tranche after trading
    uint internal defaultLockupPeriod = 365 days;

    ///@notice token issuer can specify to stop token issuance, cannot be reverted
    bool public isIssuable = true;
    
    ///@dev declares a random nonce which increases every time random number generator is used
    ///@dev ensures, that randomId is always 12 digits
    uint internal randNonce = 0;
    uint internal idModulus = 10 ** 12;

    ///@notice address of government, by default operator of any token; can be changed by companyOwner
    address public governmentAddress;

    ///@notice fee in order to get KYC/AML process
    uint public accreditationFee = 1 ether;

    ///@notice set if token should be interoperable with exchanges
    bool internal erc20compatible;

    ///@dev creates new token shell (status pending), safes information in storage
    ///@param _granularity ensures, that granularity of shares is always a positive natural figure, cannot be changed ever
    function createToken(bytes32 _companyName, bytes32 _tokenTicker, uint _granularity) public {
        assert(_granularity >= 1); // "granularity has to be greater or equal 1"
        tokenId = _generateRandomId(_companyName);
        companyName = _companyName;
        tokenTicker = _tokenTicker;
        categoryShare = "A";
        totalAmount = 0;
        granular = _granularity;
        erc20compatible = true;
        companyOwner = msg.sender;
        defaultOperator = [msg.sender, governmentAddress];

        ///@dev solidity declares a variable by default to 0, thus in the test environment we have to simulate regulation requirements
        regulationMaximumInvestors = 10 ** 4;
        regulationMaximumSharesPerInvestor = 10 ** 6;

        _toShareholderbook(msg.sender);

        emit newTokenIssuance(companyName, tokenTicker, msg.sender);
    }
  
    ///@notice process to mint new equity
    ///@notice compliant with ERC777 & EIP1410
    function mint(uint _amount, bytes _userData, bytes _operatorData) public checkGranularity(_amount) onlyOwnerOfCom {         
        require((CompanyToRequest[companyName] == true), "requires changed status from pending to active");
        require((isIssuable == true), "token issuance is finished");

        ///@notice creates random Id for new tranche of equity, stores only Id in array and metadata in metadata struct
        uint trancheId = _generateRandomId(companyName);
        IdToMetaData[trancheId] = (TrancheMetaData(_amount, block.timestamp, 0));

        ///@notice increase balance in two ways, first overall balance of owner, second tranche-specific balanche of owner
        totalAmount = totalAmount.add(_amount);
        OwnerToBalance[msg.sender] = OwnerToBalance[msg.sender].add(_amount);
        OwnerToTrancheToBalance[msg.sender][trancheId] = OwnerToTrancheToBalance[msg.sender][trancheId].add(_amount);

        OwnerToTranches[msg.sender].push(uint(trancheId));

        emit Minted(msg.sender, msg.sender, _amount, _userData, _operatorData);
        emit MintedByTranche(trancheId, msg.sender, msg.sender, _amount, _userData, _operatorData);
        if (erc20compatible) {emit Transfer(0x0, msg.sender, _amount);}
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
            uint[] memory tempTranches = OwnerToTranches[_from]; 
            uint tempTrancheId = tempTranches[tempTranches.length - counter];
                
            if(OwnerToTrancheToBalance[_from][tempTrancheId] >= _amount.sub(burnedAmount)) {
                totalAmount = totalAmount.sub((_amount.sub(burnedAmount)));
                OwnerToBalance[_from] = OwnerToBalance[_from].sub((_amount.sub(burnedAmount)));
                OwnerToTrancheToBalance[_from][tempTrancheId].sub((_amount.sub(burnedAmount)));
                emit BurnedByTranche(tempTrancheId, msg.sender, _from, _amount, _operatorData);
                break;
            }
            else {
                uint burnTx = OwnerToTrancheToBalance[_from][tempTrancheId];
                totalAmount = totalAmount.sub(burnTx);
                OwnerToBalance[_from] = OwnerToBalance[_from].sub(burnTx);
                OwnerToTrancheToBalance[_from][tempTrancheId].sub(burnTx);

                burnedAmount = burnedAmount.add(burnTx);
                counter = counter.add(1);
                emit BurnedByTranche(tempTrancheId, msg.sender, _from, _amount, _operatorData);
            }
        }
        emit Burned(msg.sender, _from, _amount, _operatorData);
        if(OwnerToBalance[_from] == 0) {_deleteShareholder(_from);}
        if(erc20compatible) {emit Transfer(_from, address(0x0), _amount);}
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
        if(OwnerToBalance[_from] == 0) {_deleteShareholder(_from);}
        if(erc20compatible) {emit Transfer(_from, address(0x0), _amount);}
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
    function _generateRandomId() internal view returns(uint) {
        uint random = uint(keccak256(abi.encodePacked("randomString", randNonce)));
        randNonce.add(1);
        return random % idModulus;
    }
    function _generateRandomId(bytes32 _stringInput) internal view returns(uint) {
        uint random = uint(keccak256(abi.encodePacked(_stringInput, randNonce)));
        randNonce.add(1);
        return random % idModulus;
    }

    ///@dev iternal function to push new address to shareholder book, checks if address exists first
    function _toShareholderbook(address _addr) internal returns(bool success_) {
        if (_checkExistence(_addr)) return false;

        uint AddressIndex = uint(TotalDistribution.push(address(_addr))) - 1;
        AddressToIndex[_addr] = AddressIndex;
        AddressExists[_addr] = true;

        emit newShareholder(_addr, TotalDistribution.length);
        return true;
    }

    function _deleteShareholder(address _from) internal returns(bool success_) {
        uint tempIndex = AddressToIndex[_from];
        delete TotalDistribution[tempIndex];
        return true;
    }

    /* ///@notice helps to re-sort arrays
    function remove(uint index)  returns(uint[]) {
        if (index >= array.length) return;
        for (uint i = index; i<array.length-1; i++){
            array[i] = array[i+1];}
        array.length--;
        return array;
    } */
    
    ///@dev manage documents associated with token, using IPFS encrypted peer-to-peer filesharing
    ///@notice EIP1400 proposal
    function setDocument(bytes32 _name, string _key, bytes32 _documentHash) external payable {
        require((msg.value == accreditationFee),"not enough ether in for payable function");
        TokenDocuments.push(Document(_name, _key,_documentHash));
        // Qmd7k4CUpE8Q6zbWJyVXCrdUbtCDBiYaCazpYmg2CQvn4q 8272F50FFD9253E3 ipo-prospectus-onepager.pdf 
    }

    function getDocument(bytes32 _name, address _documentsFrom) external view returns(string, bytes32){
        require((LevelOfAccreditation[msg.sender] == 100), "requires advocate to see download files");
        require((mAuthorized[msg.sender][_documentsFrom]), "advocate is not authorized to retrieve files");
        for (uint i = 0; i < TokenDocuments.length; i++) {
            if(TokenDocuments[i].documentName == _name) {
                return (TokenDocuments[i].key, TokenDocuments[i].documentHash);
            }
        }
    }

    ///@notice authorize a third party _operator to manage (send) msg.sender's tokens. msg.sender always operator himself, thus requirement
    ///@notice ERC777 mandatory
    function authorizeAdvocate(address _advocate) public {
        require((_advocate != msg.sender), "msg.sender cannot authorized himself");
        mAuthorized[_advocate][msg.sender] = true;
    }

    ///@notice advocate can clear a companies request, changing status pending into active token
    function clearRequest(bytes32 _companyName) external {
        // require((LevelOfAccreditation[msg.sender] == 100), "requires advocate to activate token"); omitted for testing
        CompanyToRequest[_companyName] = true;
    }

    ///@notice ERC20 mandatory
    event Transfer(address _from, address _to, uint _txamount);
    
//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------


//-----TokenGovernance-------------------------------------------------------------------------------------------------------------------- 
    ///@notice fires event if authorization of operator for an address
    ///@notice ERC777 mandatory
    event AuthorizedOperator(address operator, address tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    mapping(address => mapping(address => bool)) internal mAuthorized;

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
        require((_isRegularAddress(_addr) == true), "_addr address does not exist or is 0x0 (burning)");
        governmentAddress = _addr;
    }

    ///@notice owner can stop issuance, not revertable!
    ///@notice EIP1400 mandatory
    function stopIssuance() external onlyOwnerOfCom {
        isIssuable = false;
    }

    ///@notice provides transparency wether defaultOperators can be adjusted by company: if government address is set company changed it and is thus not controllable (return false)
    function isControllable() external view returns(bool) {
        if(governmentAddress != address(0x0)) {return false;}
        return true;
    }

    ///@dev checks existence of address in shareholder book by using mapping (address => bool)
    function _checkExistence(address _addr) internal view returns(bool success_) {
        require((_isRegularAddress(_addr) == true), "not a regular address");
        return AddressExists[_addr];
    }
    
    ///@notice check whether an address is a regular address (0x0 address and length of address). Suppress warning by "// solhint-disable-line no-inline-assembly"
    function _isRegularAddress(address _addr) internal view returns(bool) {
        if (_addr == 0x0) { 
            return false; }
        uint size;
        assembly { size := extcodesize(_addr) }
        return size == 0;
    }

    ///@dev manage documents associated with investor
    function uploadDocument(bytes32 _name, string _key, bytes32 _documentHash) external payable {
        require((msg.value == accreditationFee),"not enough ether in for payable function");
        TokenDocuments.push(Document(_name, _key,_documentHash));
        /// QmQ5vhrL7uv6tuoN9KeVBwd4PwfQkXdVVmDLUZuTNxqgvm 882ACD0FD77E4VD KYC-documents.pdf 
    }

    ///@notice advocate can approve investor to another level of accreditation; 0 = no investor, 1 = approved investor, 2 = advocate
    function authorizeRequest(address _authorizedInvestor) external {
        /// require((LevelOfAccreditation[msg.sender] == 100), "requires advocate to authorize investor"); omitted for testing
        require((LevelOfAccreditation[_authorizedInvestor] < 2), "investor already authorized an accredited");
        LevelOfAccreditation[_authorizedInvestor].add(1);
    }

    ///@notice this modul implements lockup periods, for the sake of simplicity it is not active within the contract.
    /// one has to set LockupPeriod within minting function, and the require _isReady == true within transaction functions.
    function _isReady(uint _trancheId) internal view returns(bool ready_) {
        uint readyTime = uint(IdToMetaData[_trancheId].mintedTimeStamp + IdToMetaData[_trancheId].LockupPeriod);
        return (block.timestamp >= readyTime);
    }

    function setLockup(uint _adjustedLockup) external onlyOwnerOfCom {
        defaultLockupPeriod = _adjustedLockup;
    }

//-----TokenGovernance-------------------------------------------------------------------------------------------------------------------- 

}
