/* NT ooREXX:  Create empty VFD (virtual floppy disk) with a FAT. */
/* Version  :  REXXFAT.rex 0.4, published versions older than 0.3 */
/*             had no version number.     (Frank Ellermann, 2013) */

/* History  :                                                     */
/* 0.4      -  Intro (comment at the begin) completely rewritten. */
/*          -  Replaced '512e' hack by SECLEN = 0 to force 512e.  */
/*             Default FAT1x MINDIR changed from 6 to 8 sectors,  */
/*             this removes a minor difference for 512e.          */
/*          -  Default FAT32 RS = 7 replaced by new RS = 15.      */
/*             Unusual FAT32 RS = 9 replaced by old RS = 7.       */
/*          -  Removed NUMFAT < 0 hack to force unattended mode.  */
/*             REXXFAT called by other REXX scripts or by its own */
/*             FATTEST suite now starts in unattended mode.       */
/* 0.3      -  Added input SECLEN '512e' to set an internal V512E */
/*             flag, where all relevant sector numbers have to be */
/*             multiples of 8.                                    */
/*          -  Added unattended mode, where the smallest possible */
/*             cluster size is automatically selected.            */
/*          -  Added a FATTEST suite, VHD tests require Windows 7 */
/*             DISKPART to attach and detach VHD images checked   */
/*             with CHKDSK.                                       */
/*          -  Added input SECLEN < 0 to allow cluster numbers    */
/*             4085 (FAT16 4086) and 65525 (FAT32 65526) again.   */
/*             MS CHKDSK hates this, but the MS FAT32 spec. is    */
/*             absolutely clear that this is correct.             */

/* Usage    :  REXXFAT NOS [MINDIR [NUMFAT [SECLEN]]]             */
/* SECLEN   :  128, 256, 512, 1024, 2048, or 4096;    default 512 */
/* NUMFAT   :  1..16 file allocation tables (FATs);   default   2 */
/* MINDIR   :  One or more FAT12/16 dir. sectors;     default   8 */
/* NOS      :  Number of sectors; at least four for REXXFAT 4 1 1 */
/*             For a given total number of sectors (NOS) an image */
/*             is formatted with NOS = RS + FN*FS + DS + CN*CS    */
/*             sectors.  CS is the chosen cluster size 1, 2, 4,   */
/*             etc. up to 128.  CN is the cluster number.  DS is  */
/*             the number of FAT1x root directory sectors; or 0   */
/*             for FAT32.  FS is the number of FAT sectors needed */
/*             for CN+2 cluster entries.  FN is the number of FAT */
/*             copies.  RS is the number of reserved sectors.     */
/* FN       :  NUMFAT 1..16, more than 2 is unusual.  Four bits   */
/*             indicate an active FAT32 if mirroring is disabled, */
/*             and therefore REXXFAT does not support FN > 16.    */
/* DS       :  MINDIR or more FAT12/16 dir. sectors.  Otherwise   */
/*             unused sectors end up in DS for FAT12/16 formats.  */
/* RS       :  Reserved sectors at the begin of a FAT disk image; */
/*             starting with the "volume boot record" (VBR), also */
/*             known as "partition boot record" (PBR).  A VBR/PBR */
/*             contains "boot code" to load the next stage in the */
/*             boot process.  For some file systems including FAT */
/*             the VBR also contains a BPB (BIOS parameter block) */
/*             to define file system details.  REXXFAT adds any   */
/*             otherwise unused sectors to RS for FAT32 formats.  */
/* CS       :  REXXFAT proposes all possible cluster sizes to get */
/*             NOS = RS + FN*FS + DS + CN*CS.  There can be up to */
/*             eight CS values for any given NOS and MINDIR.      */
/*             Old tools might not support CS = 128, NOS > 65535, */
/*             CN > 65524, or CN > 4084.                          */
/* CN       :  FAT12     1 ..      4084, hex.    FF4, bad     FF7 */
/*             FAT16  4085 ..     65524, hex.   FFF4, bad    FFF7 */
/*             FAT32 65525 .. 268435444, hex FFFFFF4, bad FFFFFF7 */
/*             FAT32 uses only 7 hex. digits for cluster numbers, */
/*             i.e., 28 of 32 bits.  FAT12 and FAT16 use 12 or 16 */
/*             bits, as the name suggests.                        */
/* BigFAT   :  "BigFAT" is a name for NOS > 65535.  If 16 bits in */
/*             an old "small" BPB value are 0 a new "big" 32 bits */
/*             value is used.  This also affects FAT32 version 0, */
/*             NOS has to be smaller than 4294967296 = 2**32.     */
/* 512e     :  REXXFAT NOS MINDIR NUMFAT 0                        */
/*             SECLEN = 0 is interpreted as a logical sector size */
/*             512 emulation for a physical sector size 4096.  To */
/*             avoid 512e read-modify-write accesses all relevant */
/*             structures occupy multiples of 8 sectors.  REXXFAT */
/*             accepts any NOS = N*8 and MINDIR = M*8.  For 512e  */
/*             the minimal FAT cluster size CS is 8 instead of 1. */
/* CHKDSK   :  REXXFAT NOS MINDIR NUMFAT -N                       */
/*             SECLEN < 0 allows CN = 4085 and CN = 65525 defined */
/*             in the "Microsoft Extensible Firmware Initiative,  */
/*             FAT32 File System Specification"; version 1.03, as */
/*             published 2000-12-06 and 2011-03-30.               */
/*             FAT12 CN =  4085 is illegal, MS CHKDSK accepts it. */
/*             FAT16 CN =  4085 is allowed, MS CHKDSK rejects it. */
/*             FAT16 CN = 65525 is illegal, MS CHKDSK accepts it. */
/*             FAT32 CN = 65525 is allowed, MS CHKDSK crashes.    */
/*             In FATs the first data cluster is addressed as 2,  */
/*             and the last of CN data clusters is addressed as   */
/*             CN+1.                                              */
/* Known bug:  REXXFAT NOS MINDIR -N [SECLEN]                     */
/*             Negative values -N modify the REXXFAT processing   */
/*             for the corresponding non-negative value.  In this */
/*             REXXFAT version NUMFAT < 0 has no special effects. */
/* FAT32    :  REXXFAT NOS -N [NUMFAT [SECLEN]]                   */
/*             MINDIR < 0 works like MINDIR > 0 for FAT12 and for */
/*             FAT16.  For FAT32 a "small" RS = 7 format is used  */
/*             instead of the "normal" RS = 15.                   */
/*             The minimal number of reserved sectors (RS) for a  */
/*             FAT file system is 1.  The "typical" FAT32 RS = 32 */
/*             for SECLEN 512 is rather "big"; it consists of one */
/*             boot sector (0), one FSINFO sector (1), the second */
/*             boot sector (2), three empty sectors (3..5), six   */
/*             backup sectors (6..11, copying the original 0..5), */
/*             and twenty additional empty sectors (12..31).      */
/*             A minimal FAT32 can drop FSINFO, backup, and empty */
/*             sectors arriving at RS = 1 or RS = 2 boot sectors, */
/*             with backup = 0 and FSINFO = 0.                    */
/*             A "small" FAT32 can drop all empty sectors, using  */
/*             backup = 3 after the "typical" sectors 0..2 with a */
/*             "typical" FSINFO = 1.  Three original sectors 0..2 */
/*             are copied to 3..5 as "small" backup, and sector 6 */
/*             is another copy of sector 0 at a well-known place. */
/*             NB, if sector 0 is corrupted its FSINFO and backup */
/*             pointers are unavailable, and FAT32 recovery tools */
/*             would try backup = 6.                              */
/*             The "normal" FAT32 format uses RS = 15, or RS = 16 */
/*             for unpartitioned 512e VFD images.  For VHD images */
/*             MBR + 15 is already aligned for 512e with RS = 15. */
/*             "Normal" and "typical" are otherwise identical.    */
/* FSUTIL   :  FSUTIL is used to create sparse VFD images on NTFS */
/*             volumes.  Sparse fixed VHD images (VHD type 2) do  */
/*             not work for unknown reasons.  REXXFAT uses FSUTIL */
/*             only for VFD images on NTFS.  FSUTIL needs admin   */
/*             rights.                                            */
/* MBR image:  REXXFAT -N [MINDIR [NUMFAT [SECLEN]]]              */
/*             NOS < 0 results in 0 - NOS - 1 sectors in the FAT  */
/*             image after one master boot record (MBR) with the  */
/*             partition table.  For a corresponding NOS - 1 VFD  */
/*             only 3 + FN bytes differ from NOS < 0 MBR images:  */
/*             The media descriptor in the BPP and FN FAT copies  */
/*             is hex. F8 for MBR images, or hex. F0 for almost   */
/*             all VFD images.  The number of hidden sectors in   */
/*             the BPB is 0 for a VFD, for MBR images created by  */
/*             REXXFAT it is 1.  Some tools use 63 hidden sectors */
/*             for the first partition in MBR images with a dummy */
/*             geometry of 63 sectors per track.  Old tools would */
/*             allow less sectors per track.  Many tools use 2048 */
/*             hidden sectors before the first partition.         */
/*             The third and last BPB difference between VFD and  */
/*             MBR images created by REXXAT is hex. 80 to address */
/*             the first hard disk or 00 for the first floppy in  */
/*             VBR boot code.  REXXFAT sets hex. 80 in MBR images */
/*             or hex. 00 in unpartitioned VFDs.                  */
/* VHD image:  For sector size 512 the result is transformed into */
/*             a "fixed" VHD (virtual hard disk) adding 511 bytes */
/*             for a "classic fixed VHD footer".  In theory this  */
/*             permits a "raw copy" to unformatted media with a   */
/*             capacity of N + 1 sectors.  For smaller "raw copy" */
/*             block sizes specify VHD size - 511 to get rid of   */
/*             the VHD footer.                                    */
/* Raw image:  Other sector sizes are not allowed for VHD images. */
/*             In these cases the MBR image gets no VHD footer    */
/*             and has a file extension ".dd" instead of ".vhd"   */
/*             or ".vfd".                                         */
/*             If you use IMDISK.exe to mount VFDs use its option */
/*             S to specify the sector size for an image.  Do not */
/*             touch hex. 55AA at offset 510 (REXX 510 + 1) for   */
/*             sector sizes 2**9 .. 2**12.                        */
/* Boot code:  The MBR code is a quick hack for INT 13h with LBA, */
/*             it starts a partition flagged as active, and exits */
/*             with INT 18h if that fails.  The one FAT partition */
/*             in a new VHD is not flagged as active, because the */
/*             dummy partition boot code only displays its volume */
/*             ID, waits for any key, and exits with INT 18h.     */

   signal on  novalue  name TRAP ;  signal on  syntax name TRAP
   signal on  failure  name TRAP ;  signal on  halt   name TRAP
   signal on notready  name TRAP ;  numeric digits 20

   if arg() > 1         then  do /* unattended use in REXX script */
      parse arg NOS, MINDIR, NUMFAT, SECLEN, EXTRA
      if arg() > 4      then  EXTRA = EXTRA '...'
      return REXXFAT( 1, NOS, MINDIR, NUMFAT, SECLEN, EXTRA )
   end
   else  do                      /* interactive command line use  */
      if arg( 1 ) = '*' then  return FATTEST()
      parse arg NOS  MINDIR  NUMFAT  SECLEN  EXTRA
      return REXXFAT( 0, NOS, MINDIR, NUMFAT, SECLEN, EXTRA )
   end                           /* returns 0 (okay) or 1 (error) */

