;InnoSetupVersion=4.2.6

[Setup]
AppName=iDbg
AppVerName=iDbg v0.04
DefaultDirName=c:\iDefense\iDbg\
DefaultGroupName=iDbg
OutputBaseFilename=iDbg_setup
OutputDir=./

[Files]
Source: ./dependancy\olly.dll; DestDir: {win}
Source: ./dependancy\crashmon2.dll; DestDir: {win}
Source: ./\iDbg.dll; DestDir: {app}; Flags: regserver
Source: ./dependancy\spSubclass.dll; DestDir: {win}; Flags: regserver
Source: ./dependancy\TLBINF32.DLL; DestDir: {win}; Flags: regserver
Source: ./\test2.exe; DestDir: {app}
Source: ./\winmain.dll; DestDir: {app}
Source: ./\crashmon2\crashmon.dsw; DestDir: {app}\crashmon2
Source: ./\crashmon2\pebModules.cpp; DestDir: {app}\crashmon2
Source: ./\crashmon2\safeCoCreate.cpp; DestDir: {app}\crashmon2
Source: ./\crashmon2\stackwalk.cpp; DestDir: {app}\crashmon2
Source: ./\crashmon2\TLBINF32.h; DestDir: {app}\crashmon2
Source: ./\crashmon2\symload.cpp; DestDir: {app}\crashmon2
Source: ./\crashmon2\crashmon.dsp; DestDir: {app}\crashmon2
Source: ./\crashmon2\crashmon.cpp; DestDir: {app}\crashmon2
Source: ./\crashmon2\crashmon.def; DestDir: {app}\crashmon2
Source: ./\crashmon2\crashmon.opt; DestDir: {app}\crashmon2
Source: ./\iDbg\iDdbg.vbw; DestDir: {app}\iDbg
Source: ./\iDbg\CBreakPoint.cls; DestDir: {app}\iDbg
Source: ./\iDbg\CModule.cls; DestDir: {app}\iDbg
Source: ./\iDbg\CException.cls; DestDir: {app}\iDbg
Source: ./\iDbg\CDebugger.cls; DestDir: {app}\iDbg
Source: ./\iDbg\crashmon.ilk; DestDir: {app}\iDbg
Source: ./\iDbg\CProcessInfo.cls; DestDir: {app}\iDbg
Source: ./\iDbg\frmLibDebug.frm; DestDir: {app}\iDbg
Source: ./\iDbg\modDllInject.bas; DestDir: {app}\iDbg
Source: ./\iDbg\modPEParse.bas; DestDir: {app}\iDbg
Source: ./\iDbg\Module1.bas; DestDir: {app}\iDbg
Source: ./\iDbg\frmDummy.frm; DestDir: {app}\iDbg
Source: ./\iDbg\CImport.cls; DestDir: {app}\iDbg
Source: ./\iDbg\CLoadExports.cls; DestDir: {app}\iDbg
Source: ./\iDbg\CLoadImports.cls; DestDir: {app}\iDbg
Source: ./\iDbg\CPEOffsets.cls; DestDir: {app}\iDbg
Source: ./\iDbg\CExport.cls; DestDir: {app}\iDbg
Source: ./\iDbg\iDbg.vbp; DestDir: {app}\iDbg
Source: ./\iDbg\CProcess.cls; DestDir: {app}\iDbg
Source: ./\iDbg\fmLibDebug2.frm; DestDir: {app}\iDbg
Source: ./\iDbg\iDbg.vbw; DestDir: {app}\iDbg
Source: ./\iDbg\VBA1.tmp; DestDir: {app}\iDbg
Source: ./\iDbg\frmListProcess.frm; DestDir: {app}\iDbg
Source: ./\iDbg\CContext.cls; DestDir: {app}\iDbg
Source: ./\Samples\VB6\Automated_Debugging\Project1.vbw; DestDir: {app}\Samples\VB6\Automated_Debugging
Source: ./\Samples\VB6\Automated_Debugging\fmLibDebug2.frm; DestDir: {app}\Samples\VB6\Automated_Debugging
Source: ./\Samples\VB6\Automated_Debugging\Project1.vbp; DestDir: {app}\Samples\VB6\Automated_Debugging
Source: ./\Samples\VB6\Automated_Debugging\frmLibDebug.frm; DestDir: {app}\Samples\VB6\Automated_Debugging
Source: ./\Samples\VB6\Debugger_UI\Project1.vbp; DestDir: {app}\Samples\VB6\Debugger_UI
Source: ./\Samples\VB6\Debugger_UI\CCache.cls; DestDir: {app}\Samples\VB6\Debugger_UI
Source: ./\Samples\VB6\Debugger_UI\Project1.vbw; DestDir: {app}\Samples\VB6\Debugger_UI
Source: ./\Samples\VB6\Debugger_UI\Form1.frm; DestDir: {app}\Samples\VB6\Debugger_UI
Source: ./\Samples\VB6\Debugger_UI\Module1.bas; DestDir: {app}\Samples\VB6\Debugger_UI
Source: ./\Samples\VB6\Debugger_UI\Group1.vbg; DestDir: {app}\Samples\VB6\Debugger_UI
Source: ./\Samples\PHP5\ReadMe.txt; DestDir: {app}\Samples\PHP5
Source: ./\Samples\PHP5\IDbg.php; DestDir: {app}\Samples\PHP5
Source: ./\Samples\C#\README.txt; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\WindowsApplication1.csproj; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\Form1.cs; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\Form1.resx; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\AssemblyInfo.cs; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\App.ico; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\WindowsApplication1.csproj.user; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\WindowsApplication1.sln; DestDir: {app}\Samples\C#
Source: ./\Samples\C#\WindowsApplication1.suo; DestDir: {app}\Samples\C#
Source: ./\test2\test.vcproj; DestDir: {app}\test2
Source: ./\test2\stdafx.h; DestDir: {app}\test2
Source: ./\test2\stdafx.cpp; DestDir: {app}\test2
Source: ./\test2\test.cpp; DestDir: {app}\test2
Source: ./\test2\test.sln; DestDir: {app}\test2
Source: ./\test2\test.suo; DestDir: {app}\test2
Source: ./\test2\test.ncb; DestDir: {app}\test2
Source: ./\Readme.txt; DestDir: {app}
Source: ./\olly_dll\asmserv.c; DestDir: {app}\olly_dll
Source: ./\olly_dll\assembl.c; DestDir: {app}\olly_dll
Source: ./\olly_dll\disasm.c; DestDir: {app}\olly_dll
Source: ./\olly_dll\disasm.h; DestDir: {app}\olly_dll
Source: ./\olly_dll\gpl.wri; DestDir: {app}\olly_dll
Source: ./\olly_dll\olly.def; DestDir: {app}\olly_dll
Source: ./\olly_dll\olly.dsp; DestDir: {app}\olly_dll
Source: ./\olly_dll\olly.dsw; DestDir: {app}\olly_dll
Source: ./\olly_dll\readme.htm; DestDir: {app}\olly_dll
Source: ./\olly_dll\Readme.txt; DestDir: {app}\olly_dll

