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
| `bindings-doom.el` | `SPC` leader bindings via `map!`. **Doom Emacs only** — uses Doom macros. |

### Key design constraints

- `org-gtd.el` and all `bindings-*.el` files must work in **vanilla Emacs** — no Doom macros allowed.
- `bindings-doom.el` is the only file where `map!` and other Doom macros are permitted.
- The same action is available across all three binding systems simultaneously (⌘, prefix, SPC).

### Keybinding consistency rule

When adding or changing a keybinding, update **all three** binding layers:
1. `bindings-cmd.el` — `s-<key>` for GUI/macOS
2. `bindings-prefix.el` — the shared prefix map (propagates to both `C-c g` and `F5`)
3. `bindings-doom.el` — `SPC <key>` for Doom

### Auto-sink behavior

`my/org-move-done-to-bottom` is hooked on `org-after-todo-state-change-hook`. When a task is marked DONE or CANCELLED, it automatically moves to the bottom of its parent.

### Dashboard

`my/org-dashboard` renders a `*GTD*` buffer with live counts for every view. It opens in a 30/70 left/right split — dashboard left, content right. Key behaviours:

- Opens automatically when `gtd.org` is visited or on Emacs startup (`find-file-hook`)
- `RET` / mouse-click on a row opens that view in the right pane
- `q` closes the dashboard pane
- `g` re-renders counts
- Counts refresh automatically on: todo state change, `org-schedule`, `org-deadline`, file save, and evil insert exit
- Context tag rows are derived from `#+TAGS:` in `gtd.org` — no code changes needed when tags are added

### Auto-save

`my/gtd-auto-save` runs on an idle timer (2 s) and on `evil-insert-state-exit-hook`. `my/gtd-after-save-refresh` is on `after-save-hook` and triggers `my/gtd-auto-refresh` whenever `gtd.org` is saved.

### GTD data model

- **Area** = level-1 heading with no TODO state — a container, never shown in dashboard
- **Project** = level-1 heading with `PROJECT` state (or no state if not yet classified) — shown in dashboard left pane
- **Task** = any heading with a TODO state (`NEXT`, `WAIT`, `SOMEDAY`, `DONE`, `CANCELLED`) inside a project
- **Inbox** = a top-level heading named "Inbox"; items there have no state and are excluded from projects
- Single org file pointed to by `my/gtd-file` (user must set before loading)

**Critical distinction**: A level-1 heading with `NEXT`, `WAIT`, or `SOMEDAY` state is a **task**, not a project — it is never shown in the dashboard project list. Only `nil` state or `PROJECT` state at level-1 qualifies as a project. This prevents lone top-level tasks from masquerading as projects.

### GTD workflow nuances

**Inbox usage**: `SPC i` opens the Inbox heading for free-form capture. Items there should be plain headings with no TODO state. They get triaged later into projects/tasks. Do not assign state in Inbox — that would make them look like tasks.

**Project lifecycle**:
1. Create project: level-1 heading, no state (or set `PROJECT` state explicitly)
2. Add tasks: child headings with `NEXT`, `WAIT`, or `SOMEDAY` state
3. Project appears in dashboard left pane while active
4. Project disappears automatically when future-scheduled, deferred (`WAIT`/`SOMEDAY` with no/future date), or completed/cancelled

**Task states**:
- `NEXT` — actionable, will show in Today/Anytime/Context views
- `WAIT` — blocked on something external
- `SOMEDAY` — deferred, not committed
- `DONE` / `CANCELLED` — finished; auto-sunk to bottom of parent on state change

**View membership**:
- **Today**: tasks with `NEXT`/`WAIT` scheduled for today or overdue
- **Upcoming**: all future-scheduled tasks grouped by day (within 7 days) then by month; excludes `SOMEDAY`; custom buffer not org-agenda
- **Anytime**: all `NEXT` tasks without a schedule date
- **Waiting**: all `WAIT` tasks
- **Someday**: all `SOMEDAY` tasks
- **Logbook**: all `DONE`/`CANCELLED` tasks
- **Context**: `NEXT` tasks filtered by a chosen `@tag`

**State labels in views**: Only the Today view shows state labels. All other views suppress state labels via `org-agenda-todo-keyword-format ""`. Logbook uses visual decorations instead: ✓ for DONE, strikethrough on task text for CANCELLED.

