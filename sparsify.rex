/* Classic REXX with RexxUtil:  Flag NTFS file as sparse and set  */
/* zero ranges with FSUTIL SPARSE SETFLAG (etc.).  This requires  */
/* admin rights.  Sparse files are a variant of compressed files, */
/* and compressed files cannot be mounted as virtual disks (VHD). */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

/* -------------------------------------------------------------- */

   BLKLEN = 4096                 /* avoid dubious hardwired 65536 */

   FILE = strip( strip( strip( arg( 1 )),, '"' ))
   if verify( FILE, '-/', 'M' ) = 1 then  exit USAGE()
   if FILE = ''                     then  exit USAGE()
   if FILE = '*'                    then  exit TRYIT()
   FILE = stream( FILE, 'c', 'q exists' )
   if FILE = ''                     then  exit USAGE( arg( 1 ))
   return SPARSE( FILE, 0 )

/* -------------------------------------------------------------- */

SPARSE:  procedure expose BLKLEN /* FSUTIL catches various errors */
   parse arg FILE, DEBUG         ;  call SETFLAG FILE, 1
   SEEK = 0                      ;  Z. = -1
   SIZE = stream( FILE, 'c', 'q size' )

   do while SEEK < SIZE          /* get max. runs of zero blocks: */
      L = min( BLKLEN, SIZE - SEEK )
      S = stream( FILE, 'c', 'seek' 1 + SEEK )
      if S <> SEEK + 1  then  exit ERROR( 'seek' SEEK 'failure' S )
      S = charin( FILE,, L )     /* CHARIN SEEK fails, use STREAM */
      SEEK = SEEK + L            /* note next FILE input position */

      if verify( S, d2c( 0 )) = 0   then  do
         if Z.0 < 0  then  Z.0 = SEEK - L
         Z.. = SEEK              /* zero: Z.0 = start, Z.. = end  */
      end
      else  Z.0 = RANGE( FILE, Z.0, Z.., DEBUG )
   end                           /* flag range and invalidate Z.0 */

   Z.0 = RANGE( FILE, Z.0, Z.., DEBUG )
   return SETFLAG( FILE, 0 )     /* the last range can end at EOF */

/* -------------------------------------------------------------- */

SETFLAG: procedure               /* flag FILE or query its ranges */
   parse arg FILE, FLAG          ;  call charout FILE
   if FLAG
      then  address CMD 'FSUTIL SPARSE SETFLAG "'    || FILE || '"'
      else  address CMD 'FSUTIL SPARSE QUERYRANGE "' || FILE || '"'
   return rc

/* -------------------------------------------------------------- */

RANGE:   procedure               /* suggest range of zero sectors */
   parse arg FILE, START, RANGE, DEBUG

   if 0 <= START  then  do       /* let FSUTIL catch access error */
      call charout FILE          ;  RANGE = START ( RANGE - START )
      address CMD 'FSUTIL SPARSE SETRANGE "' || FILE || '"' RANGE
      if DEBUG then  say 'SPARSE SETRANGE' RANGE
   end
   return -1                     /* caller invalidates START = -1 */

/* -------------------------------------------------------------- */

TRYIT:   procedure expose BLKLEN /* verify minimal sparse length: */
   parse source . . SRC          ;  signal off error

   SAV = BLKLEN                  ;  BLKLEN = 512
   BLK = BLKLEN * ( 2 ** 8 )     /* max. cluster size 2**7 < 2**8 */
   T.0 = left( SRC, lastpos( '.', SRC ))
   T.1 = T.0 || 'tmp'            ;  T.0 = T.0 || 'bak'

   if SysFileSystemType( left( SRC, 2 )) <> 'NTFS' then  do
      say 'Test error: Please copy' SRC
      say 'to a writable NTFS directory and run the test there.'
      return 1                   /* error exit (NTFS is required) */
   end

   do SWAP = 0 to 1              /* test zero first and zero last */
      do N = 0 to 1              /* create two empty test files   */
         call charout T.N        ;  call SysFileDelete T.N
         call charout T.N, ''    ;  call charout T.N

         if stream( T.N, 'c', 'q size' ) > 0 then  do
            say 'Test error: cannot create empty' T.N
            if N = 1 then  call SysFileDelete T.0
            return 1             /* error exit (r/w access issue) */
         end
      end N

      R = SETFLAG( T.1, 1 )      ;  if R <> 0   then  leave SWAP

      do N = 3 to 7              /* cluster size 2**3, ..., 2**7  */
         L = copies( d2c( 0 ), BLKLEN * ( 2 ** N ))
         if SWAP  then  L = left(  L || '@' || N, BLK )
                  else  L = right( '@' || N || L, BLK )
         call charout T.0, L     ;  call charout T.1, L
      end N

      say 'SPARSE SETFLAG' T.1   ;  call charout T.0
      L = 5 * BLK '= 5*' || BLK 'bytes with 8, 16, 32, 64, 128'
      if SWAP  then  say L '"zero"-sectors at the begin:'
               else  say L '"zero"-sectors at the end:'

      R = SETFLAG( T.1, 0 )      ;  if R <> 0   then  leave SWAP
      R = SPARSE(  T.1, 1 )      ;  if R <> 0   then  leave SWAP

      do N = 3 to 7              /* compare normal + sparse file: */
         if charin( T.1, BLK ) <> charin( T.0, BLK )  then  do
            say 'Test error: normal and sparse file different at' N
            R = 1                ;  leave SWAP
         end
      end N

      say                        ;  call charout T.0
   end SWAP

   if R = 0 then  do
      say 'Test okay, maybe delete' T.1
      say                        ;  call SysFileDelete T.0
      say 'The shown ranges [offset] [size] contain non-zero'
      say 'bytes; check that there are 1..4 remaining ranges.'
      say 'The smallest hidden zero-range size should be at'
      say 'least' SAV '(otherwise edit BLKLEN in the source).'
      return 0
   end

   say 'Test error:' R || ', check normal *.bak vs. sparse' T.1
   return R                      /* test files T.0 and T.1 kept   */

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE '[file|*]'
   say                           /* suited for REXXC tokenization */
   say ' Uses FSUTIL.exe to flag "zero" clusters in an NTFS file. '
   say ' FSUTIL SPARSE requires NTFS and admin rights, also see   '
   say ' FSUTIL SPARSE QUERYFLAG|SETFLAG|QUERYRANGE|SETRANGE      '
   say
   say ' Argument * starts some quick sanity tests with two files '
   say ' in the directory (must be on NTFS) of' USE 'with'
   say ' 8, 16, 32, 64, and 128 zero-sectors at the begin or end  '
   say ' of 5 test ranges (5*256*512=655360 bytes) to verify the  '
   say ' used block length (min. 8*512=4096, max. 128*512=65536). '
   say ' NTFS cluster size 8 (4096 bytes) supports all multiples  '
   say ' of 65536 zero bytes (128 zero-sectors) as a sparse range.'
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

