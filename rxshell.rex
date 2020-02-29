/* OS/2 RxShell 3.3 at <URL:http//purl.net/xyzzy/src/rxshell.zip> */

/* The new 3.x versions (2003) run under OS/2 REXXSAA 4.0 (a.k.a. */
/* classic REXX) and Quercus REXX/Personal 3.0 for OS/2.  Porting */
/* to other platforms and interpreters should be easy if and only */
/* if the target is ASCII based, i.e. neither EBCDIC nor UNICODE. */

/* REXX language level 4 is required for SIGNAL ON ... NAME ...   */
/* (not met by old BREXX interpreters).  An incomplete test with  */
/* Object REXX (language level 6) worked as expected, but the new */
/* ANSI REXX LOSTDIGITS condition is not yet supported.           */

/* If you want a RxShell version running under DOS simply remove  */
/* the math. package: 5 parts /* >> nomath */ .. /* << nomath */. */

/* Try the old RxShell in <http://purl.net/xyzzy/src/rxshell.zip> */
/* if you want to use the math. package under DOS - at the moment */
/* this is essentially the same as version 3.0 for NUMERIC DIGITS */
/* up to 100 or greater than 501.                                 */

/* Otherwise version 3.1 expects to find file -RXSHELL.cmd in the */
/* same path as RXSHELL.cmd.  In fact it uses its own name plus a */
/* leading minus character.  If you use say RXSHELL.bat, then you */
/* also need -RXSHELL.bat, and if you rename RXSHELL to BIGOOPS,  */
/* then BIGOOPS would try to read -BIGOOPS.  I know that this is  */
/* a dirty solution, but old versions already used the same trick */
/* to determine the name of the history file with a leading zero, */
/* and I want a solution working under DOS on a FAT file system - */
/* if you don't like this, here's the source.                     */

/* math. package: */
/* RX.0DIGS    used to watch numeric digits() set by user:        */
/*             call RX.DIGS  w/out argument to (re)compute math.  */
/*             "constants" for new user digits()                  */
/* RX.DIGS     also used to enter / leave "fuzzy" or double       */
/*             precision tracked in RX.0MATH internally.          */
/*          -  RX.TRAP resets  numeric digits RX.DIGS( 0 )        */
/* RX.FUNC     functions like INT(f,a,b) = integral of f(X) dX    */
/*             from X=a to b have to INTERPRET f(X), where f is   */
/*             a user formula.  This is done by RX.FUNC(X).       */
/* RX.FUNK     sets RX.0FUNC = 1 terminating the next RX.FUNC(),  */
/*             used as CALL ON HALT NAME RX.FUNK in potential     */
/*             dead loops like DF(), INT(), INV(), or SUM()       */
/* RX.TRAF     simplifies TRAce F handling of iterated RX.FUNC(). */
/*             Abusing TRAce F for a special purpose should be no */
/*             problem, it's otherwise the same as TRACE Normal.  */
/* RX.MATH     +2n: return n-th Bernoulli number, RX.0B.n         */
/*             odd: return 0, any odd Bernoulli number > 1        */
/*             +1 : 0.5 for ZETA, but 1st Bernoulli = -0.5        */
/*             -2n: return saved odd ZETA(1-2*n), RX.0B.m, m = -n */
/*              0 : Euler's C0 = lim 1+1/2+..+1/n-ln(n) = RX.0B.0 */
/*           - RX.DIGS(0) calls RX.MATH 0  after dropping RX.0B.0 */
/*             to (re)compute all necessary "constants":          */
/* RX.0LN.2    = LN( 2 )      ,  RX.0PI.2 = 2 * ATAN( 1 )         */
/* RX.0LN.1    = e = EXP( 1 ) ,  RX.0PI.1 = pi = 2*RX.0PI.2       */
/* RX.0LN.0    = LN( 2 * pi ) ,  RX.0PI.0 = ROOT( pi / 4 )        */
/* RX.0ROOT    2nd..4th ROOT() solution returned by NORM()        */
/* RX.0ZETA    ZETA() accelerator determined by RX.MATH(0)        */
/* RX.0GAMMA   hardwired C0 digits, threshold for RX.INFO 5       */
/* RX.ARGN     argument check in most functions, basically        */
/*             ARG( 1 = ARG()) without ill side effect            */
/* Not yet implemented:  ZETA(x) for 0 < x < 1 (unknown formula). */
/*             Better don't use ZETA(x) if x is no integer, the   */
/*             convergence is extremely slow (unless x is "big"). */
/* Not yet implemented:  real LOG(x) and real LN(x) for x < 0.    */
/* GAMMA(x) for hardwired x > 1000 uses Stirling's approximation. */
/*             This GAMMA-limit should be a function of digits(). */
/* GAMMA(x) won't work if 2 * x is no integer and digits() > 100, */
/*             actually "odd" ZETA( 2*n+1 ) is the real problem.  */
/* NUMERIC DIGITS 501 initialization is slow, but then accurate.  */
/* NUMERIC DIGITS 502 initialization is also slow, and then some  */
/*             functions like GAMMA(x) and LI(x) are restricted.  */
/*             pi = ACOS(-1) and e = EXP(1) are always accurate.  */

/* error handling: */
/* RC          non-zero numerical RC reflected in RxShell prompt  */
/*          -  preserved only if changed, otherwise dropped again */
/*          -  RX.TRAP sets RC according to the SIGNAL condition: */
/*             -1  NOTREADY,  -2 NOVALUE,  -3 FAILURE,  -4 HALT,  */
/*             -5..-99 SYNTAX errors 5..99 showing ERRORTEXT(RC)  */
/*          -  RX.TRAP does not modify ERROR return codes set by  */
/*             external commands (except from FAILURE conditions) */
/* RX          this variable is not exposed.  If it's lost then   */
/*             all user variables are lost, indicating a severe   */
/*             RxShell error, i.e. generally no user error.       */
/*          -  to debug the command loop RX.EXEC itself drop RX   */
/*             in RX.TRAP.  Already prepared: if 0 then drop RX   */
/* RX.WARP     reload somehow lost RxGetKey() and RxScrSiz() with */
/*             RX.UTIL(), drop into RX.TRAP, user variables lost  */
/* RX.TRAP     common error handler                               */
/*          -  if RX lost (=> user variables incl. RESULT lost):  */
/*             interactive REXX label trace (StdIn and StdOut),   */
/*             RETURN if CALLed, else (try to) continue anyway at */
/*             RX.EXEC command loop after resetting RX.0ARGN = 0, */
/*             numeric fuzz 0, and numeric digits RX.DIGS(0).     */
/*          -  if RX not lost (assuming user error in INTERPRET): */
/*             set RX.0HELP = command for detailed error help and */
/*             continue at RX.EXEC, error output via RX.CRLF()    */
/*          -  don't call RX.TRAP explicitly, this won't work as  */
/*             soon as some old trap condition() is pending after */
/*             SIGNAL RX.EXEC.                                    */
/*          -  HALT, NOVALUE, and SYNTAX are not always handled   */
/*             by RX.TRAP: compare RX.CHAW, RX.FUNK, and RX.WARP  */
/*          -  note that SIGKILL and SIGTERM aren't trapped, only */
/*             SIGINT [Ctrl]+[Break] or [Ctrl]+[C] causes HALT.   */
/*          -  sometimes the REXX default SIGNAL OFF HALT instead */
/*             of RX.TRAP handles HALT, this terminates RxShell:  */
/*             OS/2 REXXSAA HALT within INTERPRET is unreliable.  */
/* RX.HALT     break point used for interactive REXX label trace  */
/*             by RX.TRAP, could be called anywhere for debugging */
/* ERROR       user commands SIGNAL ON ERROR or CALL ON ERROR are */
/*             supported, i.e. handled by RX.TRAP like FAILURE    */
/*          -  RX.TRAP doesn't reenable SIGNAL ON ERROR, only the */
/*             first error is trapped.  CALL ON ERROR can be used */
/*             to handle all errors by RX.TRAP.  Often non-zero   */
/*             return codes of OS commands are not really errors. */
/* NOTREADY    supported like ERROR (ON or OFF, CALL or SIGNAL)   */
/*          -  DOS NUL-device can cause spurious NOTREADY         */
/* NOVALUE     forced OFF before next command line INTERPRETation */
/* SYNTAX      forced ON  before next command line INTERPRETation */
/* FAILURE     forced ON  before next command line INTERPRETation */
/* HALT        forced ON  before next command line INTERPRETation */
/* LOSTDIGITS: not supported, as long as Regina 3.0 & Object REXX */
/*             don't work reliably on an OS/2 system I can't test */
/*             this new ANSI REXX feature... :-(                  */

/* trace handling: */
/* RX.0TEST    saved user trace setting, initially the setting in */
/*             effect before the 1st statement is executed (under */
/*             'Normal' conditions 'N' or '?R' if SET RXTRACE=ON) */
/*          -  at least one REXX implementation supports only the */
/*             abbreviated settings 'O' for 'Off' etc., therefore */
/*             this script internally uses only the abbreviations */
/*             although RX.INFO 9 shows long names with RX.TRAV() */
/*          -  if the user traces his commands  then he also sees */
/*             the following two script lines unfortunately...    */
/*     RX.0TEST = trace( 'O' )   /* saves user's trace setting */ */
/*     interpret RX.0LINE        /* next command, user's trace */ */
/* RX.0?       dummy call result used to preserve user's RESULT   */

/* input handling: */
/* RX.CHAR     gets the next input char. by RxGetKey( 'NoEcho' ), */
/*             extended keys are returned as 2 bytes NUL || CODE  */
/*             compatible with Quercus INKEY( 'Wait', 'Fold' ) or */
/*             Quercus REXXLIB.DLL INKEY() a.k.a. LIB_INKEY()     */
/*          -  RxGetKey() reads from \dev\con (not StdIn) in its  */
/*             actual mode, normally "cooked": ^C, ^P, and ^S are */
/*             handled within \dev\con and not seen by RxGetKey() */
/*          -  REXXLIB.DLL INKEY() returns "raw" ^C, ^P, and ^S,  */
/*             therefore RX.CHAR shows HALT as x2c(0000) = ^BREAK */
/*          -  DOS only: if "REXX/Personal" is the interpreter as */
/*             noted in RX.0REXX then RX.CHAR() returns INKEY()   */
/*          -  INKEY() normally "folds" extended scan codes E0??  */
/*             to 00??, RxGetKey() always returns E0 and then ??. */
/*             With RxGetKey() it's not possible to distinguish   */
/*             between alpha = d2c(224) = x2c(0E0) and new keys,  */
/*             therefore ALT [pad 2]+[pad 2]+[pad 4] won't work.  */
/*          -  F6 RX.INFO(6) lists mapped "impossible" characters */
/* RX.CHAW     HALT interrupt handler used by RX.CHAR and RX.CURS */
/* RX.PLUS     input echoing by RX.ECHO() after translating ASCII */
/*             NUL / BEL / BS / TAB / LF / CR / ESC to d2c( 176 ) */
/*             defined in RX.0PLUS string of non-printable char.s */
/*          -  NAK is echoed "as is" d2c( 21 ), potential problem */
/*          -  NUL could be echoed "as is", 176 is better visible */
/*          -  ESC could be echoed "as is" if ANSI is OFF, but to */
/*             test this r/w access on \dev\con would be required */
/* RX.ECHO     input echoing and normal output using CHAROUT() on */
/*             STDOUT: assumes a TTY-device supporting CR, LF, BS */
/* RX.BEEP     calls RX.ECHO( x2c( 07 )), ASCII 7 is BEL          */
/* RX.CURS     toggles insert mode and if available CURSORTYPE(), */
/*             REXX/Personal and REXXLIB.DLL have a CURSORTYPE(). */
/* RX.SIZE     calls RxScrSiz() == RexxUtil's SysTextScreenSize() */
/*             or SCRSIZE() under REXX/Personal (only for DOS)    */
/* RX.MORE     tiny pager supporting either 40-79 or more columns */
/* say         only used in RX.TRAP or interactive RX.CHAR trace  */
/*          -  SAY writes on STDOUT (like interactive REXX trace) */
/* STDIN:      pseudo file name in some IBM REXX implementations  */
/* STDOUT:     dito, pseudo names aren't portable, not needed for */
/*             standard I/O, and therefore not used here.  Only a */
/*             program using STREAM() may need 'STDIN:'/'STDOUT:' */
/* STDERR:     dito, needed in unnamed pipe or background process */
/* '@ECHO OFF' only used if address() = 'CMD', not needed for DOS */
/* RxFuncAdd   only used in RX.UTIL to load RxScrSiz and RxGetKey */
/* RxFuncQuery ditto.  The ooREXX 6.03 RexxUtil.dll does not more */
/*             support aliases RxScrSiz + RxGetKey, therefore the */
/*             long names are now used.                           */
/* RxQueue     only used in RX.INFO as RxQueue('Get') under OS/2  */
/* RxGetKey    PC DOS 7 returns '' (a zero length string) instead */
/*             of ASCII NUL (one character) as first character of */
/*             extended key codes (i.e. function keys etc.), and  */
/*             so testing c2d(KEY) = 0 differs from KEY = d2c(0)  */

/* RX.0abcd    intentionally weird variable symbols, because user */
/*             may set ABCD with side effects on any RX.ABCD, but */
/*             he cannot change REXX constants like 0ABCD         */

   RX.0TEST = trace( 'O' )             /* <= very first statement */
   trace 'N'                           /*    preserves RXTRACE=ON */
   numeric digits 20                   /* 2010-04-11: add default */
   RX.0CRLF = x2c( 0D0A )              /* RX.TRAP uses RX.0TRAP:  */
   RX.0TRAP = RX.0CRLF || right( '+++', 10 )
   RX.0PLUS = RX.0CRLF || x2c( 000708091B )
   RX.0PLOT = copies( d2c( 176 ), length( RX.0PLUS ))
   signal on syntax name RX.TRAP ;  signal on novalue name RX.TRAP
   signal on halt   name RX.TRAP ;  signal on failure name RX.TRAP

   RX.0ARGN = arg() > 1 | arg(1) <> '' /* 0: interactive input    */
   RX.0HELP = ''                       /* no error help shortcut  */
   RX.0USER = value( 'RESULT')         /* initialize user result  */
   RX.0DIGS = 0                        /* catch change of digits  */
   RX.0     = 0         /* history lines RX.1 upto RX.n, n = RX.0 */
   RX..     = 0         /* 0 overtype or 1 insert mode, initial 0 */

   parse source RX.1 . .               /* if OS/2 ignore Quercus  */
   RX.0WARP = ( RX.1 = 'OS/2' ) | ( RX.1 = 'WindowsNT' )
   if RX.0WARP                         /* 1: OS/2 , 0: assume DOS */
      then call RX.UTIL                /* Quercus : REXX/Personal */
      else parse version RX.0REXX . .  /* PC DOS 7: REXXSAA       */

   call RX.CURS   ;  call RX.CURS      /* (try to) toggle cursor  */
   parse value RX.SIZE() with . RX.0ECHO .
   select
      when RX.0ECHO  < 40  then exit RX.TRAP( '40+ columns required' )
      when x2c( 30 ) <> 0  then exit RX.TRAP( 'EBCDIC not supported' )
      when RX.0REXX = 'REXX/Personal'           then options 'NEWCOM'
      when RX.0REXX = 'REXXSAA' & RX.1 = 'DOS'  then nop
      when RX.0WARP & RX.0ECHO < 50000          then nop
      when RX.0WARP        then exit RX.TRAP( 'SysGetKey() required' )
      otherwise   call RX.TRAP 'warning: unknown' RX.1 RX.0REXX
   end

