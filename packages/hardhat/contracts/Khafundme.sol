// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum Option {
    A,
    B
}

struct Proposal {
    string title;
    uint256 proposalDeadline;
    uint256 votesForOptionA;
    uint256 votesForOptionB;
    uint256 minimumVotes;
    address optionA;
    address optionB;
    string nameForOptionA;
    string nameForOptionB;
    bool executed;
}

struct Winner {
    uint256 proposalId;
    string winnerName;
    address winnerAddress;
}

contract Khafundme is Ownable {
    event ProposalCreated(
        uint256 proposalId,
        string title,
        uint256 proposalDeadline,
        uint256 minimumVotes,
        address optionA,
        address optionB,
        string nameForOptionA,
        string nameForOptionB
    );
    event VoteCasted(uint256 proposalId, address voter, Option selectedOption);

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Winner) public winners;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => mapping(uint256 => Option)) public voterOption;

    uint256 public proposalCounter;
    IERC20 private khaToken;

    // constructor(address _khaTokenAddress) {
    //     // khaToken = IERC20(_khaTokenAddress);
    // }

    function createProposal(
        string memory _title,
        uint256 _proposalDurationInMinutes,
        uint256 _minimumVotes,
        address _optionA,
        address _optionB,
        string memory _nameForOptionA,
        string memory _nameForOptionB
    ) public {
        require(_proposalDurationInMinutes > 0, "Proposal duration must be greater than zero");
        require(_minimumVotes > 0, "Minimum votes must be greater than zero");

        Proposal memory newProposal;
        newProposal.title = _title;
        newProposal.proposalDeadline = block.timestamp + (_proposalDurationInMinutes * 1 minutes);
        newProposal.minimumVotes = _minimumVotes;
        newProposal.optionA = _optionA;
        newProposal.optionB = _optionB;
        newProposal.nameForOptionA = _nameForOptionA;
        newProposal.nameForOptionB = _nameForOptionB;

        uint256 proposalId = proposalCounter;
        proposals[proposalCounter] = newProposal;
        proposalCounter++;

        emit ProposalCreated(
            proposalId,
            _title,
            newProposal.proposalDeadline,
            newProposal.minimumVotes,
            newProposal.optionA,
            newProposal.optionB,
            newProposal.nameForOptionA,
            newProposal.nameForOptionB
        );
    }

    function vote(uint256 _proposalId, Option _selectedOption) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.proposalDeadline, "Proposal has expired");
        require(!hasVoted[msg.sender][_proposalId], "Already voted");
        require(_selectedOption == Option.A || _selectedOption == Option.B, "Invalid option");

        uint256 votingPower = khaToken.balanceOf(msg.sender);
        require(votingPower > 0, "Voter has no voting power");

        if (_selectedOption == Option.A) {
            proposal.votesForOptionA += votingPower;
        } else {
            proposal.votesForOptionB += votingPower;
        }

        hasVoted[msg.sender][_proposalId] = true;

        emit VoteCasted(_proposalId, msg.sender, _selectedOption);
    }

    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.proposalDeadline, "Proposal deadline not yet reached");
        require(!proposal.executed, "Proposal already executed");

        Winner memory winner;
        if (proposal.votesForOptionA > proposal.votesForOptionB) {
            winner.proposalId = _proposalId;
            winner.winnerName = proposal.nameForOptionA;
            winner.winnerAddress = proposal.optionA;
        } else if (proposal.votesForOptionB > proposal.votesForOptionA) {
            winner.proposalId = _proposalId;
            winner.winnerName = proposal.nameForOptionB;
            winner.winnerAddress = proposal.optionB;
        } else {
            revert("Tie not allowed");
        }

        winners[_proposalId] = winner;
        proposal.executed = true;
    }

    function getProposal(uint256 _proposalId)
        public
        view
        returns (
            string memory title,
            uint256 proposalDeadline,
            uint256 votesForOptionA,
            uint256 votesForOptionB,
            uint256 minimumVotes,
            address optionA,
            address optionB,
            string memory nameForOptionA,
            string memory nameForOptionB,
            bool executed
        )
    {
        Proposal storage proposal = proposals[_proposalId];

        title = proposal.title;
        proposalDeadline = proposal.proposalDeadline;
        votesForOptionA = proposal.votesForOptionA;
        votesForOptionB = proposal.votesForOptionB;
        minimumVotes = proposal.minimumVotes;
        optionA = proposal.optionA;
        optionB = proposal.optionB;
        nameForOptionA = proposal.nameForOptionA;
        nameForOptionB = proposal.nameForOptionB;
        executed = proposal.executed;
    }

    function getWinner(uint256 _proposalId) public view returns (string memory winnerName, address winnerAddress) {
        Winner storage winner = winners[_proposalId];
        winnerName = winner.winnerName;
        winnerAddress = winner.winnerAddress;
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCounter;
    }

    function getHasVoted(uint256 _proposalId, address _voter) public view returns (bool) {
        require(_proposalId < proposalCounter, "Invalid proposal ID");
        return hasVoted[_voter][_proposalId];
    }
}
