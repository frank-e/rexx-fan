# rexx-fan
*Stand-alone Rexx tools: ooRexx or Regina not limited to Windows NT*

[Rexx][R] is a script language used under IBM operating systems and by related products, e.g., [XEDIT](https://en.wikipedia.org/wiki/XEDIT), PC DOS and OS/2. Rexx has been ported to other platforms including Windows and Linux. Rexx is used as a macro language in, e.g., the XEDIT clones Kedit and [THE](https://en.wikipedia.org/wiki/The_Hessling_Editor).

As a macro language Rexx could be compared with [Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language)) or [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)), and as a programming language Rexx could be compared with [AWK](https://en.wikipedia.org/wiki/AWK) or [Python](https://en.wikipedia.org/wiki/Python_(programming_language)). Classic Rexx influenced [NetRexx](https://en.wikipedia.org/wiki/NetRexx), a dialect for the Java Virtual Machine, and [ooRexx](https://en.wikipedia.org/wiki/Object_REXX), an object oriented extension.

The programs in this repo are supposed to work in command line windows (`cmd.exe` shells) on Windows 2000 or later with *[ooRexx](https://www.oorexx.org/about.html)* or *[Regina](https://sourceforge.net/projects/regina-rexx/)*, and as long as they do not use special features such as hardlinks they could still/also work on OS/2 or Linux. Please check the usual suspects such as backslashes or semicolons instead of slashes or colons on Linux.

[![Classic Rexx, Regina, ooRexx](/miscellany/rexx.png)](http://home.rexxla.org/)

1. **[7b](https://github.com/frank-e/rexx-fan/blob/master/7b.rex "7b.rex")**: binary to 7b-format (7-bit) codec + spec., claiming to be *better* than B64, for giggles.
2. **[adhrs](https://github.com/frank-e/rexx-fan/blob/master/adhrs.rex "adhrs.rex")**: Count unusual `ADHRS` attribute combos for directories.
2. **[bocu](https://github.com/frank-e/rexx-fan/blob/master/bocu.rex "bocu.rex")**: BOCU-1 + UTF-8/7/4/1 codec test suite (2010 bocu.rex = 2006 [bocu.cmd](https://web.archive.org/web/20130522122606/http://omniplex.om.funpic.de/src/bocu.cmd "bocuc.cmd")).
2. **[checkmbr](https://github.com/frank-e/rexx-fan/blob/master/checkmbr.rex "checkmbr.rex")**: `\\.\PHYSICALDRIVE`n, disk image ([MBR][M]), or unpartitioned [VBR](https://en.wikipedia.org/wiki/Volume_boot_record) floppy image.
2. **[cmpdel](https://github.com/frank-e/rexx-fan/blob/master/cmpdel.rex "cmpdel.rex")** and **[cmplink](https://github.com/frank-e/rexx-fan/blob/master/cmplink.rex "cmplink.rex")**: Compare directory trees SRC and DST, **del**ete or hard**link** identical SRC files.
2. **[countext](https://github.com/frank-e/rexx-fan/blob/master/countext.rex "countext.rex")**: Count used file **ext**ensions in a given sub-directory tree.
2. **[ff](https://github.com/frank-e/rexx-fan/blob/master/ff.rex "ff.rex")**: *FileFind*, slow as the Windows search unless directories are cached. [PC DOS 7](https://en.wikipedia.org/wiki/IBM_PC_DOS#7.00) [Norton](https://en.wikipedia.org/wiki/Norton_Utilities#Version_2.0) nostalgy.
2. **[imm](https://github.com/frank-e/rexx-fan/blob/master/imm.rex "imm.rex")** and **[say](https://github.com/frank-e/rexx-fan/blob/master/say.rex "say.rex")**: Emulate KEDIT command `imm` or [Rexx][R] `say` for one-line scripts or expressions.
2. **[md5](https://github.com/frank-e/rexx-fan/blob/master/md5.rex "md5.rex")**: [MD5](https://en.wikipedia.org/wiki/MD5) test suite 2.1 for test vectors in various IETF RFCs, replacing *xyzzy* [2.0][5], cf. [RFC 6151](https://tools.ietf.org/html/rfc6151).
2. **[pi](https://github.com/frank-e/rexx-fan/blob/master/pi.rex "pi.rex")**: Comparison of 42 Pi algorithms (2006, was [pi.cmd](https://web.archive.org/web/20020719190406/http://frank.ellermann.bei.t-online.de:80/src/pi.cmd "Pi.cmd") in 2002).
2. **[rexxfat](https://github.com/frank-e/rexx-fan/blob/master/rexxfat.rex "rexxfat.rex")**: Create [FAT12/16/32](https://en.wikipedia.org/wiki/File_Allocation_Table#Development) superfloppy ([no MBR][M]) or [VHD][V] (MBR) image files, supports [512e](https://en.wikipedia.org/wiki/Advanced_Format#512e).
2. **[rexxsort](https://github.com/frank-e/rexx-fan/blob/master/rexxsort.rex "rexxsort.rex")**: See [manual][3] on *xyzzy*. The `KWIK` in [ygrep.rex](../master/ygrep.rex) etc. is a copy of the *treble QSort* here.
2. **[rxclip](https://github.com/frank-e/rexx-fan/blob/master/rxclip.rex "rxclip.rex")**: Copy to or paste from the clipboard, requires *ooRexx* with *RxWinSys.dll* `WSClipBoard()`.
2. **[rxpause](https://github.com/frank-e/rexx-fan/blob/master/rxpause.rex "rxpause.rex")**: Inspired by NT `timeout.exe` + ooRexx `rexxpaws.exe`.
2. **[rxshell](https://github.com/frank-e/rexx-fan/blob/master/rxshell.rex "rxshell.rex")** and the required **[-rxshell](https://github.com/frank-e/rexx-fan/blob/master/-rxshell.rex "-rxshell.rex")** constants: *RxShell 3.3* with a vintage 2010 [manual][6] on *xyzzy*.
2. **[rxtime](https://github.com/frank-e/rexx-fan/blob/master/rxtime.rex "rxtime.rex")**: Measure the runtime of a specified command.
2. **[sparsify](https://github.com/frank-e/rexx-fan/blob/master/sparsify.rex "sparsify.rex")**: NTFS sparse files with `fsutil.exe` require admin rights (incl. self test).
2. **[stackget](https://github.com/frank-e/rexx-fan/blob/master/stackget.rex "stackget.rex")**: Emulate Quercus [REXX/Personal](http://www.edm2.com/index.php/Personal_REXX) `stackget.exe` (only *ooRexx*, not yet ready for *Regina*).
2. **[svg2tiny](https://github.com/frank-e/rexx-fan/blob/master/svg2tiny.rex "svg2tiny.rex")** and **[svg2true](https://github.com/frank-e/rexx-fan/blob/master/svg2true.rex "svg2true.rex")**: Try to convert [SVG](https://commons.wikimedia.org/wiki/Help:SVG) to valid [SVG tiny or basic 1.1](https://www.w3.org/TR/2003/REC-SVGMobile-20030114/) with [rsvg-convert.exe](https://sourceforge.net/projects/tumagcc/).
2. **[today](https://github.com/frank-e/rexx-fan/blob/master/today.rex "today.rex")**: List all files changed today `1 *`, *tomorrow* `0 *`, new videos this week `7 *.webm`, etc.
2. **[utf-8](https://github.com/frank-e/rexx-fan/blob/master/utf-8.rex "utf-8.rex")**: [UTF-8][U] de-/en-coders of OEM codepages [437](https://en.wikipedia.org/wiki/Code_page_437 "DOS US"), [819](https://en.wikipedia.org/wiki/ISO/IEC_8859-1 "Latin-1"), [858][8], [878](https://en.wikipedia.org/wiki/KOI8-R "KOI8-R"), [923](https://en.wikipedia.org/wiki/ISO/IEC_8859-15 "Latin-9"), and [1252][9] (incl. test suite).
2. **[utf-tab](https://github.com/frank-e/rexx-fan/blob/master/utf-tab.rex "utf-tab.rex")**: Show magic codepoints for [UTF-16BE][B], UTF-16[LE](https://en.wikipedia.org/wiki/Endianness#Big-endian "Little Endian"), [UTF-8][U], [UTF-4][4], and [UTF-1](https://en.wikipedia.org/wiki/UTF-1 "Unicode Transformation Format modulo 256-66=190, preserving 66 control char.s").
2. **[VHDclone](https://github.com/frank-e/rexx-fan/blob/master/VHDclone.rex "VHDclone.rex")**: Copy static [VHD][V] with new UUID, timestamp, and creator, faster than `diskpart.exe`.
2. **[which](https://github.com/frank-e/rexx-fan/blob/master/which.rex "which.rex")**: Oddly on Windows an ordinary **.bat** or rather **.cmd** script would be seriously tricky.
2. **[xlat](https://github.com/frank-e/rexx-fan/blob/master/xlat.rex "xlat.rex")**: Convert [UTF-32](https://en.wikipedia.org/wiki/UTF-32), [UTF-16][B], or [UTF-8][U] to [UTF-4][4], or convert UTF-4 to UTF-8. Other UTFs rejected.
2. **[xmlcheck](https://github.com/frank-e/rexx-fan/blob/master/xmlcheck.rex "xmlcheck.rex")**: Check that an XML file is well-formed, report nesting level, ignore DTD subset details.
2. **[ygrep](https://github.com/frank-e/rexx-fan/blob/master/ygrep.rex "ygrep.rex")**: A `findstr.exe` wrapper for NT, the author is used to `fgrep` or an old OS/2 `ygrep.cmd`.

The name of this repo matches [rexx-fan](https://sourceforge.net/u/rexx-fan/profile) on [SF](https://en.wikipedia.org/wiki/SourceForge "SourceForge"). For older versions of these programs try *xyzzy* [2005][0], [2011][1], or [2013][2].

[![PC DOS 7.1 REXXSAA in a very slow VM](/miscellany/pc%20dos%207.1%20(vm)%20rexxcps.png)](http://speleotrove.com/misc/rexxcpslist.html)

## Version 0.0 ##
*Download [v0.0.zip](https://github.com/frank-e/rexx-fan/archive/v0.0.zip "2020-03-21") or [tarball](https://github.com/frank-e/rexx-fan/archive/v0.0.tar.gz "2020-03-21")*

[M]: https://en.wikipedia.org/wiki/Master_boot_record (Master Boot Record)
[B]: https://en.wikipedia.org/wiki/UTF-16 (Unicode Transformation Format in 16 bits)
[R]: https://en.wikipedia.org/wiki/Rexx (classic Rexx)
[U]: https://en.wikipedia.org/wiki/UTF-8 (Unicode Transformation Format in 8 bits)
[V]: https://en.wikipedia.org/wiki/VHD_(file_format) (Virtual Hard Disk)
[0]: https://web.archive.org/web/20050505221501/http://frank.ellermann.bei.t-online.de/sources.htm#General (purl.net/xyzzy/sources.htm)
[1]: https://web.archive.org/web/20110102232137/http://home.claranet.de/xyzzy/sources.htm#General (purl.net/xyzzy/sources.htm)
[2]: https://purl.net/xyzzy/sources.htm#General (purl.net/xyzzy/sources)
[3]: https://purl.net/xyzzy/rexxsort.htm (purl.net/xyzzy/rexxsort)
[4]: https://purl.net/xyzzy/home/test/utf-4.xml (Unicode Transformation Format in 4 bits, Latin-1 friendly)
[5]: https://purl.net/xyzzy/src/md5.cmd (purl.net/xyzzy/src/md5)
[6]: https://purl.net/xyzzy/src/rxshell.htm (purl.net/xyzzy/src/rxshell)
[8]: https://purl.net/xyzzy/ibm850.htm#skipxml (PC-Multilingual-850+euro)
[9]: https://purl.net/xyzzy/ibm850.htm#cp1004 (windows-1252)
