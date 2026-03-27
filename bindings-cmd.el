;;; bindings-cmd.el --- ⌘ key GTD bindings for GUI Emacs -*- lexical-binding: t; -*-
;; Requires: org-gtd.el
;; Load this for GUI Emacs (macOS). ⌘ = super key (s-).

(with-eval-after-load 'org
  (let ((map org-mode-map))

    ;; ─── Views (global — accessible outside org buffers) ──────────────────
    (global-set-key (kbd "s-0") (lambda () (interactive) (org-agenda nil "0")))      ;; Inbox view
    (global-set-key (kbd "s-1") (lambda () (interactive) (org-agenda nil "1")))      ;; Today
    (global-set-key (kbd "s-2") (lambda () (interactive) (org-agenda nil "2")))      ;; Upcoming
    (global-set-key (kbd "s-3") (lambda () (interactive) (org-agenda nil "3")))      ;; Anytime
    (global-set-key (kbd "s-4") (lambda () (interactive) (org-agenda nil "4")))      ;; Waiting
    (global-set-key (kbd "s-5") (lambda () (interactive) (org-agenda nil "5")))      ;; Someday
    (global-set-key (kbd "s-6") (lambda () (interactive) (org-agenda nil "6")))      ;; Logbook
    (global-set-key (kbd "s-7") (lambda () (interactive) (my/org-pick-context)))     ;; Context NEXT
    (global-set-key (kbd "s-8") (lambda () (interactive) (my/org-pick-context-all))) ;; Context All
    (global-set-key (kbd "s-i") #'my/org-open-inbox)                                 ;; Open Inbox

    ;; ─── Create ───────────────────────────────────────────────────────────
    (define-key map (kbd "s-n") #'org-insert-heading-respect-content)   ;; ⌘N New to-do
    (define-key map (kbd "s-N") #'org-insert-heading)                    ;; ⇧⌘N New heading
    (define-key map (kbd "M-s-n") (lambda () (interactive)               ;; ⌥⌘N New project
                                    (goto-char (point-max))
                                    (org-insert-heading)
                                    (org-promote-subtree)))
    (define-key map (kbd "s-C") (lambda () (interactive)                 ;; ⇧⌘C New checklist
                                  (end-of-line) (newline) (insert "- [ ] ")))

    ;; ─── Edit ─────────────────────────────────────────────────────────────
    (define-key map (kbd "s-k") (lambda () (interactive) (org-todo "DONE")))       ;; ⌘K Complete
    (define-key map (kbd "M-s-k") (lambda () (interactive) (org-todo "CANCELLED")));; ⌥⌘K Cancel
    (define-key map (kbd "s-d") (lambda () (interactive)                            ;; ⌘D Duplicate
                                  (org-copy-subtree) (org-paste-subtree)))
    (define-key map (kbd "s-Y") #'org-archive-subtree)                  ;; ⇧⌘Y Archive

    ;; ─── Move ─────────────────────────────────────────────────────────────
    (define-key map (kbd "s-<up>") #'org-move-subtree-up)               ;; ⌘↑ Move up
    (define-key map (kbd "s-<down>") #'org-move-subtree-down)           ;; ⌘↓ Move down
    (define-key map (kbd "M-s-<up>") (lambda () (interactive)           ;; ⌥⌘↑ Move to top
                                       (condition-case nil
                                           (while t (org-move-subtree-up))
                                         (error nil))))
    (define-key map (kbd "M-s-<down>") (lambda () (interactive)         ;; ⌥⌘↓ Move to bottom
                                         (condition-case nil
                                             (while t (org-move-subtree-down))
                                           (error nil))))
    (define-key map (kbd "s-M") #'org-refile)                           ;; ⇧⌘M Refile
    (define-key map (kbd "s-w") #'org-refile)                           ;; ⌘W Refile

    ;; ─── Dates ────────────────────────────────────────────────────────────
    (define-key map (kbd "s-s") #'org-schedule)                                           ;; ⌘S Schedule
    (define-key map (kbd "s-t") (lambda () (interactive) (org-schedule nil ".")))        ;; ⌘T Today
    (define-key map (kbd "s-r") (lambda () (interactive) (org-schedule '(4))))           ;; ⌘R Anytime
    (define-key map (kbd "s-o") (lambda () (interactive) (org-todo "SOMEDAY")))          ;; ⌘O Someday
    (define-key map (kbd "s-D") #'org-deadline)                                          ;; ⇧⌘D Deadline
    (define-key map (kbd "C-]") (lambda () (interactive) (org-timestamp-change 1 'day))) ;; ^] +1 day
    (define-key map (kbd "C-[") (lambda () (interactive) (org-timestamp-change -1 'day)));; ^[ -1 day
    (define-key map (kbd "C-}") (lambda () (interactive) (org-timestamp-change 7 'day))) ;; ^} +1 week
    (define-key map (kbd "C-{") (lambda () (interactive) (org-timestamp-change -7 'day)));; ^{ -1 week
    (define-key map (kbd "C-.") (lambda () (interactive) (org-timestamp-change 1 'day))) ;; ^. deadline +1
    (define-key map (kbd "C-,") (lambda () (interactive) (org-timestamp-change -1 'day)));; ^, deadline -1

    ;; ─── Navigate ─────────────────────────────────────────────────────────
    (define-key map (kbd "s-<right>") #'org-narrow-to-subtree)  ;; ⌘→ Zoom in
    (define-key map (kbd "s-[") #'widen)                         ;; ⌘[ Zoom out

    ;; ─── Search & Filter ──────────────────────────────────────────────────
    (define-key map (kbd "s-f") (lambda () (interactive)         ;; ⌘F Search
                                  (if (fboundp 'consult-org-heading)
                                      (consult-org-heading)
                                    (occur "^\\*+ "))))
    (define-key map (kbd "s-T") #'org-set-tags-command)          ;; ⇧⌘T Tags
    (define-key map (kbd "C-s-t") #'org-set-tags-command)        ;; ^⌘T Tags
    (define-key map (kbd "C-s-f") (lambda () (interactive)       ;; ^⌘F Filter by tag
                                    (let ((tag (completing-read "Tag: " (org-get-buffer-tags))))
                                      (org-tags-view nil tag))))))

(provide 'bindings-cmd)
;;; bindings-cmd.el ends here
