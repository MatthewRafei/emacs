;;; early-init.el --- -*- lexical-binding: t -*-
(setq package-enable-at-startup nil)
(setq inhibit-startup-screen t)

;; Stop the White flash when first starting emacs
(setq default-frame-alist '((background-color . "#000000")
                            (ns-appearance . dark)
                            (ns-transparent-titlebar . t)))

;; Kill UI here so there's zero flicker before init.el runs
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)

;; GC: never during startup. Afterwards a 64MB threshold keeps collections
;; rare while typing/scrolling, and an idle timer collects while you're not
;; looking (see `+gc-idle' in config.org).
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1.0)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.2)))

;; Every `load' and `require' at startup walks this list for every path;
;; nothing at startup needs tramp/jka-compr handlers, so drop them until done.
(let ((handlers file-name-handler-alist))
  (setq file-name-handler-alist nil)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq file-name-handler-alist
                    (delete-dups (append file-name-handler-alist handlers))))
            101))

;; Redisplay: left-to-right text only, so skip the bidi reordering pass
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; Fonts: keep glyph caches (big fonts with icons get recompacted otherwise)
(setq inhibit-compacting-font-caches t)

;; PGTK waits this long for GTK events after drawing; the 0.1s default
;; shows up as dropped frames while scrolling
(setq pgtk-wait-for-event-timeout 0.001)

;; Processes (magit, vterm, compile): read output in bigger chunks, now
(setq read-process-output-max (* 1024 1024)
      process-adaptive-read-buffering nil)

;; Misc lookups that cost time on every file open
(setq auto-mode-case-fold nil
      ffap-machine-p-known 'reject
      native-comp-async-report-warnings-errors 'silent)