/* -------------------------------------------------------------- */
REXXFAT: procedure               /* REXXFAT wrapper for FATTEST() */
   parse arg USE1ST, NOS, MINDIR, NUMFAT, SECLEN, EXTRA

   PARTED = 0                    /* 1: create MBR, 0: superfloppy */
   V512E  = 0                    /* 1: enforce 512e alignments    */
   CHKDSK = 1                    /* 1: bypass Windows CHKDSK bug  */
   ACTIVE = 0                    /* 1: boot first VHD partition   */
   SECSUP = 2**7 2**8 2**9 2**10 2**11 2**12
   LABEL  = 'NO NAME'            /* not yet modified at run time  */
   OEMID  = 'REXXFAT 0.4'        /* avoid OEMID "NTFS" or "EXFAT" */
   VOLSER = MAKEID( 1 )          /* raw binary volume serial id.  */
   VIRGIN = x2c( 'F6' )          /* EBCDIC 'V' for legacy FORMATs */
   INT13H = ''                   /* use specific NOH SPT geometry */
   MINVHD = 16                   /* padding does not help for VHD */
   MINVFD = 4096                 /* pad small VFD to MINVFD bytes */
   XFAT32 = 8                    /* FAT32: 2*6+3 instead of 2*3+1 */

   if NOS = '-?' | NOS = '/?'       then  return USAGE()
   if datatype( NOS, 'w' ) = 0      then  return USAGE( NOS )
   if NOS <  0    then  do       /* ToDo: improve negative "hack" */
      NOS = abs( NOS ) - 1       ;  PARTED = 1
   end
   if NOS <= 0 | 2**32 <= NOS       then  return USAGE( NOS )

   if abbrev( '.', MINDIR )         then  MINDIR = 8
   if datatype( MINDIR, 'w' ) = 0   then  return USAGE( MINDIR )
   if MINDIR <= 0 then  do       /* ToDo: improve negative "hack" */
      MINDIR = abs( MINDIR )     ;  XFAT32 = 0  /* only for FAT32 */
   end

   if abbrev( '.', NUMFAT )         then  NUMFAT = 2
   if datatype( NUMFAT, 'w' ) = 0   then  return USAGE( NUMFAT )
   if NUMFAT <= 0 then  do       /* ToDo: improve negative "hack" */
      NUMFAT = abs( NUMFAT )     ;  nop         /* TBD (reserved) */
   end
   if NUMFAT <= 0 | 16 < NUMFAT     then  return USAGE( NUMFAT )

   if abbrev( '.', SECLEN )         then  SECLEN = 512
   if SECLEN < 0  then  do       /* ToDo: improve negative "hack" */
      SECLEN = abs( SECLEN )     ;  CHKDSK = 0
   end
   if SECLEN = 0  then  do       /* alignments for 512e emulation */
      SECLEN = 512               ;  V512E  = 1
      if XFAT32 = 0  then  XFAT32 = 1 - PARTED  /* 1+7+0 or 0+7+1 */
                     else  XFAT32 = 9 - PARTED  /* 1+7+8 or 0+7+9 */
      if sign(( NOS + PARTED ) // 8 ) | sign( MINDIR // 8 ) then  do
         N = '512e requires multiples of 8 sectors; got'
         return PERROR( N NOS + PARTED 'with MINDIR' MINDIR )
      end
   end
   if wordpos( SECLEN, SECSUP ) = 0 then  return USAGE( SECLEN )
   if EXTRA  <> ''                  then  return USAGE( EXTRA  )

   /* ----------------------------------------------------------- */
   C.2 = x2d(     'FF4' )        /* max. data cluster numbers CN  */
   C.1 = x2d(    'FFF4' )        /* addressed as 2..CN+1 in FATs, */
   C.0 = x2d( 'FFFFFF4' )        /* clusters 0 and 1 are no data  */

   F.0 = 0                       /* F.0 = 0 fits F.1, maximal F.8 */
   do CLOOP = 3 * V512E to 7     /* 0..7 or 3..7, 8=2**3 for 512e */
      CS = 2**CLOOP              /* cluster size 1, 2, 4, .., 128 */
      do FLOOP = 0 to 2 * sign( MINDIR )
         if sign( FLOOP )     then  do
            FAT = word( 16 12, FLOOP )
            if V512E          then  RAW = NOS - 8 - MINDIR + PARTED
                              else  RAW = NOS - 1 - MINDIR
         end                     /* FAT1x: reserve 1 + MINDIR     */
         else                       do
            FAT = 32             ;  RAW = NOS - 7 - XFAT32
         end                     /* FAT32: reserve 7 + XFAT32     */
         if RAW <= 0          then  iterate FLOOP

         CX = 0                  /* find good cluster number 2**N */
         do N = 0 until CS * CX + FS * NUMFAT > RAW
            CN = CX              /* CN = 0 indicates no known fit */
            CX = 2**N            ;  FS = FATSIZE( CX, FAT, V512E )
         end N
         CX = CN                 ;  FS = FATSIZE( CX, FAT, V512E )
         do N = N - 2 to 0 by -1 /* find max. good cluster number */
            if CS * CX + FS * NUMFAT <= RAW  then  do
               CN = CX           ;  CX = CX + 2**N
            end                  /* CN is last known good cluster */
            else  CX = CX - 2**N /* CX is the next size candidate */
            FS = FATSIZE( CX, FAT, V512E )
         end N
         if CS * CX + FS * NUMFAT <= RAW
            then  CN = CX
            else  FS = FATSIZE( CN, FAT, V512E )

         select                  /* special FAT32 case 0FFFFFF5h: */
            when  CN = C.0 + 1         then  do
               if FLOOP > 0 | CS <> 16 then  iterate FLOOP
            end                  /* skip CN if too big for FLOOP: */
            when  CN > C.FLOOP         then  iterate FLOOP
            when  FLOOP < 2            then  do
               N = FLOOP + 1     /* CN not big enough for CHKDSK: */
               if CN <= C.N + CHKDSK   then  iterate FLOOP
            end                  /* CN = 0 not enough for FAT12:  */
            when  CN = 0               then  iterate FLOOP
            otherwise   nop      /* CN > 0 suited for FAT12 FLOOP */
         end

         RAW = RAW - FS * NUMFAT - CS * CN
         DIR = 0                 ;  RES = 1
         select
            when  FLOOP = 0   then  RES = RAW + XFAT32 + 7
            when  V512E = 0   then  DIR = RAW + MINDIR
         otherwise               /* FAT12 or FAT16 512e alignment */
            RES = 8 - PARTED     ;  DIR = RAW + MINDIR
         end
         N   = F.0 + 1           ;  F.0 = N
         F.N = FAT RES FS DIR CS CN

         RAW = RES + FS * NUMFAT + DIR + CS * CN
         if RAW <> NOS  then  do
            RAW = NOS '<>' RAW '=' RES '+' FS '*' NUMFAT '+' DIR
            return PERROR( 'assertion failed:' RAW '+' CS '*' CN )
         end
      end FLOOP
   end CLOOP

   /* ----------------------------------------------------------- */
   do N = 1 to F.0
      parse var F.N FAT RES FS DIR CS CN
      L = d2c( N - 1 + c2d( 'a' ))
      L = L || ':' right( FS, 7 ) '*'
      L = L || right( NUMFAT, 2 ) 'FAT' || FAT 'sectors;'
      L = L || right( RES, 4 ) '+' || right( DIR, 4 ) 'SYS;'
      L = L || right(  CS, 4 ) '*' || right( CN, 10 ) 'data:'
      say L || right(  CS * CN, 13 )
   end N
   select
      when  PARTED = 0     then  VFD = VFDPATH( 'vfd' )
      when  MINVHD > NOS   then  VFD = VFDPATH( 'dd'  )
      when  SECLEN = 512   then  VFD = VFDPATH( 'vhd' )
      otherwise                  VFD = VFDPATH( 'dd'  )
   end

   if SECLEN <> 512  then  L = 'with sector size' SECLEN
                     else  L = 'with' NOS 'sectors'
   L = 'for' VFD L               ;  N = USE1ST
   select
      when  F.0 = 0  then  do
         L = 'Found no FAT for' NOS 'sectors,' NUMFAT 'FATs,'
         return PERROR( L 'and' MINDIR 'root dir. sectors' )
      end
      when  USE1ST   then  say 'Uses a' L
      when  F.0 = 1  then  L = 'Pick a' L
      otherwise   L = 'Pick a..' || d2c( F.0 - 1 + c2d( 'a' )) L
   end
   do while N = 0                /* does nothing for USE1ST = 1   */
      say L                      ;  pull N
      N = strip( N )             ;  if N = ''   then  return 1

      if datatype( N, 'w' )   then  do CLOOP = 1 to F.0
         if N = word( F.CLOOP, 5 )  then  do
            N = d2c( CLOOP - 1 + c2d( 'A' ))
            leave CLOOP          /* convert any visible numerical */
         end                     /* cluster size to shown choices */
      end CLOOP                  /* abcdefgh or less, upper case: */

      if length( N ) = 1      then  N = pos( N, 'ABCDEFGH' )
                              else  N = 0
      if N < 1 | F.0 < N      then  N = 0
   end

   L = ( NOS + PARTED ) * SECLEN
   if 0 <= SPARSE & SPARSE <= L  then  do
      L = 'cannot format' L 'bytes for' VFD '(free:' SPARSE || ')'
      return PERROR( L )         /* SPARSE requires NTFS + FSUTIL */
   end
   if stream( VFD, 'c', 'query exists' ) <> ''  then  do
      call UTIL 'SysFileDelete'  ;  L = SysFileDelete( VFD )
      if L <> 0   then  return PERROR( L || ': cannot create' VFD )
   end

   /* ----------------------------------------------------------- */
   parse var F.N FAT RES FS DIR CS CN
   call charout VFD, '', 1       /* triggers error on r/o medium  */

   select                        /* hardwire old well-known sizes */
      when  SECLEN <> 512  then  N = x2c( 'F0' )      /* unknown  */
      when  V512E          then  N = x2c( 'F0' )      /* any 512e */
      when  FAT <> 12      then  N = x2c( 'F0' )      /* unknown  */
      when  NOS = 5760     then  N = x2c( 'F0' ) 2 36 /* 2880 KB  */
      when  NOS = 3360     then  N = x2c( 'F0' ) 2 21 /* 1680 KB  */
      when  NOS = 2880     then  N = x2c( 'F0' ) 2 18 /* 1440 KB  */
      when  NOS = 2400     then  N = x2c( 'F9' ) 2 15 /* 1200 KB  */
      when  NOS = 1440     then  N = x2c( 'F9' ) 2  9 /*  720 KB  */
      /* single sided 80 * 1 * 8 for x2c( 'FA' ) skipped (320 KB) */
      when  NOS = 1280     then  N = x2c( 'FB' ) 2  8 /*  640 KB  */
      when  NOS =  360     then  N = x2c( 'FC' ) 1  9 /*  180 KB  */
      when  NOS =  720     then  N = x2c( 'FD' ) 2  9 /*  360 KB  */
      when  NOS =  320     then  N = x2c( 'FE' ) 1  8 /*  160 KB  */
      when  NOS =  640     then  N = x2c( 'FF' ) 2  8 /*  320 KB  */
      otherwise                  N = x2c( 'F0' )      /* unknown  */
   end                           /* maybe 'FA' NUMFAT = 1 RAMdisk */

   parse var N MEDIA NOH SPT     /* MAKEMBR ignores floppy format */
   if words( N ) = 1 then  do
      parse value NOSTRA( NOS + PARTED ) with NOH SPT
      VIRGIN = x2c( 0 )          /* format empty sectors with 00h */
   end
   select                        /* MAKEMBR uses F8 for hard disk */
      when  PARTED            then  MEDIA = MAKEMBR( VFD, NOS, FAT )
      when  INT13H = ''       then  nop
      when  INT13H = NOH SPT  then  nop
      otherwise                     MEDIA = x2c( 'F0' )
   end                           /* check legacy MEDIA descriptor */

   BUF = x2c( 'E9' )             ;  N = 62      /* offset: 00h  0 */
   if FAT = 32       then  N = 90
   BUF = BUF || RD2C(   N - 3 ,  2 )            /* offset: 01h  1 */
   BUF = BUF || left(   OEMID ,  8 )            /* offset: 03h  3 */
   BUF = BUF || RD2C(   SECLEN,  2 )            /* offset: 0Ch 11 */
   BUF = BUF || RD2C(   CS    ,  1 )            /* offset: 0Dh 13 */
   BUF = BUF || RD2C(   RES   ,  2 )            /* offset: 0Eh 14 */
   BUF = BUF || RD2C(   NUMFAT,  1 )            /* offset: 10h 16 */
   N = DIR * SECLEN % 32         /* FAT1x: entries, FAT32: 0      */
   BUF = BUF || RD2C(   N     ,  2 )            /* offset: 11h 17 */
   N = NOS * ( NOS < 2**16 )     /* FAT12: always,  FAT32: never  */
   BUF = BUF || RD2C(   N     ,  2 )            /* offset: 13h 19 */
   BUF = BUF || left(   MEDIA ,  1 )            /* offset: 15h 21 */
   N = FS * ( FAT <> 32 )
   BUF = BUF || RD2C(   N     ,  2 )            /* offset: 16h 22 */
   BUF = BUF || RD2C(   SPT   ,  2 )            /* offset: 18h 24 */
   BUF = BUF || RD2C(   NOH   ,  2 )            /* offset: 1Ah 26 */
   BUF = BUF || RD2C(   PARTED,  4 )            /* offset: 1Ch 28 */
   N = NOS * ( 2**16 <= NOS )    /* FAT12: never,   FAT32: always */
   BUF = BUF || RD2C(   N     ,  4 )            /* offset: 20h 32 */
   if FAT = 32 then  do          /* insert 28 bytes for FAT32 BPB */
      BUF = BUF || RD2C(   FS ,  4 )            /* offset: 24h 36 */
      BUF = BUF || RD2C(   0  ,  2 )            /* offset: 28h 40 */
      BUF = BUF || RD2C(   0  ,  2 )            /* offset: 2Ah 42 */
      BUF = BUF || RD2C(   2  ,  4 )            /* offset: 2Ch 44 */
      BUF = BUF || RD2C(   1  ,  2 )            /* offset: 30h 48 */
      N = 3 + 3 * ( 9 <= RES )   /* for 7 or 8 backup @3, else @6 */
      BUF = BUF || RD2C(   N  ,  2 )            /* offset: 32h 50 */
      BUF = BUF || RD2C(   0  , 12 )            /* offset: 34h 52 */
   end
   N = PARTED * 128                             /*  FAT1x,  FAT32 */
   BUF = BUF || RD2C(   N     ,  1 )            /* 24h 36, 40h 64 */
   BUF = BUF || RD2C(   0     ,  1 )            /* 25h 37, 41h 65 */
   BUF = BUF || RD2C(   41    ,  1 )            /* 26h 38, 42h 66 */
   BUF = BUF || left( VOLSER  ,  4 )            /* 27h 39, 43h 67 */
   BUF = BUF || left( LABEL   , 11 )            /* 2Bh 43, 47h 71 */
   N = 'FAT' || FAT
   BUF = BUF || left(   N     ,  8 )            /* 36h 54, 52h 82 */

   if 256 <= SECLEN  then  do                   /* 3Eh 62, 5Ah 90 */
      BUF = BUF || x2c( 'E84B0062 6F6F7420 636F6465 20706C61' )
      BUF = BUF || x2c( '6365686F 6C646572 20666F72 200056AC' )
      BUF = BUF || x2c( '0AC07409 BB0700B4 0ECD10EB F25EC306' )
      BUF = BUF || x2c( '57501E07 8BFAB804 0091C1C0 0450240F' )
      BUF = BUF || x2c( '3C0A1C69 2FAA58E2 F191585F 07C30E1F' )
      BUF = BUF || x2c( 'BF2000BE 037C897C 08E8C2FF 5EE8BEFF' )
      BUF = BUF || x2c( '83EE0B89 7C08E8B5 FF893C83 EE0BE8AD' )
      BUF = BUF || x2c( 'FFC7042D 0083EE04 8BD68B4C 028B04E8' )
      BUF = BUF || x2c( 'ADFF91E8 98FF897C 04E8A3FF E88FFF98' )
      BUF = BUF || x2c( 'CD16CD18 CD19' )       /* FAT32: F0h 240 */
   end                                          /* FAT1x: D4h 212 */
   else  BUF = BUF || x2c( 'CD18' )             /* tiny boot code */

   VBR = MAGIC( BUF )            ;  call NEXTSEC VFD, VBR

/* WASM source of VBR code ======================================>>>
DGROUP   group  _TEXT
_TEXT    segment use16 para public 'CODE'
         .386
         assume cs:DGROUP, ds:DGROUP, es:nothing, ss:nothing
         org    7C00h           ;offset used to find oemid

vbr      proc   far             ;assume good unknown stack
         jmp    near ptr code   ;CAVEAT: fix jump for FAT1x
oemid    db     "REXXFAT "

         db     55 dup (?)      ;test worst case FAT32 BPB
         db     29h             ;CAVEAT: code designed for
         db     12h,34h,56h,78h ; offset -26 from code +3
         db     "VolumeLabel"   ; offset -22 from code +3
         db     "VolumeFS"      ; offset -11 from code +3

code:    call   pout            ;"push IP", does not return
         db     "boot code placeholder for ",0
vbr      endp

show     proc   near            ;clobbers AX and BX
         push   si

next:    lodsb                  ;DS:SI message ASCIIZ
         or     al,al           ;AL = ASCII or NUL (Z)
         jz     done            ;AL = 0 terminator (Z)
         mov    bx,7            ;BL = 7 white on black
         mov    ah,0Eh          ;AH = 0Eh TTY output
         int    10h             ;BH = 0 display page
         jmp    next

done:    pop    si
         retn                   ;AL = 0
show     endp

x2c      proc   near            ;CX to ASCII (result buffer DS:DX) +++++
         push   es
         push   di              ;keeps ES:DI and CX
         push   ax              ;keeps DS:DX and AX

         push   ds
         pop    es
         mov    di,dx           ;ES:DI result DS:DX
         mov    ax,4            ;AX = 4 hex. digits
         xchg   cx,ax           ;AX = CX, CX = 4

nibble:  rol    ax,4
         push   ax
         and    al,0Fh          ;++++++++ X2C credits to Tim Lopez +++++
         cmp    al,0Ah          ;0..9  C; -6A 96..9F C  A; -66 30..39
         sbb    al,69h          ;A..F NC; -69 A1..A6 C NA; -60 41..46
         das                    ;read NC = No Carry, C NA = C + No Aux.
         stosb                  ;ASCII result
         pop    ax
         loop   nibble

         xchg   cx,ax           ;restore CX
         pop    ax              ;restore AX
         pop    di              ;restore DI
         pop    es              ;restore ES (result pointer DS:DX) +++++
         retn
x2c      endp

pout     proc   near
         push   cs
         pop    ds
         mov    di,20h          ;DI = SPace + NUL
         mov    si,offset oemid
         mov    [si+8],di       ;oemid to ASCIIZ
         call   show
         pop    si              ;SI = offset code + 3
         call   show
         sub    si,11           ;SI = offset code - 8
         mov    [si+8],di       ;FATxx to ASCIIZ
         call   show
         mov    [si],di         ;label to ASCIIZ
         sub    si,11           ;SI = offset code - 19
         call   show
         mov    word ptr [si],"-"
         sub    si,4            ;SI = offset code - 23
         mov    dx,si           ;DX = X2C output buffer
         mov    cx,[si+2]       ;high word volume ID
         mov    ax,[si+0]       ; low word volume ID
         call   x2c             ;high X2C, input: CX
         xchg   ax,cx
         call   show
         mov    [si+4],di       ;hyphen "-" to SPace
         call   x2c             ; low X2C, input: CX
         call   show
         cbw
         int    16h             ;AH = 0 (press any key)
         int    18h             ;no boot partition
         int    19h             ;INT 18h could IRET (joke)
pout     endp

_TEXT    ends
         end    vbr
<<<============================================================== */

   if FAT = 32 then  do
      BUF = MAGIC( x2c( 0 ))     ;  BUF = FSINFO( BUF, CN - 1, 2 )
      call NEXTSEC VFD, BUF      ;  BUF = MAGIC( x2c( 0 ))
      call NEXTSEC VFD, BUF      ;  BUF = FSINFO( BUF, -1, -1 )

      if 9 <= RES then  do       /* adds 3 zero sectors for 6 + 3 */
         call FILLSEC VFD, 3     ;  call NEXTSEC VFD, VBR
         call NEXTSEC VFD, BUF   ;  BUF = MAGIC( x2c( 0 ))
         call NEXTSEC VFD, BUF   ;  call FILLSEC VFD, RES - 6 - 3
      end
      else  do                   /* no zero sectors for 2 * 3 + 1 */
         call NEXTSEC VFD, VBR   ;  call NEXTSEC VFD, BUF
         BUF = MAGIC( x2c( 0 ))  ;  call NEXTSEC VFD, BUF
         call NEXTSEC VFD, VBR   ;  call FILLSEC VFD, RES - 7
      end

      DIR = DIR + CS             ;  CN = CN - 1
      BUF = copies( RD2C( x2d( 0FFFFFFF ), 4 ), 3 )
   end                           /* 3rd FAT32 entry for root dir. */
   else  do
      call FILLSEC VFD, RES - 1  /* in theory RES > 1 is allowed  */
      BUF = RD2C( -1, 3 + ( FAT = 16 ))
   end                           /* V512E FAT1x: RES = 8 - PARTED */

   BUF = left( overlay( MEDIA, BUF ), SECLEN, x2c( 0 ))
   do N = 1 to NUMFAT * sign( FS )
      call NEXTSEC VFD, BUF      ;  call FILLSEC VFD, FS - 1
   end N                         /* allow bad experimental FS = 0 */

   RES = PARTED + RES + NUMFAT * FS + DIR
   call FILLSEC VFD, DIR         /* start of sparse: RES * SECLEN */

   if SPARSE < 0  then  call SPARSEC VFD, CS * CN, RES * SECLEN
                  else  call FILLSEC VFD, CS * CN, VIRGIN
   if PARTED = 0  then  do
      PAD = max( 0, MINVFD % SECLEN - NOS )
      if PAD > 0  then  do
         call FILLSEC VFD, PAD, x2c( 'FF' )
         call PERROR 'VFD padded to min.' MINVFD % SECLEN 'sectors'
         PAD = SECLEN * PAD
      end
   end
   else  PAD = MAKEVHD( VFD, PARTED + NOS )

   N = stream( VFD, 'c', 'query size' ) - PAD
   if N / SECLEN <> NOS + PARTED then  do
      return PERROR( N / SECLEN '<>' NOS + PARTED )
   end                           /* last chance for stupid errors */
   N = c2x( reverse( VOLSER ))   ;  call charout VFD
   N = '[' || left( N, 4 ) || '-' || right( N, 4 ) || ']'
   if SPARSE < 0  then  say   'created' N 'in sparse' VFD
                  else  say   'created' N 'in output' VFD
   return 0                      /* small VFD might be not sparse */

/* -------------------------------------------------------------- */
FSINFO:  procedure expose SECLEN /* FSinfo FREE clusters, LAST 2, */
   parse arg BUF, FREE, LAST     /* FSinfo backup gets -1 unknown */
   OFS = min( 484, SECLEN - 28 ) /* expect SECLEN <> 512 to fail  */
   BUF = overlay( 'RRaA'         , BUF, 1 )
   BUF = overlay( 'rrAa'         , BUF, 1 + OFS )
   BUF = overlay( RD2C( FREE, 4 ), BUF, 5 + OFS )
   BUF = overlay( RD2C( LAST, 4 ), BUF, 9 + OFS )
   return BUF

/* -------------------------------------------------------------- */
MAGIC:   procedure expose SECLEN
   parse arg BUF                 ;  LEN = length( BUF )

   if LEN <= min( 510, SECLEN - 2 ) then  do
      BUF = left( BUF, SECLEN - 2, x2c( 0 )) || x2c( 55AA )
      if SECLEN > 512            /* second magic at offset 510:   */
         then  return overlay( x2c( 55AA ), BUF, 510 + 1 )
         else  return BUF
   end                           /* catch stupid errors a.s.a.p.: */
   exit TRAP( LEN '+ 2 >' min( SECLEN, 512 ))

/* -------------------------------------------------------------- */
MAKEMBR: procedure expose SECLEN INT13H ACTIVE
   parse arg VFD, NOS, FAT       ;  L = NOS

   parse value NOSTRA( L + 1 ) with NOH SPT
   S = L // SPT                  ;  C = ( L - S ) % SPT
   H = C // NOH                  ;  C = ( C - H ) % NOH
   L = ( C * NOH + H ) * SPT + S ;  S = S + 1
   if L <> NOS then  exit TRAP( '(' || C H S || ')' L '<>' NOS )

   L = ( C > 1023 )              /* if INT 13h extension required */
   if L  then  parse value 1023 254 63 with C H S
   select                        /* FAT12/16/32 partition types:  */
      when  FAT = 32 & L            then  FAT = 0C
      when  FAT = 32                then  FAT = 0B
      when  FAT = 16 & L            then  FAT = 0E
      when  FAT = 16 & NOS > 65535  then  FAT = 06
      when  FAT = 16                then  FAT = 04
      when  FAT = 12                then  FAT = 01
   end                           /* move 2 high bits from C to S: */
   L = C % 256                   ;  S = L * 64 + S
   C = C // 256                  ;  L = d2x( 128 * ACTIVE, 2 )

   BUF =        x2c( '33C08ED0 8BE08ED8 8EC0FBFC BE007C8B' )
   BUF = BUF || x2c( 'FEB91000 F3AAC604 10C64402 06897404' )
   BUF = BUF || x2c( 'BF00EC56 57B90008 F3A5E900 705E5F8D' )
   BUF = BUF || x2c( '9CFE018B EB813F55 AA7539B1 0483EB10' )
   BUF = BUF || x2c( '803F80E0 F8752D66 FF770866 8F440887' )
   BUF = BUF || x2c( 'DDB442CD 13721D81 BF009055 AA75158B' )
   BUF = BUF || x2c( 'F5FFE70D 0A524558 58464154 20626F6F' )
   BUF = BUF || x2c( '74203000 6633ED66 896C08C6 44020656' )
   BUF = BUF || x2c( '53BE63EC 80F2B088 540FAC0A C07409BB' )
   BUF = BUF || x2c( '0700B40E CD10EBF2 5B5E9899 CD163C20' )
   BUF = BUF || x2c( '74113C61 74AB3C30 720B3C39 770734B0' )
   BUF = BUF || x2c( '92EB9ECD 18CD19CB' )
   select                        /* ----------------------------- */
      when  SECLEN < 128 | 256 < length( BUF ) + 72
      then  exit TRAP( 'Unexpected sector or MBR code length' )
      when  SECLEN = 128         /* below 512 is only theoretical */
      then  BUF = x2c( 'CD18' )  /* if 128 use 72 + dummy INT 18h */
      when  substr( BUF, 50, 2 ) <> RD2C( 510, 2 )
      then  exit TRAP( 'Cannot patch MAGIC offset in MBR code' )
      when  SECLEN = 256         /* if 256 replace 01FEh by 00FEh */
      then  BUF = overlay( x2c( 0 ), BUF, 51 )
      otherwise   nop            /* if 512 or more magic at 01FEh */
   end                           /* ----------------------------- */

   BUF = left( BUF, min( SECLEN, 512 ) - 72, x2c( 0 ))
   BUF = BUF || MAKEID( 0 )      /* 72 = 4 +2 + 4 * 16 +2 : 01B8h */
   BUF = BUF || x2c( 0000 )      /* unclear zeros at offset 01BCh */
   BUF = BUF || x2c( L 00 02 00 FAT )
   BUF = BUF || d2c( H ) || d2c( S ) || d2c( C )
   BUF = BUF || RD2C( 1, 4 ) || RD2C( NOS, 4 )
   BUF = MAGIC( BUF )
   call NEXTSEC VFD, BUF         ;  return x2c( 'F8' )

/* WASM source of MBR code ======================================>>>
DGROUP   group  _TEXT
_TEXT    segment use16 para public 'CODE'
         .386
         assume cs:nothing, ds:DGROUP, es:DGROUP, ss:DGROUP

MAGIC    equ    512-2
MOVED    equ    7000h           ;moved offset
         org    7C00h

mbr      proc   far             ;SS:SP unknown (0000:0400h)
         xor    ax,ax
         mov    ss,ax           ;implicit LOCK, GPF in PM
         mov    sp,ax           ;SS:SP defined (0000:0000h)
         mov    ds,ax
         mov    es,ax
         sti                    ;allow interrupt
         cld
         mov    si,offset mbr
         mov    di,si           ;DI = offset MBR
         mov    cx,16           ;LBA packet size
         rep    stosb           ;clear LBA packet
         mov    byte ptr [si+00],16     ;LBA packet size
         mov    byte ptr [si+02],6      ;max. 6 * 4096
         mov    word ptr [si+04],si     ;offset mbr
         mov    di,offset mbr + MOVED
         push   si              ;SI = offset mbr
         push   di              ;DI = offset mbr + MOVED
         mov    cx,2048
         rep    movsw           ;copy 4096 bytes
         jmp    near ptr here + MOVED

here:    pop    si              ;SI = offset mbr + MOVED
         pop    di              ;DI = offset mbr
         lea    bx,[si+MAGIC]   ;patch code for sector size
         mov    bp,bx           ;BP = offset MAGIC
         cmp    word ptr [bx],0AA55h
         jne    fail
         mov    cl,4            ;CX = 4 partitions

scan:    sub    bx,16           ;BX = offset entry
         cmp    byte ptr [bx],80h
         loopne scan
         jne    fail            ;FIXME: extended partition

         push   dword ptr [bx+08]       ;LBA dword (32 bits)
         pop    dword ptr [si+08]       ;copy to LBA packet
         xchg   bp,bx           ;BX = offset MAGIC

read:    mov    ah,42h          ;DL set by BIOS or below
         int    13h             ;SI = offset mbr + MOVED
         jc     fail
         cmp    word ptr [bx-MOVED],0AA55h
         jne    fail            ;BX = offset MAGIC
         mov    si,bp           ;SI = offset entry (or 0)
         jmp    di              ;DI = offset mbr

emsg     db     0Dh,0Ah,"REXXFAT boot 0",0
DIGIT    equ    $ - offset emsg - 2

fail:    xor    ebp,ebp         ;keep BX, SI, DI for read 0
         mov    dword ptr [si+08],ebp   ;LBA 0 (MBR sector)
         mov    byte ptr [si+02],6      ;max. 6 * 4096
         push   si              ;SI = offset mbr + MOVED
         push   bx              ;BX = offset MAGIC

         mov    si,offset emsg + MOVED
         xor    dl,10110000b    ;80..89h to 30..39h
         mov    [si+DIGIT],dl
next:    lodsb                  ;DS:SI message ASCIIZ
         or     al,al           ;AL = ASCII or NUL (Z)
         jz     keyb            ;AL = 0 terminator (Z)
         mov    bx,7            ;BL = 7 white on black
         mov    ah,0Eh          ;AH = 0Eh TTY output
         int    10h             ;BH = 0 display page
         jmp    next

keyb:    pop    bx              ;BX = offset magic
         pop    si              ;SI = offset mbr + MOVED
         cbw                    ;AX = 0 (byte to  word)
         cwd                    ;DX = 0 (word to dword)
         int    16h             ;AH = 0 (get keystroke)
         cmp    al,20h
         je     exit
         cmp    al,61h
         je     read            ;DL = 0 first floppy
         cmp    al,30h
         jb     boot
         cmp    al,39h
         jnbe   boot
         xor    al,10110000b    ;30..39h to 80..89h
         xchg   dx,ax           ;DL = disk number
         jmp    read

exit:    int    18h             ;found no boot partition
boot:    int    19h
         ret
mbr      endp
_TEXT    ends
         end    mbr
<<<============================================================== */
/* -------------------------------------------------------------- */
NEXTSEC: procedure expose SECLEN /* assert SECLEN + write sector  */
   parse arg VFD, BUF
   if length( BUF ) = SECLEN  then  return charout( VFD, BUF )
   exit TRAP( length( BUF ) '<>' SECLEN )

/* -------------------------------------------------------------- */
FILLSEC: procedure expose SECLEN /* fill N sectors, default NUL:  */
   parse arg VFD, N, PAD         ;  BLK = 1024 * 1024 % SECLEN
   if PAD = '' then  PAD = x2c( 0 )
   BUF = copies( PAD, BLK * SECLEN )

   do while N > 0
      if N < BLK  then  BUF = left( BUF, N * SECLEN )
      N = N - BLK                ;  call charout VFD, BUF
   end
   return

/* -------------------------------------------------------------- */
SPARSEC: procedure expose SECLEN /* zero fill N "sparse" sectors: */
   parse arg VFD, N, ZAP         ;  BLK = 1024 * 1024 % SECLEN
   BUF = copies( x2c( 0 ), BLK * SECLEN )

   LEN = 0                       ;  call charout VFD
   address CMD 'FSUTIL SPARSE SETFLAG "' || VFD || '"'

   do while N > 0
      if N < BLK  then  do
         BLK = N                 ;  BUF = left( BUF, N * SECLEN )
      end
      N = N - BLK                ;  call charout VFD, BUF
      LEN = LEN + BLK * SECLEN   ;  call charout VFD
      address CMD 'FSUTIL SPARSE SETRANGE "' || VFD || '"' ZAP LEN
   end
   return

/* -------------------------------------------------------------- */
MAKEVHD: procedure expose SECLEN INT13H MINVHD
   parse arg VFD, LEN            /* result 0: no VHD footer added */
   if SECLEN <> 512 | LEN <= MINVHD then  return 0

   parse value NOSTRA( LEN ) with H S
   C = LEN % ( H * S )
   L = 2
   do while H > 16 & L < 256
      parse value PRIMINI( L H C ) with L H C
   end
   L = 2
   do while S * L < 256 & L <= min( 63, C )
      parse value PRIMINI( L C S ) with L C S
   end
   if 65535 < C   then  parse value 65535 16 255 with C H S

   BUF = left( 'conectix', 8 )   /* 2 = reserved VHD feature flag */
   BUF = BUF || d2c(  2, 4 ) || d2c(  1, 2 ) /* flags 2, major 1  */
   BUF = BUF || d2c(  0, 2 ) || d2c( -1, 8 ) /* minor 0, data -1  */
   N = time( 'T' ) - date( 'T', 20000101, 'S' )
   BUF = BUF || d2c(  N, 4 )     /* seconds since 2000-01-01      */
   BUF = BUF || 'REXX'           ;  parse version . N .
   L = trunc( N )                ;  N = trunc( 100 * ( N - L ))
   BUF = BUF || d2c(  L, 2 ) || d2c(  N, 2 ) /* REXX version L.xy */
   BUF = BUF || 'Wi2k'           /* host OS (Wi2k for Windows NT) */
   N = SECLEN * LEN              /* original = current size       */
   BUF = BUF || d2c(  N, 8 ) || d2c(  N, 8 )
   BUF = BUF || d2c(  C, 2 ) || d2c(  H, 1 ) || d2c(  S, 1 )
   BUF = BUF || d2c(  2, 4 )     /* VHD type 2 (fixed)            */
   do N = 1 to 16                /* 16 bytes UUID v4 RFC 4122,    */
      select                     /* randomize 122 of 128 bits:    */
         when  N = 7 then  BUF = BUF || d2c( 128 + random(  63 ))
         when  N = 9 then  BUF = BUF || d2c(  64 + random(  15 ))
         otherwise         BUF = BUF || d2c(       random( 255 ))
      end
   end N

   CHK = 0                       ;  L = length( BUF )
   do N = 1 to L                 /* checksum inserted before UUID */
      CHK = CHK + c2d( substr( BUF, N, 1 ))
   end N
   CHK = bitxor( d2c( CHK, 4 ),, x2c( 'FF' ))
   BUF = left( BUF, L - 16 ) || CHK || substr( BUF, L - 15 )
   BUF = left( BUF, SECLEN - 1, x2c( 0 ))
   call charout VFD, BUF         ;  return SECLEN - 1

/* -------------------------------------------------------------- */
FATSIZE: procedure expose SECLEN /* convert cluster number CN to  */
   parse arg CN, FAT, V512E      /* required FAT12/16/32 sectors: */
   FAT = ((( CN + 2 ) * FAT + 4 ) % 8 + SECLEN - 1 ) % SECLEN
   if V512E then  return 8 * (( FAT + 7 ) % 8 )
            else  return FAT     /* needs multiple of 8 for V512E */

/* -------------------------------------------------------------- */
RD2C:    return reverse( d2c( arg( 1 ), arg( 2 )))
PERROR:  return sign( 1 + lineout( 'stderr', arg( 1 )))

/* -------------------------------------------------------------- */
MAKEID:  procedure               /* emulate DOS idea of unique ID */
   parse value date( 'S' ) time( 'L' )    with YYYY 5 MM 7 DD X
   parse value translate( X, '  ', ':.' ) with HH NN SS X
   MM = ( MM * 256 + DD ) + SS * 256 + left( X, 2 ) + arg( 1 )
   HH = ( HH * 256 + NN ) + YYYY
   return RD2C( HH * 65536 + MM, 4 )

/* -------------------------------------------------------------- */
NOSTRA:  procedure expose INT13H /* get H S in dummy CHS geometry */
   if INT13H <> ''      then  return INT13H

   parse arg N
   S = min( N, 256 * 63 )        ;  ATA = ( 1024 * 256 * 63 <= N )

   do T = S to 4 by -1           /* 4 or more sectors per track   */
      if sign( N // T ) then  iterate T
      if ATA | N % T <= 1023  then  do S = min( T, 63 ) to 4 by -1
         if T // S = 0  then  do
            H = T % S            /* T = H * S (heads * sectors)   */
            if H > 256  then  iterate T
                        else  return H S
         end
      end S
      else  if ATA = 0  then  leave T
   end T                         /* for more than 1023 cylinders: */
   return 255 63                 /* well-known dummy (not 256 63) */

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
VFDPATH: procedure expose SPARSE /* determine the VFD output path */
   parse arg TYPE                ;  SPARSE = copies( 9, digits())
   parse source VFD . DIR        ;  SEP = '\'
   if VFD = 'LINUX'  then  SEP = '/'
   DIR = substr( DIR, 1 + lastpos( SEP, DIR ))
   VFD = left(   DIR,     lastpos( '.', DIR )) || TYPE
   DIR = directory()             /* VFD file in current directory */
   if right( DIR, 1 ) <> SEP  then  DIR = DIR || SEP
   VFD = DIR || VFD              ;  DIR = left( DIR, 2 )
   if SEP = '/'   then  return VFD

   call UTIL 'SysDriveInfo'      /* get free space on given drive */
   call UTIL 'SysFileSystemType' /* on NTFS use FSUTIL for sparse */
   call UTIL 'SysSearchPath'     /* use first FSUTIL.exe in PATH  */
   parse value SysDriveInfo( DIR ) with . SPARSE .
   if translate( TYPE ) <> 'VHD' then  do
      if 'NTFS' = SysFileSystemType( DIR )   then  do
         if SysSearchPath( 'PATH', 'FSUTIL.EXE' ) <> ''  then  do
            SPARSE = 0 - SPARSE  /* 99...99: fake LINUX max. free */
         end                     /*  n: max. free, no FSUTIL NTFS */
      end                        /* -n: ditto, FSUTIL SPARSE okay */
   end                           /* VHD does not like sparse file */
   return VFD

/* -------------------------------------------------------------- */
USAGE:   procedure expose OEMID
   if arg( 1 ) <> '' then  say 'Error:' arg( 1 ) d2c( 7 )
                     else  say
   parse source . . THIS
   say 'Usage:' THIS 'SECTORS [MINDIR [NUMFAT [SECLEN]]]'
   say OEMID 'for NTFS and Windows NT ooREXX.'
   say
   THIS  =  'The default MINDIR number is 8. '
   say THIS 'For FAT1x there will be MINDIR or'
   THIS  =  'more root dir. sectors (FAT32: 0). '
   say THIS 'Default NUMFAT: 2, SECLEN: 512.'
   say
   THIS  =  'You can interactively pick one of'
   say THIS 'up to eight possible cluster sizes'
   THIS  =  'for SECTORS <' 2**32 '(2^32). '
   say THIS 'Output:' VFDPATH( 'vfd' )
   say
   THIS  =  'If you want a fixed VHD disk image'
   say THIS 'give a negative number of SECTORS.'
   THIS  =  'The partition begins in the second'
   say THIS 'sector directly after the MBR with'
   THIS  =  'no gap.  VHD footer = 511 bytes. '
   say THIS 'Output:' VFDPATH( 'vhd' )
   return 1

/* -------------------------------------------------------------- */
FATTEST: procedure               /* self tests need admin rights  */
   /* REXXFAT( 1, sectors, dir., FATs, size )  [expected failure] */
   TEST.1   =           4     1     1        /* minimal FAT12 VFD */
   TEST.2   =           4     1     1   512  /* SECLEN  512   VFD */
   TEST.3   =           4     1     1  8192    'SECLEN 8192'
   TEST.4   =           4     1     1    64    'SECLEN 64'
   TEST.5   =           4     1     1  4096  /* SECLEN 4096   VFD */
   TEST.6   =           4     1     1   128  /* SECLEN  128   VFD */
   TEST.7   =           4     1     2     .    '1+2+1+1 = 5 > 4'
   TEST.8   =           4     2     1     .    '1+1+2+1 = 5 > 4'
   TEST.9   =           4     0     2     .    'no DIR in FAT1x'
   TEST.10  =           4     1     0     .    'no FAT in FATFS'
   TEST.11  =          20     2    16        /* 16 FATs supported */
   TEST.12  =          20     1    17     .    'too many FATs'
   TEST.13  =          24     8     1     0    '8+ 8+8+8=32 >24'
   TEST.14  =          36     8     1     0    '36 is not n*8'
   TEST.15  =          32     6     1     0    ' 6 is not n*8'
   TEST.16  =          32     8     2     0    '8+16+8+8=40 >32'
   TEST.17  =          32     8     1     0  /* minimal  512e VFD */
   TEST.18  =       66557     0              /* RS =  7 FAT32 VFD */
   TEST.19  =       66565     .              /* RS = 15 FAT32 VFD */
   TEST.20  =      525240     0     .     0  /* RS =  8  512e VFD */
   TEST.21  =      525248     .     .     0  /* RS = 16  512e VFD */
   TEST.22  =         -17     1              /* minimal FAT12 VHD */
   TEST.23  =         -32     8     1     0  /* minimal  512e VHD */
   TEST.24  =       -4142    32              /*    4084 FAT12 VHD */
   TEST.25  =       -4151    32     . '-512' /* !  4085 FAT16 bug */
   TEST.26  =       -4152    32              /*    4086 FAT16 VHD */
   TEST.28  =      -66070    32              /*   65524 FAT16 VHD */
   TEST.29  =      -66565     .     . '-512' /* ! 65525 FAT32 bug */
   TEST.30  =      -66566     .              /*   65526 FAT32 VHD */
   TEST.31  =      -66558     0              /*   65526 FAT32 VHD */
   /*          -272629756 untested, last FAT32 cluster size 1 VHD */

   do N = 1 while symbol( 'TEST.' || N ) = 'VAR'
      call PERROR 'test' right( N - 1, 2 ) || ': PASS'
      call PERROR copies( '-', 79 )
      parse var TEST.N NOS MINDIR NUMFAT SECLEN EXTRA
      call PERROR 'test' right( N, 2 ) || ': REXXFAT' TEST.N
      if NOS < 0  then  do
         call PERROR 'press ENTER for CHKDSK' VFDPATH( 'vhd' )
         pull ERR
         if ERR <> ''   then  return PERROR( 'self tests aborted' )
      end

      ERR = REXXFAT( 1, NOS, MINDIR, NUMFAT, SECLEN )
      if ERR <> 0 then  do
         if EXTRA <> '' then  iterate N
                        else  return PERROR( 'test' N 'FAIL MIA' )
      end                        /* wanted no error, got ERR <> 0 */
      if EXTRA <> ''    then  return PERROR( 'test' N 'FAIL' EXTRA )
      if NOS < 0  then  do
         address CMD 'chkdsk' ATTACH( NOS )
         ERR = rc                ;  call ATTACH 0
         if ( ERR = 0 ) = ( SECLEN = -512 )  then  do
            return PERROR( 'test' N 'FAIL: CHKDSK exit code' ERR )
         end
      end
   end N
   call PERROR 'test' right( N - 1, 2 ) || ': PASS'
   call PERROR copies( '-', 79 )
   call PERROR 'self tests okay'
   return 0

/* -------------------------------------------------------------- */
ATTACH:  procedure               /* attach VHD file for FATTEST() */
   parse arg NOS                 ;  NOS = abs( NOS )
   TMP = VFDPATH( 'tmp' )        ;  call UTIL 'SysDriveMap'
   VHD = VFDPATH( 'vhd' )        ;  call UTIL 'SysFileDelete'
   LEN = 0 || stream( VHD, 'c', 'query size' )
   OBS = LEN - 511               ;  signal off error
   if OBS // 512 = 1 then  OBS = LEN - 512
   if OBS // 512 = 0 then  OBS = NOS <> 0 & OBS <> NOS * 512
   if OBS <> 0 then  exit PERROR( 'missing or unexpected' VHD )

   call SysFileDelete TMP        ;  OBS = SysDriveMap()
   LEN = 0 || stream( TMP, 'c', 'query size' )
   if LEN <> 0 then  exit PERROR( 'cannot delete' TMP )
   call lineout TMP, 'select vdisk file="' || VHD || '"'
   if NOS = 0  then  call lineout TMP, 'detach vdisk'
               else  call lineout TMP, 'attach vdisk'
   call lineout TMP, 'exit'      ;  call lineout TMP
   address CMD '@diskpart /S "' || TMP || '">NUL'
   if rc <> 0  then  exit PERROR( 'diskpart /S' TMP '[' rc ']' )
   call SysFileDelete TMP        ;  MAP = SysDriveMap()
   parse var MAP OBJ MAP
   do while sign( wordpos( OBJ, OBS ))
      parse var MAP OBJ MAP      /* ignore race conditions, first */
   end                           /* new drive letter for test VHD */
   if NOS = 0 | OBJ <> ''  then  return OBJ
   exit PERROR( 'cannot attach' VHD )

/* -------------------------------------------------------------- */
/* see <URL:http://purl.net/xyzzy/rexxtrap.htm>, (c) F. Ellermann */

UTIL: procedure                  /* load necessary RexxUtil entry */
   if RxFuncQuery(  arg( 1 )) then
      if RxFuncAdd( arg( 1 ), 'RexxUtil', arg( 1 )) then
         exit TRAP( "can't add RexxUtil"  arg( 1 ))
   return 0

TRAP:                            /* select REXX exception handler */
   call trace 'O' ;  trace N           /* don't trace interactive */
   parse source TRAP                   /* source on separate line */
   TRAP = x2c( 0D ) || right( '+++', 10 ) TRAP || x2c( 0D0A )
   TRAP = TRAP || right( '+++', 10 )   /* = standard trace prefix */
   TRAP = TRAP strip( condition( 'c' ) 'trap:' condition( 'd' ))
   select
      when wordpos( condition( 'c' ), 'ERROR FAILURE' ) > 0 then do
         if condition( 'd' ) > ''      /* need an additional line */
            then TRAP = TRAP || x2c( 0D0A ) || right( '+++', 10 )
         TRAP = TRAP '(RC' rc || ')'   /* any system error codes  */
         if condition( 'c' ) = 'FAILURE' then rc = -3
      end
      when wordpos( condition( 'c' ), 'HALT SYNTAX'   ) > 0 then do
         if condition( 'c' ) = 'HALT' then rc = 4
         if condition( 'd' ) > '' & condition( 'd' ) <> rc then do
            if condition( 'd' ) <> errortext( rc ) then do
               TRAP = TRAP || x2c( 0D0A ) || right( '+++', 10 )
               TRAP = TRAP errortext( rc )
            end                        /* future condition( 'd' ) */
         end                           /* may use errortext( rc ) */
         else  TRAP = TRAP errortext( rc )
         rc = -rc                      /* rc < 0: REXX error code */
      end
      when condition( 'c' ) = 'NOVALUE'  then rc = -2 /* dubious  */
      when condition( 'c' ) = 'NOTREADY' then rc = -1 /* dubious  */
      otherwise                        /* force non-zero whole rc */
         if datatype( value( 'RC' ), 'W' ) = 0 then rc = 1
         if rc = 0                             then rc = 1
         if condition() = '' then TRAP = TRAP arg( 1 )
   end                                 /* direct: TRAP( message ) */

   TRAP = TRAP || x2c( 0D0A ) || format( sigl, 6 )
   signal on syntax name TRAP.SIGL     /* throw syntax error 3... */
   if 0 < sigl & sigl <= sourceline()  /* if no handle for source */
      then TRAP = TRAP '*-*' strip( sourceline( sigl ))
      else TRAP = TRAP '+++ (source line unavailable)'
TRAP.SIGL:                             /* ...catch syntax error 3 */
   if abbrev( right( TRAP, 2 + 6 ), x2c( 0D0A )) then do
      TRAP = TRAP '+++ (source line unreadable)'   ;  rc = -rc
   end
   select
      when 0 then do                   /* in pipes STDERR: output */
         parse version TRAP.REXX       /* REXX/Personal: \dev\con */
         if abbrev( TRAP.REXX, 'REXXSAA ' ) |                /**/ ,
            6 <= word( TRAP.REXX, 2 )  then  TRAP.REXX = 'STDERR'
                                       else  TRAP.REXX = '\dev\con'
         signal on syntax name TRAP.FAIL
         call lineout TRAP.REXX , TRAP /* fails if no more handle */
      end
      when 0 then do                   /* OS/2 PM or ooREXX on NT */
         signal on syntax name TRAP.FAIL
         call RxMessageBox translate( TRAP, ' ', x2c( 0D )), /**/ ,
            'Trap' time(),, 'ERROR'
      end
      otherwise   say TRAP ; trace ?L  /* interactive Label trace */
   end

   if condition() = 'SIGNAL' then signal TRAP.EXIT
TRAP.CALL:  return rc                  /* continue after CALL ON  */
TRAP.FAIL:  say TRAP ;  rc = 0 - rc    /* force TRAP error output */
TRAP.EXIT:  exit   rc                  /* exit for any SIGNAL ON  */
