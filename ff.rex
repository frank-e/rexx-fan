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

   SRC = strip( arg( 1 ))        ;  if SRC = '' then  exit USAGE()
   if sign( wordpos( SRC, '-h /h -? /?' ))      then  exit USAGE()
   if left( SRC, 1 ) = '"' then  do
      if pos( '"', SRC, 2 ) <> length( SRC ) then  exit USAGE( SRC )
      SRC = strip( SRC,, '"' )   /* unquote double-quoted string  */
   end

   DIR = qualify( '/' )
   POS = lastpos( '/', translate( SRC, '/', '\' ))
   if POS > 0        then  do
      DIR = left( SRC, POS )     ;  SRC = substr( SRC, POS + 1 )
      POS = pos( '?', translate( DIR, '?', '*' ))
      if POS > 0 | SRC == ''     then  exit USAGE( DIR )
      DIR = qualify( DIR )       /* trim or expand ../ constructs */
   end
   if SRC == '.' | SRC == '..'   then  exit USAGE( SRC )

   B.0 = 0
   do N = 1 to DIRTREE( DIR || SRC, 'F', 'FOS' )
      if DIRTREE( F.N, 'G', 'L' ) <> 1 then  do
         BAD = B.0 + 1           ;  B.BAD = F.N
         B.0 = BAD               ;  iterate N
      end                        /* lost file or ooRexx 6.04 oops */

      LEN = word( G.1, 3 )       ;  TIM = left( G.1, 16 )
      ATT = word( G.1, 4 )       ;  G.1 = subword( G.1, 5 )
      select                     /* NUMERIC DIGITS 20 up to 2**66 */
         when  LEN < 10** 8   then  LEN = ( LEN % ( 2** 0 )) || '  '
         when  LEN < 10**11   then  LEN = ( LEN % ( 2**10 )) || 'KB'
         when  LEN < 10**14   then  LEN = ( LEN % ( 2**20 )) || 'MB'
         when  LEN < 10**17   then  LEN = ( LEN % ( 2**30 )) || 'GB'
         when  LEN < 10**20   then  LEN = ( LEN % ( 2**40 )) || 'TB'
         otherwise   exit ERROR( 'unexpected length' LEN 'for' G.1 )
      end
      LEN = right( LEN, 10 )     ;  say TIM LEN ATT F.N
   end N
   do N = 1 to B.0               /* lost file or ooRexx 6.04 oops */
      BAD = copies( '?', 8 )     /* dummy TIM: 16, LEN: 8, ATT: 5 */
      say BAD || BAD BAD ' ' left( BAD, 5 ) B.N
   end N
   if F.0 <> 1 then  say F.0 'files below' DIR 'match' SRC

   return 0

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE '[SUBDIR/]FILE'
   say                           /* suited for REXXC tokenization */
   say ' Shows FILEs in or below SUBDIR (default: root directory). '
   say ' FILE can contain * or ? as wildcards.                     '
   return 1

/* ----------------------------- (SysFileTree wrapper 2017-05-12) */
/* Treat SysFileTree errors as fatal, otherwise return the number */
/* of found files stored in stem.0 for the stem specified as 2nd  */
/* argument.  Attributes (4th + 5th SysFileTree argument) are not */
/* supported; the first three SysFileTree arguments are required. */
/* Clobbers DIRTREE.. in the scope of the caller.                 */

DIRTREE:                         /* return number of found files: */
   if right( arg( 2 ), 1 ) = '.' then  DIRTREE.. = arg( 2 )
                                 else  DIRTREE.. = arg( 2 ) || '.'
   if SysFileTree( arg( 1 ), DIRTREE.., arg( 3 )) = 0
      then  return value( DIRTREE.. || 0 )
      else  exit ERROR( 'SysFileTree failed near line' sigl )

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

