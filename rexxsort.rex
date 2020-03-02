/* REXX: Compare the speed of various sort algorithms */
/* PURL: <URL:http://purl.net/xyzzy/src/rexxsort.cmd> */
/* Info: <URL:http://purl.net/xyzzy/rexxsort.htm>     */
/*             Copyright 2000,2003 by Frank Ellermann */

/* ------ sort algorithms with O(n**2)                */
/* ASORT: direct exchange  (a.k.a. "bubble sort")     */
/* BSORT: binary insertion (improved CSORT)           */
/* CSORT: direct insertion (for cheap copies)         */
/* DSORT: direct selection (for cheap comparisons)    */
/* ------ sort algorithms with O(n**1.x)              */
/* SSORT: Shell sort (sequence length 2 ** N - 1)     */
/* TSORT: Shell sort (sequence length 3 ** N / 2)     */
/* USORT: Shell sort, flexible seq., but try TESTT()  */
/* S0SORT: Shell sort sequence number A003462 = TSORT */
/* S1SORT: Shell sort sequence number A033622 in EIS  */
/* S2SORT: Shell sort sequence number A036562 in EIS  */
/* S3SORT: Shell sort sequence number A036569 in EIS  */
/* S4SORT: Shell sort sequence number A036564 in EIS  */
/* S5SORT: Shell sort sequence number A055875 in EIS  */
/* S6SORT: Shell sort sequence number A055876 in EIS  */
/* ------ sort algorithms with O(n * ld n)            */
/* FSORT: quick sort, first partition, can be O(n**2) */
/* QSORT: quick sort, Hoare partitions (middle of 3)  */
/* RSORT: quick sort, Hoare partitions (median of 3)  */
/* HSORT:  heap sort                                  */
/* MSORT: merge sort (binary  sequence length)        */
/* NSORT: merge sort (natural sequence length)        */
/* OSORT: merge sort (natural, single phase, 4 tapes) */
/* PSORT: polyphase sort (4 tapes fibonacci degree 2) */
/* ------ general sort procedures                     */
/* VSORT: like HSORT, but value() and explicit SIFT() */
/* WSORT: like RSORT, value() access on variable stem */
/* !SORT: reserved for ad hoc tests at end of script  */
/* ------ external sort procedures                    */
/* ISORT: RexxUtil SysStemSort, only for object REXX, */
/*        claims to be a QSORT, but I could not test  */
/*        it on my classic REXX system.  Please note  */
/*        that RxUtils.dll RxStemSort works only for  */
/*        upto 16384 records, therefore I removed it. */
/* JSORT: Quercus RexxLib ARRAYSORT has O(bin. merge) */
/* ------ test algorithms                             */
/* ?SORT: dummy comparing and moving n keys with O(n) */
/*        Timings are absolute for ALGO including '?' */
/*        and otherwise relative to ?SORT O(n) timing */
/* TESTS: sort N random keys, N sorted keys, N almost */
/*        sorted, and N almost inverse keys.          */
/* TESTT: sort N = 10 * N / 4 keys while N is a whole */
/*        number, i.e. build a table with C+1 columns */
/*        for initially N = Q * (2 ** C) with odd Q.  */
/* BASIC: basic function test BASIC( 0 ) or determine */
/*        sort characteristic BASIC( 1 ) as "direct", */
/*        "natural", "inverse", "sequential", "none", */
/*        "sorted", or "shuffled".                    */
/* ------ miscellaneous                               */
/* TRYIT: checks availability of external procedures. */
/* INITS: create STEM.0 random keys copied to TEST.x, */
/*        optionally apply a reference sort for later */
/*        CHECKs saved in GOOD.x (asserting that the  */
/*        reference sort is indeed GOOD).             */
/* CHECK: verify STEM.x = GOOD.x including STEM.0: if */
/*        a sort "abuses" STEM.0 it has to restore it */
/* TIMES: times a sort (with high priority for OS/2), */
/*        start at elapsed time('E') tick:            */
/*        REXX time('E') is a clumsy approach, but it */
/*        needs no profiling of the tested algorithms */
/*        and works even for external procedures.     */

   signal on novalue ;  signal on halt

   /* --- edit these lines as needed ---------------- */
   ABSOLUTE = 0            /* 0: use relative timings */
   VERYSLOW = 0            /* 0: exclude O(n**2) sort */
   ALLMERGE = 0            /* 0: exclude merging sort */
   ALLQUICK = 1            /* 0: exclude minor QSORTs */
   ALLSHELL = 0            /* 0: exclude minor SSORTs */
   ALL_OEIS = 0            /* 0: exclude  OEIS SSORTS */
   ALLVALUE = 1            /* 0: exclude stem value() */
   QREXXLIB = 0            /* 0: exclude   ArraySort  */
   REXXUTIL = 0            /* 0: exclude SysStemSort  */
   RESERVED = 1            /* 0: exclude actual !SORT */
   SEED = random()         /*    random seed = random */

   /* --- normally keep the next lines -------------- */
   EXPO = 'ALGO SEED STEM. GOOD. TEST.'
   if ALLQUICK then ALGO =  'Q R H'    /* top HSort H */
               else ALGO =    'R H'    /* top QSort R */
   if ALLSHELL then ALGO = ALGO 'S T U'
               else ALGO = ALGO 'T'    /* top SSort T */
   if ALL_OEIS then ALGO = ALGO 'S0 S1 S2 S3 S4 S5 S6'
   if ALLVALUE then ALGO = ALGO 'V W'  /* use value() */
   if REXXUTIL then ALGO = ALGO 'I'    /* object REXX */
   if QREXXLIB then ALGO = ALGO 'J'    /* Quercus     */
   if ALLMERGE then ALGO = ALGO 'M N O P'
   if RESERVED then ALGO = ALGO '!'    /* incl. !SORT */
   if VERYSLOW then ALGO =  'A B C D F' ALGO
   if ABSOLUTE then ALGO =          '?' ALGO
   call TRYIT              /* load external procedure */

   /* --- select at most one "when 1 then" test ----- */
   select
      when 0 then exit TESTS(    100 ) /* averages... */
      when 0 then exit TESTS(   1000 ) /* 70% random  */
      when 0 then exit TESTS(   5000 ) /* 10% sorted  */
      when 0 then exit TESTS(  10000 ) /* 10% almost  */
      when 0 then exit TESTS(  50000 ) /* 10% inverse */
      when 1 then exit TESTS( 100000 ) /* if fast CPU */

      when 0 then exit TESTT( 999 ) /* odd single (1) */
      when 0 then exit TESTT( 360 ) /* upto  5625 (4) */
      when 0 then exit TESTT( 600 ) /* upto  9375 (4) */
      when 0 then exit TESTT( 400 ) /* upto 15625 (5) */
      when 0 then exit TESTT( 480 ) /* upto 46875 (6) */
      when 0 then exit TESTT( 800 ) /* upto 78125 (6) */
      when 0 then exit TESTT(     ) /* show bad USORT */

      when 0 then exit BASIC( 1 )   /* characterize   */
      otherwise   exit BASIC( 0 )   /* basic testing  */
   end
   /* --- that's all, now run the selected test ----- */

/* -------------------------------------------------- */
/* catch REXX syntax error 43 (function not found) in */
/* dummy test.  After error call RxFuncDrop arg( 1 ): */

