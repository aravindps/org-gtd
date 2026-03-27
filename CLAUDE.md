# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A GTD configuration for Emacs org-mode, inspired by the workflow and feel of Things 3. Pure Emacs Lisp — no build system, no tests, no package manager. Changes take effect by reloading files in a running Emacs instance.

## Architecture

### File roles

| File | Role |
|------|------|
| `org-gtd.el` | Core: agenda views, helper functions, auto-sink hook. **No keybindings.** Load first. |
| `bindings-prefix.el` | Shared binding helper — defines `my/gtd-apply-prefix-bindings`. Never load directly. |
| `bindings-ccg.el` | Applies prefix bindings under `C-c g`. Load for terminal Emacs. |
| `bindings-f5.el` | Applies prefix bindings under `F5`. Alternative for terminal. |
| `bindings-cmd.el` | `s-` (⌘) bindings for GUI/macOS Emacs. |
| `doom-extras.el` | `SPC` leader bindings via `map!`. **Doom Emacs only** — uses Doom macros. |

### Key design constraints

- `org-gtd.el` and all `bindings-*.el` files must work in **vanilla Emacs** — no Doom macros allowed.
- `doom-extras.el` is the only file where `map!` and other Doom macros are permitted.
- The same action is available across all three binding systems simultaneously (⌘, prefix, SPC).

### Keybinding consistency rule

When adding or changing a keybinding, update **all three** binding layers:
1. `bindings-cmd.el` — `s-<key>` for GUI/macOS
2. `bindings-prefix.el` — the shared prefix map (propagates to both `C-c g` and `F5`)
3. `doom-extras.el` — `SPC <key>` for Doom

### Auto-sink behavior

`my/org-move-done-to-bottom` is hooked on `org-after-todo-state-change-hook`. When a task is marked DONE or CANCELLED, it automatically moves to the bottom of its parent.

### GTD data model

- **Project** = any heading with subtasks (no special marker)
- **Task** = subtask with a TODO state (`NEXT`, `WAIT`, `SOMEDAY`, `DONE`, `CANCELLED`)
- **Inbox** = a top-level heading named "Inbox"; tasks there have no state
- Single org file pointed to by `my/gtd-file` (user must set before loading)
