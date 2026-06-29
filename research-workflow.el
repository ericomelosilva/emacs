; Load AFTER org and org-roam. e.g.:
;;   (load (expand-file-name "research-workflow.el" user-emacs-directory))

;; ---------------------------------------------------------------------------
;; 0. Deps / paths
;; ---------------------------------------------------------------------------

(defvar my-inbox-file (expand-file-name "~/org/inbox.org")
  "context-free capture.")

(unless (package-installed-p 'vulpea)
  (ignore-errors (package-install 'vulpea)))
(require 'vulpea nil 'noerror)

;; ---------------------------------------------------------------------------
;; 1. TODO states
;; ---------------------------------------------------------------------------

(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@/!)" "|" "DONE(d!)" "KILL(k@)")
        (sequence "SORRY(s)" "|" "PROVEN(P!)")))   

(setq org-todo-keyword-faces
      '(("NEXT"   . "#fabd2f")
        ("WAIT"   . "#928374")
        ("KILL"   . "#928374")
        ("SORRY"  . "#fe8019")
        ("PROVEN" . "#b8bb26")))

(setq org-log-into-drawer t)

(setq org-tag-alist
      '((:startgroup)
        ("conjecture" . ?C) ("proved" . ?P) ("folklore" . ?F)
        ("numerical"  . ?U) ("false"  . ?X)
        (:endgroup)))

;; ---------------------------------------------------------------------------
;; 2. Agenda is built from roam notes that contain todos
;; ---------------------------------------------------------------------------

