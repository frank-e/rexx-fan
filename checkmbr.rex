/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with REXXUTIL     */

/* Check physical drive partition table and any FAT boot records. */
/* There is no "fix" mode; this is not a repair tool.  The script */
/* tries to identify unused sectors within existing partitions.   */
/* MBR (master boot record), EBRs (MBRs of extended partitions),  */
/* and FAT or NTFS boot sectors are copied to the log file.       */

/* Limitations:                                                   */
/* - The CHS output format is suited for disks up to 766 GB with  */
/*   a geometry of 255 heads and 63 sectors.  It still works up   */
/*   to 7660 GB.  Beyond that cylinder numbers are truncated.     */
/* - The CHS input format for cylinder numbers treats 99999 as a  */
/*   "don't care" value; more cylinders are reduced to 99999.     */
/*   Any unpartitioned space at the end of a disk is only shown   */
/*   if CHS is specified with a cylinder number C < 99999.  The   */
/*   script does not determine or check the physical disk size.   */
/* - FORMAT /A:128K and FORMAT /A:256K require sector size 1024   */
/*   or 2048 for the maximal FAT or NTFS cluster size 128 (80h).  */

/* Fixes and features added in 2011-07:                           */
/* - The max. cluster numbers for FAT12/16/32 were "off by one",  */
/*   the limits are now hardwired as 4084, 65524, and 268435444.  */
/* - Added partition type 27h "WinRE" for hidden windows recovery */
/*   partition and file system NTFS.                              */
/* - UEFI disks start with a protective MBR (partition type EE),  */
/*   this is now reported, but checkMBR analyzes only MBR disks.  */
/* - VFD (virtual floppy disk) and fixed VHD (virtual hard disk)  */
/*   files can now be given instead of a physical driver number.  */
/* - The VHD footer CHS values are used to populate CHS if no CHS */
/*   values are specified.  Typically this will not match the CHS */
/*   geometry of the raw disk image in the VHD.  The warning for  */
/*   this mismatch can be ignored.  Use CHS 99999 255 63 to avoid */
/*   this warning for a (virtual) disk geometry * 255 63.         */
/* - Hidden Linux extended partition ID 85 added, allowed in MBR  */
/*   for second or hidden chain of extended partitions: UNTESTED. */
/* - Errors for a broken unpartitioned FAT with seven sectors now */
/*   handled.  Don't try to fill removable media with dummy FATs, */
/*   it triggers odd bugs in Windows 7 diskpart.exe among others. */

/* Fixes and features added in 2011-08:                           */
/* - The CHS geometry "guess" now picks the first plausible value */
/*   instead of any "max. C+1 H+1 S values seen in MBR" geometry. */
/* - First FAT32 backup boot sector now reported if different.    */
/* - NTFS output now reports a "boot cluster", any unused sectors */
/*   in this cluster for cluster sizes > 1 are not more reported. */
/* - Extended partitions 05h/0Fh and Linux extended 85h sorted by */
/*   LBA (logical sector number) instead of "first come".         */
/* - Emulated SEEK > 2 GB for ooREXX 3.2 (language level < 6.03)  */
/*   removed:  Sorry, but this simplified the code significantly. */
/* - Added drive letter support based on `MOUNTVOL X: /L` output. */
/*   This fails on most volumes, e.g., CDFS is not yet supported. */

/* Fixes and features added in 2011-10:                           */
/* - It turned out that Microsoft didn't bother to follow the FAT */
/*   specification published by ECMA and Microsoft.  If there are */
/*   precisely 4085 clusters Windows 7 CHKDSK handles the volume  */
/*   as FAT12 corrupting a valid FAT16.  Likewise CHKDSK expects  */
/*   a FAT16 for 65525 clusters.  CHKDSK does not corrupt a valid */
/*   FAT32 with 65525 clusters, it dies with an internal error.   */
/* - Workaround:  Assume FAT12 for 4085 clusters if the FAT size  */
/*   is too small for FAT16, and assume FAT16 for 65525 clusters  */
/*   if the FAT size is too small for FAT32.  Otherwise stick to  */
/*   the specification.                                           */
/* - Microsoft's FAT32 specification is rather funny, but claims  */
/*   that FAT32 can address a NOT RECOMMENDED cluster 268435447.  */
/*   This is "off by one", cluster 268435446 is the odd beast, it */
/*   corresponds to the last of 268435445 data clusters.          */
/* - I've added some UNTESTED code for EXFAT.  This can result in */
/*   confusing EXFAT details for a partition incorrectly reported */
/*   as NTFS, but at least it won't report NTFS errors for EXFAT. */
/* - HPFS is also UNTESTED, and the added NTFS $MFT and $MFTmirr  */
/*   plausibility checks are presumably not applicable for HPFS.  */
/* - FWIW the plausibility of a media descriptor is now verified. */
/* - An unusual position of the FAT32 FSinfo sector could trigger */
/*   a spurious warning:  Is 0 < backup boot < FSinfo allowed ?   */
/* - The forensic tool test case for an extended partition with   */
/*   more than one primary partition apparently works, the output */
/*   flags it as "bad", but the next extended partition is shown. */
/*   Actually this means that extended partitions with more than  */
/*   one primary partition are supposed to work for all operating */
/*   systems, "fascinating".                                      */
/* - The sector size can now be given, default 512.  For a VHD it */
/*   must be 512.  PC DOS 5+ sector sizes 32 and 64 are not (yet) */
/*   supported.  In theory Windows NT supports 2**7, ..., 2**12.  */
/*   In practice MBR and FAT boot code might still insist on 512. */
/* - A spurious FAT12 with no clusters and no FAT is now reported */
/*   correctly, but triggers an internal Windows NT CHKDSK error. */

/* Fixes and features added in 2016-03:                           */
/* - One REGUTIL() instead of some RexxUtil UTIL() registrations. */
/* - New PERROR() for Regina '<STDERR>' or SAA/oo Rexx 'STDERR:'. */
/* - New ERROR() handler for REXX 5.00 (Regina) replaced TRAP().  */
/* - New RXLIFO() to get command output (here 'MOUNTVOL.exe') in  */
/*   a Rexx queue.  Regina needs ADDRESS SYSTEM, and ooRexx 6.04  */
/*   does not yet support the better Rexx 5.00 ADDRESS .. WITH .. */
/* - Annotated DEPART() partition table entry decoder.  The old   */
/*   CHS code 0+8,8,2+6 to 2+8,8,0+6 was hard to read (but okay). */
/* - Better VHD support:  Swap H <= 16 and S to get S <= 63, and  */
/*   interpret dummy CHS 65535 16 255 as dummy CHS 99999 255 63.  */

/* Fixes and features added in 2020-03:                           */
/* - Improved PERRR() + ERROR() portability wrappers for Regina.  */

/* FAT considerations:                                            */
/* Cluster numbers for FAT32 use 28 bits.   This results in up to */
/* x2d( 0FFF FFF6 ) = 268435446 clusters including the two start  */
/* entries for 0 and 1.  Each FAT32 entry occupies 32 bits for a  */
/* maximum of 2097152 FAT sectors.  With x2d( 200000 ) = 2097152  */
/* the number of sectors per FAT in the boot sector does not fit  */
/* into two bytes at offset 22 and was moved to offset 36 (32bit  */
/* directly after the BIGFAT 32bit number of sectors).            */

/* NTFS stores the number of sectors (excl. boot) as 64bit value  */
/* at offset 40.  FAT32 version 0 sticks to 32bit values and is   */
/* therefore limited to max. 2048 GB (2 TB) for cluster size 16:  */

/*  FAT12     1 ..      4084 clusters:   1 ..      12 FAT sectors */
/*  FAT16  4085 ..     65524 clusters:  16 ..     256 FAT sectors */
/*  FAT32 65525 .. 268435444 clusters: 512 .. 2097152 FAT sectors */
/*  FAT12 min.:    1 *         1                  512 (  0.5 KB)  */
/*  FAT16 min.:    1 *      4085            2,091,520 ( 2043 KB)  */
/*  FAT32 min.:    1 *     65525           33,548,800 (32763 KB)  */
/*  FAT12 max.:   64 *      4084          133,824,512 (~ 127 MB)  */
/* [FAT12 max.:  128 *      4084          267,694,024 (~ 255 MB)] */
/*  FAT16 max.:   64 *     65524        2,147,090,432 (~2047 MB)  */
/* [FAT16 max.:  128 *     65524        4,294,180,864 (~4095 MB)] */
/*  FAT32 max.:    8 * 268435444    1,099,511,578,624 (~1024 GB)  */
/*  FAT32 max.:   16 * 268173557    2,196,877,778,944 (~2046 GB)  */
/* [FAT32 max.:   32 * 134152181    2,197,949,333,504 (~2047 GB)] */
/* [FAT32 max.:   64 *  67092469    2,198,486,024,192 (~2047 GB)] */
/* [FAT32 max.:  128 *  33550325    2,198,754,099,200 (~   2 TB)] */

