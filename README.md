# ProofStack: Trustless Reputation Engine

ProofStack is a decentralised reputation and participation scoring framework designed for community governance on the Stacks blockchain. It provides a trustless mechanism to track and reward various forms of participation within decentralised communities.

## Overview

ProofStack enables communities to quantify, track, and reward different contributions to governance and community participation. The system uses a time-decaying reputation score to ensure active participants maintain higher influence in governance decisions.

## Features

- **Decentralized Reputation Tracking**: Transparent, on-chain reputation scoring
- **Multiple Contribution Types**: Support for different governance activities
- **Time-Decay Mechanism**: Reputation scores decay over time to favour active participants
- **Customizable Rewards**: Configurable point values for different contribution types
- **Permission Management**: Owner-only administrative functions

## Smart Contract Structure

The contract is built on the Stacks blockchain and includes:

### Constants
- Error codes for various failure conditions
- Default contribution types

### Data Maps
- `participant-stats`: Tracks user reputation and participation metrics
- `contribution-types`: Defines reward values for different contribution types

### Public Functions

#### User Functions
- `join-network`: Register a new participant in the system
- `record-proposal`: Record when a user submits a governance proposal
- `record-vote`: Record when a user votes on proposals
- `record-completion`: Record when a user completes assigned tasks

#### Administrative Functions
- `update-contribution-reward`: Update the reward value for a specific contribution type

### Read-Only Functions
- `get-participant-profile`: Retrieve a participant's stats and reputation
- `get-contribution-reward`: Get the reward value for a specific contribution type
- `get-active-reputation`: Calculate time-decayed reputation score

## Usage Examples

### Joining the Network

```clarity
(contract-call? .proofstack join-network)
```

### Recording Contributions

```clarity
;; After submitting a proposal
(contract-call? .proofstack record-proposal)

;; After voting on a proposal
(contract-call? .proofstack record-vote)

;; After completing a community task
(contract-call? .proofstack record-completion)
```

### Querying Reputation

```clarity
;; Get full profile
(contract-call? .proofstack get-participant-profile tx-sender)

;; Get active reputation score with time decay
(contract-call? .proofstack get-active-reputation tx-sender)
```

### Administrative Functions

```clarity
;; Update reward for completing tasks (only callable by contract owner)
(contract-call? .proofstack update-contribution-reward "task" u20)
```

## Technical Details

### Reputation Calculation

Reputation is calculated based on:
1. Base points earned from different contribution types
2. A time-decay function that reduces scores for inactive participants

The formula used for time decay is:
```
active_reputation = base_reputation / (dormancy_period / 1000)
```
where `dormancy_period` is the number of blocks since last contribution.

### Contribution Types

Default contribution types and their rewards:
- `initiative`: 10 points - Creating new proposals
- `decision`: 5 points - Voting on proposals
- `task`: 15 points - Completing assigned tasks

## Deployment

To deploy this contract on the Stacks blockchain:

1. Install the Stacks CLI and dependencies
2. Deploy using the Stacks CLI:
   ```
   stacks deploy proofstack.clar --network [mainnet|testnet]
   ```

## Security Considerations

- The contract includes validation to ensure only authorised users can perform administrative actions
- Reward values are capped to prevent excessive point manipulation
- All state changes are recorded on-chain for transparency and auditability

## Future Enhancements

Potential extensions to the ProofStack system:
- Integration with token-based voting systems
- Delegated reputation mechanisms
- Reputation-weighted governance proposals
- Enhanced time-decay algorithms
- Support for community-defined contribution types

