;;; bindings-f5.el --- F5 prefix GTD bindings for terminal Emacs -*- lexical-binding: t; -*-
;; Requires: org-gtd.el, bindings-prefix.el
;; Load this for terminal Emacs. All GTD actions under F5 prefix.

(require 'bindings-prefix (expand-file-name "bindings-prefix.el"
                                             (file-name-directory
                                              (or load-file-name buffer-file-name))))

(let ((map (make-sparse-keymap)))
  (global-set-key (kbd "<f5>") map)
  (my/gtd-apply-prefix-bindings map))

(provide 'bindings-f5)
;;; bindings-f5.el ends here
