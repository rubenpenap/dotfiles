# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#!/bin/bash

# ohMyZsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

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

# Source ohMyZsh
source $ZSH/oh-my-zsh.sh

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
alias gc="gc_func";
alias dr="dr_func";
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app';
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app';
alias deleteDSFiles="find . -name '.DS_Store' -type f -delete";
alias gpass="generatePassword";
## git aliases
function dr_func () {
  repo_name=$(basename "$PWD")
  cd ..
  rm -rf $repo_name
  echo "Deleted $repo_name"
  l
}
function ga () { ge && gl && gcam "$@" && gpsup; }
function gu () { ge && gpsup; }
function gc_func () {
  if [ -z "$1" ]; then
    echo "Usage: gc <repository-url>"
    return 1
  fi
  cd ~/code || { echo "Failed to navigate to ~/code"; return 1; }
  repo_url="$1"
  repo_name=$(basename "$repo_url" .git)
  if [ -d "$repo_name" ]; then
    if [ -d "$repo_name/.git" ]; then
      echo "Repository '$repo_name' already exists. Pulling latest changes..."
      cd "$repo_name" || { echo "Failed to navigate to $repo_name"; return 1; }
      git pull || { echo "Error during git pull"; return 1; }
    else
      echo "Directory '$repo_name' exists but is not a Git repository."
      echo "Please remove the directory or rename it."
      return 1
    fi
  else
    echo "Cloning repository..."
    git clone "$repo_url" || { echo "Error during git clone"; return 1; }
    cd "$repo_name" || { echo "Failed to navigate to $repo_name"; return 1; }
  fi
  echo "Installing dependencies..."
  i || { echo "Failed to install dependencies"; return 1; }
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

function generatePassword() {
  local venv_path=".venv/bin/activate"
  local script_path="./gp.py"
  local current_dir=$(pwd)

  cd ~/ && pwd

  if [[ ! -f "$venv_path" ]]; then
    echo "Error: No se encontró el entorno virtual en $venv_path"
    return 1
  fi

  if [[ ! -f "$script_path" ]]; then
    echo "Error: No se encontró el script $script_path"
    return 1
  fi

  # Activar entorno virtual
  source "$venv_path"

  # Ejecutar script
  if [[ -f "$1" ]]; then
		python "$script_path" "$1"
	else
		python "$script_path"
	fi

  # Desactivar entorno virtual
  deactivate

  cd "$current_dir"
}

function up () {
  echo "Updating Homebrew..."
  if ! brew update; then
    echo "Error during brew update"
    return 1
  fi

  echo "Upgrading formulae..."
  if ! brew upgrade; then
    echo "Error during brew upgrade"
    return 1
  fi

  echo "Upgrading casks..."
  if ! brew upgrade --cask caffeine chatgpt cursor dash discord figma raycast firefox github google-chrome hiddenbar itsycal keepingyouawake keka linear-linear loom maccy microsoft-auto-update microsoft-teams steam visual-studio-code warp whatsapp workflowy zoom; then
    echo "Error during brew cask upgrade"
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

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

PATH=~/.console-ninja/.bin:$PATH

export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# pnpm
export PNPM_HOME="/Users/repp.dev/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
