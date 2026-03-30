;;; org-gtd.el --- Core GTD setup for org-mode -*- lexical-binding: t; -*-
;; Pure functions and agenda config only. No keybindings.
;; Load this first, then load whichever bindings files you need.

;; ─── Files ───────────────────────────────────────────────────────────────────
;; Set my/gtd-file before loading this file, or you will be prompted.
;; Example: (setq my/gtd-file "~/org/gtd.org")

(defvar my/gtd-file nil
  "Path to your GTD org file. Set before loading: (setq my/gtd-file \"~/path/to/gtd.org\")")

(setq org-agenda-files (list my/gtd-file))

;; ─── Logging ─────────────────────────────────────────────────────────────────

(setq org-log-done 'time)

;; ─── Todo keywords ───────────────────────────────────────────────────────────

(setq org-todo-keywords
      '((sequence "PROJECT" "NEXT" "WAIT" "SOMEDAY" "|" "DONE" "CANCELLED")))

;; ─── Refile ──────────────────────────────────────────────────────────────────

(setq org-refile-targets
      (list (list my/gtd-file :maxlevel 2)))
(setq org-refile-use-outline-path t)
(setq org-outline-path-complete-in-steps nil)
(setq org-refile-allow-creating-parent-nodes 'confirm)

;; ─── Agenda Views ────────────────────────────────────────────────────────────

(setq org-agenda-custom-commands
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

        ;; 2 — Upcoming
        ("2" "Upcoming" tags-todo "SCHEDULED>=\"<today>\""
         ((org-agenda-overriding-header "Upcoming")
          (org-agenda-sorting-strategy '(scheduled-up))
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
          (org-agenda-sorting-strategy '(timestamp-down))))))

;; ─── New task ────────────────────────────────────────────────────────────────

(defun my/org-new-task ()
  "Insert a new child heading with NEXT state under the current heading."
  (interactive)
  (org-insert-subheading nil)
  (org-todo "NEXT"))

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

(defun my/org-context-tags ()
  "Return all @context tags (with @ prefix) defined in gtd.org #+TAGS line."
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
          (delete-dups tags))))))

(defun my/org-pick-context ()
  "Prompt for an @context tag and show NEXT tasks for it."
  (interactive)
  (let ((tag (completing-read "Context: " (my/org-context-tags) nil t)))
    (let ((org-agenda-overriding-header tag)
          (org-agenda-todo-keyword-format ""))
      (org-tags-view t (format "%s+TODO=\"NEXT\"" tag)))))

(defun my/org-pick-context-all ()
  "Prompt for an @context tag and show ALL tasks for it."
  (interactive)
  (let ((tag (completing-read "Context: " (my/org-context-tags) nil t)))
    (let ((org-agenda-overriding-header tag)
          (org-agenda-todo-keyword-format ""))
      (org-tags-view nil tag))))

;; ─── Completed tasks sink to bottom ──────────────────────────────────────────

(defun my/org-move-done-to-bottom ()
  "Move DONE or CANCELLED task to bottom of its sibling list."
  (when (member org-state '("DONE" "CANCELLED"))
    (condition-case nil
        (while t (org-move-subtree-down))
      (error nil))))

(add-hook 'org-after-todo-state-change-hook #'my/org-move-done-to-bottom)

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
    (my/org-dashboard)))

(add-hook 'find-file-hook #'my/gtd-maybe-open-dashboard)

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

(defun my/gtd-auto-refresh ()
  "Refresh dashboard counts and agenda view after a task state change."
  ;; Refresh dashboard buffer in place (no window changes)
  (when (get-buffer-window "*GTD*")
    (my/org-dashboard))
  ;; Refresh agenda views in place without re-prompting
  (dolist (win (window-list))
    (with-current-buffer (window-buffer win)
      (when (derived-mode-p 'org-agenda-mode)
        (let ((match org-agenda-query-string))
          (cl-letf (((symbol-function 'completing-read)
                     (lambda (&rest _) match)))
            (org-agenda-redo t)))))))

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

(add-hook 'org-agenda-finalize-hook #'my/org-agenda-apply-logbook-faces)
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

(with-eval-after-load 'evil
  (with-eval-after-load 'org-agenda
    (evil-define-key '(normal motion) org-agenda-mode-map
      (kbd "RET") #'my/org-agenda-goto-zoomed
      (kbd "q")   #'ignore)))

;; ─── Smart view opener ───────────────────────────────────────────────────────

(defun my/org-open-view (key)
  "Open agenda view KEY. If the dashboard is visible, open in the right pane."
  (let ((dash-win (get-buffer-window "*GTD*")))
    (if dash-win
        (with-selected-window (or (window-in-direction 'right dash-win) dash-win)
          (org-agenda nil key))
      (org-agenda nil key))))

;; ─── Dashboard ───────────────────────────────────────────────────────────────

(define-derived-mode my/gtd-dashboard-mode special-mode "GTD"
  "Live count dashboard for org-gtd. RET opens the view at point."
  (setq-local mode-line-format nil))
(define-key my/gtd-dashboard-mode-map (kbd "RET")   #'my/gtd-dashboard-activate)
(define-key my/gtd-dashboard-mode-map (kbd "g")     #'my/org-dashboard)
(define-key my/gtd-dashboard-mode-map (kbd "q")     #'ignore)
(define-key my/gtd-dashboard-mode-map [mouse-1]     #'my/gtd-dashboard-mouse-activate)
;; Evil-mode: bind RET in normal state so it isn't shadowed by evil-ret
(with-eval-after-load 'evil
  (evil-define-key 'normal my/gtd-dashboard-mode-map (kbd "RET") #'my/gtd-dashboard-activate)
  (evil-define-key 'normal my/gtd-dashboard-mode-map (kbd "g")   #'my/org-dashboard)
  (evil-define-key 'normal my/gtd-dashboard-mode-map (kbd "q")   #'ignore))

(defvar my/gtd-dashboard--active-ov nil
  "Overlay marking the currently active dashboard row.")

(defun my/gtd-dashboard-mark-active ()
  "Highlight the current dashboard row as active."
  (when-let ((buf (get-buffer "*GTD*")))
    (with-current-buffer buf
      (when (overlayp my/gtd-dashboard--active-ov)
        (delete-overlay my/gtd-dashboard--active-ov))
      (save-excursion
        (goto-char (point))
        (setq my/gtd-dashboard--active-ov
              (make-overlay (line-beginning-position) (line-end-position)))
        (overlay-put my/gtd-dashboard--active-ov 'face 'secondary-selection)))))

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
  (when-let ((buf (get-buffer "*GTD Upcoming*")))
    (with-current-buffer buf
      (when (overlayp my/org-upcoming--active-ov)
        (delete-overlay my/org-upcoming--active-ov))
      (setq my/org-upcoming--active-ov
            (make-overlay (line-beginning-position) (line-end-position)))
      (overlay-put my/org-upcoming--active-ov 'face 'secondary-selection))))

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
              (let* ((sched-f (nth 0 entry))
                     (htext  (nth 1 entry))
                     (state  (nth 2 entry))
                     (mark   (nth 3 entry))
                     (days   (/ (- sched-f today-start) 86400))
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
  "Show a live count dashboard for all GTD views. Press RET to open a view."
  (interactive)
  (let* ((context-tags (my/org-context-tags))
         (today-d (let ((d (decode-time))) (list (nth 4 d) (nth 3 d) (nth 5 d))))
         (now-f   (float-time))
         (inbox 0) (today 0) (upcoming 0) (anytime 0) (waiting 0) (someday 0) (logbook 0)
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
           ;; Projects: level-1 headings
           ;; Show: no-state or PROJECT, with no future scheduled date
           ;; Show: WAIT/SOMEDAY only if scheduled date is today or past
           ;; Hide: DONE/CANCELLED, and anything with a future scheduled date
           (if (= lvl 1)
               (let* ((proj-sched sched)
                      (future-p   (and proj-sched (> (float-time proj-sched) now-f)))
                      (show-p     (cond
                                   ((string= htext "Inbox") nil)
                                   ((member state '("DONE" "CANCELLED")) nil)
                                   ((member state '("WAIT" "SOMEDAY"))
                                    (and proj-sched (not future-p)))
                                   ((or (null state) (equal state "PROJECT"))
                                    (not future-p))
                                   (t nil)))) ; NEXT/anything else at level-1 = not a project
                 (if show-p
                     (progn
                       (setq current-l1 htext)
                       (push htext proj-names)
                       (puthash htext (vector 0 0 (point-marker)) proj-data))
                   (setq current-l1 nil)))
             (when (and current-l1 state)
               (let ((v (gethash current-l1 proj-data)))
                 (when v
                   (aset v 1 (1+ (aref v 1)))
                   (when (member state '("NEXT" "WAIT" "SOMEDAY"))
                     (aset v 0 (1+ (aref v 0))))))))
           ;; Inbox: level-2 headings under "* Inbox" with no todo state
           (when (and (not state)
                      (= (org-outline-level) 2)
                      (save-excursion
                        (org-up-heading-safe)
                        (string= (org-get-heading t t t t) "Inbox")))
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
           ;; Waiting / Someday / Logbook
           (when (equal state "WAIT")      (cl-incf waiting))
           (when (equal state "SOMEDAY")   (cl-incf someday))
           (when (member state '("DONE" "CANCELLED")) (cl-incf logbook))
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
          (my/org--dash-row "Upcoming" upcoming #'my/org-upcoming-view)
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
                     (indicator (cond ((= total 0)  "?")
                                     ((> active 0) "")
                                     (t            "●")))
                     (max-len   18)
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
                                     (list 'gtd-action action 'mouse-face 'highlight)))))
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
          (my/org--dash-row "Refresh" "" #'my/org-dashboard)
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

(provide 'org-gtd)
;;; org-gtd.el ends here
