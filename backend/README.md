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

```env
# GENERAL CONFIG
NODE_ENV=development
SERVER_PORT=8080

# JWT CONFIG
JWT_SECRET=
REFRESH_TOKEN_SECRET=

# REDIS CONFIG
REDIS_HOST=
REDIS_PORT=
REDIS_PASSWORD=
REDIS_USERNAME=

# OTP CONFIG
OTP_SECRET=

# SENDGRID CONFIG
SEND_GRID_HOST=
SENDGRID_API_KEY=
SEND_GRID_MAIL_FROM=
SEND_GRID_PSD=
SEND_GRID_USERNAME=

# POSTGRES DB CONFIG
POSTGRES_USER=postgres     ## DATABASE USERNAME
POSTGRES_PASSWORD=strongpassword   ## DATABASE PASSWORD
POSTGRES_DB_NAME=starkwager-backend_db  ## DATABASE NAME / DOCKER CONTAINER NAME
POSTGRES_DB_SCHEMA=wager    ## POSTGRES SCHEMA NAME

## Use this when running on docker container.
POSTGRES_DB_HOST=${POSTGRES_DB_NAME}

## Use this when running locally.
# POSTGRES_DB_HOST=localhost  ## POSTGRES HOST WITHOUT DOCKER ##NB To run migration when model change you can uncomment this so prisma can see your postgress on localhost.

POSTGRES_DB_PORT=5432       ## DEFAULT POSTGRES PORT

# PRISMA POSTGRES DATABASE CONNECTION
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_DB_HOST}:${POSTGRES_DB_PORT}/${POSTGRES_DB_NAME}?schema=${POSTGRES_DB_SCHEMA}&sslmode=prefer
```

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

## Migrations

To apply database migrations when running in Docker:

1. Ensure your Docker containers are up and running using `pnpm docker:dev`.
2. Open another terminal and navigate to the `backend` folder.
3. Run the following command to apply migrations:

```bash
pnpm migrate:dev
```

Once the migration is successful, restart your Docker containers for the changes to take effect.

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