TRYIT:   procedure expose (EXPO)
   if sign( pos( 'I', ALGO )) then do
      ? = 'RexxUtil' ;  FUNC = 'SysStemSort'
      if TRY.?( FUNC ) then call RxFuncAdd FUNC, ?, FUNC
      ? = 'object REXX' ?
      if TRY.?( FUNC ) then exit TRY.!( FUNC, ? )
   end
   if sign( pos( 'J', ALGO )) then do
      ? = 'REXXLIB'  ;  FUNC = 'ARRAYSORT'
      if TRY.?( FUNC ) then call RxFuncAdd FUNC, ?, 'LIB_' || FUNC
      ? = 'QREXXLIB'
      if TRY.?( FUNC ) then call RxFuncAdd FUNC, ?, 'LIB_' || FUNC
      ? = 'REXXLIB or' ?
      if TRY.?( FUNC ) then exit TRY.!( FUNC, ? )
   end
   return 0

TRY.?:   procedure
   signal on syntax name TRY..
   STEM.0 = 1  ;  STEM.1 = 'Quercus expects more than 0'
   interpret 'return' arg( 1 ) || '( "STEM" ) & 0'
TRY..:                  /* evaluate X & 0 or X | 1    */
   signal off syntax ;  return RxFuncDrop( arg( 1 )) | 1

TRY.!:   procedure
   say 'fatal - cannot load external procedure' arg( 1 )
   say 'check OS/2 LIBPATH for' arg( 2 ) || '.dll'
   return 1

/* -------------------------------------------------- */
/* rel. timing based on O(n) 1.0                      */
/*                                                    */
/*               1200    3000    7500   18750   46875 */
/*  heap  sort 20.444  19.964  20.827  23.187  24.955 */
/*  dumb QSort 13.889  13.179  13.787  15.332  15.767 */
/* Hoare QSort 14.222  13.393  13.720  15.062  15.478 */
/* smart QSort 11.889  11.179  11.427  12.922  13.358 */
/* Shell SSort 21.556  23.857  27.667  32.855  35.000 */
/* Knuth SSort 19.111  21.321  23.867  29.161  31.767 */
/*  bin. merge 25.000  21.643  23.213  27.052  25.938 */
/*  seq. merge 36.111  36.929  38.453  43.233  46.869 */
/*                                                    */
/* -------------------------------------------------- */
/* verify function of sort algorithms (ref. CSORT):   */

