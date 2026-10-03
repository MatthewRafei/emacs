(setq cursor-in-non-selected-windows nil)

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

(defvar +cache-dir (expand-file-name "~/.cache/emacs/"))
(make-directory (expand-file-name "backups/" +cache-dir) t)
(make-directory (expand-file-name "auto-save/" +cache-dir) t)

(setq backup-directory-alist `(("." . ,(expand-file-name "backups/" +cache-dir)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" +cache-dir) t))
      auto-save-list-file-prefix (expand-file-name "auto-save/.saves-" +cache-dir)
      backup-by-copying t
      version-control t
      delete-old-versions t
      kept-new-versions 5
      create-lockfiles nil
      recentf-save-file (expand-file-name "recentf" +cache-dir)
      savehist-file (expand-file-name "history" +cache-dir)
      save-place-file (expand-file-name "places" +cache-dir)
      tramp-persistency-file-name (expand-file-name "tramp" +cache-dir)
      url-configuration-directory (expand-file-name "url/" +cache-dir))

;; Custom writes here from now on instead of appending to init.el
(setq custom-file (expand-file-name "custom.el" +cache-dir))
(load custom-file 'noerror 'nomessage)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80)

(setq use-short-answers t
      ring-bell-function #'ignore
      confirm-kill-processes nil
      require-final-newline t
      sentence-end-double-space nil
      kill-do-not-save-duplicates t
      global-auto-revert-non-file-buffers t
      recentf-max-saved-items 300
      scroll-conservatively 101
      scroll-margin 4
      mouse-wheel-progressive-speed nil
      enable-recursive-minibuffers t)

(set-language-environment "UTF-8")

(recentf-mode 1)              ; recent files
(savehist-mode 1)             ; minibuffer history survives restarts
(save-place-mode 1)           ; reopen files where you left off
(global-auto-revert-mode 1)   ; pick up changes made outside Emacs
(delete-selection-mode 1)     ; typing replaces the region
(electric-pair-mode 1)        ; auto-close brackets and quotes
(column-number-mode 1)
(pixel-scroll-precision-mode 1)

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
  :defer t)

(require 'filenotify)

(defvar +theme-palette-file (expand-file-name "~/.cache/theme/palette.json"))
(defvar +theme-palette nil "Current palette as an alist, or nil.")

(defun +theme--read-palette ()
  (when (file-readable-p +theme-palette-file)
    (condition-case nil
        (with-temp-buffer
          (insert-file-contents +theme-palette-file)
          (json-parse-buffer :object-type 'alist))
      (error nil))))

(defun +c (key)
  "Palette colour KEY (a symbol), e.g. (+c 'accent) or (+c 'red)."
  (or (alist-get key +theme-palette)
      (alist-get key (alist-get 'normal (alist-get 'ansi +theme-palette)))))

(defun +cb (key)
  "Bright ANSI palette colour KEY."
  (alist-get key (alist-get 'bright (alist-get 'ansi +theme-palette))))

(defun +theme-apply ()
  "(Re)load the theme from the wallpaper palette."
  (interactive)
  (setq +theme-palette (+theme--read-palette))
  (mapc #'disable-theme custom-enabled-themes)
  (if (not +theme-palette)
      (load-theme 'dracula t)
    (setq modus-themes-bold-constructs t
          modus-themes-italic-constructs t
          modus-themes-mixed-fonts t
          modus-themes-prompts '(bold)
          modus-themes-headings '((1 . (1.4 bold))
                                  (2 . (1.2 bold))
                                  (t . (1.1 semibold))))
    (setq modus-vivendi-palette-overrides
          `(;; surfaces
            (bg-main ,(+c 'bg))
            (bg-dim ,(+c 'bgCard))
            (bg-alt ,(+c 'surface))
            (bg-active ,(+c 'borderAccent))
            (bg-inactive ,(+c 'bgPanel))
            (bg-hl-line ,(+c 'bgCard))
            (bg-region ,(+c 'borderAccent))
            (fg-region unspecified)
            (bg-completion ,(+c 'surface))
            (bg-paren-match ,(+c 'borderAccent))
            (border ,(+c 'border))
            (fringe unspecified)
            (cursor ,(+c 'accent))
            ;; text
            (fg-main ,(+c 'text))
            (fg-dim ,(+c 'textDim))
            (fg-alt ,(+c 'accent2))
            ;; named colours -> terminal palette
            (red ,(+c 'red))       (red-warmer ,(+cb 'red))       (red-cooler ,(+c 'red))
            (green ,(+c 'green))   (green-warmer ,(+cb 'green))   (green-cooler ,(+c 'green))
            (yellow ,(+c 'yellow)) (yellow-warmer ,(+cb 'yellow)) (yellow-cooler ,(+c 'yellow))
            (blue ,(+c 'blue))     (blue-warmer ,(+cb 'blue))     (blue-cooler ,(+c 'blue))
            (magenta ,(+c 'magenta)) (magenta-warmer ,(+cb 'magenta)) (magenta-cooler ,(+c 'magenta))
            (cyan ,(+c 'cyan))     (cyan-warmer ,(+cb 'cyan))     (cyan-cooler ,(+c 'cyan))
            ;; syntax
            (keyword ,(+c 'accent))
            (builtin ,(+c 'accent2))
            (fnname ,(+c 'blue))
            (type ,(+c 'cyan))
            (constant ,(+c 'magenta))
            (variable ,(+c 'yellow))
            (string ,(+c 'green))
            (docstring ,(+c 'textDim))
            (comment ,(+c 'textFaint))
            (preprocessor ,(+c 'red))
            ;; ui
            (fg-prompt ,(+c 'accent))
            (fg-heading-1 ,(+c 'accent))
            (fg-heading-2 ,(+c 'accent2))
            (fg-heading-3 ,(+c 'blue))
            (fg-heading-4 ,(+c 'cyan))
            (fg-link ,(+c 'accent))
            (bg-mode-line-active ,(+c 'bgPanel))
            (fg-mode-line-active ,(+c 'text))
            (border-mode-line-active ,(+c 'border))
            (bg-mode-line-inactive ,(+c 'bgPanel))
            (fg-mode-line-inactive ,(+c 'textFaint))
            (border-mode-line-inactive ,(+c 'bgPanel))
            (bg-line-number-active ,(+c 'bg))
            (bg-line-number-inactive ,(+c 'bg))
            (fg-line-number-active ,(+c 'accent))
            (fg-line-number-inactive ,(+c 'textFaint))))
    (load-theme 'modus-vivendi t))
  (run-hooks '+theme-changed-hook))

(defvar +theme-changed-hook nil
  "Run after the wallpaper theme is (re)applied.")

(defvar +theme--timer nil)
(defun +theme--on-change (event)
  (when (string= (file-name-nondirectory (or (nth 2 event) "")) "palette.json")
    ;; the generator writes several files in a burst; settle first
    (when +theme--timer (cancel-timer +theme--timer))
    (setq +theme--timer (run-with-idle-timer 0.3 nil #'+theme-apply))))

;; Watch the directory, not the file: the generator replaces the file
;; atomically, which would orphan a watch on the old inode.
(when (file-directory-p (file-name-directory +theme-palette-file))
  (file-notify-add-watch (file-name-directory +theme-palette-file)
                         '(change) #'+theme--on-change))

(elpaca-wait)  ; make sure dracula is available for the fallback
(+theme-apply)

(defvar +font
  (cond ((find-font (font-spec :name "Iosevka Extended")) "Iosevka Extended")
        ((find-font (font-spec :name "JetBrainsMono Nerd Font")) "JetBrainsMono Nerd Font")
        (t "DejaVu Sans Mono")))

(set-face-attribute 'default nil :family +font :height 110)
(set-face-attribute 'fixed-pitch nil :family +font :height 1.0)
(add-to-list 'default-frame-alist `(font . ,(format "%s-11" +font)))

(add-to-list 'default-frame-alist '(alpha-background . 90))
(add-to-list 'default-frame-alist '(internal-border-width . 14))
(set-frame-parameter nil 'alpha-background 90)
(set-frame-parameter nil 'internal-border-width 14)

(setq-default left-fringe-width 8
              right-fringe-width 8)
(setq window-divider-default-right-width 1
      window-divider-default-bottom-width 1
      window-divider-default-places t)
(window-divider-mode 1)

(defface +ml-accent '((t :inherit bold)) "Mode line accent.")
(defface +ml-dim '((t)) "Mode line secondary text.")
(defface +ml-faint '((t)) "Mode line tertiary text.")
(defface +ml-warn '((t :inherit bold)) "Mode line warning.")

(defun +ml--refresh-faces ()
  (when +theme-palette
    (set-face-attribute '+ml-accent nil :foreground (+c 'accent))
    (set-face-attribute '+ml-dim nil :foreground (+c 'textDim))
    (set-face-attribute '+ml-faint nil :foreground (+c 'textFaint))
    (set-face-attribute '+ml-warn nil :foreground (+c 'danger))
    (dolist (f '(mode-line mode-line-inactive))
      (set-face-attribute f nil :box `(:line-width 6 :color ,(+c 'bgPanel))))))
(add-hook '+theme-changed-hook #'+ml--refresh-faces)
(+ml--refresh-faces)

(defun +ml--active-p ()
  (mode-line-window-selected-p))

(defun +ml--modified ()
  (cond (buffer-read-only (propertize " ● " 'face '+ml-faint 'help-echo "read-only"))
        ((and (buffer-file-name) (buffer-modified-p))
         (propertize " ● " 'face '+ml-warn 'help-echo "modified"))
        (t (propertize " ● " 'face '+ml-accent))))

(defun +ml--vc ()
  (when (and vc-mode (buffer-file-name))
    (let ((branch (replace-regexp-in-string "^ Git[:-]" "" (substring-no-properties vc-mode))))
      (concat (propertize "  //  " 'face '+ml-faint)
              (propertize (concat " " branch) 'face '+ml-dim)))))

(defun +ml--eglot ()
  (when (and (fboundp 'eglot-managed-p) (eglot-managed-p))
    (propertize "LSP  " 'face '+ml-dim)))

(defun +ml--flymake ()
  (when (bound-and-true-p flymake-mode)
    (let ((e (length (flymake-diagnostics nil nil))))
      (when (> e 0)
        (propertize (format "%d DIAG  " e) 'face '+ml-warn)))))

(setq-default
 mode-line-format
 '((:eval (+ml--modified))
   (:eval (propertize (buffer-name) 'face (if (+ml--active-p) 'bold '+ml-dim)))
   (:eval (propertize "  //  " 'face '+ml-faint))
   (:eval (propertize (upcase (string-remove-suffix "-mode" (symbol-name major-mode)))
                      'face '+ml-dim))
   (:eval (+ml--vc))
   mode-line-format-right-align
   (:eval (+ml--flymake))
   (:eval (+ml--eglot))
   (:eval (propertize "%l:%c" 'face '+ml-dim))
   (:eval (propertize "  //  " 'face '+ml-faint))
   (:eval (propertize "%p " 'face '+ml-faint))))

(defvar +banner--width 80)

(defvar +banner--scale 2.0)

(defun +banner--center (len s &optional scale)
  (let ((padding (max 0 (/ (- len (* (length s) (or scale +banner--scale))) 2))))
    (concat (make-string (floor padding) ?\s) s)))

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
  ;; wallpaper palette when present, the original Dracula colours otherwise
  (let ((pal (lambda (key fallback)
               `(:foreground ,(or (and +theme-palette (+c key)) fallback)))))
    (cond ((eq letter 'letter-e) (funcall pal 'accent  "#ff79c6"))
          ((eq letter 'letter-m) (funcall pal 'accent2 "#bd93f9"))
          ((eq letter 'letter-a) (funcall pal 'cyan    "#8be9fd"))
          ((eq letter 'letter-c) (funcall pal 'green   "#50fa7b"))
          ((eq letter 'letter-s) (funcall pal 'yellow  "#ffb86c"))
          (t '(:foreground "white")))))

(defun +banner--dim ()
  `(:foreground ,(or (and +theme-palette (+c 'textDim)) "#6272a4")))

(defun +banner--faint ()
  `(:foreground ,(or (and +theme-palette (+c 'textFaint)) "#44475a")))

(defun make-banner ()
  (mapcar (lambda (line-index)
            (string-join
             (mapcar (lambda (letter)
                       (propertize
                        (nth line-index (cdr (assoc letter +separate-banner)))
                        'face (append (get-letter-color letter) `(:height ,+banner--scale))))
                     '(letter-e letter-m letter-a letter-c letter-s))
             ""))
          (number-sequence 0 12)))

(defun get-elpaca-package-count ()
  (length (directory-files
           (expand-file-name "builds/" elpaca-directory)
           nil "^[^.]")))

;; one fortune per session, so resizing doesn't reshuffle it
(defvar +banner--fortune nil)
(defun +banner--fortune ()
  (or +banner--fortune
      (setq +banner--fortune
            (let ((bin (or (executable-find "fortune")
                           (let ((f (expand-file-name "~/.local/bin/fortune")))
                             (and (file-executable-p f) f)))))
              (when bin
                (let* ((out (string-trim (shell-command-to-string
                                          (concat (shell-quote-argument bin) " -s -n 110"))))
                       (lines (split-string out "\n" t "[ \t]+"))
                       (author (and (cdr lines)
                                    (string-match "^--\\s-*\\(.+\\)" (car (last lines)))
                                    (match-string 1 (car (last lines))))))
                  (cons (string-join (if author (butlast lines) lines) " ")
                        author)))))))

(defvar +banner-actions
  '(("r" "recent"   consult-recent-file)
    ("p" "projects" projectile-switch-project)
    ("f" "find"     find-file)
    ("c" "config"   +open-config)
    ("g" "magit"    magit-status)
    ("q" "quit"     quit-window)))

(defun +open-config ()
  (interactive)
  (find-file (expand-file-name "config.org" user-emacs-directory)))

(defvar +home-mode-map
  (let ((map (make-sparse-keymap)))
    (dolist (a +banner-actions)
      (define-key map (kbd (car a)) (nth 2 a)))
    map))

(define-derived-mode +home-mode special-mode "Home"
  "Startup banner."
  (setq-local cursor-type nil
              mode-line-format nil
              truncate-lines t))

(defvar +banner-max-scale 1.15
  "Largest the banner art gets. 1.15 is what fits a half-screen window;
bigger windows keep that size instead of blowing the logo up.")

(defun +banner--fit-scale ()
  "Largest text scale (up to `+banner-max-scale') at which the banner fits."
  ;; width of one banner row = sum of each letter's width
  (let ((cols (apply #'+ (mapcar (lambda (letter) (length (cadr letter))) +separate-banner)))
        (rows 23))                    ; 13 art rows + stats, keys, quote
    (max 0.5 (min +banner-max-scale
                  (/ (- (window-width) 4) (float cols))
                  (/ (window-height) (* rows 0.8))))))

(defun +banner--wrap (text width)
  "Split TEXT into lines of at most WIDTH chars, on word boundaries."
  (let (lines cur)
    (dolist (w (split-string text " " t))
      (if (and cur (> (+ (length cur) 1 (length w)) width))
          (progn (push cur lines) (setq cur w))
        (setq cur (if cur (concat cur " " w) w))))
    (when cur (push cur lines))
    (nreverse lines)))

(defun draw-ascii-banner-fn ()
  (let* ((+banner--scale (+banner--fit-scale))
         (banner (make-banner))
         (longest-line (apply #'max (mapcar #'length banner)))
         (current-width (window-width))
         (padding-top (max 0 (floor (/ (- (window-height) (* (+ (length banner) 6) +banner--scale)) +banner--top-pos))))
         (padding-string (make-string longest-line ?\s))
         (fortune (+banner--fortune))
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
                                         'face (append (+banner--dim) '(:height 1.6)))
                             1.6)
            "\n\n")
    ;; shortcuts
    (insert (+banner--center
             current-width
             (mapconcat (lambda (a)
                          (concat (propertize (car a) 'face (append (get-letter-color 'letter-e) '(:weight bold :height 1.3)))
                                  (propertize (concat " " (nth 1 a)) 'face (append (+banner--dim) '(:height 1.3)))))
                        +banner-actions
                        (propertize "   " 'face '(:height 1.3)))
             1.3)
            "\n\n")
    ;; fortune
    (when fortune
      (dolist (q (+banner--wrap (concat "“" (car fortune) "”")
                                (max 20 (floor (- current-width 8) 1.2))))
        (insert (+banner--center current-width
                                 (propertize q 'face (append (+banner--dim) '(:slant italic :height 1.2)))
                                 1.2)
                "\n"))
      (when (cdr fortune)
        (insert (+banner--center current-width
                                 (propertize (concat "— " (cdr fortune)) 'face (append (+banner--faint) '(:height 1.1)))
                                 1.1)
                "\n")))
    (goto-char (point-min))))

(defun +banner--resize-handler (_)
  (when-let ((buffer (get-buffer "*home*"))
             (win (get-buffer-window buffer))
             ((window-live-p win))
             ((<= (window-height (minibuffer-window)) 1)))
    (with-selected-window win
      (with-current-buffer buffer
        (draw-ascii-banner-fn)
        (set-window-point win (point-min))))))

(defun +banner--redraw-all ()
  (when-let ((buffer (get-buffer "*home*"))
             (win (get-buffer-window buffer t)))
    (+banner--resize-handler nil)))
(add-hook '+theme-changed-hook #'+banner--redraw-all)

(defun setup-ascii-banner ()
  (let ((buf (get-buffer-create "*home*")))
    (with-current-buffer buf
      (+home-mode)
      (draw-ascii-banner-fn)
      (add-hook 'window-size-change-functions #'+banner--resize-handler)
      buf)))

(setq initial-buffer-choice #'setup-ascii-banner)

(use-package vertico
  :ensure t
  :custom
  (vertico-cycle t)
  (vertico-count 12)
  (vertico-resize nil)
  :init
  (vertico-mode 1))

;; Backspace deletes a whole path segment in find-file
(use-package vertico-directory
  :after vertico
  :ensure nil
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

(use-package consult
  :ensure t
  :bind (("C-s"     . consult-line)
         ("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-g e"   . consult-compile-error)
         ("M-g f"   . consult-flymake)
         ("C-c f"   . consult-recent-file)
         ("C-c g"   . consult-git-grep)
         ("C-c G"   . consult-grep))
  :custom
  (consult-narrow-key "<")
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref))

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-popupinfo-delay '(0.6 . 0.3))
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

;; extra completion sources: words in open buffers, file paths
(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

(setq tab-always-indent 'complete)

(use-package projectile
  :ensure t
  :config
  (projectile-mode +1)
  (setq projectile-completion-system 'default)  ; i.e. Vertico
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package multiple-cursors
  :ensure t)

(add-hook 'prog-mode-hook #'hl-line-mode)

(setq show-paren-delay 0
      show-paren-context-when-offscreen 'overlay)

(require 'org-tempo)

(setq org-hide-emphasis-markers t
      org-pretty-entities t
      org-startup-indented t
      org-ellipsis " ▾"
      org-src-fontify-natively t
      org-src-tab-acts-natively t
      org-edit-src-content-indentation 0)

(use-package org-modern
  :ensure t
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :custom
  (org-modern-star 'replace)
  (org-modern-block-fringe nil))

(setq display-buffer-alist
      '(("\\*compilation\\*" (display-buffer-same-window))
        ("\\*vterm\\*"       (display-buffer-same-window))))

(setq-default display-line-numbers-width 3)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(add-hook 'text-mode-hook #'visual-line-mode)
(add-hook 'org-mode-hook  #'visual-line-mode)

(setq c-default-style '((java-mode . "java") (awk-mode . "awk") (other . "k&r"))
      c-basic-offset 4)

(with-eval-after-load 'eglot
  (setq eglot-autoshutdown t
        eglot-events-buffer-config '(:size 0)))  ; faster, no log buffer
(dolist (hook '(c-mode-hook c++-mode-hook c-ts-mode-hook c++-ts-mode-hook))
  (add-hook hook #'eglot-ensure))

(setq compilation-scroll-output 'first-error
      compilation-always-kill t
      compilation-ask-about-save nil)
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)

;; magit needs a newer transient than the one built into Emacs 30
(use-package transient :ensure t)
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(setq Man-notify-method 'pushy)

(global-set-key (kbd "C-c c") 'compile)
(global-set-key (kbd "C-c C") 'recompile)

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

(global-set-key (kbd "C-c h") (lambda () (interactive) (switch-to-buffer (setup-ascii-banner))))
(global-set-key (kbd "C-c e") '+open-config)
(global-set-key (kbd "C-c t") '+theme-apply)
