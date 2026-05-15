function dr_func() {
  local repo_path="$PWD"
  local repo_name="${PWD:t}"

  if [[ "$repo_path" == "$HOME" || "$repo_path" == "/" ]]; then
    echo "Refusing to delete $repo_path"
    return 1
  fi

  printf "Delete %s? [y/N] " "$repo_path"
  local reply
  read -r reply
  echo

  if [[ "$reply" != [Yy] ]]; then
    echo "Cancelled."
    return 1
  fi

  cd .. || return 1
  rm -rf -- "$repo_name"
  echo "Deleted $repo_name"
  ls
}

function ga() { ge && gl && gcam "$@" && gpsup; }
function gu() { ge && gpsup; }

function gc_func() {
  if [[ -z "$1" ]]; then
    echo "Usage: gc <repository-url>"
    return 1
  fi

  cd "$HOME/Developer" || {
    echo "Failed to navigate to ~/Developer"
    return 1
  }

  local repo_url="$1"
  local repo_name="${repo_url:t}"
  repo_name="${repo_name%.git}"

  if [[ -d "$repo_name" ]]; then
    if [[ -d "$repo_name/.git" ]]; then
      echo "Repository '$repo_name' already exists. Pulling latest changes..."
      cd "$repo_name" || return 1
      git pull || {
        echo "Error during git pull"
        return 1
      }
    else
      echo "Directory '$repo_name' exists but is not a Git repository."
      echo "Please remove the directory or rename it."
      return 1
    fi
  else
    echo "Cloning repository..."
    git clone "$repo_url" || {
      echo "Error during git clone"
      return 1
    }
    cd "$repo_name" || return 1
  fi

  echo "Installing dependencies..."
  i || {
    echo "Failed to install dependencies"
    return 1
  }

  echo "Operation completed successfully."
}

function dev() {
  if [[ ! -f "package.json" ]]; then
    echo "No package.json found in the current directory."
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to inspect package.json scripts."
    return 1
  fi

  local script_to_run=""
  if jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
    script_to_run="dev"
  elif jq -e '.scripts.start' package.json >/dev/null 2>&1; then
    script_to_run="start"
  elif jq -e '.scripts.storybook' package.json >/dev/null 2>&1; then
    script_to_run="storybook"
  fi

  if [[ -n "$script_to_run" ]]; then
    echo "Running pnpm $script_to_run..."
    pnpm "$script_to_run" || {
      echo "Failed to run pnpm $script_to_run"
      return 1
    }
    return 0
  fi

  echo "No valid script (dev, start, storybook) found in package.json."
  return 1
}

function i() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "This is not a git repository."
    return 1
  fi

  if ! command -v pnpm >/dev/null 2>&1; then
    echo "pnpm is not installed. Please install pnpm and try again."
    return 1
  fi

  if pnpm list --depth 0 >/dev/null 2>&1; then
    echo "Dependencies are already installed."
  else
    echo "Installing dependencies..."
    pnpm install || {
      echo "Failed to install dependencies"
      return 1
    }
  fi

  echo "Opening project in Cursor..."
  cursor . || {
    echo "Failed to open project in Cursor"
    return 1
  }

  echo "Starting the dev server..."
  dev || {
    echo "Failed to start the dev server"
    return 1
  }

  echo "Project setup complete."
}

mg() { mkdir "$@" && cd "$@" || return 1; }
cdl() { cd "$@" && ls; }

function quit() {
  if [[ -z "$1" ]]; then
    echo "Usage: quit appname"
    return 1
  fi

  local appname
  for appname in "$@"; do
    osascript -e "quit app \"$appname\""
  done
}

function passwordGenerator() {
  local command_path="$DOTFILES_ROOT/bin/pg"

  if [[ ! -x "$command_path" ]]; then
    echo "Error: No se encontró el comando ejecutable en $command_path"
    return 1
  fi

  "$command_path" "$@"
}

function up() {
  echo "Updating Homebrew..."
  brew update || {
    echo "Error during brew update"
    return 1
  }

  echo "Upgrading formulae..."
  brew upgrade || {
    echo "Error during brew upgrade"
    return 1
  }

  echo "Upgrading casks..."
  brew upgrade --cask bruno chatgpt claude-code clickup codex codex-app cursor dash discord docker-desktop figma firefox github google-chrome hiddenbar itsycal keepingyouawake keka linear-linear loom maccy microsoft-auto-update microsoft-outlook microsoft-teams raycast warp whatsapp workflowy zoom || {
    echo "Error during brew cask upgrade"
    return 1
  }

  echo "Cleaning up..."
  brew cleanup || {
    echo "Error during brew cleanup"
    return 1
  }

  echo "All done!"
}

_cc_require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Falta '$1'"; return 1; }; }

_cc_getvar() {
  local var_name="$1"
  if [[ -n ${parameters[(I)$var_name]} ]]; then
    eval "print -r -- \${$var_name}"
  else
    print -r -- ""
  fi
}

_cc_ask() {
  local __name="$1" __prompt="$2" __def="${3-}" __val
  __val="$(_cc_getvar "$__name")"
  if [[ -z "$__val" ]]; then
    if [[ -n "$__def" ]]; then
      read -r "__val?$__prompt [$__def]: "
      [[ -z "$__val" ]] && __val="$__def"
    else
      read -r "__val?$__prompt: "
    fi
  fi
  typeset -g "$__name=$__val"
}

