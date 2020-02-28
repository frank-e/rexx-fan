/* REXX MD5 procedures and RfC examples (version 2.1), for future */
/* updates see <URL:http://purl.net/xyzzy/src/md5.cmd>.  This is  */
/* only the code and a test suite, copy wanted procedures to REXX */
/* scripts (e.g. <URL:http://purl.net/xyzzy/src/popstop.cmd>).    */

/* -------------------------------------------------------------- */
/* Modifications in version 2.1:                                  */
/* - ToDo: fix PHPASS(), add SUNMD5(), rename APR1() to BSDMD5()  */
/* - Fixed stupid MF2B32() bug found by classic REXX-Regina 3.7   */
/* Modifications in version 2.0:                                  */
/* - added 3 NIST NSRL tests <http://www.nsrl.nist.gov/testdata/> */
/* - RfC 2384 APOP erratum 2943 now enabled (verified after 1.9)  */
/* Modifications in version 1.9:                                  */
/* - added Solar Designer PHPASS(); disabled due to unclear bug   */
/* - added five APR1() "MD5 crypt" tests from different sources   */
/* - added historic RfC 2777 NomCom code variant, this allows to  */
/*   test fraction input in NOMCOM() with an RfC 2777 example     */
/* - added IETF NomCom 2009, 2010, and 2011 selections (RfC 3797) */
/* - RfC 6331 moved RfC 2831 SASL DIGEST-MD5 to "historic":  This */
/*   move was announced in an MD5 test suite version before 1.2;  */
/*   it affects only procedure DIGEST(), not RfC 2617 AUTHTTP()   */
/* Modifications in version 1.8:                                  */
/* - check out RfC 6151 for updated MD5 security considerations   */
/* - added "minimal" collision by Tao Xie and Dengguo Feng (2010, */
/*   the one page PDF announcement uses a little endian notation) */
/* - added "web-safe base64" input, compare RfC 4648 erratum 2837 */
/* - Unpadded ("invalid") base64 input STILL not supported, but   */
/*   non-canonical input with correct padding as in 'YR==' works  */
/* - NOMCOM (RfC 3797) alpha input STILL not tested               */
/* - exit code 0 fixed, BAD <> 3 exit in version 1.7 was for 1.6  */
/* Modifications in version 1.7:                                  */
/* - all expected errors eliminated (see below), all should PASS  */
/* - four RfC errata for MD5 verified by the IESG in 2009...2010  */
/*   RfC 2069 erratum  749 (code modified to use fixed MD5 value) */
/*   RfC 4122 erratum 1352 \/ (code to demonstate these verified  */
/*   RfC 2938 erratum 1080 /\  errata removed in MD5 version 1.7) */
/*   RfC 3920 erratum 1406 (editorial, no code in the test suite) */
/* - added NomCom 2008 example (was published as hot fix for 1.6) */
/* Modifications in versions 1.6:                                 */
/* - added RfC 5034 POP3 DIGEST-MD5 example with RfC 2617 variant */
/* - added RfC 4122 UUID example (with a fix for erratum 1352)    */
/* - added RfC 1910 example, very slow, disabled by IF 0 THEN ... */
/* Modifications in versions 1.5:                                 */
/* - updated for RfC 5090 (fixed two RFC 4590 RADIUS examples)    */
/* - added RfC 2617 AUTHTTP variant of RfC 2831 DIGEST procedure  */
/*   for different 'md5-sess' calculations, six new test cases.   */
/* - replaced DIGEST by AUTHTTP for six 'md5-sess' SIP examples   */
/*   found in the (expired) I-D.smith-sipping-auth-examples-01.   */
/* Minor modifications in version 1.3 and 1.4                     */
/* - RfC 2938 erratum submitted, RfC 2069 erratum finally listed. */
/* - added NomCom 2007 example, allow 38 digits entropy in MD5    */
/* Features added in version 1.2:                                 */
/* - MD5 code rewritten to allow incremental updates (streaming), */
/*   bit strings are now also supported.  Usage:                  */
/*       hash = MD5( bytes )          ==> MD5 of an octet string  */
/*       ctxt = MD5( bytes, '' )      ==> init.  new MD5 context  */
/*       ctxt = MD5( bytes, ctxt )    ==> update old MD5 context  */
/*       hash = MD5( /**/ , ctxt )    ==> finalize   MD5 context  */
/*       hash = MD5( bytes, /**/, n ) ==> MD5 of n zero-fill bits */
/*       ctxt = MD5( bytes, ''  , n ) ==> init.  MD5 bit context  */
/*       ctxt = MD5( bytes, ctxt, n ) ==> update MD5 bit context  */
/* - pre v1.2 history removed                                     */
/* - APR1 passwd, 2 tests copied from the OpenSSL 0.9.6m manual,  */
/*   3rd test verified with a 'htpasswd' and an 'openssl passwd'. */
/* - added six SIP INVITE tests found in an old Internet Draft.   */
/* - added seven B64 examples found in RfC 4648 (obsoleted 3548), */
/*   fixed B64.I() bug for an empty input string.                 */

/* -------------------------------------------------------------- */
/* List of procedures:                                            */
/* TEST     procedure to display and count test case errors       */
/* B64.I    base64 decoder used in test suite; B64.I = B64 input  */
/* B64.O    base64 encoder used in test suite; B64.O = B64 output */
/* B64.W    base64 encoder for "web-safe base64" (or "base64url") */

/* AUTHTTP  HTTP Auth Digest (RfCs 2617 and 2069), HA2 simplified */
/* DIGEST   obsolete SASL Digest-MD5 (RfC 2831), based on AUTHTTP */
/* NOMCOM   Select M random candidates of N volunteers,  RfC 3797 */
/* MF2B32   B32 encoded MD5 of media feature set,        RfC 2938 */

/* APR1     BSD $1$ / Apache $apr1$ .htpasswd MD5 crypt() variant */
/* APR1.S   pseudo-random SALT for APR1(), given as APR1.B() B64  */
/* APR1.B   right to left B64 variant used by APR1() like crypt() */
/* PHPASS   portable "private" PasswordHash.php, a.k.a. PHPass.pm */

/* EX1910   used to check the very slow HISTORIC RfC 1910 example */
/* UUID.3   RfC 4122 UUID version 3 (DNS, URL, OID, X.500 names)  */

/* OTP      one time password (hex.), RfCs 2243, 2289, and 2444   */
/* OTP.6    one time password (six words encoder used by clients) */
/* OTP.3    one time password (six words decoder used by servers) */
/* OTP.2    used by OTP.6 and OTP.3 (six words parity)            */
/* OTP.1    used by OTP.6 and OTP.3 (six words dictionary)        */
/* OTP.0    used by OTP.6 and in test suite                       */

/* CRAM     Challenge-Response Authentication Mechanism, RfC 2195 */
/* HMAC     Keyed-Hashing for Message Authentication,    RfC 2104 */

/* MD5      Message Digest (RfC 1321)                             */
/* MD5.1    MD5 round 1 used by MD5                               */
/* MD5.2    MD5 round 2 used by MD5                               */
/* MD5.3    MD5 round 3 used by MD5                               */
/* MD5.4    MD5 round 4 used by MD5                               */
/* MD5..    MD5 round 1..4 common part                            */

/* -------------------------------------------------------------- */
/* REXX MD5 test suite  : number of test cases and comment        */
/* RfC 4648 base64      : 7,  edit "if 0 then" to debug B64 stuff */
/* RfC 3548 base64      : 6,  B64 examples in RfC 2440 (= 3548),  */
/* RfC 1864 base64      : 2,  B64 examples in RfC 1864            */
/* RfC 2195 base64      : 4,  B64 examples in RfC 2195            */
/* web-safe base64      : 2,  recycled RfC 2440 example for 4648  */
/* bad YR== base64      : 1,  RfC 4648 implementation report test */

/* RfC 1321 MD5         : 7, simple interface MD5( string )       */
/* RfC 1939 APOP        : 1, tests MD5( msgid || pass )           */
/* RfC 2384 POP URL     : 1, reflects value in erratum 2943       */
/* USCYBERCOM           : 1, easter egg in USCYBERCOM logo        */
/* NIST NSRL KAT        : 3, <http://www.nsrl.nist.gov/testdata/> */

/* RfC 2104 HMAC MD5    : 3, simple interface HMAC( key, string ) */
/* RfC 2202 HMAC MD5    : 4, test cases 4..7 (like RfC 2104 1..3) */

/* RfC 2195 AUTH        : 1, simple test HMAC( pass, challenge )  */
/* RfC 2195 CRAM MD5    : 1, tests CRAM( user, pass, challenge )  */
/* I-D 2195bis          : 4, ditto draft-ietf-sasl-crammd5        */

/* MD5 collision        : 2, 6 of 1024 bits modified (2004-08-19) */
/* Message collision    : 2, 2 of  512 bits modified (2010-12-24) */
/* APR1                 : 8, apache .htpasswd MD5 crypt() variant */
/* PHPASS               : 2, PHP MD5 (disabled, doesn't work yet) */
/* RfC 1910 maplesyrup  : 1, edit "if 0 then" for slow 1024*1024  */

/* RfC 2289 six words   : 9, edit "if 0 then" to debug six words  */
/* RfC 2289 OTP MD5     : 9, OTP( pass, seed, count ) and OTP.6() */
/* RfC 2243 OTP MD5 ext : 2, edit "if 0 then" for slow count 499  */
/* RfC 2444 OTP MD5 ext : 4, B64 tests of OTP( pass, seed, sequ ) */

/* RfC 2938 features    : 3, three ok., known 4th erratum removed */
/* RfC 2777 NomCom      : 1, "10 of 25", limit 255, test fraction */
/* RfC 3797 NomCom      : 6, "10+1 of 25" plus  5 IETF 2007..2011 */
/* RfC 4122 UUID (v=3)  : 3, three ok., known 4th erratum removed */

