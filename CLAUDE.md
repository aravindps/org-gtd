# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A GTD configuration for Emacs org-mode, inspired by the workflow and feel of Things 3. Pure Emacs Lisp — no build system, no tests, no package manager. Changes take effect by reloading files in a running Emacs instance.

## Architecture

### File roles

| File | Role |
|------|------|
| `org-gtd.el` | Core: agenda views, helper functions, auto-sink hook, startup settings. Internal mode-map bindings only (dashboard, agenda). **No user-facing keybindings.** Load first. |
| `bindings-prefix.el` | Shared binding helper — defines `my/gtd-apply-prefix-bindings`. Never load directly. |
| `bindings-ccg.el` | Applies prefix bindings under `C-c g`. Load for terminal Emacs. |
| `bindings-f5.el` | Applies prefix bindings under `F5`. Alternative for terminal. |
| `bindings-cmd.el` | `s-` (⌘) bindings for GUI/macOS Emacs. |
| `bindings-doom.el` | `SPC` leader bindings via `map!`. **Doom Emacs only** — uses Doom macros. |
| `doom-overrides.el` | Doom/evil conflict fixes (C-M-RET, evil-org RET). **Doom Emacs only.** Load last. |

### Key design constraints

- `org-gtd.el` and all `bindings-*.el` files must work in **vanilla Emacs** — no Doom macros allowed.
- `bindings-doom.el` is the only file where `map!` and other Doom macros are permitted.
- `doom-overrides.el` uses `with-eval-after-load` (vanilla-compatible) even though it's only loaded in Doom.
- The same action is available across all three binding systems simultaneously (⌘, prefix, SPC).

### Keybinding consistency rule

When adding or changing a keybinding, update **all three** binding layers:
1. `bindings-cmd.el` — `s-<key>` for GUI/macOS
2. `bindings-prefix.el` — the shared prefix map (propagates to both `C-c g` and `F5`)
3. `bindings-doom.el` — `SPC <key>` for Doom

### Auto-sink behavior

`my/org-move-done-to-bottom` is hooked on `org-after-todo-state-change-hook`. When a task is marked DONE or CANCELLED, it calls `org-move-subtree-down` in a loop, stopping before the first existing DONE/CANCELLED sibling. This places the task at the **top of the done group** (not absolute bottom), keeping active tasks above and recently-completed tasks visible.

### Dashboard

`my/org-dashboard` renders a `*GTD*` buffer with live counts for every view. It opens in a 30/70 left/right split — dashboard left, content right. Key behaviours:

- Opens automatically when `gtd.org` is visited (`find-file-hook`) or on Emacs startup (`window-setup-hook`, controlled by `my/gtd-open-on-startup`)
- `RET` / mouse-click on a row opens that view in the right pane
- `q` is bound to `#'ignore` (no-op) — close the dashboard with `SPC /` / `⌘/` (toggle)
- `g` re-renders counts
- Counts refresh automatically on: todo state change, `org-schedule`, `org-deadline`, file save, and evil insert exit
- Context tag rows are derived from `#+TAGS:` in `gtd.org` — no code changes needed when tags are added
- A "No context" row shows NEXT tasks with no `@tag`
- The Logbook row intentionally shows no count (count is not computed)
- Project name width scales dynamically with window width

### Auto-save

`my/gtd-auto-save` runs on an idle timer (2 s) and on `evil-insert-state-exit-hook`. `my/gtd-after-save-refresh` is on `after-save-hook` and triggers `my/gtd-auto-refresh` whenever `gtd.org` is saved.

### GTD data model

- **Project** = level-1 heading with `PROJECT` state or no state — shown in dashboard left pane
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
- `DONE` / `CANCELLED` — finished; auto-sunk to top of done group within parent on state change

**View membership**:
- **Today**: scheduled tasks for today or overdue (all non-DONE/CANCELLED states); the agenda `skip-function` only excludes DONE/CANCELLED
- **Upcoming (dashboard)**: `my/org-upcoming-view` — custom `*GTD Upcoming*` buffer, groups future-scheduled tasks by day (within 7 days) then month; excludes SOMEDAY and today's tasks
- **Upcoming (keybinding `2`)**: `org-agenda nil "2"` — standard org-agenda `tags-todo` view showing all future-scheduled non-DONE/CANCELLED tasks as a flat list. This differs from the dashboard's custom grouped view.
- **Anytime**: all `NEXT` tasks without a schedule date or deadline
- **Waiting**: all `WAIT` tasks
- **Someday**: all `SOMEDAY` tasks
- **Logbook**: all `DONE`/`CANCELLED` tasks
- **Context**: `NEXT` tasks filtered by a chosen `@tag`

**State labels in views**: Only the Today view shows state labels. All other views suppress state labels via `org-agenda-todo-keyword-format ""`. Logbook uses visual decorations instead: checkmark prefix for DONE, strikethrough on task text for CANCELLED.

