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

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    mapping(address => Voter) VoterMap;

    function addWhiteList(address _address) public onlyOwner {
        require(
            !VoterMap[_address].isRegistered,
            "This address is already whiteListed"
        );
        VoterMap[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function statVote() public onlyOwner {
        // require(WorkflowStatus.VotingSessionStarted, "The session is already started");
        // WorkflowStatus.VotingSessionStarted = true;
    }

    function getWinner() public view returns (string memory) {}
}
