;;; ralee-structure

; Copyright (c) 2004 Sam Griffiths-Jones
;
; This is part of RALEE -- see
; http://www.sanger.ac.uk/Users/sgj/code/ralee/ and the README file
; that should accompany this file.
;
; RALEE is free software; you can redistribute it and/or modify it
; under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; RALEE is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with RALEE; if not, write to the Free Software Foundation,
; Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


(defun ralee-helix-map (pairs)
  "Calculate helix boundaries based on pairs."
  (let ((helix 0)
	(lastopen 0)
	(lastclose 9999999)
	pair
	open
	(i (length pairs))
	j
	close
	helices)

    (while (>= i 0)
      (setq i (1- i))
      (setq pair (nth i pairs))
      (setq open (car pair))
      (setq close (cdr pair))

      ; we're moving from right to left based on closing pair
      ;
      ; catch things like
      ; <<..>>..<<..>>
      ;          *
      (if (> open lastclose)
	  (setq helix (+ helix 1))
	)

      ; catch things like
      ; <<..<<..>>..<<..>>>>
      ;                   *
      (setq j 0)
      (while (nth j pairs)
	(setq p (nth j pairs))
	(setq j (1+ j))
	(if (and (< (car p) lastopen)
		 (> (car p) open))
	    (if (equal (assoc (car p) helices) helix)
		()
	      (setq helix (+ helix 1))
	      )
	  )
	)

      (setq helices (cons (cons close helix) helices))
      (setq helices (cons (cons open helix) helices))

      (setq lastopen open)
      (setq lastclose close)

      )
    helices
    )
  )


(defun ralee-get-ss-line ()
  "Get the SS_cons line"
  (save-excursion
    (let (structure-line)
      (goto-char (point-min))
      (search-forward "#=GC SS_cons")
      (copy-region-as-kill (line-beginning-position) (line-end-position))
      (setq structure (car kill-ring)))))


(defun ralee-structure-has-changed (structure-line)
  "check if the structure has changed"
  (if (equal structure-line ralee-structure-cache)
      nil
    t))


(defun ralee-get-base-pairs ()
  "Parse the secondary structure markup.
Returns a list of pairs in order of increasing closing base."
  (save-excursion
    (let ((stack ())
	  (pairs ())
	  base
	  structure-line
	  )

      (setq structure-line (ralee-get-ss-line))

      ; only recalculate the base pairing structure if structure has changed
      (if (ralee-structure-has-changed structure-line)
	  (progn
	    (goto-char (point-min))
	    (search-forward "#=GC SS_cons")
	    (search-forward " ")

	    (while (< (point) (line-end-position))
	      (setq base (char-after))
	      (if (char-equal base ?<)
		  (setq stack (cons (current-column) stack))
		)
	      (if (char-equal base ?>)
		  (progn
		    (setq pairs (cons (cons (car stack) (current-column)) pairs))
		    (setq stack (cdr stack)))
		)
	      (forward-char))
	    (setq ralee-structure-cache structure-line)   ; cache these for speed
	    (setq ralee-base-pairs-cache pairs)))         ;
      
      ralee-base-pairs-cache)))






(defun ralee-paired-column (column)
  "return the pair of <column>"
  (let (pair-column
	pairs
	pair)
    (setq pairs (ralee-get-base-pairs))
    (setq pair (assoc column pairs))
    (if pair
	(setq paired-column (cdr pair))
      (progn
	(setq pair (rassoc column pairs))
	(if pair
	    (setq paired-column (car pair)))))
    
    (if paired-column
	paired-column
      nil)))



(provide 'ralee-structure)