# First, add all your new and modified files
git status
git add .

# Now, commit the changes with a descriptive message
git commit -m "feat: completed end-to-end AI podcast prep generation workflow"

git branch -M main
git remote add origin https://github.com/akenel/infra-lite.git

# Finally, push your changes to the remote repository
git push -u origin main
git status
