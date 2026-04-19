;;; bindings-prefix.el --- Shared GTD prefix binding helper -*- lexical-binding: t; -*-
;; Provides my/gtd-apply-prefix-bindings used by bindings-ccg.el and bindings-f5.el.
;; Do not load directly — load bindings-ccg.el or bindings-f5.el instead.

(defun my/gtd-apply-prefix-bindings (map)
  "Apply all GTD bindings to keymap MAP (used as a prefix map)."

  ;; ─── Views ────────────────────────────────────────────────────────────────
  (define-key map (kbd "i") #'my/org-open-inbox)                                  ;; Open Inbox to edit
  (define-key map (kbd "/") #'my/org-dashboard)                                   ;; Dashboard
  (define-key map (kbd "0") (lambda () (interactive) (my/org-open-view "0")))     ;; Inbox
  (define-key map (kbd "1") (lambda () (interactive) (my/org-open-view "1")))     ;; Today
  (define-key map (kbd "2") #'my/org-open-upcoming)                               ;; Upcoming
  (define-key map (kbd "3") (lambda () (interactive) (my/org-open-view "3")))     ;; Anytime
  (define-key map (kbd "4") (lambda () (interactive) (my/org-open-view "4")))     ;; Waiting
  (define-key map (kbd "5") (lambda () (interactive) (my/org-open-view "5")))     ;; Someday
  (define-key map (kbd "6") (lambda () (interactive) (my/org-open-view "6")))     ;; Logbook
  (define-key map (kbd "7") (lambda () (interactive) (my/org-pick-context)))      ;; Context NEXT
  (define-key map (kbd "8") (lambda () (interactive) (my/org-pick-context-all)))  ;; Context All

  ;; ─── Create ───────────────────────────────────────────────────────────────
  (define-key map (kbd "n") #'my/org-new-heading)                   ;; New NEXT sibling (same level)
  (define-key map (kbd "N") #'my/org-new-task)                      ;; New NEXT task (child)
  (define-key map (kbd "a") #'my/org-new-project)                   ;; New top-level project
  (define-key map (kbd "c") (lambda () (interactive)                 ;; New checklist
                               (end-of-line) (newline) (insert "- [ ] ")))

  ;; ─── Edit ─────────────────────────────────────────────────────────────────
  (define-key map (kbd "e") #'my/gtd-set-state)                     ;; State picker
  (define-key map (kbd "k") #'my/gtd-complete)   ;; Complete
  (define-key map (kbd "K") #'my/gtd-cancel)    ;; Cancel
  (define-key map (kbd "d") #'my/gtd-duplicate)                     ;; Duplicate
  (define-key map (kbd "Y") #'my/gtd-archive)                       ;; Shift+y — archive (same as ⇧⌘Y / SPC Y)

  ;; ─── Move ─────────────────────────────────────────────────────────────────
  (define-key map (kbd "<up>") #'org-move-subtree-up)                ;; Move up
  (define-key map (kbd "<down>") #'org-move-subtree-down)            ;; Move down
  (define-key map (kbd "{") #'my/org-move-subtree-to-top)           ;; Move to top
  (define-key map (kbd "}") #'my/org-move-subtree-to-bottom)        ;; Move to bottom
  (define-key map (kbd "M") #'my/gtd-refile)                        ;; Shift+m — refile (same as SPC M / ⇧⌘M)

  ;; ─── Dates ────────────────────────────────────────────────────────────────
  (define-key map (kbd "s") #'org-schedule)                                          ;; Schedule
  (define-key map (kbd "t") (lambda () (interactive) (org-schedule nil ".")))        ;; Today
  (define-key map (kbd "r") (lambda () (interactive) (org-schedule '(4))))           ;; Anytime — prefix arg 4 removes the schedule date
  (define-key map (kbd "o") (lambda () (interactive) (org-todo "SOMEDAY")))          ;; Someday
  (define-key map (kbd "D") #'org-deadline)                                          ;; Deadline

  ;; ─── Navigate ─────────────────────────────────────────────────────────────
  (define-key map (kbd "-") #'my/org-zoom-toggle)       ;; Toggle zoom (narrow/widen)
  (define-key map (kbd "[") #'winner-undo)              ;; Go back

  (define-key map (kbd "'") #'my/gtd-toggle-hide-done)  ;; Hide/show DONE

  ;; ─── Search & Filter ──────────────────────────────────────────────────────
  (define-key map (kbd "f") (lambda () (interactive)    ;; Search headings
                               (if (fboundp 'consult-org-heading)
                                   (consult-org-heading)
                                 (occur "^\\*+ "))))
  (define-key map (kbd "T") #'org-set-tags-command)     ;; Tag picker
  (define-key map (kbd "?") #'my/gtd-help))             ;; Help

(provide 'bindings-prefix)
;;; bindings-prefix.el ends here