(defun my/roam-buffer-p ()
  "Non-nil if the current buffer is a file inside `org-roam-directory'."
  (and buffer-file-name
       (derived-mode-p 'org-mode)
       (string-prefix-p
        (expand-file-name (file-name-as-directory org-roam-directory))
        (expand-file-name buffer-file-name))))

(defun my/roam-has-todo-p ()
  "Non-nil if the current buffer has at least one todo-state entry."
  (org-element-map (org-element-parse-buffer 'headline) 'headline
    (lambda (h) (eq (org-element-property :todo-type h) 'todo))
    nil 'first-match))

(defun my/roam-update-agenda-tag ()
  "Add/remove the :agenda: filetag based on whether this note has todos."
  (when (and (not (active-minibuffer-window))
             (fboundp 'vulpea-buffer-tags-get)
             (my/roam-buffer-p))
    (save-excursion
      (goto-char (point-min))
      (let* ((tags (vulpea-buffer-tags-get))
             (original tags))
        (setq tags (if (my/roam-has-todo-p)
                       (cons "agenda" tags)
                     (remove "agenda" tags)))
        (setq tags (seq-uniq tags))
        (when (or (seq-difference tags original)
                  (seq-difference original tags))
          (apply #'vulpea-buffer-tags-set tags))))))

(defun my/roam-agenda-note-files ()
  "Files of all roam notes carrying the :agenda: tag."
  (seq-uniq
   (seq-map
    #'car
    (org-roam-db-query
     [:select [nodes:file]
      :from tags
      :left-join nodes :on (= tags:node-id nodes:id)
      :where (like tag (quote "%\"agenda\"%"))]))))

(defun my/update-agenda-files (&rest _)
  "Set `org-agenda-files' to the inbox plus all todo-bearing roam notes."
  (setq org-agenda-files
        (cons my-inbox-file (my/roam-agenda-note-files))))

(add-hook 'find-file-hook   #'my/roam-update-agenda-tag)
(add-hook 'before-save-hook #'my/roam-update-agenda-tag)
(advice-add 'org-agenda :before #'my/update-agenda-files)

;; ---------------------------------------------------------------------------
;; 3. Agenda views 
;; ---------------------------------------------------------------------------

(setq org-agenda-custom-commands
      '(("r" "Research dashboard"
         ((todo "NEXT"  ((org-agenda-overriding-header "Next actions")))
          (todo "WAIT"  ((org-agenda-overriding-header "Waiting on")))
          (todo "SORRY" ((org-agenda-overriding-header "Lean: open goals")))))
        ("w" "Work"     tags-todo "work")
        ("h" "Personal" tags-todo "personal")
        ("s" "Lean goals" todo "SORRY")))

(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

;; ---------------------------------------------------------------------------
;; 4. Capture: inbox only %a = backlink.
;; ---------------------------------------------------------------------------

(setq org-capture-templates
      `(("t" "Todo -> inbox" entry (file ,my-inbox-file)
         "* TODO %?\n%U\n%a\n")
        ("i" "Idea / note -> inbox" entry (file ,my-inbox-file)
         "* %?  :idea:\n%U\n%a\n")))

(global-set-key (kbd "C-c i")
                (lambda () (interactive) (find-file my-inbox-file)))

;; ---------------------------------------------------------------------------
;; 5. Daily notes 
;; ---------------------------------------------------------------------------

(with-eval-after-load 'org-roam
  (setq org-roam-dailies-directory "daily/")
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d>\n#+filetags: :daily:\n")))))

(global-set-key (kbd "C-c d") #'org-roam-dailies-goto-today)
(global-set-key (kbd "C-c L") #'org-roam-dailies-capture-today)

;; ---------------------------------------------------------------------------
;; 6. Roam capture templates
;; ---------------------------------------------------------------------------

(defvar my/roam-math-head
  (concat "#+title: ${title}\n"
          "#+filetags: :project:math:%^{Context|work|personal}:\n"
          "#+category: math\n\n"
          "* State of play\n%?\n\n"            ; rewrite in place; re-entry point
          "* Threads\n- \n\n"                  ; live questions, plain, no lifecycle
          "* Key notes & results\n- \n\n"      ; map of content -> atomic nodes
          "* Tasks\n** NEXT \n\n"              ; only genuinely actionable
          "* References\n- \n")
  "Skeleton for a pure-math project hub.")

(defvar my/roam-lean-head
  (concat "#+title: ${title}\n"
          "#+filetags: :project:lean:%^{Context|work|personal}:\n"
          "#+category: lean\n\n"
          "* Repo & blueprint\n- Repo: \n- Blueprint: \n- Upstream: \n\n"
          "* State of play\n%?\n\n"
          "* Open goals\n** SORRY \n\n"
          "* Connections\n- \n")
  "Skeleton for a Lean formalization project hub.")

(defvar my/roam-ml-head
  (concat "#+title: ${title}\n"
          "#+filetags: :project:ml:%^{Context|work|personal}:\n"
          "#+category: ml\n\n"
          "* Hypothesis / objective\n%?\n\n"
          "* Experiments\n"
          "| date | run | setup | metric | notes |\n"
          "|------+-----+-------+--------+-------|\n\n"
          "* Results\n\n"
          "* Tasks\n** NEXT \n\n"
          "* Connections\n- \n")
  "Skeleton for a numerics / ML experiment project hub.")

(defun my/pick-pdf-for-roam ()
  "Prompt for a PDF and return its full path."
  (read-file-name "Select PDF: " "~/papers/"))

(defvar my/roam-paper-head
  (concat ":PROPERTIES:\n:NOTER_DOCUMENT: %(my/pick-pdf-for-roam)\n:END:\n"
          "#+title: ${title}\n#+filetags: :paper:reading:\n\n"
          "* Metadata\n- Authors: %?\n- Year: \n- Link: \n\n"
          "* Summary\n\n* Main argument\n\n* Key concepts\n")
  "Skeleton for a paper / reading node.")

(defvar my/roam-writing-head
  (concat "#+title: ${title}\n#+filetags: :writing:\n\n"
          "* Angle\n"            
          "* Outline\n- \n\n"
          "* Draft\n%?\n")
  "Skeleton for a nontechnical writing draft (export to md/html/pdf).")

(with-eval-after-load 'org-roam
  (setq org-roam-capture-templates
        `(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t)

          ("c" "concept / definition" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+filetags: :concept:\n* Definition\n\n* Intuition\n\n* Related\n- ")
           :unnarrowed t)
          ("r" "result / theorem" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+filetags: :result:\n* Statement\n\n* Status\n  ;; conjecture / proved mod Lemma X / Smith 1990 / numerical to n=4\n\n* Idea / sketch\n\n* Related\n- Uses: \n- Generalizes: \n- See also: \n")
           :unnarrowed t)
          ("q" "question / thread" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+filetags: :question:\n* Question\n\n* Why it matters\n\n* What I've tried\n\n* Related\n- ")
           :unnarrowed t)

          ("p" "paper / reading" plain ,my/roam-paper-head
           :target (file+head "papers/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t)

          ("M" "Math project" plain ,my/roam-math-head
           :target (file+head "projects/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t)
          ("L" "Lean project" plain ,my/roam-lean-head
           :target (file+head "projects/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t)
          ("N" "Numerics / ML project" plain ,my/roam-ml-head
           :target (file+head "projects/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t)

          ("W" "Writing / essay draft" plain ,my/roam-writing-head
           :target (file+head "writing/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t))))

;; ---------------------------------------------------------------------------
;; 7. Browse by kind 
;; ---------------------------------------------------------------------------

(defun my/roam-find-tagged (tag)
  (org-roam-node-find
   nil nil (lambda (n) (member tag (org-roam-node-tags n)))))

(defun my/roam-find-project ()  (interactive) (my/roam-find-tagged "project"))
(defun my/roam-find-question () (interactive) (my/roam-find-tagged "question"))
(defun my/roam-find-result ()   (interactive) (my/roam-find-tagged "result"))
(defun my/roam-find-writing ()  (interactive) (my/roam-find-tagged "writing"))

(global-set-key (kbd "C-c r p") #'my/roam-find-project)   ; jump to a project
(global-set-key (kbd "C-c r q") #'my/roam-find-question)  ; browse live questions
(global-set-key (kbd "C-c r R") #'my/roam-find-result)    ; browse results
(global-set-key (kbd "C-c r w") #'my/roam-find-writing)   ; browse drafts
(global-set-key (kbd "C-c r f") #'org-roam-node-find)
(global-set-key (kbd "C-c r i") #'org-roam-node-insert)
(global-set-key (kbd "C-c r l") #'org-roam-buffer-toggle)
(global-set-key (kbd "C-c r c") #'org-roam-capture)

;; ---------------------------------------------------------------------------
;; 8. Refile: send inbox headings into project hubs (C-c C-w)
;; ---------------------------------------------------------------------------

(defun my/roam-project-files ()
  "Files of roam notes tagged :project: (the project hubs)."
  (seq-uniq
   (seq-map
    #'car
    (org-roam-db-query
     [:select [nodes:file]
      :from tags
      :left-join nodes :on (= tags:node-id nodes:id)
      :where (like tag (quote "%\"project\"%"))]))))

(setq org-refile-targets '((nil . (:maxlevel . 4))
                           (my/roam-project-files . (:maxlevel . 4)))
      org-refile-use-outline-path 'file
      org-outline-path-complete-in-steps nil
      org-refile-allow-creating-parent-nodes 'confirm)

;; ---------------------------------------------------------------------------
;; 9. Citations + export
;; ---------------------------------------------------------------------------
;; biblio fetches BibTeX from arXiv/CrossRef into refs.bib; citar gives the
;; search/open UI; org-cite turns [cite:@key] into LaTeX citations.

(dolist (pkg '(citar citar-org-roam biblio))
  (unless (package-installed-p pkg)
    (ignore-errors (package-install pkg))))

(setq citar-bibliography          '("~/org/refs.bib")
      org-cite-global-bibliography '("~/org/refs.bib")
      citar-notes-paths           '("~/org/roam/papers"))

(with-eval-after-load 'org
  (setq org-cite-insert-processor 'citar
        org-cite-follow-processor 'citar
        org-cite-activate-processor 'citar)
  (setq org-cite-export-processors '((latex biblatex) (t basic))
        org-latex-pdf-process '("latexmk -pdf -outdir=%o %f")))

(with-eval-after-load 'citar
  (when (require 'citar-org-roam nil 'noerror)
    (citar-org-roam-mode 1)))

(global-set-key (kbd "C-c r b") #'citar-open)     
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c [") #'org-cite-insert))

;; ---------------------------------------------------------------------------
;; REMOVE FROM init.el (superseded here):
;;   - (setq org-agenda-files '(...))
;;   - the (setq org-capture-templates ...) block in section 12
;;   - the org-capture-templates entry inside custom-set-variables
;;   - my-jump-to-today / -yesterday / my-daily-timestamped-note /
;;     my-insert-daily-template / my-insert-project-template / my-open-project
;;     and their C-c j/y/l/t/P/p bindings
;;   - the org-roam-capture-templates / my-paper-template block in section 14
;; Keep: inbox.org, roam/, org-roam-db-autosync-mode, pdf+noter setup.
;; ---------------------------------------------------------------------------

(provide 'research-workflow)
