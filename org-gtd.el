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
          (org-agenda-overriding-header "Today")
          (org-agenda-skip-function
           '(org-agenda-skip-entry-if 'todo '("DONE" "CANCELLED" "SOMEDAY")))))

        ;; 2 — Upcoming
        ("2" "Upcoming" agenda ""
         ((org-agenda-span 7)
          (org-agenda-start-on-weekday nil)
          (org-agenda-overriding-header "Upcoming — Next 7 Days")
          (org-agenda-skip-function
           '(org-agenda-skip-entry-if 'todo '("DONE" "CANCELLED" "SOMEDAY")))))

        ;; 3 — Anytime
        ("3" "Anytime" tags-todo "TODO=\"NEXT\""
         ((org-agenda-overriding-header "Anytime")
          (org-agenda-skip-function
           '(org-agenda-skip-entry-if 'scheduled 'deadline))))

        ;; 4 — Someday
        ("4" "Someday" todo "SOMEDAY"
         ((org-agenda-overriding-header "Someday")))

        ;; 5 — Logbook
        ("5" "Logbook" todo "DONE|CANCELLED"
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
    (save-excursion
      (goto-char (point-min))
      (let (tags)
        (while (re-search-forward "#\\+TAGS:.*" nil t)
          (let ((line (match-string 0))
                (start 0))
            (while (string-match "\\(@[a-zA-Z_]+\\)" line start)
              (push (match-string 1 line) tags)
              (setq start (match-end 0)))))
        (delete-dups tags)))))

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

(provide 'org-gtd)
;;; org-gtd.el ends here
