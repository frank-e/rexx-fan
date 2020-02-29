/* NT ooREXX RXWINSYS demo script (classic REXX, no WINSYSTM.CLS) */

/* RXWINSYS clipboard access, call this as command or subroutine: */
/* If a non-empty argument is given it is copied to the clipboard */

/* Otherwise the content of the clipboard is written (command) or */
/* returned (subroutine).  If the clipboard was empty nothing is  */
/* written (command error code 1).  For a function or subroutine  */
/* an empty string is returned.  This script does not support to  */
/* erase the clipboard content.           (Frank Ellermann, 2008) */

   signal on  novalue  name TRAP ;  signal on  syntax name TRAP
   signal on  failure  name TRAP ;  signal on  halt   name TRAP

   VAL = 'WSClipboard'
   if RxFuncQuery(   VAL ) then
      if RxFuncAdd(  VAL, 'RxWinSys', VAL )  then
         exit TRAP( 'cannot add RxWinSys' VAL )
   VAL = sign( WSClipboard( 'AVAIL' ))

   if arg( 1 ) <> '' then  do    /* COPY this to the clipboard... */
      if VAL   then  call WSClipboard 'EMPTY'
      VAL = WSClipboard( 'COPY', arg( 1 ))
   end
   else  do
      parse source . SRC .

      if VAL   then  do
         VAL = WSClipboard( 'PASTE' )
         if SRC = 'COMMAND'   then  do
            say VAL              ;  VAL = 0
         end
      end
      else  do
         if SRC = 'COMMAND'   then  VAL = 1
                              else  VAL = ''
      end
   end

   return VAL

/* see <URL:http://purl.net/xyzzy/rexxtrap.htm>, (c) F. Ellermann */

TRAP:                            /* select REXX exception handler */
   call trace 'O' ;  trace N           /* don't trace interactive */
   parse source TRAP                   /* source on separate line */
   TRAP = x2c( 0D ) || right( '+++', 10 ) TRAP || x2c( 0D0A )
   TRAP = TRAP || right( '+++', 10 )   /* = standard trace prefix */
   TRAP = TRAP strip( condition( 'c' ) 'trap:' condition( 'd' ))
   select
      when wordpos( condition( 'c' ), 'ERROR FAILURE' ) > 0 then do
         if condition( 'd' ) > ''      /* need an additional line */
            then TRAP = TRAP || x2c( 0D0A ) || right( '+++', 10 )
         TRAP = TRAP '(RC' rc || ')'   /* any system error codes  */
         if condition( 'c' ) = 'FAILURE' then rc = -3
      end
      when wordpos( condition( 'c' ), 'HALT SYNTAX'   ) > 0 then do
         if condition( 'c' ) = 'HALT' then rc = 4
         if condition( 'd' ) > '' & condition( 'd' ) <> rc then do
            if condition( 'd' ) <> errortext( rc ) then do
               TRAP = TRAP || x2c( 0D0A ) || right( '+++', 10 )
               TRAP = TRAP errortext( rc )
            end                        /* future condition( 'd' ) */
         end                           /* may use errortext( rc ) */
         else  TRAP = TRAP errortext( rc )
         rc = -rc                      /* rc < 0: REXX error code */
      end
      when condition( 'c' ) = 'NOVALUE'  then rc = -2 /* dubious  */
      when condition( 'c' ) = 'NOTREADY' then rc = -1 /* dubious  */
      otherwise                        /* force non-zero whole rc */
         if datatype( value( 'RC' ), 'W' ) = 0 then rc = 1
         if rc = 0                             then rc = 1
         if condition() = '' then TRAP = TRAP arg( 1 )
   end                                 /* direct: TRAP( message ) */

   TRAP = TRAP || x2c( 0D0A ) || format( sigl, 6 )
   signal on syntax name TRAP.SIGL     /* throw syntax error 3... */
   if 0 < sigl & sigl <= sourceline()  /* if no handle for source */
      then TRAP = TRAP '*-*' strip( sourceline( sigl ))
      else TRAP = TRAP '+++ (source line unavailable)'
TRAP.SIGL:                             /* ...catch syntax error 3 */
   if abbrev( right( TRAP, 2 + 6 ), x2c( 0D0A )) then do
      TRAP = TRAP '+++ (source line unreadable)'   ;  rc = -rc
   end
   select
      when 0 then do                   /* in pipes STDERR: output */
         parse version TRAP.REXX       /* REXX/Personal: \dev\con */
         if abbrev( TRAP.REXX, 'REXXSAA ' ) |                /**/ ,
            6 <= word( TRAP.REXX, 2 )  then  TRAP.REXX = 'STDERR'
                                       else  TRAP.REXX = '\dev\con'
         signal on syntax name TRAP.FAIL
         call lineout TRAP.REXX , TRAP /* fails if no more handle */
      end
      when 1 then do                   /* OS/2 PM or ooREXX on NT */
         signal on syntax name TRAP.FAIL
         call RxMessageBox translate( TRAP, ' ', x2c( 0D )), /**/ ,
            'Trap' time(),, 'ERROR'
      end
      otherwise   say TRAP ; trace ?L  /* interactive Label trace */
   end

   if condition() = 'SIGNAL' then signal TRAP.EXIT
TRAP.CALL:  return rc                  /* continue after CALL ON  */
TRAP.FAIL:  say TRAP ;  rc = 0 - rc    /* force TRAP error output */
TRAP.EXIT:  exit   rc                  /* exit for any SIGNAL ON  */
