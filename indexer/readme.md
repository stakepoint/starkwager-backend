# Indexer Setup and Execution Guide

This guide will walk you through the steps to set up and run your indexer using Docker. Follow the instructions carefully to ensure a smooth setup process.

## Prerequisites

- Docker installed on your machine.
- Docker Compose installed on your machine.
- Basic familiarity with terminal commands.

## Setup Instructions

1. **Clone the Repository**  
   Ensure you have cloned the repository containing your indexer code.

   ```bash
   git clone <repository-url>
   cd <repository-directory>/indexer
   ```

2. **Environment Configuration**  
   Copy the `indexer.env.example` file to `indexer.env`. This file contains environment variables required for the indexer to function properly.

   ```bash
   cp indexer.env.example indexer.env
   ```

   Edit the `indexer.env` file to include any necessary configurations or secrets.

3. **Start the Indexer**  
   Use Docker Compose to start the indexer. Run the following command in your terminal:

   ```bash
   docker-compose up
   ```

   This will start the indexer and all its dependencies.

4. **Handling BlockNotFound Errors**  
   If you encounter the error `ERROR apibara_starknet::provider: error=BlockNotFound`, it means the indexer is waiting for blocks to be produced. To resolve this, you need to mint a transaction to kickstart block production.

   Open a **new terminal window** and run the following command:

   ```bash
   http POST :5050/mint address=0x0 amount:=50000 unit="FRI"
   ```

   This command will mint a transaction and start block production. Once blocks are being produced, the indexer will begin ingesting them.

5. **Verify Indexer Operation**  
   After running the mint command, return to the terminal where the indexer is running. You should see logs indicating that the indexer is processing blocks.

## Troubleshooting

- **Docker Compose Issues**: Ensure Docker and Docker Compose are installed correctly and running.
- **BlockNotFound Persists**: If the error persists after minting, ensure the StarkNet devnet is running and accessible.
- **Environment Variables**: Double-check the `indexer.env` file to ensure all required variables are set correctly.

## Stopping the Indexer

To stop the indexer, press `Ctrl+C` in the terminal where the indexer is running. Alternatively, you can stop all Docker containers with:

```bash
docker-compose down
```

## Conclusion

You have successfully set up and run your indexer! If you encounter any issues, refer to the troubleshooting section or consult the documentation for the tools you are using (e.g., Docker, Apibara, StarkNet). Happy indexing!