BASIC:   procedure expose (EXPO)
   NEWS = ALGO ;  say   ;  say   ;  call TEXTS ':'
   NEW = ' test    '
   if arg( 1 )
      then NEW = NEW 'R=1     R=2    half    inv.  preference'
      else NEW = NEW '0, 1, 2, .., 19 random keys, seed' SEED
   call charout /**/, NEW

   do while NEWS > ''
      parse var NEWS NEW NEWS ;  say   ;  call TEXTS NEW

      do TOP = 0 to 19  /* 4*19 fills one DEBUG line ;-) */
         call INITS TOP, 'CSORT'
         interpret 'call' NEW || 'SORT'
         call CHECK
      end TOP
      call charout /**/, '  ok.'

      select            /* changed for new faster system */
         when NEW = '?' | \ arg( 1 )   then  iterate
         when pos( NEW, 'IJ'    ) > 0  then  TOP = 16384
         when pos( NEW, 'ABCDF' ) > 0  then  TOP =  1200
         when pos( NEW, 'HMNOP' ) > 0  then  TOP =  2000
         otherwise                           TOP =  5000
      end
      GOOD.0 = TOP   ;  STEM.0 = TOP

      do N = 1 to TOP   /* ----------------------------- */
         GOOD.N = format( N, 5, 1 )
         if N // 2
            then STEM.N = format( TOP - N, 5, 1 )
            else STEM.N = format(       N, 5, 1 )
      end N
      T.0.5 = TIMES( NEW ) ;  call CHECK  /* 50% inverse */
      do N = 1 to TOP   /* ----------------------------- */
         STEM.N = format( N, 5, 1 )
      end N
      T.1.0 = TIMES( NEW ) ;  call CHECK  /* 100% sorted */
      do N = 1 to TOP   /* ----------------------------- */
         STEM.N = format( TOP - N + 1, 5, 1 )
      end N
      T.0.0 = TIMES( NEW ) ;  call CHECK  /* all inverse */
      do N = 1 to TOP   /* ----------------------------- */
         STEM.N = format(( TOP % 2 + N ) // TOP + 1, 5, 1 )
      end N
      T.2.0 = TIMES( NEW ) ;  call CHECK  /*  50% sorted */

      U = max( T.0.0, T.0.5, T.1.0, T.2.0 )
      T = min( T.0.0, T.0.5, T.1.0, T.2.0 )
      if T > 0 then do
         call charout /**/, format( T.1.0 / T, 5, 2 )
         call charout /**/, format( T.2.0 / T, 5, 2 )
         call charout /**/, format( T.0.5 / T, 5, 2 )
         call charout /**/, format( T.0.0 / T, 5, 2 )
         select
            when 11 * T > 10 * U       then  T = 'none'
            when      T = T.0.0        then  T = 'inverse'
            when 11 * T < 10 * T.1.0   then  T = 'shuffled'
            when  5 * T.2.0 <  U       then  T = 'sequential'
            when  3 * T.0.5 <  U * 2   then  T = 'natural'
            when 10 * T.2.0 <  T * 11  then  T = 'direct'
            when      T.2.0 <> U       then  T = 'sorted'
            when      T.2.0 >  T.0.5   then  T = 'orderly'
            otherwise                        T = 'sorted'
         end
      end
      else T = '(zero ticks: increase' TOP 'in BASIC test)'
      call charout /**/, ' ' T
   end
   say   ;  return 0

/* -------------------------------------------------- */
/* determine order of sort algorithm: 32, 80, 200...  */
/* without arg. check 59052 and 78735 records (worst  */
/* cases for two USORT variants)                      */

TESTT:   procedure expose (EXPO)
   TOP = arg( 1 ) ;  TOPS = ''

   do while datatype( TOP, 'W' )
      TOPS = TOPS format( TOP, 8, 0 )  ;  TOP = 2.5 * TOP
   end                     /* 87654321 87654321 */
   if TOPS = '' then TOPS = '    59052    78735'

   call charout /**/, 'initializing: '
   do N = 1 to words( TOPS )
      TOP = word( TOPS, N )            ;  NEWS = ALGO
      ONE = INITS( TOP )
      call charout /**/, TOP || ' '

      do while NEWS > ''
         parse var NEWS NEW NEWS
         T.NEW.N = format( TIMES( NEW ) / ONE, 5, 3 )

         do L = 0 to TOP
            STEM.L = TEST.L
         end L
      end
   end N

   say
   if ONE = 1.0
      then say 'abs. timing (seconds), seed' SEED
      else say 'rel. timing based on O(n) 1.0, seed' SEED

   say   ;  call TEXTS ':' ;  say TOPS ;  NEWS = ALGO

   do while NEWS > ''
      parse var NEWS NEW NEWS ;  call TEXTS NEW

      do N = 1 to words( TOPS )
         call charout /**/, T.NEW.N
      end N
      say
   end
   return 0

/* -------------------------------------------------- */
/* for a given number of random strings add weights:  */
/* ... 70% random input                               */
/* ... 10% already sorted input                       */
/* ... 10% almost sorted input (exchanged 1st & last) */
/* ... 10% almost inverse input (only 1st & last ok.) */

TESTS:   procedure expose (EXPO)
   TOP = arg( 1 ) ;  if TOP = '' then TOP = 100
   NEWS = ALGO ;  ONE = INITS( TOP, 'QSORT' )
   call charout /**/, 'sorting' TOP 'keys, '
   if ONE = 1.0
      then call charout /**/, 'abs. timing (seconds)'
      else call charout /**/, 'rel. timing O(n) =' ONE
   say ', seed' SEED ;  say   ;  call TEXTS '.'
   say '    (70%)    (10%)   almost   almost   (100%)'
   call TEXTS ':'
   say '   random   sorted   sorted   invers   medium'

   do while NEWS > ''
      parse var NEWS NEW NEWS ;  call TEXTS NEW
      do N = 0 to TEST.0
         STEM.N = TEST.N
      end N
      M = 7 * CHECK( TIMES( NEW ) / ONE ) /* 70% rand */
      M = M + CHECK( TIMES( NEW ) / ONE ) /* 10% sort */
      N = STEM.0        ;  T = STEM.N
      STEM.N = STEM.1   ;  STEM.1 = T
      M = M + CHECK( TIMES( NEW ) / ONE ) /* 10% swap */
      do N = 2 to STEM.0 - 1
         T = STEM.0 - N  + 1  /* almost inverse order */
         STEM.N = GOOD.T      /* keeping 1st and last */
      end N
      M = M + CHECK( TIMES( NEW ) / ONE ) /* 10% inv. */
      say format( M / 10, 5, 3 )          /* average  */
   end
   return 0

/* -------------------------------------------------- */
TEXTS:   procedure
   select
      when arg( 1 ) = '.'  then T = '             '
      when arg( 1 ) = ':'  then T = 'sort methods '
      when arg( 1 ) = '?'  then T = '  O(n) dummy '
      when arg( 1 ) = '!'  then T = 'actual !SORT '
      when arg( 1 ) = 'I'  then T = 'ext. RexxUtil'
      when arg( 1 ) = 'J'  then T = 'ext. RexxLib '
      when arg( 1 ) = 'A'  then T = 'double bubble'
      when arg( 1 ) = 'B'  then T = 'binary insert'
      when arg( 1 ) = 'C'  then T = 'direct insert'
      when arg( 1 ) = 'D'  then T = 'direct select'
      when arg( 1 ) = 'H'  then T = '  heap  sort '
      when arg( 1 ) = 'M'  then T = 'binary merge '
      when arg( 1 ) = 'N'  then T = '3-tape-merge '
      when arg( 1 ) = 'O'  then T = '4-tape-merge '
      when arg( 1 ) = 'P'  then T = '   polyphase '
      when arg( 1 ) = 'F'  then T = 'simple QSort '
      when arg( 1 ) = 'Q'  then T = ' Hoare QSort '
      when arg( 1 ) = 'R'  then T = 'treble QSort '
      when arg( 1 ) = 'S'  then T = ' Shell SSort '
      when arg( 1 ) = 'S0' then T = 'A003462 Sort '
      when arg( 1 ) = 'S1' then T = 'A033622 Sort '
      when arg( 1 ) = 'S2' then T = 'A036562 Sort '
      when arg( 1 ) = 'S3' then T = 'A036569 Sort '
      when arg( 1 ) = 'S4' then T = 'A036564 Sort '
      when arg( 1 ) = 'S5' then T = 'A055875 Sort '
      when arg( 1 ) = 'S6' then T = 'A055876 Sort '
      when arg( 1 ) = 'T'  then T = ' Knuth SSort '
      when arg( 1 ) = 'U'  then T = 'simple SSort '
      when arg( 1 ) = 'V'  then T = 'value: HSort '
      when arg( 1 ) = 'W'  then T = 'value: QSort '
      otherwise T = right( arg( 1 ) || 'Sort ', 13 )
   end
   return charout( /**/, T )

/* -------------------------------------------------- */
CHECK:   procedure expose (EXPO)
   if arg() = 1
      then call charout /**/, format( arg( 1 ), 5, 3 )
   do N = 0 to GOOD.0
      if STEM.N == GOOD.N then iterate N
      say ' --> sort check @' || N || ':'
      call charout /**/, copies( ' ', 11 ) 'expected "'
      say GOOD.N || '" but got "' || STEM.N || '"'
      exit 1
   end N
   return arg( 1 )

/* -------------------------------------------------- */
/* STEM.0 = TEST.0 = GOOD.0 = TOP:  number of strings */
/* STEM.1 .. STEM.TOP:  random REXX numbers (strings) */
/* TEST.1 .. TEST.TOP:  copy of STEM to repeat a test */
/* GOOD.1 .. GOOD.TOP:  sorted STEM to check results  */
/*                      (only if 2nd arg. REF given)  */
/* returns O(n) timing for dummy ?SORT if '?' is not  */
/* included in ALGO, otherwise returns 1. to compute  */
/* absolute timings (seconds)                         */

INITS:   procedure expose (EXPO)
   arg TOP, REF

   drop STEM. GOOD. TEST.  ;  TOP = max( 1, TOP )
   STEM.0 = TOP   ;  GOOD.0 = TOP   ;  TEST.0 = TOP
   call random ,, SEED

   do N = 1 to TOP
      STEM.N = random( TOP )
      TEST.N = STEM.N               ;  GOOD.N = STEM.N
   end N

   if REF > '' then do     /* initial REFerence sort: */
      interpret 'call' REF
      X = STEM.1  ;  GOOD.1 = X  ;  STEM.1 = TEST.1

      do N = 2 to TOP      /* asserting reference ok. */
         if X >> STEM.N then trace '?R'
         X = STEM.N  ;  GOOD.N = X  ;  STEM.N = TEST.N
      end N
   end

   X = pos( 'M', ALGO ) + pos( 'N', ALGO )
   X = pos( 'O', ALGO ) + pos( 'P', ALGO ) + X
   X = sign( X ) * TOP     /* no merge -> no overhead */

   do N = TOP + 1 for X + 1
      STEM.N = '?'         /* preallocate REXX memory */
   end N                   /* used by SORT algorithms */

   if sign( pos( '?', ALGO )) then return 1.0

   X = TIMES( '?' )                 /* determine O(n) */
   do N = 0 to TOP                  /* restore random */
      STEM.N = TEST.N
   end N
   return max( 0.001, X )  /* at least 1 milli-second */

/* -------------------------------------------------- */

TIMES:   procedure expose (EXPO)
   if arg() = 1 then do
      call TIMES                    /* high priority  */
      call time 'R'  ;  do until sign( time( 'E' )) ; end
      call time 'R'  ;  interpret 'call' arg( 1 ) || 'SORT'
      return time( 'E' )
   end

   parse source P .  ;  if P <> 'OS/2' then return
   P = 'RxPriority'  ;  signal on syntax name TIM.1
   if RxFuncQuery( P )  then call RxFuncAdd P, 'RxUtils', P
   return RxPriority( /**/, 31 )    /* same class +31 */
TIM.1:                  signal on syntax name TIM.2
   call RxFuncDrop P ;  P = 'DOSPRIORITY'
   if RxFuncQuery( P )
      then call RxFuncAdd P,  'RexxLib', 'LIB_' || P
   return DOSPRIORITY( 31 )         /* +31 same class */
TIM.2:                  signal on syntax name TIM.3
   call RxFuncDrop P                /* maybe QRexxLib */
   call RxFuncAdd  P,  'QRexxLib', 'LIB_' || P
   return DOSPRIORITY( 31 )         /* +31 same class */
TIM.3:                  signal on syntax name TIM.4
   call RxFuncDrop P ;  P = 'SysSetPriority'
   if RxFuncQuery( P )  then call RxFuncAdd P, 'RexxUtil', P
   return SysSetPriority( 2, 31 )   /* user class +31 */
TIM.4:                  return RxFuncDrop( P )

/* -------------------------------------------------- */
/* DEBUG()        displays STEM.1--STEM.2--STEM.3--.. */
/* DEBUG( L, R )  dito marking L R seq. by ..->..<-.. */
/* DEBUG( L, R, L, R, L, R )  dito upto 3 marked seq. */
/* DEBUG also displays the next STEM.0 elements above */
/* STEM.0 if any R is greater than STEM.0 + 1 (merge) */

DEBUG:   procedure expose STEM.
   call trace 'O'             /* do not trace DEBUG() */
   do N = 1 to 3
      L.N = -1 ;  R.N = -1 ;  I = 2 * N
      if 2 * N <= arg() then select
         when arg( I ) > arg( I - 1 ) then do
            L.N = arg( I - 1 )   ;  R.N = arg( I ) - 1
         end
         when arg( I ) < arg( I - 1 ) then do
            L.N = arg( I ) + 1   ;  R.N = arg( I - 1 )
         end
         when arg( I ) = 2 * STEM.0 + 1 then do
            L.N = arg( I )       ;  R.N = arg( I )
         end
         otherwise
            L.N = 0              ;  R.N = 0
      end
   end N
   say   ;  I = 1 ;  J = STEM.0
   if wordpos( 0, L.1 L.2 L.3 ) > 0 then M = '>'
                                    else M = '-'
   if wordpos( 0, R.1 R.2 R.3 ) > 0 then M = M || '<'
                                    else M = M || '-'
   do 2                       /* once or maybe twice: */
      do N = I to J           /* assuming STEM.0 < 20 */
         if wordpos( N, L.1 L.2 L.3 ) > 0 then M = M || '>'
                                          else M = M || '-'
         if symbol( 'STEM.N' ) = 'VAR'
            then M = M || STEM.N
            else M = M || '?' /* show undefined value */
         if wordpos( N, R.1 R.2 R.3 ) > 0 then M = M || '<'
                                          else M = M || '-'
         call charout /**/, M ;  M = ''
      end N
      I = J + 1   ;  J = J + STEM.0
      if max( R.1, R.2, R.3 ) <= I then do
         if wordpos( I, L.1 L.2 L.3 ) > 0 then M = '>'
                                          else M = '-'
         if wordpos( I, R.1 R.2 R.3 ) > 0 then M = M || '<'
                                          else M = M || '-'
         say M ;  return 1
      end
      say
   end
   return 1

/* -------------------------------------------------- */

HALT:
NOVALUE:
   ? = condition( 'D' )
   say   ;  say 'oops... unexpected' ? 'in line' sigl
   trace '?R'  ;  ? = sourceline( sigl )  ;  exit 1

/* ================== Dummy O(n) sort =============== */

?SORT:   procedure expose (EXPO)
   do I = 1 to STEM.0         /* in single 1..n loop: */
      if STEM.I == GOOD.I     /* just compare 2 keys  */
         then STEM.I = TEST.I /* then dummy move key  */
         else STEM.I = GOOD.I /* else dummy move key  */
   end
   return

/* ================== external libraries ============ */
/* Quercus ARRAYSORT won't accept STEM.0 = 0, and old */
/* RxUtils RXSTEMSORT crashes for STEM.0 > 16384.     */

ISORT:   return SysStemSort( 'STEM' )  /* not tested  */
JSORT:   return   ARRAYSORT( 'STEM' )  /* minimum:  1 */

/* ================== Direct Exchange =============== */
/* copied from Wirth: alternating bubble sort         */

ASORT:   procedure expose STEM.
   L = 2 ;  R = STEM.0  ;  K = R

   do until L > R
      do J = R to L by -1
         I = J - 1
         if STEM.I >> STEM.J then do
            K = STEM.I  ;  STEM.I = STEM.J
            STEM.J = K  ;  K = J
         end
      end J
      L = K + 1
      do J = L to R
         I = J - 1
         if STEM.I >> STEM.J then do
            K = STEM.I  ;  STEM.I = STEM.J
            STEM.J = K  ;  K = J
         end
      end J
      R = K - 1
   end
   return

/* ================== Binary Insertion ============== */
/* O(n * ld n) keys compared, O(n * n) records copied */

BSORT:   procedure expose STEM.
   do I = 2 to STEM.0
      X = STEM.I  ;  L = 1 ;  R = I - 1   ;  T = I

      do while L <= R
         M = ( L + R ) % 2
         if X << STEM.M then R = M - 1 ;  else L = M + 1
      end
      do J = I - 1 to L by -1
         STEM.T = STEM.J                  ;  T = J
      end J
      STEM.L = X
   end I
   return

/* ================== Direct Insertion ============== */

CSORT:   procedure expose STEM.
   N = STEM.0

   do I = 2 to N
      STEM.0 = STEM.I            ;  T = I ;  J = I - 1

      do while STEM.0 << STEM.J
         STEM.T = STEM.J         ;  T = J ;  J = J - 1
      end
      STEM.T = STEM.0
   end I

   STEM.0 = N  ;  return

/* ================== Direct Selection ============== */

DSORT:   procedure expose STEM.
   N = STEM.0

   do I = 1 to N - 1
      K = I ;  X = STEM.K

      do J = I + 1 to N
         if STEM.J << X then do
            K = J ;  X = STEM.K
         end
      end J
      STEM.K = STEM.I   ;  STEM.I = X
   end I
   return

/* ================== Shell Sort (binary) =========== */
/* reported to be O( n ** 1.2 ), partition 2 ** M - 1 */

/* N.B.: The Shell sort variant for REXX published by */
/* J.R.Kowalczyk in "REXX Algorithms 1.30" (RXALG130) */
/* is only a bubble sort with O(n ** 2).  The second  */
/* Shell sort in "REXX Tips & Tricks" (version 3.30)  */
/* by I.Collier uses the sequence K = K % 2 starting  */
/* with K = N % 2, much slower than Shell's SSORT.    */

/* S.Pitt's Shell sort (also in "REXX Tips & Tricks") */
/* is based on the sequence 1 3 9 etc., but sequences */
/* not based on coprimes are slower than SSORT (shown */
/* by Knuth in the early 70s).                        */

SSORT: procedure expose STEM.
   do T = 2 while 2 ** T < STEM.0   ;  end T

   do M = T - 1 to 1 by -1
      K = 2 ** M - 1

      do I = 1 to STEM.0 - K
         J = I ;  T = J + K   ;  X = STEM.T

         do while X << STEM.J
            STEM.T = STEM.J   ;  T = J ;  J = J - K
            if J <= 0 then leave
         end
         STEM.T = X
      end I
   end M
   return

/* ================== Shell Sort (ternary) ========== */
/* Shell Sort using 3 ** M / 2 instead of 2 ** M - 1, */
/* see also Neil Sloane's OEIS sequence A003462.      */

/* N.B.: The Shell sort variant for REXX published in */
/* V.Zabrodsky's "Album of Algorithms and Techniques" */
/* is slower, although it is the same sequence 1 4 13 */
/* etc. proposed by Knuth.  Using REXX it's faster to */
/* compute K = 3 ** M % 2 than K = K % 3.             */

TSORT: procedure expose STEM.
   do T = 2 while 3 ** T < STEM.0   ;  end T

   do M = T - 1 to 1 by -1
      K = 3 ** M % 2

      do I = 1 to STEM.0 - K
         J = I ;  T = J + K   ;  X = STEM.T

         do while X << STEM.J
            STEM.T = STEM.J   ;  T = J ;  J = J - K
            if J <= 0 then leave
         end
         STEM.T = X
      end I
   end M
   return

/* ================== Shell Sort (variable) ========= */
/* often USORT is faster than SSORT or TSORT, but for */
/* e.g. 78735 records it fails miserably, see TTEST() */

USORT: procedure expose STEM.
   K = STEM.0

   do until K = 1
      K = K % 3 + 2
      if K > 3 then K = K - ( K // 2 = 0 )   ;  else K = 1

      do I = 1 to STEM.0 - K
         J = I ;  T = J + K   ;  X = STEM.T

         do while X << STEM.J
            STEM.T = STEM.J   ;  T = J ;  J = J - K
            if J <= 0 then leave
         end
         STEM.T = X
      end I
   end
   return

/* ================== Shell Sort (EIS sequences) ==== */
/* Shell sort sequences copied from Neil Sloane's EIS */
/* (Encyclopedia of Integer Sequences). S0SORT is the */
/* same sequence as in Knuth's TSORT, but here values */
/* are still "hardwired", check the Online EIS PURLs  */
/* for formulae and references:                       */
/* S0SORT: <URL:http://purl.net/net/eisa/003462>      */
/* S1SORT: <URL:http://purl.net/net/eisa/033622>      */
/* S2SORT: <URL:http://purl.net/net/eisa/036562>      */
/* S3SORT: <URL:http://purl.net/net/eisa/036569>      */
/* S4SORT: <URL:http://purl.net/net/eisa/036564>      */
/* S5SORT: <URL:http://purl.net/net/eisa/055875>      */
/* S6SORT: <URL:http://purl.net/net/eisa/055876>      */

S0SORT:  procedure expose STEM.     /* => EIS A003462 */
   SEQ = 4 13 40 121 364 1093 3280 9841 29524 88573 265720 797161
   call S?SORT ;  return

S1SORT:  procedure expose STEM.     /* => EIS A033622 */
   SEQ = 5 19 41 109 209 505 929 2161 3905 8929 16001 36289 64769
   SEQ = SEQ 146305 260609 587521   /* upto 1,000,000 */
   call S?SORT ;  return

S2SORT:  procedure expose STEM.     /* => EIS A036562 */
   SEQ = 8 23 77 281 1073 4193 16577 65921 262913
   call S?SORT ;  return

S3SORT:  procedure expose STEM.     /* => EIS A036569 */
   SEQ = 3 7 21 48 112 336 861 1968 4592 13776 33936 86961 198768
   SEQ = SEQ 463792                 /* upto 1,000,000 */
   call S?SORT ;  return

S4SORT:  procedure expose STEM.     /* => EIS A036564 */
   SEQ = 19 83 211 467 979 2003 4051 8147 16339 32723 65491 131027
   SEQ = SEQ 262099 524243          /* upto 1,000,000 */
   call S?SORT ;  return

S5SORT:  procedure expose STEM.     /* => EIS A055875 */
   SEQ = 2 19 103 311 691 1321 2309 3671 5519 7919 10957 14753
   SEQ = SEQ 19403 24809 31319 38873 47657 57559 69031 81799 96137
   SEQ = SEQ 112291 130073 149717 171529 195043 220861 248851
   SEQ = SEQ 279431 312583 347707 386093 427169 470933 517553
   SEQ = SEQ 567871 620531 677539 737203 800573 867677 938533
   call S?SORT ;  return

S6SORT:  procedure expose STEM.     /* => EIS A055876 */
   SEQ = 2 4 8 21 56 149 404 1098 2982 8104 22027 59875 162756
   SEQ = SEQ 442414                 /* upto 1,000,000 */
   call S?SORT ;  return

S?SORT:  procedure expose STEM. SEQ
   do T = 1 to words( SEQ )
      if word( SEQ, T ) > STEM.0 then leave T
   end T
   do M = T to 1 by -1
      K = word( 1 SEQ, M )

      do I = 1 to STEM.0 - K
         J = I ;  T = J + K   ;  X = STEM.T

         do while X << STEM.J
            STEM.T = STEM.J   ;  T = J ;  J = J - K
            if J <= 0 then leave
         end
         STEM.T = X
      end I
   end M
   return

/* ================== Quick Sort ==================== */
/* copied from Wirth: iterative version, first choice */
/* (this demonstrates worst cases for any partitions  */
/*  if the array is already sorted or inverse sorted) */
/* BTW: recursive quick sort variants are not faster  */
/*      in any decent language incl. interpreted REXX */

FSORT:   procedure expose STEM.
   S = 1 ;  SL.1 = 1 ;  SR.1 = STEM.0        /* stack */

   do until S = 0
      L = SL.S ;  R = SR.S ;  S = S - 1      /* pop   */

      do while L < R
         P = STEM.L  ;  I = L ;  J = R

         do until I > J
            do while STEM.I << P ;  I = I + 1   ;  end
            do while STEM.J >> P ;  J = J - 1   ;  end

            if I <= J then do
               X = STEM.I  ;  STEM.I = STEM.J   ;  STEM.J = X
               I = I + 1   ;  J = J - 1
            end
         end   /* I  > J   */

         if J - L < R - I then do   /* less left keys */
            if I < R then do                 /* push  */
               S = S + 1   ;  SL.S = I ;  SR.S = R
            end                              /* right */
            R = J                            /* new R */
         end
         else do                    /* more left keys */
            if L < J then do                 /* push  */
               S = S + 1   ;  SL.S = L ;  SR.S = J
            end                              /* left  */
            L = I                            /* new L */
         end
      end      /* R <= L   */
   end         /* S == 0   */
   return

/* ================== Quick Sort ==================== */
/* copied from Wirth: iterative version, best choice  */
/* (partition key P selected as the middle of 3 keys, */
/*  the worst case still exists, but it's not one of  */
/*  the trivial cases like already sorted or inverse) */

QSORT:   procedure expose STEM.
   S = 1 ;  SL.1 = 1 ;  SR.1 = STEM.0        /* stack */

   do until S = 0
      L = SL.S ;  R = SR.S ;  S = S - 1      /* pop   */

      do while L < R
         I = ( L + R ) % 2

         if STEM.L << STEM.R then select     /* L...R */
            when STEM.I << STEM.L then J = L /* I L R */
            when STEM.I >> STEM.R then J = R /* L R I */
            otherwise                  J = I /* L I R */
         end
         else select                         /* R...L */
            when STEM.I << STEM.R then J = R /* I R L */
            when STEM.I >> STEM.L then J = L /* R L I */
            otherwise                  J = I /* R I L */
         end

         P = STEM.J  ;  I = L ;  J = R

         do until I > J
            do while STEM.I << P ;  I = I + 1   ;  end
            do while STEM.J >> P ;  J = J - 1   ;  end

            if I <= J then do
               X = STEM.I  ;  STEM.I = STEM.J   ;  STEM.J = X
               I = I + 1   ;  J = J - 1
            end
         end   /* I  > J   */

         if J - L < R - I then do   /* less left keys */
            if I < R then do                 /* push  */
               S = S + 1   ;  SL.S = I ;  SR.S = R
            end                              /* right */
            R = J                            /* new R */
         end
         else do                    /* more left keys */
            if L < J then do                 /* push  */
               S = S + 1   ;  SL.S = L ;  SR.S = J
            end                              /* left  */
            L = I                            /* new L */
         end
      end      /* R <= L   */
   end         /* S == 0   */
   return

/* ================== Quick Sort ==================== */
/* iterate partitions by medium of 3 presorted keys - */
/* only partitions with more than 3 keys are handled  */
/* in the inmost loop, and so the pushed bigger part  */
/* consists of more than 1 key without "L < R" tests. */

/* N.B.: The recursive QQSORT by R.Wilke published in */
/* "REXX Tricks & Tips" is almost as fast as RSORT.   */
/* QQSORT uses Hoare's partitions (see QSORT), and it */
/* handles partitions with less than 9 keys by bubble */
/* sort (direct selection would be better but still a */
/* bit slower than RSORT).                            */

RSORT:   procedure expose STEM.
   S = 1 ;  SL.1 = 1 ;  SR.1 = STEM.0        /* stack */

   do until S = 0
      L = SL.S ;  R = SR.S ;  S = S - 1      /* pop   */

      do while L < R
         I = ( L + R ) % 2 ;  P = STEM.L

         if STEM.R << P then do              /* R...L */
            P = STEM.R  ;  STEM.R = STEM.L   ;  STEM.L = P
         end                                 /* L...R */
         select
            when STEM.I << P then do         /* I L R */
               X = STEM.I  ;  STEM.I = P  ;  STEM.L = X
            end                              /* L I R */
            when STEM.I >> STEM.R then do    /* L R I */
               P = STEM.R  ;  STEM.R = STEM.I   ;  STEM.I = P
            end                              /* L I R */
            otherwise   P = STEM.I           /* L I R */
         end

         I = L + 1   ;  J = R - 1            /* I...J */
         if J <= I then leave                /* ready */

         do until I > J
            do while STEM.I << P ;  I = I + 1   ;  end
            do while STEM.J >> P ;  J = J - 1   ;  end

            if I <= J then do
               X = STEM.I  ;  STEM.I = STEM.J   ;  STEM.J = X
               I = I + 1   ;  J = J - 1
            end
         end   /* I  > J   */

         if J - L < R - I then do   /* less left keys */
            S = S + 1   ;  SL.S = I ;  SR.S = R ;  R = J
         end   /* pushed old R - I > 1 keys, now do L */
         else do                    /* more left keys */
            S = S + 1   ;  SL.S = L ;  SR.S = J ;  L = I
         end   /* pushed J - old L > 1 keys, now do R */
      end      /* R <= L   */
   end         /* S == 0   */
   return

/* ================== Quick Sort ==================== */
/* like RSORT, but value() access on variable stem:   */
/* just copy procedures KWIK and KWIK.Y to a script.  */

WSORT:   return KWIK( 'STEM' )
KWIK:
   if arg() <> 1 then return abs( /* REXX error 40 */ )
   THIS... = arg( 1 )         /* abuse global THIS... */
   if right( THIS... , 1 ) <> .  then  THIS... = THIS... || .
   return KWIK.Y( THIS... )   /* expose THIS... stem  */

KWIK.Y:  procedure expose ( THIS... )
   S = 1 ;  SL.1 = 1 ;  SR.1 = value( THIS... || 0 )

   do until S = 0
      L = SL.S ;  R = SR.S ;  S = S - 1      /* pop   */

      do while L < R
         I = ( L + R ) % 2 ;  P = value( THIS... || L )

         XR = value( THIS... || R )
         if XR << P then do                  /* R...L */
            call value THIS... || R, P
            call value THIS... || L, XR   ;  P = XR
         end                                 /* L...R */
         XI = value( THIS... || I )
         XR = value( THIS... || R )
         select
            when XI << P then do             /* I L R */
               call value THIS... || I, P
               call value THIS... || L, XI
            end                              /* L I R */
            when XI >> XR then do            /* L R I */
               call value THIS... || R, XI
               call value THIS... || I, XR   ;  P = XR
            end                              /* L I R */
            otherwise   P = XI               /* L I R */
         end

         I = L + 1   ;  J = R - 1            /* I...J */
         if J <= I then leave                /* ready */

         do until I > J
            do while value( THIS... || I ) << P ;  I = I+1  ;  end
            do while value( THIS... || J ) >> P ;  J = J-1  ;  end

            if I <= J then do
               XI = value( THIS... || I )
               call value  THIS... || I, value( THIS... || J, XI )
               I = I + 1   ;  J = J - 1
            end
         end   /* I  > J   */

         if J - L < R - I then do   /* less left keys */
            S = S + 1   ;  SL.S = I ;  SR.S = R ;  R = J
         end   /* pushed old R - I > 1 keys, now do L */
         else do                    /* more left keys */
            S = S + 1   ;  SL.S = L ;  SR.S = J ;  L = I
         end   /* pushed J - old L > 1 keys, now do R */
      end      /* R <= L   */
   end         /* S == 0   */
   return 1

/* ================== Heap Sort ===================== */
/* The heap sort published in "REXX Tips & Tricks" by */
/* B.Schemmer is apparently slower than this version, */
/* but maybe my transformation of its "DownHeap" sift */
/* to inline code was not optimal.                    */

/* The bugfixed heap sort published by V.Zabrodsky in */
/* his "Album of Algorithms and Techniques" is slower */
/* than HSORT (checked with inline code of his SIFT). */

HSORT:   procedure expose STEM.
   R = STEM.0  ;  L = ( R % 2 ) + 1

   do while L > 1
      L = L - 1   ;  I = L ;  J = I + I   ;  X = STEM.I

      do while J < R       /* sift( L,N ), L = N/2..1 */
         K = J + 1   ;  if STEM.J << STEM.K then J = K

         if STEM.J <<= X then leave
         STEM.I = STEM.J   ;  I = J ;  J = I + I
      end
      if J = R then do     /* i.e. don't consider J+1 */
         if X << STEM.J then do
            STEM.I = STEM.J   ;  I = J
         end
      end

      STEM.I = X
   end
   do while R > 1
      X = STEM.R  ;  STEM.R = STEM.1   ;  STEM.1 = X
      R = R - 1   ;  I = 1 ;  J = 2

      do while J < R       /* sift( 1,R ), R = N .. 1 */
         K = J + 1   ;  if STEM.J << STEM.K then J = K

         if STEM.J <<= X then leave
         STEM.I = STEM.J   ;  I = J ;  J = I + I
      end
      if J = R then do     /* i.e. don't consider J+1 */
         if X << STEM.J then do
            STEM.I = STEM.J   ;  I = J
         end
      end

      STEM.I = X
   end
   return

/* ================== Heap Sort ===================== */
/* like HSORT, but value() access on variable stem.   */
/* The penalty for using an explicit SIFT (instead of */
/* inline code) is high, but here I wanted a readable */
/* solution: copy procedures HEAP, HEAP.., and HEAP.S */
/* (the latter is SIFT) to a script.                  */

VSORT:   return HEAP( 'STEM' )
HEAP:
   if arg() <> 1 then return abs( /* REXX error 40 */ )
   THIS... = arg( 1 )         /* abuse global THIS... */
   if left( THIS... ,  1 )    <> '.'
      then  THIS... = THIS... || '.'
   return HEAP..( THIS... )   /* expose THIS... stem  */

HEAP..:  procedure expose ( THIS... )
   R = value( THIS... || 0 )  ;  L = ( R % 2 ) + 1

   do while L > 1
      L = L - 1   ;  I = L ;  J = I + I
      X = value( THIS... || I )
      call HEAP.S          /* sift( L,N ), L = N/2..1 */
   end
   do while R > 1
      X = value( THIS... || R )
      call value THIS... || R, value( THIS... || 1, X )
      R = R - 1   ;  I = 1 ;  J = 2

      call HEAP.S          /* sift( 1,R ), R = N .. 1 */
   end
   return 1

HEAP.S:                    /* SIFT using caller var.s */
   do while J < R
      K = J + 1
      XJ = value( THIS... || J )
      XK = value( THIS... || K )
      if XJ << XK then do  ;  J = K ;  XJ = XK  ;  end
      if XJ <<= X then leave
      call value THIS... || I, XJ   ;  I = J ;  J = I + I
   end
   if J = R then do        /* i.e. don't consider J+1 */
      XJ = value( THIS... || J )
      if X << XJ then do
         call value THIS... || I, XJ   ;  I = J
      end
   end
   call value THIS... || I, X ;  return

/* ================== Merge Sort ==================== */
/* binary merge in single phase (uses 2 + 2 "tapes"), */
/* "unnatural" binary sequence lengths P = 1,2,4,...  */

MSORT:   procedure expose STEM.
   S = STEM.0              /* 2nd tape S  (downwards) */
   T = S + 1               /* 3rd tape T    (upwards) */
   F = S + S               /* 4th tape F  (downwards) */
   D = 0 ;  P = 1

   do while D | P < S
      H = 1 ;  M = S
      if D then do         /* 1 Downwards: 1,S to T,F */
         D = 0 ;  K = 1 ;  L = S ;  I = T ;  J = F
      end
      else do              /* 0 D upwards: T,F to 1,S */
         D = 1 ;  I = 1 ;  J = S ;  K = T ;  L = F
      end

      do until M = 0
         if P <= M then Q = P ;  else Q = M  ;  M = M - Q
         if P <= M then R = P ;  else R = M  ;  M = M - R

         do while Q > 0 & R > 0
            if STEM.I << STEM.J then do
               STEM.K =  STEM.I  ;  I = I + 1   ;  Q = Q - 1
            end
            else do
               STEM.K = STEM.J   ;  J = J - 1   ;  R = R - 1
            end
            K = K + H
         end
         do R
            STEM.K = STEM.J   ;  J = J - 1   ;  K = K + H
         end
         do Q
            STEM.K = STEM.I   ;  I = I + 1   ;  K = K + H
         end

         H = 0 - H   ;  X = K ;  K = L ;  L = X
      end   /* M == 0 */

      P = P + P
   end      /* S <= P */
   return

/* ================== Natural Merge ================= */
/* copied from Wirth: 3 tapes, use existing sequences */
/* ("natural" merge) in distribution and merge phases */
/* 1st tape:      STEM.0 = n  , index T < W   upwards */
/* 2nd tape: U is eof, W = n+1, index V < U   upwards */
/* 3rd tape: D is eof, F = n*2, index E > D downwards */
/* predicate P: EOF or end of (last <= next) sequence */

NSORT:   procedure expose STEM.
   W = STEM.0 + 1          /* 2nd tape W..U   upwards */
   F = STEM.0 * 2          /* 3rd tape F..D downwards */
   S = 1 + F   ;  STEM.S = '' /* dummy 1 | ... access */
   S = STEM.0              /* process only STEM.0 > 1 */

   do while S > 1          /* while S > 1 sequences   */
      U = W ;  D = F ;  T = 1          /* reset tapes */
      do until T = W                   /* distribute: */
         do until P
            STEM.U = STEM.T                  ;  T = T + 1
            P = ( T = W | STEM.U >> STEM.T ) ;  U = U + 1
         end                  /* copy sequence T to U */
         if T < W then do until P
            STEM.D = STEM.T                  ;  T = T + 1
            P = ( T = W | STEM.D >> STEM.T ) ;  D = D - 1
         end                  /* copy sequence T to D */
      end                     /* => distributed again */

      V = W ;  E = F ;  T = 1 ;  S = 0 /* reset tapes */
      do while V < U & D < E           /* merge tapes */
         S = S + 1            /* add 1 to sequences S */
         do until P           /* merge U + D sequence */
            if STEM.V << STEM.E then do
               STEM.T =  STEM.V                 ;  V = V + 1
               P = ( V = U | STEM.T >> STEM.V ) ;  T = T + 1

               if P then do until P
                  STEM.T = STEM.E                  ;  E = E - 1
                  P = ( E = D | STEM.T >> STEM.E ) ;  T = T + 1
               end            /* copy sequence D to T */
            end
            else do
               STEM.T = STEM.E                  ;  E = E - 1
               P = ( E = D | STEM.T >> STEM.E ) ;  T = T + 1

               if P then do until P
                  STEM.T = STEM.V                  ;  V = V + 1
                  P = ( V = U | STEM.T >> STEM.V ) ;  T = T + 1
               end            /* copy sequence U to T */
            end
         end                  /* => broken sequences  */
      end                     /* => 1st source merged */

      do while V < U          /* copy rest of U to T: */
         S = S + 1            /* add U sequences to S */
         do until P
            STEM.T = STEM.V                  ;  V = V + 1
            P = ( V = U | STEM.T >> STEM.V ) ;  T = T + 1
         end                  /* copy sequence U to T */
      end                     /* => 2nd source copied */
      do while D < E          /* copy rest of D to T: */
         S = S + 1            /* add D sequences to S */
         do until P
            STEM.T = STEM.E                  ;  E = E - 1
            P = ( E = D | STEM.T >> STEM.E ) ;  T = T + 1
         end                  /* copy sequence D to T */
      end                     /* => 2nd source copied */
   end                        /* until S = 1 sequence */
   return

/* ================== Balanced Merge ================ */
/* natural merge in single phase (uses 2 + 2 "tapes") */
/*  input "tape": 1...STEM.0 distributed to 3rd + 4th */
/*  first "tape":              1   upto O.0 or E.0    */
/* second "tape":     STEM.0 = N downto O.1 or E.1    */
/*  third "tape": 1 + STEM.0 = T   upto E.0 or O.0    */
/* fourth "tape": 2 * STEM.0 = F downto E.1 or O.1    */

OSORT:   procedure expose STEM.
   N = STEM.0              /* 2nd tape N... downwards */
   T = N + 1   ;  U.0 = +1 /* 3rd tape T...   upwards */
   F = N + N   ;  U.1 = -1 /* 4th tape F... downwards */
   S = 1 + F   ;  STEM.S = '' /* dummy 1 | ... access */
   S = N                   /* process only STEM.0 > 1 */

   O.0 = T  ;  O.1 = F  ;  P = 0 ;  D = 1 ;  Q = 1

   do K = 1 to N                       /* distribute: */
      if STEM.K << STEM.Q then P = \ P /* switch tape */
      Q = O.P  ;  STEM.Q = STEM.K      /* copy to O.P */
      O.P = O.P + U.P                  /* next output */
   end K
   do while S > 1
      E.0 = O.0   ;  E.1 = O.1         /* end of tape */

      if D then do                     /* 3+4 -> 1+2  */
         I.0 = T  ;  I.1 = F  ;  O.0 = 1 ;  O.1 = N
         D = 0    ;  S = 0             /* downwards:  */
      end                              /* allows exit */
      else do                          /* 1+2 -> 3+4  */
         I.0 = 1  ;  I.1 = N  ;  O.0 = T ;  O.1 = F
         D = 1    ;  S = 1             /* upwards:    */
      end                              /* cannot exit */

      J = 0 ;  P = 1       /* start tape 1(3) to 4(2) */
      E = ( I.0 < E.0 ) + ( I.1 > E.1 )

      do until E = 0       /* until EOF on both tapes */
         R = E - 1                     /* start seq.  */
         S = S + 1                     /* count seq.  */
         P = \ P                       /* next target */

         do while R        /* R = 1 merging two tapes */
            Q = I.1  ;  K = I.0        /* input tapes */
            J = ( STEM.Q << STEM.K )   /* smaller key */

            Q = O.P  ;  K = I.J
            STEM.Q = STEM.K            /* copy to O.P */
            O.P = O.P + U.P            /* next output */
            K   = K   + U.J
            I.J = K                    /* next  input */

            if K = E.J then do         /* end of tape */
               E = E - 1               /* input tapes */
               J = \ J                 /* next source */
               R = 0                   /* end of seq. */
            end
            else if STEM.K << STEM.Q then do
               J = \ J                 /* next source */
               R = 0                   /* end of seq. */
            end
         end
         do until R        /* R = 0 copying rest seq. */
            Q = O.P  ;  K = I.J
            STEM.Q = STEM.K            /* copy to out */
            O.P = O.P + U.P            /* next output */
            K   = K   + U.J
            I.J = K                    /* next  input */

            if K = E.J then do         /* end of tape */
               E = E - 1               /* input tapes */
               J = \ J                 /* next source */
               R = 1                   /* end of seq. */
            end
            else if STEM.K << STEM.Q then do
               if E > 1 then J = \ J   /* next source */
               R = 1                   /* end of seq. */
            end
         end   /* R = 1: both input sequences broken  */
      end      /* E = 0: both input "tapes" now empty */
   end         /* S = 1: only one remaining sequence  */
   return

/* ================== Polyphase Sort ================ */
/* Polyphase sort simulating 4 tapes in 2*n records:  */
/* A distribution based on fibonacci numbers of 2nd   */
/* order uses 2+1= 3 =4-1 sources simultaneously, and */
/* therefore the simulation of 4 tapes in 2*n records */
/* has to reorganize a source when the target reaches */
/* the end of the opposite input in n records:        */
/* 1:..done..----input-->..<--output--:n (no problem) */
/* 1:..done...---input--><----output--:n (swap input) */
/* 1:<--input---..free..<-----output--:n (after swap) */

/* Unfortunately this code is not very efficient, but */
/* simulating 6 tapes by 6*n records did not improve  */
/* the results for upto 20000 records.  4-tape-merge  */
/* (OSORT) was faster, 3-tape-merge (NSORT) minimally */
/* slower than all tested polyphase (PSORT) variants. */

PSORT:   procedure expose STEM.
   N = STEM.0  ;  L = 2 * N + 1  ;  STEM.L = ''
   S.0   = N + 1  ;  D.0 = +1 ;  I = 1
   S.1   = N * 2  ;  D.1 = -1 ;  P = 0
   S.2   = 1      ;  D.2 = +1 ;  K = 2
   S     = N      ;  D   = -1 ;  E = N

   do J = 0 to 2              /* initial distribution */
      I.J = S.J   ;  F.J = 1  /* of sequences 0, 1, 2 */
      E.J = S.J   ;  P.J = ( I = I.0 ) ;  R.J = D.J
      if \ P.J then do until I = I.0 | L.J >> STEM.I
            L.J = STEM.I   ;  L = E.J  ;  E.J = E.J + D.J
            STEM.L = L.J   ;  I = I + 1
      end                     /* copy a sequence to J */
   end J                      /* or note a pseudo P.J */

   J = 2                      /* further distribution */
   do while I < I.0           /* end I.0 = STEM.0 + 1 */
      L = ( J + 1 ) // 3      /* L = next target tape */
      if P.L <= P.J then do
         if P.J = 0 then do   /* P.J pseudo sequences */
            F = F.0           /* F.J fibonacci terms: */
            P.0 = F + F.1 - F.0  ;  F.0 = F + F.1
            P.1 = F + F.2 - F.1  ;  F.1 = F + F.2
            P.2 = F       - F.2  ;  F.2 = F
         end
         J = 0                /* select target tape 0 */
      end                     /* (get rid of pseudos) */
      else  J = L             /* select target tape L */

      if L.J <<= STEM.I then do
         do until I = I.0 | L.J >> STEM.I
            L.J = STEM.I   ;  L = E.J  ;  E.J = E.J + D.J
            STEM.L = L.J   ;  I = I + 1
         end                  /* continue sequence if */
      end                     /* last key L.J fits or */
      if I < I.0 then do      /* keep pseudo sequence */
         P.J = P.J - 1        /* or countdown pseudos */
         do until I = I.0 | L.J >> STEM.I
            L.J = STEM.I   ;  L = E.J  ;  E.J = E.J + D.J
            STEM.L = L.J   ;  I = I + 1
         end                  /* copy a sequence to J */
      end                     /* at end no count down */
   end                        /* (continued sequence) */

   if E.1 <> S.1 then do while F.2 > 0
      O = S + D * ( STEM.0 - 1 )
      do L = 0 to 2           /* shared I/O ranges => */
         if O <> S.L then iterate L
         O = E.L - D.L  ;  OT = L   ;  leave L
      end L                   /* output upto opposite */
      do F = 1 to F.2         /* merge fibonacci term */
         J = -1                        /* -1 = pseudo */
         do L = 0 to 2                 /* check input */
            if P.L = 0 then do         /* no pseudo = */
               J = J + 1   ;  L.J = L  /* valid input */
            end
            else P.L = P.L - 1         /* else ignore */
         end L                         /* pseudo seq. */

         if 0 <= J then do until J < 0 /* valid input */
            M = 0 ;  L = L.0  ;  K = I.L  ;  X = STEM.K

            do I = 1 to J              /* sources > 0 */
               H = L.I  ;  N = I.H     /* indirect... */
               if STEM.N << X then do  /* smaller key */
                  M = I ;  L = H ;  K = N ;  X = STEM.K
               end                     /* X: smallest */
            end I                      /* K: X index  */

            if O = E then do  /* actual output at eof */
               N = S.OT ;  D.OT = D    /* swap source */
               O = E.OT ;  E.OT = S.OT + D
               I = I.OT ;  I.OT = E.OT + O - I

               if K = I then K = I.OT  /* use K = I.L */
               do I = O + D to I by D while D * N > I * D
                  H = STEM.N  ;  STEM.N = STEM.I
                  STEM.I = H  ;  N = N - D
               end I          /* swapping while N > I */
               O = 0          /* now both use delta D */
            end               /* for E following I.OT */

            STEM.E = X  ;  E = E + D   /* L: X source */
            K = K + D.L ;  I.L = K     /* M: good L.M */

            if K = E.L then do
               L.M = L.J   ;  J = J - 1
            end               /* input / sequence end */
            else if STEM.K << X then do
               L.M = L.J   ;  J = J - 1
            end               /* input / sequence end */
         end                  /* countdown of valid J */
         else P = P + 1       /* note pseudo sequence */
      end F
      F = F.2  ;  F.2 = F.1 - F  ;  F.1 = F.0 - F  ;  F.0 = F
      do K = 0 to 2           /* input eof K = 0,1,2: */
         if I.K = E.K then leave K
      end K
      N = R.K  ;  I = S.K     /* swap output & tape K */
      D.K = D  ;  I.K = S  ;  S.K = S  ;  E.K = E  ;  P.K = P
      R.K = D  ;  D = N    ;  S = I    ;  E = I    ;  P = 0
   end

   I = I.K  ;  D = D.K        /* copy result sequence */
   if I <> 1 then do N = 1 to STEM.0 while N < I
      H = STEM.N  ;  STEM.N = STEM.I
      STEM.I = H  ;  I = I + D
   end N
   return

/* ================== Sort under test =============== */
/* !SORT is used for ad hoc tests of other algorithms */

!SORT:   procedure expose STEM.
   K = STEM.0

   do until K = 1
      K = K % 3 + 2
      if K > 5 then K = K - ( K // 2 = 0 )   ;  else K = 1

      do I = 1 to STEM.0 - K
         J = I ;  T = J + K   ;  X = STEM.T

         do while X << STEM.J
            STEM.T = STEM.J   ;  T = J ;  J = J - K
            if J <= 0 then leave
         end
         STEM.T = X
      end I
   end
   return

