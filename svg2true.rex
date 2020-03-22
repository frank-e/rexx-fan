/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) without RexxUtil: */
/* rsvg-convert SVG to SVG basic 1.1 (or SVG tiny 1.1)            */
/* Porting: Fix three lines "call SYSTEM ..." for your OS + shell */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20

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
   call SYSTEM TMP               ;  if rc <> 0  then  exit rc
   TMP = DST
   DST = left( DST, length( DST ) - 3 ) || 'svg'
   if DST = SRC                           then  exit USAGE( SRC )
   SRC = TMP
   TMP = '@if exist "' || DST || '" del "' || DST || '"'
   call SYSTEM TMP               ;  if rc <> 0  then  exit rc

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
   call SYSTEM '@del "' || SRC || '"'
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
   say ' Needs rsvg-convert in the PATH to convert a given INPUT   '
   say ' SVG to a valid SVG 1.1 tiny or basic.  This code produces '
   say ' a "tiny" SVG if the Rexx source contains TINY in its name,'
   say ' otherwise it produces a "basic" SVG.  Both can fail if the'
   say ' INPUT SVG requires an unavailable font.                   '
   say ' SVG 1.1 tiny (unlike 1.2 tiny) does not support scripts,  '
   say ' this could be a security advantage.  It also cannot handle'
   say ' style attributes, i.e., a syntactically valid SVG tiny can'
   say ' be rendered as garbage.  Try SVG 1.1 basic if TINY fails. '
   return 1                      /* exit code 1, nothing happened */

/* ----------------------------- (wrap address SYSTEM 2020-03-17) */
/* Regina uses an intuitive address SYSTEM for internal commands, */
/* redirections, and pipes.  Regina uses address CMD for external */
/* commands, roughly that is an address SYSTEM 'start ... /WAIT'. */
/* An ooRexx address CMD corresponds to Regina address SYSTEM, on */
/* Windows ooRexx RexxUtil has RxWinExec() for external commands. */

SYSTEM:  procedure expose rc
   parse version S V .           ;  call on FAILURE   name ERROR
   if ( V == 5.00 ) | ( 6 <= V & V < 7 )  then  do
      if V = 5 then  address SYSTEM arg( 1 )          /* Regina   */
               else  address CMD    arg( 1 )          /* (o)oRexx */
      return .RS < 0                                  /* 1: fail  */
   end                           /* Kedit KEXX 5.xy not supported */
   exit ERROR( 'Please edit procedure SYSTEM() for' S V )

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
