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
                  then  exit ERROR( 'no VHD:' c2x( left( DAT, 8 )))
   ERR = c2d( substr( DAT, 60 + 1, 4 ))
   if ERR <> 2    then  exit ERROR( 'no fixed VHD:' c2x( ERR ))

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
   call SysFileMove VHD , DST || BAK
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