**Deferred projects**: A project with `WAIT` or `SOMEDAY` state is hidden from the dashboard unless it has a scheduled date that is today or in the past. This keeps the left pane free of parked items while surfacing them when their scheduled date arrives.

### Project visibility rules (left pane)

| State | Scheduled | Shown |
|-------|-----------|-------|
| No state / `PROJECT` | none or past/today | ✓ |
| No state / `PROJECT` | future | ✗ |
| `WAIT` / `SOMEDAY` | today or past | ✓ |
| `WAIT` / `SOMEDAY` | none or future | ✗ |
| `DONE` / `CANCELLED` | any | ✗ |

### Project indicators (left pane)

- `  Name` — has active tasks (`NEXT`/`WAIT`/`SOMEDAY`)
- `● Name` — stale (tasks exist but all `DONE`/`CANCELLED`)
- `? Name` — empty (no child tasks yet)

### Navigation model

- Clicking any view row opens content in the **right pane**
- Clicking a task in any view opens it **narrowed to its subtree** in the right pane
- To return to a list view: click it again from the left dashboard
- `⌘[` / `winner-undo` goes back to the previous window configuration (`winner-mode` must be enabled)
- `SPC -` / `<p> -` toggles narrow/widen (zoom in and out of current subtree)
- `⌘→` narrows to subtree; `⌘←` widens (GUI only)

### Known issues / gaps

- **No `SPC` binding for Search headings** — `SPC f` conflicts with Doom's file search. Use `<p> f` or `⌘ f` instead.
- **No `SPC` binding for Zoom in/out** — `⌘ →` / `⌘ ←` GUI only. `SPC -` / `<p> -` toggle narrow/widen works in all modes.
- **Archive (`SPC y`) not yet decided** — `org-archive-subtree` moves subtrees to `gtd.org_archive`. Undecided whether to use it. Workflow note: since navigation is always via agenda/dashboard into narrowed subtrees, DONE/CANCELLED tasks in the file are not a day-to-day problem. Archive is recoverable but manual (cut from `_archive`, paste back). Revisit when `gtd.org` grows large.

### Known Doom Emacs conflicts and workarounds

- **`SPC z`** — conflicts with Doom's zoom/font-size prefix. Use `SPC -` for zoom toggle instead.
- **`RET` in normal mode** — Doom binds `RET` to `+org/dwim-at-point` which toggles TODO states. Override with `(map! :after evil-org :map evil-org-mode-map :n "RET" #'org-return)` in `config.el`. Using `evil-define-key` alone is not sufficient because Doom's `evil-org` overrides it.
- **Theme faces** — Doom's `def-doom-theme` macro does not reliably apply custom faces to org-mode buffers at load time. Buffer-local `face-remap-add-relative` can override individual faces but is fragile. Prefer sticking with a standard Doom theme.

### Implementation notes

- **Project scan** in dashboard uses `org-map-entries` at level 1, checking `org-get-todo-state` for the heading state and `org-get-scheduled-time` for the date. The `show-p` cond must explicitly enumerate valid project states (`nil`, `"PROJECT"`) and return `nil` as the default — a catch-all `(t t)` will incorrectly show level-1 `NEXT` tasks as projects.
- **Upcoming view** is a custom `*GTD Upcoming*` buffer, not an org-agenda buffer. It scans `gtd.org` directly, groups entries by date, and uses text properties (`mouse-face`, `action`) for click navigation. State labels are stripped during rendering.
- **Dashboard counts** are computed by a full scan of `gtd.org` on every refresh. Counts refresh on: `org-after-todo-state-change-hook`, `org-schedule`, `org-deadline`, `after-save-hook`, and `evil-insert-state-exit-hook`.
- **Auto-sink** (`my/org-move-done-to-bottom`) runs on `org-after-todo-state-change-hook`. When marking DONE/CANCELLED, the subtree is cut and re-inserted at the end of the parent. This keeps active tasks at the top.

### Keybindings reference

