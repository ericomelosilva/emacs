;;; vague-theme.el --- theme for Emacs inspired by vague for neovim -*- lexical-binding: t; -*-

(deftheme vague
  "A cool, dark, low-contrast theme inspired by vague.nvim.")

(let* ((class '((class color) (min-colors 89)))
       (bg "#141415")
       (bg-alt "#1c1c24")
       (fg "#cdcdcd")
       (grey "#606079")
       (line "#252530")
       (visual "#333738")
       (builtin "#b4d4cf")
       (func "#c48282")
       (string "#e8b589")
       (number "#e0a363")
       (prop "#c3c3d5")
       (constant "#aeaed1")
       (param "#bb9dbd")
       (error "#d8647e")
       (warning "#f3be7c")
       (hint "#7e98e8")
       (keyword "#6e94b2")
       (type "#9bb4bc")
       (plus "#7fa563"))

  (custom-theme-set-faces
   'vague
   ;; Basic UI
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(cursor  ((,class (:background ,fg))))
   `(fringe  ((,class (:background ,bg))))
   `(region  ((,class (:background ,visual))))
   `(hl-line ((,class (:background ,line))))
   `(minibuffer-prompt ((,class (:foreground ,keyword :weight bold))))

   `(mode-line
     ((,class (:background ,bg-alt :foreground ,fg
                           :box (:line-width -1 :style released-button)))))
   `(mode-line-inactive
     ((,class (:background ,bg :foreground ,grey :box nil))))

   `(font-lock-builtin-face       ((,class (:foreground ,builtin))))
   `(font-lock-comment-face       ((,class (:foreground ,grey :slant italic))))
   `(font-lock-constant-face      ((,class (:foreground ,constant))))
   `(font-lock-function-name-face ((,class (:foreground ,func))))
   `(font-lock-keyword-face       ((,class (:foreground ,keyword))))
   `(font-lock-string-face        ((,class (:foreground ,string :slant italic))))
   `(font-lock-type-face          ((,class (:foreground ,type))))
   `(font-lock-variable-name-face ((,class (:foreground ,prop))))
   `(font-lock-number-face        ((,class (:foreground ,number))))
   `(font-lock-warning-face       ((,class (:foreground ,warning :weight bold))))

   `(error   ((,class (:foreground ,error :weight bold))))
   `(warning ((,class (:foreground ,warning :weight bold))))
   `(success ((,class (:foreground ,plus :weight bold))))

   `(org-level-1 ((,class (:foreground ,keyword :weight bold :height 1.1))))
   `(org-level-2 ((,class (:foreground ,param   :weight bold))))
   `(org-level-3 ((,class (:foreground ,hint))))
   `(org-level-4 ((,class (:foreground ,type))))

   `(org-code  ((,class (:inherit fixed-pitch))))
   `(org-block ((,class (:background ,line :inherit fixed-pitch))))
   `(org-block-begin-line ((,class (:foreground ,grey :slant italic))))
   `(org-block-end-line   ((,class (:foreground ,grey :slant italic))))
   ))

(provide-theme 'vague)
