;;; doom-overrides.el --- Doom/evil conflict fixes for org-gtd -*- lexical-binding: t; -*-
;; Load after bindings-doom.el. Fixes Doom and evil-org default bindings
;; that conflict with org-gtd behaviour.

;; C-M-RET in Doom inserts a heading with todo state — disable it.
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-M-RET") nil))

;; evil-org overrides RET in normal mode with +org/dwim-at-point (toggles
;; TODO states). Restore plain org-return (follow links / newline).
(with-eval-after-load 'evil-org
  (define-key evil-org-mode-map (kbd "RET") #'org-return))

(provide 'doom-overrides)
;;; doom-overrides.el ends here
