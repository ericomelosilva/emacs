(defvar my-inbox-file (expand-file-name "~/org/inbox.org"))
(defvar my-daily-file (expand-file-name "~/org/daily.org"))
(defvar my-projects-file (expand-file-name "~/org/projects.org"))
(defconst my-is-mac   (eq system-type 'darwin))
(defconst my-is-linux (eq system-type 'gnu/linux))
;;-------------------------
;; 1. WARNING SUPPRESSION
;; -------------------------
(setq warning-suppress-types '((lsp-mode)))

;; -------------------------
;; 2. PRE-LOAD VARIABLES
;; -------------------------
(setq lean4-use-company-p nil) ;; Stops Company-mode error

;; Disable visual noise
(setq lsp-enable-file-watchers nil)
(setq lsp-file-watch-threshold 10000)
(setq lsp-headerline-breadcrumb-enable nil)
(setq lsp-inlay-hint-enable nil)

;; -------------------------
;; 3. BASIC UI
;; -------------------------
(setq inhibit-startup-screen t)
(electric-pair-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(fringe-mode 0)
(blink-cursor-mode -1)
(setq-default indent-tabs-mode nil)
(setq ring-bell-function 'ignore)

(global-set-key (kbd "C-x C-b") 'ibuffer)
(setq ibuffer-expert t)

(add-to-list 'default-frame-alist '(undecorated . t))
(add-to-list 'default-frame-alist '(drag-internal-border . 1))
(add-to-list 'default-frame-alist '(internal-border-width . 1))

;; -------------------------
;; 4. MINIMALIST NAVIGATION 
;; -------------------------
(tab-bar-mode -1)
(setq tab-bar-show nil)
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)
(savehist-mode 1)
(global-set-key (kbd "C-x p f") #'project-find-file)
(global-set-key (kbd "C-x b") #'consult-buffer)
;; -------------------------
;; 5. PACKAGE MANAGER
;; -------------------------
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(defun my/ensure (pkg)
  (unless (package-installed-p pkg)
    (condition-case err
        (package-install pkg)
      (error (message "Could not install %s: %s" pkg err)))))

(dolist (p '(evil vertico marginalia consult corfu orderless
             org-modern org-appear xkcd
             org-roam org-fragtog pdf-tools org-noter
             org-roam-ui eglot rust-mode haskell-mode lsp-mode
             gruvbox-theme exec-path-from-shell
             visual-fill-column ob-rust djvu magit
             typst-ts-mode))
  (my/ensure p))

(unless (package-installed-p 'lean4-mode)
  (condition-case nil
      (package-install 'lean4-mode)
    (error
     (package-vc-install "https://github.com/leanprover-community/lean4-mode"))))

;; -------------------------
;; 6. THEME & EVIL
;; -------------------------
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")

;; (if (package-installed-p 'gruvbox-theme)
;;     (load-theme 'gruvbox-dark-medium t)
;;   (load-theme 'modus-vivendi t))

(load-theme 'vague t)

(when (package-installed-p 'evil)
  (require 'evil)
  (evil-mode 1)
  (global-set-key (kbd "<escape>") #'keyboard-escape-quit))
(define-key evil-normal-state-map (kbd "C-p") #'project-find-file)

;; -------------------------
;; EVIL SURROUND
;; -------------------------
(my/ensure 'evil-surround)

(with-eval-after-load 'evil
  (require 'evil-surround)
  (global-evil-surround-mode 1))

;; -------------------------
;; FONTS & MIXED PITCH
;; -------------------------
;; 1. Set the default Monospace font (Code, Tables)
(set-face-attribute 'default nil :font "JuliaMono-15")

;; 2. Set the "Variable Pitch" font (Prose, Org-Noter)
(set-face-attribute 'variable-pitch nil :family "CMU Concrete" :height 180)

;; 3. Ensure Fixed-Pitch elements inside Org Mode stay Monospace
(custom-theme-set-faces
 'user
 '(org-block ((t (:inherit fixed-pitch))))
 '(org-code ((t (:inherit fixed-pitch))))
 '(org-table ((t (:inherit fixed-pitch))))
 '(org-verbatim ((t (:inherit fixed-pitch))))
 '(org-meta-line ((t (:inherit fixed-pitch :foreground "#928374"))))
 '(org-checkbox ((t (:inherit fixed-pitch)))))

;; 4. Enable Variable Pitch automatically in Org Mode
(add-hook 'org-mode-hook #'variable-pitch-mode)

;; Make code blocks distinct from the prose
(with-eval-after-load 'org
  (set-face-attribute 'org-block nil :background "#282828" :foreground "#ebdbb2")
  (set-face-attribute 'org-block-begin-line nil :foreground "#928374" :bold 'bold)
  (set-face-attribute 'org-block-end-line nil :foreground "#928374" :bold 'bold))

(defun my/org-surround-setup ()
  "Org-specific surround pairs: *, /, ~, _, =."
  (setq-local evil-surround-pairs-alist
              (append '(
                        (?* . ("*" . "*"))   ;; *bold*
                        (?/ . ("/" . "/"))   ;; /italic/
                        (?~ . ("~" . "~"))   ;; ~code~
                        (?_ . ("_" . "_"))   ;; _underline_
                        (?= . ("=" . "="))   ;; =verbatim=
                        )
                      evil-surround-pairs-alist)))

(add-hook 'org-mode-hook #'my/org-surround-setup)


;; 5. Optional: Center the text for a "Document" feel
;;(defun my/org-visual-setup ()
;;  (setq visual-fill-column-width 100)
;;  (setq visual-fill-column-center-text t)
;;  (visual-fill-column-mode 1))

;; You'll need to install visual-fill-column if you want the centering
;;(use-package visual-fill-column :ensure t) 
;;(add-hook 'org-mode-hook #'my/org-visual-setup)

;; -------------------------
;; 7. COMPLETION (Vertico + Consult + Orderless)
;; -------------------------
(when (package-installed-p 'vertico)
  (vertico-mode 1))

(when (package-installed-p 'marginalia)
  (marginalia-mode 1))

(when (package-installed-p 'consult)
  (global-set-key (kbd "C-x b") #'consult-buffer)
  (global-set-key (kbd "C-s") #'consult-line))

(when (package-installed-p 'orderless)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(when (package-installed-p 'corfu)
  (setq corfu-auto t)
  (setq corfu-quit-no-match t)
  (global-corfu-mode 1))

;; -------------------------
;; 8. EMAIL (Mu4e)
;; -------------------------
(let* ((mac-mu4e  "/opt/homebrew/share/emacs/site-lisp/mu/mu4e")
       (arch-mu4e "/usr/share/emacs/site-lisp/mu4e")
       (mu4e-dir  (cond
                   ((file-directory-p mac-mu4e)  mac-mu4e)
                   ((file-directory-p arch-mu4e) arch-mu4e)
                   (t nil))))
  (when mu4e-dir
    (add-to-list 'load-path mu4e-dir)
    (when (require 'mu4e nil 'noerror)
      (setq mu4e-update-interval (* 10 60))
      (setq mu4e-get-mail-command "mbsync -a")
      (setq mu4e-maildir "~/Mail")

      (setq mu4e-drafts-folder "/Drafts")
      (setq mu4e-sent-folder   "/Sent")
      (setq mu4e-refile-folder "/Archive")
      (setq mu4e-trash-folder  "/Trash")

      (require 'smtpmail)
      (setq message-send-mail-function 'smtpmail-send-it
            smtpmail-smtp-server "smtp.gmail.com"
            smtpmail-smtp-service 587
            smtpmail-stream-type 'starttls
            message-kill-buffer-on-exit t)

      (setq user-full-name    "Erico Silva"
            user-mail-address "ericsilva1229@gmail.com"))))

;; -------------------------
;; 9. SHELL PATH
;; -------------------------
(when (package-installed-p 'exec-path-from-shell)
  (require 'exec-path-from-shell)
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; -------------------------
;; 10. LEAN 4 SETUP
;; -------------------------
(when (package-installed-p 'lean4-mode)
  (require 'lean4-mode)
  (global-set-key (kbd "C-c C-i") #'lean4-toggle-info)

  (add-to-list 'display-buffer-alist
               '("\\*Lean.*\\*"
                 (display-buffer-in-side-window)
                 (side . right)
                 (slot . 0)
                 (window-width . 0.5)
                 (preserve-size . (t . nil)))))

;; -------------------------
;; 11. LANGUAGES & ORG
;; -------------------------
(require 'org)
(add-hook 'org-mode-hook #'org-indent-mode)

(with-eval-after-load 'evil
  (with-eval-after-load 'org
    (evil-define-key 'normal org-mode-map (kbd "TAB") #'org-cycle)))


(setq org-default-notes-file "~/org/inbox.org")
(setq org-directory "~/org")

;; Ensure basic org files exist 
(dolist (f '("~/org" "~/org/inbox.org"))
  (let ((dir (file-name-directory (expand-file-name f))))
    (when (and dir (not (file-exists-p dir)))
      (make-directory dir t)))
  (when (and (string-suffix-p ".org" f)
             (not (file-exists-p f)))
    (with-temp-buffer (write-file f))))

(when (display-graphic-p)
  (setq org-startup-with-inline-images t)
  (when (package-installed-p 'org-modern)
    (with-eval-after-load 'org (global-org-modern-mode)))
  (when (package-installed-p 'org-appear)
    (add-hook 'org-mode-hook #'org-appear-mode)))

;; Scale up LaTeX previews for Retina display
(setq org-format-latex-options (plist-put org-format-latex-options :scale 1.75))

;; Latex surround set up
(defun my/latex-surround-setup ()
  "Extended LaTeX surround pairs for evil-surround."
  (setq-local evil-surround-pairs-alist
              (append
               '((?$ . ("$" . "$"))
                 (?d . ("$$" . "$$"))
                 (?\] . ("\\[" . "\\]"))
                 (?b . ("\\textbf{" . "}"))
                 (?i . ("\\textit{" . "}"))
                 (?e . ("\\emph{"   . "}"))
                 (?t . ("\\texttt{" . "}"))
                 (?\( . ("\\left("  . "\\right)"))
                 (?\[ . ("\\left["  . "\\right]"))
                 (?\{ . ("\\left\\{" . "\\right\\}"))
                 (?<  . ("\\left<"  . "\\right>"))
                 (?B . my/latex-begin-end))
               evil-surround-pairs-alist)))

(defun my/latex-begin-end ()
  (let ((env (read-string "Environment: ")))
    (cons (format "\\begin{%s}\n" env)
          (format "\n\\end{%s}" env))))

(add-hook 'latex-mode-hook #'my/latex-surround-setup)
(add-hook 'LaTeX-mode-hook #'my/latex-surround-setup)


(when (package-installed-p 'org-roam-ui)
  (require 'org-roam-ui)
  (setq org-roam-ui-sync-theme t         
        org-roam-ui-follow t            
        org-roam-ui-update-on-save t    
        org-roam-ui-open-on-start t))   

;; Eglot Setup
(when (package-installed-p 'eglot)
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
    (add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer")))
    (add-to-list 'eglot-server-programs '(haskell-mode . ("haskell-language-server-wrapper" "--lsp")))
    (add-to-list 'eglot-server-programs '((c-mode c++-mode) . ("clangd")))
    (define-key eglot-mode-map (kbd "C-c f") #'eglot-format))
  (dolist (hook '(python-mode-hook rust-mode-hook haskell-mode-hook c-mode-hook c++-mode-hook))
    (add-hook hook #'eglot-ensure)))

;; File Associations
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
(add-to-list 'auto-mode-alist '("\\.c\\'"   . c-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'"   . c-mode))
(add-to-list 'auto-mode-alist '("\\.cpp\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.py\\'"  . python-mode))
(add-to-list 'auto-mode-alist '("\\.lean\\'" . lean4-mode))
(add-to-list 'auto-mode-alist '("\\.hs\\'"   . haskell-mode))

;; -------------------------
;; LITERATE PROGRAMMING (Org Babel)
;; -------------------------

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((C . t)          ;; Includes C, C++, D
     (python . t)
     (haskell . t)
     (rust . t)
     (shell . t)))    ;; Handy for shell commands

  ;; 1. No "Are you sure?" prompt for every execution
  (setq org-confirm-babel-evaluate nil)

  ;; 2. Preserve indentation in code blocks (Crucial for Python)
  (setq org-src-preserve-indentation t)
  
  ;; 3. Use the same window for editing code (C-c ')
  (setq org-src-window-setup 'current-window))

;; 4. Enable "Structure Templates" (<s TAB expansion)
(require 'org-tempo)

;; -------------------------
;; ORG ROAM KEYBINDINGS (Prefix: C-c r)
;; -------------------------

  (setq org-roam-directory (file-truename "~/org/roam"))
  (unless (file-exists-p org-roam-directory)
    (make-directory org-roam-directory t))
  (org-roam-db-autosync-mode)

;; 1. Find/Create Node (C-c r f)
(global-set-key (kbd "C-c r f") #'org-roam-node-find)

;; 2. Insert Link (C-c r i)
(global-set-key (kbd "C-c r i") #'org-roam-node-insert)

;; 3. Toggle Backlinks (C-c r l)
(global-set-key (kbd "C-c r l") #'org-roam-buffer-toggle)

;; 4. Capture to Roam (C-c r c)
(global-set-key (kbd "C-c r c") #'org-roam-capture)

;; 5. Daily Note (C-c r d)
(global-set-key (kbd "C-c r d") #'org-roam-dailies-goto-today)

;; -------------------------
;; 12. CUSTOM JOURNAL FUNCTIONS
;; -------------------------

(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

(defun my-open-inbox ()
  "Open the inbox.org file."
  (interactive)
  (find-file "~/org/inbox.org"))

(global-set-key (kbd "C-c i") #'my-open-inbox)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(agda-editor-tactics agda-lib-mode auctex biblio citar-org-roam
                         consult corfu djvu evil-surround
                         exec-path-from-shell fsrs gruvbox-theme
                         haskell-mode lean4-mode magit marginalia nov
                         ob-rust orderless org-appear org-fragtog
                         org-modern org-noter org-roam-ui pdf-tools
                         reddigg rust-mode tree-sitter-langs
                         typst-ts-mode vertico visual-fill-column
                         vulpea xkcd))
 '(package-vc-selected-packages
   '((org :url "https://git.tecosaur.net/tec/org-mode" :branch "dev"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-block ((t (:inherit fixed-pitch))))
 '(org-checkbox ((t (:inherit fixed-pitch))))
 '(org-code ((t (:inherit fixed-pitch))))
 '(org-meta-line ((t (:inherit fixed-pitch :foreground "#928374"))))
 '(org-table ((t (:inherit fixed-pitch))))
 '(org-verbatim ((t (:inherit fixed-pitch)))))

;; -------------------------
;; 13. PDF & READING SETUP
;; -------------------------

;; -- PDF Tools Configuration --
(when (package-installed-p 'pdf-tools)
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-width)
  
  ;; AUTOMATIC DARK MODE
  (add-hook 'pdf-view-mode-hook #'pdf-view-midnight-minor-mode)
  (setq pdf-view-midnight-colors '("#e0e0e2" . "#050608"))

  ;; CURSOR FIX: Hides the system cursor in PDF view to prevent flashing
  (add-hook 'pdf-view-mode-hook (lambda () (setq-local cursor-type nil))))

(with-eval-after-load 'pdf-view
  ;; basic navigation
  (define-key pdf-view-mode-map (kbd "j") #'pdf-view-next-line-or-next-page)
  (define-key pdf-view-mode-map (kbd "k") #'pdf-view-previous-line-or-previous-page)
  (define-key pdf-view-mode-map (kbd "h") #'image-backward-hscroll)
  (define-key pdf-view-mode-map (kbd "l") #'image-forward-hscroll)

  ;; fast scrolling
  (define-key pdf-view-mode-map (kbd "J")
    (lambda () (interactive)
      (dotimes (_ 5) (pdf-view-next-line-or-next-page))))
  (define-key pdf-view-mode-map (kbd "K")
    (lambda () (interactive)
      (dotimes (_ 5) (pdf-view-previous-line-or-previous-page))))

  ;; zoom
  (define-key pdf-view-mode-map (kbd "+") #'pdf-view-enlarge)
  (define-key pdf-view-mode-map (kbd "-") #'pdf-view-shrink)

  ;; fit
  (define-key pdf-view-mode-map (kbd "f") #'pdf-view-fit-page-to-window)
  (define-key pdf-view-mode-map (kbd "w") #'pdf-view-fit-width-to-window)

  ;; quit
  (define-key pdf-view-mode-map (kbd "q") #'quit-window))

(setq pdf-view-continuous t)


;; -- Org-Noter Configuration --
(when (package-installed-p 'org-noter)
  (require 'org-noter)
  (setq org-noter-notes-search-path '("~/org/roam"))
  (setq org-noter-always-create-frame nil)
  (global-set-key (kbd "C-c o n") #'org-noter))

;; -------------------------
;; 14. PAPER/PDF CAPTURE WORKFLOW
;; -------------------------

(defun my/pick-pdf-for-roam ()
  "Prompts the user to pick a PDF file and returns the full path."
  (read-file-name "Select PDF: " "~/papers/"))

;; -------------------------
;; GIT / MAGIT
;; -------------------------
(my/ensure 'magit)

(global-set-key (kbd "C-x g") #'magit-status)

(setq org-confirm-elisp-link-function nil)
(load (expand-file-name "research-workflow.el" user-emacs-directory))

(with-eval-after-load 'evil
  (evil-set-initial-state 'magit-mode 'emacs))
