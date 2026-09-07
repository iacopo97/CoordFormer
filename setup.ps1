# Creates a public GitHub repo from this folder, pushes it, and turns on
# GitHub Pages (branch: main, folder: root).
#
# Requires the GitHub CLI: https://cli.github.com  (or: winget install GitHub.cli)
#
#   gh auth login                                   # once, if you haven't already
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
#
# Change $Repo if you want a different name; the repo name becomes the URL path.

$Repo = "CoordFormer"

function Stop-If-Failed($message) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "FAILED: $message" -ForegroundColor Red
        exit 1
    }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "gh is not installed. Get it from https://cli.github.com or run: winget install GitHub.cli"
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "git is not installed. Get it from https://git-scm.com/download/win"
    exit 1
}

if (-not (Test-Path "index.html")) {
    Write-Host "Run this from the folder containing index.html"
    exit 1
}

gh auth status *> $null
Stop-If-Failed "not logged in to GitHub. Run: gh auth login"

# Git refuses to commit without an identity, and every later step depends on
# that commit existing, so check it up front.
$name  = git config --get user.name
$email = git config --get user.email
if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($email)) {
    Write-Host ""
    Write-Host "Git has no identity set. Run these two commands, then try again:" -ForegroundColor Yellow
    Write-Host '  git config --global user.name "Your Name"'
    Write-Host '  git config --global user.email "your-github-email@example.com"'
    exit 1
}

$User = gh api user --jq .login
Stop-If-Failed "could not read your GitHub username"

if (-not (Test-Path ".git")) { git init -q }
git add .
git commit -qm "CoordFormer project page"
Stop-If-Failed "nothing was committed"
git branch -M main

# --public is what makes Pages available on a free account.
gh repo create $Repo --public --source=. --remote=origin --push
Stop-If-Failed "could not create or push to the repository (does $Repo already exist?)"

# Enable Pages. The second call covers the case where Pages already exists.
gh api -X POST "repos/$User/$Repo/pages" -f "source[branch]=main" -f "source[path]=/" *> $null
if ($LASTEXITCODE -ne 0) {
    gh api -X PUT "repos/$User/$Repo/pages" -f "source[branch]=main" -f "source[path]=/" *> $null
    Stop-If-Failed "repository pushed, but enabling Pages failed. Turn it on under Settings > Pages."
}

Write-Host ""
Write-Host "Repo:  https://github.com/$User/$Repo"
Write-Host "Page:  https://$User.github.io/$Repo/   (live in a minute or two)"
