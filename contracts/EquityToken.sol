pragma solidity ^0.4.24;

/// For more documentation and illustration see the adjacent paper.

import "./ConvertLib.sol";
import "./SafeMath.sol";
import "./EquityTokenFactory.sol";

contract EquityToken is EquityTokenFactory {

//-----EquityToken------------------------------------------------------------------------------------------------------------------------
    /* This structure determines the business logic of a token (i.e. quasi-share)
        - 
        */

    ///@notice string as bytes32 only has space for 32 characters
    event adHocMessage(string _message, address _company);

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
    function balanceOfByTranche(address _addr, uint _trancheId) public view returns(uint) {
	    return OwnerToTrancheToBalance[_addr][_trancheId];
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
    function getInfosEquityToken() public view returns(uint, bytes32, bytes32, uint, uint) {
        return (tokenId, companyName, tokenTicker, granular, totalAmount);
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

    ///@dev possibility to broadcast adHocMessages for any size
    function sendAdHocMessage(string _message) public {
        // require(msg.sender == companyOwner, "requirement onlyOwner of Company modifier");  omitted for testing
        emit adHocMessage(_message, msg.sender);
    }
//-----EquityToken------------------------------------------------------------------------------------------------------------------------

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
    function startBallot(bytes32[] proposalNames) public {
        /// require(msg.sender == companyOwner, "requirement onlyOwner of Company modifier"); omitted for tests
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
    function winningProposal() public returns(bytes32 winnerName_) {
        // require(msg.sender == companyOwner, "requirement onlyOwner of Company modifier"); omitted for tests
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

    ///@notice indexing of from and to and tokenId beneficial, but dropped for mocha testing environment
    event Approval(address _from, address _to, uint _txamount);

    modifier isERC20() {
        require((erc20compatible), "erc20 compatibility has been disabled");
        _;
    }  

    ///@notice disables the ERC20 interface. 
    function disableERC20() public onlyOwnerOfCom {
        erc20compatible = false;
        //setInterfaceImplementation("ERC20Token", 0x0);
    }

    ///@notice enables the ERC20 interface.
    function enableERC20() public onlyOwnerOfCom {
        erc20compatible = true;
        ///setInterfaceImplementation("ERC20Token", this);
    }

    ///@dev number of decimals token uses, divide token amount by number of decimals to get user representation
    ///@notice ERC20 optional, ERC777 mandatory to be 18
    function decimals() public view isERC20 returns(uint8) { 
        return uint8(18);
    }

    ///@dev sender can approve an amount to be withdrawn by spender
    ///@notice ERC20 mandatory
    function approve(address _spender, uint _txamount) public checkGranularity(_txamount) isERC20 returns(bool success_) {
        allowed[msg.sender][_spender] = _txamount;
        emit Approval(msg.sender, _spender, _txamount);
        return true;
    }
  
    ///@notice ERC20 mandatory
    function allowance(address _owner, address _spender) public view isERC20 returns(uint remaining) {
        return allowed[_owner][_spender];
    }

  //-----ERC20BackwardCompatibility---------------------------------------------------------------------------------------------------------    

}
