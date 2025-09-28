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
alias zsh="cursor ~/.zshrc";
alias reload="source ~/.zshrc";
alias de="cd ~/Desktop && ls";
alias co="cd ~/code && ls";
alias gc="gc_func";
alias gcc="gcc_func";
alias dr="dr_func";
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app';
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app';
alias deleteDSFiles="find . -name '.DS_Store' -type f -delete";
alias pgen="passwordGenerator";
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
  echo "Opening project in Cursor..."
  cursor . || { echo "Failed to open project in VS Code"; return 1; }
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

function passwordGenerator() {
  local venv_path=".venv/bin/activate"
  local script_path="./gp.py"
  local current_dir=$(pwd)

  cd ~/

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

  # Ejecutar script con o sin flag
  if [[ "$1" == "-s" || "$1" == "--special" ]]; then
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
  if ! brew upgrade --cask chatgpt cursor dash discord figma raycast firefox github google-chrome hiddenbar itsycal keepingyouawake keka linear-linear loom maccy microsoft-auto-update microsoft-teams steam visual-studio-code warp whatsapp workflowy zoom; then
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

gcc_func() {
	set -euo pipefail

	# ── Emojis/frames ────────────────────────────────────────────────────────
	EMO_WAIT="🕗"   # en espera
	EMO_OK="✅"     # listo
	EMO_ERR="❌"    # falló
	SPIN_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

	# ── Helpers ──────────────────────────────────────────────────────────────
	require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Falta '$1'"; exit 1; }; }

	ask() {
		local var_name="$1" prompt="$2" default="${3:-}"
		local value="${!var_name:-}"
		if [ -z "${value}" ]; then
			if [ -n "$default" ]; then
				read -r -p "$prompt [$default]: " value; value="${value:-$default}"
			else
				read -r -p "$prompt: " value
			fi
			eval "$var_name=\"\$value\""
		fi
	}

	render() {
		clear
		for i in "${!S_LABELS[@]}"; do
			printf "%s %s\n" "${S_EMO[$i]}" "${S_LABELS[$i]}"
		done
	}

	mark_wait_all() { for i in "${!S_LABELS[@]}"; do S_EMO[$i]="$EMO_WAIT"; done; }

	spin_until_done() {
		# $1 = idx, $2 = pid
		local idx="$1" pid="$2" frame=0
		while kill -0 "$pid" >/dev/null 2>&1; do
			S_EMO[$idx]="${SPIN_FRAMES[$frame]}"
			render
			frame=$(( (frame + 1) % ${#SPIN_FRAMES[@]} ))
			sleep 0.09
		done
		wait "$pid"
	}

	run_step() {
		# $1 = idx, $2.. = comando (string eval)
		local idx="$1"; shift
		# arrancar en background
		( eval "$@" ) >/dev/null 2>&1 &
		local pid=$!
		spin_until_done "$idx" "$pid"
		local status=$?
		if [ $status -eq 0 ]; then
			S_EMO[$idx]="$EMO_OK"; render
		else
			S_EMO[$idx]="$EMO_ERR"; render
			echo; echo "Paso $((idx+1)) falló con: $*"
			exit $status
		fi
	}

	run_step_inline_ok() {
		# para pasos triviales (sin comando), solo mostrar OK con refresh
		local idx="$1"
		S_EMO[$idx]="${SPIN_FRAMES[0]}"; render
		sleep 0.15
		S_EMO[$idx]="$EMO_OK"; render
	}

	# ── Inputs ───────────────────────────────────────────────────────────────
	SRC_URL="${1-}"
	REPO_DESC="${2-}"
	COURSE_NAME="${3-}"
	COURSE_URL="${4-}"

	ask SRC_URL "URL del repo origen (SSH)" "git@github.com:epicweb-dev/advanced-mcp-features.git"
	ask REPO_DESC "Descripción para el repo nuevo" "EpicAI Advanced MCP Features"
	ask COURSE_NAME "Nombre del curso" "Advanced MCP Features"
	ask COURSE_URL "URL del curso" "https://www.epicai.pro/workshops/day-3-4-advanced-mcp-features"

	REPO_NAME="$(basename -s .git "$SRC_URL")"
	CODE_DIR="${CODE_DIR:-"$HOME/code"}"
	mkdir -p "$CODE_DIR"

	require_cmd gh; require_cmd git; require_cmd sed; require_cmd npm

	GH_USER="$(gh api user -q .login 2>/dev/null || true)"
	[ -n "$GH_USER" ] || { echo "Autentícate primero: gh auth login"; exit 1; }
	DEST_SSH="git@github.com:${GH_USER}/${REPO_NAME}.git"

	# ── Plan (labels) ────────────────────────────────────────────────────────
	S_LABELS=(
		"📦 Creando repositorio en GitHub"
		"📁 Navegando a carpeta code"
		"🧬 Clonar repositorio"
		"📂 Entrar al repo"
		"⚙️  Setup (npm run setup)"
		"🔗 Reapuntar remoto"
		"🧹 Limpiar CI (.github)"
		"📝 Ajustar .gitignore (/playground)"
		"📚 Añadir aviso al README"
		"📤 Push inicial a main"
		"💻 Abrir en Cursor"
		"🚀 Levantar dev"
	)
	declare -a S_EMO
	mark_wait_all
	render

	# 0) Crear repo (idempotente)
	if gh repo view "${GH_USER}/${REPO_NAME}" >/dev/null 2>&1; then
		run_step_inline_ok 0
	else
		run_step 0 "gh repo create '${GH_USER}/${REPO_NAME}' --public --description \"${REPO_DESC}\""
	fi

	# 1) Navegar a code
	run_step 1 "cd '$CODE_DIR'"

	# 2) Clonar
	if [ -d "$CODE_DIR/$REPO_NAME/.git" ]; then
		run_step_inline_ok 2
	else
		run_step 2 "git clone '$SRC_URL' '$REPO_NAME'"
	fi

	# 3) Entrar
	run_step 3 "cd '$CODE_DIR/$REPO_NAME'"

	# 4) npm run setup (best-effort)
	( npm run setup >/dev/null 2>&1 ) &
	spin_until_done 4 $!
	if [ $? -eq 0 ]; then S_EMO[4]="$EMO_OK"; else S_EMO[4]="$EMO_OK"; fi
	render

	# 5) Reapuntar remoto
	run_step 5 "git remote set-url origin '$DEST_SSH' || git remote add origin '$DEST_SSH'"

	# 6) Limpiar CI
	run_step 6 "rm -rf .github || true"

	# 7) Ajustar .gitignore
	if [ -f ".gitignore" ]; then
		run_step 7 "sed -i '' '/\/playground/d' .gitignore || true"
	else
		run_step_inline_ok 7
	fi

	# 8) Preprender aviso al README
	(
		TMP="$(mktemp)"
		cat > "$TMP" <<EOF
> ## 🚨 Important Notice
>
> This repository is a clone of the
> [${COURSE_NAME}](${COURSE_URL})
> by EpicAI. It has been published solely to document my GitHub activity
> and for personal educational purposes.
>
> **Note:** This is not an official fork or a maintained derivative of the
> original project.

EOF
		if [ -f README.md ]; then
			cat "$TMP" README.md > "${TMP}.all" && mv "${TMP}.all" README.md
		else
			mv "$TMP" README.md
		fi
	) &
	spin_until_done 8 $!
	[ $? -eq 0 ] && S_EMO[8]="$EMO_OK" || S_EMO[8]="$EMO_ERR"; render
	[ "${S_EMO[8]}" = "$EMO_ERR" ] && { echo; echo "Fallo al escribir README"; exit 1; }

	# 9) Commit + push main
	(
		git add -A || true
		if git diff --cached --quiet; then
			exit 0
		else
			git commit -m 'Config' || true
			git push -u origin main || {
				CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
				[ "$CUR_BRANCH" = "main" ] || git branch -M main || true
				git push -u origin main || true
			}
		fi
	) &
	spin_until_done 9 $!
	[ $? -eq 0 ] && S_EMO[9]="$EMO_OK" || S_EMO[9]="$EMO_ERR"; render
	[ "${S_EMO[9]}" = "$EMO_ERR" ] && { echo; echo "Fallo el push"; exit 1; }

	# 10) Abrir Cursor
	( if command -v cursor >/dev/null 2>&1; then cursor .; fi ) >/dev/null 2>&1 &
	spin_until_done 10 $!
	S_EMO[10]="$EMO_OK"; render

	# 11) Levantar dev (si existe script)
	( if npm run -s | grep -qE ' dev$'; then npm run dev; fi ) >/dev/null 2>&1 &
	spin_until_done 11 $!
	S_EMO[11]="$EMO_OK"; render

	echo
	echo "Listo, pues. Repo: ${GH_USER}/${REPO_NAME}"
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
