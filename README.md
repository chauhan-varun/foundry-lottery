# Provably Fair Raffle Smart Contract

A decentralized and verifiably random raffle system built on Ethereum using Solidity, Foundry, and Chainlink VRF + Automation.

## Overview

This project implements a trustless raffle where:
- Users can enter by paying an entrance fee
- A verifiably random winner is selected after a time interval
- The winner receives all the accumulated ETH
- The drawing process is fully automated and tamper-proof

## Features

- **Transparent**: All code is open source and verifiable
- **Fair**: Uses Chainlink VRF (Verifiable Random Function) for true randomness
- **Automated**: Leverages Chainlink Automation for time-based execution
- **Gas-efficient**: Optimized for minimal gas usage

## Technology Stack

- **Solidity** - Smart contract development
- **Foundry** - Testing framework
- **Chainlink VRF** - Verifiable randomness
- **Chainlink Automation** - Decentralized execution

## Project Structure

### Smart Contracts

- `src/Raffle.sol` - Main raffle contract implementation

### Scripts

- `script/DeployRaffle.s.sol` - Deployment script for the Raffle contract
- `script/HelperConfig.s.sol` - Configuration helper for different networks
- `script/Interactions.s.sol` - Scripts for interacting with the deployed contract

### Tests

- `test/unit/RaffleTest.t.sol` - Comprehensive unit tests for the Raffle contract
  - Tests for entering the raffle
  - Tests for checkUpkeep functionality
  - Tests for performUpkeep functionality
  - Tests for winner selection and prize distribution
  - and more...

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) - For building and testing
- [Forge](https://book.getfoundry.sh/reference/forge/forge) - For compiling and deploying contracts

### Installation

1. Clone the repository
```bash
git clone https://github.com/chauhan-varun/foundry-lottery.git
cd raffle
```

2. Install dependencies
```bash
forge install
```

3. Build the project
```bash
forge build
```

### Testing

Run the test suite:
```bash
forge test
```

For verbose output:
```bash
forge test -vvv
```

For specific test files:
```bash
forge test --match-path test/unit/RaffleTest.t.sol -vvv
```

### Deployment

1. Setup environment variables (create a `.env` file):
```
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. Deploy to testnet:
```bash
forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

## Contract Details

### Raffle.sol

The main contract with the following functionality:
- `enterRaffle()`: Enter the raffle by sending ETH
- `checkUpkeep()`: Check if it's time to perform a drawing
- `performUpkeep()`: Initiate the random number request
- `fulfillRandomWords()`: Process the random result and select a winner

### Script Details

#### DeployRaffle.s.sol
Handles the deployment of the Raffle contract with proper configuration based on the network.

#### HelperConfig.s.sol
Provides network-specific configurations including:
- VRF Coordinator addresses
- Gas lane values
- Subscription IDs
- Entrance fees
- Interval settings

#### Interactions.s.sol
Contains scripts for interacting with the deployed contract:
- Creating VRF subscriptions
- Funding subscriptions
- Adding consumers to subscriptions

### Test Details

The test suite covers:
- Contract initialization state
- Raffle entrance requirements and validations
- Player recording functionality
- Event emission verification
- Upkeep checks under various conditions
- Random number fulfillment and winner selection
- Prize distribution

## Configuration

The contract is configurable with:
- Entrance fee
- Drawing interval
- VRF parameters (gas lane, callback gas limit, etc.)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Varun Chauhan