| Action | SPC | Prefix | ⌘ |
|--------|-----|--------|---|
| Dashboard | `SPC /` | `<p> /` | `⌘/` |
| Inbox view | `SPC 0` | `<p> 0` | `⌘0` |
| Today | `SPC 1` | `<p> 1` | `⌘1` |
| Upcoming | `SPC 2` | `<p> 2` | `⌘2` |
| Anytime | `SPC 3` | `<p> 3` | `⌘3` |
| Waiting | `SPC 4` | `<p> 4` | `⌘4` |
| Someday | `SPC 5` | `<p> 5` | `⌘5` |
| Logbook | `SPC 6` | `<p> 6` | `⌘6` |
| Context (NEXT) | `SPC 7` | `<p> 7` | `⌘7` |
| Context (all) | `SPC 8` | `<p> 8` | `⌘8` |
| Open Inbox | `SPC i` | `<p> i` | `⌘i` |
| New task | `SPC n` | `<p> n` | `⌘n` |
| New heading | `SPC N` | `<p> N` | `⌘ N` |
| Complete | `SPC k` | `<p> k` | `⌘ k` |
| Cancel | `SPC K` | `<p> K` | `⌥ ⌘ k` |
| Duplicate | `SPC d` | `<p> d` | `⌘ d` |
| Refile | `SPC m` | `<p> m` | `⌘ M` |
| Archive | `SPC y` | `<p> y` | `⌘ Y` |
| Schedule | `SPC s` | `<p> s` | `⌘ s` |
| Schedule today | `SPC t` | `<p> t` | `⌘ t` |
| Remove schedule | `SPC r` | `<p> r` | `⌘ r` |
| Someday | `SPC o` | `<p> o` | `⌘ o` |
| Deadline | `SPC D` | `<p> D` | `⌘ D` |
| Zoom toggle | `SPC -` | `<p> -` | — |
| Zoom in (narrow) | — | — | `⌘ →` |
| Zoom out (widen) | — | — | `⌘ ←` |
| Go back (winner) | — | — | `⌘ [` |
| Tags | `SPC T` | `<p> T` | `⌘ T` |
| Search headings | — | `<p> f` | `⌘ f` |

---

## Emacs features used

### Core org-mode
- **Todo keywords** — `org-todo-keywords`, `org-todo`, `org-get-todo-state`
- **Agenda views** — `org-agenda-custom-commands`, `org-agenda`, `org-agenda-mode`
- **Scheduling & deadlines** — `org-schedule`, `org-deadline`, `org-get-scheduled-time`
- **Refile** — `org-refile`, `org-refile-targets`
- **Tags** — `org-get-tags`, `org-tags-view`, `org-set-tags-command`
- **Narrowing** — `org-narrow-to-subtree`, `widen`, `buffer-narrowed-p`
- **Heading navigation** — `org-map-entries`, `org-outline-level`, `org-get-heading`, `org-up-heading-safe`
- **Subtree ops** — `org-insert-subheading`, `org-move-subtree-up/down`, `org-copy-subtree`, `org-paste-subtree`, `org-archive-subtree`
- **Logging** — `org-log-done`
- **Hooks** — `org-after-todo-state-change-hook`, `org-agenda-finalize-hook`, `org-agenda-mode-hook`

### Emacs UI / buffer management
- **Custom major mode** — `define-derived-mode` (dashboard and upcoming view)
- **Overlays** — active row highlight in dashboard and upcoming view
- **Text properties** — clickable rows, mouse-face, markers for jump-to-task
- **Window management** — `split-window-right`, `window-in-direction`, `delete-other-windows`, `winner-mode`
- **Markers** — `point-marker`, `marker-buffer` for jump-to-task navigation
- **Faces** — `add-face-text-property` for strikethrough (CANCELLED), shadow, highlight
- **Mouse support** — `mouse-set-point`, `[mouse-1]` bindings throughout
- **Idle timer** — `run-with-idle-timer` for auto-save (2 s)
- **Advice** — `advice-add` to hook into `org-schedule` / `org-deadline`

### Evil (optional, Doom only)
- `evil-define-key`, `evil-local-set-key` for normal-mode bindings
- `evil-insert-state-exit-hook` for auto-save and dashboard refresh trigger

### Completion (optional)
- `completing-read` for context tag picker (uses Vertico if available)
- `consult-org-heading` for heading search (falls back to `occur`)

### Data portability
The GTD data (`gtd.org`) is plain text — readable by any editor or org-compatible app. All UI, views, dashboard, and automation are Emacs-only.