RX.EXEC:                               /* ----------------------- */
   do until RX.0ARGN > arg() & RX.0HELP = ''
      if value( 'RC' ) = value( 'RX' ) then drop rc
      RX = value( 'RC' )   ;  rc = RX  /* handle same or no value */
      if \ datatype( RX, 'W' ) | RX = 0 then parse source . RX .
      select                           /* select shell prompt: */
         when RX = 'COMMAND'     then  RX = 'REXX'
         when RX = 'FUNCTION'    then  RX = 'FUNC'
         when RX = 'SUBROUTINE'  then  RX = 'CALL'
         when RX > 0             then  RX = right( RX, 4, 0 )
         otherwise                     RX = right( RX, 4 )
      end
      RX.0ECHO = '[' || RX || '] '
/* >> nomath */
      if RX.0DIGS <> digits() then do  /* compute "constants": */
         RX.0DIGS =  digits() ;  call RX.DIGS
      end
/* << nomath */
      if RX.0HELP = '' & RX.0ARGN > 0 then do
         RX.0LINE = arg( RX.0ARGN )    /* treat arg as command */
         RX.0ARGN = RX.0ARGN + 1       /* in recursive RxShell */
      end
      else RX.0LINE = RX.LINE( )       /* get new command line */
      RX = rc  ;  if RX.0WARP & address() = 'CMD' then '@ECHO OFF'
      rc = RX  ;  RX.0HELP = ''        /* do not echo OS/2 CMD */
      signal off novalue            ;  result = RX.0USER
      RX.0USER = trace()            ;  trace value RX.0TEST
      interpret RX.0LINE
      RX.0TEST = trace( 'O' )       ;  trace value RX.0USER
      RX.0USER = value( 'RESULT' )     /* swap user RESULT, trace */
      signal on syntax name RX.TRAP ;  signal on novalue name RX.TRAP
      signal on halt   name RX.TRAP ;  signal on failure name RX.TRAP
   end
   if datatype( value( 'RC' ), 'W' ) then exit rc  ;  else exit 0

RX.WARP:                               /* ----------------------- */
   RX.0? = sigl
   if rc = 43 then if RX.UTIL()        /* 43: routine not found   */
      then call RX.ECHO RX.0TRAP 'RexxUtil functions reloaded'
   sigl = RX.0?
ERROR: FAILURE: HALT: NOTREADY: NOVALUE: SYNTAX: RX.TRAP:
   RX.0? = trace( 'O' )                /* stop interactive trace  */
   if 0 then drop RX                   /* 1: debug RX.EXEC itself */
   if symbol( 'RX' ) = 'VAR' then do   /* user error in INTERPRET */
      trace value RX.0USER ;  drop RX  /* RX.TRAP error is fatal  */
      RX.0HELP = ''        ;  RX.0ECHO = ''
   end
   else do                             /* fatal: lost RX variable */
      if RX.0? = 'O' then RX.0? = 'N'  /* trace Normal (at least) */
      trace value RX.0?    ;  parse source RX.0?
      RX.0HELP = '.'       ;  RX.0ECHO = RX.0TRAP RX.0?
   end
   RX.0INFO = condition( 'd' )         /* description / errortext */
   RX.0ECHO = RX.0ECHO || RX.0TRAP condition( 'c' ) 'trap:' RX.0INFO
   signal off syntax       ;  signal on failure name RX.TRAP
   signal off halt         ;  signal off novalue
   select
      when wordpos( condition( 'c' ), 'ERROR FAILURE' ) > 0 then do
         if RX.0INFO > '' then RX.0ECHO = RX.0ECHO || RX.0TRAP
         RX.0ECHO = RX.0ECHO '(RC' rc || ')'
         if condition( 'c' ) = 'FAILURE' then do
            if RX.0WARP & RX.0HELP = '' then
               RX.0HELP = RX.HELP( 'sys' || right( rc, 4, 0 ))
            rc = -3                    /* OS/2: 'helpmsg sysNNNN' */
         end
      end
      when wordpos( condition( 'c' ), 'HALT SYNTAX'   ) > 0 then do
         if condition( 'c' ) = 'HALT' then rc = 4
         if RX.0INFO > '' & pos( RX.0INFO, rc errortext( rc )) = 0
            then RX.0ECHO = RX.0ECHO || RX.0TRAP errortext( rc )
            else RX.0ECHO = RX.0ECHO errortext( rc )
         if RX.0INFO = '' then RX.0INFO = errortext( rc )
         if RX.0HELP > '' then nop     /* skip RX.HELP under test */
         else if RX.0WARP              /* REXX help OS/2 (or DOS) */
            then RX.0HELP = RX.HELP( 'rex' || right( rc, 4, 0 ))
            else RX.0HELP = RX.HELP( 'error', 'rexx' )
         rc = -rc                      /* rc < 0: REXX error code */
      end
      when condition( 'c' ) = 'NOVALUE'  then rc = -2 /* dubious  */
      when condition( 'c' ) = 'NOTREADY' then rc = -1 /* dubious  */
      otherwise                        /* force non-zero whole rc */
         if datatype( value( 'RC' ), 'W' ) = 0 then rc = 1
         if RX.0INFO = '' then RX.0ECHO = RX.0ECHO arg( 1 )
   end                                 /* any direct call RX.TRAP */
   if RX.0HELP <> '.' & RX.0HELP <> '' then do
      if RX.0REXX <> 'ooREXX' then  do /* use old DOS + OS/2 help */
         RX.0HELP = 'see "' || RX.0HELP || '"'
         RX.0ECHO = RX.0ECHO || RX.0TRAP RX.0HELP
      end
      else  do                         /* hide the ooREXX syntax: */
         interpret "RX.0HELP = ( condition( 'o' )~MESSAGE <> .nil )"
         if RX.0HELP then  do          /* show secondary message: */
            interpret "RX.0HELP = condition( 'o' )~MESSAGE"
            RX.0ECHO = RX.0ECHO || RX.0TRAP RX.0HELP
         end                           /* Windows SysGetErrortext */
      end                              /* not yet implemented :-( */
   end
   if RX.0HELP <> '.' & condition() = 'SIGNAL' then do
      RX.0USER = value( 'RESULT' )  ;  call RX.CRLF RX.0ECHO
      signal on syntax name RX.TRAP ;  signal on novalue name RX.TRAP
      signal on halt   name RX.TRAP ;  signal RX.EXEC
   end                                 /* save RESULT before CALL */

   RX.0ECHO = RX.0ECHO || RX.0CRLF || format( sigl, 6 )
   signal on syntax name RX.SIGL       /* throw syntax error 3... */
   if 0 < sigl & 0 < sourceline()      /* if no handle for source */
      then RX.0ECHO = RX.0ECHO '*-*' strip( sourceline( sigl ))
      else RX.0ECHO = RX.0ECHO '+++ (source line unavailable)'
RX.SIGL:
   signal off syntax                   /* ...catch syntax error 3 */
   if abbrev( right( RX.0ECHO, 2 + 6 ), RX.0CRLF ) then do
      RX.0ECHO = RX.0ECHO '+++ (source line unreadable)' ;  rc = -rc
   end

   say RX.0ECHO         /* trace uses STDOUT anyway, SAY is okay  */
   if condition() = 'SIGNAL' then do   /* SIGNAL, CALL, or empty  */
      RX.0USER = value( 'RESULT' )  ;  call RX.HALT
/* >> nomath */
      numeric digits RX.DIGS( 0 )   ;  numeric fuzz 0
/* << nomath */
      RX.0ARGN = 0                     /* invalidate pending arg. */
      signal on syntax name RX.TRAP ;  signal on novalue name RX.TRAP
      signal on halt   name RX.TRAP ;  signal RX.EXEC
   end                                 /* don't change next line: */
RX.HALT: trace ?L    ;  RX.HALT: RX.0? = trace( 'O' ) ;  return rc

RX.LINE: procedure expose RX.          /* ----------------------- */
   EXPO = 'LINE POS SCAN'  ;  LINE = ''   ;  POS = 0  ;  SCAN = 0
   call RX.KILL 0                      /* show initial prompt     */

   do until KEY == x2c( 0D )
      KEY = RX.CHAR()
      select
         when KEY == x2c( 08 ) then do                /* BS ----- */
            if length( LINE ) = 0 | POS = 0 then iterate
            LINE = delstr( LINE, POS, 1 ) ;  POS = POS - 1
            call RX.ECHO x2c(8) x2c(8)    ;  call RX.REST
         end
         when KEY == x2c( 09 ) then do                /* TAB ---- */
            if symbol( 'FIND' ) <> 'VAR' then FIND = LINE
            if symbol( 'LAST' ) <> 'VAR' then FIND = LINE
               else     if LAST <> LINE  then FIND = LINE
            if SCAN = 0 then SCAN = RX.0 + 1
            do I = SCAN -1 by -1 until I = SCAN
               if I = 0 then do        /* wrap around I = RX.0 */
                  if SCAN <= RX.0 then I = RX.0 ;  else leave I
               end                     /* found RX.I: I = SCAN */
               if abbrev( RX.I, FIND ) then LAST = RX.SCAN( I )
            end I
         end
         when KEY == x2c( 0A ) then call RX.NEXT KEY  /* LF ----- */
         when KEY == x2c( 0D ) then iterate           /* CR ----- */
         when KEY == x2c( 1B ) then do                /* ESC ---- */
            call RX.KILL 1 ;  LINE = ''   ;  POS = 0
         end
         when KEY == x2c( 0000 ) then  call RX.BEEP   /* HALT --- */
         when KEY == x2c( 0001 ) then  call RX.NEXT x2c(1B) /* ESC */
         when KEY == x2c( 0003 ) then  call RX.NEXT x2c(00) /* NUL */
         when KEY == x2c( 000E ) then  call RX.NEXT x2c(08) /* BS  */
         when KEY == x2c( 000F ) then  call RX.NEXT x2c(09) /* TAB */
         when KEY == x2c( 0010 ) then  call RX.NEXT x2c(11) /* c-Q */
         when KEY == x2c( 0017 ) then  call RX.NEXT x2c(09) /* TAB */
         when KEY == x2c( 0019 ) then  call RX.NEXT x2c(10) /* c-P */
         when KEY == x2c( 001A ) then  call RX.NEXT x2c(1B) /* ESC */
         when KEY == x2c( 001C ) then  call RX.NEXT x2c(0D) /* CR  */
         when KEY == x2c( 001E ) then  call RX.NEXT d2c(224)
         when KEY == x2c( 001F ) then  call RX.NEXT x2c(13) /* c-S */
         when KEY == x2c( 0022 ) then  call RX.NEXT x2c(07) /* BEL */
         when KEY == x2c( 0023 ) then  call RX.NEXT x2c(08) /* BS  */
         when KEY == x2c( 0024 ) then  call RX.NEXT x2c(0A) /* LF  */
         when KEY == x2c( 002E ) then  call RX.NEXT x2c(03) /* ETX */
         when KEY == x2c( 0032 ) then  call RX.NEXT x2c(0D) /* CR  */
         when KEY == x2c( 0037 ) then  call RX.NEXT x2c(1B) /* ESC */
         when KEY == x2c( 003B ) then  call RX.INFO 1 /* F1 ----- */
         when KEY == x2c( 003C ) then  select         /* F2 ----- */
            when LINE > '' then do
               call RX.KILL 1    ;  LINE = RX.QUOT( LINE )
               call RX.PLUS LINE ;  POS  = length(  LINE )
            end
            when RX.0 > 0  then do
               I = RX.0          ;  RX.I = RX.QUOT( RX.I )
               call RX.SCAN I
            end
            otherwise nop     /* no input and empty history */
         end
         when KEY == x2c( 003D ) then  exit RX.CRLF() /* F3 ----- */
         when KEY == x2c( 006B ) then  exit RX.CRLF() /* a-F4     */
         when KEY == x2c( 003E ) then  do             /* F4 ----- */
            call RX.KILL 1 ;  call RX.SAVE   ;  call RX.KILL 0
         end
         when KEY == x2c( 003F ) then  call RX.INFO 5 /* F5 ----- */
         when KEY == x2c( 0040 ) then  call RX.INFO 6 /* F6 ----- */
         when KEY == x2c( 0041 ) then  call RX.BEEP   /* F7 ----- */
         when KEY == x2c( 0042 ) then  call RX.BEEP   /* F8 ----- */
         when KEY == x2c( 0043 ) then  call RX.INFO 9 /* F9 ----- */
         when KEY == x2c( 0044 ) then  do I = RX.0 to 1 by -1
            RX.0 = I - 1   ;  drop RX.I               /* F10 ---- */
         end I
         when KEY == x2c( 0047 ) then  do while RX.LEFT( 1 )
         end                           /* 0047 Home, 0048 Up ---- */
         when KEY == x2c( 0048 ) then  call RX.SCAN SCAN - 1
         when KEY == x2c( 0049 ) then  call RX.BEEP   /* PgUp --- */
         when KEY == x2c( 004A ) then  call RX.BEEP   /* Minus -- */
         when KEY == x2c( 004B ) then  call RX.LEFT 1 /* Left --- */
         when KEY == x2c( 004C ) then  call RX.BEEP   /* Center - */
         when KEY == x2c( 004D ) then  call RX.LEFT 0 /* Right -- */
         when KEY == x2c( 004E ) then  call RX.BEEP   /* Plus --- */
         when KEY == x2c( 004F ) then  do while RX.LEFT( 0 )
         end                           /* 004F End, 0050 Down --- */
         when KEY == x2c( 0050 ) then  call RX.SCAN SCAN + 1
         when KEY == x2c( 0051 ) then  call RX.BEEP   /* PgDn --- */
         when KEY == x2c( 0052 ) then  call RX.CURS   /* Ins ---- */
         when KEY == x2c( 0053 ) then  do             /* Del ---- */
            LINE = delstr( LINE, POS + 1, 1 )   ;  call RX.REST
         end         /*  0072 supported by INKEY, not SysGetKey:  */
         when KEY == x2c( 0072 ) then  call RX.BEEP   /* c-PrtSc  */
         when KEY == x2c( 0073 ) then  do while RX.LEFT( 1 )
            if substr( LINE, POS + 1, 1 ) = ' ' then iterate
            if substr( LINE, POS    , 1 ) = ' ' then leave
         end                                          /* c-Left   */
         when KEY == x2c( 0074 ) then  do while RX.LEFT( 0 )
            if substr( LINE, POS    , 1 ) <> ' ' then iterate
            if substr( LINE, POS + 1, 1 ) <> ' ' then leave
         end                                          /* c-Right  */
         when KEY == x2c( 0075 ) then  do             /* c-End    */
            call RX.ECHO copies( ' ',    length( LINE ) - POS )
            call RX.ECHO copies( x2c(8), length( LINE ) - POS )
            LINE = left( LINE, POS )
         end
         when KEY == x2c( 0076 ) then  call RX.BEEP   /* c-PgDn   */
         when KEY == x2c( 0077 ) then  do             /* c-Home   */
            call RX.KILL 1 ;  LINE = substr( LINE, POS + 1 )
            POS = 0        ;  call RX.REST
         end
         when KEY == x2c( 0085 ) then  call RX.BEEP   /* F11 ---- */
         when KEY == x2c( 0086 ) then  do             /* F12 ---- */
            call RX.KILL 1 ;  call RX.CODE KEY  ;  call RX.KILL 0
         end
         when length( KEY ) > 1  then  call RX.BEEP   /* ignore key */
         otherwise   call RX.NEXT KEY                 /* insert key */
      end
   end

   if LINE > '' then do                /* update LINE history: */
      SCAN = RX.0                      /* skip void or same    */
      if LINE <> RX.SCAN then do
         SCAN = SCAN + 1   ;  RX.0 = SCAN ;  RX.SCAN = LINE
      end
      do while RX.LEFT( 0 )   ;  end   /* go to to end of line */
   end
   call RX.CRLF   ;  return LINE