function gcc_func() {
  emulate -L zsh
  set -o pipefail

  local EMO_WAIT="🕗" EMO_OK="✅" EMO_ERR="❌"
  local -a SPIN_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

  local -a S_LABELS=(
    "📦 Creando repositorio en GitHub"
    "📁 Navegando a carpeta Developer"
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
  local -a S_EMO=()
  local i
  for ((i = 1; i <= ${#S_LABELS[@]}; i++)); do
    S_EMO+="$EMO_WAIT"
  done

  render() {
    printf '\e[2J\e[H'
    local i
    for i in {1..${#S_LABELS[@]}}; do
      print -r -- "${S_EMO[i]} ${S_LABELS[i]}"
    done
  }

  spin_until_done() {
    local idx="$1" pid="$2" frame=1
    while kill -0 "$pid" >/dev/null 2>&1; do
      S_EMO[idx]="${SPIN_FRAMES[frame]}"
      render
      ((frame = frame % ${#SPIN_FRAMES[@]} + 1))
      sleep 0.09
    done
    wait "$pid"
  }

  run_step() {
    local idx="$1"
    shift
    local st

    if [[ "$*" == *"git clone"* || "$*" == *"git push"* || "$*" == *"git remote"* || "$*" == "cd "* ]]; then
      S_EMO[idx]="${SPIN_FRAMES[1]}"
      render
      if eval "$@"; then
        st=0
      else
        st=$?
      fi
    else
      ( eval "$@" ) >/dev/null 2>&1 &
      local pid=$!
      spin_until_done "$idx" "$pid"
      st=$?
    fi

    if ((st == 0)); then
      S_EMO[idx]="$EMO_OK"
      render
      return 0
    fi

    S_EMO[idx]="$EMO_ERR"
    render
    print -r -- ""
    print -r -- "Paso $idx falló: $*"
    return "$st"
  }

  run_ok() {
    local idx="$1"
    S_EMO[idx]="${SPIN_FRAMES[1]}"
    render
    sleep 0.15
    S_EMO[idx]="$EMO_OK"
    render
  }

  local SRC_URL="${1-}" REPO_DESC="${2-}" COURSE_NAME="${3-}" COURSE_URL="${4-}"

  _cc_ask SRC_URL "URL del repo origen (SSH)" "git@github.com:epicweb-dev/advanced-mcp-features.git"
  _cc_ask REPO_DESC "Descripción para el repo nuevo" "EpicAI Advanced MCP Features"
  _cc_ask COURSE_NAME "Nombre del curso" "Advanced MCP Features"
  _cc_ask COURSE_URL "URL del curso" "https://www.epicai.pro/workshops/day-3-4-advanced-mcp-features"

  local REPO_NAME="${SRC_URL:t:r}"
  local CODE_DIR="${CODE_DIR:-$HOME/Developer}"
  mkdir -p -- "$CODE_DIR"

  _cc_require_cmd gh || return 1
  _cc_require_cmd git || return 1
  _cc_require_cmd sed || return 1
  _cc_require_cmd npm || return 1

  local GH_USER
  GH_USER="$(gh api user -q .login 2>/dev/null || true)"
  [[ -n "$GH_USER" ]] || {
    echo "Autentícate: gh auth login"
    return 1
  }

  local DEST_SSH="git@github.com:${GH_USER}/${REPO_NAME}.git"

  render

  if gh repo view "${GH_USER}/${REPO_NAME}" >/dev/null 2>&1; then
    run_ok 1
  else
    run_step 1 "gh repo create '${GH_USER}/${REPO_NAME}' --public --description \"${REPO_DESC}\"" || return $?
  fi

  run_step 2 "cd '$CODE_DIR'" || return $?

  if [[ -d "$CODE_DIR/$REPO_NAME/.git" ]]; then
    run_ok 3
  else
    run_step 3 "git clone '$SRC_URL' '$REPO_NAME'" || return $?
  fi

  run_step 4 "cd '$CODE_DIR/$REPO_NAME'" || return $?

  ( npm run setup >/dev/null 2>&1 ) &
  spin_until_done 5 $!
  S_EMO[5]="$EMO_OK"
  render

  run_step 6 "git remote set-url origin '$DEST_SSH' || git remote add origin '$DEST_SSH'" || return $?
  run_step 7 "rm -rf .github || true" || return $?

  if [[ -f .gitignore ]]; then
    run_step 8 "sed -i '' '/\/playground/d' .gitignore || true" || return $?
  else
    run_ok 8
  fi

  (
    local TMP
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
    if [[ -f README.md ]]; then
      cat "$TMP" README.md > "${TMP}.all" && mv "${TMP}.all" README.md
    else
      mv "$TMP" README.md
    fi
  ) &
  spin_until_done 9 $!
  (( $? == 0 )) && S_EMO[9]="$EMO_OK" || {
    S_EMO[9]="$EMO_ERR"
    render
    echo "Fallo al escribir README"
    return 1
  }
  render

  run_step 10 "git add -A && ( git diff --cached --quiet || ( git commit -m 'Config' && git push -u origin main ) || ( git branch -M main && git push -u origin main ) )" || return $?

  ( command -v cursor >/dev/null 2>&1 && cursor . ) >/dev/null 2>&1 &
  spin_until_done 11 $!
  S_EMO[11]="$EMO_OK"
  render

  ( npm run -s | grep -qE ' dev$' && npm run dev ) >/dev/null 2>&1 &
  spin_until_done 12 $!
  S_EMO[12]="$EMO_OK"
  render

  print -r -- ""
  print -r -- "Listo, mi pana. Repo: ${GH_USER}/${REPO_NAME}"
  return 0
}
