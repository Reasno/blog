#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Default message
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi

# Commit to main repository
git add .

git pull -X theirs

git commit -a -m "$msg"

git push origin master

# Build the project.
HUGO_ENV=production hugo # if using a theme, replace with `hugo -t <YOURTHEME>`

# Go To Public folder
cd public
# Add changes to git.
git add .

git commit -m "$msg"

# Push source and build repos.
git pull -X theirs
git push origin master

# Come Back up to the Project Root
cd ..
