#!/bin/bash

# SFTP connection details for downloading the backup file
SFTP_SERVER="ssh.strato.de"
SFTP_USER="ribeiromaier.de"
SFTP_KEY="~/.ssh/id_rsa" # Use the private key for authentication
SFTP_DIR="librechat-backup/"
# MongoDB Docker container details
MONGO_CONTAINER_NAME="chat-mongodb"
MONGO_DATABASE="LibreChat"

# Backup directory
BACKUP_DIR_CONTAINER="/data/dump/"
BACKUP_DIR_HOST="./dump/"

echo "Preparing to download the backup file..."

# SSH to the SFTP server and list backup files, sort them, and pick the newest
NEWEST_BACKUP_FILE=$(ssh -i "$SFTP_KEY" "$SFTP_USER@$SFTP_SERVER" "ls -t $SFTP_DIR/mongo-dump-*.gz | head -n1")

# Check if a newest file was found
if [ -z "$NEWEST_BACKUP_FILE" ]; then
    echo "No backup files found."
    exit 1
fi

REMOTE_BACKUP_FILE=$(basename "$NEWEST_BACKUP_FILE")
LOCAL_BACKUP_FILE="$BACKUP_DIR_HOST$REMOTE_BACKUP_FILE"

# Download the backup file from the remote server using SCP (SFTP does not support direct file downloading via command line)
scp -i "$SFTP_KEY" "$SFTP_USER@$SFTP_SERVER:$SFTP_DIR$REMOTE_BACKUP_FILE" "$LOCAL_BACKUP_FILE"

# Check if the download was successful
if [ ! -f "$LOCAL_BACKUP_FILE" ]; then
    echo "Failed to download backup file."
    exit 1
fi

echo "Backup file downloaded successfully."

# Restore directory to MongoDB inside Docker
echo "Starting restoration process..."
docker exec "$MONGO_CONTAINER_NAME" bash -c "mongorestore --gzip --drop --archive=$BACKUP_DIR_CONTAINER$REMOTE_BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "MongoDB has been successfully restored."
else
    echo "Failed to restore MongoDB."
    exit 1
fi

echo "Cleanup complete."
