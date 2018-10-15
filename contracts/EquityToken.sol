pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./ConvertLib.sol";
import "./EquityTokenFactory.sol";

contract EquityToken is EquityTokenFactory {
	

    //  --- Voting ---
    /* This structure allows a company to propose multiple proposals for an issue, voters can than choose one of the proposals 
        - the owning company works as an administrator and can start ballots
        - the number of votes are linked to the amount of shares a voter posseses (1:1)
        - voters can pass their right to vote
        - the winning proposal is calculated and broadcasted automatically
        */
    
    event votingSuccessful(bytes32 winnerName, uint countVotes); 
        
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
    function startBallot(bytes32[] ProposalNames) public onlyOwnerOfCom() {
          //@dev: push proposal to public array
           for (uint i = 0; i < ProposalNames.length; i++) {
                Proposals.push(Proposal({name: ProposalNames[i], voteCount: 0
            }));
           }

        //@dev: allocates voting weigth = # of shares
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
    function winningProposal() public returns (bytes32 winnerName_)    {
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

}
