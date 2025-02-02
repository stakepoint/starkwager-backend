# StarkWager

StarkWager is a decentralized application (dApp) designed to leverage the StarkNet ecosystem, enabling users to place wagers on simple agreements or competitions with minimal transaction fees. This app ensures a seamless experience for users to deposit, withdraw, and interact with wagers through smart contracts.

## 🌟 Features
- **In-App Wallet:** Users can create an in-app wallet that can be funded and used to place wagers. It can be easily funded and withdrawn from using existing wallets such as Argent and Braavos. 🚧
- **Create/Join Wagers:** All operations are securely handled through smart contracts. 🚧
- **Invite Others:** Invite other users to join a wager. 🚧
- **Fair Distribution:** Rewards are distributed proportionally based on the stake. 🚧

## 🛠 Technology Stack
- **Smart Contracts:** Cairo (StarkNet's native smart contract language)
- **Blockchain:** StarkNet

## 🚀 Getting Started
Follow the steps below to set up, build, and test the StarkWager smart contracts locally:

### 1. Install Dependencies
The project uses `scarb` as the package manager for Cairo. 

#### Option 1: Using ASDF
```bash
asdf plugin add scarb
asdf install scarb latest
asdf global scarb latest
```

#### Option 2: Using the Installation Script
Installing via the installation script is the fastest way to get Scarb up and running. This method works on macOS and Linux.

- **To install the latest stable release:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
```

- **To install the latest nightly release:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v nightly
```

- **To install a specific version (e.g., preview or nightly version):**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.10.0-rc.1
```

### 2. Navigating to the Contracts Folder
Before running any `scarb` commands, ensure you are in the contracts directory:

```bash
cd contracts
```

### 3. Building the Contracts
To build the Cairo contracts:

```bash
scarb build
```

The compiled contracts will be located in the `target/dev` directory.

### 4. Formatting Contracts
Ensure consistent code style by formatting the contracts:

```bash
scarb fmt
```

### 5. Running Tests
To run tests for the smart contracts:

```bash
scarb test
```

## 📝 Description
StarkWager simplifies the process of creating and participating in wagers on the blockchain. By leveraging StarkNet's low transaction costs and scalability, it provides a secure and efficient platform for users. The core functionality includes an in-app wallet that can be easily funded and withdrawn from using existing wallets like Argent and Braavos.
