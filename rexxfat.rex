/* NT ooREXX:  Create empty VFD (virtual floppy disk) with a FAT. */
/* Features :  Up to 2**32 - 1 sectors for FAT32.  Cluster sizes  */
/*             with 1, 2, 4, ..., 64, 128 sectors are determined  */
/*             and interactively picked at run time.  The default */
/*             is the smallest possible cluster size.  A VFD is   */
/*             created as a "sparse" NTFS file with FSUTIL.exe if */
/*             applicable.                                        */
/*             For FAT12 and FAT16 the minimal number of sectors  */
/*             used as static root directory can be given.  The   */
/*             default 6 guarantees at least 96 root entries for  */
/*             sector size 512.                                   */
/*             The default sector size is 512 (2**9).  VFDs can   */
/*             be created for sector sizes from 2**7 up to 2**12. */
/* MBR image:  A partitioned image is created when the number of  */
/*             sectors is given as -1 -N.  This yields one MBR    */
/*             immediately followed by N sectors for the one and  */
/*             only partition in this image.  These N sectors are */
/*             in essence formatted like a VFD with N sectors.    */
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
/* INT 13h  :  VFD images never get a media descriptor F8 (hex.), */
/*             VHD and raw images always get F8.  VFD images get  */
/*             an INT 13h DL default 00 (1st floppy drive), other */
/*             images get 80 (1st hard drive).  For F8 there will */
/*             be only one hidden sector (MBR without gap).       */
/* Boot code:  The MBR code is a quick hack for INT 13h with LBA, */
/*             it starts a partition flagged as active, and exits */
/*             with INT 18h if that fails.  The one FAT partition */
/*             in a new VHD is not flagged as active, because the */
/*             dummy partition boot code only displays its volume */
/*             ID, waits for any key, and exits with INT 18h.     */
/* 512e     :  512e emulates sector size 512 for physical sector  */
/*             size 4096.  If the wanted sector size is given as  */
/*             512e instead of 512 the resulting image is aligned */
/*             for 512e, where all relevant sector numbers must   */
/*             be multiples of 8 logical numbers.  This affects   */
/*             allowed image sizes (total sectors), cluster sizes */
/*             (min. 8), and FAT1x root dir. sectors (min. 8).    */
/*             VHD images get 7 reserved sectors after the MBR.   */
/*             VFD images get 8 reserved sectors.                 */
/* Version  :  REXXFAT.rex 0.3, published versions older than 0.3 */
/*             had no version number.     (Frank Ellermann, 2013) */

   signal on  novalue  name TRAP ;  signal on  syntax name TRAP
   signal on  failure  name TRAP ;  signal on  halt   name TRAP
   signal on notready  name TRAP ;  numeric digits 20

   select
      when  arg() <> 1           /* if called by another script:  */
      then  parse arg NOS, MINDIR, NUMFAT, SECLEN, EXTRA
      when  arg( 1 ) <> '*'      /* if started on command line:   */
      then  parse arg NOS  MINDIR  NUMFAT  SECLEN  EXTRA
      otherwise   exit FATTEST() /* self test needs admin rights  */
   end
   exit REXXFAT( NOS, MINDIR, NUMFAT, SECLEN, EXTRA )

