#!/bin/bash

export TERM=xterm-256color
export CLICOLOR=1
export LSCOLORS=Fafacxdxbxegedabagacad

# PROMPT STUFF
GREEN=$(tput setaf 2);
YELLOW=$(tput setaf 3);
RESET=$(tput sgr0);

# allow substitution in PS1
setopt promptsubst

# history size
HISTSIZE=5000
HISTFILESIZE=10000

SAVEHIST=5000
setopt EXTENDED_HISTORY
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# share history across multiple zsh sessions
setopt SHARE_HISTORY
# append to history
setopt APPEND_HISTORY
# adds commands as they are typed, not at shell exit
setopt INC_APPEND_HISTORY
# do not store duplications
setopt HIST_IGNORE_DUPS

# PATH ALTERATIONS
PATH="/usr/local/bin:$PATH";

# node_modules 😆 this is *way* faster than using "npm prefix" and it works fine.
PATH="$PATH:./node_modules/.bin:../node_modules/.bin:../../node_modules/.bin:../../../node_modules/.bin:../../../../node_modules/.bin:../../../../../node_modules/.bin:../../../../../../node_modules/.bin:../../../../../../../node_modules/.bin"

# Plugins
plugins=(git)

# Custom bins
PATH="$PATH:$HOME/.bin:$HOME/.local/bin";

# disable https://scarf.sh/
SCARF_ANALYTICS=false

# Custom Aliases
alias pg="echo 'Pinging Google' && ping www.google.com";
alias zsh="code ~/.zshrc";
alias reload="source ~/.zshrc";
alias de="cd ~/Desktop && ls";
alias co="cd ~/code && ls";
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'
alias deleteDSFiles="find . -name '.DS_Store' -type f -delete"

## git aliases
function ga () { ge && gl && gcam "$@" && gpsup; }
function gu () { ge && gpsup; }
function gc () {
  if [ -z "$1" ]; then
    echo "Usage: gc <repository-url>"
    return 1
  fi
  cd ~/code || { echo "Failed to navigate to ~/code"; return 1; }
  repo_name=$(basename "$1" .git)
  if [ -d "$repo_name" ]; then
    echo "Repository '$repo_name' already exists. Pulling latest changes..."
    cd "$repo_name" || { echo "Failed to navigate to $repo_name"; return 1; }
    git pull || { echo "Error during git pull"; return 1; }
  else
    echo "Cloning repository..."
    git clone "$@" || { echo "Error during git clone"; return 1; }
  fi
  echo "Operation completed successfully."
}
function dev () {
  if ! [ -f "package.json" ]; then
    echo "No package.json found in the current directory."
    return 1
  fi
  script_to_run=""
  if jq -e '.scripts.dev' package.json > /dev/null 2>&1; then
    script_to_run="dev"
  elif jq -e '.scripts.start' package.json > /dev/null 2>&1; then
    script_to_run="start"
  elif jq -e '.scripts.storybook' package.json > /dev/null 2>&1; then
    script_to_run="storybook"
  fi
  if [ -n "$script_to_run" ]; then
    echo "Running pnpm $script_to_run..."
    pnpm "$script_to_run" || { echo "Failed to run pnpm $script_to_run"; return 1; }
  else
    echo "No valid script (dev, start, storybook) found in package.json."
    return 1
  fi
}
function i () {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "This is not a git repository."
    return 1
  fi
  if ! command -v pnpm > /dev/null 2>&1; then
    echo "pnpm is not installed. Please install pnpm and try again."
    return 1
  fi
  if pnpm list --depth 0 > /dev/null 2>&1; then
    echo "Dependencies are already installed."
  else
    echo "Installing dependencies..."
    pnpm install || { echo "Failed to install dependencies"; return 1; }
  fi
  echo "Opening project in VS Code..."
  code . || { echo "Failed to open project in VS Code"; return 1; }
  echo "Starting the dev server..."
  dev || { echo "Failed to start the dev server"; return 1; }
  echo "Project setup complete."
}

# Custom functions
mg () { mkdir "$@" && cd "$@" || exit; }
cdl () { cd "$@" && ls; }
function quit () {
  if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: quit appname"
  else
    for appname in $1; do
    osascript -e 'quit app "'$appname'"'
    done
  fi
}
function up () {
  echo "Updating Homebrew..."
  if ! brew update; then
    echo "Error during brew update"
    return 1
  fi
  echo "Upgrading packages..."
  if ! brew upgrade; then
    echo "Error during brew upgrade"
    return 1
  fi
  echo "Cleaning up..."
  if ! brew cleanup; then
    echo "Error during brew cleanup"
    return 1
  fi
  echo "All done!"
}

# zsh auto autocomplete
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
