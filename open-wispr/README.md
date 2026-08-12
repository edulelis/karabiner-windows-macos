# open-wispr + double-press Control dictation

Free, local, on-device voice dictation (whisper.cpp + Metal) that replaces
Apple's built-in dictation with a Control-key gesture.

**Behavior**

| State | Gesture | Effect |
|-------|---------|--------|
| Idle | Double-tap Control (left or right, 2 taps < 400ms, no key in between) | Start recording |
| Recording | Single Control press | Stop recording + insert text |

- `Ctrl+<letter>` chords never trigger it (any other key within the 400ms
  window cancels the double-press detection — same algorithm as Apple's own
  "Press Control Twice", but in an observer-only event monitor that cannot
  swallow keystrokes).
- Everything runs on-device. No audio ever leaves the machine.

## Accuracy

Why this replaces Apple Dictation:

- Whisper large-v3 is near state-of-the-art ASR: **~1.8% word error rate** on
  LibriSpeech test-clean (OpenAI large-v3 release, Nov 2023) and **7.44% mean
  WER** across the harder, conversational suite of the
  [HF Open ASR Leaderboard](https://huggingface.co/spaces/hf-audio/open_asr_leaderboard).
- This setup runs `large-v3-turbo`, which OpenAI documents as offering "faster
  transcription speed with a minimal degradation in accuracy" versus large-v3
  ([official Whisper README](https://github.com/openai/whisper#available-models-and-languages)).
- Apple publishes no word-error-rate figures for macOS Dictation, so there is
  no official head-to-head benchmark — but Apple Dictation is absent from ASR
  leaderboards entirely, while Whisper large-v3 sits at the top of them.
- On top of raw accuracy, `config.json` sets a `whisperPrompt` biased toward
  programming vocabulary and project names (TypeScript, Shopify, Drizzle,
  Xilften, Netflix, ...), which steers transcription toward the terms you
  actually dictate — something Apple Dictation has no equivalent for.

## What's in this folder

- `config.json` — open-wispr config: double-press on left/right Control,
  `large-v3-turbo` model (best accuracy/speed on M-series Max chips), and a
  `whisperPrompt` biased toward programming vocabulary and project names.
- `double-press.patch` — patch against open-wispr `v0.43.0` source that adds
  native double-press/single-press hotkey modes (upstream has no double-press
  support).
- `disable-apple-dictation.sh` — turns off Apple dictation in all three layers
  (master switch, auto-enable, keyboard shortcut) so it can't fire alongside
  open-wispr.

## Install

```sh
# 1. Install open-wispr (guided installer: brew, permissions, model download)
curl -fsSL https://raw.githubusercontent.com/human37/open-wispr/main/scripts/install.sh | bash

# 2. Apply the double-press patch and rebuild
brew services stop open-wispr
git clone --depth 1 https://github.com/human37/open-wispr.git /tmp/open-wispr-fork
cd /tmp/open-wispr-fork
git checkout 7ab4e62e8f182f3ecc2116e1094a1eb4416a248f   # patch base commit
git apply path/to/this/repo/open-wispr/double-press.patch
swift build -c release --disable-sandbox
bash scripts/bundle-app.sh .build/release/open-wispr OpenWispr.app 0.43.0-fork

# 3. Swap the bundled app in (backup first!)
APP=/opt/homebrew/opt/open-wispr/OpenWispr.app
cp -R "$APP" "$APP.orig"
rm -rf "$APP"
cp -R OpenWispr.app "$APP"

# 4. Pin the formula so `brew upgrade` doesn't clobber the patch
brew pin open-wispr

# 5. Re-grant permissions (re-signing invalidates the old grant)
tccutil reset Accessibility com.human37.open-wispr
tccutil reset Microphone com.human37.open-wispr

# 6. Copy the config and start
mkdir -p ~/.config/open-wispr
cp path/to/this/repo/open-wispr/config.json ~/.config/open-wispr/config.json
brew services start open-wispr

# 7. Disable Apple dictation
bash path/to/this/repo/open-wispr/disable-apple-dictation.sh
```

On first start, the app opens System Settings automatically — toggle
**OpenWispr** ON under Privacy & Security → Accessibility and allow the
Microphone.

## Verify

```sh
tail -f /opt/homebrew/var/log/open-wispr.log
```

Double-tap Control → `Double-press: start recording`.
Single tap while recording → `Single-press: stop recording`.

## Revert to stock open-wispr

```sh
brew services stop open-wispr
brew unpin open-wispr
brew reinstall open-wispr
```

## Notes

- The patch base is open-wispr commit `7ab4e62e8f182f3ecc2116e1094a1eb4416a248f`
  (v0.43.0). If upstream moves, cherry-pick the three touched files by hand —
  the edits are small (`HotkeyManager.swift`, `Config.swift`,
  `AppDelegate.swift`).
- Double-press works with no extra key required: open-wispr's event monitor is
  a pure observer (NSEvent global monitor), so it can never intercept or
  modify keystrokes — your Karabiner mappings keep working.
- Model upgrades: edit `modelSize` in `~/.config/open-wispr/config.json`
  (`large-v3` for absolute max accuracy, 3GB) and restart the service.