**Empty-state messages**: When an agenda view has no entries, a contextual placeholder is shown (e.g. "Nothing due today.", "No actionable tasks."). Implemented by `my/org-agenda-empty-state` on `org-agenda-finalize-hook`.

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

- `Name` (no prefix) — has active tasks (`NEXT`/`WAIT`/`SOMEDAY`)
- `● Name` — stale (tasks exist but all `DONE`/`CANCELLED`)
- `? Name` — empty (no child tasks yet)

### Navigation model

- Clicking any view row opens content in the **right pane**
- Clicking a task in any view opens it **narrowed to its subtree** in the right pane
- To return to a list view: click it again from the left dashboard
- `⌘[` / `winner-undo` goes back to the previous window configuration (`winner-mode` is enabled by `org-gtd.el`)
- `SPC -` / `<p> -` toggles narrow/widen (zoom in and out of current subtree)
- `⌘→` narrows to subtree; `⌘←` widens (GUI only)

### Known issues / gaps

- **No `SPC` binding for Search headings** — `SPC f` conflicts with Doom's file search. Use `<p> f` or `⌘ f` instead.
- **No `SPC` binding for Zoom in/out** — `⌘ →` / `⌘ ←` GUI only. `SPC -` / `<p> -` toggle narrow/widen works in all modes.
- **No `SPC` binding for Move up/down** — `<p> p` / `<p> P` and `⌘ ↑` / `⌘ ↓` only.
- **Archive (`SPC y`)** — `my/gtd-archive` wraps `org-archive-subtree` with a `y-or-n-p` confirmation prompt. Subtrees go to `gtd.org_archive`. Recoverable but manual (cut from `_archive`, paste back).
- **Upcoming view duality** — the dashboard "Upcoming" row opens `my/org-upcoming-view` (custom grouped buffer), while `SPC 2` / `<p> 2` / `⌘ 2` open the org-agenda command "2" (flat tags-todo list). These show different output.

### Known Doom Emacs conflicts and workarounds

- **`SPC z`** — conflicts with Doom's zoom/font-size prefix. Use `SPC -` for zoom toggle instead.
- **`RET` in normal mode** — Doom binds `RET` to `+org/dwim-at-point` which toggles TODO states. Fixed in `doom-overrides.el` via `(define-key evil-org-mode-map (kbd "RET") #'org-return)`. Using `evil-define-key` alone is not sufficient because Doom's `evil-org` overrides it — the fix must run `with-eval-after-load 'evil-org`.
- **`C-M-RET`** — Doom inserts a heading with a TODO state. Cleared in `doom-overrides.el`.
- **`s-/` in evil normal state** — `evil-nerd-commenter` binds `s-/` in `evil-normal-state-map`, shadowing the global binding. Fixed in `bindings-cmd.el` with an explicit `evil-normal-state-map` override inside `with-eval-after-load 'evil`.
- **Theme faces** — Doom's `def-doom-theme` macro does not reliably apply custom faces to org-mode buffers at load time. Buffer-local `face-remap-add-relative` can override individual faces but is fragile. Prefer sticking with a standard Doom theme.

### Implementation notes

