
iDbg

ActiveX Debugger/Tracer library which can be used from any COM aware language.

Documentation to come. See sample code for demos on how to use it.

Sample Source provided for: VB6, PHP5, and C#

This package is a late beta release. 
Class prototypes should be pretty stable by now.

Binary compatability on the interfaces has not been set yet so GUIDs and
prototypes may could change.

For development and testing apps this should not really be a problem.
Interface changes are not expected to be anything major at this point.


iDbg consists of the following binaries:
-------------------------------------------
iDbg.dll       - main debugger interface (VB6 ActiveX Object)
crashmon2.dll  - creates thread for debug loop (taken from comraider) (VC std dll)
olly.dll       - disasm library - code taken from oleh's ollydbg free source source on web (VC std dll)
spSubclass.dll - free subclassing library from Sandsprite.com (VB6 ActiveX Object)



Sample projects:
------------------------------------------
test2.exe     -  debugee sample - exploitable strcpy argv[1]
winmain.dll   -  test injectable library with msgbox in winmain

Samples\PHP5\                   - test tracer for test2.exe
Samples\C#                      - test tracer for test2.exe
Samples\VB6\Automated_Debugging - test tracer for test2.exe
samples\VB6\Debugger_UI         - very simple front end for the iDbg library (test ui)



ChangeLog
-------------------------------------------

Changes since beta build:

 Read/Modify register only take one arg now
 SetBreakPoint now takes argument OneShot as bool
 changed lots of args to byval so you dont need to declare varaible and use ref to call (C#)
 Continue now takes an argument for continue type
 updated example program to test all these features.
 removed initilize method so could be used from php without window handle
 Added DontHandle method which defaults to DBG_EXCEPTION_NOT_HANDLED for php
 Added PHP script sample

 Added events
	 - DeVMessage(function, msg)
	 - SingleStep(except as CException)

 added methods
	 - InjectDll
	 - stepinto
	 - stepover
	 - SetMultiBPX
	 - SetModuleBpx
	 - AttachProcess
 
 BugFixs - breakpoints are now reset after being hit unless it was created as a oneshot
         - can now single step after bpx


 Bugs:
	 - you may receive unexpected single step events after bpx (its doing it to restore bpx)


 existing code should not need to heavy of mods to use this version
 just some tweaks that you will clearly see from errors in compile window.

  if you want to test the injectdll use winmain.dll which will pop up
 msgboxes in its dllmain proc.











