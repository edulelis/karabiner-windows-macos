#!/bin/bash
# Disable Apple's built-in dictation on macOS so only open-wispr handles
# voice input. Idempotent — safe to re-run.
#
# Three layers:
#   1. Master switch (com.apple.assistant.support "Dictation Enabled")
#   2. Auto-enable (com.apple.HIToolbox AppleDictationAutoEnable)
#   3. Keyboard shortcut (symbolichotkeys key 164, e.g. "Press Control Twice")

set -euo pipefail

echo "Disabling Apple Dictation..."

defaults write com.apple.assistant.support "Dictation Enabled" -bool NO
defaults write com.apple.HIToolbox AppleDictationAutoEnable -bool NO
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 164 \
    '<dict><key>enabled</key><false/></dict>'

# Globe key does nothing (0 = Do Nothing) so open-wispr can own hold-to-talk
defaults write com.apple.HIToolbox AppleFnUsageType -int 0

killall DictationIM assistantd 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

sleep 2

echo "--- verification ---"
echo -n "Dictation Enabled:     "
defaults read com.apple.assistant.support "Dictation Enabled"
echo -n "Auto-enable:           "
defaults read com.apple.HIToolbox AppleDictationAutoEnable
echo -n "Shortcut (164) enabled: "
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null |
    grep -A2 ' 164 ' | grep enabled || echo "0"
echo "Done."
