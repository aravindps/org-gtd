;;; bindings-doom.el --- Doom Emacs SPC leader GTD bindings -*- lexical-binding: t; -*-
;; Requires: org-gtd.el (loaded first in config.el)
;; Load this ONLY in Doom Emacs. Adds SPC shortcuts on top of ⌘/C-c g/F5 bindings.

(map! :leader
      ;; ─── Inbox ──────────────────────────────────────────────────────────
      "i"   #'my/org-open-inbox           ;; SPC i — Open Inbox to edit

      ;; ─── Views ──────────────────────────────────────────────────────────
      "/"   #'my/org-dashboard                                   ;; Dashboard
      "0"   (lambda () (interactive) (my/org-open-view "0"))    ;; Inbox
      "1"   (lambda () (interactive) (my/org-open-view "1"))    ;; Today
      "2"   (lambda () (interactive) (my/org-open-view "2"))    ;; Upcoming
      "3"   (lambda () (interactive) (my/org-open-view "3"))    ;; Anytime
      "4"   (lambda () (interactive) (my/org-open-view "4"))    ;; Waiting
      "5"   (lambda () (interactive) (my/org-open-view "5"))    ;; Someday
      "6"   (lambda () (interactive) (my/org-open-view "6"))    ;; Logbook
      "7"   (lambda () (interactive) (my/org-pick-context))     ;; Context NEXT
      "8"   (lambda () (interactive) (my/org-pick-context-all)) ;; Context All

      ;; ─── Create ─────────────────────────────────────────────────────────
      "n"   #'my/org-new-task                        ;; New NEXT task (child)
      "N"   #'my/org-new-heading                     ;; New heading (same level, NEXT)

      ;; ─── Edit ───────────────────────────────────────────────────────────
      "k"   (lambda () (interactive) (org-todo "DONE"))       ;; Complete
      "K"   (lambda () (interactive) (org-todo "CANCELLED"))  ;; Cancel
      "d"   (lambda () (interactive)                           ;; Duplicate
              (org-copy-subtree) (org-paste-subtree))
      "m"   #'org-refile                                       ;; Move to project
      "y"   #'org-archive-subtree                              ;; Archive

      ;; ─── Dates ──────────────────────────────────────────────────────────
      "s"   #'org-schedule                                              ;; Schedule
      "t"   (lambda () (interactive) (org-schedule nil "."))           ;; Today
      "r"   (lambda () (interactive) (org-schedule '(4)))              ;; Anytime
      "o"   (lambda () (interactive) (org-todo "SOMEDAY"))             ;; Someday
      "D"   #'org-deadline                                              ;; Deadline

      ;; ─── Search & Filter ────────────────────────────────────────────────
      "T"   #'org-set-tags-command                 ;; Tag picker

      ;; ─── Navigation ─────────────────────────────────────────────────────
      "-"   #'my/org-zoom-toggle)                  ;; Toggle zoom (narrow/widen)

(provide 'bindings-doom)
;;; bindings-doom.el ends here
