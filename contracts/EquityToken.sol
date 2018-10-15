pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./ConvertLib.sol";
import "./EquityTokenFactory.sol";

contract EquityToken is EquityTokenFactory {
	

    //  --- Voting ---
    /* */

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

    address public companyowner; //@notes: company address owning the company and voting proposal

    
    mapping(address => Voter) AddressToVoter;

    //@notes: all proposals of that company
    Proposal[] public proposals;

    //@notes: create a new ballot, only possible for owner of company
    function startBallot(bytes32[] proposalNames) public onlyOwnerOfCom() {
        companyowner = msg.sender;

        //@dev: push proposal to public array
           for (uint i = 0; i < proposalNames.length; i++) {
                proposals.push(Proposal({name: proposalNames[i], voteCount: 0
            }));

        //@dev: allocates voting weigth = # of shares
        AddressToVoter[msg.sender].weight = OwnerToBalance[msg.sender];
           
        }
    }

    //@dev: give voter the right to vote on this ballot
        function giveRightToVote(address _voter) public onlyOwnerOfCom() {
               
        require(!AddressToVoter[_voter].voted, "The voter already voted");
        
        require(AddressToVoter[_voter].weight == 0, "The right to vote already has been granted");

        AddressToVoter[_voter].weight = OwnerToBalance[_voter];
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
            proposals[delegate_.vote].voteCount = proposals[delegate_.vote].voteCount.add(sender.weight);
        } else {
            delegate_.weight.add(sender.weight);
        }
    }

    //@dev: give your vote for specific proposal
    //@security: if proposal is out of range, this will automatically throw and revert changes
    function vote(uint proposal) public {
        Voter storage sender = AddressToVoter[msg.sender];
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount = proposals[proposal].voteCount.add(sender.weight);
    }

    //@dev: computes the winning proposal
    function _winningProposal() private view returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    //@dev: calls _winningProposal() function to get the index of the winner contained in the proposals array and then returns the name of the winner
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[_winningProposal()].name;
    }
}