RX.NEXT: procedure expose (EXPO) RX.   /* insert/overwrite KEY */
   POS = POS + 1  ;  call RX.PLUS arg( 1 )
   if RX..  then LINE = insert(   arg( 1 ), LINE, POS - 1 )
            else LINE = overlay(  arg( 1 ), LINE, POS )
   return RX.REST()

RX.REST: procedure expose (EXPO) RX.   /* redraw rest of LINE  */
   call RX.PLUS substr( LINE, POS + 1 ) || ' '
   return RX.ECHO( copies( x2c( 8 ), 1 + length( LINE ) - POS ))

RX.SCAN: procedure expose (EXPO) RX.   /* input = history LINE */
   arg SCAN                      ;  if SCAN > RX.0 then SCAN = 1
   if SCAN < 1 then SCAN = RX.0  ;  call RX.KILL 1
   if RX.0 = 0 then LINE = ''    ;  else LINE = RX.SCAN
   POS = length( LINE ) ;  call RX.PLUS LINE ;  return LINE

RX.KILL: procedure expose (EXPO) RX.   /* clear or redraw line */
   if arg( 1 ) then do                 /* clear complete input */
      call RX.PLUS substr( LINE, POS + 1 )
      return RX.ECHO( copies( x2c(8) x2c(8), length( LINE )))
   end
   call RX.PLUS RX.0ECHO || LINE       /* show prompt and line */
   return RX.ECHO( copies( x2c(8), length( LINE ) - POS ))

RX.LEFT: procedure expose (EXPO) RX.   /* move cursor position */
   if arg( 1 ) then do                 /* move cursor left:    */
      if POS > 0 then call RX.ECHO x2c(8)
      POS = max( 0, POS - 1 ) ;  return sign( POS )
   end                                 /* else cursor right:   */
   else  if POS < length( LINE ) then do
      POS = POS + 1  ;  call RX.PLUS substr( LINE, POS, 1 )
   end                                 /* result 1: not at end */
   return   POS < length( LINE )       /* result 0:  End pos.  */

RX.QUOT: procedure expose RX.          /* return quoted arg(1) */
   END = length( arg( 1 ))             /* 1st    -> '1st'      */
   parse arg TOP 2 MID =(END) END      /* '2nd'  -> "2nd"      */

   if TOP <> END then return "'" || arg( 1 ) || "'"
   if TOP == "'" then return '"' || MID || '"'
   if TOP == '"' then do               /* "3rd"  -> 'call 3rd' */
      if abbrev( translate( MID ), 'CALL ' )
         then return substr( MID, 6 )  /* "call 5th"  ->  5th  */
         else return "'call" MID || "'"
   end
   return "'" || arg( 1 ) || "'"       /* else   -> 'else'     */

