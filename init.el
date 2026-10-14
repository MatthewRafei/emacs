;;; init.el --- -*- lexical-binding: t -*-
;; Load config.el directly; only pull in Org to re-tangle it when config.org
;; is newer. (org-babel-load-file loads all of Org on every startup.)
(let ((org (expand-file-name "config.org" user-emacs-directory))
      (el  (expand-file-name "config.el" user-emacs-directory)))
  (when (file-newer-than-file-p org el)
    (require 'ob-tangle)
    (org-babel-tangle-file org el "emacs-lisp")
    ;; Org leaves config.el alone when the code didn't change (prose-only
    ;; edits), which would leave config.org newer and re-tangle every start
    (set-file-times el))
  (load el nil 'nomessage 'nosuffix))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("4617ec0d7efd37857f436e179449c758eb3ac27abfec8b11c90c026f00f8f810"
     default)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
