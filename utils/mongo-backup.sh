#!/bin/bash

# Set the working directory to the home directory of the current user
cd "$HOME/LibreChat" || exit

# SFTP connection details
SFTP_SERVER="ssh.strato.de"
SFTP_USER="ribeiromaier.de"
SFTP_KEY="~/.ssh/id_rsa"
SFTP_DIR="librechat-backup"
# MongoDB Docker container details
MONGO_CONTAINER_NAME="chat-mongodb"
MONGO_DATABASE="LibreChat"

# Backup directory
BACKUP_DIR_CONTAINER="/data/dump/"
BACKUP_DIR_HOST="./dump/"

# Timestamp for backup file name
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Generate backup file name
BACKUP_FILE="mongo-dump-$TIMESTAMP.gz"

# Take a MongoDB dump from the Docker container
docker exec "$MONGO_CONTAINER_NAME" /bin/sh -c "mongodump --gzip --db "$MONGO_DATABASE" --archive="$BACKUP_DIR_CONTAINER/$BACKUP_FILE""

# Transfer the backup file to the remote server using SFTP
sftp -o "IdentityFile=$SFTP_KEY" "$SFTP_USER@$SFTP_SERVER" << EOF
put "$BACKUP_DIR_HOST$BACKUP_FILE" "$SFTP_DIR"
bye
EOF

# Check if the transfer was successful
if [ $? -eq 0 ]; then
    echo "Backup file transferred successfully."
else
    echo "Failed to transfer backup file."
fi