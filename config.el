(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el")
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (elpaca-use-package-mode))

(elpaca-wait)

(setq which-key-side-window-location 'bottom
      which-key-sort-order #'which-key-key-order-alpha
      which-key-sort-uppercase-first nil
      which-key-add-column-padding 1
      which-key-max-display-columns nil
      which-key-min-display-lines 6
      which-key-side-window-slot -10
      which-key-side-window-max-height 0.25
      which-key-idle-delay 0.8
      which-key-max-description-length 25
      which-key-allow-imprecise-window-fit t
      which-key-separator " → ")
(which-key-mode 1)

(use-package dracula-theme
  :ensure t
  :config (load-theme 'dracula t))

(use-package projectile
  :ensure t
  :config
  (projectile-mode +1)
  (setq projectile-completion-system 'ido)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(ido-mode 1)
(ido-everywhere 1)

(use-package vterm
  :ensure t)

(defvar +banner--width 80)

(defun +banner--center (len s)
  (let ((padding (max 0 (/ (- len (length s)) 2))))
    (concat (make-string padding ?\s) s)))

(defcustom +banner--top-pos 3
  "2 - Perfect center; 3 - A bit higher."
  :type 'number)

(defvar +separate-banner
  '((letter-e .
              ("        ,; "
               "      f#i  "
               "    .E#t   "
               "   i#W,    "
               "  L#D.     "
               ":K#Wfff;   "
               "i##WLLLLt  "
               " .E#L      "
               "   f#E:    "
               "    ,WW;   "
               "     .D#;  "
               "       tt  "
               "           "))
    (letter-m .
              ("          ..       :"
               "         ,W,     .Et"
               "        t##,    ,W#t"
               "       L###,   j###t"
               "     .E#j##,  G#fE#t"
               "    ;WW; ##,:K#i E#t"
               "   j#E.  ##f#W,  E#t"
               " .D#L    ###K:   E#t"
               ":K#t     ##D.    E#t"
               "...      #G      .. "
               "         j          "
               "                    "
               "                    "))
    (letter-a .
              ("           .. "
               "          ;W, "
               "         j##, "
               "        G###, "
               "      :E####, "
               "     ;W#DG##, "
               "    j###DW##, "
               "   G##i,,G##, "
               " :K#K:   L##, "
               ";##D.    L##, "
               ",,,      .,,  "
               "              "
               "              "))
    (letter-c .
              ("      ., "
               "     ,Wt "
               "    i#D. "
               "   f#f   "
               " .D#i    "
               ":KW,     "
               "t#f      "
               " ;#G     "
               "  :KE.   "
               "   .DW:  "
               "     L#, "
               "      jt "
               "         "))
    (letter-s .
              ("         . "
               "        ;W "
               "       f#E "
               "     .E#f  "
               "    iWW;   "
               "   L##Lffi "
               "  tLLG##L  "
               "    ,W#i   "
               "   j#E.    "
               " .D#j      "
               ",WK,       "
               "EG.        "
               ",          "))))

(defun get-letter-color (letter)
  (cond ((eq letter 'letter-e) '(:foreground "#ff79c6"))
        ((eq letter 'letter-m) '(:foreground "#bd93f9"))
        ((eq letter 'letter-a) '(:foreground "#8be9fd"))
        ((eq letter 'letter-c) '(:foreground "#50fa7b"))
        ((eq letter 'letter-s) '(:foreground "#ffb86c"))
        (t '(:foreground "white"))))

(defun make-banner ()
  (mapcar (lambda (line-index)
            (string-join
             (mapcar (lambda (letter)
                       (propertize
                        (nth line-index (cdr (assoc letter +separate-banner)))
                        'face (get-letter-color letter)))
                     '(letter-e letter-m letter-a letter-c letter-s))
             ""))
          (number-sequence 0 12)))

(defun get-elpaca-package-count ()
  (length (directory-files
           (expand-file-name "builds/" elpaca-directory)
           nil "^[^.]")))

(defun draw-ascii-banner-fn ()
  (let* ((banner (make-banner))
         (longest-line (apply #'max (mapcar #'length banner)))
         (current-width (window-width))
         (padding-top (max 0 (floor (/ (- (window-height) (length banner)) +banner--top-pos))))
         (padding-string (make-string longest-line ?\s))
         (inhibit-read-only t))
    (erase-buffer)
    (dotimes (_ padding-top) (insert padding-string "\n"))
    (dolist (line banner)
      (insert (+banner--center current-width
                               (concat line (make-string (max 0 (- longest-line (length line))) 32))) "\n"))
    (insert padding-string "\n")
    (insert (+banner--center current-width
                             (propertize (format "%d packages  ·  %s"
                                                 (get-elpaca-package-count)
                                                 (emacs-init-time "started in %.3f seconds"))
                                         'face '(:foreground "#6272a4" :height 0.8))) "\n")      
    (read-only-mode 1)))

(defun +banner--resize-handler (_)
  (when-let ((buffer (get-buffer "*home*"))
             ((window-live-p (get-buffer-window buffer))))
    (with-current-buffer buffer (draw-ascii-banner-fn))))

(defun setup-ascii-banner ()
  (let ((buf (get-buffer-create "*home*")))
    (with-current-buffer buf (draw-ascii-banner-fn))
    (add-hook 'window-size-change-functions #'+banner--resize-handler)
    buf))

(setq initial-buffer-choice #'setup-ascii-banner)

(use-package multiple-cursors
  :ensure t)

(require 'org-tempo)

(cond
 ((find-font (font-spec :name "Iosevka Extended"))
  (set-frame-font "Iosevka Extended 11" nil t))
 ((find-font (font-spec :name "DejaVu Sans Mono"))
  (set-frame-font "DejaVu Sans Mono 11" nil t)))

(setq display-buffer-alist
      '(("\\*compilation\\*" (display-buffer-same-window))
        ("\\*vterm\\*"       (display-buffer-same-window))))

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(add-hook 'text-mode-hook #'visual-line-mode)
(add-hook 'org-mode-hook  #'visual-line-mode)

(when (file-directory-p "~/.config/emacs/simpc-mode")
  (add-to-list 'load-path "~/.config/emacs/simpc-mode")
  (require 'simpc-mode)
  (add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode)))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(simpc-mode . ("clangd"))))
(add-hook 'simpc-mode-hook #'eglot-ensure)

(setq Man-notify-method 'pushy)

(global-set-key (kbd "C-c c") 'compile)

(global-set-key (kbd "C-c s") 'window-swap-states)

(defun switch-to-compilation-buffer ()
  "Switch to the *compilation* buffer if it exists."
  (interactive)
  (let ((buf (get-buffer "*compilation*")))
    (if buf
        (switch-to-buffer buf)
      (message "Compilation buffer does not exist"))))

(global-set-key (kbd "C-c b") 'switch-to-compilation-buffer)

(global-set-key (kbd "C-x m") 'delete-other-windows)

(global-set-key (kbd "C-c m n") 'mc/mark-next-like-this)
(global-set-key (kbd "C-c m p") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c m a") 'mc/mark-all-like-this)
(global-set-key (kbd "C-c m e") 'mc/edit-lines)
