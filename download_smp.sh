#!/bin/bash

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git first."
    exit 1
fi

REPO_URL="https://github.com/sh0tx420/mcinstaller.git"
TEMP_DIR=$(mktemp -d)
REPO_NAME=$(basename "$REPO_URL" .git)

# Clone the repository
echo "Cloning repository from $REPO_URL..."
if ! git clone --recursive "$REPO_URL" "$TEMP_DIR/$REPO_NAME"; then
    echo "Error: Failed to clone repository"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check if install.sh exists
INSTALL_SCRIPT="$TEMP_DIR/$REPO_NAME/install.sh"
if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "Error: install.sh not found in the repository"
    rm -rf "$TEMP_DIR"
    exit 1ls 
fi

# Make install.sh executable and run it
chmod +x "$INSTALL_SCRIPT"
echo "Running install.sh..."

installDir=$(pwd)
cd $TEMP_DIR/$REPO_NAME/

if ! bash "$INSTALL_SCRIPT" -m 1.21.6 -s paper -o $installDir/server -p vanillasmpplus; then
    echo "Error: install.sh failed to execute"
    rm -rf "$TEMP_DIR"
    exit 1
fi

cd $installDir

# Clean up
rm -rf "$TEMP_DIR"
echo "Installation complete and temporary files cleaned up"
