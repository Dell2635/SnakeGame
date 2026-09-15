#!/usr/bin/env bash
# ============================================================
#  Snake Game bootstrapper (macOS / Linux)
#
#  This script only checks/installs the Python interpreter
#  itself. It never touches snake_game_data.json (your saves,
#  settings, achievements, high scores) — that file is only
#  ever read/written by the game (SGFF.py), never by this
#  launcher. Once Python is confirmed working, this script
#  hands off to SGFF.py, which runs its own checks for pygame
#  and other packages and can update those itself.
# ============================================================

set -u
cd "$(dirname "$0")"

MIN_MAJOR=3
MIN_MINOR=8

echo ""
echo "================================================"
echo "  Snake Game - Startup Check"
echo "================================================"
echo ""

PYCMD=""

find_python() {
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            if "$candidate" -c "import sys; sys.exit(0 if sys.version_info >= ($MIN_MAJOR, $MIN_MINOR) else 1)" >/dev/null 2>&1; then
                PYCMD="$candidate"
                return 0
            fi
        fi
    done
    return 1
}

find_any_python() {
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            PYCMD="$candidate"
            return 0
        fi
    done
    return 1
}

echo "[1/3] Checking for Python..."
if find_python; then
    PYVER="$("$PYCMD" --version 2>&1)"
    echo "  Found $PYVER — OK."
    echo ""
    echo "Starting Snake Game..."
    echo ""
    exec "$PYCMD" "$(dirname "$0")/SGFF.py"
fi

# Either no python at all, or an outdated one.
REQUIRED_MSG="Snake Game needs Python ${MIN_MAJOR}.${MIN_MINOR} or newer to run."
if find_any_python; then
    PYVER="$("$PYCMD" --version 2>&1)"
    echo "[2/3] Found $PYVER, but it's older than ${MIN_MAJOR}.${MIN_MINOR}."
else
    echo "[2/3] No Python installation was found on this system."
fi

echo ""
echo "  $REQUIRED_MSG"
echo ""
read -r -p "  Install/update it now? (y/n): " REPLY
case "$REPLY" in
    y|Y|yes|YES) ;;
    *)
        echo ""
        echo "  Snake Game can't run correctly without a compatible Python."
        read -r -p "  Install now, or close the game? (install/close): " REPLY2
        case "$REPLY2" in
            install|i|I) ;;
            *)
                echo ""
                echo "  Closing. Run this launcher again whenever you're ready."
                exit 1
                ;;
        esac
        ;;
esac

echo ""
echo "[3/3] Installing/updating Python — this may take a few minutes."
echo "  Using only official, trusted sources."
echo ""

OS_NAME="$(uname -s)"

install_via_brew() {
    if command -v brew >/dev/null 2>&1; then
        echo "  Installing via Homebrew..."
        brew install python3
        return $?
    fi
    return 1
}

install_via_apt() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "  Installing via apt (you may be asked for your password)..."
        sudo apt-get update && sudo apt-get install -y python3 python3-pip
        return $?
    fi
    return 1
}

install_via_dnf() {
    if command -v dnf >/dev/null 2>&1; then
        echo "  Installing via dnf (you may be asked for your password)..."
        sudo dnf install -y python3 python3-pip
        return $?
    fi
    return 1
}

install_via_pacman() {
    if command -v pacman >/dev/null 2>&1; then
        echo "  Installing via pacman (you may be asked for your password)..."
        sudo pacman -Sy --noconfirm python
        return $?
    fi
    return 1
}

INSTALLED=1
if [ "$OS_NAME" = "Darwin" ]; then
    if install_via_brew; then
        INSTALLED=0
    else
        echo "  Homebrew isn't available. Downloading the official installer"
        echo "  from python.org instead..."
        PKG_URL="https://www.python.org/ftp/python/3.12.7/python-3.12.7-macos11.pkg"
        PKG_PATH="/tmp/python-installer.pkg"
        if command -v curl >/dev/null 2>&1; then
            curl -L -o "$PKG_PATH" "$PKG_URL"
        fi
        if [ -f "$PKG_PATH" ]; then
            echo "  Opening the official installer — please follow its prompts."
            open "$PKG_PATH"
            echo "  Press Enter here once the installer has finished."
            read -r _
            INSTALLED=0
        else
            echo "  Download failed. Please install Python manually from"
            echo "  https://www.python.org/downloads/macos/ and run this launcher again."
        fi
    fi
else
    # Linux: try common package managers, in order.
    if install_via_apt; then
        INSTALLED=0
    elif install_via_dnf; then
        INSTALLED=0
    elif install_via_pacman; then
        INSTALLED=0
    else
        echo "  Couldn't detect a supported package manager (apt/dnf/pacman)."
        echo "  Please install Python ${MIN_MAJOR}.${MIN_MINOR}+ using your"
        echo "  distribution's package manager, or from"
        echo "  https://www.python.org/downloads/source/ and run this launcher again."
    fi
fi

echo ""
echo "  Verifying installation..."
if find_python; then
    PYVER="$("$PYCMD" --version 2>&1)"
    echo "  $PYVER is ready."
else
    echo "  Python still isn't available. Please install it manually from"
    echo "  https://www.python.org/downloads/ and run this launcher again."
    exit 1
fi

echo ""
echo "Starting Snake Game..."
echo ""
exec "$PYCMD" "$(dirname "$0")/SGFF.py"
