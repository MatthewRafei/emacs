(setq package-enable-at-startup nil)
(setq inhibit-startup-screen t)

;; Stop the White flash when first starting emacs
(setq default-frame-alist '(

			    (background-color . "#000000")

			    (ns-appearance . dark)

			    (ns-transparent-titlebar . t)))

;; Kill UI here so there's zero flicker before init.el runs
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(setq frame-inhibit-implied-resize t)

;; Crank GC during startup, reset after
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024))))
