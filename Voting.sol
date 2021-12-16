pragma solidity 0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus = WorkflowStatus.RegisteringVoters;
    mapping(address => Voter) VoterMap;
    mapping(uint256 => Proposal) ProposalMap;

    uint256 private nonce = 1;
    string private winner;
    uint256 private score;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    //modifier

    //constructor

    function addWhiteList(address _address) public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "The registering is ended"
        );
        require(
            !VoterMap[_address].isRegistered,
            "This address is already whiteListed"
        );
        VoterMap[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function startProposalsSession() public onlyOwner {
        require(
            workflowStatus != WorkflowStatus.ProposalsRegistrationStarted,
            "The session is already started"
        );
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Wrong step"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    function sendProposal(string memory proposal) public {
        require(VoterMap[msg.sender].isRegistered, "You are not whitelisted");
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "The proposal session doesn't started yet"
        );
        require(
            bytes(proposal).length != 0,
            "The proposal description is not valid"
        );

        ProposalMap[nonce].description = proposal;
        emit ProposalRegistered(nonce);
        nonce++;
    }

    function seeProposition(uint256 _proposalId)
        public
        view
        returns (Proposal)
    {
        require(
            VoterMap[msg.sender].isRegistered == true,
            "You are not whitelisted"
        );
        require(
            bytes(ProposalMap[_proposalId].description).length != 0,
            "The proposal doesn't exist"
        );
        return ProposalMap[_proposalId];
    }

    function endProposalsSession() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "The session hasn't started"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    function startVoteSession() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "The session hasn't started"
        );
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    function sendVote(uint256 _proposalId) public {
        require(!VoterMap[msg.sender].hasVoted, "You have already voted");
        require(VoterMap[msg.sender].isRegistered, "You are not whitelisted");
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "The session doesn't have started yet"
        );
        require(_proposalId < nonce, "The proposal doesn't exist");
        ProposalMap[_proposalId].voteCount += 1;
        VoterMap[msg.sender].votedProposalId = _proposalId;
        VoterMap[msg.sender].hasVoted = true;
        if (ProposalMap[_proposalId].voteCount > score) {
            winner = ProposalMap[_proposalId].description;
            score = ProposalMap[_proposalId].voteCount;
        }
        emit Voted(msg.sender, _proposalId);
    }

    function endVoteSession() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "The vote session hasn't started"
        );
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    function getStats(uint256 _proposalId)
        public
        view
        onlyOwner
        returns (uint256)
    {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "The session is not ended"
        );
        require(_proposalId < nonce, "The proposal doesn't exist");
        return ProposalMap[_proposalId].voteCount;
    }

    function setWinner(uint256 _proposalId) public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "The session is not ended"
        );
        require(_proposalId < nonce, "The proposal doesn't exist");
        winner = ProposalMap[_proposalId].description;
        score = ProposalMap[_proposalId].voteCount;
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }

    function countVote() public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "The session is not ended"
        );
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }

    function getWinner() public view returns (Proposal) {
        require(
            workflowStatus == WorkflowStatus.VotesTallied,
            "The vote is not tallied yet"
        );
        uint256 countMax;
        for (uint256 i = 0; i < nonce; i++) {
            if (ProposalMap[i].voteCount > countMax) {
                countMax = ProposalMap[i].voteCount;
            }
        }
        return ProposalMap[countMax];
    }

    function votedFor(address _address) public view returns (uint256) {
        require(
            VoterMap[_address].hasVoted == true,
            "The address hasn't voted yet"
        );
        return VoterMap[msg.sender].votedProposalId;
    }
}
