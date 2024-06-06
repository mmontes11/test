#!/bin/bash

set -eo pipefail

install_yq() {
  if ! command -v yq &> /dev/null; then
    echo "yq command not found, installing yq..."
    sudo curl -sSLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.13.4/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
  fi
}
install_yq


if [ -z "$REPO" ]; then 
  echo "REPO environment variable is mandatory"
  exit 1
fi
if [ -z "$BRANCH" ]; then 
  echo "BRANCH environment variable is mandatory"
  exit 1
fi
if [ -z "$BASE_URL" ]; then 
  echo "BASE_URL environment variable is mandatory"
  exit 1
fi
if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN environment variable is mandatory"
  exit 1
fi

export BASE_URL
export GITHUB_TOKEN

git config --global user.email "martin11lrx@gmail.com"
git config --global user.name "Martin Montes"
git clone https://github.com/$REPO.git
cd $(basename "$REPO")
git checkout $BRANCH

yq e -i '.entries.test[] |= . * {"urls": [env(BASE_URL) + .version]}' index.yaml

NEW_BRANCH="update-index-$(date +%s)"
git checkout -b $NEW_BRANCH
git add index.yaml
git commit -m "Update helm index.yaml with new URL"
git push origin $NEW_BRANCH

gh pr create \
  --title "Update helm index.yaml" \
  --body "This PR has been automatically raised after releasing a new helm chart." \
  --base $BRANCH \
  --head $NEW_BRANCH

echo "Pull request created successfully."