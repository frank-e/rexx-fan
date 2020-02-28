# rexx-fan
*Stand-alone Rexx tools: ooRexx or Regina not limited to Windows NT*

[Rexx](https://en.wikipedia.org/wiki/Rexx) is a script language used by IBM operating systems and related products, e.g., [XEDIT](https://en.wikipedia.org/wiki/XEDIT), PC DOS and OS/2. Rexx has been ported to other platforms including Windows and Linux. Rexx is used as a macro language in, e.g., the XEDIT clones Kedit and [THE](https://en.wikipedia.org/wiki/The_Hessling_Editor).

As a macro language Rexx could be compared with [Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language)) or [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)), and as a programming language Rexx could be compared with [AWK](https://en.wikipedia.org/wiki/AWK) or [Python](https://en.wikipedia.org/wiki/Python_(programming_language)). Classic Rexx influenced [NetRexx](https://en.wikipedia.org/wiki/NetRexx), a dialect for the Java virtual machine, and [ooRexx](https://en.wikipedia.org/wiki/Object_REXX), an object oriented extension.

The scripts in this repo are supposed to work in command line windows (**cmd.exe** shells) on Windows 2000 or later with *ooRexx* or *Regina*, and as long as they do not use special features such as hardlinks they could still/also work on OS/2 or Linux. Untested, check the usual suspects such as backslashes or semicolons instead of slashes or colons on Linux.


1. **cmpdel** and **cmplink**: Compare directory trees SRC and DST, **del**ete or hard**link** identical SRC files.
2. **imm** and **say**: Emulate KEDIT command *imm* or Rexx instruction *say* for one-line scripts or expressions.
2. **md5**: [MD5](https://en.wikipedia.org/wiki/MD5) test suite 2.1 for test vectors in various IETF RFCs, replacing WayBack [2.0](https://web.archive.org/web/20120918193421/http://omniplex.om.funpic.de/src/md5.cmd). Cf. [RFC 6151](https://tools.ietf.org/html/rfc6151).
2. **rxtime**: Measure the runtime of a specified command. 
2. **utf-8**: [UTF-8](https://en.wikipedia.org/wiki/UTF-8) de-/en-coders of OEM codepages 437, 819, 858, 878, 923, and 1252 (incl. test suite).
2. **utf-tab**: Show magic codepoints for UTF16-BE, UTF16-LE, UTF-8, [UTF-4](https://web.archive.org/web/20110813010254/http://omniplex.om.funpic.de/home/test/utf-4.xml), and UTF-1.
2. **which**: Oddly on Windows an ordinary **.bat** or rather **.cmd** script would be seriously tricky.
2. **ygrep**: Only a **findstr.exe** wrapper for NT, I'm used to **fgrep** or my (lost) OS/2 *ygrep.cmd*.
