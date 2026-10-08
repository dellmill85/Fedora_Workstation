
# ============================================================
# ZSH CONFIGURATION — FEDORA KDE
# Oh My Zsh + Starship + Smart Completions
# ============================================================

# ------------------------------------------------------------
# 1. ENVIRONMENT
# ------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

export EDITOR="nano"
export VISUAL="$EDITOR"
export PAGER="less"

export LESS="-R"
export LESSHISTFILE="-"

# Starship manages the prompt, not Oh My Zsh.
ZSH_THEME=""

# Avoid unnecessary automatic terminal title changes.
DISABLE_AUTO_TITLE="true"

# Disable automatic command correction prompts.
ENABLE_CORRECTION="false"

# Don't spend time scanning untracked files for Git prompts.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Oh My Zsh update behavior.
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 14

# ------------------------------------------------------------
# 2. COMMAND HISTORY
# ------------------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# ------------------------------------------------------------
# 3. COMPLETION CONFIGURATION
# ------------------------------------------------------------

# Treat uppercase and lowercase as equivalent.
CASE_SENSITIVE="false"

# Match hyphens and underscores.
HYPHEN_INSENSITIVE="true"

# Show an interactive completion menu.
zstyle ':completion:*' menu select

# Group completions by type.
zstyle ':completion:*' group-name ''

# Add readable group descriptions.
zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'

# Match case-insensitively and allow hyphen/underscore swaps.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[-_]=* r:|=*'

# Use cached completion results.
mkdir -p "$HOME/.cache/zsh"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh"

# Completion selection colors.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ------------------------------------------------------------
# 4. OH MY ZSH PLUGINS
# ------------------------------------------------------------

plugins=(
    git
    sudo
    extract
    colored-man-pages
    command-not-found
    aliases
    web-search
    copyfile
    copybuffer
    dirhistory
    autojump
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Only enable zsh-completions when installed.
if [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions" ]]; then
    plugins+=(zsh-completions)
fi

source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------
# 5. SYNTAX HIGHLIGHTING
# ------------------------------------------------------------

# These styles affect commands as you type them.
# They do not change the colors of program output.

typeset -A ZSH_HIGHLIGHT_STYLES

# Valid commands: bright green.
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'

# Unknown commands: red.
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'

# Paths and directories: green.
ZSH_HIGHLIGHT_STYLES[path]='fg=green,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=green'

# Options and arguments.
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[default]='fg=white'

# Quoted strings.
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'

# Shell operators.
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[assign]='fg=blue'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan,bold'

# Variables.
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=cyan'

# Comments.
ZSH_HIGHLIGHT_STYLES[comment]='fg=bright-black,italic'

# Autosuggestion text: subdued gray.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# ------------------------------------------------------------
# 6. MODERN COMMAND-LINE UTILITIES
# ------------------------------------------------------------

# eza: modern ls replacement.
if (( $+commands[eza] )); then
    alias ls='eza --icons'
    alias ll='eza -lah --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --icons --level=2'
fi

# bat: syntax-highlighted file viewer.
# Keep cat untouched for scripts and raw output.
if (( $+commands[bat] )); then
    alias ccat='bat --paging=never'
    alias preview='bat --style=numbers,changes'
fi

# ------------------------------------------------------------
# 7. NAVIGATION
# ------------------------------------------------------------

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias home='cd "$HOME"'
alias downloads='cd "$HOME/Downloads"'
alias documents='cd "$HOME/Documents"'

# Create a directory and enter it.
mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}

# ------------------------------------------------------------
# 8. FEDORA PACKAGE MANAGEMENT
# ------------------------------------------------------------

alias update='sudo dnf upgrade --refresh'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias searchpkg='dnf search'
alias pkginfo='dnf info'
alias autoremove='sudo dnf autoremove'

# List user-installed packages.
alias mypackages='dnf repoquery --userinstalled'

# ------------------------------------------------------------
# 9. SYSTEM INFORMATION
# ------------------------------------------------------------

alias mem='free -h'
alias disk='df -hT'
alias mounts='findmnt'
alias ports='sudo ss -tulpn'
alias processes='ps aux --sort=-%cpu'
alias uptimeinfo='uptime'

# Network information.
alias myip='ip -brief address'
alias routes='ip route'
alias listening='ss -tuln'

# ------------------------------------------------------------
# 10. GIT SHORTCUTS
# ------------------------------------------------------------

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -15'
alias gd='git diff'
alias gb='git branch'

# ------------------------------------------------------------
# 11. QUALITY-OF-LIFE FUNCTIONS
# ------------------------------------------------------------

# Extract common archives, using the Oh My Zsh extract plugin.
alias unpack='extract'

# Display the largest directories in the current directory.
bigdirs() {
    du -h --max-depth=1 "${1:-.}" 2>/dev/null | sort -hr | head -20
}

# Show the ten largest files under a directory.
bigfiles() {
    find "${1:-.}" -type f -printf '%s\t%p\n' 2>/dev/null |
        sort -nr |
        head -10 |
        numfmt --field=1 --to=iec --suffix=B
}

# Find a running process by name.
psfind() {
    ps aux | grep -i -- "$1" | grep -v '[g]rep'
}

# Quickly edit and reload Zsh configuration.
alias zshconfig='$EDITOR ~/.zshrc'

reloadzsh() {
    exec zsh
}

alias reload='reloadzsh'

# ------------------------------------------------------------
# 12. OPTIONAL INTERACTIVE TOOLS
# ------------------------------------------------------------

# Atuin: searchable command history.
if (( $+commands[atuin] )); then
    eval "$(atuin init zsh)"
fi

# ------------------------------------------------------------
# 13. STARSHIP PROMPT
# ------------------------------------------------------------

if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

# ============================================================
# END OF CONFIGURATION
# ============================================================
