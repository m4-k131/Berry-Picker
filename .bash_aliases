# --- Berry-Picker Crawler Alias ---
# This alias makes it easy to activate the Python virtual environment for the crawler.
alias start_crawler='source ~/venv/crawler/bin/activate'


# --- Quality of Life Functions & Aliases ---

# 1. lswc: Count files/folders in a directory
# Usage:
#   lswc              - Counts all items in the current directory
#   lswc /path/to/dir - Counts all items in the specified directory
#   lswc *.py         - Counts all .py files in the current directory
#   lswc /path/to/dir *.csv - Counts all .csv files in the specified directory
lswc() {
    local target_dir="."
    local pattern="*"

    if [ $# -eq 0 ]; then
        # No arguments: count all in current dir
        command ls -1A . | wc -l
    elif [ $# -eq 1 ]; then
        # One argument: could be a directory or a pattern in the current dir
        if [ -d "$1" ]; then
            command ls -1A "$1" | wc -l
        else
            command ls -1Ad $1 2>/dev/null | wc -l
        fi
    elif [ $# -eq 2 ]; then
        # Two arguments: directory and pattern
        if [ ! -d "$1" ]; then
            echo "Error: Directory '$1' not found."
            return 1
        fi
        # Using a subshell to avoid changing the current directory
        (cd "$1" && command ls -1Ad $2 2>/dev/null | wc -l)
    else
        echo "Usage: lswc [directory] [pattern]"
        return 1
    fi
}


# 2. workon: Easily switch between Python virtual environments
# Usage: workon <venv_name>
workon() {
    local venv_path="$HOME/venv/$1/bin/activate"
    if [ -f "$venv_path" ]; then
        source "$venv_path"
        echo "Activated virtual environment: $1"
    else
        echo "Error: Virtual environment '$1' not found at $HOME/venv/"
        return 1
    fi
}


# 3. OpenVPN Aliases
# NOTE: You may need to adjust the path to your .ovpn configuration file.
alias vpn_start="sudo openvpn --config ~/vpn/config.ovpn --daemon"
alias vpn_stop="sudo killall openvpn"
alias vpn_status="ps aux | grep '[o]penvpn'"


# 4. Screen QoL Alias
# Re-attach to the first available detached screen session
alias sattach='screen -r'

# Checks Raspberry Pi power and thermal status
check_pi() {
    local throttled_code
    throttled_code=$(vcgencmd get_throttled | cut -d'=' -f2)
    local dec_code
    dec_code=$(printf "%d" "$throttled_code")

    echo "----------------------------------------"
    echo "Raspberry Pi Status Check"
    echo "Throttled Code: $throttled_code"
    echo "----------------------------------------"

    if [ "$dec_code" -eq 0 ]; then
        echo "✅ STATUS: OK. No issues detected."
        return
    fi

    echo "⚠️  STATUS: Issues detected!"

    # --- Current Issues (Active Now) ---
    if (( (dec_code & 1) != 0 )); then echo "  - 🚨 Under-voltage NOW"; fi
    if (( (dec_code & 2) != 0 )); then echo "  - 🚨 ARM frequency capped NOW"; fi
    if (( (dec_code & 4) != 0 )); then echo "  - 🚨 Throttled NOW"; fi
    if (( (dec_code & 8) != 0 )); then echo "  - 🔥 Soft temperature limit NOW"; fi

    # --- Historical Issues (Since last boot) ---
    if (( (dec_code & 0x10000) != 0 )); then echo "  - ⚡ Under-voltage HAS occurred"; fi
    if (( (dec_code & 0x20000) != 0 )); then echo "  - ⚡ ARM frequency capping HAS occurred"; fi
    if (( (dec_code & 0x40000) != 0 )); then echo "  - ⚡ Throttling HAS occurred"; fi
    if (( (dec_code & 0x80000) != 0 )); then echo "  - 🌡️ Soft temperature limit HAS occurred"; fi
    echo "----------------------------------------"
}

# To overwrite the log file.
# Usage: tout <logfile> <command> [command_args...]
tout() {
    # Check if we have at least a logfile and a command.
    if [ "$#" -lt 2 ]; then
        echo "Usage: tout <logfile> <command> [args...]" >&2
        return 1
    fi

    local logfile="$1" # The first argument is the log file.
    shift             # Remove the first argument from the list.

    # Now, execute the rest of the arguments ("$@") as the command,
    # with the redirection and pipe applied.
    "$@" 2>&1 | tee "$logfile"
}

# To append to the log file (a for append).
# Usage: touta <logfile> <command> [command_args...]
touta() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: touta <logfile> <command> [args...]" >&2
        return 1
    fi

    local logfile="$1"
    shift

    "$@" 2>&1 | tee -a "$logfile"
}
