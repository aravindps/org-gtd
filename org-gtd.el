;;; org-gtd.el --- Core GTD setup for org-mode -*- lexical-binding: t; -*-
;; Pure functions and agenda config only. No keybindings.
;; Load this first, then load whichever bindings files you need.

;; ─── Files ───────────────────────────────────────────────────────────────────
;; Set my/gtd-file before loading this file, or you will be prompted.
;; Example: (setq my/gtd-file "~/org/gtd.org")

(defvar my/gtd-file
  (let ((default "~/gtd.org"))
    (if (file-exists-p (expand-file-name default))
        default
      (read-file-name "GTD file not found. Select your gtd.org: " "~/" nil t)))
  "Path to your GTD org file.")

(setq org-agenda-files (list my/gtd-file))

;; ─── Logging ─────────────────────────────────────────────────────────────────

(setq org-log-done 'time)

;; ─── Refile ──────────────────────────────────────────────────────────────────

(setq org-refile-targets
      (list (list my/gtd-file :maxlevel 2)))
(setq org-refile-use-outline-path t)
(setq org-outline-path-complete-in-steps nil)
(setq org-refile-allow-creating-parent-nodes 'confirm)

;; ─── Agenda Views ────────────────────────────────────────────────────────────

(setq org-agenda-custom-commands
      '(;; 0 — Inbox
        ("0" "Inbox" tags "LEVEL=2&Inbox"
         ((org-agenda-overriding-header "Inbox")))

        ;; 1 — Today
        ("1" "Today" agenda ""
         ((org-agenda-span 1)
          (org-agenda-start-day nil)
          (org-agenda-overriding-header "Today")
          (org-agenda-skip-function
           '(org-agenda-skip-entry-if 'todo '("DONE" "CANCELLED" "SOMEDAY")))))

        ;; 2 — Upcoming
        ("2" "Upcoming" agenda ""
         ((org-agenda-span 7)
          (org-agenda-start-on-weekday 1)
          (org-agenda-overriding-header "Upcoming — Next 7 Days")
          (org-agenda-skip-function
           '(org-agenda-skip-entry-if 'todo '("DONE" "CANCELLED" "SOMEDAY")))))

        ;; 3 — Anytime
        ("3" "Anytime" tags-todo "TODO=\"NEXT\""
         ((org-agenda-overriding-header "Anytime")
          (org-agenda-skip-function
           '(org-agenda-skip-entry-if 'scheduled 'deadline))))

        ;; 4 — Waiting
        ("4" "Waiting" todo "WAIT"
         ((org-agenda-overriding-header "Waiting — Blocked")))

        ;; 5 — Someday
        ("5" "Someday" todo "SOMEDAY"
         ((org-agenda-overriding-header "Someday")))

        ;; 6 — Logbook
        ("6" "Logbook" todo "DONE|CANCELLED"
         ((org-agenda-overriding-header "Logbook — Completed")
          (org-agenda-sorting-strategy '(timestamp-down))))))

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
    (org-tags-view t (format "%s+TODO=\"NEXT\"" tag))))

(defun my/org-pick-context-all ()
  "Prompt for an @context tag and show ALL tasks for it."
  (interactive)
  (let ((tag (completing-read "Context: " (my/org-context-tags) nil t)))
    (org-tags-view nil tag)))

;; ─── Completed tasks sink to bottom ──────────────────────────────────────────

(defun my/org-move-done-to-bottom ()
  "Move DONE or CANCELLED task to bottom of its sibling list."
  (when (member org-state '("DONE" "CANCELLED"))
    (condition-case nil
        (while t (org-move-subtree-down))
      (error nil))))

(add-hook 'org-after-todo-state-change-hook #'my/org-move-done-to-bottom)

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

(defun my/org-agenda-goto-zoomed ()
  "Open task in a bottom split, narrowed to its parent subtree for full context.
Reuses the bottom pane if one already exists."
  (interactive)
  (let ((marker (or (org-get-at-bol 'org-marker)
                    (org-get-at-bol 'org-hd-marker))))
    (when marker
      (let ((bottom (or (window-in-direction 'below)
                        (split-window-below))))
        (select-window bottom)
        (org-goto-marker-or-bmk marker)
        (widen)
        (let ((task-pos (point)))
          (if (org-up-heading-safe)
              (org-narrow-to-subtree)
            (org-narrow-to-subtree))
          (goto-char task-pos))
        (use-local-map (copy-keymap org-mode-map))
        (local-set-key (kbd "q") #'delete-window)
        (with-eval-after-load 'evil
          (evil-local-set-key 'normal (kbd "q") #'delete-window))))))

(with-eval-after-load 'org-agenda
  (define-key org-agenda-mode-map [mouse-1]
    (lambda (event)
      (interactive "e")
      (mouse-set-point event)
      (my/org-agenda-goto-zoomed))))

(with-eval-after-load 'evil
  (with-eval-after-load 'org-agenda
    (evil-define-key '(normal motion) org-agenda-mode-map
      (kbd "RET") #'my/org-agenda-goto-zoomed)))

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
  "Live count dashboard for org-gtd. RET opens the view at point.")
(define-key my/gtd-dashboard-mode-map (kbd "RET")   #'my/gtd-dashboard-activate)
(define-key my/gtd-dashboard-mode-map (kbd "g")     #'my/org-dashboard)
(define-key my/gtd-dashboard-mode-map (kbd "q")     #'delete-window)
(define-key my/gtd-dashboard-mode-map [mouse-1]     #'my/gtd-dashboard-mouse-activate)
;; Evil-mode: bind RET in normal state so it isn't shadowed by evil-ret
(with-eval-after-load 'evil
  (evil-define-key 'normal my/gtd-dashboard-mode-map (kbd "RET") #'my/gtd-dashboard-activate)
  (evil-define-key 'normal my/gtd-dashboard-mode-map (kbd "g")   #'my/org-dashboard)
  (evil-define-key 'normal my/gtd-dashboard-mode-map (kbd "q")   #'delete-window))

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

(defun my/org-dashboard ()
  "Show a live count dashboard for all GTD views. Press RET to open a view."
  (interactive)
  (let* ((context-tags (my/org-context-tags))
         (today-d (let ((d (decode-time))) (list (nth 4 d) (nth 3 d) (nth 5 d))))
         (now-f   (float-time))
         (in-7    (+ now-f (* 7 86400)))
         (inbox 0) (today 0) (upcoming 0) (anytime 0) (waiting 0) (someday 0) (logbook 0)
         (ctx-counts (mapcar (lambda (tag) (cons tag 0)) context-tags))
         (no-ctx 0))
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
                (ctx    (seq-find (lambda (tg) (string-prefix-p "@" tg)) tags)))
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
           ;; Upcoming: scheduled in next 7 days but not today
           (when (and active sched
                      (> (float-time sched) now-f)
                      (<= (float-time sched) in-7))
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
          (my/org--dash-row "Upcoming" upcoming (lambda () (my/org-open-view "2")))
          (my/org--dash-row "Anytime"  anytime  (lambda () (my/org-open-view "3")))
          (my/org--dash-row "Waiting"  waiting  (lambda () (my/org-open-view "4")))
          (my/org--dash-row "Someday"  someday  (lambda () (my/org-open-view "5")))
          (my/org--dash-row "Logbook"  logbook  (lambda () (my/org-open-view "6")))
          (when context-tags
            (insert "\n")
            (dolist (pair ctx-counts)
              (let ((tag (car pair)) (n (cdr pair)))
                (my/org--dash-row tag n
                                  (let ((tg tag))
                                    (lambda () (org-tags-view t (format "%s+TODO=\"NEXT\"" tg)))))))
            (let ((no-ctx-match
                   (concat "TODO=\"NEXT\""
                           (mapconcat (lambda (tg) (concat "-" tg)) context-tags ""))))
              (my/org--dash-row "No context" no-ctx
                                (let ((m no-ctx-match))
                                  (lambda () (org-tags-view t m))))))
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
          (set-window-buffer right (find-file-noselect my/gtd-file)))))))

(defun my/org--dash-row (label count action)
  "Insert one dashboard row with LABEL, COUNT, and ACTION on RET."
  (let ((start (point)))
    (insert (format "  %-14s%s" label
                    (if (equal count "") "" (format " %d" count))))
    (add-text-properties start (point)
                         (list 'gtd-action action 'mouse-face 'highlight)))
  (insert "\n"))

(provide 'org-gtd)
;;; org-gtd.el ends here
