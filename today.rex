/* OS/2 REXX - list files modified in the last up to 28 days with */
/*             SysFileTree, typically used to find lost new files */
/*             or dubious "future" files. (Frank Ellermann, 2006) */

   signal on novalue  name TRAP  ;  signal on syntax name TRAP
   signal on failure  name TRAP  ;  signal on halt   name TRAP
   signal on notready name TRAP  ;  call UTIL 'SysFileDelete'
   call UTIL 'SysFileTree'       ;  call UTIL 'SysDriveMap'
   parse arg X A                 ;  A = strip( A )

   if X = ''                  then  exit HELP()
   if datatype( X, 'w') = 0   then  exit HELP( X )
   if X < 0 | X > 28          then  exit HELP( X )

   LOG = XENV( 'TMP' )
   if abbrev( LOG, '/' )      then  LOG = LOG || '/today.tmp'
                              else  LOG = LOG || '\today.tmp'
   call SysFileDelete LOG

   parse value date( 's' ) with YY 5 M 7 D
   D = D - X
   if D < 1 then do
      D = D + 31  ;  M = M - 1
      select
         when M = 0  then parse value 12 YY - 1 with M YY
         when sign( wordpos( M, 1 3 5 7 8 10 )) then  nop
         when sign( wordpos( M,   4 6   9 11 )) then  D = D - 1
         when sign( YY // 4 )                   then  D = D - 3
         when sign( YY // 100 )                 then  D = D - 2
         when sign( YY // 400 )                 then  D = D - 3
         otherwise                                    D = D - 2
      end
   end

   M  = right( M, 2, 0 )
   YY = YY || '/' || M || '/' || right( D, 2, 0 )  /* fill MM, DD */
   parse value time() with D ':' M ':' .           /* ignore secs */
   D  = YY || '/' || D || '/' || M     /* SysFileTree time format */
   M  = SysDriveMap( /**/, 'LOCAL' )   /* is really braindead :-( */

   do until A = ''
      if abbrev( A, '"' )  then parse var A '"' YY '"' A
                           else parse var A     YY     A
      A = strip( A ) ;  YY = strip( YY )
      if YY = '' then YY = '*'         /* no arg. => all drives   */
      if verify( YY, '/:\', 'M' ) = 0  then  do N = 1 to words( M )
         call SCAN D, word( M, N ) || '\' || YY
      end N                            /* if file => all drives   */
      else  call SCAN D, YY            /* if path => respect it   */
   end

   call lineout LOG
   if lines( LOG ) > 0  then  say 'see' LOG
                        else  say LOG 'empty'
   exit 0

SCAN: procedure expose LOG             /* display recent files... */
   MONTHS = 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec'

   if sign( SysFileTree( arg(2), 'PATH', 'FST' )) then drop PATH
   do N = 1 to PATH.0
      parse var PATH.N DATE TAIL HEAD PATH.N
      if verify( left( DATE, 1 ), '89' )  then DATE = '20' || DATE
                                          else DATE = '19' || DATE
      if DATE < arg(1) then iterate N  /* ignore all older files  */

      HEAD = HEAD right( TAIL, 9 )
      TAIL = translate( right( DATE, 5 ), ':', '/' ) PATH.N
      DATE = substr( DATE, 6, 5 )   ;  TAIL = right( DATE, 2 ) TAIL
      say HEAD word( MONTHS, left( DATE, 2 )) TAIL
      call lineout LOG, HEAD word( MONTHS, left( DATE, 2 )) TAIL
   end N
   return

HELP: procedure                  /* error info and usage message  */
   parse source . . THIS
   if arg( 1, 'e' )  then  say 'error:' arg( 1 )
   say
   say 'usage:' THIS 'days [patterns]'
   say
   say 'Show all files modified in the last 0 up to 28 days'
   say 'matching the given patterns (default: * on all drives).'
   say
   say '`'|| THIS 0 || '` lists "future" files.'
   return 1

/* see <URL:http://purl.net/xyzzy/rexxtrap.htm>, (c) F. Ellermann */

XENV: procedure                  /* DOS REXX portable environment */
   parse version ENV . .
   if ENV = 'REXXSAA' then do
      parse source ENV . .       /* OS/2 REXXSAA:  os2environment */
      if ENV = 'OS/2'   then ENV = 'OS2ENVIRONMENT'
                        else ENV = ENV || 'ENVIRONMENT'
   end                           /* DOS  REXXSAA:  DOSENVIRONMENT */
   else  ENV = 'ENVIRONMENT'     /* REXX/Personal:    environment */
   select
      when arg() = 1 then  return value( arg( 1 ),/* get */, ENV )
      when arg() = 2 then  return value( arg( 1 ), arg( 2 ), ENV )
      otherwise            return abs( /* force REXX error 40 */ )
   end

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
      when 1 then do                   /* in pipes STDERR: output */
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
