#!/bin/bash

# Check for required commands
if ! command -v yq &> /dev/null; then
    echo "yq command not found, please install yq."
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "gh command not found, please install GitHub CLI."
    exit 1
fi

# Check if the correct number of parameters are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <repository> <branch> <base_url>"
    echo "Example: $0 mmontes11/test gh-pages https://helm.mariadb.com/mariadb-operator/"
    exit 1
fi

REPO=$1
BRANCH=$2
export BASE_URL=$3

# Clone the repository and switch to the specified branch
git clone https://github.com/$REPO.git
cd $(basename "$REPO")
git checkout $BRANCH
git config user.email "martin11lrx@gmail.com"
git config user.name "Martin Montes"

# Update the index.yaml file using yq
yq e -i '.entries.mariadb-operator[] |= . * {"urls": [env(BASE_URL) + .version]}' index.yaml

# Commit the changes and push to a new branch
NEW_BRANCH="update-index-$(date +%s)"
git checkout -b $NEW_BRANCH
git add index.yaml
git commit -m "Update helm index.yaml with new URL"
git push origin $NEW_BRANCH

# Create a pull request using gh CLI
gh pr create --title "Update helm index.yaml with new URL" --body "This PR updates the urls field in index.yaml with the new base URL." --base $BRANCH --head $NEW_BRANCH

echo "Pull request created successfully."