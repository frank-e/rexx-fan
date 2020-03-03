/* 7B-format specification and NT ooREXX (classic REXX) encoder   */

/* 7B-format overview:                                            */
/* 7B-encoded binaries consist of octets 21 .. 7E organized as    */
/* text lines.  A concept of text lines is not specified here,    */
/* because it depends on the application and operating system,    */
/* notably CRLF vs. LF line terminators, or fixed line lengths    */
/* without line terminator.  However, HT (09), LF (0A), CR (0D),  */
/* and SP (20) are the only octets permitted to form some kind    */
/* of line for 7B-encoded text.   White space SP or HT is only    */
/* permitted at the begin or end of whatever constitutes a line.  */

/* The 12 octets 24..2F are used as lead bytes and introduce a    */
/* pair of lead and trail byte.  The 16 octets 30..3F are used    */
/* as trail bytes.  The three octets 21..23 are singletons and    */
/* encode NUL (00), SP (20), or DEL (7F), respectively.           */

/* The 8*16 octets 80..FF are encoded with 8 lead bytes 28..2F    */
/* and 16 trail bytes 30..3F.  Likewise the 2*31 octets 01..1F    */
/* and 21..3F are encoded as pairs with lead bytes 24..27.        */

/* The two pairs 24 30 or 26 30 do not encode octets, because     */
/* NUL (00) and SP (20) are encoded as singletons 21 and 22.      */
/* The pair 24 30 is used as 7B-signature (magic).  The pair      */
/* 26 30 is used as EOF (end of file) mark.  Encoding summary:    */

/*    01..0F -> 24 plus 31..3F,     10..1F -> 25 plus 30..3F,     */
/*    21..2F -> 26 plus 31..3F,     30..3F -> 27 plus 30..3F,     */
/*    magic:    24 plus 30    ,         00 -> 21 (singleton),     */
/*      EOF:    26 plus 30    ,         20 -> 22 (singleton),     */
/*    40..7E -> (as is) 40..7E,         7F -> 23 (singleton),     */
/*    80..8F -> 28 plus 30..3F,     90..9F -> 29 plus 30..3F,     */
/*    A0..AF -> 2A plus 30..3F,     B0..BF -> 2B plus 30..3F,     */
/*    C0..CF -> 2C plus 30..3F,     D0..DF -> 2D plus 30..3F,     */
/*    E0..EF -> 2E plus 30..3F,     F0..FF -> 2F plus 30..3F.     */

/* 7B-encoding of compressed binaries with length N results in    */
/* a net encoded size 4 + N * 446 / 256, because 190 octets are   */
/* encoded as pairs (446 = 256 + 190).  The overhead for a line   */
/* length 80 yields about N * 1115 / 624, an increase of 79%.     */

/* For comparison:                                                */
/* - A similar 8B-encoding can encode 30..FF as is, use 28..2F    */
/*   as trail bytes, use 22..27 as lead bytes to encode 01..2F,   */
/*   use a singleton 21 to encode 00, and use 22 28 as magic      */
/*   and EOF.                                                     */
/*   The net 8B-encoded size is 4 + N * 303 / 256, for length     */
/*   80 this yields about N * 1515 / 1248, an increase of 22%.    */
/* - The net B64-encoded size is N * 4 / 3 plus 0..2 pad bytes.   */
/*   For length 80 B64-encoding yields about N * 160 / 117, an    */
/*   increase of 37%.  Factor 80 / 78 assumes CRLF line ends.     */

/* 7B-encoding (unlike B64) of uncompressed binaries can result   */
/* in different increases.  By design 7B encodes octet 00 as a    */
/* single octet, because runs of zero octets are common in some   */
/* uncompressed binary formats.  The worst case is UTF-8 input    */
/* without spaces and US-ASCII characters in the range 41..7E,    */
/* it results in a 7B-encoded size N * 2 * 80 / 78 (length 80).   */

/* 7B-requirements for encoders:                                  */
/* The ouput consists of bytes in the range 21..FF organized in   */
/* text lines with optional leading or trailing white space.      */
/* For the 7B-format "white space" can only occur at the begin    */
/* or end of a line and consists of SP (20) or HT (09).           */

/* The output line length SHOULD be limited to 80 octets (incl.   */
/* optional leading or trailing white space and line end, e.g.,   */
/* CRLF) and MUST NOT exceed 255 octets.                          */

/* The output line length MAY vary.  An output line MUST NOT be   */
/* empty, i.e., consist only of optional white space and a line   */
/* end.  The output begins with a signature 24 30 and ends with   */
/* 26 30.  An empty file is therefore encoded as 24 30 26 30 in   */
/* at most four lines.                                            */

/* If a fixed line length is desired lead and trail byte pairs    */
/* can be separated by a line end (incl. optional trailing and    */
/* leading white space).  Generally trailing white space might    */
/* not survive mail transport or processing with text editors,    */
/* but MAY be used as filler in the last line after the end of    */
/* file mark 26 30 for output with a fixed line length.           */

/* An encoder can be implemented with 9 conditions including      */
/* three loops (input loop with buffer and line output loops).    */

/* 7B-requirements for decoders:                                  */
/* 7B-encoded input begins with hex. 24 30 and ends with 26 30.   */
/* If that is not the case the decoder MUST initiate its error    */
/* processing.  In the error processing a decoder SHOULD erase    */
/* or otherwise invalidate its output and report an error.        */

