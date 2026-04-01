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
      "n"   #'my/org-new-heading                     ;; New NEXT sibling (same level)
      "N"   #'my/org-new-task                        ;; New NEXT task (child)
      "c"   (lambda () (interactive)                 ;; New checklist item
              (end-of-line) (newline) (insert "- [ ] "))

      ;; ─── Edit ───────────────────────────────────────────────────────────
      "e"   #'my/gtd-set-state                                ;; State picker
      "k"   (lambda () (interactive) (org-todo "DONE"))       ;; Complete
      "K"   (lambda () (interactive) (org-todo "CANCELLED"))  ;; Cancel
      "d"   #'my/gtd-duplicate                                 ;; Duplicate
      "m"   #'my/gtd-refile                                    ;; Move to project
      "y"   #'my/gtd-archive                                   ;; Archive

      ;; ─── Dates ──────────────────────────────────────────────────────────
      "s"   #'org-schedule                                              ;; Schedule
      "t"   (lambda () (interactive) (org-schedule nil "."))           ;; Today
      "r"   (lambda () (interactive) (org-schedule '(4)))              ;; Anytime — prefix arg 4 removes the schedule date
      "o"   (lambda () (interactive) (org-todo "SOMEDAY"))             ;; Someday
      "D"   #'org-deadline                                              ;; Deadline

      ;; ─── Search & Filter ────────────────────────────────────────────────
      "T"   #'org-set-tags-command                 ;; Tag picker

      ;; ─── Navigation ─────────────────────────────────────────────────────
      "-"   #'my/org-zoom-toggle)                  ;; Toggle zoom (narrow/widen)

(provide 'bindings-doom)
;;; bindings-doom.el ends here
