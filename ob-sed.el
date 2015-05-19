;;; ob-sed.el --- org-babel functions for sed scripts

;; Copyright (C) 2015 Bjarte Johansen

;; Author: Bjarte Johansen
;; Keywords: literate programming, reproducible research
;; Version: 0.1.0

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides a way to evaluate sed scripts in org-mode.

;;; Usage:

;; Add to your Emacs config:

;; (org-babel-do-load-languages
;;  'org-babel-load-languages
;;  '((sed . t)))

(require 'ob)


(defvar org-babel-sed-command "sed")

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("sed" . "sed"))

(defvar org-babel-default-header-args:sparql '()
  "Default arguments for evaluating a sed source code block.")

(defun org-babel-execute:sed (body params)
  "Execute a block of sed code with org-babel.  This function is
called by `org-babel-execute-src-block'"
  (message "executing sed source code block")
  (let* ((result-params (cdr (assoc :result-params params)))
         (cmd-line (cdr (assoc :cmd-line params)))
         (in-file (cdr (assoc :in-file params)))
	 (code-file (let ((file (org-babel-temp-file "sed-")))
                      (with-temp-file file
			(insert body)) file))
	 (stdin (let ((stdin (cdr (assoc :stdin params))))
		   (when stdin
		     (let ((tmp (org-babel-temp-file "sed-stdin-"))
			   (res (org-babel-ref-resolve stdin)))
		       (with-temp-file tmp
			 (insert res))
		       tmp))))
         (cmd (mapconcat #'identity (remove nil (list org-babel-sed-command
						      "-f" code-file
						      cmd-line
						      in-file))
			 " ")))
    (org-babel-reassemble-table
     (let ((results
            (cond
             (stdin (with-temp-buffer
                      (call-process-shell-command cmd stdin (current-buffer))
                      (buffer-string)))
             (t (org-babel-eval cmd "")))))
       (when results
         (org-babel-result-cond result-params
	   results
	   (let ((tmp (org-babel-temp-file "sed-results-")))
	     (with-temp-file tmp (insert results))
	     (org-babel-import-elisp-from-file tmp)))))
     (org-babel-pick-name
      (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
     (org-babel-pick-name
      (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params))))))

(provide 'ob-sed)
;;; ob-sed.el ends here