[Dirs]
Name: {app}\crashmon2
Name: {app}\crashmon2\Debug
Name: {app}\iDbg
Name: {app}\Samples
Name: {app}\Samples\VB6
Name: {app}\Samples\VB6\Automated_Debugging
Name: {app}\Samples\VB6\Debugger_UI
Name: {app}\Samples\PHP5
Name: {app}\Samples\C#
Name: {app}\test2
Name: {app}\olly_dll

[Run]
Filename: {app}\Readme.txt; Description: View readme file now?; Flags: shellexec postinstall

[Icons]
Name: {group}\Source\iDbg.vbp; Filename: {app}\iDbg\iDbg.vbp; WorkingDir: {app}\iDbg
Name: {group}\Source\crashmon2.dsw; Filename: {app}\crashmon2\crashmon2.dsw; WorkingDir: {app}\crashmon2\
Name: {group}\Uninstall.exe; Filename: {app}\unins000.exe; WorkingDir: {app}
Name: {group}\Samples\VB6_Debugger_UI.vbp; Filename: {app}\Samples\VB6\Debugger_UI\Project1.vbp
Name: {group}\Samples\VB6_Tracer.vbp; Filename: {app}\Samples\VB6\Automated_Debugging\Project1.vbp
Name: {group}\Samples\C#_Readme.txt; Filename: {app}\Samples\C#\README.txt
Name: {group}\Samples\C#_Tracer.sln; Filename: {app}\\Samples\C#\WindowsApplication1.sln
Name: {group}\Samples\PHP_Readme.txt; Filename: {app}\Samples\PHP5\ReadMe.txt
Name: {group}\Samples\PHP5_Tracer.php; Filename: notepad.exe; Parameters: {app}\Samples\PHP5\iDbg.php
Name: {group}\Readme.txt; Filename: {app}\Readme.txt
Name: {group}\Source\test2.sln; Filename: {app}\test2\test.sln
Name: {group}\Source\olly_dll.dsw; Filename: {app}\olly_dll\olly.dsw

[CustomMessages]
NameAndVersion=%1 version %2
AdditionalIcons=Additional icons:
CreateDesktopIcon=Create a &desktop icon
CreateQuickLaunchIcon=Create a &Quick Launch icon
ProgramOnTheWeb=%1 on the Web
UninstallProgram=Uninstall %1
LaunchProgram=Launch %1
AssocFileExtension=&Associate %1 with the %2 file extension
AssocingFileExtension=Associating %1 with the %2 file extension...
