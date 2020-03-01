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

   VHD = strip( arg( 1 ))        ;  SEC = 512
   if VHD = ''    then  exit USAGE()
   CHK = wordpos( VHD, '-? /? /h -h ?' )
   if CHK <> 0    then  exit USAGE()
   CHK = stream( strip( VHD,, '"' ), 'c', 'query exists' )
   if CHK = ''    then  exit USAGE( 'found no' VHD )
   LEN = stream( CHK, 'c', 'query size' )
   VHD = CHK                     ;  CHK = LEN // SEC
   if CHK = 0     then  CHK = SEC
   if CHK < 511   then  exit USAGE( 'no VHD size:' LEN / SEC )
   ERR = stream( VHD, 'c', 'open read' )
   if ERR <> 'READY:'
                  then  exit PERROR( 'cannot read' VHD ERR )

   LEN = LEN - CHK               /* length of disk image - footer */
   DAT = charin( VHD, LEN + 1, CHK )
   DAT = left( DAT, SEC, x2c( 0 ))
   if \ abbrev( DAT, 'conectix' )
                  then  exit PERROR( 'no VHD:' c2x( left( DAT, 8 )))
   ERR = c2d( substr( DAT, 60 + 1, 4 ))
   if ERR <> 2    then  exit PERROR( 'no fixed VHD:' c2x( ERR ))

   parse version . NEW .         ;  TOP = trunc( NEW )
   NEW = d2c( TOP, 2 ) || d2c( trunc( 100 * ( NEW - TOP )), 2 )
   NEW = 'REXX' || NEW           /* patch NEW timestamp + creator */
   NEW = d2c( time( 'T' ) - date( 'T', 20000101, 'S' ), 4 ) || NEW
   DAT = overlay( NEW, DAT, 24 + 1 )
   NEW = d2c( 0, 4 )
   do N = 1 to 16                /* 16 bytes UUID v4 RFC 4122,    */
      select                     /* randomize 122 of 128 bits:    */
         when  N = 7 then  NEW = NEW || d2c( 128 + random(  63 ))
         when  N = 9 then  NEW = NEW || d2c(  64 + random(  15 ))
         otherwise         NEW = NEW || d2c(       random( 255 ))
      end
   end N
   DAT = overlay( NEW, DAT, 64 + 1 )
   NEW = 0
   do N = 1 to length( DAT )     /* patch NEW VHD footer checksum */
      NEW = NEW + c2d( substr( DAT, N, 1 ))
   end N
   NEW = bitxor( d2c( NEW, 4 ),, x2c( 'FF' ))
   DAT = overlay( NEW, DAT, 64 + 1 )

   DST = BACKUP( VHD )           ;  N = 0
   do while N < LEN              /* VHD 3 block size 2**21 (2 MB) */
      TOP = trunc( 100 * N / LEN )
      call charout /**/, x2c( 0D ) N LEN TOP || '%'
      NEW = min( 2**21, LEN - N )
      call charout DST, charin( VHD, N + 1, NEW )
      N = N + NEW                ;  call SysSleep 0
   end
   call stream VHD, 'c', 'close' ;  call charout DST, DAT
   call stream DST, 'c', 'close' ;  say x2c( 0D ) 'created' DST
   return 0

/* -------------------------------------------------------------- */

BACKUP:  procedure
   parse arg VHD
   NEW = lastpos( '/', translate( VHD, '/', '\' ))
   DST = left( VHD, NEW )        ;  NEW = substr( VHD, NEW + 1 )
   NEW = translate( left( NEW, lastpos( '.', NEW ) - 1 ))
   if NEW = 'W2KVPC'       then  NEW = 'W2KTWO'
                           else  NEW = NEW || '-CLONE'
   BAK = NEW || '.bak'           ;  NEW = DST || NEW || '.vhd'
   VHD = stream( NEW, 'c', 'query exists' )
   if VHD = '' then  return qualify( NEW )

   call SysFileDelete DST || BAK
   address CMD '@ren "' || VHD || '" "' || BAK || '"'
   say ' backup:' DST || BAK     ;  return VHD

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   if arg() then  say 'Error:' arg( 1 )
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say 'Usage:' USE 'VHD'
   say                           /* suited for REXXC tokenization */
   say ' Copies some.vhd (a fixed size Virtual Hard Disk image) to'
   say ' some-CLONED.vhd in the same directory with a new VHD UUID'
   say ' and VHD timestamp.  The raw disk image and its (virtual) '
   say ' geometry are kept as is.                                 '
   say ' DISKPART.exe can also do this, but it needs admin rights,'
   say ' simplifies (= clobbers) valid ATA 28-bit disk geometries,'
   say ' and is slower than this script.                          '
   say ' Any old some-CLONED.vhd is kept as some-CLONED.bak with a'
   say ' shell REN (rename) command:  Edit this for your platform.'
   return 1                      /* exit code 1, nothing happened */

/* ----------------------------- (STDERR: unification 2016-03-20) */

PERROR:  procedure
   parse version SAA NUM .       ;  signal off notready
   select
      when  SAA = 'REXXSAA' | 6 <= NUM          /* IBM or ooRexx  */
      then  NUM = lineout( 'STDERR:'  , arg( 1 ))
      when  NUM = 5.00                          /* Regina (maybe) */
      then  NUM = lineout( '<STDERR>' , arg( 1 ))
      otherwise   NUM = 1                       /* other versions */
   end
   if NUM   then  say arg( 1 )   ;  return 1

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

