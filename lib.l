# 27feb16abu
# (c) Software Lab. Alexander Burger

(de task (Key . Prg)
   (nond
      (Prg (del (assoc Key *Run) '*Run))
      ((num? Key) (quit "Bad Key" Key))
      ((assoc Key *Run)
         (push '*Run
            (conc
               (make
                  (when (lt0 (link Key))
                     (link (+ (eval (pop 'Prg) 1))) ) )
               (ifn (sym? (car Prg))
                  Prg
                  (cons
                     (cons 'job
                        (cons
                           (lit
                              (make
                                 (while (atom (car Prg))
                                    (link
                                       (cons (pop 'Prg) (eval (pop 'Prg) 1)) ) ) ) )
                           Prg ) ) ) ) ) ) )
      (NIL (quit "Key conflict" Key)) ) )

(de forked ()
   (let N (caar *Run)
      (when (gt0 N)
         (push '*Fork (list 'close N)) )
      (push '*Fork (list 'task N)) ) )

(de timeout (N)
   (if2 N (assoc -1 *Run)
      (set (cdr @) (+ N))
      (push '*Run (list -1 (+ N) '(bye)))
      (del @ '*Run) ) )

(de abort ("N" . "Prg")
   (catch 'abort
      (alarm "N" (throw 'abort))
      (finally (alarm 0) (run "Prg")) ) )

(de macro "Prg"
   (run (fill "Prg")) )

(de later ("@Var" . "@Prg")
   (macro
      (task (pipe (pr (prog . "@Prg")))
         (setq "@Var" (in @ (rd)))
         (task (close @)) ) )
   "@Var" )

(de recur recurse
   (run (cdr recurse)) )

(de curry "Z"
   (let ("X" (pop '"Z")  "Y" (pop '"Z")  "P" (filter pat? "X"))
      (if2 "P" (diff "X" "P")
         (list "Y" (cons 'job (lit (env @)) (fill "Z" "P")))
         (cons "Y" (fill "Z" "P"))
         (list "Y" (cons 'job (lit (env @)) "Z"))
         (cons "Y" "Z") ) ) )

(====)

### Definitions ###
(de expr ("F")
   (set "F"
      (list '@ (list 'pass (box (getd "F")))) ) )

(de subr ("F")
   (set "F"
      (getd (cadr (cadr (getd "F")))) ) )

(de undef ("X" "C")
   (when (pair "X")
      (setq  "C" (cdr "X")  "X" (car "X")) )
   (ifn "C"
      (prog1 (val "X") (set "X"))
      (prog1
         (cdr (asoq "X" (val "C")))
         (set "C"
            (delq (asoq "X" (val "C")) (val "C")) ) ) ) )

(de redef "Lst"
   (let ("Old" (car "Lst")  "New" (name "Old"))
      (set
         "New" (getd "Old")
         "Old" "New"
         "Old" (fill (cdr "Lst") "Old") )
      "New" ) )

(de daemon ("X" . Prg)
   (prog1
      (nond
         ((pair "X")
            (or (pair (getd "X")) (expr "X")) )
         ((pair (cdr "X"))
            (method (car "X") (cdr "X")) )
         (NIL
            (method (car "X") (get (or (cddr "X") *Class) (cadr "X"))) ) )
      (con @ (append Prg (cdr @))) ) )

(de patch ("Lst" "Pat" . "Prg")
   (bind (fish pat? "Pat")
      (recur ("Lst")
         (loop
            (cond
               ((match "Pat" (car "Lst"))
                  (set "Lst" (run "Prg")) )
               ((pair (car "Lst"))
                  (recurse @) ) )
            (NIL (cdr "Lst"))
            (T (atom (cdr "Lst"))
               (when (match "Pat" (cdr "Lst"))
                  (con "Lst" (run "Prg")) ) )
            (setq "Lst" (cdr "Lst")) ) ) ) )

(====)

(de cache ("Var" X . Prg)
   (let K (cons (char (hash X)) X)
      (nond
         (Prg (caar (idx "Var" K)))
         ((setq "Var" (caar (idx "Var" K T)))
            (set (car K) (run Prg 1)) )
         ((n== "Var" (val "Var"))
            (set "Var" (run Prg 1)) )
         (NIL (val "Var")) ) ) )

(====)

### I/O ###
(de tab (Lst . @)
   (for N Lst
      (let V (next)
         (and (gt0 N) (space (- N (length V))))
         (prin V)
         (and (lt0 N) (args) (space (- 0 N (length V)))) ) )
   (prinl) )

(de beep ()
   (prin "^G") )

(de msg (X . @)
   (out 2
      (print X)
      (pass prinl)
      (flush) )
   X )

(de script (File . @)
   (load File) )

(de once Prg
   (unless (idx '*Once (file) T)
      (run Prg 1) ) )

(de pil @
   (when (== "Pil" '"Pil")
      (call "mkdir" "-p" (setq "Pil" `(pack (sys "HOME") "/.pil/"))) )
   (pass pack "Pil") )

(de rc (File Key . @)
   (ctl File
      (let Lst (in File (read))
         (ifn (args)
            (cdr (assoc Key Lst))
            (let Val (next)
               (if (assoc Key Lst)
                  (con @ Val)
                  (push 'Lst (cons Key Val)) )
               (protect
                  (out File (println Lst)) )
               Val ) ) ) ) )

(de acquire (File)
   (ctl File
      (let P (in File (rd))
         (or
            (= P *Pid)
            (unless (and P (kill P 0))
               (out File (pr *Pid)) ) ) ) ) )

(de release (File)
   (ctl File (out File)) )

# Temporary Files
(de tmp @
   (unless *Tmp
      (push '*Bye '(call "rm" "-r" *Tmp))
      (push '*Fork '(off *Tmp) '(del '(call "rm" "-r" *Tmp) '*Bye))
      (call "mkdir" "-p" (setq *Tmp (pil "tmp/" *Pid "/"))) )
   (pass pack *Tmp) )

### List ###
(de insert (N Lst X)
   (conc
      (cut (dec N) 'Lst)
      (cons X)
      Lst ) )

(de remove (N Lst)
   (conc
      (cut (dec N) 'Lst)
      (cdr Lst) ) )

(de place (N Lst X)
   (conc
      (cut (dec N) 'Lst)
      (cons X)
      (cdr Lst) ) )

(de uniq (Lst)
   (let R NIL
      (filter
         '((X)
            (not (idx 'R (cons (hash X) X) T)) )
         Lst ) ) )

(de group (Lst)
   (make
      (for X Lst
         (if (assoc (car X) (made))
            (conc @ (cons (cdr X)))
            (link (list (car X) (cdr X))) ) ) ) )

### Symbol ###
(de qsym "Sym"
   (cons (val "Sym") (getl "Sym")) )

(de loc (S X)
   (if (and (str? X) (= S X))
      X
      (and
         (pair X)
         (or
            (loc S (car X))
            (loc S (cdr X)) ) ) ) )

(de local Lst
   (mapc zap Lst) )

(de import Lst
   (for Sym Lst
      (unless (== Sym (intern Sym))
         (quit "Import conflict" Sym) ) ) )

### OOP ###
(de class Lst
   (let L (val (setq *Class (car Lst)))
      (def *Class
         (recur (L)
            (if (atom (car L))
               (cdr Lst)
               (cons (car L) (recurse (cdr L))) ) ) ) ) )

(de object ("Sym" "Val" . @)
   (putl "Sym")
   (def "Sym" "Val")
   (while (args)
      (put "Sym" (next) (next)) )
   "Sym" )

(de extend X
   (setq *Class (car X)) )

# Class variables
(de var X
   (if (pair (car X))
      (put (cdar X) (caar X) (cdr X))
      (put *Class (car X) (cdr X)) ) )

(de var: X
   (apply meta X This) )

### Math ###
(de scl ("N" . "Prg")
   (if "Prg"
      (let *Scl "N" (run "Prg"))
      (setq *Scl "N") ) )

# (Knuth Vol.2, p.442)
(de ** (X N)  # N th power of X
   (if (ge0 N)
      (let Y 1
         (loop
            (when (bit? 1 N)
               (setq Y (* Y X)) )
            (T (=0 (setq N (>> 1 N)))
               Y )
            (setq X (* X X)) ) )
      0 ) )

(de accu (Var Key Val)
   (when Val
      (if (assoc Key (val Var))
         (con @ (+ Val (cdr @)))
         (push Var (cons Key Val)) ) ) )

### Pretty Printing ###
(de pretty (X N)
   (setq N (abs (space (or N 0))))
   (while (and (pair X) (== 'quote (car X)))
      (prin "'")
      (pop 'X) )
   (cond
      ((atom X) (print X))
      ((memq (car X) '(de dm redef))
         (_pretty
            (spPrt (pop 'X))
            (spPrt (pop 'X))
            (prtty1 X N Z) ) )
      ((memq (car X) '(let let?))
         (_pretty
            (cond
               ((atom (car X))
                  (spPrt (pop 'X))
                  (prtty? (pop 'X) N) )
               ((>= 12 (size (car X)))
                  (prin " (")
                  (let Z (pop 'X)
                     (prtty2 Z NIL Z) )
                  (prin ")") )
               (T
                  (nlPrt N)
                  (prin "(")
                  (let Z (pop 'X)
                     (prtty2 Z (+ N 3) Z) )
                  (prin " )") ) )
            (prtty1 X N Z) ) )
      ((== 'for (car X))
         (_pretty
            (cond
               ((or (atom (car X)) (atom (cdar X)))
                  (spPrt (pop 'X))
                  (prtty? (pop 'X) N) )
               ((>= 12 (size (car X)))
                  (spPrt (pop 'X)) )
               (T
                  (nlPrt N)
                  (prtty0 (pop 'X) (+ 3 N)) ) )
            (prtty1 X N Z) ) )
      ((== 'if2 (car X))
         (_pretty
            (when (>= 12 (size (head 2 X)))
               (spPrt (pop 'X))
               (spPrt (pop 'X)) )
            (prtty1 X N Z) ) )
      ((memq (car X) '(while until do state finally co))
         (prtty3 X N) )
      ((>= 12 (size X))
         (ifn (memq (car X) '(set setq default))
            (print X)
            (prin "(")
            (let Z X
               (printsp (pop 'X))
               (prtty2 X NIL Z) )
            (prin ")") ) )
      ((memq (car X) '(=: use later recur tab new))
         (_pretty
            (space)
            (print (pop 'X))
            (prtty1 X N Z) ) )
      ((memq (car X) '(set setq default))
         (_pretty
            (if (cdddr X)
               (prog
                  (nlPrt N)
                  (prtty2 X N Z) )
               (spPrt (pop 'X))
               (nlPrt1 (pop 'X) N) ) ) )
      ((memq (car X) '(T NIL ! if ifn when unless case casq with catch push bind job in out ctl))
         (prtty3 X N) )
      (T (prtty0 X N)) ) )

(de _pretty "Prg"
   (prin "(")
   (let Z X
      (print (pop 'X))
      (run "Prg") )
   (prin " )") )

(de prtty0 (X N)
   (prin "(")
   (let Z X
      (pretty (pop 'X) (- -3 N))
      (prtty1 X N Z) )
   (prin " )") )

(de prtty1 (X N Z)
   (loop
      (NIL X)
      (T (== Z X) (prin " ."))
      (T (atom X) (prin " . ") (print X))
      (nlPrt1 (pop 'X) N) ) )

(de prtty2 (X N Z)
   (loop
      (print (pop 'X))
      (NIL X)
      (T (== Z X) (prin " ."))
      (T (atom X) (prin " . ") (print X))
      (if N
         (prtty? (pop 'X) N)
         (space)
         (print (pop 'X)) )
      (NIL X)
      (T (== Z X) (prin " ."))
      (T (atom X) (prin " . ") (print X))
      (if N
         (nlPrt N)
         (space 2) ) ) )

(de prtty3 (X N)
   (prin "(")
   (let Z X
      (print (pop 'X))
      (when (or (atom (car X)) (>= 12 (size (car X))))
         (spPrt (pop 'X)) )
      (when X
         (prtty1 X N Z)
         (space) ) )
   (prin ")") )

(de prtty? (X N)
   (ifn (or (atom X) (>= 12 (size X)))
      (nlPrt1 X N)
      (spPrt X) ) )

(de spPrt (X)
   (space)
   (print X) )

(de nlPrt (N)
   (prinl)
   (space (+ 3 N)) )

(de nlPrt1 (X N)
   (prinl)
   (pretty X (+ 3 N)) )

(de pp ("X" C)
   (let *Dbg NIL
      (pretty
         (if (or C (pair "X"))
            (cons 'dm "X"
               (if (pair "X")
                  (method (car "X") (cdr "X"))
                  (method "X" C) ) )
            (cons 'de "X" (val "X")) ) )
      (prinl)
      "X" ) )

(de show ("X" . @)
   (let *Dbg NIL
      (setq "X" (pass get "X"))
      (when (sym? "X")
         (print "X" (val "X"))
         (prinl)
         (maps
            '((X)
               (space 3)
               (if (atom X)
                  (println X)
                  (println (cdr X) (car X)) ) )
            "X" ) )
      "X" ) )

(de view (X Y)
   (let *Dbg NIL
      (if (=T Y)
         (let N 0
            (recur (N X)
               (when X
                  (recurse (+ 3 N) (cddr X))
                  (space N)
                  (println (car X))
                  (recurse (+ 3 N) (cadr X)) ) ) )
         (let Z X
            (loop
               (T (atom X) (println X))
               (if (atom (car X))
                  (println '+-- (pop 'X))
                  (print '+---)
                  (view
                     (pop 'X)
                     (append Y (cons (if X "|   " "    "))) ) )
               (NIL X)
               (mapc prin Y)
               (T (== Z X) (println '*))
               (println '|)
               (mapc prin Y) ) ) ) ) )

### Check ###
# Assertions
(de assert Prg
   (when *Dbg
      (cons
         (list 'unless
            (if (cdr Prg) (cons 'and Prg) (car Prg))
            (list 'quit "'assert' failed" (lit (car Prg))) ) ) ) )

# Unit tests
(de test (Pat . Prg)
   (bind (fish pat? Pat)
      (unless (match Pat (run Prg 1))
         (msg Prg)
         (quit "'test' failed" Pat) ) ) )

### Debug ###
`*Dbg

(if (info (pil "editor"))
   (load (pil "editor"))
   (load "@lib/led.l" "@lib/edit.l") )

(load "@lib/debug.l" "@lib/lint.l")

(noLint 'pretty 'Z)
(noLint '_pretty 'Z)

# vi:et:ts=3:sw=3