/* -------------------------------------------------------------- */
REXXFAT: procedure               /* REXXFAT wrapper for FATTEST() */
   parse arg NOS, MINDIR, NUMFAT, SECLEN, EXTRA

   /* configuration values already supported by run time arg.s:   */
   SECDEF = 512                  /* default sector length (2**9)  */
   NUMDEF = 2                    /* default number of FAT copies  */
   MINDEF = 6                    /* min. FAT1x default dir. sec.s */
   MINRES = 0                    /* 7 + MINRES reserved for FAT32 */
   PARTED = 0                    /* 1: create MBR, 0: superfloppy */
   USE1ST = 0                    /* 1: first cluster size, 0: ask */
   V512E  = 0                    /* 1: enforce 512e alignments    */

   /* configuration values not yet supported by run time arg.s:   */
   SECSUP = 2**7 2**8 2**9 2**10 2**11 2**12
   LABEL  = 'NO NAME'            /* not yet modified at run time  */
   INT13H = ''                   /* maybe force INT13H = NOH SPT  */
   OEMID  = 'REXXFAT'            /* avoid OEMID "NTFS" or "EXFAT" */
   VIRGIN = x2c( 'F6' )          /* EBCDIC 'V' for legacy FORMATs */
   VOLSER = MAKEID( 1 )          /* raw binary volume serial id.  */
   MINVHD = 16                   /* padding does not help for VHD */
   MINVFD = 4096                 /* pad small VFD to MINVFD bytes */
   CHKDSK = 1                    /* 1: bypass Windows CHKDSK bug  */
   ACTIVE = 0                    /* 1: boot first VHD partition   */
   MAJMIN = 0.3                  /* version reported by USAGE()   */

   if NOS = '' | NOS = '/?'         then  return USAGE()
   if datatype( NOS, 'w' ) = 0      then  return USAGE( NOS )
   if NOS <  0    then  do       /* ToDo: improve negative "hack" */
      NOS = abs( NOS ) - 1       ;  PARTED = 1
   end
   if NOS <= 0 | 2**32 <= NOS       then  return USAGE( NOS )
   if MINDIR = ''                   then  MINDIR = MINDEF
   if datatype( MINDIR, 'w' ) = 0   then  return USAGE( MINDIR )
   if MINDIR <= 0 then  do       /* ToDo: improve negative "hack" */
      MINDIR = abs( MINDIR )     ;  MINRES = 2
   end
   if NUMFAT = ''                   then  NUMFAT = NUMDEF
   if datatype( NUMFAT, 'w' ) = 0   then  return USAGE( NUMFAT )
   if NUMFAT <= 0 then  do       /* ToDo: improve negative "hack" */
      NUMFAT = abs( NUMFAT )     ;  USE1ST = 1
   end
   if NUMFAT <= 0 | 16 < NUMFAT     then  return USAGE( NUMFAT )
   if SECLEN = ''                   then  SECLEN = SECDEF
   if translate( SECLEN ) = '512E'  then  do
      SECLEN = 512               ;  V512E  = 1
      if MINRES = 0  then  MINRES = 1 - PARTED
                     else  MINRES = 8 - PARTED
      if sign(( NOS + PARTED ) // 8 ) | sign( MINDIR // 8 ) then  do
         N = '512e requires multiples of 8 sectors; got'
         return PERROR( N NOS + PARTED 'with MINDIR' MINDIR )
      end
   end
   if SECLEN < 0  then  do       /* ToDo: improve negative "hack" */
      SECLEN = abs( SECLEN )     ;  CHKDSK = 0
   end
   if wordpos( SECLEN, SECSUP ) = 0 then  return USAGE( SECLEN )
   if EXTRA  <> ''                  then  return USAGE( EXTRA  )

   /* ----------------------------------------------------------- */
   F. = 0                        /* F.0 = 0 fits F.1, F.2, etc.   */
   do CLOOP = 3 * V512E to 7     /* for 512e use only 8, 16, etc. */
      CS = 2**CLOOP              /* cluster size 1, 2, 4, .., 128 */

      do FLOOP = 0 to 2 * sign( MINDIR )
         select
            when  FLOOP = 0   then  FAT = 32
            when  FLOOP = 1   then  FAT = 16
            when  FLOOP = 2   then  FAT = 12
         end
         if sign( FLOOP )     then  RAW = NOS - 1 - MINDIR
                              else  RAW = NOS - 7 - MINRES
         if V512E & FLOOP > 0 then  RAW = NOS - 8 - MINDIR + PARTED
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

         select                  /* CN = 0 if binary search fails */
            when  CN <= x2d(     0FF4 ) & CN > 0
            then  if FAT <> 12   then  iterate FLOOP
            when  CN <= x2d(    0FFF4 ) & CN > x2d(  0FF4 ) + CHKDSK
            then  if FAT <> 16   then  iterate FLOOP
            when  CN <= x2d( 0FFFFFF4 ) & CN > x2d( 0FFF4 ) + CHKDSK
            then  if FAT <> 32   then  iterate FLOOP
            when  CN  = x2d( 0FFFFFF4 ) + CHKDSK & CS = 16
            then  if FAT <> 32   then  iterate FLOOP
            otherwise                  iterate FLOOP
         end

         RAW = RAW - FS * NUMFAT - CS * CN
         DIR = 0                 ;  RES = 1
         select
            when  FLOOP = 0   then  RES = RAW + MINRES + 7
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
   end
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
   do while N = 0
      say L                      ;  pull N
      N = strip( N )             ;  if N = ''   then  exit 1

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
USAGE:   procedure expose MINDEF NUMDEF SECDEF MAJMIN
   if arg( 1 ) <> '' then  say 'Error:' arg( 1 ) d2c( 7 )
                     else  say
   parse source . . THIS
   say 'Usage:' THIS 'SECTORS [MINDIR [NUMFAT [SECLEN]]]'
   say 'Version' MAJMIN 'for NTFS and Windows NT ooREXX.'
   say
   THIS  =  'The default MINDIR number is' MINDEF || '. '
   say THIS 'For FAT1x there will be MINDIR or'
   THIS  =  'more root dir. sectors (FAT32: 0). '
   say THIS 'Default NUMFAT:' NUMDEF || ', SECLEN:' SECDEF || '.'
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
   /*    REXXFAT( sectors, dir., FATs, size )  [expected failure] */
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
   TEST.13  =          24     8     1 '512e     8+ 8+8+8=32 >24'
   TEST.14  =          36     8     1 '512e     36 is not n*8'
   TEST.15  =          32     6     1 '512e      6 is not n*8'
   TEST.16  =          32     8     2 '512e     8+16+8+8=40 >32'
   TEST.17  =          32     8     1 '512e' /* minimal  512e VFD */
   TEST.18  =         -17                    /* minimal FAT12 VHD */
   TEST.19  =         -32     8     1 '512e' /* minimal  512e VHD */
   TEST.20  =       -4126    16              /*    4084 FAT12 VHD */
   TEST.21  =       -4135    16     . '-512' /* !  4085 FAT16 bug */
   TEST.22  =       -4136    16              /*    4086 FAT16 VHD */
   TEST.23  =      -66054    16              /*   65524 FAT16 VHD */
   TEST.24  =      -66557    16     . '-512' /* ! 65525 FAT32 bug */
   TEST.25  =      -66558    16              /*   65526 FAT32 VHD */
   /*          -272629756 untested, last FAT32 cluster size 1 VHD */

   do N = 1 while symbol( 'TEST.' || N ) = 'VAR'
      call PERROR 'test' right( N - 1, 2 ) || ': PASS'
      call PERROR copies( '-', 79 )
      parse var TEST.N SEC DIR FAT LEN CHK
      TEST.N = translate( SEC DIR FAT LEN,, '.' )
      call PERROR 'test' right( N, 2 ) || ': REXXFAT' TEST.N
      if SEC < 0  then  do
         call PERROR 'press ENTER for CHKDSK' VFDPATH( 'vhd' )
         pull ERR
         if ERR <> ''   then  return PERROR( 'self tests aborted' )
      end
      if FAT = '' then  FAT = .
      if FAT = .  then  FAT = 0 - 2    /* negative FAT number to  */
                  else  FAT = 0 - FAT  /*  disable cluster choice */
      if DIR = .  then  if LEN = .
                     then  ERR = REXXFAT( SEC,    , FAT )
                     else  return PERROR( 'test' N 'invalid' )
                  else  if LEN = .
                     then  ERR = REXXFAT( SEC, DIR, FAT )
                     else  ERR = REXXFAT( SEC, DIR, FAT, LEN )
      if ERR <> 0 then  if CHK <> ''
                     then  iterate N
                     else  return PERROR( 'test' N 'FAIL MIA' )
      if CHK <> ''   then  return PERROR( 'test' N 'FAIL' CHK )
      if SEC > 0     then  iterate N
      address CMD 'chkdsk' ATTACH( SEC )
      ERR = rc                   ;  call ATTACH 0
      if ( ERR = 0 ) = ( LEN = -512 )  then  do
         return PERROR( 'test' N 'FAIL: CHKDSK exit code' ERR )
      end
   end N
   call PERROR 'test' right( N - 1, 2 ) || ': PASS'
   call PERROR copies( '-', 79 )
   call PERROR 'self tests okay'
   return 0

/* -------------------------------------------------------------- */
ATTACH:  procedure               /* attach VHD file for FATTEST() */
   parse arg SEC                 ;  SEC = abs( SEC )
   TMP = VFDPATH( 'tmp' )        ;  call UTIL 'SysDriveMap'
   VHD = VFDPATH( 'vhd' )        ;  call UTIL 'SysFileDelete'
   LEN = 0 || stream( VHD, 'c', 'query size' )
   OBS = LEN - 511               ;  signal off error
   if OBS // 512 = 1 then  OBS = LEN - 512
   if OBS // 512 = 0 then  OBS = SEC <> 0 & OBS <> SEC * 512
   if OBS <> 0 then  exit PERROR( 'missing or unexpected' VHD )

   call SysFileDelete TMP        ;  OBS = SysDriveMap()
   LEN = 0 || stream( TMP, 'c', 'query size' )
   if LEN <> 0 then  exit PERROR( 'cannot delete' TMP )
   call lineout TMP, 'select vdisk file="' || VHD || '"'
   if SEC = 0  then  call lineout TMP, 'detach vdisk'
               else  call lineout TMP, 'attach vdisk'
   call lineout TMP, 'exit'      ;  call lineout TMP
   address CMD '@diskpart /S "' || TMP || '">NUL'
   if rc <> 0  then  exit PERROR( 'diskpart /S' TMP '[' rc ']' )
   call SysFileDelete TMP        ;  MAP = SysDriveMap()
   parse var MAP OBJ MAP
   do while sign( wordpos( OBJ, OBS ))
      parse var MAP OBJ MAP      /* ignore race conditions, first */
   end                           /* new drive letter for test VHD */
   if SEC = 0 | OBJ <> ''  then  return OBJ
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