/* Decoders split their input into lines and strip any leading    */
/* or trailing white space (hex. 20 or 09).  If the remainder     */
/* contains any octets in the ranges 00..20 or 7F..FF a decoder   */
/* MUST start its error processing.  Notably VT (0B), FF (0C),    */
/* and unexpected CR (0D) octects MUST be processed as errors.    */

/* The decoder MUST initiate its error processing if a lead byte  */
/* 24..2F is not followed by a trail byte 30..3F (or vice versa). */

/* Lead and trail byte pairs can be separated by a line end with  */
/* trailing or leading white space as specified above.  The pair  */
/* 24 30 can only occur at the begin, otherwise it MUST trigger   */
/* the error processing.                                          */

/* If the decoder reaches the physical end of the input without   */
/* finding an end of file indicator 26 30 it MUST initiate its    */
/* error processing.  Decoders MUST close the input stream in     */
/* their error or EOF processing.  Notably input lines after an   */
/* end of file indicator 26 30 are no error and MUST be ignored.  */

   signal on notready name INERROR     ;  signal on novalue
   IN = strip( arg( 1 ))               ;  CC = abbrev( IN, '+' )

   if CC == abbrev( IN, '-' ) then  do
      parse source . . IB              ;  OB = 'stderr'
      call lineout OB, 'usage:' IB '+|- [file]'
      call lineout OB, '+ [file] encodes file or stdin to stdout'
      call lineout OB, '- [file] decodes file or stdin to stdout'
      exit 1
   end

   IN = strip( strip( strip( substr( IN, 2 )),, '"' ))
   if '' = IN  then  IN = 'stdin'
   if 0  = CC  then  exit DECODE( IN )

   CC = chars( IN )                    /* encode also file size 0 */
   LL = 78                             /* pick output line length */
   OB = x2c( 24 30 )                   /* start with a signature  */

   do while sign( CC )
      IB = charin( IN,, min( 4096, CC ))
      CC = chars( IN )
      do until IB == ''
         D = c2d( left( IB, 1 ))       ;  IB = substr( IB, 2 )
         select
            when  127 < D  then  do    /* hex. xy 80..FF to 2x 3y */
               X = D // 16             ;  D = ( D - X ) % 16
               OB = OB ||  d2c( 32 + D ) || d2c( 48 + X )
            end
            when  127 = D  then  OB = OB || x2c( 23 )
            when   63 < D  then  OB = OB || d2c( D )
            when   32 = D  then  OB = OB || x2c( 22 )
            when    0 = D  then  OB = OB || x2c( 21 )
            when   64 > D  then  do    /* xy 01..3F to  24..27 3y */
               X = D // 16             ;  D = ( D - X ) % 16
               OB = OB ||  d2c( 36 + D ) || d2c( 48 + X )
            end
         end
      end
      do while LL <= length( OB )
         say left( OB, LL )            ;  OB = substr( OB, LL + 1 )
      end
   end

   OB = OB || x2c( 26 30 )             /* end with EOF signature, */
   do while LL <= length( OB )         /* trim last output lines: */
      say left( OB, LL )               ;  OB = substr( OB, LL + 1 )
   end
   if OB <> '' then  say left( OB, LL )
   exit 0

INERROR:
   if condition() = ''  then  do       /* DECODE( IN ) error 2..9 */
      call lineout 'stderr', '"' || IN || '" error' arg( 1 )
      return arg( 1 )
   end
   call lineout 'stderr', '"' || IN || '"' stream( IN, 'd' )
   exit 1                              /* IN (or stdout) NOTREADY */

DECODE:  procedure
   parse arg IN                        ;  OF = 'stdout'
   L = 1                               ;  OB = ''

   do while sign( lines( IN ))
      IB = strip( translate( linein( IN ), x2c( 20 ), x2c( 09 )))

      if IB = ''  then  return INERROR( 2 )
      do while IB <> ''
         D = c2d( left( IB, 1 ))       ;  IB = substr( IB, 2 )
         select
            when  0 = L then  select   /* no pending lead byte L  */
               when   33 > D        then  return INERROR( 3 )
               when   33 = D        then  OB = OB || x2c( 00 )
               when   34 = D        then  OB = OB || x2c( 20 )
               when   35 = D        then  OB = OB || x2c( 7F )
               when   48 > D        then  L = D - 32
               when   64 > D        then  return INERROR( 4 )
               when  127 > D        then  OB = OB || d2c( D )
               otherwise                  return INERROR( 5 )
            end                        /* ----------------------- */
            when  D < 48 | 63 < D   then  return INERROR( 6 )
            when  4 > L then  select   /* magic 2430 (dec. 36 48) */
               when  36 = D & 1 = L then  L = 2
               when  48 = D & 2 = L then  L = 0
               otherwise                  return INERROR( 7 )
            end                        /* ----------------------- */
            when  7 < L    then  do    /* for lead bytes 28 .. 2F */
               OB = OB || d2c( D - 48 + 16 * L )
               L = 0
            end                        /* ----------------------- */
            when  L // 2   then  do    /* for lead bytes 25 or 27 */
               OB = OB || d2c( D - 112 + 16 * L )
               L = 0
            end                        /* ----------------------- */
            when  D > 48   then  do    /* for lead bytes 24 or 26 */
               OB = OB || d2c( D - 112 + 16 * L )
               L = 0
            end                        /* ----------------------- */
            when  6 = L    then  do    /* found 2630 (EOF)        */
               call charout OF, OB     ;  return 0
            end                        /* ----------------------- */
            when  4 = L    then           return INERROR( 8 )
         end                           /* magic 2430 not at begin */
      end
      call charout OF, OB              ;  OB = ''
   end
   return INERROR( 9 )

