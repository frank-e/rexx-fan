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

   parse source . . TMP          ;  TMP = filespec( 'name', TMP )
   MKLINK = abbrev( translate( TMP ), 'CMPLINK' )

   if arg() = 0 | arg() > 2   then  exit USAGE()
   if arg() = 2               then  parse arg       SRC,    DST
   if arg() = 1               then  do
      TMP = strip( arg( 1 ))     ;  DST = pos( '"', TMP )
      select
         when  TMP = ''       then  exit USAGE()
         when  DST = 0        then  parse var TMP   SRC     DST
         when  DST = 1        then  parse var TMP 2 SRC '"' DST
         when  DST > 1        then  do
            SRC = strip( left( TMP, DST - 1 ))
            DST = substr( TMP, DST )
         end
      end
      TMP = strip( DST )         ;  DST = pos( '"', TMP )
      if DST = 0              then  parse var TMP   DST     TMP
                              else  parse var TMP 2 DST '"' TMP
      if DST = ''             then  exit USAGE( SRC )
      if TMP <> ''            then  exit USAGE( DST )
   end

   S.. = DIRECT( strip( SRC ))   ;  DUP = 0
   DIR = DIRECT( strip( DST ))   ;  ERR = 0
   POS = length( S.. ) + 1
   if S.. = '' | S.. = DIR    then  exit USAGE( SRC )
   if DIR = ''                then  exit USAGE( DST )
   if DIRTREE( S.. || '\*', 'S', 'FSO' ) = 0
                              then  exit USAGE( SRC )

   do N = 1 to S.0
      REL = substr( S.N, POS )   ;  CHK = DIR || REL
      call charout /**/, left( SRC || REL, 79 ) || x2c( 0D )

      TMP = CMPFILE( S.N, CHK )
      if TMP <  0 then  ERR = ERR + 1
      if TMP <> 0 then  iterate  /* files different (or NOTREADY) */

      TMP = SysFileDelete( S.N )
      if TMP <> 0 then  do
         TMP = SysGetErrorText( TMP )
         ERR = ERR + 1           ;  say SRC || REL TMP
      end                        /* FIXME: not tested on Linux    */
      else  do
         if MKLINK               /* SIGNAL ON ERROR catches error */
            then  '@mklink /H "' || S.N || '" "' || CHK || '" 1>nul'
            else  say SRC || REL 'erased'
         DUP = DUP + 1
      end
   end N

   call charout /**/, left( '', 79 ) || x2c( 0D )

   if \ MKLINK then  do until DONE
      DONE = 1                   /* remove empty sub-directories: */
      do N = 1 to DIRTREE( S.. || '\*', 'S', 'DSO' )
         if DIRTREE( S.N || '\*', 'F', 'SO' ) = 0  then  do
            DUP = DUP + 1        ;  REL = substr( S.N, POS )
            TMP = SysRmDir( S.N );  say SRC || REL 'empty'
            if TMP <> 0 then  do
               TMP = SysGetErrortext( TMP )
               exit ERROR( 'SysRmDir(' S.N ') error:' TMP )
            end                  /* error must exit SysRmDir loop */
            DONE = 0             /* retry until no new empty dir. */
         end
      end N
   end

   if MKLINK   then  TMP = 'hardlinked'
               else  TMP = 'deleted'
   say DUP 'dupe(s) in "' || SRC || '"' TMP || ',' ERR 'error(s)'
   return ( ERR <> 0 )

DIRECT:  procedure
   CWD = directory()             ;  DIR = directory( arg( 1 ))
   CWD = directory( CWD )        ;  return DIR

/* -------------------------------------------------------------- */

CMPFILE: procedure
   parse arg F1, F2              ;  BLK = 2**21

   S2 = stream( F2, 'c', 'query exists' )
   if S2 = ''  then  return 1    /* +1: empty != non-existing     */

   S1 = stream( F1, 'c', 'query size' )
   S2 = stream( F2, 'c', 'query size' )
   if S2 <> S1 then  return 1    /* +1: different size            */

   S1 = -1                       /* -1: not ready (maybe locked)  */
   signal on notready NAME CMPFILE.BUSY

   do while sign( S2 )
      S1 = min( S2, BLK )
      if charin( F1 ,, S1 ) \== charin( F2 ,, S1 )
         then  leave             /* S2 > 0: files are different   */
      S2 = S2 - S1               /* S2 = 0: files are identical   */
   end
   S1 = sign( S2 )               /* S1 = +1 if difference found   */

CMPFILE.BUSY:
   if S1 = -1  then  do          /* S1 = -1, report condition():  */
      S2 = condition( 'd' )
      if S2 <> '' then  say S2 stream( S2, 'd' )
   end

   call lineout F1               ;  call lineout F2
   return sign( S1 )             /* S1 = 0: files are identical   */

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure expose MKLINK /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'SRCDIR DSTDIR'
   say                           /* suited for REXXC tokenization */
   if MKLINK   then  do          /* CAVEAT, unusual USAGE() hack  */
      say ' Hardlinks all SRCDIR files also found in DSTDIR with '
      say ' MKLINK /H (Windows, for Linux edit this script).  The'
      say ' file system must permit hardlinks (e.g., NTFS.)  Any '
      say ' SRCDIR/[sub/]file with an identical DSTDIR/[sub/]file'
      say ' is first deleted and then hardlinked.                '
      return 1
   end
   say ' Deletes all SRCDIR files also found in DSTDIR, i.e., any'
   say ' SRCDIR/[sub/]file with an identical DSTDIR/[sub/]file is'
   say ' deleted.                                                '
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

