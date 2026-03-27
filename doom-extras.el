;;; doom-extras.el --- Doom Emacs SPC leader GTD bindings -*- lexical-binding: t; -*-
;; Requires: org-gtd.el (loaded first in config.el)
;; Load this ONLY in Doom Emacs. Adds SPC shortcuts on top of ⌘/C-c g/F5 bindings.

(map! :leader
      ;; ─── Inbox ──────────────────────────────────────────────────────────
      "i"   #'my/org-open-inbox           ;; SPC i — Open Inbox to edit

      ;; ─── Views ──────────────────────────────────────────────────────────
      "0"   (lambda () (interactive) (org-agenda nil "0"))      ;; Inbox view
      "1"   (lambda () (interactive) (org-agenda nil "1"))      ;; Today
      "2"   (lambda () (interactive) (org-agenda nil "2"))      ;; Upcoming
      "3"   (lambda () (interactive) (org-agenda nil "3"))      ;; Anytime
      "4"   (lambda () (interactive) (org-agenda nil "4"))      ;; Someday
      "5"   (lambda () (interactive) (org-agenda nil "5"))      ;; Logbook
      "6"   (lambda () (interactive) (my/org-pick-context))     ;; Context NEXT
      "7"   (lambda () (interactive) (my/org-pick-context-all)) ;; Context All

      ;; ─── Create ─────────────────────────────────────────────────────────
      "n"   #'org-insert-heading-respect-content   ;; New to-do
      "N"   #'org-insert-heading                    ;; New heading

      ;; ─── Edit ───────────────────────────────────────────────────────────
      "k"   (lambda () (interactive) (org-todo "DONE"))       ;; Complete
      "K"   (lambda () (interactive) (org-todo "CANCELLED"))  ;; Cancel
      "w"   #'org-refile                                       ;; Move to project
      "y"   #'org-archive-subtree                              ;; Archive

      ;; ─── Dates ──────────────────────────────────────────────────────────
      "s"   #'org-schedule                                              ;; Schedule
      "t"   (lambda () (interactive) (org-schedule nil "."))           ;; Today
      "r"   (lambda () (interactive) (org-schedule '(4)))              ;; Anytime
      "o"   (lambda () (interactive) (org-todo "SOMEDAY"))             ;; Someday
      "D"   #'org-deadline                                              ;; Deadline

      ;; ─── Search & Filter ────────────────────────────────────────────────
      "T"   #'org-set-tags-command                 ;; Tag picker
      "/"   (lambda () (interactive)               ;; Filter by tag
              (let ((tag (completing-read "Tag: " (org-get-buffer-tags))))
                (org-tags-view nil tag))))

(provide 'doom-extras)
;;; doom-extras.el ends here
