#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/TITAN-OS"
CONFIG="$HOME/.config/titan"
MAN="$HOME/.local/share/man"
COMP="$CONFIG/completion"
BASHRC="$HOME/.bashrc"
STAMP="$(date +%Y%m%d%H%M%S)"

backup() {
    [ ! -e "$1" ] || cp -p "$1" "$1.titan-bak.$STAMP"
}

mkdir -p "$COMP" "$MAN/man1"

# Preserve the user's existing shell configuration.
touch "$BASHRC"
if ! grep -q 'TITAN OS TERMINAL CONFIG' "$BASHRC"; then
    backup "$BASHRC"
    cat >> "$BASHRC" <<'EOF'

# TITAN OS TERMINAL CONFIG
[ -r "$HOME/.config/titan/bashrc" ] && source "$HOME/.config/titan/bashrc"
EOF
fi

# TITAN shell configuration.
cat > "$CONFIG/bashrc" <<'EOF'
# TITAN OS terminal environment
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias tihelp='ti --help'
alias titanhelp='titan --help'

# Load TITAN command completion.
for f in "$HOME"/.config/titan/completion/*; do
    [ -r "$f" ] && source "$f"
done
EOF

# ti completion.
cat > "$COMP/ti" <<'EOF'
_ti_complete() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local commands="add remove search info list update upgrade autoremove clean doctor history repo"
    local repo_commands="list add remove"

    if [[ "$prev" == "repo" ]]; then
        COMPREPLY=( $(compgen -W "$repo_commands" -- "$cur") )
    elif [[ "$COMP_CWORD" -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$commands --help --version -y --yes" -- "$cur") )
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "--help --version -y --yes" -- "$cur") )
    fi
}
complete -F _ti_complete ti
EOF

# titan completion.
cat > "$COMP/titan" <<'EOF'
_titan_complete() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"

    local commands="info status monitor performance battery thermal storage memory cpu gpu processes security network logs doctor"

    if [[ "$COMP_CWORD" -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$commands --help --version" -- "$cur") )
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "--help --once -i -n" -- "$cur") )
    fi
}
complete -F _titan_complete titan
EOF

# Manual page: ti.
cat > "$MAN/man1/ti.1" <<'EOF'
.TH TI 1 "November 2026" "TITAN OS 0.1.0" "User Commands"
.SH NAME
ti \- TITAN OS package management command
.SH SYNOPSIS
.B ti
.I command
.RI [ arguments ]
.SH DESCRIPTION
The ti command provides a unified interface to package management.
.SH COMMANDS
.TP
.B add PACKAGE
Install a package.
.TP
.B remove PACKAGE
Remove a package.
.TP
.B search QUERY
Search available packages.
.TP
.B info PACKAGE
Show package information.
.TP
.B list
List installed packages.
.TP
.B update
Refresh package information.
.TP
.B upgrade
Upgrade installed packages.
.TP
.B autoremove
Remove unused dependencies.
.TP
.B clean
Clean package cache.
.TP
.B doctor
Check package-management health.
.TP
.B history
Show package-management history.
.TP
.B repo
Manage configured repositories.
.SH OPTIONS
.TP
.B --help
Display help.
.TP
.B --version
Display version.
.TP
.B -y, --yes
Assume yes where supported.
.SH AUTHOR
BARATH
EOF

# Manual page: titan.
cat > "$MAN/man1/titan.1" <<'EOF'
.TH TITAN 1 "November 2026" "TITAN OS 0.1.0" "User Commands"
.SH NAME
titan \- TITAN OS system information and management tool
.SH SYNOPSIS
.B titan
.I command
.RI [ options ]
.SH DESCRIPTION
Displays system information and provides supported monitoring and diagnostic commands.
.SH COMMANDS
.TP
.B info
Display system information.
.TP
.B status
Display system status.
.TP
.B monitor
Monitor system information.
.TP
.B performance
Display or select a performance profile.
.TP
.B battery
Display battery information.
.TP
.B thermal
Display thermal information where available.
.TP
.B storage
Display storage information.
.TP
.B memory
Display memory information.
.TP
.B cpu
Display CPU information.
.TP
.B gpu
Display GPU information where available.
.TP
.B processes
Display running processes.
.TP
.B security
Display security checks.
.TP
.B network
Display network information.
.TP
.B logs
Display TITAN logs.
.TP
.B doctor
Run system diagnostics.
.SH AUTHOR
BARATH
EOF

# Manual page: fastfetch.
cat > "$MAN/man1/fastfetch.1" <<'EOF'
.TH FASTFETCH 1 "November 2026" "TITAN OS" "User Commands"
.SH NAME
fastfetch \- display system information
.SH SYNOPSIS
.B fastfetch
.RI [ options ]
.SH DESCRIPTION
Fastfetch displays system information in the terminal.
TITAN OS provides a custom logo and configuration.
.SH EXAMPLES
.TP
.B fastfetch
Display system information.
.TP
.B fastfetch --help
Display available options.
.SH AUTHOR
BARATH
EOF

# Set a user-level manual search path.
if ! grep -q 'TITAN OS MANPATH' "$CONFIG/bashrc"; then
    cat >> "$CONFIG/bashrc" <<'EOF'

# TITAN OS MANPATH
export MANPATH="$HOME/.local/share/man:$PREFIX/share/man"
EOF
fi

# Validate generated shell scripts.
bash -n "$CONFIG/bashrc"
bash -n "$COMP/ti"
bash -n "$COMP/titan"

echo
echo "TITAN OS terminal setup completed."
echo "Restart Termux or run: source ~/.bashrc"
echo "Then try: man ti"
