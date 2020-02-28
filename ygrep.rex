/* NT ooREXX - grep first occurence of pattern per file, and sort */
/* result by the number of occurences.  If the pattern contains a */
/* space it has to be quoted.                                     */

/* Bug fix 2019: Drop option /P (scan only Printable files), this */
/* now skips ordinary *.CMD shell scripts, not only binary files. */

/* This is a clone of OS/2 <http://purl.net/xyzzy/src/ygrep.cmd>. */
/* This variant uses FINDSTR instead of 'grep -i'.  I replaced an */
/* old TRAP handler by a similar ERROR handler, because NT is not */
/* OS/2, ooRexx is no SAAREXX, and Regina <STDERR> is not STDERR. */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

/* -------------------------------------------------------------- */

   if abbrev( strip( arg( 1 )), '"' )
      then  parse arg '"' PAT '"' TXT
      else  parse arg     PAT     TXT
   TXT = strip( TXT )
   if TXT = '' then  TXT = '*.txt'
   if PAT = '' then  exit USAGE()

   if abbrev( TXT, '"' )   then  do
      parse var TXT '"' SUB '"' BAD
      if BAD <> ''         then  exit USAGE( TXT )
      TXT = SUB
   end

   WLD = TXT                     ;  SUB = ''
   if abbrev( TXT, '*\' )  then  do
      SUB = substr( TXT, 3 )
      if SUB = ''          then  exit USAGE( TXT )
      WLD = SUB                  ;  SUB = '/S'
   end                           /* scan CWD + subdirectories /S  */
   WLD = '"' || WLD || '"'       /* insensitive /I, reg. exp. /R  */

   OLD = queued()
   say space('FINDSTR' SUB '/I /R /C:"' ) || PAT || '"' WLD
   call RXLIFO 'FINDSTR' SUB '/I /R /C:"' || PAT || '"' WLD
   if rc <> 0 | queued() <= OLD  then  do
      say 'found no "' || PAT || '" in "' || TXT || '"'
      do while queued() > OLD
         pull
      end
      exit max( 1, abs( rc ))
   end

   GOT = ''
   N = 0                         ;  W.0 = 0
   do while queued() > OLD
      parse pull TXT ':' PAT
      if abbrev( GOT, strip( TXT ) || ':' ) = 0 then  do
         if N > 0 then  do
            L = W.0 + 1          ;  W.0 = L
            W.L = right( min( N, 999 ), 3 ) GOT
            N = 0
         end
         GOT = strip( TXT ) || ':' PAT
      end
      N = N + 1
   end
   if N > 0 then  do
      L = W.0 + 1                ;  W.0 = L
      W.L = right( min( N, 999 ), 3 ) GOT
   end

   call KWIK 'W.'                /* sort by number of occurences  */
   do N = 1 to W.0
      say left( W.N, 79 )
   end N
   return 0

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'pattern [files]'
   say                           /* suited for REXXC tokenization */
   say ' Double quote pattern as needed.  Default files: *.txt'
   say ' To scan *.txt files in the current working directory'
   say ' and all subdirectories use *\*.txt.  This is only a'
   say ' hack to get Windows NT FINDSTR option /S in addition'
   say ' to /I (case insensitive) and /R (regular expression).'
   return 1

/* -------------------------------------------------------------- */

KWIK:                            /* quick sort: call KWIK 'stem.' */
   if arg() <> 1 then return abs( /* REXX error 40 */ )
   THIS... = arg( 1 )            /* abuse global THIS... as stem  */
   if right( THIS... , 1 ) <> .  then  THIS... = THIS... || .
   return KWIK.Y( THIS... )      /* expose THIS... stem           */

KWIK.Y:  procedure expose ( THIS... )
   S = 1 ;  SL.1 = 1 ;  SR.1 = value( THIS... || 0 )

   do until S = 0
      L = SL.S ;  R = SR.S ;  S = S - 1                  /* pop   */

      do while L < R
         I = ( L + R ) % 2 ;  P = value( THIS... || L )

         XR = value( THIS... || R )
         if XR << P then do                              /* R...L */
            call value THIS... || R, P
            call value THIS... || L, XR   ;  P = XR
         end                                             /* L...R */
         XI = value( THIS... || I )
         XR = value( THIS... || R )
         select
            when XI << P then do                         /* I L R */
               call value THIS... || I, P
               call value THIS... || L, XI
            end                                          /* L I R */
            when XI >> XR then do                        /* L R I */
               call value THIS... || R, XI
               call value THIS... || I, XR   ;  P = XR
            end                                          /* L I R */
            otherwise   P = XI                           /* L I R */
         end

         I = L + 1   ;  J = R - 1                        /* I...J */
         if J <= I then leave                            /* ready */

         do until I > J
            do while value( THIS... || I ) << P ;  I = I+1  ;  end
            do while value( THIS... || J ) >> P ;  J = J-1  ;  end

            if I <= J then do
               XI = value( THIS... || I )
               call value  THIS... || I, value( THIS... || J, XI )
               I = I + 1   ;  J = J - 1
            end
         end /* I  > J */

         if J - L < R - I then do               /* less left keys */
            S = S + 1   ;  SL.S = I ;  SR.S = R ;  R = J
         end               /* pushed old R - I > 1 keys, now do L */
         else do                                /* more left keys */
            S = S + 1   ;  SL.S = L ;  SR.S = J ;  L = I
         end               /* pushed J - old L > 1 keys, now do R */
      end    /* R <= L */
   end       /* S == 0 */
   return value( THIS... || 0 )

/* ----------------------------- (RXQUEUE portability 2016-03-05) */
/* ooRexx 6.04 does not yet support ADDRESS ... WITH, otherwise   */
/* the same syntax could get the command output in a REXX stem    */
/* without using a REXX queue (aka REXX stack).                   */

RXLIFO:  procedure expose rc
   signal off error              ;  parse version . REXX .
   LIFO = 'RxQueue' rxqueue( 'get' ) '/LIFO'
   if REXX <> 5   then  address CMD     arg( 1 ) '|' LIFO
                  else  address SYSTEM  arg( 1 ) '|' LIFO
   return ( .RS < 0 )            /* 0: okay (any rc), 1: failure  */

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

