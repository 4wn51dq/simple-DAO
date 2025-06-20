//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract DAO {

    event NewProposal(uint proposalId, address proposer, bytes proposalData, uint deadlineOfVoting);
    event Welcome(address newMember, address welcomedBy);
    event ProposalExecuted(uint proposalId);

    address[] public members;
    
    mapping(address => bool) public isMember;
    
    enum Support {voteFor, voteAgainst} 
    //think of this like every voter would have an enum card which they can use to show choice.

    event NewTransparentVote(address voter, uint proposalId, Support);


    mapping(uint => mapping(address => bool)) hasVoted;
    //nested mapping to ensure a particular proposal doesnt take
    //a vote from the same address again

    struct Proposal{
        address sender;
        bytes idea; 
        uint forCount;
        uint againstCount;
        uint proposalId; //each proposal will be unique by its proposalId
        uint voteDeadline;

        bool executed;
    }
    struct Vote{
        address voter;
        uint voteTo;
        uint voteIdx;
    }

    Proposal[] public proposals;

    function addMember(address newMember) external {
        require(isMember[msg.sender], 'permission denied');
        require(!isMember[newMember], 'already a member.');

        members.push(newMember);
        isMember[newMember] = true;

        emit Welcome(newMember, msg.sender);
    }

    function createProposal(bytes memory _idea, uint _votingPeriod) public {
        require(isMember[msg.sender], 'not a member');

        Proposal memory proposal = Proposal({
            sender: msg.sender,
            idea: _idea,
            forCount: 0,
            againstCount: 0,
            proposalId: proposals.length,
            voteDeadline: block.timestamp + _votingPeriod,
            // _votingPeriod is the amount of time after calling the function till which 
            // members can vote.
            executed: false
        });

        proposals.push(proposal);

        emit NewProposal(proposal.proposalId, msg.sender, _idea, proposal.voteDeadline);
    }

    Vote[] public votes;

    function castVote(uint _proposalId, Support _support) public {
        require(isMember[msg.sender], "not a member");
        require(!hasVoted[_proposalId][msg.sender], "no double voting");

        Proposal storage proposal = proposals[_proposalId]; // the proposal to be dealt with
        require (block.timestamp <= proposal.voteDeadline, 'too late to cast vote'); 
        // the particular proposal cannot be dealt with any further if deadline has crossed

        // this contract wont directly cast vote but would also declare choice (go with or go against)
        // everything below wouldnt make sense if caller was past deadline.

        if (_support == Support.voteFor) {
            proposal.forCount++;
        } else {
            proposal.againstCount++;
        }

        // choice was declared, this lets the person now create their vote 
        // then the vote will be put into record 
        Vote memory newVote = Vote({
            voter: msg.sender,
            voteTo: _proposalId,
            voteIdx: votes.length
        });
        votes.push(newVote);

        hasVoted[_proposalId][msg.sender] = true;

        emit NewTransparentVote(msg.sender, _proposalId, _support);
    }

    //the execute function is what ensures the smart contract is autonomous
    // the execute function has to be private (only current contract can call or simply 
    // ensuring the the function is auto executed).
    function execute(uint _proposalId) public {
        require(isMember[msg.sender]);
        require(_proposalId < proposals.length);

        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.voteDeadline);
        require(!proposal.executed);
        require(proposal.forCount > proposal.againstCount);

        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }
}