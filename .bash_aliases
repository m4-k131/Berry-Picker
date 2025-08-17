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
