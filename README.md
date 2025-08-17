# 🍓 Berry-Picker

A bash script to quickly configure a Raspberry Pi for web crawling and scraping. It automates the installation of Python, Selenium, Firefox, and other required dependencies, and adds several quality-of-life shell functions.

---

## Installation

Choose one of enlightningthe following methods to get started.

### Method 1: Using `curl` + `unzip` (Recommended)

This method is ideal for a fresh Raspberry Pi OS installation, as it uses pre-installed tools.

1.  **Download the repository:**
    ```bash
    curl -LO https://github.com/m4-k131/Berry-Picker/archive/refs/heads/main.zip
    ```

2.  **Unzip the file:**
    ```bash
    unzip main.zip
    ```

3.  **Navigate into the directory:**
    *Note: The directory will be named `Berry-Picker-main`.*
    ```bash
    cd Berry-Picker-main
    ```

4.  **Proceed to the Configuration step below.**

### Method 2: Using `git`

This method is useful if you already have `git` installed.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/m4-k131/Berry-Picker.git
    ```

2.  **Navigate into the directory:**
    ```bash
    cd Berry-Picker
    ```
3.  **Proceed to the Configuration step below.**

---

## Configuration & Execution

After following one of the installation methods, complete the setup with these steps:

1.  **Create your environment file:**
    Copy the example `.env` file. This file is ignored by git, so your private keys and passwords will not be committed.
    ```bash
    cp .env.example .env
    ```

2.  **Edit the environment file:**
    Use a text editor like `nano` to add your credentials and authorized SSH keys.
    ```bash
    nano .env
    ```
    Press `Ctrl+X`, then `Y`, then `Enter` to save and exit.

3.  **Make the setup script executable:**
    ```bash
    chmod +x setup.sh
    ```

4.  **Run the script:**
    The script will prompt for your password to install system packages.
    ```bash
    ./setup.sh
    ```

5.  **Reload your shell:**
    To use the new aliases, you must reload your shell's configuration.
    ```bash
    source ~/.bashrc
    ```

---

## Usage

The script adds several helpful aliases and functions to your shell:

* `start_crawler`: Activates the Python virtual environment located at `~/venv/crawler/`.
* `workon <venv_name>`: A generic function to activate any virtual environment located in `~/venv/`.
* `lswc [dir] [pattern]`: Counts files and folders in a directory, with an optional pattern.
* `vpn_start` / `vpn_stop` / `vpn_status`: Aliases to manage an OpenVPN connection.
* `sattach`: Re-attaches to the first available detached `screen` session.
* `check_pi`: Provides a verbose, human-readable report on the Pi's power and thermal status to check for undervolting or throttling.