/* CHS considerations:                                            */
/* In 2002 ATA-6 stated that CHS addressing is obsolete.  In fact */
/* the 24=10+8+6 INT 13h CHS bits or the 24=14+4+6 ATA-5 bits are */
/* pointless for disks with more than 8064 MB (sic!).  Worse, the */
/* 32 bits LBA values in the MBR partition table can handle disks */
/* up to 2 TB for sector size 512.  The "advanced format" using   */
/* sector size 4096 still emulates logical size 512 (aka "512e"). */
/* MBRs don't record the disk geometry and sector size, therefore */
/* disks larger than 2 TB (2 TeraByte=4*1024*1024*1024*512 bytes) */
/* require the newer UEFI partitioning scheme.                    */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

   if 6 <= REXX   then  do       /* ooRexx 3.2 SEEK limit is 2 GB */
      if REXX < 6.03 then  exit USAGE( 'ooRexx' REXX 'SEEK < 2 GB' )
   end

   /* ----------------- check arguments ------------------------- */
   parse upper arg P C H S L R

   GSS  = 2**7 2**8 2**9 2**10 2**11 2**12
   GNOT = 99999                        ;  G.1 = 1 + length( GNOT )
   GNOS = 0                            ;  G.2 = 1 + length( 256 )
   GSPT = 0                            ;  G.3 = 1 + length( 63 )
   EXPO = 'GIN GNOT GNOS GSPT GSS G.'

   N = length( P )
   select
      when  N = 0 | sign( pos( '?', P ))  then  exit USAGE()
      when  N = 1                         then  do
         if verify( P, '0123456789' )     then  exit USAGE( P )
         GIN = '\\.\PHYSICALDRIVE' || P
      end                              /* drive number P to phys. */
      when  N = 2 & right( P, 1 ) = ':'   then  do
         Q = queued()                  /* drive letter P: to GUID */
         X = RXLIFO( 'mountvol' P '/L' )
         do while queued() > Q
            parse pull X               ;  X = strip( X )
         end
         if abbrev( X, '\\?\Volume' ) = 0 then  exit USAGE( P X )
         GIN = left( X, length( X ) - 1 )
      end
   otherwise
      if abbrev( P, '"' )  then  parse arg '"' P '"' C H S L R
                           else  parse arg     P     C H S L R
      GIN = stream( strip( P ), 'c', 'query exists' )
      if GIN = ''          then  exit USAGE( 'found no' P )
      P = translate( substr( GIN, lastpos( '.', GIN )))
      if L = ''   then  L = 512
      select
         when  P = '.VHD'  then  do    /* VHD requires ooREXX 4.x */
            if L <> 512
               then  exit  USAGE( 'VHD requires 512, got' L )
            P = stream( GIN, 'c', 'query size' )
            if wordpos( P // 512, 0 511 ) = 0
               then  exit USAGE( 'invalid VHD size' P )
            N = stream( GIN, 'c', 'open read' )
            N = ( P - 512 + sign( P // 512 )) / 512
            X = stream( GIN, 'c', 'seek' ( N * 512 + 1 ))
            P = charin( GIN, /* @N+1 */, 511 )
            if abbrev( P, 'conectix' ) = 0
               then  exit USAGE( 'missing VHD cookie' )
            X = c2d( substr( P, 61, 4 ))
            if X <> 2                  /* @60: VHD type, 2 fixed  */
               then  exit USAGE( 'not a fixed VHD' d2x( X ))
            X = c2d( substr( P, 49, 8 ))
            if X <> N * 512            /* @48: VHD current size   */
               then  exit USAGE( X / 512 '<>' N 'sectors' )
            if C = ''   then  do       /* @56: VHD geo. 28=16+4+8 */
               C = c2d( substr( P, 56 + 1, 2 )) /* C in ATA C H S */
               H = c2d( substr( P, 56 + 3, 1 )) /* H in ATA C H S */
               S = c2d( substr( P, 56 + 4, 1 )) /* S in ATA C H S */
               X = C * H * S
               select
                  when  H > 16
                  then  exit USAGE( H > '16 heads (ATA 28=16+4+8)' )
                  when  X = 65535 * 16 * 255    /* dummy FFFF10FF */
                  then  parse value 99999 255 63   with C H S
                  when  X > N          /* non-existing sectors    */
                  then  exit USAGE( X '>' N 'sectors :' C H S )
                  when  X = N & S > 63 /* swap H and S for S < 64 */
                  then  parse value 99999 S H      with C H S
                  otherwise   nop      /* X < N can be a rounding */
               end                     /* issue (it is not a HPA) */
            end
         end
         when  sign( wordpos( P, '.VFD .IMA .IMG .DSK' ))   then  do
            P = stream( GIN, 'c', 'query size' )
            if P // L <> 0 then  exit USAGE( 'VFD size' P )
         end
         otherwise   exit USAGE( P 'is not a VFD/VHD or 0..9' )
      end
   end

   if L <> ''  then  N = wordpos(   L, GSS )
               else  N = wordpos( 512, GSS )
   if N > 0    then  GSS = word( GSS, N )
               else  exit USAGE( L '- use' GSS )
   if C <> ''  then  do
      if C = '*'                          then  C = GNOT
      if C = GNOT & H = ''                then  H = 255
      if C = GNOT & S = ''                then  S = 63
      if datatype( C, 'w' ) = 0 | C <= 0  then  exit USAGE( C )
      if datatype( H, 'w' ) = 0 | H <= 0  then  exit USAGE( H )
      if datatype( S, 'w' ) = 0 | S <= 0  then  exit USAGE( S )
      if S > 63      then  exit USAGE( S '- use 1..63' )
      if H > 256     then  exit USAGE( H '- use 1..256' )
      if R <> ''     then  exit USAGE( R )
      GNOT = min( C, GNOT )            ;  GNOS = H
      GSPT = S
   end

   /* ----------------- read master boot record ----------------- */
   INSEC = IN55AA( 0, 'partition table' )
   if INSEC = ''  then  exit 1         /* access error not logged */

   IN.1 = 0 BASE64( INSEC )            ;  IN.0 = 1
   EXPO = EXPO OPENLOG( arg( 1 ))      /* open and expose LOGFILE */

   if sign( wordpos( c2x( left( INSEC, 1 )), 'EB E9' ))  then  do
      X = substr( INSEC, 55, 8 )       /* check FAT12, FAT16, FAT */
      N = abbrev( X, 'FAT' ) & right( X, 3 ) ==  '   '
      N = N | ( 'FAT32   ' == substr( INSEC, 83, 8 ))
      X = substr( INSEC, 4, 61 )
      if N | ( X == left( 'EXFAT   ', 61, x2c( 0 )))  then  do
         if BOOTFAT( INSEC )  then  exit STOPLOG()
      end                              /* unpartitioned FAT drive */
   end                                 /* NTFS always partitioned */

   if GSPT = 0 then  do                /* guessing drive geometry */
      do N = 1 to 4  while GSPT = 0
         X = DEPART( substr( INSEC, 431 + 16 * N, 16 ))
         parse var X . P C H S R D I T L
         if P = 00 | L = 0 | S = 0 | T = 0 | C = D then  iterate N
         P = R + L - 1

         do GNOS = 256 to 1 by -1      /* C <> D permits a guess, */
            do GSPT = 63 to 8 by -1    /* assume 8 <= GSPT <= 63  */
               if ( C H S R ) = GEOPLUS( C H S, 0 )   then  do
                  X = GEOPLUS( C H S, L - 1 )
                  if ( D I T P ) = X         then  leave N
                  if T <> GSPT | GSPT <> 63  then  iterate GSPT
                  if D <> 1023 | GNOS < 255  then  iterate GSPT
                  if I <> GNOS - 1           then  iterate GSPT
                  if P > 1024 * GNOS * 63    then  leave N
               end
            end GSPT
         end GNOS
         GSPT = 0
      end N
      if GSPT < 8 then  exit USAGE( 'try C H S = 99999 255 63' )
   end

   X    = c2x( REVSUB( INSEC, 431 + 10, 4 ))
   IN.. = '[' || left( X, 4 ) || '-' || right( X, 4 ) || ']'
   X    = '(assume geometry CHS' || right( GNOT, G.1 )
   X    =  X || right( GNOS, G.2 ) || right( GSPT, G.3 ) || ')'
   call OUTPUT DRIVE19( GIN ) X 'id.' IN..
   call OUTPUT '   MBR' LINEND( 0 0 1 0 0 0 1 1 )

   /* ----------------- check partition table ------------------- */
   BASE  = 0                           ;  EXTRA = 0
   NEXT  = 1                           ;  EXEND = 0
   START = 0                           ;  LINUX = 0
   PART  = 4                           ;  ID85H = 0
   call DECODE INSEC, 0                ;  S.0 = 0
   do N = 1 to 4
      parse var PART.N B ID C H S R D I T L X
      ERR = GEOPART( NEXT, R, ID, BASE )
      select                           /* if start partition flag */
         when  START = 0 & B == 80  then  do
               START = X               ;  X = X || ':*' || ID || ':'
         end
         when              B <> 00  then  do
               ERR = 1                 ;  X = X || ':?' || ID || ':'
         end
         otherwise                        X = X || ': ' || ID || ':'
      end
      if ID <> 00 then  do
         Y = GEOTEST( C H S R D I T L, BASE )
         parse var Y C H S D I T       ;  NEXT = R + L
      end
      else  ERR = ERR | ( C + H + S + R + D + I + T + L <> 0 )
      if FSTYPE( ID ) == '=> EXT' | ID == 85 then  select
         when  ID <> 85 & EXTRA <> 0   then  ERR = 1
         when  ID == 85 & LINUX <> 0   then  ERR = 1
         when  ID == 85 then  do       /* Linux (second) extended */
            LINUX = R                  ;  ID85H = NEXT
         end
         otherwise                     /* note extended partition */
            EXTRA = R                  ;  EXEND = NEXT
      end
      X = X LINEND( C H S R D I T L )
      if ERR = 0  then  do
         call OUTPUT X FSTYPE( ID )    ;  K = S.0 + 1
         S.0 = K                       /* note 1..4 for TESTFAT() */
         S.K = ID C H S R D I T L BASE N
      end
      else  call OUTPUT X 'bad'        /* dubious: skip TESTFAT() */
   end N
   X = ''
   if GNOT <> 99999  then  do          /* assume GNOT is no dummy */
      C = GNOT - 1                     ;  H = GNOS - 1
      parse value GEOPLUS( C H GSPT, 1 ) with C H S R
      if GEOPART( NEXT, R, -1, BASE )  then  X = 'bad'
                                       else  NEXT = R
   end
   EXTRA = TOTALS( EXTRA, BASE, NEXT, X )
   NEXT = 1                            /* relative sector numbers */

   /* ----------------- get extended partitions ----------------- */
   if 0 < LINUX & LINUX < EXTRA  then  do
      parse value LINUX EXTRA with EXTRA LINUX
      parse value ID85H EXEND with EXEND ID85H
   end                                 /* LINUX type 85h UNTESTED */
   parse value EXPART( EXTRA, EXEND, NEXT, PART ) with NEXT PART
   parse value EXPART( LINUX, ID85H, NEXT, PART ) with NEXT PART

   /* ----------------- check FAT and NTFS boot records --------- */
   X = 1
   do N = 1 to S.0
      if X  then  call OUTPUT          ;  X = TESTFAT( S.N )
   end N
   exit STOPLOG()

/* -------------------------------------------------------------- */
EXPART:  procedure expose (EXPO) IN. S.
   parse arg EXTRA, EXEND, NEXT, PART

   do PART = PART while EXTRA <> 0     /* shown as 5+6, 6+7, etc. */
      INSEC = IN55AA( EXTRA, 'extended partition' )
      if INSEC = ''  then  leave PART

      parse value GEOPLUS( 0 0 1, EXTRA ) with C H S BASE
      call OUTPUT '=> EXT' LINEND( C H S 0 C H S 1 )
      call DECODE INSEC, PART          ;  EXTRA = 0
      N = IN.0 + 1                     ;  IN.0 = N
      IN.N = BASE BASE64( INSEC )

      do N = 1 to 4
         parse var PART.N B ID C H S R D I T L X
         TAG = X
         ERR = GEOPART( NEXT, R, ID, BASE )
         if B <> 00  then  do          /* dubious start partition */
            ERR = 1                    ;  X = X || ':?' || ID || ':'
         end
         else                             X = X || ': ' || ID || ':'
         if ID <> 00 then  do
            Y = GEOTEST( C H S R D I T L, BASE )
            parse var Y C H S D I T    ;  NEXT = R + L
         end
         else  ERR = ERR | ( C + H + S + R + D + I + T + L <> 0 )
         if FSTYPE( ID ) = '=> EXT' then  if EXTRA = 0
            then  EXTRA = R            ;  else  ERR = 1
         select                        /* expect one non-extended */
            when  N > 2 & ID <> 00     then  ERR = 1
            when  N = 2 & ID == 00     then  nop
            when  N = 2 & EXTRA = 0    then  ERR = 1
            otherwise                        nop
         end
         if ID <> 00 | N <= 2 then  do /* skip unused parts 3 + 4 */
            X = X LINEND( C H S R D I T L )
            if ERR   then  call OUTPUT X 'bad'
                     else  call OUTPUT X FSTYPE( ID )
            K = S.0 + 1                ;  S.0 = K
            S.K = ID C H S R D I T L BASE TAG
         end
      end N
      X = ''
      if EXTRA = 0   then  do          /* check last unused space */
         R = EXEND - BASE              /* relative to actual BASE */
         if GEOPART( NEXT, R, -1, BASE )  then  X = 'bad'
                                          else  NEXT = R
      end
      EXTRA = TOTALS( EXTRA, BASE, NEXT, X )
      NEXT = 1                         /* relative sector numbers */
   end PART

   return NEXT PART

/* -------------------------------------------------------------- */
BOOTFAT: procedure expose (EXPO) IN.   /* unpartitioned FAT drive */
   parse arg INSEC                     /* TOTAL incl. boot sector */

   X = '20 33 73'                      ;  LEN = 1
   do N = 1 to 3 until TOTAL <> 0
      OFS = word( X, N )               ;  LEN = 2 * LEN
      TOTAL = c2d( REVSUB( INSEC, OFS, LEN ))
   end                                 /* NTFS offset not checked */
   if TOTAL = 0   then  return 0       /* maybe not a boot sector */

   if GSPT = 0    then  do             /* undefined disk geometry */
      X = ( LEN < 8 )                  /* EXFAT gets 99999 255 63 */
      S = c2d( REVSUB( INSEC, 25, 2 )) * X +  63 * ( 1 - X )
      H = c2d( REVSUB( INSEC, 27, 2 )) * X + 255 * ( 1 - X )
      if S = 0 | S > 63 | H = 0 | H > 256 then  return 0
      GSPT = S                         ;  GNOS = H
   end

   X = right( GNOT, 5 ) right( GNOS, 3 ) right( GSPT, 2 )
   X = DRIVE19( GIN ) '(assume geometry CHS' X || ')'
   call OUTPUT X 'UNPARTITIONED'

   parse value GEOPLUS( 0 0 1, TOTAL ) with C H S X
   return TESTFAT( '??' 0 0 1 0 C H S TOTAL 0 ) /* ?? for TESTFAT */

/* -------------------------------------------------------------- */
REVSUB:  return reverse( substr( arg( 1 ), arg( 2 ), arg( 3 )))

/* -------------------------------------------------------------- */
DRIVE19: procedure                     /* truncates long VHD path */
   parse arg N                         /* (for first output line) */
   if length( N ) > 22  then  N = '...' || right( N, 19 )
   return left( N, 22 )

/* -------------------------------------------------------------- */
FSTYPE:  procedure                     /* simplified file system  */
   parse arg X                         /* names (often ambiguous) */
   if X == 00           then  return 'unused'
   if X == 01 | X == 11 then  return 'FAT12'    /* 11: hidden 01  */
   if X == 04 | X == 14 then  return 'FAT16'    /* 14: hidden 04  */
   if X == 05 | X == 0F then  return '=> EXT'   /* 05 CHS, 0F LBA */
   if X == 06 | X == 16 then  return 'bigFAT'   /* 16: hidden 06  */
   if X == 07 | X == 17 then  return 'NTFS'     /* could be HPFS  */
   if X == 27           then  return 'NTFS'     /* WinRE (hidden) */
   if X == 0A           then  return 'bootOS'   /* OS/2 manager   */
   if X == 0B | X == 1B then  return 'FAT32'    /* CHS (C < 1024) */
   if X == 0C | X == 1C then  return 'FAT32'    /* LBA FAT32      */
   if X == 0E | X == 1E then  return 'VFAT'     /* LBA bigFAT     */
   if X == 12 | X == 98 then  return 'ROMDOS'   /* (98 can be 0C) */
   if X == 42           then  return 'W2Kdyn'   /* (could be SFS) */
   if X == 80 | X == 81 then  return 'Minix'    /* 80: NTFT   (?) */
   if X == 85           then  return 'LinEXT'   /* Linux extended */
   if X == 'A8'         then  return 'Darwin'   /* Darwin UFS (?) */
   if X == 'DB'         then  return 'CP/M'     /* concurrent DOS */
   if X == 'DE'         then  return 'DELL'     /* apparently FAT */
   if X == 'EE'         then  return '(EFI)'    /* EFI pseudo-MBR */
   if X == 'EF'         then  return 'EFIFAT'   /* EFI (12/16/32) */
   if sign( wordpos( X, '82 83    8E'    ))  then  return 'Linux'
   if sign( wordpos( X, '63 A5 A6 A9'    ))  then  return 'Unix'
   if sign( wordpos( X, '65 67 68 69'    ))  then  return 'Novell'
   if sign( wordpos( X, 'BE BF'          ))  then  return 'SolSun'
   if sign( wordpos( X, '      C0 D0'    ))  then  return 'Real32'
   if sign( wordpos( X, '   CF C5 D5'    ))  then  return 'SecExt'
   if sign( wordpos( X, '      C1 D1 E1' ))  then  return 'FAT12'
   if sign( wordpos( X, '84    C4 D4 E4' ))  then  return 'FAT16'
   if sign( wordpos( X, '86 B6 C6 D6'    ))  then  return 'bigFAT'
   if sign( wordpos( X, '87 B7 C7 D7'    ))  then  return 'NTFS'
   if sign( wordpos( X, '8B 8C BC CB CC' ))  then  return 'FAT32'
   if sign( wordpos( X, 'E2 E3'          ))  then  return 'r/oDOS'
   if sign( wordpos( X, '02 03    FF'    ))  then  return 'Xenix'
   return ''

/* -------------------------------------------------------------- */
TESTFAT: procedure expose (EXPO) IN.   /* check FATxx boot sector */
   arg P C H S R D I T L AS PART       ;  AS = AS + R
   Q = P                               /* keep original ID in P   */

   if sign( wordpos( Q, '12 98 C0 D0 DB DE E2 E3 EF' ))
      then  Q = '??'                   /* undetermined FAT values */
   N =   '1B 1C 1E CB CC CE'           /* hidden form of 0B 0C 0E */
   N = N '8B 8C    BC CB CC'           /* handle as 0B 0C FAT32 ? */
   N = N '11 E1       C1 D1'           /* interpret as 01 FAT12   */
   N = N '14 E4 84    C4 D4'           /* interpret as 04 FAT16   */
   N = N '16 E6 86 B6 C6 D6'           /* interpret as 06 BIGFAT  */
   N = N '17 27 87 B7 C7'              /* interpret as 07 NTFS    */
   N = wordpos( Q, N )
   if 0 < N  then Q = overlay( 0, Q )  /* 0[1467BCE] : ?[1467BCE] */

   FAT = ( Q <> 07 )                   /* 0: NTFS or HPFS, 1: FAT */
   if FAT > pos( Q, '01 04 06 0B 0C 0E ??' )       then  return 0
   PRINT = xrange( x2c( 20 ), x2c( 7E ))

   /* ----------------- read FAT boot sector -------------------- */
   if PART = ''   then  PART = 'volume'
                  else  PART = left( PART || ':', 2 ) P || ':'
   TAG = FSTYPE( P )
   call OUTPUT PART LINEND( C H S AS D I T L ) TAG
   if PART <> 'volume'  then  TAG = PART
   INSEC = IN55AA( AS, TAG 'boot record' )
   if INSEC = ''  then  return 1       /* 1: some lines written   */

   select                              /* FAT32 or NTFS are HUGE: */
      when  sign( wordpos( Q, '07 0B 0C' ))        then  HUGE = 1
      when  sign( wordpos( Q, '01 04 06 0E' ))     then  HUGE = 0
      when  abbrev( substr( INSEC, 55 ), 'FAT' )   then  HUGE = 0
      otherwise                                          HUGE = 1
   end
   EXFAT = ( substr( INSEC, 12, 53 ) == copies( x2c( 0 ), 53 ))
   if EXFAT then  select
      when  HUGE = 0 then  EXFAT = 0   /* EXFAT is HUGE (P = 07)  */
      when  P = '??' then  FAT   = 0   /* EXFAT is no FAT32       */
      when  FAT      then  EXFAT = 0   /* FAT32 is no EXFAT       */
      otherwise   nop                  /* EXFAT is most plausible */
   end

   /* ----------------- collect BPB values ---------------------- */
   EB = c2x( substr( INSEC,  1,  1 ))  /* EB (jmp short) or E9    */
   EC =    ( substr( INSEC,  2,  2 ))  /* EB offset + NOP (90h)   */
   XT =    ( substr( INSEC,  4,  8 ))  /* NTFS, EXFAT, or OEM id. */
   SL = c2d( REVSUB( INSEC, 12,  2 ))  /* sector length           */
   CS = c2d( substr( INSEC, 14,  1 ))  /* cluster size            */
   BS = c2d( REVSUB( INSEC, 15,  2 ))  /* reserved sectors        */
   FN = c2d( substr( INSEC, 17,  1 ))  /* FAT copies              */
   RN = c2d( REVSUB( INSEC, 18,  2 ))  /* root entries     (or 0) */
   VS = c2d( REVSUB( INSEC, 20,  2 ))  /* 16bit sectors    (or 0) */
   F8 = c2x( substr( INSEC, 22,  1 ))  /* media descriptor        */
   FS = c2d( REVSUB( INSEC, 23,  2 ))  /* FAT12/16 sectors (or 0) */
   TS = c2d( REVSUB( INSEC, 25,  2 ))  /* sectors per track       */
   HN = c2d( REVSUB( INSEC, 27,  2 ))  /* number of heads (sides) */
   HS = c2d( REVSUB( INSEC, 29,  4 ))  /* hidden sectors          */
   WS = c2d( REVSUB( INSEC, 33,  4 ))  /* 32bit sectors    (or 0) */
   FX = c2d( REVSUB( INSEC, 37,  4 ))  /* FAT32 sectors (FS == 0) */
   FF =    ( REVSUB( INSEC, 41,  2 ))  /* FAT32 flags             */
   VX = c2x( REVSUB( INSEC, 43,  2 ))  /* FAT32 version (0)       */
   RX = c2d( REVSUB( INSEC, 45,  4 ))  /* FAT32 root (2) cluster  */
   IX = c2d( REVSUB( INSEC, 49,  2 ))  /* FAT32 info (1) sector   */
   BX = c2d( REVSUB( INSEC, 51,  2 ))  /* FAT32 copy (6) sector   */
   RZ = c2x( substr( INSEC, 53, 12 ))  /* FAT32 reserved zero     */
   DL = c2x( substr( INSEC, 65,  1 ))  /* INT 13h DL 00h or 80h   */
   CD = c2d( substr( INSEC, 66,  1 ))  /* chkdsk flags (0,1,2,3)  */
   MX = c2x( substr( INSEC, 67,  1 ))  /* FAT32 magic 29h         */
   SX = c2x( REVSUB( INSEC, 68,  4 ))  /*   volume serial         */
   LX =    ( substr( INSEC, 72, 11 ))  /*   volume label          */
   TX =    ( substr( INSEC, 83,  8 ))  /*   volume FSType         */
   IP = 91 - 1                         /* normal boot code offset */

   select
      when  FAT & HUGE     then  do    /* adjust value for FAT32: */
         if FS <> 0        then  do
            X = 'inconsistent or redundant FAT32 sectors' FS FX
            call OUTPUT X
         end                           /* use FX <> 0 as FAT32 FS */
         if FX <> 0        then  FS = FX
      end
      when  FAT > HUGE     then  do    /* adjust values for FAT1x */
         DL = c2x( substr( INSEC,  37,  1 )) /* INT 13h DL 00/80  */
         CD = c2d( substr( INSEC,  38,  1 )) /* chkdsk (0,1,2,3)  */
         MX = c2x( substr( INSEC,  39,  1 )) /* magic 29h or 28h: */
         SX = c2x( REVSUB( INSEC,  40,  4 )) /* [ volume serial   */
         LX =    ( substr( INSEC,  44, 11 )) /*   volume label    */
         TX =    ( substr( INSEC,  55,  8 )) /*   volume FSType ] */
         select
            when  MX = 29  then  IP = 63 - 1 /* min. MX = 29 code */
            when  MX = 28  then  IP = 44 - 1 /* min. MX = 28 code */
            otherwise            IP = 39 - 1 /* other code offset */
         end                           /* TBD: no LX/TX for MX 28 */
      end
      when  HUGE > EXFAT   then  do    /* adjust values for NTFS: */
         TX = XT                       /* no OEM id.: "NTFS    "  */
         drop MX LX XT FX              /* throw NOVALUE if used   */
         VS = max( VS, WS )            /* use 16 or 32bits VS = 0 */
         DL = c2x( substr( INSEC,  37, 1 ))  /* INT 13h DL 00/80  */
         CD = c2d( substr( INSEC,  38, 1 ))  /* chkdsk (0,1,2,3)  */
         X  = c2x( REVSUB( INSEC,  39, 2 ))  /* boot code scratch */
         WS = c2d( REVSUB( INSEC,  41, 8 ))  /* total sectors - 1 */
         M1 = c2d( REVSUB( INSEC,  49, 8 ))  /* cluster $MFT      */
         M2 = c2d( REVSUB( INSEC,  57, 8 ))  /* cluster $MFTmirr  */
         X  = c2d( REVSUB( INSEC,  65, 4 ))  /* clusters per FRS  */
         X  = c2d( REVSUB( INSEC,  69, 4 ))  /* clusters per IB   */
         SX = c2x( REVSUB( INSEC,  73, 4 ))  /* volume serial low */
         X  = c2x( REVSUB( INSEC,  77, 4 ))  /* volume serial hi  */
         X  = c2d( REVSUB( INSEC,  81, 4 ))  /* unclear checksum  */
         IP = 85 - 1                   /* normal boot code offset */
      end
      when  HUGE & EXFAT   then  do    /** EXFAT code not tested **/
         TX = XT                       /* no OEM id.: "EXFAT   "  */
         VS = 0                              /* dummy VS = 0 test */
         RN = 0                              /* dummy RN = 0 dir. */
         BX = 12                             /* known BX backup   */
         drop MX LX XT FX F8 IX              /* NOVALUE assertion */
         HS = c2d( REVSUB( INSEC,  65, 8 ))  /* hidden sectors    */
         WS = c2d( REVSUB( INSEC,  73, 8 ))  /*  total sectors    */
         BS = c2d( REVSUB( INSEC,  81, 4 ))  /*   boot sectors    */
         FS = c2d( REVSUB( INSEC,  85, 4 ))  /*  EXFAT sectors    */
         E1 = c2d( REVSUB( INSEC,  89, 4 ))  /* E1 + E2 * CS = WS */
         E2 = c2d( REVSUB( INSEC,  93, 4 ))  /* E2 data clusters  */
         RX = c2d( REVSUB( INSEC,  97, 4 ))  /* root dir. cluster */
         SX = c2d( REVSUB( INSEC, 101, 4 ))  /* volume serial id. */
         VX = c2x( REVSUB( INSEC, 105, 2 ))  /* EXFAT version (1) */
         FF =    ( REVSUB( INSEC, 107, 2 ))  /* EXFAT flags       */
         CD = c2d( bitand( FF, x2c( '0006' ))) % 2
         SL = c2d( substr( INSEC, 109, 1 ))  /*  sector size 2**N */
         CS = c2d( substr( INSEC, 110, 1 ))  /* cluster size 2**N */
         FN = c2d( substr( INSEC, 111, 1 ))  /* EXFAT copies 1..2 */
         DL = c2x( substr( INSEC, 112, 1 ))  /* INT 13h DL 00/80  */
         E3 = c2d( substr( INSEC, 113, 1 ))  /* percent heap used */
         RZ = c2x( substr( INSEC, 114, 7 ))  /* EXFAT reserved    */
         IP = 121 - 1                  /* normal boot code offset */
      end                              /***************************/
   end                                 /* assertion: no otherwise */

   /* ----------------- plausibility checks --------------------- */
   select
      when  EB = 'EB'   then  N = 2 + c2d( left( EC, 1 ), 1 )
      when  EB = 'E9'   then  N = 3 + c2d( reverse( EC ), 2 )
   otherwise
      X = 'boot record does not start with jump EBxxxx, got'
      call OUTPUT X EB || c2x( EC )    ;  N = ''
   end
   if N <> '' & N < IP  then  do       /* zero-based code offsets */
      X = 'unexpected boot code offset' N '<' IP 'in'
      call OUTPUT X EB || c2x( EC )
   end

   if EXFAT then  do                   /* test + convert EXFAT CS */
      if          18 < CS  then  do    /* allegedly SL + CS <= 25 */
         X = 'expected EXFAT cluster size exponent 0..18; got' CS
         return OUTPUT( 'analysis aborted:' X )
      end                              ;  else  CS = 2**CS
      if SL < 7 | 12 < SL  then  do    /* test + convert EXFAT SL */
         X = 'expected EXFAT sector length exponent 7..12; got' SL
         call OUTPUT X                 ;  SL = GSS
      end                              ;  else  SL = 2**SL
   end
   else  if FAT | HUGE  then  do       /* classic cluster size CS */
      if wordpos( CS, 1 2 4 8 16 32 64 128 ) = 0   then  do
         X = 'expected cluster size 1, 2, 4, ..., 128; got' CS
         return OUTPUT( 'analysis aborted:' X )
      end
      if TS <> GSPT | HN <> GNOS then  do
         if TS <> 63 | HN <> 255 then  do
            X = 'boot geometry: *' right( HN, 3 ) right( TS, 2 )
            X = X 'does not match  CHS' || right(  '*', G.1 )
            X = X || right( GNOS, G.2 ) || right( GSPT, G.3 )
            call OUTPUT X              /* ignoring dummy * 255 63 */
         end
      end
      X = 'F0 F8 FA'
      select
         when  sign( wordpos( F8, X )) then  X = F8
         when  VS = 80 * 2 * 15        then  X = 'F9'
         when  VS = 80 * 2 *  9        then  X = 'F9'
         when  VS = 80 * 2 *  8        then  X = 'FB'
         when  VS = 40 * 1 *  9        then  X = 'FC'
         when  VS = 40 * 2 *  9        then  X = 'FD'
         when  VS = 40 * 1 *  8        then  X = 'FE'
         when  VS = 40 * 2 *  8        then  X = 'FF'
         otherwise   nop
      end
      if X <> F8  then  do
         X = 'expected media descriptor' X || ', got' F8
         call OUTPUT X
      end
   end

   if SL <> GSS   then  do             /* display + ignore bad SL */
      X = 'sector length' SL 'wrong or unexpected, assuming' GSS
      call OUTPUT X                    ;  SL = GSS
   end                                 /* actually unused: fix SL */

   if FAT | HUGE  then  do             /* NTFS, EXFAT, or any FAT */
      select
         when  WS = 0   then  WS = VS
         when  VS = 0   then  nop      /* for EXFAT fake VS = 0   */
      otherwise
         X = 'inconsistent or redundant 16/32/64-bit sectors' VS WS
         call OUTPUT X
      end
      VS = sign( VS )                  /* note non-zero for FAT16 */
      RS = ( 32 * RN + GSS - 1 ) % GSS /* for EXFAT fake RN = 0   */
      U0 = 0                           /* only EXFAT gets area U0 */

      select                           /* data area DS in sectors */
         when  EXFAT | FAT then  do
            FB = FS * GSS * 8          /* FAT size in bits        */
            DS = WS - BS - FN * FS - RS
            if EXFAT       then  do    /* unused area after EXFAT */
               U0 = DS - CS * E2       ;  DS = CS * E2
            end
         end                           /* ----------------------- */
         when  BS + FN + RN + VS + FS = 0 then  do
            WS = WS + 1                ;  DS = WS - CS
            BS = CS                    /* NTFS has a boot cluster */
         end
      otherwise                        /* unexpected NTFS: HPFS ? */
         X = 'expected (offset 14) 00000000000000' || F8 || '0000,'
         call OUTPUT X 'got' c2x( substr( INSEC, 15, 10 ))
         X = 'unexpected non-zero values in NTFS boot sector'
         return OUTPUT( 'analysis aborted:' X )
      end                              /* ----------------------- */

      if HS <> R | WS <> L then  do
         X = 'hidden or total sectors' HS WS 'do not match' R L
         call OUTPUT X
      end
      if CD > 3 | ( DL <> 00 & DL <> 80 ) then  do
         X = 'expected INT 13h DL 80'  /* just for the records... */
         X = X 'or 00 and AUTOCHK flags 00..03, got' DL d2x( CD )
         call OUTPUT X
      end
      if DS < 0   then  do
         X = DS '< 0 data sectors are not possible'
         return OUTPUT( 'analysis aborted:' X )
      end

      MC = DS % CS + 1                 ;  U2 =  L - WS
      U1 = DS + CS - MC * CS           ;  DS = DS - U1
   end

   /* ----------------- check FAT type -------------------------- */
   if FAT | EXFAT then  select
      when  DS = 0 & FS = 0 & RS = 0   then  nop
      when  DS > 0 & FS > 0 & RS > 0   then  nop
      when  DS = 0                     then  do
         X = 'no data:' FN * FS + RS 'unused FAT + dir. sectors'
         call OUTPUT X
      end
      when  FS = 0                     then  do
         call OUTPUT 'missing FAT sectors (' || FN 'copies)'
      end
      when  HUGE                       then  nop
      when  RS = 0                     then  do
         X = 'missing root directory for' DS 'data sectors'
         call OUTPUT X
      end
   end                                 /* assertion: no otherwise */
   if FAT   then  select               /* ----------- empty ----- */
      when MC = 1 & FS = 0                         then  do
         call OUTPUT 'no data: spurious FAT12 expected to fail'
         Q = FSMATCH( MC, P, Q, 01 )
         M = 0                         /* 0 bytes per FAT, Q = 12 */
      end                              /* ------------ 4084 ----- */
      when MC < x2d( 00000FF6 )                    then  do
         Q = FSMATCH( MC, P, Q, 01 )
         M = 3 * ( MC + 2 ) % 2 - 1    /* M bytes per FAT, Q = 12 */
      end                              /* off by one:  4085 ----- */
      when MC = x2d( 00000FF6 ) & FB < 16 *  4087  then  do
         X = 'FAT12 for  4085 clusters violates specification'
         call OUTPUT X                 /* stupid CHKDSK allows it */
         Q = FSMATCH( MC, P, Q, 01 )
         M = 3 * ( MC + 2 ) % 2 - 1    /* M bytes per FAT, Q = 12 */
      end                              /* ----------- 65524 ----- */
      when MC < x2d( 0000FFF6 )                    then  do
         if VS then  Q = FSMATCH( MC, P, Q, 04, 0E )
               else  Q = FSMATCH( MC, P, Q, 06, 0E )
         M = 2 * ( MC + 1 )            /* M bytes per FAT, Q = 16 */
      end                              /* off by one: 65525 ----- */
      when MC = x2d( 0000FFF6 ) & FB < 32 * 65527  then  do
         X = 'FAT16 for 65525 clusters violates specification'
         call OUTPUT X                 /* stupid CHKDSK allows it */
         if VS then  Q = FSMATCH( MC, P, Q, 04, 0E )
               else  Q = FSMATCH( MC, P, Q, 06, 0E )
         M = 2 * ( MC + 1 )            /* M bytes per FAT, Q = 16 */
      end                              /* ------- 268435444 ----- */
      when MC < x2d( 0FFFFFF6 )                    then  do
         Q = FSMATCH( MC, P, Q, 0B, 0C )
         M = 4 * ( MC + 1 )            /* M bytes per FAT, Q = 32 */
      end                              /* dubious 268435445 ----- */
      when MC = x2d( 0FFFFFF6 )                    then  do
         Q = FSMATCH( MC, P, Q, 0B, 0C )
         M = 4 * ( MC + 1 )            /* M bytes per FAT, Q = 32 */
      end                              /* ----- FAT32 limit ----- */
      otherwise                        /* FAT32 uses only 28 bits */
         Q = FSMATCH( MC, P, Q, 0B, 0C )
         J = MC                        ;  MC = x2d( 0FFFFFF5 )
         N = CS * ( J - MC )           ;  DS = DS - N
         X = 'max. cluster' J 'too big for' FSTYPE( 0B )
         call OUTPUT X || ', assuming' MC
         X = N 'data sectors added to' U1 'unused sectors'
         call OUTPUT X                 ;  U1 = U1 + N
         M = 4 * ( MC + 1 )            /* M bytes per FAT, Q = 32 */
   end
   if FAT | EXFAT then  do
      if FAT      then  do             /* FB is FAT size in bits: */
         X = 'FAT' || Q                ;  J = FB % Q
      end
      else  do                         /* EXFAT also uses 32bits: */
         X = 'EXFAT'                   ;  J = FB % 32
         M = 4 * ( MC + 1 )
      end

      M = FS - ( M + GSS - 1 ) % GSS   /* clusters in FS sectors: */
      if M > 0 then  do
         call OUTPUT 'the last' M 'of' FS X 'sectors are not used'
      end
      if M < 0 then  do
         M = CS * ( MC - J )           ;  DS = DS - M
         X = 'max. cluster' MC 'exceeds' FS X 'sectors:'
         call OUTPUT X
         call OUTPUT M 'data sectors added to' U1 'unused sectors'
         MC = J                        ;  U1 = U1 + M
      end
      if MC > J & MC > 1   then  do    /* "allows" MC = 1 & J = 0 */
         exit ERROR( 'assertion' MC '<=' J 'failed' )
      end
   end

   /* ----------------- FAT32 checks ---------------------------- */
   if FAT & ( HUGE | Q = 32 ) then  do
      N = 0                            /* spurious error counter  */
      if RX < 2 | MC <= RX then  do
         X = 'FAT32 root dir. cluster' RX 'outside of 2..' || MC
         N = N + OUTPUT( X )
      end
      if BX = 65535  then  BX = -1     /* allegedly -1 is allowed */
      if IX = 65535  then  IX = -1     /*  maybe 0 is not allowed */
      if BX <= 0           then  do    /* ----------------------- */
         X = 'no FAT32 backup sectors (' || BX || ')'
         N = N + OUTPUT( X )
      end
      if IX <= 0           then  do
         X = 'no FAT32 FSinfo sector (' || IX || ')'
         N = N + OUTPUT( X )
      end                              /* ----------------------- */
      if BS <= IX          then  do    /* bad IX = BX not checked */
         X = 'FAT32 FSinfo sector' IX 'outside of 1..' || ( BS - 1 )
         N = N + OUTPUT( X )           /* show BX <= IX if 0 < BX */
      end                              /* show BS <= IX if BX < 1 */
      if BS <= ( BX + 2 )  then  do    /* min. three boot sectors */
         X = BX || '..' || ( BX + 2 )
         X = 'FAT32 backup sectors' X 'outside of 1..' || ( BS - 1 )
         N = N + OUTPUT( X )
      end                              /* ----------------------- */
      if VX <> 0000     then  do
         X = 'FAT32 version' VX 'unexpected, assuming 0.00'
         N = N + OUTPUT( X )
      end
      else  if RZ <> 0  then  do       /* test only known version */
         X = 'FAT32 reserved bytes not zero, got hex.' RZ
         N = N + OUTPUT( X )
      end                              /* ----------------------- */
      if bitand( FF, x2c( 'FF70' )) <> x2c( 0000 ) then  do
         X = 'FAT32 reserved flag bits not zero, got' c2x( FF )
         N = N + OUTPUT( X )
      end
      X = c2d( bitand( FF, x2c( 000F ))) + 1
      if bitand( FF, x2c( 0080 )) = x2c( 0080 ) & X > FN then  do
         X = 'FAT32 active FAT' X 'greater than number of FATs' FN
         N = N + OUTPUT( X )
      end                              /* ----------------------- */
      if HUGE <> ( Q = 32 )   then  do /* Q = 32 can be wrong for */
         if sign( N )                  /* invalid max. cluster MC */
            then  X = 'ignore' N 'reported FAT32 issues if n/a'
            else  X = 'all FAT32 tests confirm file system FAT32'
         call OUTPUT X                 /* Q = 32 can be valid for */
      end                              /* erroneous partition id. */
   end

   /* ----------------- EXFAT checks ---------------------------- */
   if EXFAT then  do
      if VX <> 0100     then  do
         X = 'EXFAT version' VX 'unexpected, assuming 1.00 (@104)'
         call OUTPUT X
      end
      else  if RZ <> 0  then  do
         X = 'EXFAT reserved bytes not zero, got hex.' RZ '(@113)'
         call OUTPUT X
      end
      if WS <> E1 + E2 * CS   then  do
         X = 'EXFAT' WS '<>' E1 '+' E2 '*' CS 'sectors (@88)'
         call OUTPUT X
      end
      if E2 <> MC - 1         then  do
         X = 'EXFAT' E2 '<>' ( MC - 1 ) 'clusters (@92)'
         call OUTPUT X
      end
      if MC <= RX | RX < 2    then  do
         X = 'EXFAT root cluster' RX 'outside of 2..' || MC '(@96)'
         call OUTPUT X
      end
      if E3 > 100             then  do
         X = 'EXFAT' E3 || '% > 100% unexpected (@112)'
         call OUTPUT X
      end
      if FN > 2 | ( FN = c2d( FF ) // 2 ) then  do
         X = 'EXFAT' FN '> 2 copies (@110), or active >' FN '(@106)'
         call OUTPUT X
      end                              /* ignore unclear bit 0008 */
      if bitand( FF, x2c( 'FFF0' )) <> x2c( 0000 ) then  do
         X = 'EXFAT reserved flags not zero, got' c2x( FF ) '(@106)'
         call OUTPUT X
      end
   end

   /* ----------------- minimal NTFS check ---------------------- */
   if HUGE > ( FAT + EXFAT )  then  do
      if MC <= max( M1, M2 )  then  do
         X = 'NTFS $MFT' M1 'or $MFTmirr' M2 '>' ( MC - 1 )
         call OUTPUT X
      end
   end

   /* ----------------- check filesystem name ------------------- */
   select                              /* FAT32 always has FSType */
      when  EXFAT                         then  X = 'EXFAT   '
      when  FAT < HUGE                    then  X = 'NTFS    '
      when  FAT & HUGE                    then  X = 'FAT32   '
      when  FAT & ( MX = 29 | MX = 28 )   then  X = 'FAT' || Q '  '
      otherwise   LX = ''              ;        X = ''
   end
   if X <> ''  then  do                /* get label or volume id. */
      SX = '[' || left( SX, 4 ) || '-' || right( SX, 4 ) || ']'
      select
         when  TX = X                        then  X = ''   /* OK */
         when  FAT & TX = left( 'FAT', 8 )   then  X = ''   /* OK */
         when  HUGE                          then  nop   /* wrong */
         when  FAT & MX = 29                 then  nop   /* wrong */
         when  FAT & MX = 28                 then  X = ''   /* OK */
      end                              /* assertion: no otherwise */
      if X <> ''  then  do
         X = 'expected FSType string "' || X || '", got'
         if sign( verify( TX, PRINT ))
            then  call OUTPUT X 'non-ASCII' c2x( TX )
            else  call OUTPUT X '"' || TX || '"'
      end
      select                           /* NTFS: LX + MX undefined */
         when  FAT = 0                             then  LX = SX
         when  MX = 28 | LX = '' | LX = 'NO NAME'  then  LX = SX
         when  sign( verify( LX, PRINT ))          then  LX = SX
         otherwise   nop               /* can use volume label LX */
      end
   end

   /* ----------------- show volume layout ---------------------- */
   TAG = 'boot'                        ;  R = AS
   select
      when  EXFAT       then  N = BX   /* EXFAT backup: 12 + 12   */
      when  FAT & HUGE  then  N = 3    /* FAT32 backup: BX + 3    */
      otherwise               N = 0    /* FAT12/16 has no backup  */
   end                                 /* NTFS backup is unclear  */
   if sign( N ) & N <= BX & BX <= BS - N  then  do
      parse value GEOAREA( C H S AS BX TAG ) with C H S AS
      if EXFAT then  X = ' EXFAT'      ;  else  X = ' FAT32'
      if IN55AA( AS, X 'backup boot' ) <> INSEC then  do
         call OUTPUT 'backup boot sector does not match boot sector'
      end                              /* check first backup boot */

      TAG = 'backup boot'              ;  BS = BS - BX
      parse value GEOAREA( C H S AS N  TAG ) with C H S AS
      TAG = 'rest boot'                ;  BS = BS - N
   end
   parse value GEOAREA( C H S AS BS TAG ) with C H S AS

   if EXFAT then  TAG = 'EXFAT'        ;  else  TAG = 'FAT' || Q
   do N = 1 to FN
      X = '#' || N
      parse value GEOAREA( C H S AS FS TAG X ) with C H S AS
   end N
   if RS * GSS = RN * 32   then  TAG = 'dir.'  right( RN, 6 )
                           else  TAG = 'dirty' right( RN, 6 )
   parse value GEOAREA( C H S AS RS TAG      ) with C H S AS
   parse value GEOAREA( C H S AS U0 'unused' ) with C H S AS
   parse value GEOAREA( C H S AS DS 'data'   ) with C H S AS
   parse value GEOAREA( C H S AS U1 'unused' ) with C H S AS

   /* ----------------- cluster summary ------------------------- */
   N = right( LX '(cluster size' || right( CS, 4 ), 29 )
   N = left( N || ', number' || right( MC - 1, 12 ) || ')', 54 )
   call OUTPUT N 'total' || right( WS, 12 )

   TAG = 'unused raw'                  /* volume size < partition */
   parse value GEOAREA( C H S AS U2 TAG      ) with C H S AS

   if symbol( 'IN..' ) = 'VAR'   then  do
      N = IN.0 + 1                     ;  IN.0 = N
      IN.N = R BASE64( INSEC )         /* backup of boot sector R */
   end
   else  if LX <> '' then  IN.. = SX   /* unpartitioned volume SX */
   else  IN.. = left( 'DOS 3.x', 11 )  /* unpartitioned garbage ? */

   return 1                            /* 1: some lines written   */

/* -------------------------------------------------------------- */
FSMATCH: procedure expose (EXPO)       /* check expected FAT type */
   parse arg MC, P, Q, ID, ID2         /* if given ID2 is for LBA */

   if Q <> '??' & Q <> ID & Q <> ID2   then  do
      Q = space( strip( ID ID2 ), 1, '/' )
      Q = 'max. cluster' MC 'requires type' Q '(' || FSTYPE( ID )
      call OUTPUT Q || '), got' P '(' || FSTYPE( P ) || ')'
   end
   select
      when  ID = 01                       then  return 12
      when  ID = 04 | ID = 06 | ID = 0E   then  return 16
      when  ID = 0B | ID = 0C             then  return 32
   end                                 /* otherwise raise SYNTAX  */

/* -------------------------------------------------------------- */
IN55AA:  procedure expose (EXPO)       /* seek, read, test sector */
   parse arg SECTOR, MAGIC             ;  signal off notready
   if stream( GIN ) == 'UNKNOWN' then  do
      call charin GIN, 1, 0            /* open drive at its begin */
      S = stream( GIN, 'd' )           /* bypass ooREXX "ERROR:0" */
      if S == 'ERROR:0' then  call charin GIN, 1, 0
   end

   S = GSS * SECTOR + 1
   if S = stream( GIN, 'c', 'seek' S ) then  do
      INSEC = charin( GIN,, GSS )
      if length( INSEC ) = GSS   then  do
         if right( INSEC, 2 ) == x2c( 55AA ) then  return INSEC
         MAGIC = MAGIC 'magic 55AA not found'
         call OUTPUT MAGIC             ;  return ''
      end
   end                                 /* else drop to seek error */

   S = 'sector' || right( SECTOR, 12 ) stream( GIN, 'd' )
   call stream GIN, 'c', 'close'       ;  call charin GIN, 1, 0
   call OUTPUT DRIVE19( GIN ) S        ;  return ''

/* -------------------------------------------------------------- */
TOTALS:  procedure expose LOGFILE      /* next extended partition */
   arg E, B, N                         ;  X = left( '', 54 )
   if E <> 0   then  do
      E = E + B                        /* show abs. sector number */
      X = right( '(extended offset' || right( E, 12 ), 37 )
      X = left( X || ')', 54 )
   end
   X = X 'total' || right( N, 12 )     ;  call OUTPUT X
   return E                            /* sector number (0 first) */

/* -------------------------------------------------------------- */
DECODE:  procedure expose PART.        /* decode and sort part.s: */
   parse arg INSEC, PART
   do N = 1 to 4                       /* decode PART.1 .. PART.4 */
      X = DEPART( substr( INSEC, 431 + 16 * N, 16 ))
      PART.N = X ( PART + N )          ;  R = word( X, 6 )

      if R > 0 then  do K = 1 to N - 1 /* sort by start sector R: */
         X = word( PART.K, 6 )         ;  if X < R then  iterate K
         R = X                         ;  X = PART.N
         PART.N = PART.K               ;  PART.K = X
      end K
   end N
   return                              /* result PART.1 .. PART.4 */

/* -------------------------------------------------------------- */
DEPART:  procedure                     /* decode partition entry: */
   parse arg X
   B = c2x( substr( X,  1, 1 ))        /* boot flag (00 or 80)    */
   H = c2d( substr( X,  2, 1 ))        /* CHS start head 0...255  */
   U = c2d( substr( X,  3, 1 ))        /* CHS     sector 1....63  */
   C = c2d( substr( X,  4, 1 ))        /* CHS   cylinder 0..1023  */
   S = U // 64                         ;  C = C + 4 * ( U - S )
   P = c2x( substr( X,  5, 1 ))        /* partition type 00...FF  */
   I = c2d( substr( X,  6, 1 ))        /* CHS end   head 0...255  */
   U = c2d( substr( X,  7, 1 ))        /* CHS     sector 1....63  */
   D = c2d( substr( X,  8, 1 ))        /* CHS   cylinder 0..1023  */
   T = U // 64                         ;  D = D + 4 * ( U - T )
   R = c2d( REVSUB( X,  9, 4 ))        /* LBA relative offset     */
   L = c2d( REVSUB( X, 13, 4 ))        /* LBA length (sectors)    */
   return B P C H S R D I T L

/* -------------------------------------------------------------- */
LINEND:  procedure expose (EXPO)       /* unique CHS text format: */
   arg C H S R D I T L                 /* length 10+1 for 2**32-1 */
   R =      right( R,  12 )            ;  L =      right( L,  12 )
   C =      right( C, G.1 )            ;  D =      right( D, G.1 )
   C = C || right( H, G.2 )            ;  D = D || right( I, G.2 )
   C = C || right( S, G.3 )            ;  D = D || right( T, G.3 )
   return 'CHS' || C 'at' || R || ', end' || D 'len' || L

/* -------------------------------------------------------------- */
GEOTEST: procedure expose (EXPO)       /* adjust C H S above 8 GB */
   arg C.1 H.1 S.1 REL C.2 H.2 S.2 LEN, BASE
   B.1 = BASE + REL                    ;  B.2 = B.1 + LEN - 1
   BAD = 0

   do N = 1 to 2
      B.N = subword( GEOPLUS( 0 0 1, B.N ), 1, 3 )
      parse var B.N C.0 H.0 S.0        /* C.0 > 1023 is special:  */
      select                           /* if not max. match C H S */
         when  C.0 <= 1023             then  nop   /* match C H S */
         when  C.N <> 1023             then  nop   /* match C H S */
         when  H.N = H.0 & S.N = S.0   then  iterate N
         when  S.N <> 63 | H.N < 254   then  nop   /* match C H S */
         otherwise   iterate N         /* accept (1023 25[45] 63) */
      end                              /* accept (1023 H S) match */
      BAD = BAD | ( B.N <> ( C.N H.N S.N ))
   end N
   if BAD   then  call OUTPUT 'adjust' LINEND( arg( 1 )) '?'
   return B.1 B.2

/* -------------------------------------------------------------- */
GEOPART: procedure expose (EXPO)       /* detect reserved sectors */
   arg NEXT, R, ID, BASE, TAG          /* linear relative to BASE */
   if R < NEXT          then  return ID <> 00
   if R = NEXT          then  return 0 /* 0: no overlap or ID 00  */

   parse value GEOPLUS( 0 0 1, BASE + NEXT  ) with C H S .
   parse value GEOPLUS( 0 0 1, BASE + R - 1 ) with D I T .
   call OUTPUT 'unused' LINEND( C H S NEXT D I T ( R - NEXT )) TAG
   return 0

/* -------------------------------------------------------------- */
GEOAREA: procedure expose (EXPO)       /* BS sectors start at CHS */
   parse arg C H S AS BS TAG NOTE      /* asserts linear AS = CHS */
   if BS = 0   then  return C H S AS   /* BS = 0 silently ignored */

   parse value GEOPLUS( C H S, ( BS - 1 )) with D I T L
   X = right( TAG, 6 ) LINEND( C H S AS D I T BS ) NOTE
   call OUTPUT X

   if L + 1 <> AS + BS  then  exit ERROR( 'LBA' L + 1 )
   return GEOPLUS( D I T, 1 )

/* -------------------------------------------------------------- */
GEOPLUS: procedure expose (EXPO)       /* CHS + N sectors to CHS  */
   call trace 'O'                      ;  arg C H S, N
   N = ( C * GNOS + H ) * GSPT + ( S - 1 ) + N

   S = N // GSPT                       ;  C = ( N - S ) % GSPT
   H = C // GNOS                       ;  C = ( C - H ) % GNOS
   if N < 0 then  exit ERROR( 'LBA' N )
   return C H ( S + 1 ) N

/* -------------------------------------------------------------- */
STOPLOG: procedure expose (EXPO) IN.   /* save collected sectors  */
   if symbol( 'LOGFILE' ) = 'VAR'   then  do
      if symbol( 'IN..' ) = 'VAR'   then  do
         do N = 1 to IN.0
            parse var IN.N K X         ;  K = right( K, 11 )
            call lineout LOGFILE, ''   ;  K = K 'volume' IN.. || ':'
            call lineout LOGFILE, 'base 64 backup of sector' || K
            do until X == ''
               call lineout LOGFILE, ' ' left( X, 76 )
               X = substr( X, 77 )
            end
         end N
         call lineout LOGFILE          ;  X = chars( LOGFILE )
         say IN.. 'output added to' LOGFILE '(size' X || ')'
      end
   end
   return 0

/* -------------------------------------------------------------- */
OUTPUT:  procedure expose LOGFILE      /* add output to a LOGFILE */
   signal on notready name ERROR       ;  say arg( 1 )
   if symbol( 'LOGFILE' ) = 'VAR'      /* else LOGFILE not opened */
      then  call lineout LOGFILE, strip( arg( 1 ), 'T' )
   return 1                            /* 1: some lines written   */

/* -------------------------------------------------------------- */
OPENLOG: procedure expose LOGFILE      /* create / append LOGFILE */
   parse source . . THIS               ;  L = lastpos( '.', THIS )
   if L > 0 then  L = left( THIS, L ) || 'log'
            else  L = THIS || '.log'

   signal off notready                 /* example: read-only disk */
   if lineout( L, copies( '-', 79 ))   then  do
      signal on notready name ERROR    /* stderr write error trap */
      call PERROR 'no write access on logfile' L
      return ''                        /* LOGFILE stays undefined */
   end
   signal on notready name ERROR       ;  LOGFILE = L
   parse value date( 'S' ) time() with I 5 S 7 O T
   call lineout LOGFILE, I || '-' || S || '-' || O T THIS arg( 1 )
   return 'LOGFILE'                    /* add this to EXPO string */

/* -------------------------------------------------------------- */
PRIMINI: procedure               /* next prime, REXX dot is "NAN" */
   parse arg Q L R
   if sign( L // Q ) then  do    /* Q is no factor of L, get next */
      P = .   2   3   5   7  11  13  17  19  23  29  31  37  41  43
      P = P  47  53  59  61  67  71  73  79  83  89  97 101 103 107
      P = P 109 113 127 131 137 139 149 151 157 163 167 173 179 181
      P = P 191 193 197 199 211 223 227 229 233 239 241 251 257   .
      return word( P, 1 + wordpos( Q, P )) L R
   end
   return Q ( L % Q ) ( R * Q )  /* can move factor Q from L to R */

/* -------------------------------------------------------------- */
BASE64:  procedure               /* trace Off for trusted B64.O   */
   call trace 'O'                      ;  return B64.O( arg( 1 ))

/* -------------------------------------------------------------- */
/* see REXX <URL:http://purl.net/xyzzy/src/md5.cmd> (version 2.1) */

B64.O :  procedure               /* string to (unlimited) base64: */
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = translate( B64 ) || B64 || '0123456789+/'

   SRC = x2b( c2x( arg( 1 )))    ;  DST = ''
   ADD = ( length( SRC ) / 4 ) // 3
   SRC = SRC || copies( '00', ADD )

   do while SRC <> ''
      parse var SRC N 7 SRC      ;  N = x2d( b2x( N ))
      DST = DST || substr( B64, N + 1, 1 )
   end
   return DST || copies( '=', ADD )

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE '0..9|VHD [C H S [L]]'
   say                           /* suited for REXXC tokenization */
   say ' for physical drive 0..9 or a fixed VHD virtual hard disk '
   say ' with geometry C H S.                                     '
   say
   say ' Use S = 1..63 (sectors per track) and H = 1..256 heads.  '
   say ' Use C = 99999 or * if only H and S are clear.  Sometimes '
   say ' the script can guess C H S; try * 255 63 if the output   '
   say ' makes no sense.                                          '
   say
   say ' Use L = 128, 256, ..., 4096 to modify the default sector '
   say ' size 512.                                                '
   return 1

/* ----------------------------- (RXQUEUE portability 2020-03-14) */
/* ooRexx 6.04 does not yet support ADDRESS ... WITH, otherwise   */
/* the same syntax could get the command output in a REXX stem    */
/* without using a REXX queue (aka REXX stack).                   */

RXLIFO:  procedure expose rc
   signal off error              ;  parse version . REXX .
   LIFO = 'RxQueue' rxqueue( 'get' ) '/LIFO'
   if REXX <> 5   then  address CMD     arg( 1 ) || '|' || LIFO
                  else  address SYSTEM  arg( 1 ) || '|' || LIFO
   return ( .RS < 0 )            /* 0: okay (any rc), 1: failure  */

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