- **Project scan** in dashboard uses `org-map-entries` to scan all headings. Level-1 headings are identified inline via `(= lvl 1)`. Visibility is determined by `my/gtd--project-visible-p` which checks heading state and scheduled date. It must explicitly enumerate valid project states (`nil`, `"PROJECT"`) and return `nil` as the default — a catch-all `(t t)` will incorrectly show level-1 `NEXT` tasks as projects.
- **Upcoming view** (`my/org-upcoming-view`) is a custom `*GTD Upcoming*` buffer, not an org-agenda buffer. It scans `gtd.org` directly, groups entries by date, and uses text properties (`mouse-face`, `gtd-marker`) for click navigation. State labels are stripped during rendering.
- **Dashboard counts** are computed by a full scan of `gtd.org` on every refresh. Counts refresh on: `org-after-todo-state-change-hook`, `org-schedule`, `org-deadline`, `after-save-hook`, and `evil-insert-state-exit-hook`. The Logbook row intentionally shows no count.
- **Auto-sink** (`my/org-move-done-to-bottom`) runs on `org-after-todo-state-change-hook`. When marking DONE/CANCELLED, it calls `org-move-subtree-down` in a loop, stopping before the first existing closed sibling. This places the task at the top of the done group (not absolute bottom), keeping active tasks above and recently-completed tasks visible.
- **Complete/cancel with children** — `my/gtd-complete` and `my/gtd-cancel` count active descendants. If any exist, they prompt: `Complete 'T1' and 3 child tasks?`. On confirmation, `my/gtd--mark-children-as` marks all active descendants bottom-up (`push` naturally reverses scan order to give bottom-up processing, avoiding intermediate state-change hook triggers), then marks the heading itself. Guards are in place so re-running on already-closed headings is a no-op.
- **State picker** (`my/gtd-set-state`, `⌘e` / `SPC e`) — one-line minibuffer prompt, single keypress via `read-char-choice`, no Enter needed. Options: NEXT, WAIT, SOMEDAY, DONE, CANCEL, Promote to project, quit. `[p] Promote` cuts the subtree, finds `* Inbox`, moves to `org-end-of-subtree` of Inbox, pastes as a level-1 heading immediately after Inbox, then sets state to PROJECT (subtasks carried along automatically). If `* Inbox` is not found, falls back to after the last top-level heading.
- **Refile filtering** — `my/gtd-refile` wraps `org-refile` with `org-refile-target-verify-function` to exclude DONE/CANCELLED headings and the Inbox heading from refile targets.
- **Context tags cache** — `my/org-context-tags` caches the `#+TAGS:` scan result in `my/gtd--context-tags-cache`. The cache is cleared via `after-save-hook` whenever `gtd.org` is saved.
- **Shared internal helpers** — `my/gtd--insert-next-heading` is the shared implementation for `my/org-new-task` and `my/org-new-heading`. They differ in two ways: (1) `level-offset` — `0` for sibling (`⌘n`), `1` for child (`⌘N`); (2) `if-closed` — `'insert-before` for sibling (inserts as first sibling under parent, errors if parent is also closed), `'error` for child (always errors if heading is closed). For sibling insertion, `org-end-of-subtree` is used to skip past the entire subtree including all children. `my/gtd--mark-active-line` is shared by dashboard and upcoming view for overlay highlighting.
- **Hide done** — `my/gtd-toggle-hide-done` (`⌘'` / `SPC '`) hides or reveals all DONE/CANCELLED headings in the buffer using `org-flag-region` on the full heading line plus its subtree. State is tracked with `defvar-local my/gtd--hide-done-active`. `my/gtd--reapply-hide-done` on `org-cycle-hook` re-applies the filter after any S-TAB visibility cycle so it persists.
- **Startup settings** — `org-gtd.el` sets `org-agenda-prefix-format` (hides file prefix in views), enables `winner-mode`, and adds an `org-mode-hook` to disable line numbers. `my/gtd-open-on-startup` (default `t`) controls whether a `window-setup-hook` auto-opens `my/gtd-file` on Emacs launch.
- **Agenda UI** — `q` is bound to `#'ignore` in both `org-agenda-mode-map` and `my/gtd-dashboard-mode-map` to prevent accidental closure. Mode line and cursor are suppressed in agenda buffers. `my/org-agenda-empty-state` inserts contextual placeholders when views have no entries.
- **Smart view opener** — `my/org-open-view` opens agenda views in the right pane when the dashboard is visible. Currently used only by `bindings-doom.el`; `bindings-cmd.el` and `bindings-prefix.el` call `(org-agenda nil KEY)` directly.

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
| New sibling heading | `SPC n` | `<p> n` | `⌘n` |
| New child task | `SPC N` | `<p> N` | `⌘ N` |
| Checklist item | `SPC c` | `<p> c` | `⌘ C` |
| New top-level project | — | — | `⌥ ⌘ n` |
| State picker | `SPC e` | `<p> e` | `⌘e` |
| Complete | `SPC k` | `<p> k` | `⌘ k` |
| Cancel | `SPC K` | `<p> K` | `⌥ ⌘ k` |
| Toggle hide done | `SPC '` | `<p> '` | `⌘ '` |
| Duplicate | `SPC d` | `<p> d` | `⌘ d` |
| Refile | `SPC m` | `<p> m` | `⌘ M` |
| Archive | `SPC y` | `<p> y` | `⌘ Y` |
| Move up | — | `<p> p` | `⌘ ↑` |
| Move down | — | `<p> P` | `⌘ ↓` |
| Move to top | — | — | `⌥ ⌘ ↑` |
| Move to bottom | — | — | `⌥ ⌘ ↓` |
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
| Tags (alt) | — | — | `^ ⌘ T` |
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
- **Subtree ops** — `org-move-subtree-up/down`, `org-copy-subtree`, `org-paste-subtree`, `org-cut-subtree`, `org-archive-subtree`, `org-end-of-subtree`
- **Visibility** — `org-flag-region` for hiding DONE headings
- **Logging** — `org-log-done`
- **Hooks** — `org-after-todo-state-change-hook`, `org-agenda-finalize-hook`, `org-agenda-mode-hook`, `org-cycle-hook`

### Emacs UI / buffer management
- **Custom major mode** — `define-derived-mode` for dashboard (`my/gtd-dashboard-mode`); upcoming view uses `special-mode` directly
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
