#!/bin/sh
mkdir emacs
cd emacs
wget 'http://mirror.switch.ch/ftp/mirror/gnu/windows/emacs/emacs-24.3-bin-i386.zip'
unzip emacs-24.3-bin-i386.zip
mv emacs-24.3 ${HOME}/3rd/
cd ..
rm -rf emacs
cat > ~/.emacs <<EOF
;;(global-font-lock-mode 0)
(setq w32-get-true-file-attributes nil)
(set-language-environment "UTF-8")
(setq-default indent-tabs-mode 0);
(setq default-truncate-lines 1)
(setq truncate-partial-width-windows default-truncate-lines)
(setq backup-inhibited 1)
(setq inhibit-startup-message 1)

(line-number-mode 1)
(column-number-mode 1)
(auto-save-mode 0)
(menu-bar-mode 0)

(setq default-tab-width 4)
(setq backup-inhibited 1)
(setq compile-command (concat "make -C " (getenv "PWD")))
(setq compilation-read-command nil)
(setq compilation-ask-about-save nil)
(setq compilation-scroll-output 1)

(global-set-key [f5] "\C-xo")
(global-set-key [f9] 'buffer-menu)
(global-set-key [f12] 'compile)

(defun my-c-mode-common-hook ()
  (c-set-style "bsd")
  (setq c-basic-offset 4)
  (c-set-offset 'arglist-close '(c-lineup-close-paren))
)
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(add-hook 'vhdl-mode-hook
  '(lambda ()
    (setq indent-tabs-mode 1)
    (setq vhdl-self-insert-comments nil)
    (setq comment-column 0)
    (setq end-comment-column 120)
  )
)
(defvar vhdl-basic-offset 4)

(setq interprogram-cut-function nil)
(setq interprogram-paste-function nil)
(defun paste-from-pasteboard()
  (interactive)
  (and mark-active (filter-buffer-substring (region-beginning) (region-end) t))
  (insert (ns-get-pasteboard))
)
(defun copy-to-pasteboard(p1 p2)
  (interactive "r*")
  (ns-set-pasteboard (buffer-substring p1 p2))
  (message "Copied selection to pasteboard")
)
(defun cut-to-pasteboard(p1 p2)
  (interactive "r*")
  (ns-set-pasteboard (filter-buffer-substring p1 p2 t))
)
(global-set-key (kbd "s-v") 'paste-from-pasteboard)
(global-set-key (kbd "s-c") 'copy-to-pasteboard)
(global-set-key (kbd "s-x") 'cut-to-pasteboard)
EOF
