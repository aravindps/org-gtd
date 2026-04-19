# CLAUDE.md

GTD configuration for Emacs org-mode. Pure Emacs Lisp — no build system, no tests, no package manager. Reload files in a running Emacs to apply changes.

## Scope

Action-only — no calendar, no recurring tasks, no reference storage. Weekly review is manual.

## File roles


| File                                 | Role                                                                            |
| ------------------------------------ | ------------------------------------------------------------------------------- |
| `org-gtd.el`                         | Core: views, helpers, hooks, dashboard. No user-facing keybindings. Load first. |
| `bindings-prefix.el`                 | Shared binding helper. Never load directly.                                     |
| `bindings-ccg.el` / `bindings-f5.el` | Terminal prefix bindings (`C-c g` / `F5`).                                      |
| `bindings-cmd.el`                    | `s-` (⌘) bindings for GUI/macOS.                                                |
| `bindings-doom.el`                   | `SPC` leader via `map!`. **Doom only.**                                         |
| `doom-overrides.el`                  | Doom/evil conflict fixes. **Doom only.** Load last.                             |


## Key constraints

- `org-gtd.el` and `bindings-*.el` must work in **vanilla Emacs** — no Doom macros.
- `bindings-doom.el` is the **only** file where `map!` is allowed.
- When adding/changing a keybinding, update **all three** layers: `bindings-cmd.el`, `bindings-prefix.el`, `bindings-doom.el`.
- Org’s variable is `org-agenda-custom-commands` (not `org-custom-agenda-commands`). org-gtd **prepends** its views (`0`, `1`, `3`–`6`) to the existing value when its `eval-after-load 'org` runs (using `boundp` so it does not error if `org-agenda` has not defined the variable yet), so agendas already on the variable at that moment are kept after the GTD block. Any later plain `setq org-agenda-custom-commands` elsewhere in init replaces the whole list—merge with `append` or ensure that code runs before org-gtd’s hook. For duplicate keys, Org uses the first match (GTD’s numerics stay first).

## GTD data model

- **Project** = level-1 heading with `PROJECT` state or no state
- **Task** = child heading with `NEXT`, `WAIT`, `SOMEDAY`, `DONE`, or `CANCELLED`
- **Inbox** = top-level `* Inbox` heading; items have no state
- Single org file via `my/gtd-file`
- A level-1 heading with `NEXT`/`WAIT`/`SOMEDAY` is a **task**, not a project

## Project visibility (dashboard left pane)


| State                | Scheduled          | Shown |
| -------------------- | ------------------ | ----- |
| No state / `PROJECT` | none or past/today | Yes   |
| No state / `PROJECT` | future             | No    |
| `WAIT` / `SOMEDAY`   | today or past      | Yes   |
| `WAIT` / `SOMEDAY`   | none or future     | No    |
| `DONE` / `CANCELLED` | any                | No    |


## Project indicators

- *(no prefix)* — has NEXT tasks (actionable)
- `~` — no NEXT tasks, has WAIT/SOMEDAY only (blocked/deferred)
- `●` — all tasks DONE/CANCELLED (stale)
- `?` — no child tasks (empty)

## Auto-sink

On DONE/CANCELLED, task moves down to **top of done group** (before first closed sibling), not absolute bottom.

## Key behaviors

- Dashboard: 30/70 split, live counts, auto-opens with `gtd.org`
- Auto-save: 2s idle timer + evil insert exit
- Complete/cancel with children: prompts confirmation, marks descendants bottom-up
- State picker (`SPC e`): single keypress, includes promote-to-project
- Hide done (`SPC '`): toggles DONE/CANCELLED visibility, persists across S-TAB
- Refile (Shift+m everywhere: `C-c g M`, `SPC M`, `⇧⌘M`; plain `⌘m` stays minimize): excludes DONE/CANCELLED and Inbox from targets
- Upcoming view (`*GTD Upcoming*`) is a custom buffer, not an org-agenda buffer
- Logbook dashboard row intentionally shows no count
- Context tags derived from `#+TAGS:` in gtd.org — no code changes needed for new tags

## Keybinding exceptions


| Action      | SPC | Prefix | ⌘     | Reason                                    |
| ----------- | --- | ------ | ----- | ----------------------------------------- |
| Checklist   | `c` | `c`    | `⌘C`  | `⌘c` = copy                               |
| Refile      | `M` | `M`    | `⇧⌘M` | same chord (Shift+m); `⌘m` = minimize; Doom `SPC m` free |
| New project | `a` | `a`    | `⌥⌘a` | `⌘a` = select all                         |
| Search      | —   | `f`    | `⌘f`  | `SPC f` = Doom files                      |


**Doom:** refile is **`SPC M`** (Shift+m), same as **`C-c g M`** / **`F5 M`** and **`⇧⌘M`** on macOS GUI, so stock **`SPC m`** stays free. Vanilla Emacs never loads `bindings-doom.el`; it still gets prefix + GUI bindings above.