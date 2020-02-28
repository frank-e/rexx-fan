/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with RexxUtil     */

/* Replace older stupid WHICH.CMD with a decent NT ooREXX script: */
/* WHICH.REX displays all files in the PATH for a given NAME or   */
/* NAME.EXT (without EXT all PATHEXT extensions are scanned).     */
/*                                        (Frank Ellermann, 2011) */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             /* UTIL = REGUTIL()              */

/* -------------------------------------------------------------- */

   NAME = strip( strip( arg( 1 )),, '"' )
   HELP = verify( NAME, '/\*?"<|>:', 'M' )
   STOP = lastpos( '.', NAME )   ;  TYPE = ''
   select
      when  NAME == ''     then  exit USAGE()
      when  HELP > 0       then  exit USAGE( NAME )
      when  STOP = 0       then  HELP = HELP( NAME )
      when  NAME = '.'     then  nop
   otherwise                     /* some kind of last dot exists: */
      TYPE = substr( NAME, STOP )
      NAME = left(   NAME, STOP - 1 )
   end

   if MISS( NAME, TYPE )   then  do
      if TYPE = ''
         then  TYPE = '"' || NAME || '.*" (using PATHEXT)'
         else  TYPE = '"' || NAME || TYPE || '"'
      TYPE = TYPE 'not found in PATH'
      if HELP  then  say TYPE || ', but see `HELP' NAME || '`.'
               else  say TYPE    /* 1: unknown, HELP concurs      */
      return 1 - HELP            /* 0: known, internal HELP       */
   end

   if HELP  then  say 'Also see `HELP' NAME || '`.'
   return 0                      /* 0: known, external file       */

/* -------------------------------------------------------------- */
/* trace 'o'   : disable erroneous Regina trace for return code 1 */
/* 1>nul 2>&1  : trash HELP.exe stdout and stderr output          */

/* CAVEAT, the `HELP GRAFTABL` rc 1 (known command) is about an   */
/* ancient 16bit NTVDM command GRAFTABL.com unavailable on 64bit  */
/* Windows platforms (same idea as 16bit COMMAND.com + KEYB.com,  */
/* but unlike other old 32bit EXE-files with file extension COM.) */

HELP: procedure                  /* check internal commands       */
   signal off error              ;  parse arg NAME

   if NAME = 'SC' then  return 1 /* suppress interactive 'SC /?'  */
   call trace 'o'                /* suppress Regina failure trace */

   '@help "' || NAME || '" >nul 2>&1'
   return ( rc = 1 )             /* rc = 1 is good (and no error) */

/* -------------------------------------------------------------- */
MISS: procedure                  /* check external commands       */
   parse arg NAME, FEXT
   PATH = value( 'PATH'    ,, 'ENVIRONMENT' )
   PEXT = value( 'PATHEXT' ,, 'ENVIRONMENT' )
   PATH = '.;' || PATH           /* check current directory first */
   MISS = 1
   do until PATH == ''
      parse var PATH NEXT ';' PATH
      if FEXT = ''   then  EXTS = PEXT
                     else  EXTS = FEXT
      do until EXTS == ''
         parse var EXTS FILE ';' EXTS
         FILE = NEXT || '\' || NAME || FILE
         if stream( FILE, 'c', 'query exists' ) = ''  then  iterate
         SIZE = stream( FILE, 'c', 'query size' )
         DATE = stream( FILE, 'c', 'query timestamp' )
         if SIZE > 33554432   then  SIZE = SIZE % 1048576 || 'M'
                              else  SIZE = SIZE || ' '
         say left( DATE, 16 ) right( SIZE, 9 ) FILE
         MISS = 0
      end
   end
   return MISS                   /* 0: found, 1: not found        */

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'NAME[.EXT]'
   say                           /* suited for REXXC tokenization */
   say ' Shows all NAME.EXT in the current directory or PATH.    '
   say ' Without .EXT the extensions in PATHEXT are checked.     '
   say ' NAME can be "empty" if a leading dot is the last dot.   '
   say ' "NAME[.EXT]" must be quoted if it begins with a space.  '
   return 1

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

