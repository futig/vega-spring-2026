// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Voting power formula: VP(t) = Σ_i (expiry_i - t)^2 * amount_i / YEAR^2
// Duration D^initial ∈ [1, 4] years; result is in token-equivalent units (wei).
contract VegaVoting is ERC721, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant YEAR         = 365 days;
    uint256 public constant MIN_DURATION = YEAR;
    uint256 public constant MAX_DURATION = 4 * YEAR;

    IERC20 public immutable vvToken;

    struct Stake {
        uint256 amount;
        uint256 expiry;
    }

    struct Voting {
        bytes32 id;
        uint256 deadline;
        uint256 votingPowerThreshold;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool passed;
    }

    struct VoteResult {
        bytes32 voteId;
        uint256 yesVotes;
        uint256 noVotes;
        bool passed;
        uint256 finalizedAt;
        string description;
    }

    mapping(address => Stake[]) private _stakes;
    mapping(bytes32 => Voting) private _votings;
    bytes32[] public votingIds;
    mapping(address => mapping(bytes32 => bool)) public hasVoted;
    mapping(uint256 => VoteResult) private _voteResults;
    uint256 private _nftCounter;

    event Staked(address indexed user, uint256 indexed stakeIndex, uint256 amount, uint256 expiry);
    event Unstaked(address indexed user, uint256 indexed stakeIndex, uint256 amount);
    event VoteCreated(bytes32 indexed id, uint256 deadline, uint256 threshold, string description);
    event VoteCast(bytes32 indexed voteId, address indexed voter, bool support, uint256 votingPower);
    event VoteFinalized(bytes32 indexed voteId, bool passed, uint256 yesVotes, uint256 noVotes, uint256 nftTokenId);

    constructor(address _vvToken, address initialOwner)
        ERC721("VegaVotingResult", "VVR")
        Ownable(initialOwner)
    {
        require(_vvToken != address(0), "VegaVoting: zero token address");
        vvToken = IERC20(_vvToken);
    }

    function stake(uint256 amount, uint256 duration) external whenNotPaused nonReentrant {
        require(amount > 0, "VegaVoting: amount must be positive");
        require(
            duration >= MIN_DURATION && duration <= MAX_DURATION,
            "VegaVoting: duration must be in [1, 4] years"
        );

        vvToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 expiry = block.timestamp + duration;
        _stakes[msg.sender].push(Stake({amount: amount, expiry: expiry}));

        emit Staked(msg.sender, _stakes[msg.sender].length - 1, amount, expiry);
    }

    function unstake(uint256 stakeIndex) external nonReentrant {
        Stake[] storage stakes = _stakes[msg.sender];
        require(stakeIndex < stakes.length, "VegaVoting: invalid stake index");

        Stake storage s = stakes[stakeIndex];
        require(s.amount > 0, "VegaVoting: already withdrawn");
        require(block.timestamp >= s.expiry, "VegaVoting: stake not yet expired");

        uint256 amount = s.amount;
        s.amount = 0;
        vvToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, stakeIndex, amount);
    }

    function votingPowerOf(address user) public view returns (uint256) {
        return _votingPowerAt(user, block.timestamp);
    }

    function _votingPowerAt(address user, uint256 t) internal view returns (uint256 vp) {
        Stake[] storage stakes = _stakes[user];
        uint256 yearSquared = YEAR * YEAR;
        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage s = stakes[i];
            if (s.amount > 0 && s.expiry > t) {
                uint256 dRemain = s.expiry - t;
                vp += (dRemain * dRemain * s.amount) / yearSquared;
            }
        }
    }

    function createVote(
        bytes32 id,
        uint256 deadline,
        uint256 votingPowerThreshold,
        string calldata description
    ) external onlyOwner whenNotPaused {
        require(deadline > block.timestamp, "VegaVoting: deadline must be in the future");
        require(_votings[id].deadline == 0, "VegaVoting: vote ID already exists");
        require(votingPowerThreshold > 0, "VegaVoting: threshold must be positive");
        require(bytes(description).length > 0, "VegaVoting: empty description");

        _votings[id] = Voting({
            id: id,
            deadline: deadline,
            votingPowerThreshold: votingPowerThreshold,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            passed: false
        });
        votingIds.push(id);

        emit VoteCreated(id, deadline, votingPowerThreshold, description);
    }

    function castVote(bytes32 voteId, bool support) external whenNotPaused nonReentrant {
        Voting storage v = _votings[voteId];
        require(v.deadline != 0, "VegaVoting: vote does not exist");
        require(!v.finalized, "VegaVoting: vote already finalized");
        require(block.timestamp < v.deadline, "VegaVoting: voting period ended");
        require(!hasVoted[msg.sender][voteId], "VegaVoting: already voted");

        uint256 vp = votingPowerOf(msg.sender);
        require(vp > 0, "VegaVoting: no voting power");

        hasVoted[msg.sender][voteId] = true;

        if (support) {
            v.yesVotes += vp;
        } else {
            v.noVotes += vp;
        }

        emit VoteCast(voteId, msg.sender, support, vp);

        if (v.yesVotes >= v.votingPowerThreshold) {
            _finalizeVote(voteId);
        }
    }

    function finalizeVote(bytes32 voteId) external whenNotPaused {
        Voting storage v = _votings[voteId];
        require(v.deadline != 0, "VegaVoting: vote does not exist");
        require(!v.finalized, "VegaVoting: vote already finalized");
        require(block.timestamp >= v.deadline, "VegaVoting: voting period not ended");

        _finalizeVote(voteId);
    }

    function _finalizeVote(bytes32 voteId) internal {
        Voting storage v = _votings[voteId];
        v.finalized = true;
        v.passed = v.yesVotes >= v.votingPowerThreshold;

        uint256 tokenId = _nftCounter++;
        _safeMint(owner(), tokenId);

        _voteResults[tokenId] = VoteResult({
            voteId: voteId,
            yesVotes: v.yesVotes,
            noVotes: v.noVotes,
            passed: v.passed,
            finalizedAt: block.timestamp,
            description: v.description
        });

        emit VoteFinalized(voteId, v.passed, v.yesVotes, v.noVotes, tokenId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getVoting(bytes32 id) external view returns (Voting memory) {
        require(_votings[id].deadline != 0, "VegaVoting: vote does not exist");
        return _votings[id];
    }

    function getUserStakes(address user) external view returns (Stake[] memory) {
        return _stakes[user];
    }

    function getVoteResult(uint256 tokenId) external view returns (VoteResult memory) {
        require(_ownerOf(tokenId) != address(0), "VegaVoting: token does not exist");
        return _voteResults[tokenId];
    }

    function getVotingCount() external view returns (uint256) {
        return votingIds.length;
    }
}
