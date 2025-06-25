#!/bin/bash

## lib / vars
_szGreen="\033[1;32m"
_szRed="\033[1;31m"
_szWhite="\033[1;37m"
_szReset="\033[0m"

_szPrefix="${_szRed}[inst]${_szWhite}"

## lib / funcs
function _cprintfraw {
      printf "$_szPrefix %s${_szReset}" "$@"
}

function cprintf {
      local format="$1"
      shift
      printf "${_szPrefix} ${format} ${_szReset}\n" "$@"
}

function _CheckDependencies {
    local -a packages=("$@")  # Accept array of packages as arguments
    local -a missing_packages=()
    local distro

    # Determine distribution
    _get_distro() {
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            echo "${ID}"
        else
            echo "unknown"
        fi
    }

    distro=$(_get_distro)

    # Check and install based on distribution
    case "${distro}" in
        "debian"|"ubuntu")
            cprintf "Detected distribution: Debian-based"
            
            # Verify apt is available
            if ! command -v apt &>/dev/null; then
                cprintf "Error: apt package manager not found."
                return 1
            fi

            # Check for missing packages
            for pkg in "${packages[@]}"; do
                if ! dpkg -s "${pkg}" &>/dev/null; then
                    missing_packages+=("${pkg}")
                fi
            done

            if [[ ${#missing_packages[@]} -gt 0 ]]; then
                cprintf "Missing packages: %s" "${missing_packages[*]}"
                cprintf "Updating package lists..."
                if ! sudo apt update; then
                    cprintf "Error: Failed to update apt repositories."
                    return 1
                fi
                cprintf "Installing missing packages via apt..."
                if ! sudo apt -y install "${missing_packages[@]}"; then
                    cprintf "Error: Failed to install packages: %s" "${missing_packages[*]}"
                    return 1
                fi
                cprintf "Successfully installed: %s" "${missing_packages[*]}"
            else
                cprintf "Found dependencies: %s" "${packages[*]}"
            fi
            ;;
        "arch")
            cprintf "Detected distribution: Arch Linux"
        
            # Verify pacman is available
            if ! command -v pacman &>/dev/null; then
                cprintf "Error: pacman package manager not found."
                return 1
            fi

            # Check for missing packages
            for pkg in "${packages[@]}"; do
                if ! pacman -Qs "${pkg}" &>/dev/null; then
                    missing_packages+=("${pkg}")
                fi
            done

            if [[ ${#missing_packages[@]} -gt 0 ]]; then
                cprintf "Missing packages: %s" "${missing_packages[*]}"
                cprintf "Installing missing packages via pacman..."
                if ! sudo pacman -Syu --noconfirm "${missing_packages[@]}"; then
                    cprintf "Error: Failed to install packages: %s" "${missing_packages[*]}"
                    return 1
                fi
                cprintf "Successfully installed: %s" "${missing_packages[*]}"
            else
                cprintf "Found dependencies: %s" "${packages[*]}"
            fi
            ;;
        "fedora")
            cprintf "Detected distribution: Fedora"
            
            # Verify dnf is available
            if ! command -v dnf &>/dev/null; then
                cprintf "Error: dnf package manager not found."
                return 1
            fi

            # Check for missing packages
            for pkg in "${packages[@]}"; do
                if ! rpm -q "${pkg}" &>/dev/null; then
                    missing_packages+=("${pkg}")
                fi
            done

            if [[ ${#missing_packages[@]} -gt 0 ]]; then
                cprintf "Missing packages: %s" "${missing_packages[*]}"
                cprintf "Installing missing packages via dnf..."
                if ! sudo dnf install -y "${missing_packages[@]}"; then
                    cprintf "Error: Failed to install packages: %s" "${missing_packages[*]}"
                    return 1
                fi
                cprintf "Successfully installed: %s" "${missing_packages[*]}"
            else
                cprintf "Found dependencies: %s" "${packages[*]}"
            fi
            ;;
        *)
            cprintf "Error: Unsupported distribution: %s. Please install packages manually: %s" "${distro}" "${packages[*]}"
            return 1
            ;;
    esac
}

