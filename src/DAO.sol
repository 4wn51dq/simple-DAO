//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface DAOEvents {

    event NewProposal(uint proposalId, address proposer, bytes32 proposalData, uint deadlineOfVoting);
    event Welcome(address newMember, address welcomedBy);
    event ProposalExecuted(uint proposalId);
    event ProposalAltered(uint256 proposalId);
}

contract DAO is DAOEvents{

    struct Proposal{
        address sender;
        bytes32 idea; 
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

    address[] public members;
    Proposal[] public proposals;

    
    mapping(address => bool) public isMember;
    mapping (address => mapping (uint256 => bool)) private hasVoted; /* voted for the proposal index */

    
    enum Support {voteFor, voteAgainst} 
    event NewTransparentVote(address voter, uint proposalId, Support);



    constructor () {
         isMember[msg.sender] = true;
         members.push(msg.sender);
    }

    function addMember(address newMember) external {
        require(isMember[msg.sender], 'permission denied');
        require(!isMember[newMember], 'already a member.');

        members.push(newMember);
        isMember[newMember] = true;

        emit Welcome(newMember, msg.sender);
    }

    function createProposal(bytes32 _idea, uint _votingPeriod) public returns (Proposal memory){
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

        return proposal;
    }

    function editProposal(uint256 _proposalId, bytes32 _newIdea, uint256 _votingPeriod) external {
        require(isMember[msg.sender]);
        require(proposals[_proposalId].sender == msg.sender);

        Proposal storage editedProposal = proposals[_proposalId];
        require (block.timestamp <= editedProposal.voteDeadline, "proposal already sent for evaluation");

        editedProposal.idea = _newIdea;
        editedProposal.forCount = 0;
        editedProposal.againstCount = 0;
        editedProposal.voteDeadline = block.timestamp + _votingPeriod;

        emit ProposalAltered(_proposalId);
    }

    // Vote[] public votes; /* expensive */

    function castVote(uint _proposalId, Support _support) public {
        require(isMember[msg.sender], "not a member");
        require(!hasVoted[msg.sender][_proposalId], "no double voting");

        Proposal storage proposal = proposals[_proposalId]; // the proposal to be dealt with
        require (block.timestamp <= proposal.voteDeadline, 'voting period over for proposal'); 

        _support == Support.voteFor ? proposal.forCount++ : proposal.againstCount++ ;

        hasVoted[msg.sender][_proposalId] = true;

        emit NewTransparentVote(msg.sender, _proposalId, _support);
    }

    function execute(uint _proposalId) public {
        require(isMember[msg.sender]);
        require(_proposalId < proposals.length);

        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.voteDeadline, "voting is ongoing");
        require(!proposal.executed, "already Executed");
        require(proposal.forCount > proposal.againstCount, "not enough support");

        require(proposal.forCount + proposal.againstCount> members.length/2, "low participation");

        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    
}