RX.CODE: procedure expose RX.          /* input key decoder... */
   do N = 0 to 255                     /* WIN keys INCOMPLETE  */
      X = d2x( N, 2 )   ;  I.X = d2c( N )
      if N < 32 then I.X = I.X '  (^' || d2c( N + 64 ) || ')'
      X.X = '-/-' x2c( 7 )    /* for unknown 00??: x2c(7) BELl */
   end N                      /* all DOS keys should be known  */
   I.07 = 'BEL (^G)' ;  I.08 = 'BS  (^H)' ;  I.09 = 'TAB (^I)'
   I.0A = 'LF  (^J)' ;  I.0D = 'CR  (^M)' ;  I.1B = 'ESC (^[)'
   I.20 = 'SPace'    ;  I.FF = 'RSP'      ;  I.7F = 'DEL (^?)'
   R.0  = 'Up Minus Center Plus Down Ins Del Tab Slash Star'
   R.1  = 'F s-F c-F a-F'     /* c-Up, c-Minus overlap 141,142 */
   R.2  = 'QWERTYUIOP'        /* hex. 0010..0019               */
   R.3  = 'ASDFGHJKL:'        /* hex. 001E..0028               */
   R.4  = 'ZXCVBNM<>?'        /* hex. 002C..0035               */
   do N = 10 to 1 by -1
      X = d2x( N +  1, 2 ) ;  X.X = 'c-'  || N // 10
      X = d2x( N + 15, 2 ) ;  X.X = 'alt' substr( R.2, N, 1 )
      X = d2x( N + 29, 2 ) ;  X.X = 'alt' substr( R.3, N, 1 )
      X = d2x( N + 43, 2 ) ;  X.X = 'alt' substr( R.4, N, 1 )
      X = d2x( N + 58, 2 ) ;  X.X = '  F' || N
      X = d2x( N + 83, 2 ) ;  X.X = 's-F' || N
      X = d2x( N + 93, 2 ) ;  X.X = 'c-F' || N
      X = d2x( N +103, 2 ) ;  X.X = 'a-F' || N
      X = d2x( N +119, 2 ) ;  X.X = 'alt' N // 10
      KEY = word( R.1, (N + 1) % 2 ) || (11 + (N + 1) // 2)
      X = d2x( N +132, 2 ) ;  X.X = right( KEY, 5 )
      X = d2x( N +140, 2 ) ;  X.X = 'c-'  || word( R.0, N )
   end N
   R.0 = 'Left Right  End   PgDn Home'
   R.1  = '[{  ]}     Enter -/-  A'    /* -/- 001D left Contr. */
   R.2  = ';:  ''"    `~    -/-  |\'   /* -/- 002A left  Shift */
   R.3  = ',<  .>     /?    -/-  Star' /* -/- 0036 right Shift */
   R.4 = 'Home Up     PgUp  Minus'     /* overlap  | 7 8 9 - 4 */
   R.5 = 'Left Center Right Plus'      /* numeric  | 4 5 6 + 1 */
   R.6 = 'End  Down   PgDn  Ins  Del'  /* keypad   | 1 2 3 0 . */
   do N = 5 to 1 by -1
      X = d2x( N + 25, 2 ) ;  X.X = 'alt' word( R.1, N )
      X = d2x( N + 38, 2 ) ;  X.X = 'alt' word( R.2, N )
      X = d2x( N + 53, 2 ) ;  X.X = 'alt' word( R.3, N )
      X = d2x( N + 70, 2 ) ;  X.X = '  ' || word( R.4, N )
      X = d2x( N + 74, 2 ) ;  X.X = '  ' || word( R.5, N )
      X = d2x( N + 78, 2 ) ;  X.X = '  ' || word( R.6, N )
      X = d2x( N +114, 2 ) ;  X.X = 'c-' || word( R.0, N )
      X = d2x( N +150, 2 ) ;  X.X = 'a-' || word( R.4, N )
      X = d2x( N +154, 2 ) ;  X.X = 'a-' || word( R.5, N )
      X = d2x( N +158, 2 ) ;  X.X = 'a-' || word( R.6, N )
   end N
   I.00 = X.00                /* c-@  0003 not mapped => no 00 */
   X.00 = 'HALT'              /* c-Break: see HALT in RX.CHAR  */
   X.01 = 'alt ESC'           /* DOS: 0001, OS/2: task switch  */
   X.03 = 'NUL (^@)'          /* WIN: 0002..000B see c-1..c-0  */
   X.07 = I.00                /* c-6  0007 mapped to 1E, RS ^^ */
   X.0D = 'ctrl =+'           /* ???: 000D, DOS and OS/2: n/a  */
   X.0E = 'alt BS'            /* c-_  000C mapped to 1F, US ^- */
   X.0F = 'shift TAB'         /* n/a: 0038 left Alt            */
   X.37 = 'a-Star'            /* n/a: 003A CapsLock            */
   X.39 = 'a-Space'           /* WIN: 0039, DOS and OS/2: n/a  */
   X.2A = I.00 ;  X.36 = I.00 /* n/a: 002A, 0036 L-, R-Shift   */
   X.4A = X.9A ;  X.9A = I.00 /* n/a: 009A, alt pad Minus 004A */
                  X.9C = I.00 /* n/a: 009C a-Center impossible */
   X.4E = X.9E ;  X.9E = I.00 /* n/a: 009E, alt pad Plus: 004E */
   X.72 = 'c-PrtSc'           /* Print Screen, once shift STAR */
   X.82 = 'alt -_ (scan 0C)'  /* hex. 0082..0083 on key 12..13 */
   X.83 = 'alt =+ (scan 0D)'  /* n/a: 0045..0046 Num-, S-Lock  */
   X.84 = 'c-PgUp'            /* hex. E00D   NumEnter -> 0D CR */
   X.A4 = 'a-Slash'           /* hex. E00A c-NumEnter -> 0A LF */
   X.A5 = 'a-Tab'             /* DOS: 00A5, OS/2: task switch  */
   X.A6 = 'a-NumEnter'        /* hex. 00A7..00FF undefined     */

   arg KEY OLD ;  call RX.CRLF 'press key twice to exit decoder'
   do until KEY = OLD                  /* WIN keys INCOMPLETE  */
      X = c2x( KEY ) ;  N = right( X, 2 ) ;  X = left( X, 4 )
      if length( KEY ) = 2 then call RX.ECHO '[' || X || ']' X.N
                           else call RX.ECHO '[' || X || ']' I.N
      call RX.ECHO left( '', 24 ) x2c( 0D )
      OLD = KEY   ;  KEY = RX.CHAR()
   end
   return RX.ECHO( left( '', 24 ) x2c( 0D ))

RX.HELP: procedure expose RX.          /* build a help command */
   parse arg LINE, X
   if RX.0WARP then CMD = "address CMD 'helpmsg"
               else CMD = "address COMMAND 'help"
   if X > ''   then return CMD X LINE || "'"
               else return CMD   LINE || "'"

RX.FILE: procedure expose RX.          /* history or constants */
   parse source . . FILE
   N = max( lastpos( '\', FILE ), lastpos( '/', FILE )) + 1
   parse var FILE FILE =(N) N          /* for LINUX, OS/2, DOS */
   return FILE || arg( 1 ) || N        /* rx\name ==> rx\0name */

RX.SAVE: procedure expose RX.          /* save or load history */
   FILE = RX.FILE( '0' )               /* rx\name ==> rx\0name */
   HEAD = '/*' centre( ' */ signal off novalue /* ', 72, '-' ) '*/'

   if RX.0 > 0 then do                 /* save history in file */
      call lineout FILE, HEAD    ;  call lineout FILE, ''
      do N = 1 to RX.0
         call lineout FILE, RX.N ;  drop RX.N
      end
      call RX.CRLF RX.0 'history lines saved >>' FILE
      call lineout FILE ;  RX.0 = 0    /* use "portable" close */
   end
   else do                             /* load command history */
      do while sign( lines( FILE ))
         N = RX.0 + 1 ; RX.N = linein( FILE )
         if RX.N > '' & RX.N <> HEAD then RX.0 = N
      end                              /* else empty or header */
      call lineout FILE                /* use "portable" close */
      call RX.CRLF RX.0 'history lines loaded <' FILE
   end
   return

RX.UTIL: procedure expose RX.          /* load RexxUtil stuff  */
   if \ RX.0WARP then return 0         /* 0 = not loaded (DOS) */
   parse version RX.0REXX I .          /* 1 = OS/2 or ooREXX ? */
   if trunc( I ) = 6 then  RX.0REXX = 'ooREXX'
   parse source I .                    /* OS/2: force REXXSAA  */
   if I = 'OS/2'     then  RX.0REXX = 'REXXSAA'

   /* ooREXX 6.03 does not support aliases, so use long names: */
   Y.1 = 'SysGetKey' ;  Y.2 = 'SysTextScreenSize'  /* RexxUtil */

   do I = 1 to 2
      if RxFuncQuery( Y.I ) = 0              then  iterate I
      if RxFuncAdd( Y.I, 'RexxUtil', Y.I )   then  return 0
   end I                               /* 0 = fatal, not found */
   return 1                            /* 1 = functions loaded */

RX.BEEP: procedure expose RX.          /* tty output ASCII BEL */
   return RX.ECHO( x2c( 07 ))          /* no beep() in DOSREXX */

RX.CURS: procedure expose RX.          /* toggle insert mode   */
   RX.. = 1 - RX..
   if RX.0REXX = 'ooREXX' & address() = 'CMD'   then  do
      'color' d2x( 112 + 128 * RX.. )  /* NT color to show INS */
      return (7 - 3 * RX..) 8          /* emulate 7 8 vs. 4 8  */
   end
   signal on syntax name RX.CHAW       /* optional CursorType  */
   parse value CursorType() with T B . /* assume max. bottom B */
   if RX.. then T = B % 2  ;  else T = B - 1
   return CursorType( T, B )           /* top T=1 doesn't work */

RX.CRLF: procedure expose RX.          /* lineout(x) on StdOut */
   return RX.ECHO( arg( 1 ) || RX.0CRLF )

RX.PLUS: procedure expose RX.          /* echo TTY-"printable" */
   return RX.ECHO( translate( arg( 1 ), RX.0PLOT, RX.0PLUS ))

RX.ECHO: procedure expose RX.          /* charout(x) on StdOut */
   return charout( /**/, arg( 1 ))

RX.CHAR: procedure expose RX.          /* charin( ) w/out echo */
   if sign( wordpos( trace( 'O' ), '?R ?I ?A ?L' ))
      then say '       +++ next input key' || x2c( 07 ) || ':'
   signal on syntax name RX.WARP       /* if RxGetKey unloaded */
   signal on halt   name RX.CHAW       /* interrupted RxGetKey */
   select
      when RX.0WARP                    then  do
         KEY = SysGetKey( 'NoEcho' )
         if c2d( KEY ) = 0 | c2d( KEY ) = 224
            then  KEY = x2c( 00 ) || SysGetKey( 'NoEcho' )
      end
      when RX.0REXX = 'REXXSAA'        then  do
         KEY =  RxGetKey( 'NoEcho' )
         if c2d( KEY ) = 0 | c2d( KEY ) = 224
            then  KEY = x2c( 00 ) ||  RxGetKey( 'NoEcho' )
      end
      when RX.0REXX = 'REXX/Personal'  then KEY = INKEY()
      otherwise   KEY = charin()       /* charin NOT supported */
   end
   return KEY
RX.CHAW: return x2c( 0000 )            /* HALT code 0000 Break */

RX.SIZE: procedure expose RX.          /* get text screen size */
   signal on syntax name RX.WARP       /* if RxScrSiz unloaded */
   select
      when RX.0WARP  then  return SysTextScreenSize()
      when RX.0REXX = 'REXXSAA'        then  return RxScrSiz()
      when RX.0REXX = 'REXX/Personal'  then  return SCRSIZE()
      otherwise                        return 24 80   /* dummy */
   end

/* ----------------------------------------------------------- */
/* RxShell info functions, yet only used by RX.INFO( 9 )       */

RX.PATH: procedure expose RX.          /* get/set a directory: */
   parse arg DIR
   if RX.0WARP | RX.0REXX <> 'REXXSAA' then do
      if arg() = 1   then return directory( DIR )
                     else return directory()
   end                           /* OS/2 or REXX/Personal okay */
   if arg() = 1 then do          /* assuming PC DOS 7 REXXSAA: */
      if right( DIR, 1 ) = ':' then DIR = DIR || '.'
      if RxChDir( DIR ) <> 0   then return ''
      call RxChDrv left( DIR, pos( ':', DIR ))
   end                           /* RxChDrv('') result ignored */
   return RxGetDrv() || RxGetDir()

RX.EVAL: procedure expose RX.          /* get/set environment: */
   ENV = 'ENVIRONMENT'
   select   /* PC DOS REXXSAA needs upper case DOSENVIRONMENT: */
      when RX.0REXX = 'ooREXX'         then  nop
      when RX.0REXX = 'REXX/Personal'  then  nop
      when RX.0WARP                    then  ENV = 'OS2' || ENV
      when RX.0REXX = 'REXXSAA'        then  ENV = 'DOS' || ENV
      otherwise                              nop   /* optimist */
   end
   if arg( 2, 'o' )  then return value( arg( 1 ),/* get */, ENV )
                     else return value( arg( 1 ), arg( 2 ), ENV )

RX.TRAV: procedure expose RX.          /* show TRAce Verbosely */
   arg TOP 2 VAL                       /* skip known prefixes  */
   if pos( TOP, '?!$+-' ) = 0 then arg VAL, TOP
   select
      when VAL = 'C'          then  return TOP || 'Commands'
      when VAL = 'A'          then  return TOP || 'All'
      when VAL = 'R'          then  return TOP || 'Results'
      when VAL = 'E'          then  return TOP || 'Errors'
      when VAL = 'O'          then  return TOP || 'Off'
      when VAL = 'F'          then  return TOP || 'Failure'
      when VAL = 'N'          then  return TOP || 'Normal'
      when VAL = 'I'          then  return TOP || 'Intermediates'
      when VAL = 'L'          then  return TOP || 'Labels'
      when TOP || VAL = 'ON'  then  return 'ON (?Results)'
      when TOP || VAL = 'OFF' then  return 'OFF (Normal)'
      when TOP || VAL = ''    then  return 'n/a (Normal)'
      otherwise                     return TOP || VAL
   end

RX.MORE: procedure expose RX.          /* output item counter: */
   parse arg ITEM, ROWS, COLS, TEXT ;  if ITEM = 0 then return 0
   call RX.PLUS TEXT                ;  ITEM = ITEM + 1
   select
      when ROWS =  1 then nop          /* no new line if 1 row */
      when COLS < 80 then call RX.CRLF /* new line 40..79 COLS */
      otherwise                        /* new line if odd item */
         if ITEM // 2 then call RX.CRLF
         ROWS = 2 * ROWS - 2           /* double limit 80 COLS */
   end
   select                              /* adjust 1 prompt line */
      when ROWS > 1 + ITEM                   then  return ITEM
      when ROWS = 2 & ITEM = 2 & 80 <= COLS  then  return ITEM
      otherwise   ITEM = 'press ESCape or any key to continue...'
   end
   select                              /* separate prompt line */
      when ROWS > 1                    then TEXT = ''
      when COLS < length( TEXT ITEM )  then ITEM = x2c(7)
      when COLS < length( TEXT ) + 40  then ITEM = ' ' || ITEM
      otherwise ITEM = left( '', COLS - 40 - length( TEXT )) ITEM
   end
   TEXT = ITEM || TEXT
   TEXT = copies( x2c(8) x2c(8), length( TEXT )) x2c( 0D )
   call RX.ECHO ITEM ;  ITEM = RX.CHAR() <> x2c( 1B )
   call RX.ECHO TEXT ;  return ITEM    /* 1: new page, 0: ESC  */

RX.INFO: procedure expose (EXPO) RX.   /* show RxShell info    */
   call RX.KILL 1 ;  call RX.CRLF
   parse value RX.SIZE() with ROWS COLS
   select
      when arg( 1 ) = 1 then do        /* F1: general help     */
         I.1  = 'F1         RxShell help (this text)    '
         I.3  = 'F2         quote (last) input line     '
         I.5  = 'F3         exit                        '
         I.7  = 'F4         save or load history file   '
         I.9  = 'F5         -/-                         '
/* >> nomath */
         I.9  = 'F5         list of RxShell functions   '
/* << nomath */
         I.11 = 'F6         input key mapping           '
         I.2  = 'F7         -/-                         '
         I.4  = 'F8         -/-                         '
         I.6  = 'F9         show REXX environment info  '
         I.8  = 'F10        clear history (free memory) '
         I.10 = 'F11        -/-                         '
         I.12 = 'F12        input key decoder tests     '
         I.13 = '<- arrow   move cursor left            '
         I.14 = 'Ctrl <-    move to prev. word          '
         I.15 = '-> arrow   move cursor right           '
         I.16 = 'Ctrl ->    move to next  word          '
         I.17 = 'END        last  character             '
         I.18 = 'Ctrl END   clear to last  char         '
         I.19 = 'HOME       first character             '
         I.20 = 'Ctrl HOME  clear to first char         '
         I.21 = 'TAB        complete line with history  '
         I.22 = 'BackSpace  clear prev. char            '
         I.23 = 'up   arrow show prev. line in history  '
         I.24 = 'DEL        clear next  char            '
         I.25 = 'down arrow show next  line in history  '
         I.26 = 'ESC        clear complete line         '
         I.27 = 'INS        toggle insert mode          '
         I.28 = 'Alt-F4     exit                        '
      end
      when arg( 1 ) = 5 then do        /* F5: math. functions  */
/* >> nomath */
         I.1   = 'ARC(  x )      rad <-> degree.min.sec'
         I.2   = 'complex ARG:   see ATAN and also NORM'
         I.3   = 'ASIN( x )      arcsin, if abs(x) <= 1' /* ----- */
         I.4   = 'ARSH( x )      Area SH, x=ArSH(SH(x))' /* here  */
         I.5   = 'ACOS( x )      arccos: pi/2 - ASIN(x)' /* avoid */
         I.6   = 'AREA( x )      1<=x: ArCH, -1<x: ArTH' /* alpha */
         I.7   = 'ATAN( x )      arctan, pi/2 = ACOS(0)' /* order */
         I.8   = 'ATAN( x, y )   polar angle re x, im y' /* ----- */
         I.9   = "DF(  f, x )    diff. f'(X) = df(X)/dX"
         I.10  = 'ERF( x )       int. error, x *ROOT(2)'
         I.11  = 'GCD( x, y )    greatest common divisor'
         I.12  = 'INT( f, a, b ) int. f(X) dX, X=a to b'
         I.13  = 'LN(  x )       log hyp, x=LN(EXP(x))'  /* ----- */
         I.14  = 'EXP( x )       e ** x with e = EXP(1)' /* here  */
         I.15  = 'LOG( x, y )    log: LN( x ) / LN( y )' /* avoid */
         I.16  = 'GAMMA( x )     whole x only for x > 0' /* alpha */
         I.17  = 'LOG( x )       binary log LN(x)/LN(2)' /* order */
         I.18  = '!( x )         GAMMA( x+1 ) if 0 <= x' /* ----- */
         I.19  = 'LI(  x )       log int. if 0 < x <> 1'
         I.20  = 'OVER(  x, n )  binomial x over 0 <= n'
         I.21  = 'SIN( x )       sine:  COS( x - pi/2 )' /* ----- */
         I.22  = 'SH( x )        sinh: (e**x - e**-x)/2' /* here  */
         I.23  = 'COS( x )       cosine'                 /* avoid */
         I.24  = 'CH( x )        cosh: (e**x + e**-x)/2' /* alpha */
         I.25  = 'TAN( x )       tangens: SIN(x)/COS(x)' /* order */
         I.26  = 'TH( x )        tan hyp: SH(x) / CH(x)' /* ----- */
         I.27  = 'ROOT( x, y )   x ** (1/y), for 0 <= x'
         I.28  = 'NORM( x, y )   abs( re x, im y ) ** 2'
         I.29  = 'ROOT( x )      square root x ** (1/2)'
         I.30  = 'NORM( x )      abs(x) = ROOT(NORM(x))'
         if digits() > RX.0GAMMA /* discourage GAMMA(x) dead loop */
            then I.16 = 'GAMMA( x )     only for whole 2*x > 0'
            else I.18 = 'GAMMA( x, y )  beta: G(x)*G(y)/G(x+y)'
         I.31  = 'INV( f,y,a )   invert f(X)=y, tangent'
         I.32  = 'SUM(  f )      sum of f(X), X=1..0/0'
         I.33  = 'INV( f,y,a,b ) invert f(X)=y, secant'
         I.34  = 'ZETA( x )      use only whole  x <> 1'
         I.35  = 'f( X ) example: "X -" VAR "* ROOT(X)"'
         I.36  = "trace 'F'      watch f( X ) iteration"
/* >> option */
         do I = 36 to 31 by -1
            L = I + 4   ;  I.L = I.I
         end I                   /* 4 lines (optional) equations: */
         I.31  = 'ROOT( a,b,c )  min.|s|: (a*s+b)*s+c=0'
         I.32  = 'ROOT( a,b,c,d ) s: ((a*s+b)*s+c)*s+d=0'
         I.33  = 'NORM( a,b,c )  max.|s|: (a*s+b)*s+c=0'
         I.34  = 'NORM( a,b,c,d ) solution s2,s3 if real'
/* << option */
/* << nomath */
      end
      when arg( 1 ) = 6 then do        /* F6: key mapping 00?? */
         I.1   = 'alt-A      mapped to d2c(224' d2c(224) /* 1E */
         I.2   = 'Ctrl G     unchanged BEL (^G' x2c(07)
         I.3   = 'alt-C      mapped to ETX (^C' x2c(03)  /* 2E */
         I.4   = 'alt-G      mapped to BEL (^G' x2c(07)  /* 22 */
         I.5   = 'alt-BS     mapped to BS  (^H' x2c(08)  /* 0E */
         I.6   = 'shift-TAB  mapped to TAB (^I' x2c(09)  /* 0F */
         I.7   = 'alt-H      mapped to BS  (^H' x2c(08)  /* 23 */
         I.8   = 'alt-I      mapped to TAB (^I' x2c(09)  /* 17 */
         I.9   = 'Ctrl CR    unchanged LF  (^J' x2c(0A)
         I.10  = 'alt-CR     mapped to CR  (^M' x2c(0D)  /* 1C */
         I.11  = 'alt-J      mapped to LF  (^J' x2c(0A)  /* 24 */
         I.12  = 'alt-M      mapped to CR  (^M' x2c(0D)  /* 32 */
         I.13  = 'alt-P      mapped to DLE (^P' x2c(10)  /* 19 */
         I.14  = 'alt-Q      mapped to DC1 (^Q' x2c(11)  /* 10 */
         I.15  = 'alt-S      mapped to DC3 (^S' x2c(13)  /* 1F */
         I.16  = 'alt-ESC    mapped to ESC (^[' x2c(1B)  /* 01 */
         I.17  = 'alt-STAR   mapped to ESC (^[' x2c(1B)  /* 37 */
         I.18  = 'alt-[{ US  mapped to ESC (^[' x2c(1B)  /* 1A */
         I.19  = 'Ctrl @2    mapped to NUL (^@' x2c(00)  /* 03 */
         I.20  = 'Use F12 to start key decoder tests...'
         do I = 1 to 19
            I.I = insert( '), echo', I.I, 28 )
         end I
      end
      when arg( 1 ) = 9 then do        /* F9: RxShell state    */
         parse source I.1              /* long line = 2 items: */
         I.1   = 'source :' I.1 '(' || sourceline() 'lines)'
         I.2   = substr( I.1, 40 )     ;  parse version I.3
         I.3   = 'version:' I.3
         I.4   = 'address:' address()
         L     = condition() condition( 's' ) condition( 'c' )
         I.5   = 'status :' L
         if L  = ''  then L = '(no signal condition status)'
                     else L = RX.0INFO /* RX.0INFO by RX.TRAP  */
         if L  = ''  then L = '(no' condition( 'c' ) 'description)'
         I.6   = 'verbose:' L
         I.7   = 'numeric: digits' digits()
         I.8   = 'numeric: fuzz' fuzz() 'form' form()
         I.9   = 'trace  :' RX.TRAV( RX.0TEST ) '(user)'
         I.10  = 'trace():' RX.TRAV( trace()) '(shell)'
         I.12  = 'RXTRACE:' RX.TRAV( RX.EVAL( 'RXTRACE' ))
         I.11  = 'CWD    :' RX.PATH()  /* may overwrite RXTRACE:  */
         if 40 <= length( I.11 ) then  I.12 = substr( I.11, 40 )
         I.13  = 'queued :' queued() 'lines'
         if RX.0WARP
            then I.13 = I.13 '(' || RxQueue( 'Get' ) || ')'
         else if RX.0REXX  = 'REXX/Personal'
            then I.13 = I.13 '(' || stackstatus(   ) || ')'
         if RX.0REXX = 'REXXSAA' | RX.0WARP
            then I.14 = 'date   :' date( 'W' ) || ',' date( 'L' )
            else I.14 = 'date   :' date( 'W' ) || ',' date()
         I.15  = 'history:' RX.0 'lines'
         I.16  = 'time   :' time()
         I.17  = 'result :' RX.0USER   ;  I.18 = substr( I.17, 40 )
         if I.18 = '' then do
            I.18 = COLS 'x' ROWS || ', insert:'
            if RX.. then I.18 = I.18 'ON' ;  else I.18 = I.18 'OFF'
            I.18 = 'screen :' I.18
         end
      end
   end   /* otherwise REXX error 7: WHEN or OTHERWISE expected */
   N = 1
   do I = 1 while symbol( "I.I" ) = 'VAR'
      N = RX.MORE( N, ROWS, COLS, left( I.I, 40 - 1 ))
   end I
   if I // 2 = 0 then call RX.CRLF  ;  return RX.KILL( 0 )

/* >> nomath */
/* ----------------------------------------------------------- */
/* RxShell arithmetical functions (almost arbitrary precision) */

/* Derived functions which could be easily added when needed:  */
/* abs(x,y) = hypot(x,y) = ROOT(x*x + y*y) = ROOT( NORM(x,y) ) */
/* arg(x,y) =  ATAN(x,y), "overloading" REXX arg() or abs()    */
/*  im(x,y) = x * SIN(y), complex polar coordinates x versor y */
/*  re(x,y) = x * COS(y) for angle y = ATAN( re(x,y),im(x,y) ) */

/* (arc)cot: cot(x) = COS(x) / SIN(x), arccot(x) = ATAN( 1/x ) */
/* (Ar)cot hyp.: coth(x) = 1 /  TH(x), Arcoth(x) = AREA( 1/x ) */
/* (co)sec hyp.: sech(x) = 1 /  CH(x),   csch(x) = 1 /  SH(x)  */
/* (co)secans:    sec(x) = 1 / COS(x),  cosec(x) = 1 / SIN(x)  */
/* arc(co)sec: arcsec(x) = ACOS( 1/x), arccsc(x) = ASIN( 1/x ) */
/* Ar(co)sech: arsech(x) = AREA( 1/x), Arcsch(x) = ARSH( 1/x ) */
/* exp. int.:  Ei(x) = LI( EXP( x )) ,  log10(x) = LOG( x,10 ) */
/* Gauss phi: phi(x) = ERF(x/ROOT(2)) aka probability integral */
/* power:   pow(x,y) = EXP( LN(x)*y ), or x**y, ROOT(x,1/y)    */

/* T(x,n) = 2**-n * ((x+ROOT(x*x-1))**n + (x-ROOT(x*x-1))**n), */
/* T(x,n) = 2**-n*2*COS(n*ACOS(x)), whole n>0: Cebysev-polynom */

/* The implemented DF(f,x) approximation of f'(x) is slow and  */
/* unreliable.  Whenever possible determine f'(x) directly:    */
/* arctan'( x ) = 1 / ( 1 + x*x ),  arccot'(x) = -arctan'(x)   */
/* Artanh'( x ) = 1 / ( 1 - x*x ),  Arcoth'(x) = +Artanh'(x)   */
/* arcsin'( x ) = 1 / ROOT( 1-x*x), arccos'(x) = -arcsin'(x)   */
/* Arsinh'( x ) = 1 / ROOT( 1+x*x), Arsech'(x) =  arccos'(x)/x */
/* Arcosh'( x ) = 1 / ROOT( x*x-1), arcsec'(x) =  Arcosh'(x)/x */
/* Arcsch'( x ) = - Arsinh'(x) / x, arccsc'(x) = -arcsec'(x)   */
/*  erf'(x) = EXP(-x*x  ) / ROOT(pi/4), Ei'(x) = EXP(x) / x    */
/*  phi'(x) = EXP(-x*x/2) / ROOT(pi/2), Li'(x) =   1 / LN(x)   */
/*  sin'(x) = +COS(x), sh'(x) = CH(x), tan'(x) = 1 +TAN(x)**2  */
/*  cos'(x) = -SIN(x), ch'(x) = SH(x),  th'(x) = 1 - TH(x)**2  */
/*  cot'(x) =      -1 / (SIN(x)**2),  coth'(x) = -1/(SH(x)**2) */
/*  csc'(x) = -COS(x) / (SIN(x)**2),   sec'(x) = TAN(x)/COS(x) */
/* csch'(x) = - CH(x) / ( SH(x)**2),  sech'(x) = -TH(x)/ CH(x) */

/* generally: f'(x) = s'(x) * g'( s(x) ) for f(x) =  g( s(x)), */
/* logarithm: f'(x) = s'(x) / s(x)       for f(x) = LN( s(x)), */
/* parameter: f'(x) = s'(t) / c'(t) for x = c(t) and y = s(t), */
/*   inverse: f'(x) =     1 / F'(x) for x = F(f(x)), y = f(x), */
/* a=0 polar: f'(x) = r'(0) / r(0)  for x = r(0) and y = 0,    */
/*     polar: f'(x) = (r(a)+tan(a)*r'(a))/(r'(a)-tan(a)*r(a)), */
/*     angle 0 < a < 2*pi, x = cos(a)*r(a) and y = sin(a)*r(a) */

RX.MATH: procedure expose RX.          /* misc. math. function */
   arg L ;  if abs( L // 2 ) then return (L = 1) / 2
   N = 0 ;  F = L - 1   ;  L = L % 2   /* L = 1: 0.5, odd L: 0 */

   if symbol( 'RX.0B.L' ) = 'VAR' then return RX.0B.L
   signal on syntax name RX.TRAP ;  signal on novalue name RX.TRAP
   numeric digits RX.DIGS( +2 )  ;  numeric fuzz 0
   TEST = RX.TRAF( 1 ) = 0 | right( RX.0TEST, 1 ) = 'F'

   if L > 0 then do K = 1 to L   /* ----- new Bernoulli number */
      if symbol( 'RX.0B.' || K ) = 'VAR' then iterate K
      RX.0B.K = ( 1 - 2 * K ) / 2   ;  F = 1
      do N = 1 to K - 1
         F = F * ( 2 * K + 3 - 2 * N ) / ( 1 - 2 * N )
         F = F * ( 2 * K + 2 - 2 * N ) / (   - 2 * N )
         RX.0B.K = RX.0B.K + RX.0B.N * F
      end N
      RX.0B.K = - RX.0B.K / ( 2 * K + 1 )
   end K
   else if L < 0 then do         /* ---- almost infinite loop: */
      do K = 1 until RX.0B.L = N /* ZETA( 1 - 2 * L ) stored   */
         RX.0B.L = N ;  N = N + K ** F
      end K                      /* feature: HALT truncates it */
      if TEST then do
         call RX.CRLF '[TEST] zeta(' 1 - 2 * L ') terms:' K
         call trace RX.TRAF( 0 )
      end
   end
   else do                       /* ----- new constants if L=0 */
      do K = 1 until F                 /* drop (most) RX.0B.?: */
         F = ( symbol( 'RX.0B.K' ) <> 'VAR' )   ;  N = - K
         F = ( symbol( 'RX.0B.N' ) <> 'VAR' ) & F
         drop RX.0B.K RX.0B.N          /* recomputed when used */
      end K

      I = RX.FILE( '-' )               /* rx\name ==> rx\-name */
      do while sign( lines( I ))
         H = linein( I )
         if abbrev( H, 'math.' ) = 0   then  iterate
         parse var H 'math.' K ' = ' H    ;  H = H / 1
         select
            when K = 'PI.1'   then  RX.0PI.1 = H
            when K = 'PI.0'   then  RX.0PI.0 = H
            when K = 'LN.0'   then  RX.0LN.0 = H
            when K = 'LN.1'   then  RX.0LN.1 = H
            when K = 'LN.2'   then  RX.0LN.2 = H
            when K = 'GAMM'   then  RX.0B.0  = H
            otherwise               RX.0ZETA = K + 1
               K = ( 1 - K ) / 2 ;  RX.0B.K  = H
         end
         if H = 1 then leave
      end
      call lineout I

      RX.0GAMMA = 1003        ;  if H <> 1 then RX.0ZETA = 0
      if digits() > RX.0GAMMA then do  /* compute "constants": */
         F = ATAN( 1 )        ;  RX.0ZETA = 1.5 * digits()
         RX.0LN.1 = EXP( 1 )  ;  RX.0PI.0 = ROOT( F ) ;  F = F + F
         RX.0LN.2 = LN(  2 )  ;  RX.0PI.1 = F + F  ;  RX.0PI.2 = F
         RX.0LN.0 = LN(  F ) + 2 * RX.0LN.2
      end                              /* RX.0LN.0 is LN(2*pi) */
      else do
         RX.0PI.2 = RX.0PI.1 / 2       /* pi / 2 and pi check  */
         F = RX.0PI.0 + RX.0LN.0       /* dummy NOVALUE check  */

         if RX.0ZETA = 0 | TEST then do
            F = 1 ;  N = 0 ;  I = 0    /* Euler's C0 aka GAMMA */
            do I = 3 by 2 until K = 1  /* sum over odd I > 1   */
               K = RX.MATH( 1 - I ) ;  F = F / 4
               N = N + K * F / I       /* sum ZETA(I)*(2**-I)  */
            end I                      /* C0 = LN(2) - odd sum */
            RX.0ZETA = I + 1  ;  K = digits() - 2

            I = format( RX.0B.0, , K ) /* using C0 as checksum */
            I = format( RX.0LN.2 - N, , K ) -I
            I = format( abs( I ) , , , 4, 0 )
            if I <> 0 then exit RX.TRAP( '[TEST] GAMMA error' I )
         end
      end
   end
   numeric digits RX.DIGS( -2 )
   if L <> 0 | \ TEST then return RX.0B.L

   numeric digits RX.DIGS( +1 )  ;  D = digits() + 1
   N = 1 ;  parse value RX.SIZE() with ROWS COLS
   I = '[TEST] inv(F(X))  N X=10**-N | 1-10**-N'
   if N // 2 & 80 <= COLS then I = left( I, 40 )
   N = RX.MORE( N, ROWS, COLS, I )
   I = '[TEST] 1 + accuracy I(F) F(I) I(F) F(I)'
   if N // 2 & 80 <= COLS then I = left( I, 40 )
   N = RX.MORE( N, ROWS, COLS, I )
   do K = 6 to D - 3 by D - 9          /* 6 and user's digits: */
      F = 10 ** -K
      FUNC = 'abs( ROOT( X ** 2 ) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( ROOT( X ) ** 2 - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      if I J = '' then parse value 'all void: accurate' with I J
      I = '[TEST] sq. root' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( LOG( ROOT( 2, 1 / X )) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( ROOT( 2, 1 / LOG( X )) - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      I = '[TEST] log,2**x' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( ROOT( X **' D ',' D ') - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( ROOT( X,' D ') **' D ' - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      R = left( D || '.', 3 )
      I = '[TEST]' R 'root' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( LN( EXP( X )) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( EXP( LN( X )) - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      I = '[TEST] ln , exp' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( SIN( ASIN( X )) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( ASIN( SIN( X )) - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      I = '[TEST] sin,asin' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( SH( ARSH( X )) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( ARSH( SH( X )) - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      I = '[TEST] sh, arsh' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( TAN( ATAN( X )) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( ATAN( TAN( X )) - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      I = '[TEST] tan,atan' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( TH( AREA( X )) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( AREA( TH( X )) - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      I = '[TEST] th, area' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( COS( ACOS( X )) - X )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J =   right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      FUNC = 'abs( ACOS( COS( X )) - X )'
      I = I right( format( RX.FUNC( F )  , , , 4, 0 ), 4 )
      J = J right( format( RX.FUNC( 1-F ), , , 4, 0 ), 4 )
      I = '[TEST] cos,acos' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
      FUNC = 'abs( CH( AREA( 1/X )) * X - 1 )'
      I =   right( format( RX.FUNC( F )  , , , 4, 0 ), 4 ) '1+X:'
      FUNC = 'abs( CH( AREA( X )) - X )'
      J =   right( format( RX.FUNC( 1+F ), , , 4, 0 ), 4 )
      FUNC = 'abs( AREA( CH( X )) - X )'
      J = J right( format( RX.FUNC( 1+F ), , , 4, 0 ), 4 )
      I = '[TEST] ch, area' || right( K, 4 ) I J
      if N // 2 & 80 <= COLS then I = left( I, 40 )
      N = RX.MORE( N, ROWS, COLS, I )  ;  if N = 0 then leave K
   end K
   return RX.DIGS( -1, RX.0B.0 )

RX.TRAF: procedure expose RX.    ;  F = trace( 'O' )
   if arg( 1 ) then return ( 'F' <> right( F, 1 ))
   if \ abbrev( F, '?' ) then return F /* no interactive trace */
   F = translate( RX.CHAR())     ;  rc = 4
   if F = x2c(0000) then call RX.FUNK  /* check trace request: */
   if F = x2c( 1B ) then F = '?'       /* 'F' nop / '?' toggle */
   if verify( F, 'CAREOFNIL?' ) then F = 'F' ;  return F

RX.DIGS: procedure expose RX.    ;  call trace 'O' ;  arg X, Y
   signal on syntax name RX.TRAP ;  signal on novalue name RX.TRAP
   select
      when arg() = 0 then do           /* initialize RX.MATH   */
         RX.0MATH = 0   ;  drop RX.0B.0   ;  return RX.MATH( 0 )
      end
      when arg() > 1 & X > 0 then do   /* clumsy ROOT rounding */
         numeric digits RX.DIGS( -X )  ;  Y = Y / ( 2 = arg())
         numeric digits RX.DIGS( +X )  ;  return Y
      end
      when arg() > 1 then do           /* normal exit rounding */
         if X < 0 then numeric digits RX.DIGS( X )
         select
            when datatype( Y, 'n' ) then Y = Y / 1
            when Y = '0/0' | Y = .  then nop
            when abbrev( Y, 'E' )   then do
               rc = substr( Y, 2 )  ;  X = ''
               if rc = 'RC' then do    /* else obsolete info   */
                  X = condition( 'c' ) || ':' condition( 'd' ) ''
                  if X = ':  ' | X = 'SYNTAX:  '      then X = ''
               end
               select                  /* 'RC': NOVALUE / HALT */
                  when rc = 'RC' then  nop
                  when rc =  -3  then  X = '0/0 not supported'
                  when rc =  -2  then  X = 'not yet implemented'
                  when rc =  -1  then  X = 'complex result'
                  otherwise            X = X || errortext( rc )
               end
               X = '[' || left( arg(3), 4 ) || ']' X  ;  Y = .
               call RX.CRLF x2c( 0D ) || X
            end
            when arg(3) = 'FUNC'    then do
               X = errortext( 41 ) || ':' Y           ;  Y = .
               call RX.CRLF x2c( 0D ) || '[FUNC]' X
            end                        /* FUNC(): Not A Number */
         /* otherwise REXX error 7: WHEN or OTHERWISE expected */
         end
         return Y
      end
      when X =  1 & 0 = RX.0MATH then do
         RX.0MATH = 1;  RX.0FUNC = 0   ;  return RX.0DIGS + 2
      end                              /* use fuzzy  precision */
      when X =  1                then  RX.0MATH = RX.0MATH + 1
      when X =  2 & 0 = RX.0MATH then do
         RX.0MATH = 8;  RX.0FUNC = 0   ;  return RX.0DIGS * 2 +1
      end                              /* use double precision */
      when X =  2 & 8 > RX.0MATH then do
         RX.0MATH = 8 * RX.0MATH       ;  return RX.0DIGS * 2 +1
      end                              /* note fuzzy -> double */
      when X =  2                then  RX.0MATH = RX.0MATH * 8
      when X = -1 & 1 < RX.0MATH then  RX.0MATH = RX.0MATH - 1
      when X = -2 & 8 < RX.0MATH then  RX.0MATH = RX.0MATH % 8
      otherwise         RX.0MATH = 0   ;  return RX.0DIGS
   end                                 /* reset user precision */
   return digits()                     /* unmodified precision */

RX.FUNC: procedure expose RX. FUNC     /* user formula FUNC(X) */
   if RX.0FUNC then return .           /* catch RX.0FUNC <<=== */
   signal on syntax name RX.FUNK ;  signal on novalue name RX.FUNK

   arg X ;  numeric fuzz 0       ;  interpret 'X =' FUNC
   if X = '0/0' then X = 'E-3'   ;  return RX.DIGS( 0, X, 'FUNC' )
RX.FUNK: RX.0FUNC = 1                  /* <<=== throw RX.0FUNC */
   return RX.DIGS( 0, 'E' || value( 'RC' ), 'FUNC' )

   /* 0/0 - 0/0 undefined: DF(), INT(), INV(), and SUM() fail, */
   /* 0/0 is handled here, RX.FUNC returns a number or dummy . */

RX.ARGN:          /* check standard errors like "Not A Number" */
   select         /* caller may use '0/0' instead of any 'E-3' */
      when arg(1) <> 1              then  return 'E40'
      when arg(2) = '0/0'           then  return 'E-3'
      when arg(2) = .               then  return .
      when datatype( arg(2), 'n' )  then  return arg( 2 )
      otherwise                           return 'E40'
   end

ACOS:    procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when \ datatype( X, 'n' )  then  Y = X
      when abs( X ) > 1          then  Y = 'E-1'
      otherwise                        Y = RX.0PI.2 - ASIN( X )
   end                                 /* X: -1,   0     ,  1  */
   return RX.DIGS( -1, Y, 'ACOS' )     /* Y: pi,   pi/2  ,  0  */

ARC:     procedure expose RX.    ;  arg X, Y, Z
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   if arg() = 1 then do                /* split degree.mm.ss   */
      arg X '.' Y '.' Z                /* but xx.yy is radiant */
      if Z = '' then arg X Y Z         /* blank delimiter okay */
   end                                 /* point delimiter okay */
   select                              /* but xx.yy zz dubious */
      when arg() > 3 | arg() = 0             then  Y = 'E40'
      when X = . | Y = . | Z = .             then  Y = .
      when              \ datatype( X, 'n' ) then  Y = 'E41'
      when ( Z > '' ) >   datatype( Z. 'n' ) then  Y = 'E41'
      when ( Y > '' ) >   datatype( Y. 'n' ) then  Y = 'E41'
      when Y > '' & Z = '' then  Y = RX.0PI.1 * (X + Y/60) / 180
      when Y > '' then  Y = RX.0PI.1 * (Z/3600 + X + Y/60) / 180
      otherwise                        /* rad -> degree.mm.ss  */
         X = (( 180 / RX.0PI.1 ) * X ) // 360
         numeric digits RX.DIGS( -1 )  /* result is no number  */
         Y = abs( 60 * ( X // 1 ))  ;  Z = 60 * ( Y // 1 )
         Z = format( Z,, 0 )        ;  Y = Y + Z % 60
         X = X + Y % 60*(1-2*(X<0)) ;  Y = right(( Y//60 ) %1, 2, 0)
         return X %1 || '.' || Y || '.' || right(( Z//60 ) %1, 2, 0)
   end   /* -360.00.00 < x.y.z < +360.00.00 depending on input */
   return RX.DIGS( -1, Y, 'ARC' )

AREA:    procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when \ datatype( X, 'n' )  then  Y = X
      when X < -1 then  Y = 'E-1'      /* complex result error */
      when X = -1 then  Y = '0/0'      /* X < +1: area tan hyp */
      when X < +1 then  Y = LN(( 1 + X ) / ( 1 - X )) / 2
      otherwise         Y = LN( X + ROOT( X ** 2 -1 ))
   end                                 /* 1 <= X: area cos hyp */
   return RX.DIGS( -1, Y, 'AREA' )

ARSH:    procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select                              /* sign(0/0) undefined  */
      when X = 'E-3'             then  Y = '0/0'
      when \ datatype( X, 'n' )  then  Y = X
      otherwise   Y = LN( X + ROOT( X ** 2 +1 ))
   end
   return RX.DIGS( -1, Y, 'ARSH' )

ASIN:    procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when \ datatype( X, 'n' )  then  Y = X
      when abs( X ) > 1 then Y = 'E-1' /* complex result error */
      when abs( X ) = 1 then Y = sign( X ) * RX.0PI.2
      otherwise              Y = ATAN( X / ROOT( 1 - X ** 2 ))
   end                                 /* ATAN is good enough, */
   return RX.DIGS( -1, Y, 'ASIN' )     /* ASIN( +-1 ) = +-pi/2 */

ATAN:    procedure expose RX.    ;  X = RX.ARGN( arg()>0, arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select                              /* ATAN(0/0) undefined  */
      when \ datatype( X, 'n' )  then  Y = X
      when arg() > 2 then  Y = 'E40'
      when arg() = 2 then do           /* polar angle X + i*Y: */
         Y = RX.ARGN( 1, arg( 2 ))     /* X = Y = 0 => dummy 0 */
         if datatype( Y, 'n' ) then select
            when X = 0  then Y = RX.0PI.2 * sign( Y )
            when X > 0  then Y = ATAN( Y/X )
            when Y > 0  then Y = ATAN( Y/X ) + RX.0PI.1
            when Y < 0  then Y = ATAN( Y/X ) - RX.0PI.1
            otherwise Y = RX.0PI.1     /* X > 0 => ATAN( Y/X ) */
         end                           /* Y > 0 => result > 0  */
      end                              /* Y < 0 => result < 0  */
      when X = 1  then Y = 5 * ATAN( 1/7 ) + 2 * ATAN( 3/79 )
      when X < 0  then Y = -ATAN( -X ) /* avoid slow ATAN sum: */
      when X > 2  then Y = -ATAN( 1/X ) + RX.0PI.2
      when X > 1  then Y = -ATAN( (X+1) / (X-1) ) +3/2 * RX.0PI.2
      when X > .5 then Y = +ATAN( (1+X) / (1-X) ) -1/2 * RX.0PI.2
      otherwise                        /* quick 0 <= X <= 0.5: */
         Q = -X * X  ;  Y = 0          /* => alternating signs */
         do N = 1 by 2 until R = Y     /* odd N sum T = X ** N */
            R = Y    ;  Y = Y + X / N  ;  X = X * Q
         end N
   end
   return RX.DIGS( -1, Y, 'ATAN' )

   /* ATAN(x,y) corresponds to arg(x,y) instead of atan2(x,y). */

CH:      procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   if datatype( X, 'n' ) then do ;  Y = EXP( X )
      if Y = 0 | Y = '0/0' then Y = '0/0'
                           else Y = ( Y + EXP( -X )) / 2
   end                                 /* CH(x) unlike SH(x)   */
   else  Y = X                         /* always uses EXP(x)   */
   return RX.DIGS( -1, Y, 'CH' )

COS:     procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when \ datatype( X,'n') then Y = X
      when X < 0              then Y =  COS(-X )
      when X > RX.0PI.1 * 2   then Y =  COS( X // ( RX.0PI.1 * 2 ))
      when X > RX.0PI.1       then Y = -COS( X -RX.0PI.1 )
      when X > RX.0PI.2       then Y = -COS( RX.0PI.1 -X )
      when X > RX.0PI.2 / 2   then Y =  SIN( RX.0PI.2 -X )
      otherwise                        /* else 0 <= X <= pi/4: */
         Q = -X * X  ;  Y = 1 ;  X = 1 /* => alternating signs */
         do N = 2 by 2 until R = Y     /* term T = X ** N / N! */
            R = Y ;  X = X * ( Q / N ) / ( N - 1 ) ;  Y = Y + X
         end N
   end
   return RX.DIGS( -1, Y, 'COS' )

DF:      procedure expose RX.    ;  X = RX.ARGN( arg()=2, arg(2))
   numeric digits RX.DIGS( +2 )  ;  signal on syntax name RX.TRAP
   call on halt name RX.FUNK     ;  FUNC = arg( 1 )
   FUZZ = digits() % 2 - 1       ;  DIFF = 4

   if datatype( X, 'n' ) then Y = RX.FUNC( X )  ;  else Y = X
   if datatype( Y, 'n' ) then do       /* using magnitude of X */
      DX = abs( X + (X=0)) / (5**FUZZ) /* smaller can be fatal */
      do L = 1 to DIFF
         F.L = RX.FUNC( X + L * DX )   ;  if F.L = . then leave L
         E.L = RX.FUNC( X - L * DX )   ;  if E.L = . then leave L
      end L                            /* RX.FUNC traps error: */
      if L <= 3 then Y = .             /* RX.FUNC error => dot */
   end
   if datatype( Y, 'n' ) then do
      C.0 = GAMMA( 2 * DIFF ) ;  C.1 = 6944  ;  C.3 = 48
      P = 0 ;  M = 0          ;  C.2 = 1022  ;  C.4 = 1
      do L = DIFF to 1 by -1
         Y = F.L * C.L  ;  if L // 2 then P = P+Y  ;  else M = M+Y
         Y = E.L * C.L  ;  if L // 2 then M = M+Y  ;  else P = P+Y
      end L
      S.0 = ( P-M ) / ( DX * 2 * C.0 ) /* S.0: 7th differences */
      C.0 = GAMMA( 4 * DIFF ) ;  C.3 = 12555034128 ;  C.6 = 35370
      C.1 = 1801840451840     ;  C.4 = 289774030   ;  C.7 = 224
      C.2 = 265345802722      ;  C.5 = 3945200     ;  C.8 = 1

      do K = 1 until Y = S.0 | F.1 == E.1
         numeric fuzz 0 ;  DX = DX / 2 ;  T.K = 0  ;  Y = .
         do L = DIFF to 1 by -1        /* 2 * DIFF old points: */
            P = L + L   ;  F.P = F.L   ;  E.P = E.L
            P = P - 1   ;  E = P * DX  /* only odd points new: */
            F.P = RX.FUNC( X + E )  ;  if F.P = . then leave K
            E.P = RX.FUNC( X - E )  ;  if E.P = . then leave K
         end L
         P = 0 ;  M = 0                /* P = sum of '+' terms */
         do L = 2 * DIFF to 1 by -1    /* M = sum of '-' terms */
            Y = F.L*C.L ;  if L // 2 then P = P+Y  ;  else M = M+Y
            Y = E.L*C.L ;  if L // 2 then M = M+Y  ;  else P = P+Y
         end L                         /* use 15th differences */
         Q = 1 ;  Y = S.0  ;  S.K = ( P - M ) / ( DX * 2 * C.0 )
         do L = K to 1 by -1           /* DX**2 extrapolation: */
            Q = Q * 4   ;  P = L - 1   ;  T.P = S.P   ;  E = Q
            if S.L <> T.L then E = Q * ( S.P - T.L ) / ( S.L - T.L )
            S.P = S.L + ( S.L - S.P ) / ( E - 1 )
         end L                         /* E = 1 impossible ??? */
         numeric fuzz FUZZ             /* <= fuzzy termination */

         if RX.TRAF( 1 ) then iterate K
         if 1E-999999 < DX & DX < 9E+999999
            then Q = ' DX' || format( DX, 2, 0, 6, 0 )
            else Q = format( DX, 2, 0, 9, 0 )
         call RX.CRLF '[DiFf]' || Q || ':' S.0
         call trace RX.TRAF( 0 )       /* format() bug ignored */
      end K
      if Y <> S.0 & Y <> . then        /* patch zero or error: */
         if sign( DX - abs( Y )) > 0 then Y = 0 ;  else Y = 'E42'
   end                                 /* here E42 = underflow */
   return RX.DIGS( -2, Y, 'DiFf' )     /* for f(X+H) == f(X-H) */

   /* Dynamically determined coefficients and more differences */
   /* are possible, but for 19 = 9*2+1 digits 21st differences */
   /* are meaningless: GAMMA(22) > 10**19.                     */
   /* DF( "gamma(x)", 1000 ) won't work: ZETA versus Stirling. */

ERF:     procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +2 )  ;  signal on syntax name RX.TRAP
   select                              /* sign(0/0) undefined  */
      when \ datatype( X, 'n' )  then  Y = X
      when X < 0                 then  Y = -ERF( -X )
      otherwise                        /* => alternating signs */
         Y = X ;  Q = -X * X     ;  D = digits()
         do N = 1 until R = Y | ( 1 <= X & D < length( trunc( X )))
            R = Y    ;  X = X * Q / N  ;  Y = Y + X / ( 2 * N + 1 )
         end N                         /* 1 if all digits lost */
         Y = Y / RX.0PI.0  ;  if 1 <= Y then Y = 1
   end
   return RX.DIGS( -2, Y, 'ERF' )

   /* Gauss integral probability is Phi(x) = ERF(x / ROOT(2)). */
   /* For D digits < lg(x) the final sum would be meaningless, */
   /* using D < length(trunc(x)) = 1 + trunc(lg(x)) if 1 <= x. */

EXP:     procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select                              /* RX.0LN.1 = EXP( 1 ): */
      when \ datatype( X, 'n' )  then  Y = X
      when X < 0 then do               /* treat underflow as 0 */
         X = EXP(-X) ;  if X = '0/0' then Y = 0 ;  else Y = 1 / X
      end                              /* e**(-X) = 1 / (e**X) */
      when X > 2 then select           /* e**(N+x)=e**N * e**x */
         when datatype( '1E' || trunc( X ), 'n' ) then do
            N = trunc( X )
            numeric digits RX.DIGS(+2) ;  Y = RX.0LN.1 ** N
            numeric digits RX.DIGS(-2) ;  Y = Y * EXP( X -N )
         end
         when X <= 2302585092.9 then do
            N = 999999999              /* limit ** 999 999 999 */
            numeric digits RX.DIGS(+2) ;  Y = RX.0LN.1 ** N
            numeric digits RX.DIGS(-2) ;  Y = Y * EXP( X -N )
         end                           /* results are not very */
         otherwise   Y = '0/0'         /* accurate if 9 digits */
      end
      otherwise   P = 1 ;  Y = 1       /* sum okay for small X */
         do N = 1 until R = Y
            R = Y ;  P = P * X / N  ;  Y = Y + P
         end N
   end
   return RX.DIGS( -1, Y, 'EXP' )

!:       return GAMMA( 1 + arg( 1 = arg()))
GAMMA:   procedure expose RX.    ;  X = RX.ARGN( arg()>0, arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when \ datatype( X, 'n' )  then Y = X
      when arg() > 2             then Y = 'E40'
      when arg() = 2  then do          /* Euler's BETA(x,y) =  */
         R = GAMMA( X ) ;  Y = arg(2)  /* G(x) * G(y) / G(x+y) */
         S = R ;  if datatype( R, 'n' ) then S = GAMMA( Y )
         P = S ;  if datatype( S, 'n' ) then P = GAMMA( X + Y )
         Y = P ;  if datatype( P, 'n' ) then Y = R * ( S / P )
         /* BETA( x+1, y+1 ) = 2 * integral from t=0 to pi/2   */
         /*  over (sin(t) ** (2*x+1)) * (cos(t) ** (2*y+1)) dt */
         /* = integral from t=0 to 1 over (t**x)*((1-t)**y) dt */
         if Y = '0/0' then Y = 'E-2'   /* NOT YET IMPLEMENTED  */
      end                              /* integer X < 1 => 0/0 */
      when X < 1 & X = trunc(X)  then Y = '0/0'
      when 1000 < X then do            /* use Stirling formula */
         Y = X - 1   ;  X = 1 ;  S = 0 /* DON'T ignore LN(1+S) */
         numeric digits RX.DIGS( +2 )  ;  P = LN( Y )
         do N = 1 until R = S
            R = S ;  S = S + 1 / ( N * (( 12 * Y ) ** N ))
         end N    /* formula without LN(1+S) is less accurate: */
         Y = EXP( RX.0LN.0 / 2 + LN( 1+S ) + P / 2 + Y * ( P-1 ))
         numeric digits RX.DIGS( -2 )
      end
      when 0 < X & X <= 0.5 then do    /* G( X-1 ) = G(X) / X  */
         Y = 1 / X   ;  X = X + 1      /* 1 <= X < 2 see below */
      end
      when X < 1 then do               /* G( 1-X ) * G(1+X) =  */
         Y = 1 - X   ;  X = 1          /* = pi*X / sin( pi*X ) */
         Y = Y * RX.0PI.1 / ( GAMMA( Y+1 ) * SIN( Y * RX.0PI.1 ))
      end                              /* X < 0 or 0.5 < X < 1 */
      otherwise   Y = 1
         do while 2 <= X               /* other 1 < X <= 1000: */
            X = X - 1   ;  Y = Y * X   /* G( X+1 ) = G(X) * X  */
        end                            /* 1 <= X < 2 see below */
   end
   select
      when arg() = 2 | \ datatype( Y, 'n' ) then nop
      when 2 <= X    then  Y = Y/(X=2) /* G(1+1) = G(1) *1 = 1 */
      when X <= 1    then  Y = Y/(X=1) /* assert 1 <= X <= 2   */
      when X  > 1.5  then  Y = Y * ( X-1 ) * GAMMA( X-1 )
      when X  = 1.5  then  Y = Y * RX.0PI.0
      otherwise do                     /* G(1.5) = ROOT(pi/4)  */
         X = 1 - X   ;  P = X    ;  S = X * RX.MATH( 0 )
         do N = 2 until R = S          /* 1..1.5: sum LN(G(X)) */
            R = S ;  P = P * X   ;  S = S + ZETA( N ) * ( P / N )
         end N                         /* as far as Euler's C0 */
         Y = Y * EXP( S )              /* RX.MATH(0) accurate: */
      end                              /* limited by ZETA( 3 ) */
   end
   return RX.DIGS( -1, Y, 'BETA' )

GCD:     procedure expose RX.    ;  X = RX.ARGN( arg()=2, arg(1))
   if datatype( X, 'n' ) then do
      Y = RX.ARGN( 1, arg( 2 ))  ;  signal on syntax name RX.FUNK
      if datatype( Y, 'n' ) then do
         do while Y <> 0   ;  parse value Y X // Y with X Y ;  end
         Y = abs( X )
      end         /* Euclid's algorithm:  Greatest Common Div. */
   end            /* catch X//Y error 26: length(X%Y) > digits */
   else  Y = X
   return RX.DIGS( 0, Y, 'GCD' )

INT:     procedure expose RX.    ;  arg FUNC, A, B, Q
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   call on halt name RX.FUNK
   select
      when arg() < 3 | arg() > 4 then  Y = 'E40'
      when A = .     | B = .     then  Y = .
      when A = '0/0' | B = '0/0' then  Y = 'E-3'
      when datatype( A, 'n' ) & datatype( B, 'n' ) then do
         S = RX.FUNC( A )  ;  Y = S ;  I = B - A
         if Y <> .   then Y = RX.FUNC( B )
         if Y <> .   then S.0 = ( S + Y ) * I / 2
         if Q <> 0   then Q = 1        /* Q: polynom division, */
      end                              /* else only parabolic  */
      otherwise   Y = 'E41'
   end                                 /* Romberg integration: */
   if datatype( Y, 'n' ) then do K = 1 until Y = S.0
      numeric fuzz 0 ;  S = 0 ;  I = I / 2   ;  T.K = 0
      do P = A + I to B by 2 * I       /* sum of new A+I..B-I: */
         Y = RX.FUNC( P )  ;  if Y = . then leave K
         S = S + Y                     /* RX.FUNC traps errors */
      end P                            /* incl. '0/0' -> 'E-3' */

      H = 1 ;  Y = S.0  ;  L = K - 1   ;  S.K = S.L / 2 + S * I
      do L = K to 1 by -1              /* extrapolation in H*H */
         H = H * 4   ;  P = L-1  ;  T.P = S.P   ;  E = H
         if Q & ( S.L <> T.L )         /* Q: polynom division  */
            then E = H * ( S.P - T.L ) / ( S.L - T.L )
         S.P = S.L + ( S.L - S.P ) / ( E - 1 )
      end L                            /* E = 1 impossible ??? */
      numeric fuzz 1                   /* <= fuzzy termination */

      if RX.TRAF( 1 ) then iterate K
      call RX.CRLF '[INT ]' || right( 1 + 2 ** K, 7 ) 'terms:' S.0
      call trace RX.TRAF( 0 )
   end K
   return RX.DIGS( -1, Y, 'INT' )

INV:     procedure expose RX.    ;  arg FUNC, Y, A, B
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   call on halt name RX.FUNK     ;  X = 0
   select                              /* void : find f(x) = x */
      when arg() > 4 | arg() < 3    then  X = 'E40'
      when arg() = 4 &  B = .       then  X = B
      when              A = .       then  X = A
      when \ datatype( A, 'n' )     then  X = 'E41'
      when arg( 2, 'o' )            then  FUNC = FUNC '-X'
      when \ datatype( Y, 'n' )     then  X = 'E41'
      when Y = 0  then nop             /* Y = 0: find f(x) = 0 */
      when Y > 0  then FUNC = FUNC '-' || Y
      otherwise        FUNC = FUNC '+' || abs( Y )
   end                                 /* else : find f(x) = Y */
   if \ datatype( B, 'n' ) & B <> . & B > '' then  X = 'E41'
   if \ datatype( X, 'n' ) then  return RX.DIGS( -1, X, 'INV' )

   X = A ;  Y = RX.FUNC( X )  ;  C = Y ;  D = Y ;  NN = 10 ** -99
   if Y = . then return RX.DIGS( -1, . )
   if arg() = 4 then D = RX.FUNC( B )  ;  else B = A
   if D = . then return RX.DIGS( -1, . )

   do until sign( Y ) = 0 | A = B      /* exact Y=0, fuzzy A=B */
      numeric fuzz 0 ;  Z = ( C = D )
      if arg() = 3 | Z then do         /* determine Z = f'(X)  */
         Z = DF( FUNC, X ) ;  if Z <> . then Z = ( Z + NN ) - NN
      end                              /* truncate small Z = 0 */
      select
         /* original Newton: X' = X -f(X) / f'(X)              */
         /* modified Newton: X' = X -f(X) / f'(X) * 2**-N with */
         /*                  0 <= N & abs(f(X')) <= abs(f(X))  */
         /* Broyden method:  if N = 0 or 1 replace next f'(X') */
         /*                  by diff. ( f(X')-f(X ) / ( X'-X ) */
         /* Raphson method:  Z  = ROOT(f'(X)**2-2*f(x)*f''(X)) */
         /*                  X' = X -( f'(X) +[-] Z ) / f''(X) */
         /* implemented:     Z  = X -f(X) / f'(X) [* 2**-N ]   */
         /*                  X' = Z -f(Z) / f'(X) [* 2**-N']   */
         when Z <> 0 & Z <> . then do  /* tangent f'(X) <> 0:  */
            C = Y / Z   ;  A = abs(Y)  /* get |f(B)| <= |f(X)| */
            do until abs( D ) <= A
               B = X -C ;  D = RX.FUNC( B )  ;  C = C / 2
               if D = . then return RX.DIGS( -1, . )
            end                        /* B in X..X-f(X)/f'(X) */
            C = D / Z   ;  Z = abs(D)  /* get |f(A)| <= |f(B)| */
            do until abs( Y ) <= Z
               A = B -C ;  Y = RX.FUNC( A )  ;  C = C / 2
               if Y = . then return RX.DIGS( -1, . )
            end                        /* A in B..B-f(B)/f'(X) */
            X = A ;  C = Y
         end
         when C <> D then do           /* secant (A,C)...(B,D) */
            Z = sign( C ) * sign( D )  /* Z < 0:  regula falsi */
            if 0 <= Z & abs( C ) < abs( D ) then do
               X = B ;  B = A ;  A = X
               Y = D ;  D = C ;  C = Y
            end
            X = ( A * D - B * C ) / ( D - C )
            if Z < 0 & ( X = A | X = B ) then X = ( A + B ) / 2
            Y = RX.FUNC( X )           /* Z < 0: try bisection */
            if Y = . then return RX.DIGS( -1, . )
            if Z < 0 & sign( Y ) = sign( D ) then do
               B = X ;  D = Y
            end
            else do
               A = X ;  C = Y ;  if Z < 0 & Y = 0 then Y = D
            end
         end
         otherwise                     /* secant = tangent = 0 */
            X = . ;  if Z = 0 then X = 'E42' ;  leave
      end                              /* necessarily fatal ?? */
      numeric fuzz 1                   /* <= fuzzy termination */

      if RX.TRAF( 1 ) then iterate
      if 1E-999999 < abs( Y ) & abs( Y ) < 9E+999999
         then Z = ' Y=' || format( Y, 2, 0, 6, 0 )
         else Z = format( Y, 2, 0, 9, 0 )
      if sign( C ) * sign( D ) < 0
         then call RX.CRLF '[ INV]' || Z || ':' X
         else call RX.CRLF '[ INV]' || Z || ';' X
      call trace RX.TRAF( 0 )
   end
   return RX.DIGS( -1, X, 'INV' )

LI:      procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when X = 1 | X = 'E-3'     then Y = '0/0'
      when \ datatype( X, 'n' )  then Y = X
      when X = 0                 then Y = X
      when X < 0                 then Y = 'E-2'
      otherwise
         Q = LN( X ) ;  Y = LN( abs( Q )) + RX.MATH( 0 ) ;  X = 1
         do N = 1 until R = Y          /* Li( x ) = Ei(ln(x)): */
            R = Y ;     X = X * Q / N  ;  Y = Y + X / N
         end N /* LI(x) = integral 1/LN(t) dt from 0 to x <> 1 */
   end         /* LI(x) approximates the number of primes <= X */
   return RX.DIGS( -1, Y, 'LI' )

LN:      procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select                              /* ln( X ) log natural. */
      when X = 'E-3'             then Y = '0/0'
      when \ datatype( X, 'n' )  then Y = X
      when X < 0       then Y = 'E-1'  /* complex result error */
      when X = 0       then Y = '0/0'  /* X = +0 = lim ln(1/n) */
      when X < 1       then Y = -LN( 1 / X )
      when X > RX.0LN.1 then do        /* ln(x*(e**Y))=Y+ln(x) */
         numeric digits RX.DIGS( +2 )  ;  Y = 0
         do while X > RX.0LN.1         /* split x*(e**(2**P)), */
            Q = 1                      /* 2**N <= 999,999,999: */
            do N = 1 until X <= R | \ datatype( '1E' || Q, 'n' )
               R = RX.0LN.1 ** Q ;  Q = Q + Q
            end N                      /* ln(ln(X))/ln(2) <= N */
            N = 2 ** (N-2) ;  R = RX.0LN.1 ** N
            do while X > R ;  Y = Y + N   ;  X = X / R   ;  end
         end                           /* rest 0 <= ln(x) < 1: */
         numeric digits RX.DIGS( -2 )  ;  Y = Y + LN( X )
      end   /* double precision only for accurate RX.0LN.1 = e */
      otherwise
         X = (X-1) / (X+1) ;  Q = X*X  ;  Y = 0
         do N = 1 by 2 until R = Y     /* ln(x) for 1 <= X < e */
            R = Y ;  Y = Y + 2 * X / N ;  X = X * Q
         end N
   end
   return RX.DIGS( -1, Y, 'LN' )

LOG:     procedure expose RX.    ;  X = RX.ARGN( arg()>0, arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   if arg( 2, 'e' ) then B = RX.ARGN( 1, arg( 2 )) ;  else B = 2
   select
      when ( X = 'E-3' ) = datatype( X, 'n' )   then Y = X
      when ( B = 'E-3' ) = datatype( B, 'n' )   then Y = B
      when arg() > 2    then Y = 'E40' /* default arg(2): B=2  */
      when B = 1        then Y = 'E40' /* ambiguous: 1**0=1**1 */
      when 1 = X        then Y = 0     /* always B ** 0 = 1 ?? */
      when B = X        then Y = 1     /* always B ** 1 = B ?? */
      when B = 'E-3'    then Y = B     /* dubious base B = 0/0 */
      when B = 0        then Y = 'E40' /* but 0**0 =1, 0**1 =0 */
      when B < 0        then Y = 'E-2' /* NOT YET IMPLEMENTED  */
      when X = 'E-3'    then Y = '0/0' /* B ** 0/0 -> 0 or 0/0 */
      when X = 0        then Y = '0/0' /* B ** 0/0 -> 0 or 0/0 */
      when X < 0        then Y = 'E-1' /* complex: B ** Y < 0  */
      when B <> 2       then Y = LN( X ) / LN( B )
      otherwise   numeric digits RX.DIGS( +2 )
                  Y = RX.DIGS( -2, LN( X ) / RX.0LN.2 )
   end                                 /* use RX.0LN.2 = LN(2) */
   return RX.DIGS( -1, Y, 'LOG' )

NORM:    procedure expose RX.          /* result can be string */
   arg X, Y, Z, U, V             ;  signal on syntax name RX.TRAP
   select
      when X = . | Y = . | Z = . then  Y = .
      when X = '0/0' | Y = '0/0' then  select
         when arg() = 1          then  Y = '0/0'
         when arg() > 2          then  Y = 'E-3'
         when datatype( X, 'n' ) then  Y = '0/0'
         when datatype( Y, 'n' ) then  Y = '0/0'
         when X = Y  & Y = '0/0' then  Y = '0/0'
         otherwise                     Y = 'E40'
      end
      when \ datatype( X, 'n' )  then  Y = 'E40'
      when arg() = 1             then  Y = X * X
      when \ datatype( Y, 'n' )  then  Y = 'E40'
      when arg() = 2             then  Y = X * X + Y * Y
/* >> option */
      when \ datatype( Z, 'n' )  then  Y = 'E40'
      when arg() = 3 then select       /* 2nd degree equation: */
         when X = 0 & Z = 0      then  Y = 0
         when X = 0 & Y = 0      then  Y = 'E33'
         when X = 0              then  Y = -Z / Y
         when Z = 0              then  Y = -Y / X
         otherwise   call ROOT X, Y, Z ;        Y = RX.0ROOT
      end                              /* ROOT handles errors  */
      when arg() = 4 then select       /* 3rd degree equation: */
         when X = 0           then  Y = NORM( Y, Z, U )
         when U = 0 & Z = 0   then  Y = NORM( X, Y, Z )
         when U = 0 | ( X = U & Y = Z ) then do
            if U = 0          then  Y = ROOT( X, Y,    Z )
                              else  Y = ROOT( X, Y -X, X )
            if Y <> RX.0ROOT & datatype( RX.0ROOT, 'n' )
               then  return Y '.' RX.0ROOT
         end                           /* string for 2 results */
         otherwise   call ROOT X, Y, Z, U ;     return RX.0ROOT
      end                              /* 0..2 other solutions */
      when arg() = 5 then select       /* 4th degree equation: */
         when X = 0           then  return NORM( Y, Z, U, V )
         when V = 0 & U = 0   then  return NORM( X, Y, Z, U )
         when V = 0 then do            /* 0..3 other solutions */
            Y = ROOT( X, Y, Z, U )     /* excluding duplicates */
            if sign( wordpos( Y, RX.0ROOT ))
                              then  return RX.0ROOT
                              else  return RX.0ROOT '.' Y
         end                           /* ROOT handles errors: */
         otherwise   call ROOT X, Y, Z, U, V ;  return RX.0ROOT
      end                              /* 0..3 other solutions */
/* << option */
      otherwise      Y = 'E40'
   end
   return RX.DIGS( 0, Y, 'NORM' )

OVER:    procedure expose RX.    ;  X = RX.ARGN( arg()=2, arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   Y = 1 ;  N = RX.ARGN( 1, arg(2))    /* X over N (binomial), */
   select   /* textbook implementation, no tricks, X < N okay: */
      when  \ datatype( X, 'n' )             then  Y = X
      when  \ datatype( N, 'n' )             then  Y = N
      when  \ datatype( N, 'w' ) | N < 0     then  Y = 'E26'
      otherwise   do N = N to 1 by -1
         Y = Y * X / N  ;  X = X - 1
      end N /* Intentionally no "smart" operations like using  */
   end      /* (X-N) instead of N where this could be "better" */
   return RX.DIGS( -1, Y, 'OVER' )

ROOT:    procedure expose RX.          /* root or equation:    */
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   arg X, Y, Z, U, V             ;  if arg() = 1 then Y = 2
   R = 1 ;  RX.0ROOT = .               /* "." no real solution */
   select
      when arg() = 0 | arg() > 5             then R = 'E40'
      when sign( wordpos( . , X Y Z U V ))   then R = .
      when (X = '0/0' ) = datatype( X, 'n' ) then R = 'E40'
      when (Y = '0/0' ) = datatype( Y, 'n' ) then R = 'E40'
/* >> option */
      when arg() > 2 & ( X='0/0' | Y='0/0' ) then R = 'E-3'
      when arg() > 2 & \ datatype( Z, 'n' )  then R = 'E40'
      when arg() > 3 & \ datatype( U, 'n' )  then R = 'E40'
      when arg() > 4 & \ datatype( V, 'n' )  then R = 'E40'
      when arg() = 3 then select       /* 2nd degree equation: */
         when Z = 0  then R = 0        /* X*s*s + Y*s + Z = 0  */
         when X = 0 & Y = 0   then R = 'E33'
         when X = 0           then R = -Z / Y
         when 4*(X*Z) > Y**2  then R = 'E-1'
         otherwise                     /* 2nd result RX.0ROOT: */
            R = ROOT(( Y ** 2 ) -4 * X * Z ) * ( 1 -2 * (Y < 0))
            RX.0ROOT = -( R + Y ) / ( 2 * X )
            R =        +( R - Y ) / ( 2 * X )
            RX.0ROOT = RX.DIGS( 1, RX.0ROOT )
      end         /* smallest zero minimizes rounding problems */
      when arg() = 4 then select       /* 3rd degree equation, */
         when U = 0  then R = 0        /* ((X*s+Y)*s+Z)*s+U=0  */
         when X = 0           then R = ROOT( Y, Z, U )
         when X = U & Y = Z   then R = -1
         otherwise                     /* very tricky rounding */
            numeric digits RX.DIGS( +2 )
            V = Y ;  Y = Y/3  ;  U = (U*X*X - Z*X*Y) / 2 + (Y**3)
            Z = Z * X - V * Y ;  V = (U**2) + (( Z/3 ) ** 3 )
            if 0 <= V then do          /* use Cardano formula, */
               if Z <> 0 then do       /* 1..2 real solutions: */
                  R = ROOT( V )
                  R = (ROOT( R-U, 3 ) -ROOT( R+U, 3 ) -Y) / X
                  if V = 0 then  U = ( ROOT(   U, 3 ) -Y) / X
               end                     /* else no 2nd solution */
               else              R = (-ROOT( U+U, 3 ) -Y) / X
               numeric digits RX.DIGS( -2 )
               if V = 0 & Z <> 0 then RX.0ROOT = RX.DIGS( 1, U )
            end
            /* Other solution for R = +[-: U<0] ROOT(abs(Z/3)) */
            /* Z = 0: R = (               -ROOT( U+U, 3) -Y)/X */
            /* Z > 0: R = (-2*R* SH( ARSH(U / R**3) / 3) -Y)/X */
            /* V > 0: R = (-2*R* CH( AREA(U / R**3) / 3) -Y)/X */
            /* U = 0: R = ( [ +1 | 0 | -1 ] * ROOT( -Z ) -Y)/X */
            /* else : R = (-2*R*COS( ACOS(U / R**3) / 3) -Y)/X */
            else do
               R = 0                   /* R=0 for trivial U=0  */
               if U <> 0 then do       /* if irreducible case: */
                  R = ROOT( abs( Z / 3 )) * ( 1 -2 * (U < 0))
                  R = -2 * R * COS( ACOS( U / (R ** 3)) / 3 )
               end
               U = ROOT( 1, R, Z + R ** 2 )
               R = (R-Y)/X ;  U = (U-Y)/X ;  Z = (RX.0ROOT-Y)/X
               numeric digits RX.DIGS( -2 )
               RX.0ROOT = RX.DIGS( 1, U ) ;  Z = RX.DIGS( 1, Z )
               if RX.0ROOT <> Z then RX.0ROOT = RX.0ROOT '.' Z
            end                        /* 2..3 real solutions, */
      end                              /* 3rd = 2nd eliminated */
      when arg() = 5 & V = 0  then R = V
      when arg() = 5 & X = 0  then R = ROOT( Y, Z, U, V )
      when arg() = 5 then do           /* 4th degree equation: */
         if Y <> U | X <> V then do    /* reduce general case: */
            R = Y/4  ;  V = V*(X**3)-U*X*X*R +Z*X*R*R -3*(R**4)
            R = Y/2  ;  U = U*(X**2)-Z*X*R   +R**3
            Y = R/2  ;  Z = Z*X     -3*Y*R
         end
         else R = ''                   /* symmetry: X= V, Y= U */
         select
            when R = '' then do        /* symmetrical equation */
               V = 0 ;  R = Z - 2 * X  ;  RX.0ROOT = 0
               if 4 * X * R <= Y * Y then V = ROOT( X, Y, R )
               U = RX.0ROOT            /* V < 2, U < 2 invalid */
               if 2 <= abs( V ) then do
                  X = ROOT( V * V -4 ) ;  V = X +Z ;  R = X -Z
               end                     /* solution pair V & R, */
               else  V = ''            /* both invalid: V = '' */
               if 2 <= abs( U ) then do
                  X = ROOT( U * U -4 ) ;  U = X +Z ;  Z = X -Z
               end                     /* solution pair U & Z, */
               else  U = ''            /* both invalid: U = '' */
               X = 2 ;  Y = 0          /* adjust for R=(R-0)/2 */
            end
            when V =  0 then do        /* R=0 for trivial V=0: */
               R = 0 ;  V = ROOT( 1, 0, Z, U )
               parse var RX.0ROOT U . Z
               if U = . then U = '' ;  if Z = '' then Z = U
            end                        /* validate Z = U pair  */
            when U <> 0 then do        /* use Ferrari formula: */
               R = ROOT( 8, -Z * 4, -V * 8, Z * V * 4 - U ** 2 )
               Z = R ** 2  ;  N = ( U ** 2 ) / ( 4 * ( Z - V ))
               if 0 <= N & V <= Z then do
                  Z = ROOT( Z - V ) ;  N = ROOT( N )
                  if RX.DIGS( 1, Z * N ) = RX.DIGS( 1, U / 2 )
                     then N = -N       /* match Z * N = -U / 2 */
                  if 4 * ( R+Z ) <= N * N then do
                     U = ROOT( 1,  N, R+Z )  ;  V = RX.0ROOT
                  end                  /* temporary pair U, V, */
                  else  U = ''         /* both invalid: U = '' */
                  if 4 * ( R-Z ) <= N * N then do
                     Z = ROOT( 1, -N, R-Z )  ;  R = RX.0ROOT
                  end                  /* temporary pair Z, R, */
                  else  Z = ''         /* both invalid: Z = '' */
                  parse value V Z with Z V
               end                     /* after swap U,Z & V,R */
               else     parse value '' with U V
            end                        /* if no real solutions */
            when 4 * V <= Z * Z then do
               V = ROOT( 1, Z, V )  ;  U = RX.0ROOT
               if 0 <= V then V = ROOT( V )  ;  else V = ''
               if 0 <= U then U = ROOT( U )  ;  else U = ''
               if V > '' then R = -V   /* (s**4)+Z*(s**2)+V=0: */
               if U > '' then Z = -U   /* +/- 2nd degree roots */
            end                        /* pair U, Z or V, R    */
            otherwise   parse value '' with U V
         end                           /* if no real solutions */
         if U > '' then U = ( U-Y ) / X   ;  else Z = ''
         if V > '' then V = ( V-Y ) / X   ;  else R = ''
         if Z > '' then Z = ( Z-Y ) / X   ;  Z = Z U V
         if R > '' then R = ( R-Y ) / X   ;  R = Z R  ;  U = ''
         do while R > ''               /* skip duplicate zeros */
            parse var R V R   ;  V = RX.DIGS( 1, V )
            if wordpos( V, U ) = 0 then U = U '.' V
         end                           /* split 1st solution R */
         parse var U . R . RX.0ROOT    /* no 2nd solution: '.' */
         if RX.0ROOT = ''  then  RX.0ROOT = .
         if R = '' then R = 'E-1'      /* if no real solutions */
      end                              /********************** */
/* << option */
      when arg() > 2 then R = 'E40'    /* normal ROOT function */
      when Y = 0 then select           /* undefined: -1**(1/0) */
         when X = 1        then  R = 1 /* all X**(1/0) dubious */
         when X = '0/0'    then  R = '0/0'
         when abs( X ) > 1 then  R = '0/0'
         when abs( X ) < 1 then  R = 0
         otherwise               R = 'E33'
      end
      when Y = '0/0'       then  R = 1 /* (0/0)**0 = 1 dubious */
      when X = 0     then  if Y > 0 then  R = 0 ;  else R = '0/0'
      when X = '0/0' then  if Y < 0 then  R = 0 ;  else R = '0/0'
      when Y < 0     then do           /* avoid double fault:  */
           R = ROOT( X, -Y )  ;  if R <> . then R = 1 / R
      end
      when datatype( '1E' || (1/Y), 'n' ) then R = X ** ( 1 / Y )
      when X < 0     then do           /* X < 0 okay for odd Y */
         do N = 1 to 2 + digits() % 2 while \ datatype( Y, 'w' )
            Y = Y * 10  ;  R = R * 10  /* try Y*(10**N), other */
         end N                         /* primes not reliable  */
         if datatype( Y, 'w' ) then do /* R < 10** digits() -2 */
            N = GCD( R, Y )   ;  Y = Y / N   ;  R = R / N
         end
         else Y = 0                    /* inconclusive <> even */
         select                        /* odd Y no square root */
            when Y // 2 & R // 2 then  R = -ROOT( -X ** R, Y )
            when Y // 2          then  R = +ROOT( -X ** R, Y )
            when Y <> 0          then  R = 'E-1'
            otherwise   R = 'E41'      /* error if square root */
         end
      end
      otherwise                        /* limit ** 999,999,999 */
         V = 0 ;  U = 0 ;  Z = Y - 1   /* limit 500 iterations */
         if datatype( '1E' || Z, 'n' ) /* stop if oscillating: */
            then do N = 1 to 500 until W = U & V = R
               W = V ;  V = U ;  U = R
               R = ( Z * R + X / ( R ** Z )) / Y
            end N
         if V <> R then R = EXP( LN( X ) / Y )
   end   /* binomial sum for X ** (1/Y) would be less accurate */
   return RX.DIGS( -1, R, 'ROOT' )

   /* Collections of math. functions often support POW( x,y ), */
   /* but having a **-operator ROOT( x, 1/y ) is less limited: */
   /*  0 ** (0/1) =   1              : POW( 0,0 ) often fails  */
   /*  X ** (1/0) =  ROOT(  X, 0/1 ) : ROOT supports X <> -1   */
   /* +X ** (N/1) =   POW( +X, N/1 ) : whole N/1 not essential */
   /* +X ** (N/1) =  ROOT( +X, 1/N ) : dito, 1/N not essential */
   /* -X ** (N/1) =   POW( -X, N/1 ) : often limited N < 2**30 */
   /* -X ** (N/1) <> ROOT( -X, 1/N ) ? may fail, not essential */
   /* -X ** (1/N) <>  POW( -X, 1/N ) : generally not supported */
   /* -X ** (1/N) =  ROOT( -X, N/1 ) : ROOT supports any odd N */
   /* -X ** (M/N) <>  POW( -X, M/N ) : generally not supported */
   /* -X ** (M/N) <> ROOT( -X, N/M ) ? not generally supported */

SH:      procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when X = 'E-3'             then Y = '0/0'
      when \ datatype( X, 'n' )  then Y = X
      when abs( X ) <= digits()  then do
         Q = X * X   ;  Y = 0          /* sum is more accurate */
         do N = 3 by 2 until R = Y     /* odd N: T = X**N / N! */
            R = Y ;  Y = Y + X   ;  X = X * ( Q / N ) / ( N - 1 )
         end N
      end                              /* sign(0/0) undefined: */
      otherwise   Y = '0/0'   ;  Q = EXP( X )
                  if Q <> 0 & Q <> Y then Y = ( Q -EXP( -X )) / 2
   end
   return RX.DIGS( -1, Y, 'SH' )

SIN:     procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   select
      when \ datatype( X,'n') then Y =  X
      when X < 0              then Y = -SIN(-X )
      when X > RX.0PI.1 * 2   then Y =  SIN( X // ( RX.0PI.1 * 2 ))
      when X > RX.0PI.1       then Y = -SIN( X -RX.0PI.1 )
      when X > RX.0PI.2       then Y =  SIN( RX.0PI.1 -X )
      when X > RX.0PI.2 / 2   then Y =  COS( RX.0PI.2 -X )
      otherwise                        /* else 0 <= X <= pi/4: */
         Y = X ;  Q = -X * X           /* => alternating signs */
         do N = 2 by 2 until R = Y     /* term T = X ** N / N! */
            R = Y ;  X = X * ( Q / N ) / ( N + 1 ) ;  Y = Y + X
         end N
   end
   return RX.DIGS( -1, Y, 'SIN' )

SUM:     procedure expose RX.    ;  arg FUNC ;  Y = ( 1 <> arg())
   if FUNC = . then Y = FUNC && FUNC   /* test syntax error 34 */
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   call on halt name RX.FUNK     ;  if Y then Y = 'E40'
   if Y = 0 then do N = 1 until R = Y | Y = .
      R = Y ;  Y = RX.FUNC( N )  ;  if Y <> . then Y = R + Y

      if RX.TRAF( 1 ) then iterate N
      call RX.CRLF '[SUM ]' || right( N, 7 ) 'terms:' Y
      call trace RX.TRAF( 0 )
   end N
   return RX.DIGS( -1, Y, 'SUM' )

TAN:     procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   if datatype( X, 'n' ) then do ;  Y = COS( X )
      if Y = 0 then  Y = '0/0'   ;  else  Y = SIN( X ) / Y
   end                                 /* COS(X) =0: Y = '0/0' */
   else  Y = X
   return RX.DIGS( -1, Y, 'TAN' )

TH:      procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   if datatype( X, 'n' ) then do ;  Y = CH( X )
      if Y = '0/0' then Y = sign( X )  ;  else  Y = SH( X ) / Y
   end                                 /* huge X: Y = sign(X)  */
   else  Y = X
   return RX.DIGS( -1, Y, 'TH' )

ZETA:    procedure expose RX.    ;  X = RX.ARGN( arg(), arg(1))
   numeric digits RX.DIGS( +1 )  ;  signal on syntax name RX.TRAP
   Y = 0 ;  K = RX.0ZETA
   if datatype( X, 'n' ) then N = trunc( abs( X )) ;  else Y = .
   select
      when Y = .     then Y = X        /* +0/0 -> 1, -0/0 -> ? */
      when X = 1     then Y = '0/0'    /* X = 1: undefined 0/0 */
      when X > K     then Y = 1        /* depending on digits  */
      when X = -N    then Y = RX.MATH( 1-X ) / ( X-1 )
      when X < 0.5   then do           /* X < 1/2, no integer: */
         Y =   0.5 * ZETA( 1-X ) / COS( X * RX.0PI.2 )
         Y = Y *( EXP(( RX.0LN.0 ) * X ) / GAMMA( X ))
      end   /* 0.5*ZETA(1-X)*((2*pi)**X)/(COS(X*pi/2)*(X-1)! ) */
      when X = 0.5   then Y = 'E-2'    /* NOT YET IMPLEMENTED: */
      when X < 1     then Y = 'E-2'    /* 0 < X < 1 won't work */
      when X > N     then  do K = 1 until N = Y
         N = Y ;  Y = Y + EXP( -X * LN( K ))

         if \ RX.TRAF( 1 ) then do
            call RX.CRLF '[ZETA]' || right( K, 7 ) 'terms:' Y
            call trace RX.TRAF( 0 )
         end      /* X>1: ZETA = sum K**-X = sum EXP(-X*LN(K)) */
      end K       /* odd: RX.MATH(1-X) saves ZETA = sum K**-X  */
      when N // 2    then Y = RX.MATH( 1-X )
      when K < X * 2 then  do K = 1 until N = Y
         N = Y ;  Y = Y + K**-X        /* fast and accurate if */
      end K                            /* X > 1, "big" even X  */
      otherwise                        /* X > 1, small even X: */
         numeric digits RX.DIGS( +2 )  /* for double precision */
         Y = abs( RX.MATH( X )) * (( 2 * RX.0PI.1 ) ** X )
         Y = Y / ( 2 * X * GAMMA( X )) /* use Bernoulli number */
         numeric digits RX.DIGS( -2 )  /* below accuracy limit */
   end
   return RX.DIGS( -1, Y, 'ZETA' )

/* << nomath */
