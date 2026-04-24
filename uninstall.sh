#!/bin/bash
# uninstall.sh
#
# Removes Jarvis from your local machine and optionally deletes GitHub Secrets.
#
# Usage: ./uninstall.sh

set -euo pipefail

JARVIS_DIR="$(cd "$(dirname "$0")" && pwd)"
JARVISRC="$HOME/.jarvisrc"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Jarvis Uninstall               ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "This will remove:"
echo "  • $JARVISRC"
echo "  • jarvis PATH entry from your shell config"
echo ""
read -r -p "Continue? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

# =============================================================================
# Remove ~/.jarvisrc
# =============================================================================
if [[ -f "$JARVISRC" ]]; then
  rm "$JARVISRC"
  echo "  ✓ Removed $JARVISRC"
else
  echo "  — $JARVISRC not found (already removed)"
fi

# =============================================================================
# Remove PATH entry from shell config
# =============================================================================
SHELL_RC=""
if [[ "$SHELL" == */zsh ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]] && grep -qF "$JARVIS_DIR/bin" "$SHELL_RC" 2>/dev/null; then
  # Remove the comment line and the export line together
  # Use a temp file for portability (macOS sed -i requires a backup suffix)
  local_tmp=$(mktemp)
  grep -v "# Jarvis CLI" "$SHELL_RC" | grep -v "$JARVIS_DIR/bin" > "$local_tmp"
  mv "$local_tmp" "$SHELL_RC"
  echo "  ✓ Removed PATH entry from $SHELL_RC"
  echo "  Run: source $SHELL_RC  (or open a new terminal)"
elif [[ -n "$SHELL_RC" ]]; then
  echo "  — No PATH entry found in $SHELL_RC"
else
  echo "  — Could not detect shell config; remove the jarvis PATH entry manually"
fi
echo ""

echo "╔══════════════════════════════════════╗"
echo "║       Uninstall Complete             ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  The jarvis directory itself was NOT deleted."
echo "  To fully remove: rm -rf $JARVIS_DIR"
echo ""
