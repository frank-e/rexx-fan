/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with RexxUtil     */
/* rsvg-convert SVG to SVG basic 1.1 (or SVG tiny 1.1)            */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

/* -------------------------------------------------------------- */

   parse upper source . . TMP    ;  TMP = sign( pos( 'TINY', TMP ))
   BASIC = 1 - TMP               /* BASIC if not TINY in own name */

   SRC = strip( strip( arg( 1 )),, '"' )
   TMP = wordpos( translate( SRC ), '/? -? /H -H' )
   if SRC = '' | sign( TMP )              then  exit USAGE()
   if sign( verify( '<?*>', SRC, 'M' ))   then  exit USAGE( SRC )
   TMP = stream( SRC, 'c', 'query exist' )
   if TMP = ''                            then  exit USAGE( SRC )
   SRC = TMP
   TMP = lastpos( '/', translate( TMP, '/', '\' ))
   if BASIC then  DST = left( SRC, TMP ) || 'true.tmp'
            else  DST = left( SRC, TMP ) || 'tiny.tmp'
   TMP = '@rsvg-convert -f svg -o "' || DST || '" "' || SRC || '"'
   address CMD TMP               ;  if rc <> 0  then  exit rc
   TMP = DST
   DST = left( DST, length( DST ) - 3 ) || 'svg'
   if DST = SRC                           then  exit USAGE( SRC )
   SRC = TMP
   TMP = '@if exist "' || DST || '" del "' || DST || '"'
   address CMD TMP               ;  if rc <> 0  then  exit rc

   TMP = '<?xml version="1.0" encoding="UTF-8" ?><!DOCTYPE svg'
   TMP = TMP 'PUBLIC "-//W3C//DTD SVG 1.1'
   if BASIC then  TMP = TMP 'Basic//EN" "http://www.'
            else  TMP = TMP 'Tiny//EN" "http://www.'
   TMP = TMP || 'w3.org/Graphics/SVG/1.1/DTD/svg11-'
   if BASIC then  call lineout DST, TMP || 'basic.dtd">'
            else  call lineout DST, TMP || 'tiny.dtd">'

   do N = 1 while sign( lines( SRC ))
      TMP = linein( SRC )
      if N = 2 then  call lineout DST, POINT( TMP, BASIC )
      if N > 2 then  call lineout DST, STYLE( TMP, BASIC )
   end
   call lineout SRC              ;  call lineout DST
   address CMD '@del "' || SRC || '"'
   exit rc

/* -------------------------------------------------------------- */

STYLE:   procedure               /* remove style=... for SVG tiny */
   if arg( 2 ) then  return arg( 1 )
   parse arg HEAD 'style="' . '"' TAIL
   if TAIL = ''   then  return   HEAD
   return strip( HEAD, 'T' ) strip( TAIL, 'L' )

/* -------------------------------------------------------------- */

POINT:   procedure               /* svg baseProfile basic or tiny */
   parse arg . 'width=' W 'height=' H 'viewBox=' V 'version=' .
   parse var W '"' W 'pt"'       ;  W =   'width="' || W || '"'
   parse var H '"' H 'pt"'       ;  H =  'height="' || H || '"'
   parse var V '"' V '"'         ;  V = 'viewBox="' || V || '"'
   if arg( 2 ) then  V = W H V 'baseProfile="basic" version="1.1">'
               else  V = W H V 'baseProfile="tiny" version="1.1">'
   W = '<svg xmlns="http://www.w3.org/2000/svg"'
   H = 'xmlns:xlink="http://www.w3.org/1999/xlink"'
   return W H V

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'INPUT'
   say                           /* suited for REXXC tokenization */
   say ' FIXME'
   say ' Needs rsvg-convert in the PATH to convert a given INPUT'
   say ' SVG to SVGT 1.1 (incomplete)'
   return 1                      /* exit code 1, nothing happened */

/* ----------------------------- (Regina SysLoadFuncs 2015-12-06) */

REGUTIL: procedure               /* Not needed for ooRexx > 6.03  */
   if RxFuncQuery( 'SysLoadFuncs' ) then  do
      ERR = RxFuncAdd( 'SysLoadFuncs', 'RexxUtil' )
      if ERR <> 0 then  exit ERROR( 'RexxUtil load error' ERR )
   end                           /* static Regina has no RexxUtil */
   ERR = SysLoadFuncs()          ;  return SysUtilVersion()

/* ----------------------------- (REXX ERROR template 2015-11-28) */
/* ERROR() shows an error message and the source line number sigl */
/* on stderr.  Examples:   if 0 = 1 then  exit ERROR( 'oops' )    */
/*                         call ERROR 'interactive debug here'    */

/* ERROR() can also catch exceptions (REXX conditions), examples: */
/* SIGNAL ON ERROR               non-zero rc or unhandled FAILURE */
/* SIGNAL ON NOVALUE NAME ERROR  uninitialized variable           */
/* CALL ON NOTREADY NAME ERROR   blocked I/O (incl. EOF on input) */

/* ERROR returns 1 for ordinary calls and CALL ON conditions, for */
/* SIGNAL ON conditions ERROR exits with rc 1.                    */

ERROR:
   ERROR.3 = trace( 'o' )        /* disable any trace temporarily */
   parse version ERROR.1 ERROR.2 ERROR.3
   select                        /* unify stderr output kludges   */
      when  abbrev( ERROR.1, 'REXX' ) = 0 then  ERROR.1 = ''
      when  ERROR.1 == 'REXXSAA'          then  ERROR.1 = 'STDERR:'
      when  ERROR.2 == 5.00               then  ERROR.1 = '<STDERR>'
      when  6 <= ERROR.2 & ERROR.2 < 7    then  ERROR.1 = 'STDERR:'
      otherwise                                 ERROR.1 = '/dev/con'
   end
   ERROR.3 = lineout( ERROR.1, '' )
   ERROR.3 = right( sigl '*-*', 10 )
   if sigl <= sourceline()       /* show source line if possible  */
      then  ERROR.3 = ERROR.3 strip( sourceline( sigl ))
      else  ERROR.3 = ERROR.3 '(source line unavailable)'
   ERROR.3 = lineout( ERROR.1, ERROR.3 )
   ERROR.3 = right( '+++', 10 ) condition( 'c' ) condition( 'd' )
   if condition() = ''  then  ERROR.3 = right( '>>>', 10 ) arg( 1 )
   ERROR.3 = lineout( ERROR.1, ERROR.3 )
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
   if ERROR.3 <> ''  then  do
      ERROR.3 = lineout( ERROR.1, right( '>>>', 10 ) ERROR.3 )
   end
   trace ?L                      ;  ERROR:
   if condition() <> 'SIGNAL'
      then  return 1             ;  else  exit 1

