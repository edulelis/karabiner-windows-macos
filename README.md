# Karabiner Windows macOS

Karabiner-Elements configuration for Windows-style keyboard mappings on macOS.

The config is proposed through pull requests so changes remain reviewable before landing on `main`.

## Install

1. Install [Karabiner-Elements](https://karabiner-elements.pqrs.org/).
2. Copy `karabiner/karabiner.json` to `~/.config/karabiner/karabiner.json`.
3. Build the Finder Backspace helper. This requires Apple's Xcode Command Line Tools because it uses `swiftc`:

```sh
scripts/install-finder-backspace-helper
```

4. In System Settings, allow the helper under Privacy & Security > Accessibility.

If the Settings pane does not open automatically, run:

```sh
open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'
```

After the Karabiner config is active, `Ctrl-Option-Command-Shift-K` also runs the helper in permission-prompt mode and opens the same Settings pane.

## Finder Backspace

This config maps plain Backspace in Finder to Windows-style folder navigation:

- While editing a filename or other Finder text field, Backspace deletes text.
- Otherwise, Backspace goes to the parent folder, equivalent to Command-Up.

Karabiner can tell that Finder is the frontmost app, but it cannot reliably tell whether Finder is currently editing a filename. The helper uses macOS Accessibility APIs to inspect Finder's focused UI element, then posts the correct key event.

That is why Accessibility permission is needed. This is a macOS privacy approval, not an admin-password action, so `sudo` cannot grant it. Opening the Accessibility pane is the important step.

## Skipping The Helper

If you do not want to grant Accessibility permission, do not install or approve the helper.

With the Finder Backspace rule still enabled but the helper not approved, plain Backspace in Finder may open the Accessibility pane and the intended key action will not fire. `Shift-Backspace` still falls through to Finder because this rule only handles plain Backspace.

To skip the helper cleanly, remove or disable this rule from `karabiner/karabiner.json`:

```text
Backspace: Delete text while editing; otherwise go to parent folder (Finder)
```

Without that rule, Finder keeps its default macOS Backspace behavior and you will not get the Windows-style "go to parent folder" mapping.

## Dictation (open-wispr fork)

Apple dictation replaced by [open-wispr](https://github.com/human37/open-wispr), a free, local, on-device whisper.cpp dictation app, patched with a native double-press Control gesture:

- **Double-tap Control** starts recording
- **Single Control press** stops recording and inserts the text
- `Ctrl+<letter>` shortcuts are never affected (the patch uses an observer-only event monitor)

Everything lives in [`open-wispr/`](open-wispr/) — config, the double-press patch, and a script that disables Apple dictation so the two never fire together. See [`open-wispr/README.md`](open-wispr/README.md) for install and revert steps.

