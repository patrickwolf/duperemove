#!/bin/bash
set -e # Exit immediately if a command fails

# --- Distribution Check ---
# Check if this is a Debian-based system (e.g., Ubuntu, Debian, Mint)
if [ ! -f /etc/debian_version ]; then
    echo "This script is intended for Debian-based Linux distributions (e.g., Ubuntu, Debian)."
    echo "It uses 'apt-get' for package management, which is not available on this system."
    echo "Please adapt the script for your distribution's package manager."
    exit 1
fi

# --- Configuration ---
# Define the version/tag to clone
DUPEREMOVE_TAG="v0.15.1"
# The version number without the 'v' prefix, as expected by the Makefile for a release
DUPEREMOVE_VERSION_NUM="0.15.1"
REPO_URL="https://github.com/markfasheh/duperemove.git"
CLONE_DIR="duperemove" # Directory name after cloning

# --- Script ---
# Note: This script assumes it is run with root privileges if 'sudo' is omitted from commands.
# If you are not running as root, 'apt-get' and 'make install' will likely fail.

echo "Updating package lists..."
# Using apt-get instead of apt, and removed sudo
apt-get update -qq

echo "Installing dependencies..."
# Using apt-get instead of apt, and removed sudo
# git is still needed for cloning
# Changed to linux-headers-generic for Docker compatibility
# Added pandoc for man page generation
apt-get install -y -qq build-essential git pkg-config uthash-dev libglib2.0-dev libsqlite3-dev libattr1-dev linux-headers-generic libxxhash-dev libbsd-dev uuid-dev libmount-dev libblkid-dev pandoc

echo "Cloning duperemove repository (full clone)..."
# Remove existing clone directory to prevent errors if run multiple times
rm -rf "${CLONE_DIR}"

# Perform a full clone
git clone "${REPO_URL}" "${CLONE_DIR}"
if [ $? -ne 0 ]; then
  echo "Failed to clone repository. Exiting."
  exit 1
fi

# Navigate into the cloned directory
cd "${CLONE_DIR}" || { echo "Failed to cd into ${CLONE_DIR}. Exiting."; exit 1; }

echo "Checking out tag ${DUPEREMOVE_TAG}..."
# Checkout the specific tag into a new local branch
git checkout "tags/${DUPEREMOVE_TAG}" -b "${DUPEREMOVE_TAG}-branch"
if [ $? -ne 0 ]; then
  echo "Failed to checkout tag ${DUPEREMOVE_TAG}. Exiting."
  exit 1
fi

echo "Compiling duperemove..."
# Pass VERSION and IS_RELEASE to make to prevent it from trying to use git describe.
# This is important as the .git directory might not be in the expected state
# or accessible in all build environments after specific checkouts.
make -s VERSION="${DUPEREMOVE_VERSION_NUM}" IS_RELEASE=1

echo "Running tests..."
# Also pass version info to make test, as it might re-invoke parts of the build
make -s test VERSION="${DUPEREMOVE_VERSION_NUM}" IS_RELEASE=1

echo "Installing duperemove..."
# Removed sudo from make install. This requires the script to be run with root privileges.
# The Makefile uses pandoc to generate man pages, so it's needed for 'make install'.
make -s install VERSION="${DUPEREMOVE_VERSION_NUM}" IS_RELEASE=1

echo "Duperemove ${DUPEREMOVE_TAG} build and installation complete."

echo "Cleaning up cloned repository..."
# Go back to the parent directory before removing the clone directory
cd ..
rm -rf "${CLONE_DIR}"
echo "Cleanup complete."
