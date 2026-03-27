;;; bindings-ccg.el --- C-c g prefix GTD bindings for terminal Emacs -*- lexical-binding: t; -*-
;; Requires: org-gtd.el, bindings-prefix.el
;; Load this for terminal Emacs. All GTD actions under C-c g prefix.

(require 'bindings-prefix (expand-file-name "bindings-prefix.el"
                                             (file-name-directory
                                              (or load-file-name buffer-file-name))))

(let ((map (make-sparse-keymap)))
  (global-set-key (kbd "C-c g") map)
  (my/gtd-apply-prefix-bindings map))

(provide 'bindings-ccg)
;;; bindings-ccg.el ends here
