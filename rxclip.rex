/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with RexxUtil     */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

/* -------------------------------------------------------------- */
/* NT ooREXX RXWINSYS demo script (classic REXX, no WINSYSTM.CLS) */

/* RXWINSYS clipboard access, call this as command or subroutine: */
/* If a non-empty argument is given it is copied to the clipboard */

/* Otherwise the content of the clipboard is written (command) or */
/* returned (subroutine).  If the clipboard was empty nothing is  */
/* written (command error code 1).  For a function or subroutine  */
/* an empty string is returned.  This script does not support to  */
/* erase the clipboard content.           (Frank Ellermann, 2020) */

   if REXX = 5 then  exit ERROR( 'w32util cannot be loaded' )
               else  parse value 'WSClipboard RxWinSys' with VAL SRC

   if RxFuncQuery( VAL )   then  do
      ERR = RxFuncAdd(  VAL, SRC, VAL )
      if ERR <> 0 then  exit ERROR( SRC 'load' VAL 'error' ERR )
      if REXX = 5 then  call w32loadfuncs
   end

   VAL = sign( CLIP.AVAIL())

   if arg( 1 ) <> '' then  do    /* COPY this to the clipboard... */
      if VAL   then  call CLIP.EMPTY
      VAL = CLIP.COPY( arg( 1 ))
   end
   else  do
      parse source . SRC .

      if VAL   then  do
         VAL = CLIP.PASTE()
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

CLIP.AVAIL: if REXX = 5 then  return w32clipgetstem( 'CLIP.' ) = 0
                        else  return WSClipboard( 'AVAIL' )
CLIP.EMPTY: if REXX = 5 then  return w32clipempty()
                        else  return WSClipboard( 'EMPTY' )
CLIP.PASTE: if REXX = 5 then  return w32clipget()
                        else  return WSClipboard( 'PASTE' )
CLIP.COPY:  if REXX = 5 then  return w32clipset(          arg( 1 ))
                        else  return WSClipboard( 'COPY', arg( 1 ))

/* ----------------------------- (Regina SysLoadFuncs 2015-12-06) */

REGUTIL: procedure               /* Not needed for ooRexx > 6.03  */
   if RxFuncQuery( 'SysLoadFuncs' ) then  do
      ERR = RxFuncAdd( 'SysLoadFuncs', 'RexxUtil' )
      if ERR <> 0 then  exit ERROR( 'RexxUtil load error' ERR )
   end                           /* static Regina has no RexxUtil */
   ERR = SysLoadFuncs()          ;  return SysUtilVersion()

/* ----------------------------- (STDERR: unification 2020-03-14) */
/* PERROR() emulates lineout( 'STDERR:', emsg ) with ERROUT().    */
/* ERROUT() emulates charout( 'STDERR:', emsg ).                  */

/* ERROR() shows an error message and the source line number sigl */
/* on stderr.  Examples:   if 0 = 1 then  exit ERROR( 'oops' )    */
/*                         call ERROR 'interactive debug here'    */

/* ERROR() can also catch exceptions (REXX conditions), examples: */
/* SIGNAL ON ERROR               non-zero rc or unhandled FAILURE */
/* SIGNAL ON NOVALUE NAME ERROR  uninitialized variable           */
/* CALL ON NOTREADY NAME ERROR   blocked I/O (incl. EOF on input) */

/* ERROR() uses ERROR. in the context of its caller and returns 1 */
/* for explicit calls or CALL ON conditions.  For a SIGNAL ON ... */
/* condition ERROR() ends with exit 1.                            */

PERROR:  return sign( ERROUT( arg( 1 ) || x2c( 0D0A )))
ERROUT:  procedure
   parse version S V .           ;  signal off notready
   select
      when  6 <= V & V < 7 then  S = 'STDERR:'        /* (o)oRexx */
      when  S == 'REXXSAA' then  S = 'STDERR:'        /* IBM Rexx */
      when  V == 5.00      then  S = '<STDERR>'       /* Regina   */
      otherwise                  S = '/dev/con'       /* Quercus  */
   end                           /* Kedit KEXX 5.xy not supported */
   return charout( S, arg( 1 ))

ERROR:                           /* trace off, save result + sigl */
   ERROR.3 = trace( 'o' )        ;  ERROR.1 = value( 'result' )
   ERROR.2 = sigl                ;  call PERROR
   ERROR.3 = right( ERROR.2 '*-*', 10 )
   if ERROR.2 <= sourceline()
      then  call PERROR ERROR.3 strip( sourceline( ERROR.2 ))
      else  call PERROR ERROR.3 '(source line unavailable)'

   ERROR.3 = right( '+++', 10 ) condition( 'c' ) condition( 'd' )
   if condition() = ''  then  ERROR.3 = right( '>>>', 10 ) arg( 1 )
   call PERROR ERROR.3
   select
      when  sign( wordpos( condition( 'c' ), 'ERROR FAILURE' ))
      then  ERROR.3 = 'RC' rc
      when  condition( 'c' ) = 'SYNTAX'
      then  ERROR.3 = errortext( rc )
      when  condition( 'c' ) = 'HALT'
      then  ERROR.3 = errortext( 4 )
      when  condition( 'c' ) = 'NOTREADY' then  do
         ERROR.3 = condition( 'd' )
         if ERROR.3 <> ''  then  do
            ERROR.3 = stream( ERROR.3, 'd' )
         end
      end
      otherwise   ERROR.3 = ''
   end
   if ERROR.3 <> ''  then  call PERROR right( '>>>', 10 ) ERROR.3
   parse value ERROR.2 ERROR.1 with sigl result
   if ERROR.1 == 'RESULT'  then  drop result
   trace ?L                      /* -- interactive label trace -- */
ERROR:   if condition() = 'SIGNAL'  then  exit 1
                                    else  return 1
