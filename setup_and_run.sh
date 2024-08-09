#!/bin/bash

# Step 1: Install Node.js and npm if not already installed
echo "Checking for Node.js installation..."
if ! command -v node &> /dev/null
then
    echo "Node.js not found. Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js is already installed."
fi

# Step 2: Create a temporary directory for the script
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Step 3: Create package.json and install dependencies
echo "Setting up the environment..."
npm init -y
npm install @solana/web3.js bs58 readline

# Step 4: Create the Solana transaction script
cat <<EOL > solana_send.js
const solanaWeb3 = require('@solana/web3.js');
const bs58 = require('bs58');
const readline = require('readline');

async function main() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    // Ask for wallet private key
    const privateKey = await new Promise((resolve) => {
        rl.question('Enter your wallet private key: ', resolve);
    });

    // Ask for recipient address
    const recipientAddress = await new Promise((resolve) => {
        rl.question('Enter recipient address: ', resolve);
    });

    rl.close();

    // Decode the private key
    const keypair = solanaWeb3.Keypair.fromSecretKey(bs58.decode(privateKey));

    // Connect to the network
    const connection = new solanaWeb3.Connection(
        "https://devnet.sonic.game", // Updated RPC URL
        'confirmed'
    );

    // Create the transaction
    for (let i = 0; i < 101; i++) {
        const transaction = new solanaWeb3.Transaction().add(
            solanaWeb3.SystemProgram.transfer({
                fromPubkey: keypair.publicKey,
                toPubkey: new solanaWeb3.PublicKey(recipientAddress),
                lamports: 10000 //  SOL (1 SOL = 10^9 lamports)
            })
        );

        // Send the transaction
        const signature = await solanaWeb3.sendAndConfirmTransaction(
            connection,
            transaction,
            [keypair]
        );

        console.log(\`Transaction \${i + 1} sent: \${signature}\`);
    }
}

main().catch(err => {
    console.error(err);
});
EOL

# Step 5: Run the Solana transaction script
echo "Running the Solana transaction script..."
node solana_send.js

# Step 6: Clean up the temporary directory
cd ..
rm -rf $TEMP_DIR

echo "Script completed."