/* RfC 2069 http 1.0    : 1, fixed value for RfC 2069 erratum 749 */
/* RfC 2617 http 1.1    : 1, MD5 digest (qop=auth)                */
/* RfC 2831 Digest-MD5  : 4, response + rspauth IMAP + ACAP       */
/* RfC 4643 NNTPAUTH    : 2, response + rspauth NNTP (auth-conf)  */
/* RfC 5034 Digest-MD5  : 4, response + rspauth POP3              */
/* RfC 5090 RADIUS      : 4, response + rspauth RADIUS            */
/* I-D.smith-sipping    : 6, draft smith-sipping-auth-examples-01 */
/*                          3.1 qop missing => RfC 2069 fallback  */
/*                          3.2 qop=auth,     alg missing => MD5  */
/*                          3.3 qop=auth,     alg=MD5             */
/*                          3.4 qop=auth,     alg=MD5-sess (2617) */
/*                          3.5 qop=auth-int, alg=MD5             */
/*                          3.6 qop=auth-int, alg=MD5-sess (2617) */
/* RfC 2831 Digest-MD5  : 4, modified for RfC 2617 erratum        */
/* RfC 4643 NNTPAUTH    : 2, modified for RfC 2617 erratum        */
/* RfC 5034 Digest-MD5  : 2, modified for RfC 2617 erratum        */

   signal on novalue
   BAD = 0           ;  VERSION = 2.1

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   if 1 then do                  /* optional base64 sanity tests: */
      X = ''         ;  Y = ''         /* RfC 4648 1st example    */
      BAD = BAD + TEST( B64.O( X ), Y, '4648 encoded empty base64' )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 decoded empty base64' )

      X = 'f'        ;  Y = 'Zg=='     /* RfC 4648 2nd example    */
      BAD = BAD + TEST( B64.O( X ), Y, '4648 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 decoded base64' Y )

      X = 'fo'       ;  Y = 'Zm8='     /* RfC 4648 3rd example    */
      BAD = BAD + TEST( B64.O( X ), Y, '4648 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 decoded base64' Y )

      X = 'foo'      ;  Y = 'Zm9v'     /* RfC 4648 4th example    */
      BAD = BAD + TEST( B64.O( X ), Y, '4648 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 decoded base64' Y )

      X = 'foob'     ;  Y = 'Zm9vYg==' /* RfC 4648 5th example    */
      BAD = BAD + TEST( B64.O( X ), Y, '4648 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 decoded base64' Y )

      X = 'fooba'    ;  Y = 'Zm9vYmE=' /* RfC 4648 6th example    */
      BAD = BAD + TEST( B64.O( X ), Y, '4648 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 decoded base64' Y )

      X = 'foobar'   ;  Y = 'Zm9vYmFy' /* RfC 4648 7th example    */
      BAD = BAD + TEST( B64.O( X ), Y, '4648 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 decoded base64' Y )

      K = '14fb9c03d97e'         /* RfC 3548 / 2440 (1st example) */
      Y = 'FPucA9l+'             ;  X = x2c( K )   ;  K = '0x' || K
      BAD = BAD + TEST( B64.O( X ), Y, '3548 encoded base64' K )
      BAD = BAD + TEST( B64.I( Y ), X, '3548 decoded base64' K )

      K = '14fb9c03d9'           /* RfC 3548 / 2440 (2nd example) */
      Y = 'FPucA9k='             ;  X = x2c( K )   ;  K = '0x' || K
      BAD = BAD + TEST( B64.O( X ), Y, '3548 encoded base64' K )
      BAD = BAD + TEST( B64.I( Y ), X, '3548 decoded base64' K )

      K = '14fb9c03'             /* RfC 3548 / 2440 (3rd example) */
      Y = 'FPucAw=='             ;  X = x2c( K )   ;  K = '0x' || K
      BAD = BAD + TEST( B64.O( X ), Y, '3548 encoded base64' K )
      BAD = BAD + TEST( B64.I( Y ), X, '3548 decoded base64' K )

      X = 'Check Integrity!'     ;  Y = 'Q2hlY2sgSW50ZWdyaXR5IQ=='
      BAD = BAD + TEST( B64.O( X ), Y, '1864 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '1864 decoded base64' X )

      X = '<1896.697170952@postoffice.reston.mci.net>'
      Y = 'PDE4OTYuNjk3MTcwOTUyQHBvc3RvZmZpY2UucmVzdG9uLm1jaS5uZXQ+'
      BAD = BAD + TEST( B64.O( X ), Y, '2195 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '2195 decoded base64' X )

      X = 'tim b913a602c7eda7a495b4e6e7334d3890'
      Y = 'dGltIGI5MTNhNjAyYzdlZGE3YTQ5NWI0ZTZlNzMzNGQzODkw'
      BAD = BAD + TEST( B64.O( X ), Y, '2195 encoded base64' X )
      BAD = BAD + TEST( B64.I( Y ), X, '2195 decoded base64' X )

      K = '14fb9c03d97e'         /* modified RfC 3548 "web-safe": */
      Y = 'FPucA9l-'             ;  X = x2c( K )   ;  K = '0x' || K
      BAD = BAD + TEST( B64.W( X ), Y, 'encoded web-safe base64' K )
      BAD = BAD + TEST( B64.I( Y ), X, 'decoded web-safe base64' K )

      X = 'a'                    /* a bad encoding of 'a': 'YQ==' */
      Y = 'YR=='                 ;  K = 'vs. canonical' B64.O( X )
      BAD = BAD + TEST( B64.I( Y ), X, '4648 test of base64' Y K   )
   end

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   X = ''                        /* RfC 1321 test suite example 1 */
   Y = 'd41d8cd98f00b204e9800998ecf8427e'
   BAD = BAD + TEST( MD5( X ), Y, '1321 empty' )

   X = 'a'                       /* RfC 1321 test suite example 2 */
   Y = '0cc175b9c0f1b6a831c399e269772661'
   BAD = BAD + TEST( MD5( X ), Y, '1321' X )

   X = 'abc'                     /* RfC 1321 test suite example 3 */
   Y = '900150983cd24fb0d6963f7d28e17f72'
   BAD = BAD + TEST( MD5( X ), Y, '1321' X )

   X = 'message digest'          /* RfC 1321 test suite example 4 */
   Y = 'f96b697d7cb7938d525a2f31aaf161d0'
   BAD = BAD + TEST( MD5( X ), Y, '1321' X )

   X = 'abcdefghijklmnopqrstuvwxyz'
   Y = 'c3fcd3d76192e4007dfb496cca67e13b'
   BAD = BAD + TEST( MD5( X ), Y, '1321' X )

   X = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
   X = X || '0123456789'         /* RfC 1321 test suite example 6 */
   Y = 'd174ab98d277d9f5a5611c2c9f419d9f'
   BAD = BAD + TEST( MD5( X ), Y, '1321 AB..Zab..z01..9' )

   X = copies( '1234567890', 8 ) /* RfC 1321 test suite example 7 */
   Y = '57edf4a22be3c955ac49da2e2107b67a'
   BAD = BAD + TEST( MD5( X ), Y, '1321 8 * 1234567890' )

   X = MD5( '123', '' ) ;  X = MD5( copies( '4567890123', 7 ), X )
   X = MD5( '4567890', X ) ;  X = MD5( /**/, X )
   BAD = BAD + TEST( X, Y, '1321 8 * 1234567890 streaming input' )

   X = '<1896.697170952@dbc.mtview.ca.us>tanstaaf'
   Y = 'c4c9334bac560ecc979e58001b3e22fb'
   BAD = BAD + TEST( MD5( X ), Y, '1939 APOP' )

   X = '<1896.697170952@mail.eudora.com>secret'
   Y = '8f5de26536bc248ba202a9ca612e71bd'
   BAD = BAD + TEST( MD5( X ), Y, '2384 APOP (erratum 2943)' )

   X = MD5( '', '' )             /* get a new "empty" MD5 context */
   X = MD5( 'USCYBERCOM plans, coordinates, integrates, synchr', X )
   X = MD5( 'onizes and conducts activities to: direct the ope', X )
   X = MD5( 'rations and defense of specified Department of De', X )
   X = MD5( 'fense information networks and; prepare to, and w', X )
   X = MD5( 'hen directed, conduct full spectrum military cybe', X )
   X = MD5( 'rspace operations in order to enable actions in a', X )
   X = MD5( 'll domains, ensure US/Allied freedom of action in', X )
   X = MD5( ' cyberspace and deny the same to our adversaries.', X )
   Y = '9ec4c12949a4f31474f299058ce2b22a'
   K = 'USCYBERCOM mission statement (MD5 in logo)'
   BAD = BAD + TEST( MD5( /* finalize MD5 context */, X ), Y, K )

   X = 'abc'                     /* www.nsrl.nist.gov/testdata/   */
   Y = '900150983cd24fb0d6963f7d28e17f72'
   BAD = BAD + TEST( MD5( X ), Y, 'NIST NSRL Test Data (1 of 3)' )

   X = 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'
   Y = '8215ef0796a20bcaaae116d3876c664a'
   BAD = BAD + TEST( MD5( X ), Y, 'NIST NSRL Test Data (2 of 3)' )

   K = copies( 'a', 1000 )       /* split 1,000,000 lower case A: */
   X = MD5( K, '' )              /* initial MD5 context: 1000 'a' */
   do 999
      X = MD5( K, X )            /* update context: 1000*1000 'a' */
   end
   X = MD5( /**/, X )            /* finalize MD5 of given context */
   Y = '7707d6ae4e027c70eea2a935c2296f21'
   BAD = BAD + TEST(      X  , Y, 'NIST NSRL Test Data (3 of 3)' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   K = copies( '0B'x, 16 )       /* RfC 2104 / RFC 2202 example 1 */
   X = 'Hi There'
   Y = '9294727a3638bb1c13f48ef8158bfc9d'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2104' X )

   K = 'Jefe'                    /* RfC 2104 / RFC 2202 example 2 */
   X = 'what do ya want for nothing?'
   Y = '750c783e6ab0b503eaa86e310a5db738'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2104' X )

   K = copies( 'AA'x, 16 )       /* RfC 2104 / RFC 2202 example 3 */
   X = copies( 'DD'x, 50 )
   Y = '56be34521d144c88dbb8c733f0e8b3f6'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2104 16 * AA, 50 * DD' )

   K = '0102030405060708090a0b0c0d0e0f10111213141516171819'x
   X = copies( 'CD'x, 50 )       /* RfC 2202 test suite example 4 */
   Y = '697eaf0aca3a3aea3a75164746ffaa79'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2202 HMAC-MD5 test 4' )

   K = copies( '0C'x, 16 )       /* RfC 2202 test suite example 5 */
   X = 'Test With Truncation'    /* (trunc. to 96 bits not shown) */
   Y = '56461ef2342edc00f9bab995690efd4c'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2202 HMAC-MD5 test 5' )

   K = copies( 'AA'x, 80 )       /* RfC 2202 test suite example 6 */
   X = 'Test Using Larger Than Block-Size Key - Hash Key First'
   Y = '6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2202 HMAC-MD5 test 6' )

   K = copies( 'AA'x, 80 )       /* RfC 2202 test suite example 7 */
   X = 'Test Using Larger Than Block-Size Key'
   X = X 'and Larger Than One Block-Size Data'
   Y = '6f630fad67cda0ee1fb1f562db3aa53e'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2202 HMAC-MD5 test 7' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   K = 'tanstaaftanstaaf'        /* RfC 2195 AUTH CRAM-MD5 detail */
   X = '<1896.697170952@postoffice.reston.mci.net>'
   Y = 'b913a602c7eda7a495b4e6e7334d3890'
   BAD = BAD + TEST( HMAC( K, X ), Y, '2195 CRAM-MD5 details' )

   USER = 'tim'                  /* RfC 2195 AUTH CRAM-MD5 (same  */
   PASS = 'tanstaaftanstaaf'     /* example recycled in RfC 2595) */
   X = '+ PDE4OTYuNjk3MTcwOTUyQHBvc3RvZmZpY2UucmVzdG9uLm1jaS5uZXQ+'
   Y = 'dGltIGI5MTNhNjAyYzdlZGE3YTQ5NWI0ZTZlNzMzNGQzODkw'
   BAD = BAD + TEST( CRAM( USER, PASS, X ), Y, '2195 CRAM-MD5 B64' )

   USER = 'joe'                  /* 2195bis A.1.1                 */
   PASS = 'tanstaaftanstaaf'
   X = '+ PDE4OTYuNjk3MTcwOTUyQHBvc3RvZmZpY2UuZXhhbXBsZS5uZXQ+'
   Y = 'am9lIDNkYmM4OGYwNjI0Nzc2YTczN2IzOTA5M2Y2ZWI2NDI3'
   BAD = BAD + TEST( CRAM( USER, PASS, X ), Y, 'I-D 2195bis A.1.1' )

   USER = 'Ali Baba'             /* 2195bis A.1.2                 */
   PASS = 'Open, Sesame'
   X = B64.O( '<68451038525716401353.0@localhost>' )
   Y = B64.O( USER '6fa32b6e768f073132588e3418e00f71' )
   BAD = BAD + TEST( CRAM( USER, PASS, X ), Y, 'I-D 2195bis A.1.2' )

   USER = 'Aladdin' || x2c( 'C2AE' )
   PASS = 'Open, Sesame'         /* 2195bis A.1.3, UTF-8 SASLprep */
   X = B64.O( '<92230559549732219941.0@localhost>' )
   Y = B64.O( USER '9950ea407844a71e2f0cd3284cbd912d' )
   BAD = BAD + TEST( CRAM( USER, PASS, X ), Y, 'I-D 2195bis A.1.3' )

   USER = 'joe'                  /* 2195bis A.2.1                 */
   PASS = 'tanstaaftanstaaf'
   X = B64.O( '<2262304172.6455022@gw2.gestalt.entity.net>' )
   Y = B64.O( USER '2aa383bf320a941d8209a7001ef6aeb6' )
   BAD = BAD + TEST( CRAM( USER, PASS, X ), Y, 'I-D 2195bis A.2.1' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   X =   'd1 31 dd 02   c5 e6 ee c4   69 3d 9a 06   98 af  f9 5c'
   X = X '2f ca b5 87   12 46 7e ab   40 04 58 3e   b8 fb  7f 89'
   X = X '55 ad 34 06   09 f4 b3 02   83 e4 88 83   25 71  41 5a'
   X = X '08 51 25 e8   f7 cd c9 9f   d9 1d bd f2   80 37  3c 5b'
   X = X 'd8 82 3e 31   56 34 8f 5b   ae 6d ac d4   36 c9  19 c6'
   X = X 'dd 53 e2 b4   87 da 03 fd   02 39 63 06   d2 48  cd a0'
   X = X 'e9 9f 33 42   0f 57 7e e8   ce 54 b6 70   80 a8  0d 1e'
   X = X 'c6 98 21 bc   b6 a8 83 93   96 f9 65 2b   6f f7  2a 70'
   C = x2c( X )
   Y = '79054025255fb1a26e4bc422aef54eb4'
   TXT = 'MD5 collision test, 6 of 1024 bits modified'
   BAD = BAD + TEST( MD5( C ), Y, TXT '- see also at URL:' )

   X =   '00 00 00 00   00 00 00 00   00 00 00 00   00 00  00 00'
   X = X '00 00 00  80  00 00 00 00   00 00 00 00   00 00  00 00'
   X = X '00 00 00 00   00 00 00 00   00 00 00 00   00  80 00 00'
   X = X '00 00 00 00   00 00 00 00   00 00 00  80  00 00  00 00'
   X = X '00 00 00 00   00 00 00 00   00 00 00 00   00 00  00 00'
   X = X '00 00 00  80  00 00 00 00   00 00 00 00   00 00  00 00'
   X = X '00 00 00 00   00 00 00 00   00 00 00 00   00  80 00 00'
   X = X '00 00 00 00   00 00 00 00   00 00 00  80  00 00  00 00'
   C = bitxor( C, x2c( X ))      /* toggle 6 bits of 1024 =16*8*8 */
   TXT = 'www.rtfm.com/movabletype/archives/2004_08.html#001055'
   BAD = BAD + TEST( MD5( C ), Y, '<http://' || TXT || '>' )

   X =   '0e 30 65 61   55 9a  a7 87   d0 0b c6 f7   0b bd fe 34'
   X = X '04 cf 03 65   9e 70  4f 85   34 c0 0f fb   65 9c 4c 87'
   X = X '40 cc 94 2f   eb 2d  a1 15   a3 f4 15 5c   bb 86 07 49'
   X = X '73 86 65 6d   7d 1f  34 a4   20 59 d7 8f   5a 8d d1 ef'
   C = x2c( X )
   Y = 'cee9a457e790cf20d4bdaa6d69f01e41'
   TXT = 'MD5 message collision, 2 of 512 bits modified'
   BAD = BAD + TEST( MD5( C ), Y, TXT '(2010), see URL:' )

   X =   '00 00 00 00   00 00  00 00   00 00 00 00   00 00 00 00'
   X = X '00 00 00 00   00  04 00 00   00 00 00 00   00 00 00 00'
   X = X '00 00 00 00   00 00  00 00   00 00 00  80  00 00 00 00'
   X = X '00 00 00 00   00 00  00 00   00 00 00 00   00 00 00 00'
   C = bitxor( C, x2c( X ))      /* toggle 2 bits of 512 = 16*8*4 */
   TXT = 'eprint.iacr.org/2010/643.pdf> (Tao Xie, Dengguo Feng)'
   BAD = BAD + TEST( MD5( C ), Y, '<http://' || TXT )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   PASS   = 'password'           /* found in the `openssl passwd` */
   MAGIC  = '$1$'                /* examples for option -1 (BSD)  */
   SALT   = 'xxxxxxxx'
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$UYCIxa628.9qXjpQCjM4a.'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 1 of 8:' Y )

   PASS   = 'password'           /* found in the `openssl passwd` */
   MAGIC  = '$apr1$'             /* examples for option -apr1     */
   SALT   = 'xxxxxxxx'
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$dxHfLAsjHkDRmG83UXe8K0'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 2 of 8:' Y )

   PASS   = 'password'           /* found in John's sample hashes */
   MAGIC  = '$1$'                /* on http://openwall.info/wiki/ */
   SALT   = 'O3JMY.Tw'
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$AdLnLjQ/5jXF9.MTp3gHv/'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 3 of 8:' Y )

   PASS   = 'passphrase'         /* found in cpan.org MD5Crypt.pm */
   MAGIC  = '$1$'                /* - the author "zefram" states  */
   SALT   = 'Vd3f8aG6'           /* that MD5 crypt() is "baroque" */
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$GcsdF4YCXb0PM2UmXjIoI1'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 4 of 8:' Y )

   PASS   = 'GNU libc manual'    /* GNU is Not Unix (recursively) */
   MAGIC  = '$1$'
   SALT   = '/iSaq7rB'
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$EoUw5jJPPvAPECNaaWzMK/'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 5 of 8:' Y )

   PASS   = 'rasmuslerdorf'      /* PHP CRYPT_MD5 crypt() example */
   MAGIC  = '$1$'
   SALT   = 'rasmusle'
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$rISCgZzpwk3UhDidwXvin0'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 6 of 8:' Y )

   PASS   = 'password'           /* Python passlib.hash.md5_crypt */
   MAGIC  = '$1$'
   SALT   = '3azHgidD'
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$SrJPt7B.9rekpmwJwtON31'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 7 of 8:' Y )

   PASS   = '0123456789-0123456789-0123456789-'
   MAGIC  = '$apr1$'             /* length 33 test, verified with */
   SALT   = 'dz1.....'           /* htpasswd and `openssl passwd` */
   HASH   = APR1( PASS, MAGIC, SALT )
   Y      = MAGIC || SALT || '$g7vOevi4RVgXbTai5Bo.g/'
   BAD = BAD + TEST( HASH, Y, 'APR1 test 8 of 8:' Y )

   if 0  then  do                /** disabled, does not yet work **/
      PASS   = 'test12345'       /* PHP portable PasswordHash.php */
      MAGIC  = '$P$'             /* published by "Solar Designer" */
      COST   = 11                /* 11th APR1.B() is expected '9' */
      SALT   = 'IQRaTwmf'        /* 8 char.s SALT following $P$9  */
      HASH   = PHPASS( PASS, MAGIC, COST, SALT )
      Y      = left( APR1.B( d2c( COST )), 1 )
      Y      = MAGIC || Y || SALT || 'eRo7ud9Fh4E2PdI0S3r.L0'
      BAD = BAD + TEST( HASH, Y, 'PasswordHash.php:' Y )

      PASS   = 'passphrase'      /* in cpan.org/~zefram PHPass.pm */
      MAGIC  = '$P$'             /*  based on Solar Designer code */
      COST   = 10                /* 10th APR1.B() is expected '8' */
      SALT   = 'NaClNaCl'        /* 8 char.s SALT following $P$8  */
      HASH   = PHPASS( PASS, MAGIC, COST, SALT )
      Y      = left( APR1.B( d2c( COST )), 1 )
      Y      = MAGIC || Y || SALT || 'ObRxTm/.EiiYN02xUeAQs/'
      BAD = BAD + TEST( HASH, Y, 'ditto, PHPass.pm:' Y )

      PASS   = 'password'        /* Python example found in       */
      MAGIC  = '$P$'             /* code.google.com/p/passlib     */
      COST   = 10
      SALT   = 'ohUJ.1sd'
      HASH   = PHPASS( PASS, MAGIC, COST, SALT )
      Y      = left( APR1.B( d2c( COST )), 1 )
      Y      = MAGIC || Y || SALT || 'Fw09/bMaAQPTGDNi2BIUt1'
      BAD = BAD + TEST( HASH, Y, 'ditto, PHPass.pm:' Y )
   end                           /* ----------------------------- */

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   if 0 then do                  /* disable slow RfC 1910 example */
      X = EX1910( 'maplesyrup', x2c( d2x( 2, 24 )))
      Y = '526f5eed9fcce26f8964c2930787d82b'
      BAD = BAD + TEST( X, Y, '1910 maplesyrup' )
   end

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   if 0 then do                  /* RfC 2289 Six-word parity test */
      X = '85c43ee03857765b'     /* lower case hex. and no spaces */
      Y = 'FOWL KID MASH DEAD DUAL OAF'
      BAD = BAD + TEST( OTP.0( X ), Y, '2289 encoded 6 words' X )
      BAD = BAD + TEST( OTP.3( Y ), X, '2289 decoded 6 words' X )
      X = ''                     /* expect empty for parity error */
      Y = 'FOWL KID MASH DEAD DUAL NUT'
      BAD = BAD + TEST( OTP.3( Y ), X, '2289 parity error in' Y )
      Y = 'FOWL KID MASH DEAD DUAL O'
      BAD = BAD + TEST( OTP.3( Y ), X, '2289 parity error in' Y )
      Y = 'FOWL KID MASH DEAD DUAL OAK'
      BAD = BAD + TEST( OTP.3( Y ), X, '2289 parity error in' Y )

      PASS = 'Too_short'         /* RfC 2289 invalid arguments    */
      SEED = 'iamvalid'          /* length of PASS phrase < 10    */
      RFC = '2289 verify' PASS SEED
      BAD = BAD + TEST( OTP.6( PASS, SEED, 1 ), '', RFC )

      PASS = 'A_Valid_Pass_Phrase'
      SEED = 'Length_Okay'       /* SEED must be alphanumeric     */
      RFC = '2289 verify' PASS SEED
      BAD = BAD + TEST( OTP.6( PASS, SEED, 1 ), '', RFC )
      SEED = 'LengthOfSeventeen' /* SEED length 1..16 characters  */
      RFC = '2289 verify' PASS SEED
      BAD = BAD + TEST( OTP.6( PASS, SEED, 1 ), '', RFC )
      SEED = 'A Seed'            /* SEED must not contain spaces  */
      RFC = '2289 verify' PASS SEED
      BAD = BAD + TEST( OTP.6( PASS, SEED, 1 ), '', RFC )
   end

   PASS = 'This is a test.'      /* RfC 2289 test 1..3 hex:/word: */
   SEED = 'TeSt'
   X = 0                         /* RfC 2289 test 1..3, 1st X= 0  */
   Y = '9e876134d90499dd'        /* lower case hex. and no spaces */
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 1 hex:' || Y )
   Y = 'INCH SEA ANNE LONG AHEM TOUR'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )
   X = 1                         /* RfC 2289 test 1..3, 2nd X= 1  */
   Y = '7965e05436f5029f'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 2 hex:' || Y )
   Y = 'EASE OIL FUM CURE AWRY AVIS'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )
   X = 99                        /* RfC 2289 test 1..3, 3rd X=99  */
   Y = '50fe1962c4965880'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 3 hex:' || Y )
   Y = 'BAIL TUFT BITS GANG CHEF THY'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )

   PASS = 'AbCdEfGhIjK'          /* RfC 2289 test 4..6 hex:/word: */
   SEED = 'alpha1'
   X = 0                         /* RfC 2289 test 4..6, 1st X= 0  */
   Y = '87066dd9644bf206'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 4 hex:' || Y )
   Y = 'FULL PEW DOWN ONCE MORT ARC'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )
   X = 1                         /* RfC 2289 test 4..6, 2nd X= 1  */
   Y = '7cd34c1040add14b'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 5 hex:' || Y )
   Y = 'FACT HOOF AT FIST SITE KENT'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )
   X = 99                        /* RfC 2289 test 4..6, 3rd X=99  */
   Y = '5aa37a81f212146c'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 6 hex:' || Y )
   Y = 'BODE HOP JAKE STOW JUT RAP'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )

   PASS = "OTP's are good"       /* RfC 2289 test 7..9 hex:/word: */
   SEED = 'correct'
   X = 0                         /* RfC 2289 test 7..9, 1st X= 0  */
   Y = 'f205753943de4cf9'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 7 hex:' || Y )
   Y = 'ULAN NEW ARMY FUSE SUIT EYED'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )
   X = 1                         /* RfC 2289 test 7..9, 2nd X= 1  */
   Y = 'ddcdac956f234937'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 8 hex:' || Y )
   Y = 'SKIM CULT LOB SLAM POE HOWL'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )
   X = 99                        /* RfC 2289 test 7..9, 3rd X=99  */
   Y = 'b203e28fa525be47'
   BAD = BAD + TEST( OTP(   PASS, SEED, X ), Y, '2289 9 hex:' || Y )
   Y = 'LONG IVY JULY AJAR BOND LEE'
   BAD = BAD + TEST( OTP.6( PASS, SEED, X ), Y, '2289  word:' || Y )

   if 1 then do                  /* RfC 2243 example, challenge   */
      PASS = 'This is a test.'   /* was 'otp-md5 499 ke1234 ext'  */
      SEED = 'ke1234'
      OLDX = 499                 /* X = 499 MD5 iterations (slow) */
      NEWS = 'ke1235'
      NEWX = 499
      Y = 'init-hex:5bf075d9959d036f'
      Y = Y || ':md5' NEWX NEWS || ':3712dcb4aa5316c1'
      INIT = OTP(   PASS, SEED, OLDX ) || ':md5' NEWX NEWS || ':'
      INIT = 'init-hex:' || INIT || OTP(   PASS, NEWS, NEWX )
      BAD = BAD + TEST( INIT, Y, '2243' Y )
      Y = 'init-word:BOND FOGY DRAB NE RISE MART'
      Y = Y || ':md5' NEWX NEWS || ':RED HERD NOW BEAN PA BURG'
      INIT = OTP.6( PASS, SEED, OLDX ) || ':md5' NEWX NEWS || ':'
      INIT = 'init-word:' || INIT || OTP.6( PASS, NEWS, NEWX )
      BAD = BAD + TEST( INIT, Y, '2243' left( Y, 53 ) '..' )
   end

   X = 'otp-md5 123 ke1234 ext'  /* RfC 2444 OTP IMAP challenge   */
   Y = 'b3RwLW1kNSAxMjMga2UxMjM0IGV4dA=='
   BAD = BAD + TEST( B64.O( X ), Y, '2444 encoded base64' X )
   BAD = BAD + TEST( B64.I( Y ), X, '2444 decoded base64' X )
   parse var X . SEQU SEED .
   PASS = 'this is a test'
   X = 'hex:' || OTP( PASS, SEED, SEQU )
   Y = 'aGV4OjExZDRjMTQ3ZTIyN2MxZjE='
   BAD = BAD + TEST( B64.O( X ), Y, '2444 encoded base64' X )
   BAD = BAD + TEST( B64.I( Y ), X, '2444 decoded base64' X )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   X = '(& (pix-x<=200) (pix-y<=150) )'
   Y = '(h.SBB5REAOMHC09CP2GM4V07PQP0)'
   BAD = BAD + TEST( MF2B32( X ), Y, '2938' Y )

   Y = x2c( 0D0A )               /* RfC 2938 3rd example (ch. 4)  */
   X =   '(& (image-file-structure=TIFF-minimal)             ' Y
   X = X '   (MRC-mode=0)                                    ' Y
   X = X '   (color=Binary)                                  ' Y
   X = X '   (image-coding=MH) (MRC-mode=0)                  ' Y
   X = X '   (| (& (dpi=204) (dpi-xyratio=[204/98,204/196]) )' Y
   X = X '      (& (dpi=200) (dpi-xyratio=[200/100,1]) ) )   ' Y
   X = X '   (size-x<=2150/254)                              ' Y
   X = X '   (paper-size=A4)                                 ' Y
   X = X '   (ua-media=stationery) )                         ' Y
   Y = '(h.MSB955PVIRT1QOHET9AJT5JM3O)'
   BAD = BAD + TEST( MF2B32( X ), Y, '2938' Y )

   Y = x2c( 0D0A )               /* RfC 2938 4th example (ch. 4)  */
   X =   '(& (image-coding=JPEG)                  ' Y
   X = X '   (image-coding-constraint=JPEG-T4E)   ' Y
   X = X '   (color-space=CIELAB)                 ' Y
   X = X '   (color-illuminant=D50)               ' Y
   X = X '   (CIELAB-L-min>=0)                    ' Y
   X = X '   (CIELAB-L-max<=100)                  ' Y
   X = X '   (dpi=[100,200,300]) (dpi-xyratio=1) )' Y
   Y = '(h.QVSEM8V2LMJ8VOR7V682J7079O)'
   BAD = BAD + TEST( MF2B32( X ), Y, '2938' Y )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   S.1 = '9, 18, 26, 34, 41, 45' /* RfC 2777: six lottery numbers */
   S.2 = '2, 5, 12, 8, 10'       /* RfC 2777: five winning horses */
   S.3 = '9319'                  /* RfC 2777: whole number input  */
   S.4 = '13.6875'               /* RfC 2777: 13 11/16 as 13.6875 */
   X = NOMCOM( -25, 10, S.1, S.2, S.3, S.4 )
   Y = '12 6 8 3 2 24 11 19 15 22'
   BAD = BAD + TEST( X, Y, '2777 NomCom' Y )

   S.1 = '9319'                  /* 1st "raw" random input string */
   S.2 = '2, 5, 12, 8, 10'       /* 2nd "raw" input (CSV numbers) */
   S.3 = '9, 18, 26, 34, 41, 45' /* 3rd "raw" input (CSV numbers) */
   X = NOMCOM( 25, 11, S.1, S.2, S.3 )
   Y = '17 7 2 16 25 23 8 24 19 13 22'
   BAD = BAD + TEST( X, Y, '3797 NomCom' Y )

   S.1 = '9 13 15 31 48 3 6'     ;  S.2 = '61636147'
   S.4 = '7 39 41 48 53 21'      ;  S.3 = '95231775'
   X = NOMCOM( 108, 20, S.1, S.2, S.3, S.4 )
   Y =   '57 12 105 5 11 18 99 93 43 102'
   Y = Y '40 14 84 28 79 60 72 75 78 89'
   BAD = BAD + TEST( X, Y, '3797 NomCom 2007' )

   S.1 = '02 20 25 37 39 05 08'  ;  S.2 = '42831475'
   S.4 = '21 25 26 50 51 22'     ;  S.3 = '14964684'
   X = NOMCOM( 99, 15, S.1, S.2, S.3, S.4 )
   Y = '91 38 36 94 52 33 84 1 53 34 86 29 81 78 89'
   BAD = BAD + TEST( X, Y, '3797 NomCom 2008' )

   S.1 = '5 8 10 29 39 41 15'    ;  S.2 = '05260357'
   S.4 = '20 29 35 45 53 41'     ;  S.3 = '81433717'
   X = NOMCOM( 93, 15, S.1, S.2, S.3, S.4 )
   Y = '43 83 27 15 10 26 88 60 31 28 16 84 54 20 72'
   BAD = BAD + TEST( X, Y, '3797 NomCom 2009' )

   S.1 = '01 08 09 14 17 20 23'  ;  S.2 = '76998828'
   S.4 = '20 21 23 38 42 6'      ;  S.3 = '79622755'
   X = NOMCOM( 101, 15, S.1, S.2, S.3, S.4 )
   Y = '87 25 14 46 79 31 75 91 47 23 16 60 92 89 19'
   BAD = BAD + TEST( X, Y, '3797 NomCom 2010' )

   S.1 = '02 12 23 35 39 49 44'  ;  S.2 = '43838132'
   S.4 = '06 26 33 34 39 03 04'  ;  S.3 = '43531153'
   X = NOMCOM( 120, 15, S.1, S.2, S.3, S.4 )
   Y = '118 35 100 44 84 92 1 99 108 76 58 104 54 97 90'
   BAD = BAD + TEST( X, Y, '3797 NomCom 2011' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   X = UUID.3( 'DNS', 'www.widgets.com', 'bypass RfC 4122 erratum' )
   Y = 'urn:uuid:e902893a-9d22-3c7e-a7b8-d6e313b71d9f'
   BAD = BAD + TEST( X, Y, '4122' Y )

   X = UUID.3( 'DNS', 'python.org' )
   Y = 'urn:uuid:6fa459ea-ee8a-3ca4-894e-db77e160355e'
   BAD = BAD + TEST( X, Y, '4122 UUID for python.org' )

   X = UUID.3( 'URL', 'http://www.ossp.org/' )
   Y = 'urn:uuid:02d9e6d5-9467-382e-8f9b-9300a64ac3cd'
   BAD = BAD + TEST( X, Y, '4122 UUID for http://www.ossp.org/' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   USER   = 'Mufasa'             /* RfC 2069 example (has no qop) */
   PASS   = 'CircleOfLife'       /* This is a FIXED version based */
   REALM  = 'testrealm@host.com' /* on RfC 2069 erratum 749 (NEW) */
   NONCE  = 'dcd98b7102dd2f0e8b11d0f600bfb0c093'
   URI    = '/dir/index.html'
   ALG    = 'MD5'                /* can be also omitted for 2069  */

   X = 'GET:' || URI             /* HTTP access method for 2069   */
   X = DIGEST( USER, PASS, REALM, NONCE, /**/, /**/, /**/, X, ALG )
   Y = 'e966c932a9242554e42c8ee200cec7f6'    /* OLD - expect FAIL */
   Y = '1949323746fe6a43ef61f9606e7febea'    /* NEW - expect PASS */
   BAD = BAD + TEST( X, Y, '2069 erratum 749 authorization' )

   USER   = 'Mufasa'             /* RfC 2617 qop=auth example     */
   PASS   = 'Circle Of Life'
   REALM  = 'testrealm@host.com'
   NONCE  = 'dcd98b7102dd2f0e8b11d0f600bfb0c093'
   CNONCE = '0a4f113b'
   NC     = 1
   QOP    = 'auth'
   URI    = '/dir/index.html'
   ALG    = 'md5'

   X = 'GET:' || URI             /* HTTP access method for 2617   */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '6629fae49393a05397450978507c4ef1'
   BAD = BAD + TEST( X, Y, '2617 HTTP/1.1 qop=auth' )

   USER   = 'chris'              /* RfC 2831 IMAP example         */
   PASS   = 'secret'             /* (B64 output format not shown) */
   REALM  = 'elwood.innosoft.com'
   NONCE  = 'OA6MG9tEQGm2hh'
   CNONCE = 'OA6MHXh6VqTrRk'
   NC     = 1
   QOP    = 'auth'
   URI    = 'imap/elwood.innosoft.com'
   ALG    = 'md5-sess'

   X = 'AUTHENTICATE:' || URI    /* 2831 AUTHENTICATE:digest-uri  */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'd388dad90d4bbd760a152321f2143af7'
   BAD = BAD + TEST( X, Y, '2831 IMAP example' )

   X = ':' || URI                /* 2831 rspauth for IMAP example */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'ea40f60335c427b5527b84dbabcdfffd'
   BAD = BAD + TEST( X, Y, '2831 IMAP rspauth' )

   NONCE  = 'OA9BSXrbuRhWay'     /* RfC 2831 ACAP example         */
   CNONCE = 'OA9BSuZWMSpW8m'     /* (other values as shown above) */
   URI    = 'acap/elwood.innosoft.com'

   X = 'AUTHENTICATE:' || URI    /* 2831 AUTHENTICATE:digest-uri  */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '6084c6db3fede7352c551284490fd0fc'
   BAD = BAD + TEST( X, Y, '2831 ACAP example' )

   X = ':' || URI                /* 2831 rspauth for ACAP example */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '2f0b3d7c3c2e486600ef710726aa2eae'
   BAD = BAD + TEST( X, Y, '2831 ACAP rspauth' )

   USER   = 'test'               /* NNTPAUTH example in RfC 4643  */
   PASS   = 'test'               /* (B64 encoding not shown here) */
   REALM  = 'eagle.oceana.com'
   NONCE  = 'sayAOhCEKGIdPMHC0wtleLqOIcOI2wQYIe4zzeAtuiQ='
   CNONCE = '0Y3JQV2Tg9ScDip+O1SVC0rhVg//+dnOIiGz/7CeNJ8='
   NC     = 1
   QOP    = 'auth-conf'          /* auth-conf dummy hash 32 zeros */
   URI    = 'nntp/localhost' || ':' || d2x( 0, 32 )
   ALG    = 'md5-sess'

   X = 'AUTHENTICATE:' || URI    /* NNTP AUTHENTICATE:digest-uri  */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'd43cf66cffa903f9eb0356c08a3db0f2'
   BAD = BAD + TEST( X, Y, '4643 NNTPAUTH example' )

   X = ':' || URI                /* NNTP rspauth in 283 parameter */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'de2e127e5a81cda53d97acda35cde83a'
   BAD = BAD + TEST( X, Y, '4643 NNTPAUTH rspauth' )

   USER   = 'chris'              /* RfC 5034 POP3 example         */
   PASS   = 'secret'             /* B64 input + output not shown  */
   REALM  = 'elwood.innosoft.com'
   NONCE  = 'OA6MG9tEQGm2hh'
   CNONCE = 'OA6MHXh6VqTrRk'
   NC     = 1
   QOP    = 'auth'
   URI    = 'pop/elwood.innosoft.com'
   ALG    = 'md5-sess'

   X = 'AUTHENTICATE:' || URI    /* 5034 AUTHENTICATE:digest-uri  */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'b0d56d2f054c24b62072322106468db9'
   BAD = BAD + TEST( X, Y, '5034 POP3 example' )

   X = ':' || URI                /* 5034 rspauth for POP3 example */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '0b971462cef5e8f930db9a33b02fc9a0'
   BAD = BAD + TEST( X, Y, '5034 POP3 rspauth' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   USER   = '12345678'           /* RfC 5090 fixed 4590 example 1 */
   PASS   = 'secret'
   REALM  = 'example.com'
   NONCE  = '3bada1a0'
   CNONCE = '56593a80'
   NC     = 1
   QOP    = 'auth'
   URI    = 'sip:97226491335@example.com'
   ALG    = 'md5'

   X = 'INVITE:' || URI          /* RADIUS example SIP/2.0 INVITE */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '756933f735fcd93f90a4bbdd5467f263'

   BAD = BAD + TEST( X, Y, 'RfC 5090 RADIUS INVITE' )

   X = ':' || URI                /* RADIUS Access-Accept rspauth  */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'f847de948d12285f8f4199e366f1af21'
   BAD = BAD + TEST( X, Y, 'RfC 5090 RADIUS rspauth' )

   USER   = '12345678'           /* RfC 5090 fixes 4590 example 2 */
   PASS   = 'secret'
   REALM  = 'example.com'
   NONCE  = 'a3086ac8'
   CNONCE = '56593a80'
   NC     = 1
   QOP    = 'auth'
   URI    = '/index.html'
   ALG    = 'MD5'

   X = 'GET:' || URI             /* RADIUS example HTTP/1.1 GET   */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'a4fac45c27a30f4f244c54a2e99fa117'
   BAD = BAD + TEST( X, Y, 'RfC 5090 RADIUS GET' )

   X = ':' || URI                /* RADIUS Access-Accept rspauth  */
   X = DIGEST( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '08c4e942d1d0a191de8b3aa98cd35147'
   BAD = BAD + TEST( X, Y, 'RfC 5090 RADIUS rspauth' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   USER   = 'bob'                /* RfC 3261 SIP INVITE, in draft */
   REALM  = 'biloxi.com'         /* -smith-sipping-auth-examples, */
   PASS   = 'zanzibar'           /* I-D password known to be okay */
   NONCE  = 'dcd98b7102dd2f0e8b11d0f600bfb0c093'
   CNONCE = '0a4f113b'
   NC     = 1
   URI    = 'sip:bob@biloxi.com'

   X = 'INVITE:' || URI          /* I-D.smith 3.1.2, QOP omitted: */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, /* QOP */, X )
   Y = 'bf57e4e0d0bffc0fbaedce64d59add5e'
   BAD = BAD + TEST( X, Y, 'I-D.smith-sipping-auth-examples 3.1.2' )

   QOP    = 'auth'
   X = 'INVITE:' || URI          /* I-D.smith 3.2.2 uses QOP=auth */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, /**/ )
   Y = '89eb0059246c02b2f6ee02c7961d5ea3'
   BAD = BAD + TEST( X, Y, 'I-D.smith-sipping-auth-examples 3.2.2' )

   ALG = 'MD5'                   /* I-D.smith 3.3.2 uses ALG=MD5, */
   X = 'INVITE:' || URI          /* as expected the same result   */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   BAD = BAD + TEST( X, Y, 'I-D.smith-sipping-auth-examples 3.3.2' )

   ALG = 'MD5-sess'              /* I-D.smith 3.4.2, ALG=MD5-sess */
   X = 'INVITE:' || URI          /* okay based on RfC 2617 errata */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'e4e4ea61d186d07a92c9e1f6919902e9'
   BAD = BAD + TEST( X, Y, 'I-D.smith-sipping-auth-examples 3.4.2' )

   ALG = 'MD5'                   /* I-D.smith 3.5.2, QOP=auth-int */
   QOP = 'auth-int'              /* H(entity-body) added directly */
   X = 'INVITE:' || URI || ':c1ed018b8ec4a3b170c0921f5b564e48'
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'bdbeebb2da6adb6bca02599c2239e192'
   BAD = BAD + TEST( X, Y, 'I-D.smith-sipping-auth-examples 3.5.2' )

   ALG = 'MD5-sess'              /* I-D.smith 3.6.2, QOP=auth-int */
   QOP = 'auth-int'              /* okay based on RfC 2617 errata */
   X = 'INVITE:' || URI || ':c1ed018b8ec4a3b170c0921f5b564e48'
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '91984da2d8663716e91554859c22ca70'
   BAD = BAD + TEST( X, Y, 'I-D.smith-sipping-auth-examples 3.6.2' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   USER   = 'chris'              /* compare RfC 2831 IMAP example */
   PASS   = 'secret'             /* modified for RfC 2617 erratum */
   REALM  = 'elwood.innosoft.com'
   NONCE  = 'OA6MG9tEQGm2hh'
   CNONCE = 'OA6MHXh6VqTrRk'
   NC     = 1
   QOP    = 'auth'
   URI    = 'imap/elwood.innosoft.com'
   ALG    = 'md5-sess'

   X = 'AUTHENTICATE:' || URI    /* 2831 AUTHENTICATE:digest-uri  */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '26ef1190b643a36e879673066098379c'
   BAD = BAD + TEST( X, Y, '2831 IMAP example (RfC 2617 md5-sess)' )

   X = ':' || URI                /* 2831 rspauth for IMAP example */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'c316c87a595a2cbfb4405784db016e34'
   BAD = BAD + TEST( X, Y, '2831 IMAP rspauth (RfC 2617 md5-sess)' )

   NONCE  = 'OA9BSXrbuRhWay'     /* compare RfC 2831 ACAP example */
   CNONCE = 'OA9BSuZWMSpW8m'     /* (other values as shown above) */
   URI    = 'acap/elwood.innosoft.com'

   X = 'AUTHENTICATE:' || URI    /* 2831 AUTHENTICATE:digest-uri  */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '90771dc5643a801bb9a9bcbb1ed3cd34'
   BAD = BAD + TEST( X, Y, '2831 ACAP example (RfC 2617 md5-sess)' )

   X = ':' || URI                /* 2831 rspauth for ACAP example */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'ec0700b2da00dd133bcb0c841f42d341'
   BAD = BAD + TEST( X, Y, '2831 ACAP rspauth (RfC 2617 md5-sess)' )

   USER   = 'test'               /* compare NNTPAUTH in RfC 4643, */
   PASS   = 'test'               /* modified for RfC 2617 erratum */
   REALM  = 'eagle.oceana.com'
   NONCE  = 'sayAOhCEKGIdPMHC0wtleLqOIcOI2wQYIe4zzeAtuiQ='
   CNONCE = '0Y3JQV2Tg9ScDip+O1SVC0rhVg//+dnOIiGz/7CeNJ8='
   NC     = 1
   QOP    = 'auth-conf'          /* auth-conf dummy hash 32 zeros */
   URI    = 'nntp/localhost' || ':' || d2x( 0, 32 )
   ALG    = 'md5-sess'

   X = 'AUTHENTICATE:' || URI    /* NNTP AUTHENTICATE:digest-uri  */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '41e814138958b1a0f08ef8b2dbe94ee9'
   BAD = BAD + TEST( X, Y, '4643 example using RfC 2617 md5-sess' )

   X = ':' || URI                /* NNTP rspauth in 283 parameter */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '3f4d2b034c67c0c77df650f34ece6127'
   BAD = BAD + TEST( X, Y, '4643 rspauth using RfC 2617 md5-sess' )

   USER   = 'chris'              /* compare RfC 5034 POP3 example */
   PASS   = 'secret'             /* modified for RfC 2617 erratum */
   REALM  = 'elwood.innosoft.com'
   NONCE  = 'OA6MG9tEQGm2hh'
   CNONCE = 'OA6MHXh6VqTrRk'
   NC     = 1
   QOP    = 'auth'
   URI    = 'pop/elwood.innosoft.com'
   ALG    = 'md5-sess'

   X = 'AUTHENTICATE:' || URI    /* 5034 AUTHENTICATE:digest-uri  */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = '089a19fffd2d75667e9d01583ee0fd58'
   BAD = BAD + TEST( X, Y, '5034 POP3 example (RfC 2617 md5-sess)' )

   X = ':' || URI                /* 5034 rspauth for POP3 example */
   X = AUTHTTP( USER, PASS, REALM, NONCE, CNONCE, NC, QOP, X, ALG )
   Y = 'bb52468bdaadaac994e05c3958c71a09'
   BAD = BAD + TEST( X, Y, '5034 POP3 rspauth (RfC 2617 md5-sess)' )

   /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
   say BAD 'error(s); no error expected in MD5 test suite' VERSION
   exit ( BAD <> 0 )

/* -------------------------------------------------------------- */
TEST  :  procedure               /* TEST( got, want, rfc text )   */
   parse arg GOT, WANT, RFC TEXT
   if datatype( RFC, 'w' ) then  RFC = 'RfC' RFC

   if GOT == WANT then  do       /* caller counts 1: bad, 0: okay */
      say 'okay:' RFC TEXT       ;  return 0
   end
   say 'FAIL:' RFC TEXT          ;  say 'want:' WANT
   say ' got:' GOT               ;  return 1

/* -------------------------------------------------------------- */
/* RfC 4648 base64 procedure B64.I() decodes and B64.O() encodes. */
/* B64.I() also supports "web-safe base64" input ('-_' for '+/'). */
/* B64.W() translates B64.O() to RfC 4648 "web-safe base64".      */
/* Leading or trailing input white space is ignored by B64.I().   */

B64.I :  procedure               /* (unlimited) base64 to string: */
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = translate( B64 ) || B64 || '0123456789+/'

   SRC = strip( translate( arg( 1 ), '+/', '-_' ))
   DST = ''
   do while abbrev( '==', SRC ) = 0
      parse var SRC ADD 2 SRC    /* if no B64 force REXX error 40 */
      ADD = d2x( pos( ADD, B64 ) - 1 )
      DST = DST || right( x2b( ADD ), 6, 0 )
   end
   return x2c( b2x( left( DST, length( DST ) - 2 * length( SRC ))))

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

B64.W :  return translate( B64.O( arg( 1 )), '-_', '+/' )

/* -------------------------------------------------------------- */
/* HOTP as specified in RfC 4226 is defined for HMAC_SHA1, but a  */
/* variant for HMAC_MD5 is obvious; for the maximal offset hex. F */
/* use substr( HMAC || HMAC, 1 + 15, 4 ) to get the bytes 16..20. */
/* There are no HMAC_MD5 test vectors, this function is unused.   */

HOTP:    procedure
   numeric digits 10
   parse arg SECRET, MOVING, DIGITS

   if arg( 3, 'o' )        then  DIGITS = 6
   CHECKS = ( DIGITS < 0 )       ;  DIGITS = abs( DIGITS )
   if DIGITS > 8           then  return 'max. digits 8, got' DIGITS
   if DIGITS < 6           then  return 'min. digits 6, got' DIGITS
   if length( MOVING ) > 8 then  return 'unexpected moving factor'

   HMAC.X = HMAC( SECRET, right( MOVING, 8, d2c( 0 )))
   MOVING = x2d(  right( HMAC.X, 1 ))
   MOVING = x2d( substr( HMAC.X || HMAC.X, 1 + 2 * MOVING, 8 ))
   MOVING = right( MOVING // x2d( 80000000 ), DIGITS, 0 )

   if CHECKS   then  do          /* ISO 7812 decimal check digit, */
      CHECKS = 0                 /* aöso known as Luhn algorithm  */
      do N = 1 to DIGITS
         D = substr( MOVING, DIGITS + 1 - N, 1 )
         if N // 2   then  D = translate( D, 246813579, 123456789 )
         CHECKS = CHECKS + D     /* keep 0 as is, used elsewhere  */
      end N                      /* to ignore any leading zeros   */
      MOVING = MOVING || right( 10 - right( CHECKS, 1 ), 1 )
   end
   return MOVING

/* -------------------------------------------------------------- */
/* RfC 2617 HTTP Auth Digest, works also for RfCs 2069 and 2831,  */
/* but 'md5-sess' is not the same as in the (historic) RfC 2831.  */

/* Some input values are expected to be an unquoted <qdstr-val>   */
/* (not <quoted-string>), either UTF-8 (2831) or Latin-1 (2617).  */

/* CNONCE and NC are used if QOP is given or ALG is md5-sess, all */
/* further plausibility tests skipped here.  QOP etc. are omitted */
/* in RfC 2069 compatible calculations, other QOP values are used */
/* as is, but only 'auth', 'auth-int', and 'auth-conf' are valid. */

/* XURI has the form  [method]:digest-uri [:hash]  with colons as */
/* separators.  The method is empty for responses, for challenges */
/* it is either AUTHENTICATE (2831) or GET, INVITE, etc. (2617).  */
/* The hash has to be given for QOP 'auth-int' and 'auth-conf' as */
/* colon plus 32 lower case hex. digits, zeros for an empty body. */

AUTHTTP: procedure               /* (skipping plausibility tests) */
   parse arg USER, PASS, REALM, NONCE, CNONCE, NC, QOP, XURI, ALG
   ALG = translate( ALG )        /* ALGorithm is case insensitive */

   HA1 = MD5(  USER || ':' || REALM || ':' || PASS )
   if ALG = 'MD5-SESS'  then  do
      HA1 = HA1 || ':' || NONCE || ':' || CNONCE
      if arg( 10, 'e' ) then  HA1 = HA1 || ':' || arg( 10 )
      HA1 = MD5( HA1 )           /* optional 10th argument: AUTHZ */
   end

   HA2 = MD5( XURI )             /* XURI incl. hash for auth-int  */
   TMP = NONCE                   /* 2069 compatibility (= no qop) */
   if ALG = 'MD5-SESS' | QOP <> ''  then  do
      TMP = translate( d2x( NC, 8 ), 'abcdef', 'ABCDEF' )
      TMP = NONCE || ':' || TMP || ':' || CNONCE || ':' || QOP
   end

   return MD5( HA1 || ':' || TMP || ':' || HA2 )

/* -------------------------------------------------------------- */
/* RfC 2831 DIGEST-MD5 SASL mechanism, based on RfC 2617 AUTHTTP, */
/* but its 'md5-sess' algorithm is unfortunately incompatible.    */

DIGEST:  procedure               /* (skipping plausibility tests) */
   parse arg USER, PASS, REALM, NONCE, CNONCE, NC, QOP, XURI, ALG
   ALG = translate( ALG )        /* ALGorithm is case insensitive */

   HA1 = MD5(  USER || ':' || REALM || ':' || PASS )
   if ALG = 'MD5-SESS'  then  do
      HA1 = x2c( HA1 ) || ':' || NONCE || ':' || CNONCE
      if arg( 10, 'e' ) then  HA1 = HA1 || ':' || arg( 10 )
      HA1 = MD5( HA1 )           /* optional 10th argument: AUTHZ */
   end

   HA2 = MD5( XURI )             /* XURI incl. hash for auth-int  */
   TMP = NONCE                   /* 2069 compatibility (= no qop) */
   if ALG = 'MD5-SESS' | QOP <> ''  then  do
      TMP = translate( d2x( NC, 8 ), 'abcdef', 'ABCDEF' )
      TMP = NONCE || ':' || TMP || ':' || CNONCE || ':' || QOP
   end

   return MD5( HA1 || ':' || TMP || ':' || HA2 )

/* -------------------------------------------------------------- */
/* NOMCOM selects S candidates out of V volunteers using public   */
/* random string sources arg(3), arg(4), etc. as input for an MD5 */
/* random number generator.  The input strings are canonicalized  */
/* non-negative numbers (decimal fractions are allowed):  Whole   */
/* numbers terminated by a dot, strings terminated by a slash.    */

/* The entropy is checked assuming random decimal digits for the  */
/* worst case of selecting S = V / 2 candidates.  This might fail */
/* for the higher entropy of random alphanumerical sources, and   */
/* the upper limit 38 for 38 decimal digits in MD5 is dubious.    */

/* For historic RfC 2777 8bits instead of the new RfC 3797 16bits */
/* calculations specify V < 0.  This is limited to 255 volunteers */
/* and used to test the RfC 2777 "fraction" input example.        */

NOMCOM:  procedure               /* see RfC 3797 for all details: */
   arg V, S                      ;  numeric digits 40
   KEY = ''                      ;  HD = 4

   if V < 0       then  do       /* RfC 2777 8bits: 2 hex. digits */
      V = 0 - V                  ;  HD = 2
      if V > 255  then  return 'pool too big'
   end
   if V > 65535   then  return 'pool too big'
   if V <= S      then  return 'pool too small (or all selected)'

   SKIP = xrange( /**/, x2c( 2D )) || x2c( 2F ) /* accept dot 2E  */
   SKIP = SKIP || xrange( x2c( 3A ), x2c( 40 )) /* accept digits  */
   SKIP = SKIP || xrange( x2c( 5B ))            /* accept A .. Z  */

   do N = 3 while arg( N, 'e' )  /* get raw entropy source values */
      R = translate( arg( N ))   /* (upper case US ASCII letters) */
      R = translate( R, ' ', SKIP )

      if 0 = verify( R, '0.123 456 789' ) then  do
         C = ''                  /* using space separated numbers */
         do W = 1 to words( R )  /* rejecting exponential format: */
            X = format( word( R, W ))
            if pos( 'E', X ) > 0 then  return 'overflow' X arg( N )
            if pos( '.', X ) = 0 then  X = X || .
            X = strip( X, 'T', 0 )

            do I = 1 to words( C )
               if X <= word( C, I ) then  leave I
            end I                /* sorting C by direct insertion */
            C = subword( C, 1, I - 1 ) X subword( C, I )
         end W
      end                        /* 3797 alphanum not yet tested: */
      else  C = translate( R, ' ', '.' ) || '.'

      if 0 = verify( C, ' .' )   then  return 'unexpected' arg( N )
      KEY = KEY || space( C, 0 ) || '/'
   end N
   if KEY = ''    then  return 'empty key (missing random sources)'

   C = ''   ;  X = 1 ;  W = 1 + V % 2
   do N = 1 to V
      C = C N        ;  if N < W then  X = X * ( W + N ) / N
   end N             /* required entropy for worst case S = V / 2 */

   numeric form scientific       /* use format() as cheap log10() */
   W = 1 + substr( format( X,, 0,, 0 ), 3 )
   I = min( 38, length( space( translate( KEY, /**/, '/.' ), 0 )))
   if I < W then  return V 'may need' W 'digits entropy, got only' I

   V = C                         ;  C = ''
   do N = 1 to S                 /* V volunteers and C candidates */
      W = x2c( d2x( N - 1, HD )) ;  W = MD5( W || KEY || W )
      W = x2d( W ) // words( V ) ;  C = C word( V, W + 1 )
      V = subword( V, 1, W ) subword( V, W + 2 )
   end N
   return strip( C )             /* integer sequence / error text */

/* -------------------------------------------------------------- */
/* RfC 2938: B32 encoded MD5 hash of canonicalized media feature; */
/* see "Base 32 Encoding with Extended Hex Alphabet" in RFC 4648. */

MF2B32:  procedure               /* RfC 2938 "media feature hash" */
   parse arg SRC
   DST = ''                      ;  QUO = 0
   do while SRC <> ''            /* remove unquoted control char. */
      TOP = left( SRC, 1 )       ;  SRC = substr( SRC, 2 )
      if TOP = '"'   then  QUO = 1 - QUO
      if QUO         then  DST = DST || TOP  ;  else
         if ' ' < TOP & TOP <= '~'
                     then  DST = DST || translate( TOP )
   end                           /* stick to ASCII, remove 7F..FF */

   B32 = '0123456789ABCDEFGHIJKLMNOPQRSTUV'
   SRC = ''
   DST = x2b( MD5( DST )) || '00'
   do while DST <> ''            /* convert hex. MD5 to base32hex */
      TOP = substr( B32, x2d( b2x( left( DST, 5 ))) + 1, 1 )
      SRC = SRC || TOP           ;  DST = substr( DST, 6 )
   end
   return '(h.' || SRC || ')'

/* -------------------------------------------------------------- */
/* Apache .htpasswd user:$apr1$salt...8$hash....10..........22    */
/* The (unused) user: prefix is an index into the password file.  */
/* The magics $apr1$ and $1$ use the same MD5 crypt() algorithm.  */
/* The salt is delimited by $ and truncated to eight characters.  */
/* The hash is 22 characters long, B64 alphabet: ./ DIGIT ALPHA   */

APR1  :  procedure               /* sorry, no RfC for this horror */
   parse arg PASS, MAGIC, SALT   /* (slow, 1001 MD5 calculations) */

   if MAGIC <> '$apr1$' & MAGIC <> '$1$'  then  return ''
   if arg( 3, 'o' )                       then  SALT = APR1.S()
   SALT = left( SALT, min( 8, length( SALT )))

   SRC = PASS || MAGIC || SALT
   DST = x2c( MD5( PASS || SALT || PASS ))

   ADD = length( PASS )          /* pointless additions, 1st part */
   do while ADD > 0
      SRC = SRC || left( DST, min( 16, ADD ))
      ADD = ADD - 16
   end
   ADD = length( PASS )          /* pointless additions, 2nd part */
   do while ADD > 0
      if ADD // 2       then  SRC = SRC || d2c( 0 )
                        else  SRC = SRC || left( PASS, 1 )
      ADD = ADD % 2
   end

   DST = x2c( MD5( SRC ))        /* 1000 varying MD5 calculations */
   do N = 0 to 999
      if sign( N // 3 ) then  SRC = SALT
                        else  SRC = ''
      if sign( N // 7 ) then  SRC = SRC || PASS
      if N // 2         then  SRC = PASS || SRC || DST
                        else  SRC = DST  || SRC || PASS
      DST = x2c( MD5( SRC ))
   end N

   SRC = ''                      /* pointless scrambling of hash: */
   ADD = '13 7 1 14 8 2 15 9 3 16 10 4 6 11 5 12'
   do N = 1 to 16
      SRC = substr( DST, word( ADD, N ), 1 ) || SRC
   end N
   return MAGIC || SALT || '$' || APR1.B( SRC )

APR1.S:  procedure               /* init. APR1() or PHPASS() SALT */
   SALT = d2x( random( 0, 65535 ), 4 )
   SALT = d2x( random( 0, 65535 ), 4 ) || SALT
   SALT = d2x( random( 0, 65535 ), 4 ) || SALT
   return APR1.B( x2c( SALT ))

APR1.B:  procedure               /* B64-like right to left encode */
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = './0123456789' || translate( B64 ) || B64

   SRC = x2b( c2x( arg( 1 )))    ;  DST = ''
   SRC = copies( '00', ( length( SRC ) / 4 ) // 3 ) || SRC
   do while SRC <> ''
      parse var SRC N 7 SRC      ;  N = x2d( b2x( N ))
      DST = substr( B64, N + 1, 1 ) || DST
   end
   return DST

/* -------------------------------------------------------------- */
/***************** DO NOT USE, SOMETHING IS WRONG *****************/
/* The "private" $P$ PasswordHash.php MD5 algorithm might be used */
/* where its better algorithms are unavailable; uses the APR1.B() */
/* alphabet and the APR1.S() pseudo-random SALT.  Details such as */
/* the minimal COST or SALT checks differ in published sources.   */

PHPASS:  procedure               /* Portable MD5 PasswordHash.php */
   parse arg PASS, MAGIC, COST, SALT

   if MAGIC <> '$P$' & MAGIC <> '$H$'        then  return ''
   if arg( 3, 'o' ) | COST < 7 | COST > 30   then  COST = 8
   if arg( 4, 'o' )                          then  SALT = APR1.S()
   if length( SALT ) <> 8                    then  return ''

   HASH = x2c( MD5( SALT || PASS ))
   do N = 1 to 2**COST           /* clearly not as bad as APR.1() */
      HASH = x2c( MD5( HASH || PASS ))
   end N

   HASH = APR1.B( HASH )
   COST = left( APR1.B( d2c( COST )), 1 )
   return MAGIC || COST || SALT || HASH

/* -------------------------------------------------------------- */
/* RfC 1910 is a HISTORIC experimental RfC added here, because it */
/* contains a rather obscure application of MD5 with an example.  */

EX1910:  procedure               /* see RfC 1910 for the details  */
   parse arg PASS, ID            ;  LEN = length( PASS )
   CTX = ''                      ;  TOT = LEN
   if length( ID ) <> 12 | LEN = 0  then  return ''   /* => error */

   do while TOT < 1024 * 1024    /* Caveat: VERY SLOW, do not use */
      CTX = MD5( PASS, CTX )     ;  TOT = LEN + TOT
   end                           /* it's even weirder than APR1() */

   CTX = MD5( left( PASS, 1024 * 1024 + LEN - TOT ), CTX )
   KEY = x2c( MD5( /**/, CTX ))
   return MD5( KEY || ID || KEY )

/* -------------------------------------------------------------- */
/* RfC 4122 name-based MD5 UUID (version 3).  Any value as third  */
/* argument triggers the endian magic to reproduce the RfC 4122   */
/* example, without this magic two other published examples work. */

UUID.3:  procedure               /* see RfC 4122 for the details, */
   parse arg NS, NAME            /* NS can be a custom hex. UUID  */
   NS = translate( space( translate( NS, ' ', '-' ), 0 ))
   LE = arg( 3, 'e' )            /* bypass plausible 4122 erratum */

   select                        /* name spaces given in RfC 4122 */
      when NS = 'DNS'            /* fully qualified domain name   */
      then NS = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
      when NS = 'URL'
      then NS = '6ba7b811-9dad-11d1-80b4-00c04fd430c8'
      when NS = 'OID'
      then NS = '6ba7b812-9dad-11d1-80b4-00c04fd430c8'
      when NS = 'X500'           /* X.500 DN (DER or text)        */
      then NS = '6ba7b814-9dad-11d1-80b4-00c04fd430c8'
      when length( NS ) = 32 & datatype( NS, 'H' ) then nop
   end                           /* otherwise force REXX error 7  */

   X = x2c( space( translate( NS, ' ', '-' ), 0 ))
   if LE then  do                /* bypass plausible 4122 erratum */
      parse var X X.1 +4 X.2 +2 X.3 +2 X
      X = reverse( X.1 ) || reverse( X.2 ) || reverse( X.3 ) || X
   end
   X = x2c( MD5( X || NAME ))
   if LE then  do                /* bypass plausible 4122 erratum */
      parse var X X.1 +4 X.2 +2 X.3 +2 X
      X = reverse( X.1 ) || reverse( X.2 ) || reverse( X.3 ) || X
   end
   X = bitand( X, x2c( 'FFFF FFFF FFFF 0FFF 3FFF FFFF FFFF FFFF' ))
   X = bitxor( X, x2c( '0000 0000 0000 3000 8000 0000 0000 0000' ))

   parse value c2x( X ) with X.1 +8 X.2 +4 X.3 +4 X.4 +4 X
   X = X.1 || '-' || X.2 || '-' || X.3 || '-' || X.4 || '-' || X
   return 'urn:uuid:' || translate( X, 'abcdef', 'ABCDEF' )

/* -------------------------------------------------------------- */
/* RfC 2289 otp-md5 (with standard One Time Password dictionary). */
/* For a hex. OTP generator copy procedure OTP and the MD5 stuff. */
/* For six words format use OTP.6 adding OTP.2, OTP.1, and OTP.0, */
/* servers need only OTP.3, OTP.2, and OTP.1 to decode six words. */

OTP   :  procedure               /* see RfC 2289 to improve COUNT */
   parse arg PASS, SEED, COUNT   /* down by storing computed OTPs */

   select                        /* check arguments, see RfC 2289 */
      when datatype( SEED, 'A' ) = 0   then  return ''
      when length( SEED ) > 16         then  return ''
      when length( PASS ) < 10         then  return ''
      otherwise   nop            /* empty result if invalid arg., */
   end                           /* empty SEED found by datatype  */

   ATOZ = 'abcdefghijklmnopqrstuvwxyz'
   PASS = translate( SEED, ATOZ, translate( ATOZ )) || PASS

   do COUNT + 1                  /* compute next OTP from scratch */
      PASS = x2c( MD5( PASS ))   /* fold MD5 output into 64 bits: */
      PASS = bitxor( left( PASS, 8 ), right( PASS, 8 ))
   end                           /* RfC 2243 "SHOULD": lower case */
   return translate( c2x( PASS ), 'abcdef', 'ABCDEF' )

/* For six words format use OTP.6 adding OTP.2, OTP.1, and OTP.0: */
/* 64 bits given as 8 hex. bytes to 6 words or v.v. is defined in */
/* RfC 2289, RfC 2243, and RfC 2444.  An OTP dictionary with 2048 */
/* words encodes 11 bits in 1 word (6 * 11 = 64 + 2 bits parity). */

OTP.6 :  return OTP.0( OTP( arg( 1 ), arg( 2 ), arg( 3 )))

OTP.0 :  procedure               /* 8 hex. bytes to 6 word format */
   SRC = space( arg( 1 ), 0 )    ;  SIX = ''
   if datatype( SRC, 'x' ) & length( SRC ) = 16 then  do
      SRC = x2b( SRC )           ;  SRC = SRC || OTP.2( SRC )
      do 6                       /* encode 6 * 11 bits as 6 words */
         SIX = SIX OTP.1( left( SRC, 11 ))
         SRC = substr( SRC, 12 )
      end
      return strip( SIX )
   end
   return ''                     /* empty result if invalid arg.  */

OTP.1:   procedure               /* access on Six-Word dictionary */
   X = trace( 'O' )              /* don't trace dictionary init.  */
   S =   'A    ABE  ACE  ACT  AD   ADA  ADD  AGO '
   S = S 'AID  AIM  AIR  ALL  ALP  AM   AMY  AN  '
   S = S 'ANA  AND  ANN  ANT  ANY  APE  APS  APT '
   S = S 'ARC  ARE  ARK  ARM  ART  AS   ASH  ASK '
   S = S 'AT   ATE  AUG  AUK  AVE  AWE  AWK  AWL '
   S = S 'AWN  AX   AYE  BAD  BAG  BAH  BAM  BAN '
   S = S 'BAR  BAT  BAY  BE   BED  BEE  BEG  BEN '
   S = S 'BET  BEY  BIB  BID  BIG  BIN  BIT  BOB '
   S = S 'BOG  BON  BOO  BOP  BOW  BOY  BUB  BUD '
   S = S 'BUG  BUM  BUN  BUS  BUT  BUY  BY   BYE '
   S = S 'CAB  CAL  CAM  CAN  CAP  CAR  CAT  CAW '
   S = S 'COD  COG  COL  CON  COO  COP  COT  COW '
   S = S 'COY  CRY  CUB  CUE  CUP  CUR  CUT  DAB '
   S = S 'DAD  DAM  DAN  DAR  DAY  DEE  DEL  DEN '
   S = S 'DES  DEW  DID  DIE  DIG  DIN  DIP  DO  '
   S = S 'DOE  DOG  DON  DOT  DOW  DRY  DUB  DUD '
   S = S 'DUE  DUG  DUN  EAR  EAT  ED   EEL  EGG '
   S = S 'EGO  ELI  ELK  ELM  ELY  EM   END  EST '
   S = S 'ETC  EVA  EVE  EWE  EYE  FAD  FAN  FAR '
   S = S 'FAT  FAY  FED  FEE  FEW  FIB  FIG  FIN '
   S = S 'FIR  FIT  FLO  FLY  FOE  FOG  FOR  FRY '
   S = S 'FUM  FUN  FUR  GAB  GAD  GAG  GAL  GAM '
   S = S 'GAP  GAS  GAY  GEE  GEL  GEM  GET  GIG '
   S = S 'GIL  GIN  GO   GOT  GUM  GUN  GUS  GUT '
   S = S 'GUY  GYM  GYP  HA   HAD  HAL  HAM  HAN '
   S = S 'HAP  HAS  HAT  HAW  HAY  HE   HEM  HEN '
   S = S 'HER  HEW  HEY  HI   HID  HIM  HIP  HIS '
   S = S 'HIT  HO   HOB  HOC  HOE  HOG  HOP  HOT '
   S = S 'HOW  HUB  HUE  HUG  HUH  HUM  HUT  I   '
   S = S 'ICY  IDA  IF   IKE  ILL  INK  INN  IO  '
   S = S 'ION  IQ   IRA  IRE  IRK  IS   IT   ITS '
   S = S 'IVY  JAB  JAG  JAM  JAN  JAR  JAW  JAY '
   S = S 'JET  JIG  JIM  JO   JOB  JOE  JOG  JOT '
   S = S 'JOY  JUG  JUT  KAY  KEG  KEN  KEY  KID '
   S = S 'KIM  KIN  KIT  LA   LAB  LAC  LAD  LAG '
   S = S 'LAM  LAP  LAW  LAY  LEA  LED  LEE  LEG '
   S = S 'LEN  LEO  LET  LEW  LID  LIE  LIN  LIP '
   S = S 'LIT  LO   LOB  LOG  LOP  LOS  LOT  LOU '
   S = S 'LOW  LOY  LUG  LYE  MA   MAC  MAD  MAE '
   S = S 'MAN  MAO  MAP  MAT  MAW  MAY  ME   MEG '
   S = S 'MEL  MEN  MET  MEW  MID  MIN  MIT  MOB '
   S = S 'MOD  MOE  MOO  MOP  MOS  MOT  MOW  MUD '
   S = S 'MUG  MUM  MY   NAB  NAG  NAN  NAP  NAT '
   S = S 'NAY  NE   NED  NEE  NET  NEW  NIB  NIL '
   S = S 'NIP  NIT  NO   NOB  NOD  NON  NOR  NOT '
   S = S 'NOV  NOW  NU   NUN  NUT  O    OAF  OAK '
   S = S 'OAR  OAT  ODD  ODE  OF   OFF  OFT  OH  '
   S = S 'OIL  OK   OLD  ON   ONE  OR   ORB  ORE '
   S = S 'ORR  OS   OTT  OUR  OUT  OVA  OW   OWE '
   S = S 'OWL  OWN  OX   PA   PAD  PAL  PAM  PAN '
   S = S 'PAP  PAR  PAT  PAW  PAY  PEA  PEG  PEN '
   S = S 'PEP  PER  PET  PEW  PHI  PI   PIE  PIN '
   S = S 'PIT  PLY  PO   POD  POE  POP  POT  POW '
   S = S 'PRO  PRY  PUB  PUG  PUN  PUP  PUT  QUO '
   S = S 'RAG  RAM  RAN  RAP  RAT  RAW  RAY  REB '
   S = S 'RED  REP  RET  RIB  RID  RIG  RIM  RIO '
   S = S 'RIP  ROB  ROD  ROE  RON  ROT  ROW  ROY '
   S = S 'RUB  RUE  RUG  RUM  RUN  RYE  SAC  SAD '
   S = S 'SAG  SAL  SAM  SAN  SAP  SAT  SAW  SAY '
   S = S 'SEA  SEC  SEE  SEN  SET  SEW  SHE  SHY '
   S = S 'SIN  SIP  SIR  SIS  SIT  SKI  SKY  SLY '
   S = S 'SO   SOB  SOD  SON  SOP  SOW  SOY  SPA '
   S = S 'SPY  SUB  SUD  SUE  SUM  SUN  SUP  TAB '
   S = S 'TAD  TAG  TAN  TAP  TAR  TEA  TED  TEE '
   S = S 'TEN  THE  THY  TIC  TIE  TIM  TIN  TIP '
   S = S 'TO   TOE  TOG  TOM  TON  TOO  TOP  TOW '
   S = S 'TOY  TRY  TUB  TUG  TUM  TUN  TWO  UN  '
   S = S 'UP   US   USE  VAN  VAT  VET  VIE  WAD '
   S = S 'WAG  WAR  WAS  WAY  WE   WEB  WED  WEE '
   S = S 'WET  WHO  WHY  WIN  WIT  WOK  WON  WOO '
   S = S 'WOW  WRY  WU   YAM  YAP  YAW  YE   YEA '
   S = S 'YES  YET  YOU  ABED ABEL ABET ABLE ABUT'
   S = S 'ACHE ACID ACME ACRE ACTA ACTS ADAM ADDS'
   S = S 'ADEN AFAR AFRO AGEE AHEM AHOY AIDA AIDE'
   S = S 'AIDS AIRY AJAR AKIN ALAN ALEC ALGA ALIA'
   S = S 'ALLY ALMA ALOE ALSO ALTO ALUM ALVA AMEN'
   S = S 'AMES AMID AMMO AMOK AMOS AMRA ANDY ANEW'
   S = S 'ANNA ANNE ANTE ANTI AQUA ARAB ARCH AREA'
   S = S 'ARGO ARID ARMY ARTS ARTY ASIA ASKS ATOM'
   S = S 'AUNT AURA AUTO AVER AVID AVIS AVON AVOW'
   S = S 'AWAY AWRY BABE BABY BACH BACK BADE BAIL'
   S = S 'BAIT BAKE BALD BALE BALI BALK BALL BALM'
   S = S 'BAND BANE BANG BANK BARB BARD BARE BARK'
   S = S 'BARN BARR BASE BASH BASK BASS BATE BATH'
   S = S 'BAWD BAWL BEAD BEAK BEAM BEAN BEAR BEAT'
   S = S 'BEAU BECK BEEF BEEN BEER BEET BELA BELL'
   S = S 'BELT BEND BENT BERG BERN BERT BESS BEST'
   S = S 'BETA BETH BHOY BIAS BIDE BIEN BILE BILK'
   S = S 'BILL BIND BING BIRD BITE BITS BLAB BLAT'
   S = S 'BLED BLEW BLOB BLOC BLOT BLOW BLUE BLUM'
   S = S 'BLUR BOAR BOAT BOCA BOCK BODE BODY BOGY'
   S = S 'BOHR BOIL BOLD BOLO BOLT BOMB BONA BOND'
   S = S 'BONE BONG BONN BONY BOOK BOOM BOON BOOT'
   S = S 'BORE BORG BORN BOSE BOSS BOTH BOUT BOWL'
   S = S 'BOYD BRAD BRAE BRAG BRAN BRAY BRED BREW'
   S = S 'BRIG BRIM BROW BUCK BUDD BUFF BULB BULK'
   S = S 'BULL BUNK BUNT BUOY BURG BURL BURN BURR'
   S = S 'BURT BURY BUSH BUSS BUST BUSY BYTE CADY'
   S = S 'CAFE CAGE CAIN CAKE CALF CALL CALM CAME'
   S = S 'CANE CANT CARD CARE CARL CARR CART CASE'
   S = S 'CASH CASK CAST CAVE CEIL CELL CENT CERN'
   S = S 'CHAD CHAR CHAT CHAW CHEF CHEN CHEW CHIC'
   S = S 'CHIN CHOU CHOW CHUB CHUG CHUM CITE CITY'
   S = S 'CLAD CLAM CLAN CLAW CLAY CLOD CLOG CLOT'
   S = S 'CLUB CLUE COAL COAT COCA COCK COCO CODA'
   S = S 'CODE CODY COED COIL COIN COKE COLA COLD'
   S = S 'COLT COMA COMB COME COOK COOL COON COOT'
   S = S 'CORD CORE CORK CORN COST COVE COWL CRAB'
   S = S 'CRAG CRAM CRAY CREW CRIB CROW CRUD CUBA'
   S = S 'CUBE CUFF CULL CULT CUNY CURB CURD CURE'
   S = S 'CURL CURT CUTS DADE DALE DAME DANA DANE'
   S = S 'DANG DANK DARE DARK DARN DART DASH DATA'
   S = S 'DATE DAVE DAVY DAWN DAYS DEAD DEAF DEAL'
   S = S 'DEAN DEAR DEBT DECK DEED DEEM DEER DEFT'
   S = S 'DEFY DELL DENT DENY DESK DIAL DICE DIED'
   S = S 'DIET DIME DINE DING DINT DIRE DIRT DISC'
   S = S 'DISH DISK DIVE DOCK DOES DOLE DOLL DOLT'
   S = S 'DOME DONE DOOM DOOR DORA DOSE DOTE DOUG'
   S = S 'DOUR DOVE DOWN DRAB DRAG DRAM DRAW DREW'
   S = S 'DRUB DRUG DRUM DUAL DUCK DUCT DUEL DUET'
   S = S 'DUKE DULL DUMB DUNE DUNK DUSK DUST DUTY'
   S = S 'EACH EARL EARN EASE EAST EASY EBEN ECHO'
   S = S 'EDDY EDEN EDGE EDGY EDIT EDNA EGAN ELAN'
   S = S 'ELBA ELLA ELSE EMIL EMIT EMMA ENDS ERIC'
   S = S 'EROS EVEN EVER EVIL EYED FACE FACT FADE'
   S = S 'FAIL FAIN FAIR FAKE FALL FAME FANG FARM'
   S = S 'FAST FATE FAWN FEAR FEAT FEED FEEL FEET'
   S = S 'FELL FELT FEND FERN FEST FEUD FIEF FIGS'
   S = S 'FILE FILL FILM FIND FINE FINK FIRE FIRM'
   S = S 'FISH FISK FIST FITS FIVE FLAG FLAK FLAM'
   S = S 'FLAT FLAW FLEA FLED FLEW FLIT FLOC FLOG'
   S = S 'FLOW FLUB FLUE FOAL FOAM FOGY FOIL FOLD'
   S = S 'FOLK FOND FONT FOOD FOOL FOOT FORD FORE'
   S = S 'FORK FORM FORT FOSS FOUL FOUR FOWL FRAU'
   S = S 'FRAY FRED FREE FRET FREY FROG FROM FUEL'
   S = S 'FULL FUME FUND FUNK FURY FUSE FUSS GAFF'
   S = S 'GAGE GAIL GAIN GAIT GALA GALE GALL GALT'
   S = S 'GAME GANG GARB GARY GASH GATE GAUL GAUR'
   S = S 'GAVE GAWK GEAR GELD GENE GENT GERM GETS'
   S = S 'GIBE GIFT GILD GILL GILT GINA GIRD GIRL'
   S = S 'GIST GIVE GLAD GLEE GLEN GLIB GLOB GLOM'
   S = S 'GLOW GLUE GLUM GLUT GOAD GOAL GOAT GOER'
   S = S 'GOES GOLD GOLF GONE GONG GOOD GOOF GORE'
   S = S 'GORY GOSH GOUT GOWN GRAB GRAD GRAY GREG'
   S = S 'GREW GREY GRID GRIM GRIN GRIT GROW GRUB'
   S = S 'GULF GULL GUNK GURU GUSH GUST GWEN GWYN'
   S = S 'HAAG HAAS HACK HAIL HAIR HALE HALF HALL'
   S = S 'HALO HALT HAND HANG HANK HANS HARD HARK'
   S = S 'HARM HART HASH HAST HATE HATH HAUL HAVE'
   S = S 'HAWK HAYS HEAD HEAL HEAR HEAT HEBE HECK'
   S = S 'HEED HEEL HEFT HELD HELL HELM HERB HERD'
   S = S 'HERE HERO HERS HESS HEWN HICK HIDE HIGH'
   S = S 'HIKE HILL HILT HIND HINT HIRE HISS HIVE'
   S = S 'HOBO HOCK HOFF HOLD HOLE HOLM HOLT HOME'
   S = S 'HONE HONK HOOD HOOF HOOK HOOT HORN HOSE'
   S = S 'HOST HOUR HOVE HOWE HOWL HOYT HUCK HUED'
   S = S 'HUFF HUGE HUGH HUGO HULK HULL HUNK HUNT'
   S = S 'HURD HURL HURT HUSH HYDE HYMN IBIS ICON'
   S = S 'IDEA IDLE IFFY INCA INCH INTO IONS IOTA'
   S = S 'IOWA IRIS IRMA IRON ISLE ITCH ITEM IVAN'
   S = S 'JACK JADE JAIL JAKE JANE JAVA JEAN JEFF'
   S = S 'JERK JESS JEST JIBE JILL JILT JIVE JOAN'
   S = S 'JOBS JOCK JOEL JOEY JOHN JOIN JOKE JOLT'
   S = S 'JOVE JUDD JUDE JUDO JUDY JUJU JUKE JULY'
   S = S 'JUNE JUNK JUNO JURY JUST JUTE KAHN KALE'
   S = S 'KANE KANT KARL KATE KEEL KEEN KENO KENT'
   S = S 'KERN KERR KEYS KICK KILL KIND KING KIRK'
   S = S 'KISS KITE KLAN KNEE KNEW KNIT KNOB KNOT'
   S = S 'KNOW KOCH KONG KUDO KURD KURT KYLE LACE'
   S = S 'LACK LACY LADY LAID LAIN LAIR LAKE LAMB'
   S = S 'LAME LAND LANE LANG LARD LARK LASS LAST'
   S = S 'LATE LAUD LAVA LAWN LAWS LAYS LEAD LEAF'
   S = S 'LEAK LEAN LEAR LEEK LEER LEFT LEND LENS'
   S = S 'LENT LEON LESK LESS LEST LETS LIAR LICE'
   S = S 'LICK LIED LIEN LIES LIEU LIFE LIFT LIKE'
   S = S 'LILA LILT LILY LIMA LIMB LIME LIND LINE'
   S = S 'LINK LINT LION LISA LIST LIVE LOAD LOAF'
   S = S 'LOAM LOAN LOCK LOFT LOGE LOIS LOLA LONE'
   S = S 'LONG LOOK LOON LOOT LORD LORE LOSE LOSS'
   S = S 'LOST LOUD LOVE LOWE LUCK LUCY LUGE LUKE'
   S = S 'LULU LUND LUNG LURA LURE LURK LUSH LUST'
   S = S 'LYLE LYNN LYON LYRA MACE MADE MAGI MAID'
   S = S 'MAIL MAIN MAKE MALE MALI MALL MALT MANA'
   S = S 'MANN MANY MARC MARE MARK MARS MART MARY'
   S = S 'MASH MASK MASS MAST MATE MATH MAUL MAYO'
   S = S 'MEAD MEAL MEAN MEAT MEEK MEET MELD MELT'
   S = S 'MEMO MEND MENU MERT MESH MESS MICE MIKE'
   S = S 'MILD MILE MILK MILL MILT MIMI MIND MINE'
   S = S 'MINI MINK MINT MIRE MISS MIST MITE MITT'
   S = S 'MOAN MOAT MOCK MODE MOLD MOLE MOLL MOLT'
   S = S 'MONA MONK MONT MOOD MOON MOOR MOOT MORE'
   S = S 'MORN MORT MOSS MOST MOTH MOVE MUCH MUCK'
   S = S 'MUDD MUFF MULE MULL MURK MUSH MUST MUTE'
   S = S 'MUTT MYRA MYTH NAGY NAIL NAIR NAME NARY'
   S = S 'NASH NAVE NAVY NEAL NEAR NEAT NECK NEED'
   S = S 'NEIL NELL NEON NERO NESS NEST NEWS NEWT'
   S = S 'NIBS NICE NICK NILE NINA NINE NOAH NODE'
   S = S 'NOEL NOLL NONE NOOK NOON NORM NOSE NOTE'
   S = S 'NOUN NOVA NUDE NULL NUMB OATH OBEY OBOE'
   S = S 'ODIN OHIO OILY OINT OKAY OLAF OLDY OLGA'
   S = S 'OLIN OMAN OMEN OMIT ONCE ONES ONLY ONTO'
   S = S 'ONUS ORAL ORGY OSLO OTIS OTTO OUCH OUST'
   S = S 'OUTS OVAL OVEN OVER OWLY OWNS QUAD QUIT'
   S = S 'QUOD RACE RACK RACY RAFT RAGE RAID RAIL'
   S = S 'RAIN RAKE RANK RANT RARE RASH RATE RAVE'
   S = S 'RAYS READ REAL REAM REAR RECK REED REEF'
   S = S 'REEK REEL REID REIN RENA REND RENT REST'
   S = S 'RICE RICH RICK RIDE RIFT RILL RIME RING'
   S = S 'RINK RISE RISK RITE ROAD ROAM ROAR ROBE'
   S = S 'ROCK RODE ROIL ROLL ROME ROOD ROOF ROOK'
   S = S 'ROOM ROOT ROSA ROSE ROSS ROSY ROTH ROUT'
   S = S 'ROVE ROWE ROWS RUBE RUBY RUDE RUDY RUIN'
   S = S 'RULE RUNG RUNS RUNT RUSE RUSH RUSK RUSS'
   S = S 'RUST RUTH SACK SAFE SAGE SAID SAIL SALE'
   S = S 'SALK SALT SAME SAND SANE SANG SANK SARA'
   S = S 'SAUL SAVE SAYS SCAN SCAR SCAT SCOT SEAL'
   S = S 'SEAM SEAR SEAT SEED SEEK SEEM SEEN SEES'
   S = S 'SELF SELL SEND SENT SETS SEWN SHAG SHAM'
   S = S 'SHAW SHAY SHED SHIM SHIN SHOD SHOE SHOT'
   S = S 'SHOW SHUN SHUT SICK SIDE SIFT SIGH SIGN'
   S = S 'SILK SILL SILO SILT SINE SING SINK SIRE'
   S = S 'SITE SITS SITU SKAT SKEW SKID SKIM SKIN'
   S = S 'SKIT SLAB SLAM SLAT SLAY SLED SLEW SLID'
   S = S 'SLIM SLIT SLOB SLOG SLOT SLOW SLUG SLUM'
   S = S 'SLUR SMOG SMUG SNAG SNOB SNOW SNUB SNUG'
   S = S 'SOAK SOAR SOCK SODA SOFA SOFT SOIL SOLD'
   S = S 'SOME SONG SOON SOOT SORE SORT SOUL SOUR'
   S = S 'SOWN STAB STAG STAN STAR STAY STEM STEW'
   S = S 'STIR STOW STUB STUN SUCH SUDS SUIT SULK'
   S = S 'SUMS SUNG SUNK SURE SURF SWAB SWAG SWAM'
   S = S 'SWAN SWAT SWAY SWIM SWUM TACK TACT TAIL'
   S = S 'TAKE TALE TALK TALL TANK TASK TATE TAUT'
   S = S 'TEAL TEAM TEAR TECH TEEM TEEN TEET TELL'
   S = S 'TEND TENT TERM TERN TESS TEST THAN THAT'
   S = S 'THEE THEM THEN THEY THIN THIS THUD THUG'
   S = S 'TICK TIDE TIDY TIED TIER TILE TILL TILT'
   S = S 'TIME TINA TINE TINT TINY TIRE TOAD TOGO'
   S = S 'TOIL TOLD TOLL TONE TONG TONY TOOK TOOL'
   S = S 'TOOT TORE TORN TOTE TOUR TOUT TOWN TRAG'
   S = S 'TRAM TRAY TREE TREK TRIG TRIM TRIO TROD'
   S = S 'TROT TROY TRUE TUBA TUBE TUCK TUFT TUNA'
   S = S 'TUNE TUNG TURF TURN TUSK TWIG TWIN TWIT'
   S = S 'ULAN UNIT URGE USED USER USES UTAH VAIL'
   S = S 'VAIN VALE VARY VASE VAST VEAL VEDA VEIL'
   S = S 'VEIN VEND VENT VERB VERY VETO VICE VIEW'
   S = S 'VINE VISE VOID VOLT VOTE WACK WADE WAGE'
   S = S 'WAIL WAIT WAKE WALE WALK WALL WALT WAND'
   S = S 'WANE WANG WANT WARD WARM WARN WART WASH'
   S = S 'WAST WATS WATT WAVE WAVY WAYS WEAK WEAL'
   S = S 'WEAN WEAR WEED WEEK WEIR WELD WELL WELT'
   S = S 'WENT WERE WERT WEST WHAM WHAT WHEE WHEN'
   S = S 'WHET WHOA WHOM WICK WIFE WILD WILL WIND'
   S = S 'WINE WING WINK WINO WIRE WISE WISH WITH'
   S = S 'WOLF WONT WOOD WOOL WORD WORE WORK WORM'
   S = S 'WORN WOVE WRIT WYNN YALE YANG YANK YARD'
   S = S 'YARN YAWL YAWN YEAH YEAR YELL YOGA YOKE'

   trace value X  ;  arg X       /* 11 bits to dict. word or v.v. */
   if datatype( X, 'B' )   then  do
      if length( X ) = 11  then  return word( S, 1 + x2d( b2x( X )))
   end                           /* d2x() REXX error 40 if bad X: */
   return right( x2b( d2x( wordpos( X, S ) - 1 )), 11 )

OTP.2 :  procedure               /* compute the parity of 64 bits */
   parse arg B                ;  P = 0
   do N = 1 to 63 by 2           /* add 0 .. 3 modulo 4 to parity */
      P = ( P + b2x( substr( B, N, 2 ))) // 4
   end N
   return right( x2b( P ), 2 )   /* returns parity 00, 01, 10, 11 */

/* Servers need only OTP.3, OTP.2, and OTP.1 to decode six words: */

OTP.3 :  procedure               /* 6 word format to 8 hex. bytes */
   arg SIX                       ;  DST = ''
   if words( SIX ) = 6  then  do
      do 6
         parse var SIX PART SIX  ;  DST = DST || OTP.1( PART )
      end
      parse var DST DST 65 PART  /* strip and check 2 parity bits */
      if PART = OTP.2( DST )
         then  return translate( b2x( DST ), 'abcdef', 'ABCDEF' )
   end                           /* better return lower case hex. */
   return ''                     /* empty result if invalid arg.  */

/* -------------------------------------------------------------- */
/* To use CRAM-MD5 copy procedures CRAM, HMAC, and the MD5 stuff. */
/* CRAM( USER, PASS, CHALLENGE ) returns a base64 response for a  */
/* base64 challenge.  The challenge can have the form '+ base64'. */

CRAM  :  procedure               /* for CRAM details see RfC 2195 */
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = translate( B64 ) || B64 || '0123456789+/'

   DST = '' ;  SRC = arg( 3 )    /* strip IMAP or POP3 AUTH '+ ': */
   if abbrev( SRC, '+ ' )  then  SRC = substr( SRC, 3 )
   do while abbrev( '==', SRC ) = 0
      parse var SRC ADD 2 SRC    /* if no B64 force REXX error 40 */
      ADD = d2x( pos( ADD, B64 ) - 1 )
      DST = DST || right( x2b( ADD ), 6, 0 )
   end
   SRC = x2c( b2x( left( DST, length( DST ) - 2 * length( SRC ))))
   SRC = x2b( c2x( arg( 1 ) HMAC( arg( 2 ), SRC )))
   DST = ''
   ADD = ( length( SRC ) / 4 ) // 3
   SRC = SRC || copies( '00', ADD )

   do while SRC <> ''
      parse var SRC N 7 SRC   ;  N = x2d( b2x( N ))
      DST = DST || substr( B64,  N + 1, 1 )
   end
   return DST || copies( '=', ADD )

/* -------------------------------------------------------------- */
/* To use HMAC-MD5 copy procedure HMAC and all MD5 procedures.    */
/* The typical key length is 16 bytes, e.g. x2c( MD5( secret )).  */
/* Use left( x2c( HMAC( key, msg )), 12 ) for the first 96 bits.  */

HMAC  :  procedure               /* for HMAC details see RfC 2104 */
   parse arg KEY, MSG            /* also known as KEYED-MD5       */

   if length( KEY ) > 64   then  KEY = x2c( MD5( KEY ))

   OPAD = bitxor( KEY, copies( '5C'x, 64 ), '00'x )
   IPAD = bitxor( KEY, copies( '36'x, 64 ), '00'x )
   return MD5( OPAD || x2c( MD5( IPAD || MSG )))

/* -------------------------------------------------------------- */
/* Credits: RSA Data Security, Inc. MD5 Message-Digest Algorithm, */
/* for an MD5 test suite see <http://purl.net/xyzzy/src/md5.cmd>  */
/* hash = MD5( bytes )                 => MD5 of an octet string  */
/* ctxt = MD5( bytes, '' )             => init.  new MD5 context  */
/* ctxt = MD5( bytes, ctxt )           => update old MD5 context  */
/* hash = MD5( /**/ , ctxt )           => finalize   MD5 context  */
/* hash = MD5( bytes, /**/, n )        => MD5 of n zero-fill bits */
/* ctxt = MD5( bytes, ''  , n )        => init.  MD5 bit context  */
/* ctxt = MD5( bytes, ctxt, n )        => update MD5 bit context  */

MD5   :  procedure               /* for MD5 details see RfC 1321  */
   if arg( 2 ) = ''  then  do    /* no or empty context => init.  */
      A = '67452301' ;  B = 'EFCDAB89' ;  LEN = 0
      C = '98BADCFE' ;  D = '10325476' ;  BIN = ''
   end
   else  parse value arg( 2 ) with  A B C D LEN BIN

   numeric digits 20             /* 20 digits for max. 2**64 bits */
   ADD = 8 * length( arg( 1 ))   /* use length ADD if no arg( 3 ) */
   NEW = length( BIN )           /* BIN = remaining bits, mod 512 */

   if arg( 3 ) = '' & NEW // 8 = 0  then  do
      MSG = x2c( b2x( BIN )) || arg( 1 )
      NEW = NEW + ADD         ;  ADD = NEW // 512
      NEW = NEW - ADD         ;  BIN = substr( MSG, NEW / 8 + 1 )
      LEN = LEN + NEW         ;  MSG = left( MSG, NEW / 8 )
      BIN = x2b( c2x( BIN ))     /* save up to 511 remaining bits */
   end                           /* code above is good for octets */
   else  do                      /* code below is for bit-strings */
      if arg( 3 ) <> '' then  ADD = arg( 3 )
      BIN = BIN || left( x2b( c2x( arg( 1 ))), ADD, 0 )
      NEW = NEW + ADD         ;  ADD = NEW // 512
      NEW = NEW - ADD         ;  MSG = left( BIN, NEW )
      LEN = LEN + NEW         ;  BIN = substr( BIN, NEW + 1 )
      MSG = x2c( b2x( MSG ))     /* caveat, for the 3rd argument  */
   end                           /*  you'll get what you paid for */

   if arg( 2, 'o' ) | ( arg( 1, 'o' ) & arg( 2 ) <> '' ) then  do
      LEN = LEN + ADD            /* compute total length in bits, */
      NEW = NEW + ADD            /* note NEW bits for final loop, */
      ADD = 448 - ADD            /* pad to length 448 modulo 512  */
      if ADD <= 0 then  ADD = ADD + 512
      BIN = b2x( BIN || left( 1, ADD, 0 ))
      MSG = MSG || x2c( BIN ) || reverse( x2c( d2x( LEN, 16 )))
      NEW = NEW + ADD + 64       /* reverse little endian length, */
      LEN = 'EOF'                /* using 16 * 4 = 512 - 448 bits */
   end
   call trace 'O' ;  trace 'N'   /* disable interactive MD5 trace */

   do N = 1 to NEW / 512         /* for MSG with N * 512 NEW bits */
      A = x2c( A )   ;  AA = A   ;  B = x2c( B )   ;  BB = B
      C = x2c( C )   ;  CC = C   ;  D = x2c( D )   ;  DD = D
      K = N * 64 - 63            /* fetch next 64 * 8 = 512 bits, */
      do J = 0 to 15             /* 512 = 16 * 32 bits to decimal */
         M.J = c2d( reverse( substr( MSG, K + J * 4, 4 )))
      end J

      A = MD5.1( A, B, C, D,  7, M.0  + 3614090360 )  /*  1 */
      D = MD5.1( D, A, B, C, 12, M.1  + 3905402710 )  /*  2 */
      C = MD5.1( C, D, A, B, 17, M.2  +  606105819 )  /*  3 */
      B = MD5.1( B, C, D, A, 22, M.3  + 3250441966 )  /*  4 */
      A = MD5.1( A, B, C, D,  7, M.4  + 4118548399 )  /*  5 */
      D = MD5.1( D, A, B, C, 12, M.5  + 1200080426 )  /*  6 */
      C = MD5.1( C, D, A, B, 17, M.6  + 2821735955 )  /*  7 */
      B = MD5.1( B, C, D, A, 22, M.7  + 4249261313 )  /*  8 */
      A = MD5.1( A, B, C, D,  7, M.8  + 1770035416 )  /*  9 */
      D = MD5.1( D, A, B, C, 12, M.9  + 2336552879 )  /* 10 */
      C = MD5.1( C, D, A, B, 17, M.10 + 4294925233 )  /* 11 */
      B = MD5.1( B, C, D, A, 22, M.11 + 2304563134 )  /* 12 */
      A = MD5.1( A, B, C, D,  7, M.12 + 1804603682 )  /* 13 */
      D = MD5.1( D, A, B, C, 12, M.13 + 4254626195 )  /* 14 */
      C = MD5.1( C, D, A, B, 17, M.14 + 2792965006 )  /* 15 */
      B = MD5.1( B, C, D, A, 22, M.15 + 1236535329 )  /* 16 */

      A = MD5.2( A, B, C, D,  5, M.1  + 4129170786 )  /* 17 */
      D = MD5.2( D, A, B, C,  9, M.6  + 3225465664 )  /* 18 */
      C = MD5.2( C, D, A, B, 14, M.11 +  643717713 )  /* 19 */
      B = MD5.2( B, C, D, A, 20, M.0  + 3921069994 )  /* 20 */
      A = MD5.2( A, B, C, D,  5, M.5  + 3593408605 )  /* 21 */
      D = MD5.2( D, A, B, C,  9, M.10 +   38016083 )  /* 22 */
      C = MD5.2( C, D, A, B, 14, M.15 + 3634488961 )  /* 23 */
      B = MD5.2( B, C, D, A, 20, M.4  + 3889429448 )  /* 24 */
      A = MD5.2( A, B, C, D,  5, M.9  +  568446438 )  /* 25 */
      D = MD5.2( D, A, B, C,  9, M.14 + 3275163606 )  /* 26 */
      C = MD5.2( C, D, A, B, 14, M.3  + 4107603335 )  /* 27 */
      B = MD5.2( B, C, D, A, 20, M.8  + 1163531501 )  /* 28 */
      A = MD5.2( A, B, C, D,  5, M.13 + 2850285829 )  /* 29 */
      D = MD5.2( D, A, B, C,  9, M.2  + 4243563512 )  /* 30 */
      C = MD5.2( C, D, A, B, 14, M.7  + 1735328473 )  /* 31 */
      B = MD5.2( B, C, D, A, 20, M.12 + 2368359562 )  /* 32 */

      A = MD5.3( A, B, C, D,  4, M.5  + 4294588738 )  /* 33 */
      D = MD5.3( D, A, B, C, 11, M.8  + 2272392833 )  /* 34 */
      C = MD5.3( C, D, A, B, 16, M.11 + 1839030562 )  /* 35 */
      B = MD5.3( B, C, D, A, 23, M.14 + 4259657740 )  /* 36 */
      A = MD5.3( A, B, C, D,  4, M.1  + 2763975236 )  /* 37 */
      D = MD5.3( D, A, B, C, 11, M.4  + 1272893353 )  /* 38 */
      C = MD5.3( C, D, A, B, 16, M.7  + 4139469664 )  /* 39 */
      B = MD5.3( B, C, D, A, 23, M.10 + 3200236656 )  /* 40 */
      A = MD5.3( A, B, C, D,  4, M.13 +  681279174 )  /* 41 */
      D = MD5.3( D, A, B, C, 11, M.0  + 3936430074 )  /* 42 */
      C = MD5.3( C, D, A, B, 16, M.3  + 3572445317 )  /* 43 */
      B = MD5.3( B, C, D, A, 23, M.6  +   76029189 )  /* 44 */
      A = MD5.3( A, B, C, D,  4, M.9  + 3654602809 )  /* 45 */
      D = MD5.3( D, A, B, C, 11, M.12 + 3873151461 )  /* 46 */
      C = MD5.3( C, D, A, B, 16, M.15 +  530742520 )  /* 47 */
      B = MD5.3( B, C, D, A, 23, M.2  + 3299628645 )  /* 48 */

      A = MD5.4( A, B, C, D,  6, M.0  + 4096336452 )  /* 49 */
      D = MD5.4( D, A, B, C, 10, M.7  + 1126891415 )  /* 50 */
      C = MD5.4( C, D, A, B, 15, M.14 + 2878612391 )  /* 51 */
      B = MD5.4( B, C, D, A, 21, M.5  + 4237533241 )  /* 52 */
      A = MD5.4( A, B, C, D,  6, M.12 + 1700485571 )  /* 53 */
      D = MD5.4( D, A, B, C, 10, M.3  + 2399980690 )  /* 54 */
      C = MD5.4( C, D, A, B, 15, M.10 + 4293915773 )  /* 55 */
      B = MD5.4( B, C, D, A, 21, M.1  + 2240044497 )  /* 56 */
      A = MD5.4( A, B, C, D,  6, M.8  + 1873313359 )  /* 57 */
      D = MD5.4( D, A, B, C, 10, M.15 + 4264355552 )  /* 58 */
      C = MD5.4( C, D, A, B, 15, M.6  + 2734768916 )  /* 59 */
      B = MD5.4( B, C, D, A, 21, M.13 + 1309151649 )  /* 60 */
      A = MD5.4( A, B, C, D,  6, M.4  + 4149444226 )  /* 61 */
      D = MD5.4( D, A, B, C, 10, M.11 + 3174756917 )  /* 62 */
      C = MD5.4( C, D, A, B, 15, M.2  +  718787259 )  /* 63 */
      B = MD5.4( B, C, D, A, 21, M.9  + 3951481745 )  /* 64 */

      A = d2x( c2d( AA ) + c2d( A ), 8 )
      B = d2x( c2d( BB ) + c2d( B ), 8 )
      C = d2x( c2d( CC ) + c2d( C ), 8 )
      D = d2x( c2d( DD ) + c2d( D ), 8 )
   end N

   if LEN = 'EOF' then  do       /* return lower case c2x( hash ) */
      MSG = reverse( x2c( D || C || B || A ))
      return translate( c2x( MSG ), 'abcdef', 'ABCDEF' )
   end                           /* caller uses x2c for real hash */
   else  return A B C D LEN BIN  /* return an updated MD5 context */

MD5.1 :  procedure               /* function used in MD5 round 1: */
   parse arg A, B, C, D, S, M
   C = bitor( bitand( B, C ), bitand( D, bitxor( B, 'FFFFFFFF'x )))
   signal MD5..                  /* = return MD5..(), common part */

MD5.2 :  procedure               /* function used in MD5 round 2: */
   parse arg A, B, C, D, S, M
   C = bitor( bitand( B, D ), bitand( C, bitxor( D, 'FFFFFFFF'x )))
   signal MD5..                  /* = return MD5..(), common part */

MD5.3 :  procedure               /* function used in MD5 round 3: */
   parse arg A, B, C, D, S, M
   C = bitxor( B, bitxor( C, D ))
   signal MD5..                  /* = return MD5..(), common part */

MD5.4 :  procedure               /* function used in MD5 round 4: */
   parse arg A, B, C, D, S, M
   C = bitxor( C, bitor( B, bitxor( D, 'FFFFFFFF'x )))
MD5.. :                          /* common part incl. S rotation: */
   C = x2b( d2x( c2d( A ) + c2d( C ) + M, 8 ))
   C = b2x( right( C || left( C, S ), 32 ))
   return x2c( d2x( x2d( C ) + c2d( B ), 8 ))
