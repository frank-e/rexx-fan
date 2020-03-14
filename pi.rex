/*  # title   formula                                          */
/*  1 Zeta  2 PI*PI =       6   * (1+1/4+1/9+....1/(n** 2)+..) */
/*  2 Zeta  4 PI**4 =      90   * (1+1/16+1/81+..1/(n** 4)+..) */
/*  3 Zeta  6 PI**6 =     945   * (1+1/64+.......1/(n** 6)+..) */
/*  4 Zeta  8 PI**8 =    9450   * (1+1/256+......1/(n** 8)+..) */
/*  5 Zeta 10 PI**10=   93555   * (1+1/1024+.....1/(n**10)+..) */
/*  6 Zeta 12 PI**12= 12!/(2**11* B( 6)) * (1+...1/(n**12)+..) */
/*  7 Zeta 14 PI**14=  912612.5 * (1+1/16384+....1/(n**14)+..) */
/*  8 Zeta 16 PI**16= 16!/(2**15* B( 8)) * (1+...1/(n**16)+..) */
/* ..  ..  ..  B(n) = n-th Bernoulli number                    */
/* 21 Zeta 42 PI**42= 42!/(2**41* B(21)) * (1+...1/(n**42)+..) */
/* 22 Euler-1 PI**3 =  32   * (1-1/27+.. +-1/((2*n-1)**3)+-..) */
/* 23 Euler-2 PI**5 = 307.2 * (1-1/243+..+-1/((2*n-1)**5)+-..) */
/* 24 Euler-3 PI**7 = 6!* 256/E(3) *(1-..+-1/((2*n-1)**7)+-..) */
/* ..  ..  ..  E(n) = n-th Euler number (+-: alternating sign) */
/* 28 Euler-7 PI**15= 14!*(2**16)/E(7)*(..+-1/((2*n-1)**15)..) */
/* 29 Leibniz PI =  4*atan 1 = 4*(1-1/3+1/5+-...1/(2*n+1)+-..) */
/* 30 Euler   PI =  4*atan 1/2 + 4*atan 1/3                    */
/* 31 Machin  PI = 16*atan 1/5 - 4*atan 1/239                  */
/* 32 Meissel PI = 32*atan 1/10- 4*atan 1/239-16*atan 1/515    */
/* 33 acot 2  PI =  4*atan 1/2 + 4*atan 1/5  + 4*atan 1/8      */
/* 34 acot 7  PI = 20*atan 1/7 + 8*atan 3/79                   */
/* 35 acot 10 PI = 32*atan 1/10- 4*atan 1758719/147153121 :#32 */
/* 36 acot 12 PI = 12*atan 1/12+28*atan 1/17 + 8*atan 101/1618 */
/* 37 asin .5 PI = 6 * arcsin( 1/2 )                           */
/* 38 Wallis  PI > 2 * (4/3+16/15+36/35+...4*n*n/(4*n*n-1)+..) */
/* 39 Gamma   PI = Gamma(1/2) ** 2, even worse than Wallis #38 */
/* 40 Zeta 2n PI**(2*n) > (2*n)! / (( 2**(2*n-1) ) * B(n))     */
/*            N.B.: this is the first term of formulae #1..#21 */
/* 41 sin x/x PI = PI / (2 * sin(PI/6)) using (sin x) / x sum  */
/* 42 B'stein PI = 4 - 8 *( 1/(3*5)+..1/((4*n-1)*(4*n+1))+.. ) */
/*            (unknown author, found in Bronstein-Semendjajev) */

/* For straight formulae the number of terms (= iterations) is */
/* shown, otherwise the number of iterations needed to get the */
/* n-th root of PI**n is shown or added.  Results are given in */
/* the order of convergence speed (excluding slow formulae,    */
/* which did not reach an accurate result).  The chosen output */
/* works best with upto 20 or upto 60 digits in 80 columns.    */
/* The first 60 - 1 = 59 digits of the PI-fraction (PI-3) are: */
/* 14159265358979323846264338327950288419716939937510582097494 */

