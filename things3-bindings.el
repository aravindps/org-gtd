;;; things3-bindings.el --- Things 3 style keybindings for org-mode -*- lexical-binding: t; -*-
;; Works with both Doom Emacs and vanilla Emacs.
;; - org-mode bindings use define-key (universal)
;; - View shortcuts use SPC (Doom) or C-c g (vanilla)

;; ─── org-mode keybindings (works in both Doom and vanilla) ──────────────────

(with-eval-after-load 'org
  (let ((map org-mode-map))

    ;; ─── Create items ───────────────────────────────────────────────────────

    ;; ⌘N — New to-do
    (define-key map (kbd "s-n") #'org-insert-heading-respect-content)

    ;; ⌥⌘N — New project (top-level heading)
    (define-key map (kbd "M-s-n") (lambda () (interactive)
                                    (goto-char (point-max))
                                    (org-insert-heading)
                                    (org-promote-subtree)))

    ;; ⇧⌘N — New heading at same level
    (define-key map (kbd "s-N") #'org-insert-heading)

    ;; ⇧⌘C — New checklist item
    (define-key map (kbd "s-C") (lambda () (interactive)
                                  (end-of-line)
                                  (newline)
                                  (insert "- [ ] ")))

    ;; ─── Edit items ─────────────────────────────────────────────────────────

    ;; ⌘K — Complete item
    (define-key map (kbd "s-k") (lambda () (interactive) (org-todo "DONE")))

    ;; ⌥⌘K — Cancel item
    (define-key map (kbd "M-s-k") (lambda () (interactive) (org-todo "CANCELLED")))

    ;; ⌘D — Duplicate subtree
    (define-key map (kbd "s-d") (lambda () (interactive)
                                  (org-copy-subtree)
                                  (org-paste-subtree)))

    ;; ⇧⌘Y — Archive subtree
    (define-key map (kbd "s-Y") #'org-archive-subtree)

    ;; ─── Move items ─────────────────────────────────────────────────────────

    ;; ⌘↑ / ⌘↓ — Move item up/down
    (define-key map (kbd "s-<up>") #'org-move-subtree-up)
    (define-key map (kbd "s-<down>") #'org-move-subtree-down)

    ;; ⌥⌘↑ — Move item to top
    (define-key map (kbd "M-s-<up>") (lambda () (interactive)
                                       (condition-case nil
                                           (while t (org-move-subtree-up))
                                         (error nil))))

    ;; ⌥⌘↓ — Move item to bottom
    (define-key map (kbd "M-s-<down>") (lambda () (interactive)
                                         (condition-case nil
                                             (while t (org-move-subtree-down))
                                           (error nil))))

    ;; ⇧⌘M / ⌘W — Move to another project (refile)
    (define-key map (kbd "s-M") #'org-refile)
    (define-key map (kbd "s-w") #'org-refile)

    ;; ─── Edit dates ─────────────────────────────────────────────────────────

    ;; ⌘S — Schedule
    (define-key map (kbd "s-s") #'org-schedule)

    ;; ⌘T — Start Today
    (define-key map (kbd "s-t") (lambda () (interactive) (org-schedule nil ".")))

    ;; ⌘R — Start Anytime (remove schedule)
    (define-key map (kbd "s-r") (lambda () (interactive) (org-schedule '(4))))

    ;; ⌘O — Start Someday
    (define-key map (kbd "s-o") (lambda () (interactive) (org-todo "SOMEDAY")))

    ;; ⇧⌘D — Add Deadline
    (define-key map (kbd "s-D") #'org-deadline)

    ;; ^] / ^[ — Schedule ±1 day
    (define-key map (kbd "C-]") (lambda () (interactive) (org-timestamp-change 1 'day)))
    (define-key map (kbd "C-[") (lambda () (interactive) (org-timestamp-change -1 'day)))

    ;; ^} / ^{ — Schedule ±1 week
    (define-key map (kbd "C-}") (lambda () (interactive) (org-timestamp-change 7 'day)))
    (define-key map (kbd "C-{") (lambda () (interactive) (org-timestamp-change -7 'day)))

    ;; ^. / ^, — Deadline ±1 day
    (define-key map (kbd "C-.") (lambda () (interactive) (org-timestamp-change 1 'day)))
    (define-key map (kbd "C-,") (lambda () (interactive) (org-timestamp-change -1 'day)))

    ;; ─── Navigate ───────────────────────────────────────────────────────────

    ;; ⌘→ — Zoom into subtree
    (define-key map (kbd "s-<right>") #'org-narrow-to-subtree)

    ;; ⌘[ — Zoom out (⌘← intercepted by macOS)
    (define-key map (kbd "s-[") #'widen)

    ;; ─── Search ─────────────────────────────────────────────────────────────

    ;; ⌘F — Search headings (falls back to occur if consult not available)
    (define-key map (kbd "s-f")
      (lambda () (interactive)
        (if (fboundp 'consult-org-heading)
            (consult-org-heading)
          (occur "^\\*+ "))))

    ;; ─── Tag & Filter ───────────────────────────────────────────────────────

    ;; ^⌘T / ⇧⌘T — Tag picker
    (define-key map (kbd "C-s-t") #'org-set-tags-command)
    (define-key map (kbd "s-T") #'org-set-tags-command)

    ;; ^⌘F — Filter by tag (flat list)
    (define-key map (kbd "C-s-f")
      (lambda () (interactive)
        (let ((tag (completing-read "Filter by tag: " (org-get-buffer-tags))))
          (org-tags-view nil tag))))))

;; ─── View shortcuts ──────────────────────────────────────────────────────────
;; Doom Emacs: SPC 0-5, SPC c n/a
;; Vanilla Emacs: C-c g 0-5, C-c g n/a

(defun my/gtd-bind-views (bind-fn)
  "Register GTD view shortcuts using BIND-FN."
  (funcall bind-fn "0" (lambda () (interactive) (org-agenda nil "0")))  ;; Inbox
  (funcall bind-fn "1" (lambda () (interactive) (org-agenda nil "1")))  ;; Today
  (funcall bind-fn "2" (lambda () (interactive) (org-agenda nil "2")))  ;; Upcoming
  (funcall bind-fn "3" (lambda () (interactive) (org-agenda nil "3")))  ;; Anytime
  (funcall bind-fn "4" (lambda () (interactive) (org-agenda nil "4")))  ;; Someday
  (funcall bind-fn "5" (lambda () (interactive) (org-agenda nil "5")))  ;; Logbook
  (funcall bind-fn "cn" (lambda () (interactive) (my/org-pick-context)))      ;; @context NEXT
  (funcall bind-fn "ca" (lambda () (interactive) (my/org-pick-context-all)))) ;; @context All

;; Vanilla Emacs: view shortcuts under C-c g prefix
;; Doom users get SPC shortcuts via doom-extras.el
(let ((prefix-map (make-sparse-keymap)))
  (global-set-key (kbd "C-c g") prefix-map)
  (my/gtd-bind-views
   (lambda (key fn)
     (define-key prefix-map (kbd key) fn))))

(provide 'things3-bindings)
;;; things3-bindings.el ends here
