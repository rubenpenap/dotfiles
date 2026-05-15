# ~/.zshrc

export SCHEMA_NAME=template
export DATABASE_USERNAME=repp.dev
export DATABASE_PASSWORD=password
export DATABASE_URL=jdbc:postgresql://127.0.0.1:5432/template?currentSchema=template

export ZSH="$HOME/.oh-my-zsh"
export TERM=xterm-256color
export CLICOLOR=1
export LSCOLORS=Fafacxdxbxegedabagacad
export SCARF_ANALYTICS=false

if command -v tput >/dev/null 2>&1; then
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  RESET="$(tput sgr0)"
else
  GREEN=""
  YELLOW=""
  RESET=""
fi

setopt promptsubst

HISTSIZE=5000
HISTFILESIZE=10000
SAVEHIST=5000
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history

setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS

typeset -g DOTFILES_ROOT="${${(%):-%N}:A:h}"
typeset -U path PATH

for file in \
  "$DOTFILES_ROOT/shell/zsh/path.zsh" \
  "$DOTFILES_ROOT/shell/zsh/runtime.zsh"
do
  [[ -f "$file" ]] && source "$file"
done

plugins=(git)
source "$ZSH/oh-my-zsh.sh"

for file in \
  "$DOTFILES_ROOT/shell/zsh/aliases.zsh" \
  "$DOTFILES_ROOT/shell/zsh/functions.zsh"
do
  [[ -f "$file" ]] && source "$file"
done