/*                                          Meissel's formula  */
/* needs obviously D+1 terms for 2*D digits (using atan 1/10), */
/* or more exactly 10*(D+1) multiplications (incl. divisions)  */
/* with 10 = 3 * M + 1 for M = 3 atan-arguments => O(10+D*10). */
/* Using acot 7 requires S * 7 multiplications (7=3*2+1) with  */
/* S = trunc( 1 + D * ln 10 / ln 7 ) => O( 1+ D * 8.2857143 ). */

/* Generally any atan-formula needs about D* ln 10/ln A terms, */
/* where 1/A is its absolutely biggest atan-argument, example: */
/*  30*ln 10/ln 10 = 30, 31 terms for Meissel using atan 1/10, */
/*  30*ln 10/ln 7  > 35, 37 terms for acot-7 (or atan 1/7),    */
/*  30*ln 10/ln 2  > 99, 99 terms for Euler's acot 2=atan 1/2. */
/* Replacing ln 10 by ln 2 yields needed terms for 2*B binary  */
/* (instead of 2*D decimal) digits, i.e. B in Euler's formula: */
/* 100*ln 2 /ln 2 = 100, 99 terms, 2*B=200 digits => O(7*B-7). */

   signal on novalue ;  FIX = 21 ;  arg USE RED .

   if USE = '!' then do L = 1
      parse value sourceline( L ) with '/*' USE '*/'
      say USE  ;  if USE = '' then exit 1
      if L // 11 = 0 then pull
   end L

   if \ datatype( USE, 'W' ) then USE = 0 - FIX - 1
   if 2 * FIX < USE | USE < 0 - FIX then do
      parse upper source . . USE
      USE = substr( USE, 1+ lastpos( '\', USE ))
      USE = substr( USE, 1+ lastpos( '/', USE ))
      if pos( '.', USE ) > 0
         then USE = left( USE, lastpos( '.', USE ) -1 )
      RED = digits()
      say USE ' 0   shows' 2 * FIX 'pi-formulae with' RED 'digits'
      RED = copies( ' ', length( USE ))
      say USE ' 0 N shows' 2 * FIX 'pi-formulae with N digits,'
      say RED '     but N > 20 digits is very slow...'
      say USE '-M'
      say USE '-M N dito excluding pi-formulae 1..' || FIX
      say RED '     except from Bernoulli 0 < M <' FIX + 1
      say USE ' M'
      say USE ' M N shows only pi-formula 0 < M <' 2 * FIX + 1
      say USE '!    list of supported formulae 1..' || 2 * FIX
      exit 1
   end

   if RED = '' then RED = digits()  ;  else RED = max( RED, 2 )
   numeric fuzz 1    ;  numeric digits RED + 2
   ROD = 0           ;  EXP1 = EXP(1)  /* e used by LN and EXP */

   do L = 1 to FIX   ;  E.L = 1     ;  end L
   E.1 = 1           ;  E.2 = 5     ;  E.3 = 61
   E.4 = 1385        ;  E.5 = 50521 ;  E.6 = 2702765
   E.7 = 199360981   ;  F   = 1     ;  T   = 1

   do L = 1 to FIX
      F = F * 2 * L * ( 2 * L - 1 )    ;  T = T * 4
      D.L = 0  ;  N.L = 0  ;  P.L = 0
      A.L = F * 2 / ( T * B( L ))      /* used for Bernoullis  */
      O.L = ( USE = 0 | USE = L | USE = -L )
      M = L + FIX
      D.M = 0  ;  N.M = 0  ;  P.M = 0
      A.M = T * F * 4 / E.L            /* used for Euler terms */
      O.M = ( USE <= 0 | USE = M )
   end L

   signal on halt ;  DONE = 0          /* handle loop abortion */
   say 'formula root loop pi (' || RED 'digits)'

   do N = 1 until DONE
      do L = 1 to FIX                  /* use Bernoulli 1..FIX */
         TEXT = 'Zeta' right( 2 * L, 2 )
         if D.L <> O.L then do         /* if not yet constant: */
            O.L = D.L
            D.L = D.L + A.L / ( N ** ( 2 * L ))
            P.L = RED( ROOT( D.L, 2 * L ))
            N.L = N || '+' || ROD      /* necessary iterations */
            say TEXT || right( ROD, 5 ) || right( N, 5 ) P.L
            DONE = DONE + (N < 999)    /* enforced termination */
         end
         M = L + FIX
         if D.M <> O.M then do         /* if not yet constant: */
            T = 2 * N - 1  ;  if N // 2 then O.M = D.M
            if L > 7 then do           /* check only odd terms */
               select                  /* for alternating sign */
                  when L = 21 then do  /* slow: no DONE count  */
                     if N = 1 then D.M = 1
                     D.M = D.M - 2 / ((4 * N - 1) * (4 * N + 1))
                     TEXT = "B'stein"  /* (Bronstein 4.1.8.10) */
                  end
                  when L = 20 then do  /* 3/pi= sin(pi/6)*6/pi */
                     D.M = 0  ;  N.M = 1
                     P.M = 1  ;  E.L = - E.L * E.L / 36
                     do T = 3 by 2 until ROD = D.M
                        ROD = D.M
                        D.M = D.M + P.M / N.M
                        P.M = P.M * E.L
                        N.M = N.M * T * ( T - 1 )
                     end T             /* sum for (sin x) / x  */
                     E.L = 3 / D.M     ;  N.M = N || '+' || T
                     TEXT = 'sin x/x' || right( T, 5 )
                     P.M = RED( E.L )  ;  T = 0
                     say TEXT || right( N, 5 ) P.M
                  end                  /* T=0: no pi/4 formula */
                  when L = 19 then do  /* ZETA(2N) <= PI**(2N) */
                     E.L = E.L * T * ( T + 1 )
                     D.M = E.L / (( 2 ** T ) * B( N ))
                     D.M = RED( ROOT( D.M, T + 1 ))
                     TEXT = 'Zeta(' || T + 1 || ')'
                     N.M = N || '+' || ROD   ;  P.M = D.M
                     say TEXT right( ROD, 10 -length( T + 1 )) P.M
                     T = 0             /* T=0: no pi/4 formula */
                  end
                  when L = 18 then do  /* Gamma(0.5)=Root(pi): */
                     E.L = E.L * N / ( N + 0.5 )
                     D.M = ROOT( N, 2 ) * E.L * 2
                     P.M = RED( D.M * D.M )
                     N.M = N || '+' || ROD
                     TEXT = ' Gamma' right( ROD, 5 )
                     say TEXT || right( N, 5 ) P.M
                     T = 0             /* T=0: no pi/4 formula */
                  end
                  when L = 17 then do
                     D.M = 4 * N * N   /* slow: no DONE count  */
                     E.L = E.L * D.M /(D.M - 1) ;  D.M = E.L / 2
                     TEXT = ' Wallis'  /* common pi/4 handling */
                  end
                  when L = 16 then do
                     DONE = DONE + 1   /* fast: count not DONE */
                     if N > 1          /* using 2 * arcsin 1/2 */
                        then E.L = (E.L / 4) * ( T-2 ) / ( T-1 )
                     D.M = D.M + 3 * (E.L / 4) / T
                     TEXT = 'asin .5'  /* pi = 6 * arcsin 1/2  */
                  end
                  when L = 15 then do
                     DONE = DONE + 1   ;  E.L = (1618 / 101) ** T
                     T = ( 2 / E.L +7 / (17**T) +3 / (12**T)) / T
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + T
                        else D.M = D.M - T
                     TEXT = 'acot 12'  /* pi=12 arccot 12 +28* */
                  end                  /* A(17) +8 A(1618/101) */
                  when L = 14 then do
                     DONE = DONE + 1   ;  E.L = 147153121/1758719
                     T = ( -1 / (E.L ** T) +8 / (10 ** T)) / T
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + T
                        else D.M = D.M - T
                     TEXT = 'acot 10'  /* = variant of Meissel */
                  end
                  when L = 13 then do
                     DONE = DONE + 1   /* fast: count not DONE */
                     T = ( 2 / ( (79/3)**T ) +5 / ( 7**T )) / T
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + T
                        else D.M = D.M - T
                     TEXT = 'acot 7 '  /* pi = 20 arccot 7     */
                  end                  /*       8 arccot 79/3  */
                  when L = 12 then do
                     DONE = DONE + 1   /* fast: count not DONE */
                     T = ( 1/( 8**T ) +1/( 5**T ) +1/( 2**T )) / T
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + T
                        else D.M = D.M - T
                     TEXT = 'acot 2 '  /* pi/4 = arccot 2      */
                  end                  /*  +arccot 5 +arccot 8 */
                  when L = 11 then do
                     DONE = DONE + 1   /* fast: count not DONE */
                     T = (-4/(515**T) -1/(239**T) +8/(10**T) ) / T
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + T
                        else D.M = D.M - T
                     TEXT = 'Meissel'  /* pi = 32 arccot 10    */
                  end                  /* -4 A(239) -16 A(515) */
                  when L = 10 then do
                     DONE = DONE + 1   /* fast: count not DONE */
                     T = ( -1 / ( 239**T ) +4 / ( 5**T )) / T
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + T
                        else D.M = D.M - T
                     TEXT = ' Machin'  /* pi = 16 arccot 5     */
                  end                  /*      -4 arccot 239   */
                  when L =  9 then do
                     DONE = DONE + 1   /* fast: count not DONE */
                     T = ( +1 / ( 3**T ) +1 / ( 2**T )) / T
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + T
                        else D.M = D.M - T
                     TEXT = '  Euler'  /* pi =  4 arccot 2     */
                  end                  /*      +4 arccot 3     */
                  when L =  8 then do
                     if N // 2         /* odd plus, even minus */
                        then D.M = D.M + 1 / T
                        else D.M = D.M - 1 / T
                     TEXT = 'Leibniz'  /* pi =  4 arccot 1     */
                  end
                  otherwise   T = 0
               end
               if T <> 0 then do       /* common PI/4 handling */
                  P.M = RED( 4 * D.M ) ;  N.M = N
                  say TEXT right( N.M, 9 ) P.M
               end
            end
            else do
               if N // 2               /* odd plus, even minus */
                  then D.M = D.M + A.M / ( T ** ( 2 * L + 1 ))
                  else D.M = D.M - A.M / ( T ** ( 2 * L + 1 ))
               P.M = RED( ROOT( D.M, 2 * L + 1 ))
               N.M = N || '+' || ROD
               TEXT = 'Euler-' || L || right( ROD, 5 )
               say TEXT || right( N, 5 ) P.M
               DONE = DONE + (N < 999) /* enforced termination */
            end
         end
      end L
      if USE > 0
         then DONE = ( O.USE = D.USE ) /* DONE: no more change */
         else DONE = ( DONE  = 0     ) /* (almost) all stopped */
   end N

   /* --- sort and show results ------------------------------ */
HALT:
   if USE > 0 then exit 0              /* single formula shown */

   numeric fuzz 0 ;  numeric digits RED   ;  RED = 0
   do L = 1 to FIX * 2                 /* max pi approximation */
      if D.L == O.L then RED = max( RED, P.L )
   end L
   numeric fuzz min( 1, digits() - 2 ) /* no fuzz for 2 digits */

   do L = 1 to FIX
      O.L = 'Zeta' right( 2 * L, 2 ) right( N.L, 8 )
      select
         when P.L  = 0     then N = '000000'
         when P.L <> RED   then N = '999999'
         otherwise   interpret 'N = right(' N.L ', 6, 0 )'
      end                              /* P.L <> pi devaluated */
      if N = 0 then  O.L = N  ;  else  O.L = N O.L P.L
      M = L + FIX
      select
         when L = 21 then  O.M = "B'stein" right( N.M, 8 )
         when L = 20 then  O.M = 'sin x/x' right( N.M, 8 )
         when L = 19 then do
            parse var N.M N '+' O.M ;  N = 2 * N
            O.M = 'Zeta(' ||N|| ')' right( O.M, 9 - length( N ))
         end
         when L = 18 then  O.M = '  Gamma' right( N.M, 8 )
         when L = 17 then  O.M = ' Wallis' right( N.M, 8 )
         when L = 16 then  O.M = 'asin .5' right( N.M, 8 )
         when L = 15 then  O.M = 'acot 12' right( N.M, 8 )
         when L = 14 then  O.M = 'acot 10' right( N.M, 8 )
         when L = 13 then  O.M = 'acot 7 ' right( N.M, 8 )
         when L = 12 then  O.M = 'acot 2 ' right( N.M, 8 )
         when L = 11 then  O.M = 'Meissel' right( N.M, 8 )
         when L = 10 then  O.M = ' Machin' right( N.M, 8 )
         when L = 9  then  O.M = '  Euler' right( N.M, 8 )
         when L = 8  then  O.M = 'Leibniz' right( N.M, 8 )
         when L < 8  then  O.M = 'Euler-' || L right( N.M, 8 )
         otherwise   O.M = '#' || left( M, 5 ) right( N.M, 8 )
      end
      select
         when P.M = 0      then N = '000000'
         when P.M <> RED   then N = '999999'
         otherwise   interpret 'N = right(' N.M ', 6, 0 )'
      end                              /* P.M <> pi devaluated */
      if N = 0 then  O.M = N  ;  else  O.M = N O.M P.M
   end L

   do L = 1 to FIX * 2                 /* sort by convergence: */
      K = L ;  RED = O.K
      do J = L + 1 to FIX * 2
         if O.J >> RED then do
            K = J ;  RED = O.K
         end
      end J
      O.K = O.L   ;  O.L = RED
   end L

   say copies( '-', 19 + digits())
   if digits() > 20 then do L = 1 to FIX * 2
      if abbrev( O.L, '000000' ) then leave L
      if abbrev( O.L, '999999' )       /* P.L <> pi indicator: */
         then say substr( translate( O.L, ':', '.' ), 8 )
         else say substr( O.L, 8 )     /* P.L (fuzzy) accurate */
   end L
   else do L = 2 to FIX * 2 by 2
      M = L - 1
      if abbrev( O.M, '000000' ) then leave L
      if abbrev( O.M, '999999' )       /* P.M <> pi indicator: */
         then M = substr( translate( O.M, ':', '.' ), 8 )
         else M = substr( O.M, 8 )     /* P.M (fuzzy) accurate */
      M = left( M, 39 )
      if abbrev( O.L, '999999' )       /* P.L <> pi indicator: */
         then say M substr( translate( O.L, ':', '.' ), 8 )
         else say M substr( O.L, 8 )   /* P.L (fuzzy) accurate */
   end L

   pull  ;  exit 0

RED:  procedure expose RED             /* reduce shown digits: */
   numeric digits RED   ;  return arg( 1 ) + 0

B:    procedure expose B.              /* Bernoulli numbers... */
   arg K                               /* calls are ascending  */
   if symbol( 'B.' || K ) = 'LIT' then do
      numeric digits digits() * 2      /* increased precision: */
      B.K = ( 2 * K - 1 ) / 2 ;  F = 1
      do N = 1 to K - 1
         F = F * ( 2 * K + 3 - 2 * N ) / ( 1 - 2 * N )
         F = F * ( 2 * K + 2 - 2 * N ) / (     2 * N )
         B.K = B.K + B.N * F
      end N
      B.K = abs( B.K / ( 2 * K + 1 ))
   end
   return B.K

ROOT: procedure expose EXP1 ROD        /* N-th root of X > 0:  */
   arg X, N ;  return EXP( LN( X ) / N )

EXP:  procedure expose EXP1 ROD        /* exp( X ) sum formula */
   arg X                               /* ok. for small 0 <= X */
   if X < 0 then return 1 / EXP( -X )  /* e**(-X) = 1 / (e**X) */
   if X > 8 then do                    /* e**(N+y)=e**N * e**y */
      N = trunc( X ) ;  X = X - N      /* X = N.y splits X > 8 */
      return ( EXP1 ** N ) * EXP( X )
   end

   S = 1 ;  P = 1
   do N = 1 until R = S
      R = S ;     P = P * X / N  ;  S = S + P   ;  ROD = ROD + 1
   end N
   return S

LN:   procedure expose EXP1 ROD        /* ln( X ) log natural. */
   arg X
   if X < 0 then return abs()          /* force error by abs() */
   if X < 1 then return - LN( 1 / X )  /* force error if X = 0 */
   do N = 0 while EXP1 <= X   ;  X = X / EXP1   ;  end N
   if N > 0 then return N + LN( X )    /* ln(x*(e**N))=N+ln(x) */

   P = ( X - 1 ) / ( X + 1 )  ;  X = P * P   ;  S = 0
   do ROD = 1 by 2 until R = S
      R = S ;  S = S + 2 * P / ROD  ;  P = P * X
   end ROD
   return S

