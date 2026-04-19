;;; org-gtd.el --- Core GTD setup for org-mode -*- lexical-binding: t; -*-
;; Pure functions and agenda config only. No keybindings.
;; Load this first, then load whichever bindings files you need.

;; ─── Files ───────────────────────────────────────────────────────────────────
;; Set my/gtd-file before loading this file, or you will be prompted.
;; Example: (setq my/gtd-file "~/org/gtd.org")

(defvar my/gtd-file nil
  "Path to your GTD org file. Set before loading: (setq my/gtd-file \"~/path/to/gtd.org\")")

(defvar my/gtd-open-on-startup t
  "If non-nil, open the GTD file automatically on Emacs startup.")

(add-hook 'window-setup-hook
          (lambda ()
            (when my/gtd-open-on-startup
              (if my/gtd-file
                  (find-file my/gtd-file)
                (user-error "org-gtd: Set my/gtd-file before loading, e.g. (setq my/gtd-file \"/path/to/gtd.org\")")))))

(add-hook 'org-mode-hook (lambda () (display-line-numbers-mode 0)))

;; ─── Constants ───────────────────────────────────────────────────────────────
(defconst my/gtd-inbox-heading "Inbox")
(defconst my/gtd-closed-states '("DONE" "CANCELLED"))
(defconst my/gtd-active-states '("NEXT" "WAIT" "SOMEDAY"))
(defconst my/gtd-project-states '(nil "PROJECT"))

;; ─── Winner mode ─────────────────────────────────────────────────────────────
(winner-mode 1)

(with-eval-after-load 'org

  ;; ─── Files ─────────────────────────────────────────────────────────────────
  (when my/gtd-file
    (setq org-agenda-files (list my/gtd-file)))

  ;; ─── Agenda window behaviour ───────────────────────────────────────────────
  (setq org-agenda-window-setup 'current-window)

  ;; ─── Agenda prefix — hide file name prefix ─────────────────────────────────
  (setq org-agenda-prefix-format
        '((agenda . " %i %?-12t% s")
          (todo   . "  ")
          (tags   . "  ")
          (search . " %i %-12:c")))

  ;; ─── Logging ───────────────────────────────────────────────────────────────
  (setq org-log-done 'time)

  ;; ─── Todo keywords ─────────────────────────────────────────────────────────
  (setq org-todo-keywords
        '((sequence "PROJECT" "NEXT" "WAIT" "SOMEDAY" "|" "DONE" "CANCELLED")))

  ;; ─── Refile ────────────────────────────────────────────────────────────────
  (when my/gtd-file
    (setq org-refile-targets
          (list (list my/gtd-file :maxlevel 2))))
  (setq org-refile-use-outline-path 'file)
  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-allow-creating-parent-nodes 'confirm)

  ;; ─── Agenda Views ──────────────────────────────────────────────────────────
  ;; Prepend so keys 0,1,3–6 stay ours (dashboard / bindings); other custom
  ;; agendas from earlier config remain after and keep other letter keys.
  ;; `org-agenda-custom-commands' may not exist until org-agenda loads — guard
  ;; with `boundp' (void-variable if we read it too early).
  (setq org-agenda-custom-commands
        (append
         '(;; 0 — Inbox
           ("0" "Inbox" tags "LEVEL=2"
            ((org-agenda-overriding-header "Inbox")
             (org-agenda-files (list my/gtd-file))
             (org-agenda-skip-function
              '(lambda ()
                 (unless (and (string= (save-excursion
                                         (org-up-heading-safe)
                                         (org-get-heading t t t t))
                                       "Inbox")
                              (not (org-get-todo-state)))
                   (org-end-of-subtree t))))))

           ;; 1 — Today
           ("1" "Today" agenda ""
            ((org-agenda-span 1)
             (org-agenda-start-day nil)
             (org-agenda-overriding-header "Today")
             (org-agenda-prefix-format '((agenda . "  %(my/org-agenda-state-prefix) ")))
             (org-agenda-skip-function
              '(org-agenda-skip-entry-if 'todo '("DONE" "CANCELLED")))))

           ;; 3 — Anytime
           ("3" "Anytime" tags-todo "TODO=\"NEXT\""
            ((org-agenda-overriding-header "Anytime")
             (org-agenda-todo-keyword-format "")
             (org-agenda-skip-function
              '(org-agenda-skip-entry-if 'scheduled 'deadline))))

           ;; 4 — Waiting
           ("4" "Waiting" todo "WAIT"
            ((org-agenda-overriding-header "Waiting — Blocked")
             (org-agenda-todo-keyword-format "")))

           ;; 5 — Someday
           ("5" "Someday" todo "SOMEDAY"
            ((org-agenda-overriding-header "Someday")
             (org-agenda-todo-keyword-format "")))

           ;; 6 — Logbook
           ("6" "Logbook" todo "DONE|CANCELLED"
            ((org-agenda-overriding-header "Logbook — Completed")
             (org-agenda-todo-keyword-format "")
             (org-agenda-sorting-strategy '(timestamp-down)))))
         (if (boundp 'org-agenda-custom-commands)
             org-agenda-custom-commands
           nil))))

;; ─── Dashboard helpers ───────────────────────────────────────────────────────

(defun my/gtd--project-visible-p (htext state sched now-f)
  "Return non-nil if a level-1 heading should appear in the dashboard project list.
HTEXT is the heading text, STATE is the todo state, SCHED is the scheduled time,
NOW-F is the current time as a float."
  (let ((future-p (and sched (> (float-time sched) now-f))))
    (cond
     ((string= htext my/gtd-inbox-heading)    nil)  ; Inbox is never a project
     ((member state my/gtd-closed-states)      nil)  ; DONE/CANCELLED hidden
     ((member state '("WAIT" "SOMEDAY"))       (and sched (not future-p)))  ; only if due
     ((member state my/gtd-project-states)     (not future-p))              ; hide if future
     (t nil))))                                                              ; lone NEXT etc

;; ─── Refile (filtered) ───────────────────────────────────────────────────────

(defun my/gtd-refile ()
  "Refile current task, excluding DONE/CANCELLED headings and Inbox as targets."
  (interactive)
  (let ((org-refile-target-verify-function
         (lambda ()
           (and (not (member (org-get-todo-state) my/gtd-closed-states))
                (not (string= (org-get-heading t t t t) my/gtd-inbox-heading))))))
    (org-refile)))

(defun my/gtd-archive ()
  "Archive current subtree with confirmation."
  (interactive)
  (when (y-or-n-p "Archive this subtree? ")
    (org-archive-subtree)))

(defun my/gtd-duplicate ()
  "Duplicate current subtree, placing the copy immediately after the original."
  (interactive)
  (org-back-to-heading t)
  (org-copy-subtree)
  (org-end-of-subtree t t)
  (org-paste-subtree))

;; ─── New task ────────────────────────────────────────────────────────────────

(defun my/gtd--insert-next-heading (level-offset if-closed)
  "Insert a NEXT heading relative to the current heading.
LEVEL-OFFSET controls depth: 0 = sibling, 1 = child.
IF-CLOSED controls behaviour when the heading has a closed state:
  \\='error        — signal a user-error
  \\='insert-before — insert the new heading before the current one instead."
  (org-back-to-heading t)
  (let ((level (org-outline-level))
        (closed (member (org-get-todo-state) my/gtd-closed-states)))
    (cond
     ((and closed (eq if-closed 'error))
      (user-error "Heading is closed (%s). Re-open it first." (org-get-todo-state)))
     ((and closed (eq if-closed 'insert-before))
      (org-up-heading-safe)
      (when (member (org-get-todo-state) my/gtd-closed-states)
        (user-error "Heading is closed (%s). Re-open it first." (org-get-todo-state)))
      (forward-line 1)
      (while (and (not (eobp))
                  (not (looking-at org-heading-regexp)))
        (forward-line 1))
      (insert (make-string (+ level level-offset) ?*) " NEXT \n")
      (forward-line -1)
      (end-of-line))
     (t
      (if (= level-offset 0)
          ;; Sibling: skip entire subtree (including children)
          (org-end-of-subtree t t)
        ;; Child: skip only body text, stop before first child heading
        (forward-line 1)
        (while (and (not (eobp))
                    (not (looking-at org-heading-regexp)))
          (forward-line 1)))
      (unless (bolp) (newline))
      (insert (make-string (+ level level-offset) ?*) " NEXT \n")
      (forward-line -1)
      (end-of-line)))))

(defun my/org-new-task ()
  "Insert a new NEXT child task under the current heading.
Errors if the current heading is closed."
  (interactive)
  (my/gtd--insert-next-heading 1 'error))

(defun my/org-new-heading ()
  "Insert a new NEXT sibling heading.
If the current heading is closed, inserts before it instead of after."
  (interactive)
  (my/gtd--insert-next-heading 0 'insert-before))

;; ─── Inbox ───────────────────────────────────────────────────────────────────

(defun my/org-open-inbox ()
  "Narrow to Inbox subtree in current file, cursor on a new child heading."
  (interactive)
  (widen)
  (goto-char (point-min))
  (search-forward "* Inbox")
  (org-narrow-to-subtree)
  (goto-char (point-max))
  (unless (bolp) (newline))
  (insert "** ")
  (message "Type task, then zoom out when done"))

;; ─── Context views ───────────────────────────────────────────────────────────

(defvar my/gtd--context-tags-cache nil
  "Cached list of @context tags from gtd.org #+TAGS line.")

(defun my/gtd--context-tags-invalidate ()
  "Clear the context tags cache."
  (setq my/gtd--context-tags-cache nil))

(add-hook 'after-save-hook
          (lambda ()
            (when (and my/gtd-file
                       (string= (buffer-file-name) (expand-file-name my/gtd-file)))
              (my/gtd--context-tags-invalidate))))

(defun my/org-context-tags ()
  "Return all @context tags (with @ prefix) defined in gtd.org #+TAGS line.
Result is cached and invalidated on save."
  (or my/gtd--context-tags-cache
      (setq my/gtd--context-tags-cache
            (with-current-buffer (find-file-noselect (car org-agenda-files))
              (save-restriction
                (widen)
                (save-excursion
                  (goto-char (point-min))
                  (let (tags)
                    (while (re-search-forward "#\\+TAGS:.*" nil t)
                      (let ((line (match-string 0))
                            (start 0))
                        (while (string-match "\\(@[a-zA-Z_]+\\)" line start)
                          (push (match-string 1 line) tags)
                          (setq start (match-end 0)))))
                    (delete-dups tags))))))))

(defun my/org-pick-context ()
  "Prompt for an @context tag and show NEXT tasks for it."
  (interactive)
  (let* ((tag (completing-read "Context: " (my/org-context-tags) nil t))
         (org-agenda-overriding-header tag)
         (org-agenda-todo-keyword-format ""))
    (org-tags-view t (format "%s+TODO=\"NEXT\"" tag))))

(defun my/org-pick-context-all ()
  "Prompt for an @context tag and show ALL tasks for it."
  (interactive)
  (let* ((tag (completing-read "Context: " (my/org-context-tags) nil t))
         (org-agenda-overriding-header tag)
         (org-agenda-todo-keyword-format ""))
    (org-tags-view nil tag)))

;; ─── Hide/show DONE tasks ────────────────────────────────────────────────────

(defvar-local my/gtd--hide-done-active nil
  "Non-nil when the hide-DONE sparse tree filter is active.")

(defun my/gtd--flag-done-headings (flag)
  "Hide (FLAG=t) or show (FLAG=nil) all DONE/CANCELLED headings in the buffer."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward org-heading-regexp nil t)
      (when (member (org-get-todo-state) my/gtd-closed-states)
        (let ((start (line-beginning-position))
              (end (save-excursion (org-end-of-subtree t t) (point))))
          (org-flag-region start end flag 'outline))))))

(defun my/gtd-toggle-hide-done ()
  "Toggle visibility of DONE/CANCELLED headings in the org buffer.
Works on top of the current S-TAB visibility mode."
  (interactive)
  (if my/gtd--hide-done-active
      (progn
        (setq my/gtd--hide-done-active nil)
        (my/gtd--flag-done-headings nil)
        (message "Showing DONE/CANCELLED tasks"))
    (setq my/gtd--hide-done-active t)
    (my/gtd--flag-done-headings t)
    (message "Hiding DONE/CANCELLED — press ⌘' again to restore")))

(defun my/gtd--reapply-hide-done (&rest _)
  "Re-hide DONE/CANCELLED headings after S-TAB cycle if filter is active."
  (when my/gtd--hide-done-active
    (my/gtd--flag-done-headings t)))

(add-hook 'org-cycle-hook #'my/gtd--reapply-hide-done)

;; ─── State picker ────────────────────────────────────────────────────────────

(defun my/gtd-set-state ()
  "Set task state via a one-line mini-prompt. Single keypress, no Enter needed.
[p] promotes the current subtree to a top-level PROJECT."
  (interactive)
  (let ((choice (read-char-choice
                 "State: [n] NEXT  [w] WAIT  [s] SOMEDAY  [k] DONE  [x] CANCEL  [p] Promote to project  [q] quit  "
                 '(?n ?w ?s ?k ?x ?p ?q))))
    (message nil)
    (pcase choice
      (?p (let ((heading (org-get-heading t t t t)))
            (when (y-or-n-p (format "Promote \"%s\" to top-level project? " heading))
              (org-cut-subtree)
              (goto-char (point-min))
              (if (re-search-forward "^\\* Inbox" nil t)
                  (org-end-of-subtree t t)
                (let (last-top)
                  (while (re-search-forward "^\\* " nil t)
                    (setq last-top (match-beginning 0)))
                  (when last-top
                    (goto-char last-top)
                    (org-end-of-subtree t t))))
              (unless (bolp) (newline))
              (org-paste-subtree 1)
              (org-back-to-heading t)
              (org-todo "PROJECT"))))
      (?q nil)
      (?k (my/gtd-complete))
      (?x (my/gtd-cancel))
      (_  (let ((state (cdr (assoc choice '((?n . "NEXT")
                                            (?w . "WAIT")
                                            (?s . "SOMEDAY"))))))
            (when state (org-todo state)))))))

;; ─── Complete / Cancel guards ────────────────────────────────────────────────

(defun my/gtd--collect-active-children ()
  "Collect markers of active (NEXT/WAIT/SOMEDAY) tasks in current subtree.
Returns list in bottom-up order (push reverses scan order)."
  (let ((markers '())
        (end (save-excursion (org-end-of-subtree t) (point))))
    (save-excursion
      (org-back-to-heading t)
      (while (re-search-forward org-heading-regexp end t)
        (when (member (org-get-todo-state) '("NEXT" "WAIT" "SOMEDAY"))
          (push (point-marker) markers))))
    markers))

(defun my/gtd--mark-children-as (state markers)
  "Mark all MARKERS as STATE, bottom-up."
  (dolist (marker markers)
    (goto-char marker)
    (org-todo state)))

(defun my/gtd-complete ()
  "Mark task DONE. No-op if already DONE.
If active tasks exist in subtree, asks to mark them all DONE (including self)."
  (interactive)
  (unless (equal (org-get-todo-state) "DONE")
    (let* ((markers (my/gtd--collect-active-children))
           (count   (length markers)))
      (if (> count 1)
          (when (y-or-n-p (format "Complete \"%s\" and %d child task%s? "
                                  (org-get-heading t t t t)
                                  (1- count)
                                  (if (= count 2) "" "s")))
            (my/gtd--mark-children-as "DONE" markers))
        (org-todo "DONE")))))

(defun my/gtd-cancel ()
  "Mark task CANCELLED. No-op if already CANCELLED.
If active tasks exist in subtree, asks to mark them all CANCELLED (including self)."
  (interactive)
  (unless (equal (org-get-todo-state) "CANCELLED")
    (let* ((markers (my/gtd--collect-active-children))
           (count   (length markers)))
      (if (> count 1)
          (when (y-or-n-p (format "Cancel \"%s\" and %d child task%s? "
                                  (org-get-heading t t t t)
                                  (1- count)
                                  (if (= count 2) "" "s")))
            (my/gtd--mark-children-as "CANCELLED" markers))
        (org-todo "CANCELLED")))))


;; ─── Completed tasks sink to bottom ──────────────────────────────────────────

(defun my/org-move-done-to-bottom ()
  "Move DONE or CANCELLED task just before the first closed sibling.
If no closed siblings exist, moves to the bottom."
  (when (member org-state my/gtd-closed-states)
    (condition-case nil
        (while (save-excursion
                 (and (org-get-next-sibling)
                      (not (member (org-get-todo-state) my/gtd-closed-states))))
          (org-move-subtree-down))
      (error nil))))

(add-hook 'org-after-todo-state-change-hook #'my/org-move-done-to-bottom)

;; ─── Move to top / bottom ────────────────────────────────────────────────

(defun my/org-move-subtree-to-top ()
  "Move the current subtree to the top among its siblings."
  (interactive)
  (condition-case nil
      (while t (org-move-subtree-up))
    (error nil)))

(defun my/org-move-subtree-to-bottom ()
  "Move the current subtree to the bottom among its siblings."
  (interactive)
  (condition-case nil
      (while t (org-move-subtree-down))
    (error nil)))

;; ─── New top-level project ──────────────────────────────────────────────

(defun my/org-new-project ()
  "Insert a new top-level heading at the end of the buffer."
  (interactive)
  (goto-char (point-max))
  (org-insert-heading)
  (org-promote-subtree))

;; ─── Zoom toggle ─────────────────────────────────────────────────────────────

(defun my/org-zoom-toggle ()
  "Toggle between narrowing to subtree and widening."
  (interactive)
  (if (buffer-narrowed-p)
      (widen)
    (org-narrow-to-subtree)))

;; ─── Auto-open dashboard ─────────────────────────────────────────────────────

(defun my/gtd-maybe-open-dashboard ()
  "Open dashboard automatically when the GTD file is visited."
  (when (and (buffer-file-name)
             (string= (expand-file-name (buffer-file-name))
                      (expand-file-name my/gtd-file))
             (not (get-buffer-window "*GTD*")))
    (my/org-dashboard--open)))

(add-hook 'find-file-hook #'my/gtd-maybe-open-dashboard)

;; ─── Switch file ─────────────────────────────────────────────────────────────

(defun my/gtd-switch-file ()
  "Close all buffers and switch to a different GTD org file."
  (interactive)
  (let ((file (read-file-name "GTD file: " nil nil t nil
                              (lambda (f) (string-suffix-p ".org" f)))))
    ;; Save current GTD file if modified
    (let ((old-buf (get-file-buffer my/gtd-file)))
      (when (and old-buf (buffer-modified-p old-buf))
        (with-current-buffer old-buf (save-buffer))))
    ;; Kill all buffers except *scratch* and *Messages*
    (dolist (buf (buffer-list))
      (unless (member (buffer-name buf) '("*scratch*" "*Messages*"))
        (kill-buffer buf)))
    ;; Point everything at the new file
    (setq my/gtd-file (expand-file-name file))
    (setq org-agenda-files (list my/gtd-file))
    (setq org-refile-targets (list (list my/gtd-file :maxlevel 2)))
    (setq my/gtd--context-tags-cache nil)
    (delete-other-windows)
    (find-file my/gtd-file)
    (my/org-dashboard)))

;; ─── Auto-save ───────────────────────────────────────────────────────────────

(defun my/gtd-auto-save ()
  "Save the GTD file if it has unsaved changes."
  (let ((buf (get-file-buffer my/gtd-file)))
    (when (and buf (buffer-modified-p buf))
      (with-current-buffer buf (save-buffer)))))

(defun my/gtd-after-save-refresh ()
  "Refresh dashboard when the GTD file is saved."
  (when (string= (expand-file-name (buffer-file-name))
                 (expand-file-name my/gtd-file))
    (my/gtd-auto-refresh)))

(add-hook 'after-save-hook #'my/gtd-after-save-refresh)

(run-with-idle-timer 2 t #'my/gtd-auto-save)

(with-eval-after-load 'evil
  (add-hook 'evil-insert-state-exit-hook #'my/gtd-auto-save)
  (add-hook 'evil-insert-state-exit-hook #'my/gtd-auto-refresh))
(add-hook 'org-after-todo-state-change-hook #'my/gtd-auto-refresh)
(advice-add 'org-schedule :after (lambda (&rest _) (my/gtd-auto-refresh)))
(advice-add 'org-deadline :after (lambda (&rest _) (my/gtd-auto-refresh)))

(defvar my/gtd--refresh-timer nil
  "Idle timer used to debounce dashboard/agenda refreshes.")

(defun my/gtd--do-refresh ()
  "Actually refresh dashboard and agenda views.
Skips entirely if no dashboard or agenda buffer is visible."
  (setq my/gtd--refresh-timer nil)
  (let ((dash-visible (get-buffer-window "*GTD*"))
        (agenda-wins '()))
    (dolist (win (window-list))
      (with-current-buffer (window-buffer win)
        (when (derived-mode-p 'org-agenda-mode)
          (push win agenda-wins))))
    (when (or dash-visible agenda-wins)
      (when dash-visible
        (my/org-dashboard--open))
      (dolist (win agenda-wins)
        (with-current-buffer (window-buffer win)
          (let ((match org-agenda-query-string))
            (cl-letf (((symbol-function 'completing-read)
                       (lambda (&rest _) match)))
              (org-agenda-redo t))))))))

(defun my/gtd-auto-refresh ()
  "Schedule a debounced refresh of dashboard and agenda views.
Multiple calls within 0.3s collapse into a single refresh."
  (when my/gtd--refresh-timer
    (cancel-timer my/gtd--refresh-timer))
  (setq my/gtd--refresh-timer
        (run-with-idle-timer 0.3 nil #'my/gtd--do-refresh)))

;; ─── Agenda mouse click ──────────────────────────────────────────────────────

(defun my/org-agenda-state-prefix ()
  "Return the TODO state of the current agenda entry, for use in prefix-format."
  (or (org-get-at-bol 'todo-state) ""))

(defun my/org-agenda-goto-zoomed ()
  "Open task narrowed to its subtree in the right pane."
  (interactive)
  (let ((marker (or (org-get-at-bol 'org-marker)
                    (org-get-at-bol 'org-hd-marker))))
    (when marker
      (let ((agenda-win (selected-window)))
        (with-selected-window (or (window-in-direction 'right agenda-win)
                                  agenda-win)
          (org-goto-marker-or-bmk marker)
          (widen)
          (org-narrow-to-subtree)
          (goto-char (point-min)))))))

;; ─── Logbook: strikethrough CANCELLED entries ────────────────────────────────

(defun my/org-agenda-task-text-bounds ()
  "Return (start . end) of just the task text on the current line, excluding tags."
  (save-excursion
    (let* ((bol (line-beginning-position))
           (eol (line-end-position))
           ;; tags are at end of line like :tag1:tag2:
           (tag-start (save-excursion
                        (goto-char eol)
                        (if (re-search-backward "[ \t]+:[a-zA-Z0-9_@:]+:[ \t]*$" bol t)
                            (match-beginning 0)
                          eol)))
           ;; task text starts after leading whitespace
           (text-start (save-excursion
                         (goto-char bol)
                         (skip-chars-forward " \t")
                         (point))))
      (when (< text-start tag-start)
        (cons text-start tag-start)))))

(defun my/org-agenda-apply-logbook-faces ()
  "Apply faces to DONE/CANCELLED entries in agenda buffers."
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (let ((state (get-text-property (point) 'todo-state)))
        (cond
         ((equal state "CANCELLED")
          (when-let ((bounds (my/org-agenda-task-text-bounds)))
            (add-face-text-property (car bounds) (cdr bounds)
                                    '(:strike-through t))))
         ((equal state "DONE")
          (save-excursion
            (goto-char (line-beginning-position))
            (when (re-search-forward "\\S-" (line-end-position) t)
              (goto-char (match-beginning 0))
              (insert "✓ "))))))
      (forward-line 1))))

(defun my/org-agenda-empty-state ()
  "Insert a placeholder message when the agenda buffer has no entries."
  (save-excursion
    (goto-char (point-min))
    ;; Skip the header line(s); look for any task entry
    (let ((header-end (or (re-search-forward "^-+$" nil t) (point-min))))
      (goto-char header-end)
      (forward-line 1)
      (when (eobp)
        (let ((inhibit-read-only t)
              (msg (cond
                    ((string-match-p "Today\\|agenda" (or org-agenda-overriding-header ""))
                     "\n  Nothing due today.\n")
                    ((string-match-p "Anytime" (or org-agenda-overriding-header ""))
                     "\n  No actionable tasks.\n")
                    ((string-match-p "Waiting" (or org-agenda-overriding-header ""))
                     "\n  Nothing waiting.\n")
                    ((string-match-p "Someday" (or org-agenda-overriding-header ""))
                     "\n  No someday items.\n")
                    ((string-match-p "Logbook" (or org-agenda-overriding-header ""))
                     "\n  No completed tasks.\n")
                    (t "\n  No tasks.\n"))))
          (insert (propertize msg 'face 'shadow)))))))

(add-hook 'org-agenda-finalize-hook #'my/org-agenda-apply-logbook-faces)
(add-hook 'org-agenda-finalize-hook #'my/org-agenda-empty-state)
(add-hook 'org-agenda-mode-hook (lambda ()
                                  (setq-local mode-line-format nil)
                                  (setq-local cursor-type nil)))

(with-eval-after-load 'org-agenda
  (define-key org-agenda-mode-map (kbd "q") #'ignore)
  (define-key org-agenda-mode-map [mouse-1]
    (lambda (event)
      (interactive "e")
      (mouse-set-point event)
      (my/org-agenda-goto-zoomed))))


;; ─── Smart view opener ───────────────────────────────────────────────────────

(defun my/org-open-view (key)
  "Open agenda view KEY. If the dashboard is visible, open in the right pane."
  (let ((dash-win (get-buffer-window "*GTD*")))
    (if dash-win
        (with-selected-window (or (window-in-direction 'right dash-win) dash-win)
          (org-agenda nil key))
      (org-agenda nil key))))

(defun my/org-open-upcoming ()
  "Open the Upcoming view. If the dashboard is visible, open in the right pane."
  (interactive)
  (let ((dash-win (get-buffer-window "*GTD*")))
    (if dash-win
        (with-selected-window (or (window-in-direction 'right dash-win) dash-win)
          (my/org-upcoming-view))
      (my/org-upcoming-view))))

;; ─── Dashboard ───────────────────────────────────────────────────────────────

(define-derived-mode my/gtd-dashboard-mode special-mode "GTD"
  "Live count dashboard for org-gtd. RET opens the view at point."
  (setq-local mode-line-format nil))
(define-key my/gtd-dashboard-mode-map (kbd "RET")   #'my/gtd-dashboard-activate)
(define-key my/gtd-dashboard-mode-map (kbd "g")     #'my/org-dashboard--open)
(define-key my/gtd-dashboard-mode-map (kbd "q")     #'ignore)
(define-key my/gtd-dashboard-mode-map [mouse-1]     #'my/gtd-dashboard-mouse-activate)

(defun my/gtd--mark-active-line (buf-name ov-var)
  "Highlight the current line in BUF-NAME, storing overlay in OV-VAR."
  (when-let ((buf (get-buffer buf-name)))
    (with-current-buffer buf
      (when (overlayp (symbol-value ov-var))
        (delete-overlay (symbol-value ov-var)))
      (set ov-var (make-overlay (line-beginning-position) (line-end-position)))
      (overlay-put (symbol-value ov-var) 'face 'secondary-selection))))

(defvar my/gtd-dashboard--active-ov nil
  "Overlay marking the currently active dashboard row.")

(defun my/gtd-dashboard-mark-active ()
  "Highlight the current dashboard row as active."
  (my/gtd--mark-active-line "*GTD*" 'my/gtd-dashboard--active-ov))

(defun my/gtd-dashboard-mouse-activate (event)
  "Mouse click handler — move point to click position then open view."
  (interactive "e")
  (mouse-set-point event)
  (my/gtd-dashboard-activate))

(defun my/gtd-dashboard-activate ()
  "Open the GTD view for the current row in the right pane."
  (interactive)
  (when-let ((action (get-text-property (point) 'gtd-action)))
    (my/gtd-dashboard-mark-active)
    (let ((right (window-in-direction 'right)))
      (if right
          (with-selected-window right (funcall action))
        (funcall action)))))

(defvar my/org-upcoming--active-ov nil
  "Overlay marking the currently selected upcoming row.")

(defun my/org-upcoming-mark-active ()
  "Highlight the current line in the upcoming view."
  (my/gtd--mark-active-line "*GTD Upcoming*" 'my/org-upcoming--active-ov))

(defun my/org-upcoming-goto ()
  "Open the task at point in the right pane, narrowed to its subtree."
  (interactive)
  (my/org-upcoming-mark-active)
  (when-let ((mark (get-text-property (point) 'gtd-marker)))
    (let ((upcoming-win (get-buffer-window "*GTD Upcoming*")))
      (with-selected-window (or (and upcoming-win (window-in-direction 'right upcoming-win))
                                (selected-window))
        (switch-to-buffer (marker-buffer mark))
        (widen)
        (goto-char mark)
        (org-narrow-to-subtree)
        (goto-char (point-min))))))

(defun my/org-upcoming-mouse-goto (event)
  "Mouse click handler for upcoming view."
  (interactive "e")
  (mouse-set-point event)
  (my/org-upcoming-mark-active)
  (my/org-upcoming-goto))

(defun my/org-upcoming-view ()
  "Show all upcoming scheduled tasks grouped by day (within 7 days) then month."
  (interactive)
  (let* ((entries '())
         (now-f      (float-time))
         (today-d    (decode-time))
         (today-start (float-time
                       (encode-time 0 0 0
                                    (nth 3 today-d) (nth 4 today-d) (nth 5 today-d)))))
    (with-current-buffer (find-file-noselect my/gtd-file)
      (save-restriction
        (widen)
        (org-map-entries
         (lambda ()
           (let* ((state (org-get-todo-state))
                  (sched (org-get-scheduled-time (point))))
             (when (and state
                        (not (member state '("DONE" "CANCELLED" "SOMEDAY")))
                        sched
                        (>= (float-time sched) today-start))
               (push (list (float-time sched)
                           (org-get-heading t t t t)
                           state
                           (point-marker))
                     entries))))
         nil 'file)))
    (setq entries (sort entries (lambda (a b) (< (car a) (car b)))))
    (let ((buf (get-buffer-create "*GTD Upcoming*")))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (special-mode)
          (setq-local mode-line-format nil)
          (use-local-map (copy-keymap special-mode-map))
          (local-set-key (kbd "q") #'delete-window)
          (local-set-key (kbd "RET") #'my/org-upcoming-goto)
          (local-set-key [mouse-1] #'my/org-upcoming-mouse-goto)
          (with-eval-after-load 'evil
            (evil-local-set-key 'normal (kbd "q")   #'delete-window)
            (evil-local-set-key 'normal (kbd "RET") #'my/org-upcoming-goto))
          (insert "\n")
          (let ((current-section nil))
            (dolist (entry entries)
              (pcase-let* ((`(,sched-f ,htext ,state ,mark) entry)
                           (days    (/ (- sched-f today-start) 86400))
                           (section (cond
                                     ((< days 1) nil)
                                     ((< days 2) "Tomorrow")
                                     ((< days 7)
                                      (nth (nth 6 (decode-time (seconds-to-time sched-f)))
                                           '("Sunday" "Monday" "Tuesday" "Wednesday"
                                             "Thursday" "Friday" "Saturday")))
                                     (t (format-time-string "%B" (seconds-to-time sched-f))))))
                (when section
                  (unless (equal section current-section)
                    (setq current-section section)
                    (insert (format "\n  %s\n" section)))
                  (let ((start (point)))
                    (insert (format "    %s\n" htext))
                    (add-text-properties start (1- (point))
                                         (list 'gtd-marker mark 'mouse-face 'highlight)))))))
          (goto-char (point-min))))
      (let ((dash-win (get-buffer-window "*GTD*")))
        (if dash-win
            (with-selected-window (or (window-in-direction 'right dash-win) dash-win)
              (switch-to-buffer buf))
          (switch-to-buffer buf))))))

(defun my/org-open-project (marker)
  "Open the project at MARKER narrowed to its subtree in the right pane."
  (let ((dash-win (get-buffer-window "*GTD*")))
    (with-selected-window (or (and dash-win (window-in-direction 'right dash-win))
                              (selected-window))
      (switch-to-buffer (marker-buffer marker))
      (widen)
      (goto-char marker)
      (org-narrow-to-subtree)
      (goto-char (point-min)))))

(defun my/org-dashboard ()
  "Toggle the GTD dashboard. If visible, close it; otherwise open it."
  (interactive)
  (let ((dash-win (get-buffer-window "*GTD*")))
    (if dash-win
        (delete-window dash-win)
      (my/org-dashboard--open))))

(defun my/org-dashboard--open ()
  "Open and render the GTD dashboard."
  (let* ((context-tags (my/org-context-tags))
         (today-d (let ((d (decode-time))) (list (nth 4 d) (nth 3 d) (nth 5 d))))
         (now-f   (float-time))
         (inbox 0) (today 0) (upcoming 0) (anytime 0) (waiting 0) (someday 0)
         (ctx-counts (mapcar (lambda (tag) (cons tag 0)) context-tags))
         (no-ctx 0)
         (proj-names '()) (proj-data (make-hash-table :test 'equal)) (current-l1 nil))
    (with-current-buffer (find-file-noselect my/gtd-file)
      (save-restriction
        (widen)
        (org-map-entries
         (lambda ()
           (let* ((state  (org-get-todo-state))
                  (tags   (org-get-tags))
                  (sched  (org-get-scheduled-time (point)))
                  (dead   (org-get-deadline-time  (point)))
                  (active (and state (not (member state '("DONE" "CANCELLED" "SOMEDAY")))))
                  (ctx    (seq-find (lambda (tg) (string-prefix-p "@" tg)) tags))
                  (lvl    (org-outline-level))
                  (htext  (org-get-heading t t t t)))
             (if (= lvl 1)
               (if (my/gtd--project-visible-p htext state sched now-f)
                   (progn
                     (setq current-l1 htext)
                     (push htext proj-names)
                     (puthash htext (vector 0 0 (point-marker) 0) proj-data))
                 (setq current-l1 nil))
             (when (and current-l1 state)
               (let ((v (gethash current-l1 proj-data)))
                 (when v
                   (aset v 1 (1+ (aref v 1)))
                   (when (member state my/gtd-active-states)
                     (aset v 0 (1+ (aref v 0))))
                   (when (equal state "NEXT")
                     (aset v 3 (1+ (aref v 3))))))))
           ;; Inbox: level-2 headings under "* Inbox" with no todo state
           (when (and (not state)
                      (= (org-outline-level) 2)
                      (save-excursion
                        (org-up-heading-safe)
                        (string= (org-get-heading t t t t) my/gtd-inbox-heading)))
             (cl-incf inbox))
           ;; Today: scheduled/deadline today or overdue
           (when (and active
                      (or (and sched (<= (float-time sched) (+ now-f 86400))
                               (equal (let ((s (decode-time sched)))
                                        (list (nth 4 s) (nth 3 s) (nth 5 s)))
                                      today-d))
                          (and dead  (<= (float-time dead) now-f))))
             (cl-incf today))
           ;; Upcoming: all future scheduled tasks
           (when (and active sched (> (float-time sched) now-f))
             (cl-incf upcoming))
           ;; Anytime: NEXT with no schedule and no deadline
           (when (and (equal state "NEXT") (not sched) (not dead))
             (cl-incf anytime))
           ;; Waiting / Someday
           (when (equal state "WAIT")      (cl-incf waiting))
           (when (equal state "SOMEDAY")   (cl-incf someday))
           ;; Context: all NEXT tasks, by @tag
           (when (equal state "NEXT")
             (if ctx
                 (when-let ((cell (assoc ctx ctx-counts))) (cl-incf (cdr cell)))
               (cl-incf no-ctx)))))
       nil 'file)))
    ;; ── Render ────────────────────────────────────────────────────────────────
    (let ((buf (get-buffer-create "*GTD*")))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (my/gtd-dashboard-mode)

          (insert "\n")
          (my/org--dash-row "Inbox"    inbox    (lambda () (my/org-open-view "0")))
          (my/org--dash-row "Today"    today    (lambda () (my/org-open-view "1")))
          (my/org--dash-row "Upcoming" upcoming #'my/org-open-upcoming)
          (my/org--dash-row "Anytime"  anytime  (lambda () (my/org-open-view "3")))
          (my/org--dash-row "Waiting"  waiting  (lambda () (my/org-open-view "4")))
          (my/org--dash-row "Someday"  someday  (lambda () (my/org-open-view "5")))
          (my/org--dash-row "Logbook"  0        (lambda () (my/org-open-view "6")))
          (when proj-names
            (insert "\n")
            (my/org--dash-section-label "Projects")
            (dolist (name (nreverse proj-names))
              (let* ((v         (gethash name proj-data))
                     (active    (aref v 0))
                     (total     (aref v 1))
                     (mark      (aref v 2))
                     (has-next  (aref v 3))
                     (indicator (cond ((= total 0)    "?")
                                     ((> has-next 0)  "")
                                     ((> active 0)    "~")
                                     (t               "●")))
                     (max-len   (- (window-width) 6))
                     (display   (if (> (length name) max-len)
                                   (concat (substring name 0 (1- max-len)) "…")
                                 name))
                     (label     (if (string= indicator "")
                                   display
                                 (concat indicator " " display)))
                     (start     (point))
                     (action    (let ((m mark)) (lambda () (my/org-open-project m)))))
                (insert (format "  %s\n" label))
                (add-text-properties start (- (point) 1)
                                     (list 'gtd-action action
                                           'mouse-face 'highlight
                                           'face 'default)))))
          (when context-tags
            (insert "\n")
            (my/org--dash-section-label "Contexts")
            (dolist (pair ctx-counts)
              (let ((tag (car pair)) (n (cdr pair)))
                (my/org--dash-row tag n
                                  (let ((tg tag))
                                    (lambda ()
                                      (let ((org-agenda-overriding-header tg)
                                            (org-agenda-todo-keyword-format ""))
                                        (org-tags-view t (format "%s+TODO=\"NEXT\"" tg))))))))
            (let ((no-ctx-match
                   (concat "TODO=\"NEXT\""
                           (mapconcat (lambda (tg) (concat "-" tg)) context-tags ""))))
              (my/org--dash-row "No context" no-ctx
                                (let ((m no-ctx-match))
                                  (lambda ()
                                    (let ((org-agenda-overriding-header "No context")
                                          (org-agenda-todo-keyword-format ""))
                                      (org-tags-view t m)))))))
          (insert "\n")
          (goto-char (point-min))))
      ;; Setup windows only on first open; refresh just updates buffer content
      (if (get-buffer-window buf)
          (with-current-buffer buf (goto-char (point-min)))
        (delete-other-windows)
        (switch-to-buffer buf)
        (let ((right (split-window-right (floor (* 0.3 (frame-width))))))
          (let ((rbuf (find-file-noselect my/gtd-file)))
            (set-window-buffer right rbuf)
            (with-current-buffer rbuf
              (setq-local mode-line-format nil))))))))

(defun my/org--dash-section-label (text)
  "Insert a non-clickable grey section label TEXT in the dashboard."
  (let ((start (point)))
    (insert (format "  %s\n" text))
    (add-text-properties start (point)
                         '(face (:inherit shadow :height 1.0)))))

(defun my/org--dash-row (label count action)
  "Insert one dashboard row with LABEL, COUNT, and ACTION on RET."
  (let ((start (point)))
    (insert (format "  %-14s%s" label
                    (cond ((or (equal count "") (eql count 0)) "")
                          ((stringp count) (format " %s" count))
                          (t (format " %d" count)))))
    (add-text-properties start (point)
                         (list 'gtd-action action 'mouse-face 'highlight)))
  (insert "\n"))

;; ─── Help ────────────────────────────────────────────────────────────────────

(defvar my/gtd-help-mode-map (make-sparse-keymap)
  "Keymap for GTD help buffer.")

(define-derived-mode my/gtd-help-mode special-mode "GTD Help"
  "Interactive GTD keybinding cheatsheet. Press any key to execute."
  (setq-local mode-line-format nil)
  (setq-local cursor-type nil))

(defun my/gtd-help--bind (key fn)
  "Bind KEY in help buffer to close help then call FN."
  (define-key my/gtd-help-mode-map (kbd key)
    (lambda () (interactive)
      (quit-window)
      (call-interactively fn))))

(defun my/gtd-help--bind-view (key view-key)
  "Bind KEY in help buffer to close help then open agenda view VIEW-KEY."
  (define-key my/gtd-help-mode-map (kbd key)
    (lambda () (interactive)
      (quit-window)
      (my/org-open-view view-key))))

;; Views
(my/gtd-help--bind "/" #'my/org-dashboard)
(my/gtd-help--bind-view "0" "0")
(my/gtd-help--bind-view "1" "1")
(my/gtd-help--bind "2" #'my/org-open-upcoming)
(my/gtd-help--bind-view "3" "3")
(my/gtd-help--bind-view "4" "4")
(my/gtd-help--bind-view "5" "5")
(my/gtd-help--bind-view "6" "6")
(my/gtd-help--bind "7" #'my/org-pick-context)
(my/gtd-help--bind "8" #'my/org-pick-context-all)
(my/gtd-help--bind "i" #'my/org-open-inbox)

;; Create
(my/gtd-help--bind "n" #'my/org-new-heading)
(my/gtd-help--bind "N" #'my/org-new-task)
(my/gtd-help--bind "a" #'my/org-new-project)
(define-key my/gtd-help-mode-map (kbd "c")
  (lambda () (interactive)
    (quit-window)
    (end-of-line) (newline) (insert "- [ ] ")))

;; Edit
(my/gtd-help--bind "e" #'my/gtd-set-state)
(my/gtd-help--bind "k" #'my/gtd-complete)
(my/gtd-help--bind "K" #'my/gtd-cancel)
(my/gtd-help--bind "d" #'my/gtd-duplicate)
(my/gtd-help--bind "y" #'my/gtd-archive)
(my/gtd-help--bind "'" #'my/gtd-toggle-hide-done)

;; Move
(my/gtd-help--bind "<up>" #'org-move-subtree-up)
(my/gtd-help--bind "<down>" #'org-move-subtree-down)
(my/gtd-help--bind "{" #'my/org-move-subtree-to-top)
(my/gtd-help--bind "}" #'my/org-move-subtree-to-bottom)
(my/gtd-help--bind "M" #'my/gtd-refile)

;; Dates
(my/gtd-help--bind "s" #'org-schedule)
(define-key my/gtd-help-mode-map (kbd "t")
  (lambda () (interactive) (quit-window) (org-schedule nil ".")))
(define-key my/gtd-help-mode-map (kbd "r")
  (lambda () (interactive) (quit-window) (org-schedule '(4))))
(define-key my/gtd-help-mode-map (kbd "o")
  (lambda () (interactive) (quit-window) (org-todo "SOMEDAY")))
(my/gtd-help--bind "D" #'org-deadline)

;; Navigate
(my/gtd-help--bind "-" #'my/org-zoom-toggle)
(my/gtd-help--bind "[" #'winner-undo)
(define-key my/gtd-help-mode-map (kbd "f")
  (lambda () (interactive)
    (quit-window)
    (if (fboundp 'consult-org-heading) (consult-org-heading) (occur "^\\*+ "))))
(my/gtd-help--bind "T" #'org-set-tags-command)

;; Close
(define-key my/gtd-help-mode-map (kbd "q") #'quit-window)
(define-key my/gtd-help-mode-map (kbd "?") #'quit-window)

(defun my/gtd-help--row (key1 label1 &optional key2 label2)
  "Insert one or two help entries on a line."
  (let ((col1 (format "  %s  %-22s" (propertize (format "%-4s" key1) 'face 'bold) label1)))
    (insert col1)
    (when key2
      (insert (format "  %s  %s" (propertize (format "%-4s" key2) 'face 'bold) label2)))
    (insert "\n")))

(defun my/gtd-help ()
  "Open interactive GTD help in the right pane. Toggle if already open."
  (interactive)
  (let ((existing (get-buffer-window "*GTD Help*")))
    (if existing
        (quit-window nil existing)
      (let ((buf (get-buffer-create "*GTD Help*")))
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (erase-buffer)
            (my/gtd-help-mode)
            (insert "\n")
            (insert (propertize "  GTD Help" 'face '(:weight bold :height 1.1)))
            (insert (propertize " — press any key to run\n\n" 'face 'shadow))

            (my/org--dash-section-label "Views")
            (my/gtd-help--row "/"  "Dashboard toggle"    "0"  "Inbox view")
            (my/gtd-help--row "1"  "Today"               "2"  "Upcoming")
            (my/gtd-help--row "3"  "Anytime"             "4"  "Waiting")
            (my/gtd-help--row "5"  "Someday"             "6"  "Logbook")
            (my/gtd-help--row "7"  "Context (NEXT)"      "8"  "Context (all)")
            (my/gtd-help--row "i"  "Open Inbox")

            (insert "\n")
            (my/org--dash-section-label "Create")
            (my/gtd-help--row "n"  "New sibling"         "N"  "New child task")
            (my/gtd-help--row "a"  "New project"         "c"  "Checklist item")

            (insert "\n")
            (my/org--dash-section-label "Edit")
            (my/gtd-help--row "e"  "State picker"        "k"  "Complete")
            (my/gtd-help--row "K"  "Cancel"              "d"  "Duplicate")
            (my/gtd-help--row "y"  "Archive"             "'"  "Hide/show done")

            (insert "\n")
            (my/org--dash-section-label "Move")
            (my/gtd-help--row "↑"  "Move up"             "↓"  "Move down")
            (my/gtd-help--row "{"  "Move to top"         "}"  "Move to bottom")
            (my/gtd-help--row "M"  "Refile")

            (insert "\n")
            (my/org--dash-section-label "Dates")
            (my/gtd-help--row "s"  "Schedule"            "t"  "Schedule today")
            (my/gtd-help--row "r"  "Remove schedule"     "o"  "Someday")
            (my/gtd-help--row "D"  "Deadline")

            (insert "\n")
            (my/org--dash-section-label "Navigate")
            (my/gtd-help--row "-"  "Zoom toggle"         "["  "Go back")
            (my/gtd-help--row "T"  "Tags"                "f"  "Search headings")

            (insert "\n")
            (my/gtd-help--row "q"  "Close help")

            (goto-char (point-min))))
        ;; Open in right pane if dashboard visible, and focus it
        (let* ((dash-win (get-buffer-window "*GTD*"))
               (target (if dash-win
                           (or (window-in-direction 'right dash-win) dash-win)
                         (selected-window))))
          (set-window-buffer target buf)
          (select-window target))))))

(provide 'org-gtd)
;;; org-gtd.el ends here
