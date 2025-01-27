StarkWager
StarkWager is a decentralized application (dApp) designed to leverage the StarkNet ecosystem, enabling users to place wagers on simple agreements or competitions with minimal transaction fees. The app ensures a seamless experience for users to deposit, withdraw, and interact with wagers, making it a powerful tool in the StarkNet ecosystem.

🌟 Features
Create Wallet: Get a wallet that can be funded and used to place a wager 🚧

Connect Existing Wallet: Easily fund wagers from already existing wallets (e.g., Argent) 🚧

Create/Join Wagers: All operations are handled through smart contracts 🚧

Invite Others: Invite other users to join a wager 🚧

Fair Distribution: Rewards are distributed proportionally based on stake 🚧

🛠 Technology Stack
Smart Contracts: Cairo (StarkNet's native smart contract language)

Blockchain: StarkNet

Frontend: Next.js

Testing Framework: snforge (for Cairo smart contracts)

Getting Started
To get started with the StarkWager App, follow the instructions below:

1. Install Dependencies
The project uses pnpm as the package manager. First, install pnpm globally:

bash
Copy
npm install -g pnpm
Then install the project dependencies:

bash
Copy
pnpm install
2. Running the Development Server
Start the development server to run the app locally:

bash
Copy
pnpm dev
Your app will be available at http://localhost:3000.

Testing with snforge
To test the Cairo smart contracts, we use snforge, a testing framework for StarkNet smart contracts. Follow the steps below to set up and run tests.

1. Install snforge
If you haven't already, install snforge using the following command:

bash
Copy
cargo install --git https://github.com/foundry-rs/starknet-foundry snforge
Alternatively, you can use starknet-foundry, which includes snforge and other tools:

bash
Copy
cargo install --git https://github.com/foundry-rs/starknet-foundry --profile local --force
Verify the installation by running:

bash
Copy
snforge --version
2. Write Tests
Tests for Cairo smart contracts are written in Cairo itself. Place your test files in the tests directory. For example:

cairo
Copy
// tests/test_wager.cairo
#[test]
fn test_create_wager() {
    // Your test logic here
}
3. Run Tests
To run all tests, use the following command:

bash
Copy
snforge test
This will execute all test files in the tests directory and display the results in the terminal.

Contributing
We welcome contributions from the community! If you'd like to contribute, please follow these steps:

Fork the repository.

Create a new branch (git checkout -b feature/YourFeatureName).

Commit your changes (git commit -m 'Add some feature').

Push to the branch (git push origin feature/YourFeatureName).

Open a pull request.
