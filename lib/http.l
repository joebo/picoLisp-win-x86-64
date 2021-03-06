# 13may16abu
# (c) Software Lab. Alexander Burger

# *HPorts *Home *Gate *Host *Port *Port1 *Port% *Http1 *Chunked
# *Sock *Agent *ContL *ContLen *MPartLim *MPartEnd "*HtSet"
# *Post *Url *Timeout *SesAdr *SesId *ConId
# *Referer *Cookies "*Cookies"

(default
   *HPorts 0
   *Timeout (* 300 1000) )

(mapc allow '(*Adr *Gate *Cipher *Host *ContL))

(zero *Http1)

(de *Mimes
   (`(chop "html") "text/html; charset=utf-8")
   (`(chop "svg") "image/svg+xml; charset=utf-8")
   (`(chop "au") "audio/basic" 3600)
   (`(chop "wav") "audio/x-wav" 3600)
   (`(chop "mp3") "audio/x-mpeg" 3600)
   (`(chop "gif") "image/gif" 3600)
   (`(chop "tif") "image/tiff" 3600)
   (`(chop "tiff") "image/tiff" 3600)
   (`(chop "bmp") "image/bmp" 86400)
   (`(chop "png") "image/png" 86400)
   (`(chop "jpg") "image/jpeg" 3600)
   (`(chop "jpeg") "image/jpeg" 3600)
   (`(chop "txt") "text/octet-stream" 1 T)
   (`(chop "csv") "text/csv; charset=utf-8" 1 T)
   (`(chop "css") "text/css" 3600)
   (`(chop "js") "application/x-javascript" 86400)
   (`(chop "ps") "application/postscript" 1)
   (`(chop "pdf") "application/pdf" 1)
   (`(chop "zip") "application/zip" 1)
   (`(chop "jar") "application/java-archive" 86400) )

(de mime (S . @)
   (let L (chop S)
      (if (assoc L *Mimes)
         (con @ (rest))
         (push '*Mimes (cons L (rest))) ) ) )

(de mimetype (File Typ)
   (in (list 'file "-b" (if Typ "--mime-type" "--mime") File)
      (line T) ) )

### HTTP-Client ###
(de client (Host Port How . Prg)
   (let? Sock (connect Host Port)
      (prog1
         (out Sock
            (if (atom How)
               (prinl "GET /" How " HTTP/1.0^M")
               (prinl "POST /" (car How) " HTTP/1.0^M")
               (prinl "Content-Length: " (size (cdr How)) "^M") )
            (prinl "User-Agent: PicoLisp^M")
            (prinl "Host: " Host "^M")
            (prinl "Accept-Charset: utf-8^M")
            (prinl "^M")
            (and (pair How) (prin (cdr @)))
            (flush)
            (in Sock (run Prg 1)) )
         (close Sock) ) ) )

# Local Password
(de pw (N)
   (if N
      (out ".pw" (prinl (fmt64 (in "/dev/urandom" (rd N)))))
      (in ".pw" (line T)) ) )

# PicoLisp Shell
(de psh (Pw Tty)
   (nond
      (Pw (println *Port) (bye))
      ((nand (= Pw (pw)) (ctty Tty))
         (off *Run)
         (println *Pid)
         (load (if *Dbg "@lib/too.l" "@dbg.l"))
         (off *Err)
         (quit) ) ) )

### HTTP-Server ###
(de -server ()
   (server (format (opt)) (opt)) )

(de server (P H)
   (setq
      *Port P
      *Port1 (or (sys "NAME") P)
      *Home (cons H (chop H))
      P (port *Port) )
   (gc)
   (loop
      (setq *Sock (listen P))
      (NIL (fork) (close P))
      (close *Sock) )
   (task *Sock (http @))
   (http *Sock)
   (or *SesId (bye))
   (task *Sock
      (when (accept *Sock)
         (task @ (http @)) ) ) )

(de retire (Min . Prg)
   (when (sys "PORT")
      (task -60000 60000  X (cons Min Min Prg)
         (cond
            (*Adr (off *Adr) (set X (cadr X)))
            ((kids) (set X (cadr X)))
            ((=0 (dec X)) (run (cddr X)) (bye)) ) )
      (forked) ) )

(de baseHRef (Port . @)
   (pass pack
      (or *Gate "http") "://" *Host
      (if *Gate "/" ":")
      (or Port (if *SesId *Port *Port1))
      "/" ) )

(de https @
   (pass pack "https://" *Host "/" *Port "/" *SesId) )

(de ext.html (Sym)
   (pack (ht:Fmt Sym) ".html") )

(de disallowed ()
   (and
      *Allow
      (not (idx *Allow *Url))
      (or
         (sub? ".." *Url)
         (nor
            (and *Tmp (pre? *Tmp *Url))
            (find pre? (cdr *Allow) (circ *Url)) ) ) ) )

(de notAllowed (X)
   (unless (= X "favicon.ico")
      (msg X " [" *Adr "] not allowed") ) )

# Application startup
(de app ()
   (unless *SesId
      (setq
         *Port% (not *Gate)
         *SesAdr *Adr
         *SesId (pack (in "/dev/urandom" (rd 7)) "~")
         *Sock (port *HPorts '*Port) )
      (timeout *Timeout) ) )

# Set a cookie
(de cookie @
   (if (assoc (next) "*Cookies")
      (con @ (rest))
      (push '"*Cookies" (cons (arg) (rest))) ) )

# Handle HTTP-Transaction
(de http (S)
   (use (*Post U L @X)
      (off *Post *Port% *ContL *ContLen *Cookies "*Cookies" "*HtSet")
      (catch 'http
         (in S
            (case (till " " T)
               ("GET" (_htHead))
               ("POST"
                  (on *Post)
                  (off *MPartLim *MPartEnd)
                  (_htHead)
                  (cond
                     (*MPartLim (_htMultipart))
                     ((=0 *ContLen))
                     ((cond (*ContL (line)) (*ContLen (ht:Read @)))
                        (for L (split @ '&)
                           (when (setq L (split L "="))
                              (let? S (_htSet (car L) (ht:Pack (cadr L) T))
                                 (and
                                    (cddr L)
                                    (format (car @))
                                    (unless (out (tmp S) (echo @))
                                       (call "rm" "-f" (tmp S)) ) ) ) ) ) )
                     (T (throw 'http)) ) )
               (T
                  (and @ (out S (httpStat 400 "Bad Request")))
                  (task (close S))
                  (off S)
                  (throw 'http) ) )
            (if (or (<> *ConId *SesId) (and *SesAdr (<> @ *Adr)))
               (prog (task (close S)) (off S))
               (setq
                  L (split U "?")
                  U (car L)
                  L (mapcan
                     '((A)
                        (cond
                           ((cdr (setq A (split A "=")))
                              (nil (_htSet (car A) (htArg (cadr A)))) )
                           ((tail '`(chop ".html") (car A))
                              (cons (pack (car A))) )
                           (T (cons (htArg (car A)))) ) )
                     (split (cadr L) "&") ) )
               (unless (setq *Url (ht:Pack U T))
                  (setq  *Url (car *Home)  U (cdr *Home)) )
               (out S
                  (cond
                     ((match '("-" @X "." "h" "t" "m" "l") U)
                        (and *SesId (timeout *Timeout))
                        (apply try L 'html> (extern (ht:Pack @X T))) )
                     ((disallowed)
                        (notAllowed *Url)
                        (http404) )
                     ((= "!" (car U))
                        (and *SesId (timeout *Timeout))
                        (apply (val (intern (ht:Pack (cdr U) T))) L) )
                     ((tail '("." "l") U)
                        (and *SesId (timeout *Timeout))
                        (apply script L *Url) )
                     ((=T (car (info *Url)))
                        (if (info (setq *Url (pack *Url "/default")))
                           (apply script L *Url)
                           (http404) ) )
                     ((assoc (stem U ".") *Mimes)
                        (apply httpEcho (cdr @) *Url) )
                     (T (httpEcho *Url "application/octet-stream" 1 T)) ) ) ) ) )
      (and S (=0 *Http1) (task (close S))) ) )

(de _htHead ()
   (unless
      (and
         (char)
         (= "/" (char))
         (prog (setq U (till " ")) (char))
         (= "HTTP/1" (till "." T))
         (char)
         (setq *Http1 (format (line T))) )
      (task (close S))
      (off S)
      (throw 'http) )
   (setq *Chunked (gt0 *Http1))
   (if (index "~" U)
      (setq
         *ConId (head @ U)
         U (cdr (nth U @))
         *ConId (pack (if (member "/" *ConId) (cdr @) *ConId)) )
      (off *ConId) )
   (while
      (case (lowc (till " ^M^J" T))
         ("host:" (setq *Host (cdr (line))))
         ("referer:" (setq *Referer (cdr (line))))
         ("cookie:"
            (setq *Cookies
               (mapcar
                  '((L)
                     (setq L (split L "="))
                     (cons (htArg (clip (car L))) (htArg (cadr L))) )
                  (split (cdr (line)) ";") ) ) )
         ("user-agent:" (setq *Agent (cdr (line))))
         ("content-length:" (setq *ContLen (format (cdr (line)))))
         ("content-type:"
            (if (= " multipart/form-data; boundary" (lowc (till "=" T)))
               (setq
                  *MPartLim (append '(- -) (cdr (line)))
                  *MPartEnd (append *MPartLim '(- -)) )
               (line) ) )
         ("x-pil:"
            (char)
            (when (till "=")
               (_htSet @ (ht:Pack (cdr (line)) T))
               T ) )
         (T (if (eol) (char) (line T))) ) )
   (unless *Gate
      (and (member ":" *Host) (con (prior @ *Host))) ) )

# rfc1867 multipart/form-data
(de _htMultipart ()
   (use Var
      (let L (line)
         (while (= *MPartLim L)
            (unless (= "content-disposition: form-data; name=" (lowc (till "\"" T)))
               (line)
               (throw 'http) )
            (char)
            (setq Var (till "\""))
            (char)
            (nond
               ((line)
                  (while (line))
                  (_htSet Var
                     (pack
                        (make
                           (until
                              (or
                                 (= *MPartLim (setq L (line)))
                                 (= *MPartEnd L) )
                              (when (eof)
                                 (throw 'http) )
                              (when (made)
                                 (link "^J") )
                              (link (trim L)) ) ) ) ) )
               ((head '`(chop "; filename=") (setq L @))
                  (while (line)) )
               (NIL
                  (while (line))
                  (setq L (cdr (rot (nth L 13))))
                  (if (_htSet Var (pack (stem L "/" "\\")))
                     (let F (tmp @)
                        (unless (out F (echo (pack "^M^J" *MPartLim)))
                           (call "rm" "-f" F) ) )
                     (out "/dev/null" (echo (pack "^M^J" *MPartLim))) )
                  (setq L (if (= "-" (car (line))) *MPartEnd *MPartLim)) ) ) ) ) ) )

(de _htSet (L Val)
   (let "Var" (intern (ht:Pack (car (setq L (split L ":"))) T))
      (cond
         ((and *Allow (not (idx *Allow "Var")))
            (notAllowed "Var")
            (throw 'http) )
         ((cadr L)
            (let? N (format (car (setq L (split @ "."))))
               (case (caadr L)
                  ("x" (setq Val (cons (format Val))))
                  ("y" (setq Val (cons NIL (format Val)))) )
               (nond
                  ((memq "Var" "*HtSet")
                     (push '"*HtSet" "Var")
                     (set "Var" (cons (cons N Val)))
                     Val )
                  ((assoc N (val "Var"))
                     (queue "Var" (cons N Val))
                     Val )
                  (NIL
                     (let X @
                        (cond
                           ((nand (cadr L) (cdr X)) (con X Val))
                           ((car Val) (set (cdr X) @))
                           (T (con (cdr X) (cdr Val))) ) ) ) ) ) )
         (T
            (if (= "*" (caar L))
               (set "Var" Val)
               (put "Var" 'http Val) ) ) ) ) )

(de htArg (Lst)
   (case (car Lst)
      ("$" (intern (ht:Pack (cdr Lst) T)))
      ("+" (format (cdr Lst)))
      ("-" (extern (ht:Pack (cdr Lst) T)))
      ("_" (mapcar htArg (split (cdr Lst) "_")))
      (T (ht:Pack Lst T)) ) )

# Http Transfer Header
(de http1 (Typ Upd File Att)
   (prinl "HTTP/1." *Http1 " 200 OK^M")
   (prinl "Server: PicoLisp^M")
   (prin "Date: ")
   (httpDate (date T) (time T))
   (when Upd
      (prinl "Cache-Control: max-age=" Upd "^M")
      (when (=0 Upd)
         (prinl "Cache-Control: private, no-store, no-cache^M") ) )
   (prinl "Content-Type: " (or Typ "text/html; charset=utf-8") "^M")
   (when File
      (prinl
         "Content-Disposition: "
         (if Att "attachment" "inline")
         "; filename=\"" File "\"^M" ) ) )

(de httpCookies ()
   (mapc
      '((L)
         (prin "Set-Cookie: "
            (ht:Fmt (pop 'L)) "=" (ht:Fmt (pop 'L))
            "; path=" (or (pop 'L) "/") )
         (and (pop 'L) (prin "; expires=" @))
         (and (pop 'L) (prin "; domain=" @))
         (and (pop 'L) (prin "; secure"))
         (and (pop 'L) (prin "; HttpOnly"))
         (prinl) )
      "*Cookies" ) )

(de respond (S)
   (http1 "application/octet-stream" 0)
   (prinl "Content-Length: " (size S) "^M^J^M")
   (prin S) )

(de httpHead (Typ Upd File Att)
   (http1 Typ Upd File Att)
   (and *Chunked (prinl "Transfer-Encoding: chunked^M"))
   (httpCookies)
   (prinl "^M") )

(de httpDate (Dat Tim)
   (let D (date Dat)
      (prinl
         (day Dat *Day) ", "
         (pad 2 (caddr D)) " "
         (get *Mon (cadr D)) " "
         (car D) " "
         (tim$ Tim T) " GMT^M" ) ) )

# Http Echo
(de httpEcho (File Typ Upd Att)
   (and *Tmp (pre? *Tmp File) (one Upd))
   (ifn (info File)
      (http404)
      (let I @
         (http1 (or Typ (mimetype File)) Upd (stem (chop File) "/") Att)
         (prinl "Content-Length: " (car I) "^M")
         (prin "Last-Modified: ")
         (httpDate (cadr I) (cddr I))
         (prinl "^M")
         (in File (echo)) ) ) )

(de srcUrl (Url)
   (if (or (pre? "http:" Url) (pre? "https:" Url))
      Url
      (baseHRef *Port1 Url) ) )

(de sesId (Url)
   (if
      (or
         (pre? "http:" Url)
         (pre? "https:" Url)
         (pre? "mailto:" Url)
         (pre? "javascript:" Url)
         (pre? "tel:" Url) )
      Url
      (pack *SesId Url) ) )

(de httpStat (N X . @)
   (let B (fin X)
      (if (pair X)
         (setq X (car X))
         (setq B (pack "<H1>" B "</H1>")) )
      (prinl "HTTP/1." *Http1 " " N " " X "^M")
      (prinl "Server: PicoLisp^M")
      (while (args)
         (prinl (next) "^M") )
      (prinl "Content-Type: text/html^M")
      (httpCookies)
      (prinl "Content-Length: " (+ 59 (length N) (length X) (length B)) "^M")
      (prinl "^M")
      (prinl "<HTML>")
      (prinl "<HEAD><TITLE>" N " " X "</TITLE></HEAD>")
      (prinl "<BODY>" B "</BODY>")
      (prinl "</HTML>") ) )

(de noContent ()
   (prinl "HTTP/1.0 204 No Content^M")
   (prinl "^M") )

(de redirect @
   (httpStat 303 "See Other" (pass pack "Location: ")) )

(de forbidden ()
   (httpStat 403 "No Permission")
   (throw 'http) )

(de http404 ()
   (httpStat 404 "Not Found") )

# vi:et:ts=3:sw=3
