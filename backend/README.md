# STARKWAGER - BACKEND ⚔️

**StarkWager** is a decentralized backend service designed to support the **StarkNet** ecosystem, facilitating the management of wagers through secure and efficient smart contract interactions. The backend ensures seamless integration between the blockchain, smart contracts, and the frontend, enabling functionalities such as wallet creation, wager management, and reward distribution.

---

## 🌟 Features

- **Smart Contract Integration**: Interact with Cairo-based smart contracts on StarkNet.
- **User Wallet Management**: Handle user wallets for deposits, withdrawals, and balances.
- **Wager Management**: Create, join, and manage wagers through secure endpoints.
- **Reward Distribution**: Facilitate fair and proportional reward distribution based on stakes.
- **Secure Authentication**: Provide user authentication and authorization for accessing wager-related features.

---

## 🛠️ Technology Stack

- **Smart Contracts**: Cairo (StarkNet's native language)
- **Blockchain**: StarkNet
- **Backend Framework**: Node.js (with NestJS for structure and scalability)
- **Database**: PostgreSQL (with TypeORM for ORM management)
- **Authentication**: JWT-based authentication
- **Cache**: Redis for caching frequently accessed data

---

## Getting Started

To set up and run the StarkWager Backend locally, follow these steps:

### 1. Prerequisites

Ensure the following tools are installed on your system:

- **Docker** (for containerized deployment)
- **Node.js** (v18 or above) and **npm**
- **pnpm** (preferred package manager)

### 2. Clone the Repository

Clone the backend repository from GitHub:

```bash
git clone https://github.com/stakepoint/starkwager-backend.git
cd backend
```

### 3. Configure Environment Variables

Create a `.env` file in the root directory based on the `.env.example` provided. Update the empty fields:


### 4. Run the Project

The project supports running in development or production mode via Docker.

#### Development Mode

Use the following command to start the development environment:

```bash
pnpm docker:dev
```

This command will build and start the development containers using the `docker-compose.dev.yml` configuration file.

#### Production Mode

To run the project in production mode:

```bash
pnpm docker:prod
```

This will use the `docker-compose.prod.yml` configuration file to build and start the production containers.

#### Stopping Containers

To stop and remove containers, use:

- For development:

```bash
pnpm docker:down:dev
```

- For production:

```bash
pnpm docker:down:prod
```

- To stop all environments:

```bash
pnpm docker:down:all
```

---

## API Documentation

The API documentation is available via Swagger after starting the server. Visit:

[http://localhost:8080/api-docs](http://localhost:8080/api-docs)

---

## ♻️ Contributing

We welcome contributions to improve the StarkWager backend. Please follow the [Contribution Guide](https://github.com/stakepoint/starkwager-backend/blob/staging/CONTRIBUTING.md) for detailed instructions.

---

## 📃 License

This project is licensed under the MIT License.

