# projectbt - Git Submodules (from zero)

This repo is a parent project that contains two Git submodules:
backend/ -> backendbt
frontendclient/ -> frontendclientbt

Links:
backendbt: [https://github.com/Abdlehakim/backendbt.git](https://github.com/Abdlehakim/backendbt.git)
frontendclientbt: [https://github.com/Abdlehakim/frontendclientbt.git](https://github.com/Abdlehakim/frontendclientbt.git)
projectbt (parent): [https://github.com/Abdlehakim/projectbt.git](https://github.com/Abdlehakim/projectbt.git)

Final structure:
projectbt/
  backend/
  frontendclient/
  .gitmodules
  README.md

Requirements:
Create these 3 empty repos on GitHub first: projectbt, backendbt, frontendclientbt
Run commands in Git Bash or PowerShell
Change paths if your folders are not under ~/Desktop/projectbt

STEP 1 - Create the BACKEND repo and push it

cd ~/Desktop/projectbt/backend
git init
git branch -M main
git add .
git commit -m "Initial commit (backend)"
git remote add origin [https://github.com/Abdlehakim/backendbt.git](https://github.com/Abdlehakim/backendbt.git)
git push -u origin main

STEP 2 - Create the FRONTEND repo and push it

cd ~/Desktop/projectbt/frontendclient
git init
git branch -M main
git add .
git commit -m "Initial commit (frontend)"
git remote add origin [https://github.com/Abdlehakim/frontendclientbt.git](https://github.com/Abdlehakim/frontendclientbt.git)
git push -u origin main

STEP 3 - Create the PARENT repo and add submodules

cd ~/Desktop
mkdir projectbt-parent
cd projectbt-parent

git init
git branch -M main
git remote add origin [https://github.com/Abdlehakim/projectbt.git](https://github.com/Abdlehakim/projectbt.git)

git submodule add [https://github.com/Abdlehakim/backendbt.git](https://github.com/Abdlehakim/backendbt.git) backend
git submodule add [https://github.com/Abdlehakim/frontendclientbt.git](https://github.com/Abdlehakim/frontendclientbt.git) frontendclient

echo "projectbt parent repo (with submodules)" > README.md

git add .
git commit -m "Add backend and frontendclient as submodules"
git push -u origin main

STEP 4 - Clone the parent repo with submodules (on any PC)

git clone --recurse-submodules [https://github.com/Abdlehakim/projectbt.git](https://github.com/Abdlehakim/projectbt.git)
cd projectbt

If you already cloned without submodules:
git submodule update --init --recursive

STEP 5 - Daily workflow (update submodules)

Update backend:
cd backend
git checkout main
git pull
cd ..
git add backend
git commit -m "Update backend submodule"
git push

Update frontend:
cd frontendclient
git checkout main
git pull
cd ..
git add frontendclient
git commit -m "Update frontend submodule"
git push

Update both at once:
git submodule update --remote --merge
git add backend frontendclient
git commit -m "Update submodules"
git push

Useful commands:
git submodule status
git submodule update --init --recursive
git config --global submodule.recurse true

Common problems:
If you see "cloned an empty repository", the GitHub repo has no commits yet, do STEP 3 and push
If submodule folders are empty, run: git submodule update --init --recursive
If parent repo shows changes after updating submodules, commit the new submodule pointers and push
