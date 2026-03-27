;;; bindings-prefix.el --- Shared GTD prefix binding helper -*- lexical-binding: t; -*-
;; Provides my/gtd-apply-prefix-bindings used by bindings-ccg.el and bindings-f5.el.
;; Do not load directly — load bindings-ccg.el or bindings-f5.el instead.

(defun my/gtd-apply-prefix-bindings (map)
  "Apply all GTD bindings to keymap MAP (used as a prefix map)."

  ;; ─── Views ────────────────────────────────────────────────────────────────
  (define-key map (kbd "i") #'my/org-open-inbox)                                  ;; Open Inbox to edit
  (define-key map (kbd "0") (lambda () (interactive) (org-agenda nil "0")))       ;; Inbox view
  (define-key map (kbd "1") (lambda () (interactive) (org-agenda nil "1")))       ;; Today
  (define-key map (kbd "2") (lambda () (interactive) (org-agenda nil "2")))       ;; Upcoming
  (define-key map (kbd "3") (lambda () (interactive) (org-agenda nil "3")))       ;; Anytime
  (define-key map (kbd "4") (lambda () (interactive) (org-agenda nil "4")))       ;; Waiting
  (define-key map (kbd "5") (lambda () (interactive) (org-agenda nil "5")))       ;; Someday
  (define-key map (kbd "6") (lambda () (interactive) (org-agenda nil "6")))       ;; Logbook
  (define-key map (kbd "7") (lambda () (interactive) (my/org-pick-context)))      ;; Context NEXT
  (define-key map (kbd "8") (lambda () (interactive) (my/org-pick-context-all)))  ;; Context All

  ;; ─── Create ───────────────────────────────────────────────────────────────
  (define-key map (kbd "n") #'org-insert-heading-respect-content)   ;; New to-do
  (define-key map (kbd "N") #'org-insert-heading)                    ;; New heading
  (define-key map (kbd "c") (lambda () (interactive)                 ;; New checklist
                               (end-of-line) (newline) (insert "- [ ] ")))

  ;; ─── Edit ─────────────────────────────────────────────────────────────────
  (define-key map (kbd "k") (lambda () (interactive) (org-todo "DONE")))       ;; Complete
  (define-key map (kbd "K") (lambda () (interactive) (org-todo "CANCELLED")))  ;; Cancel
  (define-key map (kbd "d") (lambda () (interactive)                            ;; Duplicate
                               (org-copy-subtree) (org-paste-subtree)))
  (define-key map (kbd "y") #'org-archive-subtree)                  ;; Archive

  ;; ─── Move ─────────────────────────────────────────────────────────────────
  (define-key map (kbd "p") #'org-move-subtree-up)                  ;; Move up
  (define-key map (kbd "P") #'org-move-subtree-down)                ;; Move down
  (define-key map (kbd "w") #'org-refile)                           ;; Move to project

  ;; ─── Dates ────────────────────────────────────────────────────────────────
  (define-key map (kbd "s") #'org-schedule)                                          ;; Schedule
  (define-key map (kbd "t") (lambda () (interactive) (org-schedule nil ".")))        ;; Today
  (define-key map (kbd "r") (lambda () (interactive) (org-schedule '(4))))           ;; Anytime
  (define-key map (kbd "o") (lambda () (interactive) (org-todo "SOMEDAY")))          ;; Someday
  (define-key map (kbd "D") #'org-deadline)                                          ;; Deadline

  ;; ─── Navigate ─────────────────────────────────────────────────────────────
  (define-key map (kbd "]") #'org-narrow-to-subtree)   ;; Zoom in
  (define-key map (kbd "[") #'widen)                    ;; Zoom out

  ;; ─── Search & Filter ──────────────────────────────────────────────────────
  (define-key map (kbd "f") (lambda () (interactive)    ;; Search headings
                               (if (fboundp 'consult-org-heading)
                                   (consult-org-heading)
                                 (occur "^\\*+ "))))
  (define-key map (kbd "T") #'org-set-tags-command)     ;; Tag picker
  (define-key map (kbd "/") (lambda () (interactive)    ;; Filter by tag
                               (let ((tag (completing-read "Tag: " (org-get-buffer-tags))))
                                 (org-tags-view nil tag)))))

(provide 'bindings-prefix)
;;; bindings-prefix.el ends here
