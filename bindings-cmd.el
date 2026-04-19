;;; bindings-cmd.el --- ⌘ key GTD bindings for GUI Emacs -*- lexical-binding: t; -*-
;; Requires: org-gtd.el
;; Load this for GUI Emacs (macOS). ⌘ = super key (s-).

(with-eval-after-load 'org
  (let ((map org-mode-map))

    ;; ─── Views (global — accessible outside org buffers) ──────────────────
    (global-set-key (kbd "s-/") #'my/org-dashboard)                                  ;; Dashboard
    (with-eval-after-load 'evil
      (define-key evil-normal-state-map (kbd "s-/") #'my/org-dashboard))
    (global-set-key (kbd "s-0") (lambda () (interactive) (my/org-open-view "0")))    ;; Inbox
    (global-set-key (kbd "s-1") (lambda () (interactive) (my/org-open-view "1")))    ;; Today
    (global-set-key (kbd "s-2") #'my/org-open-upcoming)                              ;; Upcoming
    (global-set-key (kbd "s-3") (lambda () (interactive) (my/org-open-view "3")))    ;; Anytime
    (global-set-key (kbd "s-4") (lambda () (interactive) (my/org-open-view "4")))    ;; Waiting
    (global-set-key (kbd "s-5") (lambda () (interactive) (my/org-open-view "5")))    ;; Someday
    (global-set-key (kbd "s-6") (lambda () (interactive) (my/org-open-view "6")))    ;; Logbook
    (global-set-key (kbd "s-7") (lambda () (interactive) (my/org-pick-context)))     ;; Context NEXT
    (global-set-key (kbd "s-8") (lambda () (interactive) (my/org-pick-context-all))) ;; Context All
    (global-set-key (kbd "s-i") #'my/org-open-inbox)                                 ;; Open Inbox
    (global-set-key (kbd "C-s-o") #'my/gtd-switch-file)                               ;; Switch GTD file

    ;; ─── Create ───────────────────────────────────────────────────────────
    (define-key map (kbd "s-n") #'my/org-new-heading)                     ;; ⌘n  New NEXT sibling (after current heading's body)
    (define-key map (kbd "s-N") #'my/org-new-task)                       ;; ⇧⌘N New NEXT child of current heading
    (define-key map (kbd "M-s-a") #'my/org-new-project)                  ;; ⌥⌘A New project
    (define-key map (kbd "s-C") (lambda () (interactive)                 ;; ⇧⌘C New checklist
                                  (end-of-line) (newline) (insert "- [ ] ")))

    ;; ─── Edit ─────────────────────────────────────────────────────────────
    (define-key map (kbd "s-'") #'my/gtd-toggle-hide-done)                       ;; ⌘' Hide/show DONE
    (define-key map (kbd "s-e") #'my/gtd-set-state)                              ;; ⌘E State picker
    (define-key map (kbd "s-k") #'my/gtd-complete)                                  ;; ⌘K Complete
    (define-key map (kbd "s-K") #'my/gtd-cancel)                                    ;; ⇧⌘K Cancel
    (define-key map (kbd "s-d") #'my/gtd-duplicate)                      ;; ⌘D Duplicate
    (define-key map (kbd "s-y") #'my/gtd-archive)                        ;; ⌘y Archive

    ;; ─── Move ─────────────────────────────────────────────────────────────
    (define-key map (kbd "s-<up>") #'org-move-subtree-up)               ;; ⌘↑ Move up
    (define-key map (kbd "s-<down>") #'org-move-subtree-down)           ;; ⌘↓ Move down
    (define-key map (kbd "s-{") #'my/org-move-subtree-to-top)          ;; ⌘{ Move to top
    (define-key map (kbd "s-}") #'my/org-move-subtree-to-bottom)       ;; ⌘} Move to bottom
    (define-key map (kbd "s-M") #'my/gtd-refile)                        ;; ⇧⌘M Refile (not plain ⌘m — minimize)

    ;; ─── Dates ────────────────────────────────────────────────────────────
    (define-key map (kbd "s-s") #'org-schedule)                                           ;; ⌘S Schedule
    (define-key map (kbd "s-t") (lambda () (interactive) (org-schedule nil ".")))        ;; ⌘T Today
    (define-key map (kbd "s-r") (lambda () (interactive) (org-schedule '(4))))           ;; ⌘R Anytime — prefix arg 4 removes the schedule date
    (define-key map (kbd "s-o") (lambda () (interactive) (org-todo "SOMEDAY")))          ;; ⌘O Someday
    (define-key map (kbd "s-D") #'org-deadline)                                          ;; ⇧⌘D Deadline

    ;; ─── Navigate ─────────────────────────────────────────────────────────
    (define-key map (kbd "s-<right>") #'org-narrow-to-subtree)  ;; ⌘→ Zoom in
    (define-key map (kbd "s-<left>")  #'widen)                   ;; ⌘← Zoom out
    (global-set-key (kbd "s-[") #'winner-undo)                   ;; ⌘[ Go back

    ;; ─── Search & Filter ──────────────────────────────────────────────────
    (define-key map (kbd "s-f") (lambda () (interactive)         ;; ⌘F Search
                                  (if (fboundp 'consult-org-heading)
                                      (consult-org-heading)
                                    (occur "^\\*+ "))))
    (define-key map (kbd "s-T") #'org-set-tags-command)          ;; ⇧⌘T Tags
    (define-key map (kbd "s-?") #'my/gtd-help)))                ;; ⌘? Help

(provide 'bindings-cmd)
;;; bindings-cmd.el ends here
