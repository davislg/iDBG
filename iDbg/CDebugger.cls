VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CDebugger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'License:   GPL
'Copyright: 2005 iDefense a Verisign Company
'Site:      http://labs.idefense.com
'
'Author:  David Zimmer <david@idefense.com, dzzie@yahoo.com>
'
'         This program is free software; you can redistribute it and/or modify it
'         under the terms of the GNU General Public License as published by the Free
'         Software Foundation; either version 2 of the License, or (at your option)
'         any later version.
'
'         This program is distributed in the hope that it will be useful, but WITHOUT
'         ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
'         FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
'         more details.
'
'         You should have received a copy of the GNU General Public License along with
'         this program; if not, write to the Free Software Foundation, Inc., 59 Temple
'         Place, Suite 330, Boston, MA 02111-1307 USA
'
'  Project based on the initial comraider CCrashmon class
'
'BUGS:
'  - you may receive extra single step events in ui from setapplicablebreakpoints
'
'
'
'
' TODO:
'       hardware breakpoints
'       memory snapshots


Option Explicit

Event ReadyToRun()
Event Exception(except As CException)
Event SingleStep(except As CException)
Event UserBreakpoint(except As CException)
Event Terminate()
Event DllLoad(path As String, base As Long, size As Long)
Event ThreadCreate(threadID As Long, startAddress As Long)
Event ThreadDestroy(threadID As Long, exitCode As Long)
Event DevMessage(func As String, msg As String)
Event DebugString(msg As String)


'Event ApiLogMsg(msg As String)

Dim WithEvents subclass As clsSubClass
Attribute subclass.VB_VarHelpID = -1
Dim WithEvents tmrUnBlock As CTimer
Attribute tmrUnBlock.VB_VarHelpID = -1

Enum DebugDecisions
    DBG_CONTINUE = &H10002
    DBG_TERMINATE_THREAD = &H40010003
    DBG_TERMINATE_PROCESS = &H40010004
    DBG_CONTROL_C = &H40010005
    DBG_CONTROL_BREAK = &H40010008
    DBG_EXCEPTION_NOT_HANDLED = &H80010001
End Enum

Private Declare Function Disasm Lib "olly.dll" (ByRef src As Byte, ByVal srcsize As Long, ByVal ip As Long, Disasm As t_Disasm, Optional disasmMode As Long = 4) As Long

Private Declare Function ActivePID Lib "crashmon2.dll" () As Long
Private Declare Sub GetErrorMessage Lib "crashmon2.dll" (ByVal buf500 As String)
Private Declare Function LaunchDebugedProcess Lib "crashmon2.dll" (ByVal filename As String) As Long
Private Declare Sub DebugContinue Lib "crashmon2.dll" Alias "Continue" (Optional ByVal decision As DebugDecisions = DBG_CONTINUE)
Private Declare Sub StopDebugger Lib "crashmon2.dll" ()
Private Declare Sub SetTargetHwnd Lib "crashmon2.dll" (ByVal hwnd As Long)
Private Declare Sub GetModuleListErrorMsg Lib "crashmon2.dll" (ByVal buf500 As String)
Private Declare Function GetModuleList Lib "crashmon2.dll" (ByVal lpfnCallBack As Long) As Long
Private Declare Sub GetStackWalkErrMsg Lib "crashmon2.dll" (ByVal buf500 As String)
Private Declare Function InitStackWalk Lib "crashmon2.dll" (ByVal lpfnCallBack As Long) As Long
Private Declare Sub GetCallStack Lib "crashmon2.dll" (ByVal hThread As Long, c As Any)
Private Declare Function GetTibForThread Lib "crashmon2.dll" (ByVal hThread As Long) As Long
Private Declare Function AttachDebugger Lib "crashmon2.dll" (ByVal pid As Long) As Long


Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Private Declare Function ReadProcessMemory Lib "kernel32" (ByVal hProcess As Long, ByVal lpBaseAddress As Any, lpBuffer As Byte, ByVal nSize As Long, lpNumberOfBytesWritten As Long) As Long
Private Declare Function CloseHandle Lib "kernel32" (ByVal hObject As Long) As Long
Private Declare Function OpenProcess Lib "kernel32" (ByVal dwDesiredAccess As Long, ByVal bInheritHandle As Long, ByVal dwProcessId As Long) As Long
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)
Private Declare Function GetThreadContext Lib "kernel32" (ByVal hThread As Long, lpContext As Any) As Long
Private Declare Function SetThreadContext Lib "kernel32" (ByVal hThread As Long, lpContext As Any) As Long
Private Declare Function IsBadReadPtr Lib "kernel32" (ByVal adr As Long, ByVal leng As Long) As Long
Private Declare Function CallAsm Lib "user32" Alias "CallWindowProcA" (ByRef lpBytes As Any, ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function WriteProcessMemory Lib "kernel32" (ByVal hProcess As Long, lpBaseAddress As Any, lpBuffer As Any, ByVal nSize As Long, lpNumberOfBytesWritten As Long) As Long

'Sym* Api
Private Declare Function GetSymbol Lib "crashmon2.dll" (ByVal offset As Long, ByVal name As String, ByVal decl As String, ByVal buflen As Long) As Long
Private Declare Function LoadModuleSymbols Lib "crashmon2.dll" (ByVal imgName As String, ByVal dllBase As Long, ByVal dllSize As Long) As Long
Private Declare Sub Cleanup Lib "crashmon2.dll" ()
Private Declare Function InitSearchPath Lib "crashmon2.dll" (ByVal path As String, ByVal hProcess As Long) As Long

Public LastEventAddress As Long
Public LastEventCode As Long
Public LoadedFile As String
Public ActiveThreadID As Long
Public Threads As New Collection
Public Modules As Collection
Public BreakPoints As Collection

Private Kernel32Base As Long
Private InternalRemoveBpx As Boolean
Private InternalSingleStep As Boolean
Private InternalActiveBp As CBreakPoint
Private InternalStepOver As Boolean
Private DebugDecision As Long
Private InternalSkipFirstResetCycle As Boolean 'user wants to single step dont reset bpx
Private isInitilized As Boolean

Private Events As New Collection
Private SkippedAttachBp As Boolean
Private ProcessInfo As CREATE_PROCESS_DEBUG_INFO
Private Const WM_COPYDATA = &H4A

Private Type COPYDATASTRUCT
    dwFlag As Long
    cbSize As Long
    lpData As Long
End Type

Private Type CREATE_THREAD_DEBUG_INFO
    hThread As Long
    lpThreadLocalBase As Long
    lpStartAddress As Long
End Type

Private Type DEBUG_EVENT
    dwDebugEventCode As DbgEvents
    dwProcessId As Long
    dwThreadId As Long
    Data(20) As Long 'vb does not support unions
End Type

Private Type EXCEPTION_DEBUG_INFO
    'Public Type EXCEPTION_RECORD
       ExceptionCode As DbgEvents
       ExceptionFlags As ExceptionFlags
       pExceptionRecord As Long
       ExceptionAddress As Long
       NumberParameters As Long
       ExceptionInformation(15) As Long
    'End Type
    dwFirstChance As Long
End Type

Private Type CREATE_PROCESS_DEBUG_INFO
    hFile As Long
    hProcess As Long
    hThread As Long
    lpBaseOfImage As Long
    dwDebugInfoFileOffset As Long
    nDebugInfoSize As Long
    lpThreadLocalBase As Long
    lpStartAddress As Long
    lpImageName As Long
    fUnicode As Integer
End Type

Private Type LOAD_DLL_DEBUG_INFO
    hFile As Long
    lpBaseOfDll As Long
    dwDebugInfoFileOffset As Long
    nDebugInfoSize As Long
    lpImageName As Long
    fUnicode As Integer
End Type

Private Type OUTPUT_DEBUG_STRING_INFO
    lpDebugStringData As Long
    fUnicode As Integer
    nDebugStringLength As Integer
End Type


Private Type sehRecord
    pNextRecord As Long
    vaHandler As Long
End Type

Private Type t_Disasm
  ip As Long
  dump As String * 256
  result As String * 256
  unused(1 To 308) As Byte
End Type

'Private Type DEBUG_OUTPUT_DEBUG_STRING_INFO
'    Header As DEBUG_EVENT_HEADER
'    lpDebugStringData As Long
'    fUnicode As Integer
'    nDebugStringLength As Integer
'End Type

Enum DbgEvents
        VC_THROW_SEH = &HE06D7363
        EXCEPTION_IN_PAGE_ERROR = &HC0000006
        EXCEPTION_NONCONTINUABLE_EXCEPTION = &HC0000025
        EXCEPTION_FLT_DENORMAL_OPERAND = &HC000008D
        EXCEPTION_FLT_INEXACT_RESULT = &HC000008F
        EXCEPTION_FLT_STACK_CHECK = &HC0000092
        EXCEPTION_FLT_UNDERFLOW = &HC0000093
        STATUS_WAIT_0 = &H0
        STATUS_ABANDONED_WAIT_0 = &H80
        STATUS_USER_APC = &HC0
        STATUS_TIMEOUT = &H102
        STATUS_PENDING = &H103
        STATUS_SEGMENT_NOTIFICATION = &H40000005
        STATUS_GUARD_PAGE_VIOLATION = &H80000001
        STATUS_NO_MEMORY = &HC0000017
        STATUS_CONTROL_C_EXIT = &HC000013A
        EXCEPTION_DEBUG_EVENT = 1
        EXCEPTION_DATATYPE_MISALIGNMENT = &H80000002
        EXCEPTION_SINGLE_STEP = &H80000004
        EXCEPTION_ACCESS_VIOLATION = &HC0000005
        EXCEPTION_BREAKPOINT = &H80000003
        EXCEPTION_ARRAY_BOUNDS_EXCEEDED = &HC000008C
        EXCEPTION_FLT_DIVIDE_BY_ZERO = &HC000008E
        EXCEPTION_FLT_INVALID_OPERATION = &HC0000090
        EXCEPTION_FLT_OVERFLOW = &HC0000091
        EXCEPTION_INT_DIVIDE_BY_ZERO = &HC0000094
        EXCEPTION_INT_OVERFLOW = &HC0000095
        EXCEPTION_ILLEGAL_INSTRUCTION = &HC000001D
        EXCEPTION_PRIV_INSTRUCTION = &HC0000096
        CREATE_THREAD_DEBUG_EVENT = 2
        CREATE_PROCESS_DEBUG_EVENT = 3
        EXIT_THREAD_DEBUG_EVENT = 4
        EXIT_PROCESS_DEBUG_EVENT = 5
        LOAD_DLL_DEBUG_EVENT = 6
        UNLOAD_DLL_DEBUG_EVENT = 7
        OUTPUT_DEBUG_STRING_EVENT = 8
End Enum







Enum ExceptionFlags
    EXCEPTION_CONTINUABLE = 0
    EXCEPTION_NONCONTINUABLE = 1   '\\ Noncontinuable exception
End Enum

Enum Registers
    edi
    Esi
    Ebx
    Edx
    Ecx
    Eax
    ebp
    eip
    esp
    EFlags
End Enum
 
Public SymbolPath As String
Public UseSymbols As Boolean

Private ModuleBpx As Collection 'so we can set breakpoints on dlls not loaded yet and they can be rebased wo err
Private exports As New CLoadExports
 
Sub About()
    
    Dim msg As String
    msg = "dzDbg v" & App.Major & "." & App.Minor & "." & App.Revision & _
          "\n\n" & _
          "Developer: David Zimmer (david@idefense.com, dzzie@yahoo.com)\n" & _
          "CopyRight: iDefense, a Verisign Company\n" & _
          "License: GPL\n" & _
          "Requires: spSubclass.dll, olly.dll, crashmon2.dll\n\n" & _
          "Additional Copyrights: GPL code in olly.dll is copyright Oleh Yuschuk\n"
          
    MsgBox Replace(msg, "\n", vbCrLf), vbInformation
    
End Sub
Function InjectDLL(ByVal dllPath As String) As Boolean
    Dim tmp() As String
    
    InjectDLL = modDllInject.InjectDLL(ActivePID, dllPath, -1, tmp)
    
    If Not InjectDLL Then
        RaiseEvent DevMessage("InjectDll", Join(tmp, vbCrLf))
    End If
    
End Function

Function ModuleAtVA(va As Long) As String
    Dim m As CModule
    For Each m In Modules
        If va >= m.base And va <= (m.base + m.size) Then
            ModuleAtVA = m.path
            Exit Function
        End If
    Next
End Function

Sub StepInto()
    SetSingleStep
    InternalSkipFirstResetCycle = True
    Continue
End Sub

Sub StepOver()
    Dim iLen As Long
    Dim nVa As Long
    
    InternalSkipFirstResetCycle = True
    
    If InStr(1, CurrentInstruction(iLen), "call", vbTextCompare) > 0 Then
        InternalStepOver = True 'this will trigger as singlestep event rather than bpx
        nVa = ReadRegister(eip) + iLen   'va of next instruction
        SetBreakPoint nVa, True
        Continue
    Else
        SetSingleStep
        Continue
    End If
    
End Sub

Function SelectProcess(ret_proc As CProcess) As Boolean
    Dim c As New Collection
    Dim p As New CProcessInfo
    On Error Resume Next
    Set c = p.GetRunningProcesses
    Set ret_proc = frmListProcess.SelectProcess(c)
    If Not ret_proc Is Nothing Then SelectProcess = True
End Function

Sub DbgDontHandle()
    Continue DBG_EXCEPTION_NOT_HANDLED
End Sub
 
Sub DbgContinue()
    Continue DBG_CONTINUE
End Sub

Sub Continue(Optional ByVal mode As DebugDecisions = DBG_CONTINUE)
    DebugDecision = mode
    tmrUnBlock.EnableTimer 10
End Sub

Property Get isDebugging() As Boolean
    isDebugging = (ActivePID > 0)
End Property

Private Function Initilize(ByVal hwnd As Long)
    
    If isInitilized Then Exit Function
    
    If hwnd = 0 Then hwnd = frmDummy.hwnd
        
    Set tmrUnBlock = New CTimer
    Set subclass = New clsSubClass
    subclass.AttachMessage hwnd, WM_COPYDATA              'debugger messages
    SetTargetHwnd hwnd
    If InitStackWalk(AddressOf StackWalkCallBack) = 0 Then MsgBox GetStkWalkErr()
 
    isInitilized = True
    
End Function

Private Sub Class_Terminate()
    
    On Error Resume Next
    StopDbg
    Set subclass = Nothing
    Set tmrUnBlock = Nothing
    Unload frmDummy
    Debug.Print "Unloading CDebug objptr=" & ObjPtr(Me)
    
End Sub



Function isUserBpx(ByVal va As Long, Optional cb As CBreakPoint) As Boolean
    Dim b As CBreakPoint
    
    For Each b In BreakPoints
        If b.va = va Then
            Set cb = b
            isUserBpx = True
            Exit Function
        End If
    Next
    
End Function

 
Sub SetModuleBpx(ByVal DllName, ByVal bpxRva As Long)
    'this allows you to set a breakpoint on a module when it is first loaded
    'by rva, this way you dont have to worry if it was rebased
    
    Dim m As CModule
    For Each m In Modules
        If InStr(1, m.path, DllName, 1) > 0 Then 'module already loaded
            If bpxRva > m.base Then RaiseEvent DevMessage("SetModuleBpx", "make sure you are using rva and not va here!")
            SetBreakPoint m.base + bpxRva
            Exit Sub
        End If
    Next
    
    Set m = New CModule 'we are reusing this class type cause it is close and can contain the data
    m.path = DllName
    m.base = bpxRva
    ModuleBpx.Add m
    
    RaiseEvent DevMessage("SetModuleBpx", "Breakpoint will be set @ 0x" & Hex(bpxRva) & " when module " & DllName & " is loaded")
    
    
End Sub



Sub SetMultiBpx(ByVal oneShot As Boolean, ParamArray bpx())
    Dim x
    On Error Resume Next
    For Each x In bpx
        SetBreakPoint CLng(x), oneShot
    Next
End Sub

'todo:
'   optional condition as string
Function SetBreakPoint(ByVal va As Long, Optional ByVal oneShot As Boolean = False) As Boolean
    Dim b As CBreakPoint
    Dim c As Byte
    
    If isUserBpx(va) Then Exit Function 'errVar = "Breakpoint already Set"
       
    Set b = New CBreakPoint
    b.oneShot = oneShot
    
    If Not ReadByte2(va, c) Then
        'module is not loaded yet to set bpx on? we will set as soon as valid
        RaiseEvent DevMessage("SetBreakpoint", "BreakPoint will be set when module is loaded at address " & Hex(va))
        b.va = va
        b.isSet = False
    Else
        WriteByte va, CByte(&HCC) 'todo: check for err writing
        b.OrginalByte = c
        b.va = va
        b.isSet = True
    End If
    
    BreakPoints.Add b, "va:" & va
    SetBreakPoint = True
    
End Function

Private Function SetApplicableBreakPoints()
        
    Dim b As CBreakPoint
    Dim c As Byte
    
    If InternalSingleStep Then Exit Function
        'user called continue while we are already waiting
    
    'called from two places...
    '   onContinue = reset user breakpoints
    '   onModuleLoad = allows users to set breakpoints at addresses not yet in memory
    
    For Each b In BreakPoints
        If Not b.isSet Then
            If ReadRegister(eip) = b.va Then 'currently at bp we want to reset, we have to
                If Not InternalSkipFirstResetCycle Then 'if they are trying to single step we cant do this force reset maneuver which would mask their desire
                    InternalSingleStep = True    'step it to execute it then we can reset it
                    Set InternalActiveBp = b
                    SetSingleStep
                Else
                    RaiseEvent DevMessage("SetApplicableBreakpoints", "eip=" & Hex(b.va) & "  InternalSkipFirstResetCycle=true skipping reset for now")
                End If
            Else
                RaiseEvent DevMessage("SetApplicableBreakpoints", "Resetting bpx @ " & Hex(b.va) & " eip=" & Hex(ReadRegister(eip)))
                
                If ReadByte2(b.va, c) Then
                    WriteByte b.va, CByte(&HCC) 'todo: check for err writing
                    b.OrginalByte = c
                    b.isSet = True
                End If
                
            End If
            
        End If
    Next
        
    
End Function


Function RemoveBreakpoint(ByVal va As Long) As Boolean

    Dim b As CBreakPoint
    Dim c As Byte
    
    If Not isUserBpx(va, b) Then
        RaiseEvent DevMessage("RemoveBreakpoint", "Bpx not set!")
        Exit Function
    End If
    
    If Not ReadByte2(va, c) Then
        'we should be able to set a breakpoint on modules not yet loaded and
        'use th isset member to set it as the module is loaded..future rev
        RaiseEvent DevMessage("RemoveBreakpoint", "Could not ready process memory at va 0x" & Hex(va))
        Exit Function
    End If
    
    If c <> &HCC Then
        RaiseEvent DevMessage("RemoveBreakpoint", "Breakpoint has been removed or overwritten!")
        Exit Function
    End If
    
    WriteByte va, b.OrginalByte 'todo check for err
    
    If InternalRemoveBpx Then
        b.isSet = False
    Else
        BreakPoints.Remove "va:" & va
    End If
    
    InternalRemoveBpx = False
    
End Function


Function Attach(pid As Long) As Boolean
        
        LastEventAddress = 0
        LastEventCode = 0
        LoadedFile = Empty
        SkippedAttachBp = False
        Erase CallStack
        Set Modules = New Collection
        Set BreakPoints = New Collection
        Set ModuleBpx = New Collection
        
        If isDebugging Then StopDbg
        Attach = CBool(AttachDebugger(pid))
        
End Function

Function LaunchProcess(ByVal path As String) As Boolean
        
        If isDebugging Then StopDbg
        
        LastEventAddress = 0
        LastEventCode = 0
        LoadedFile = path
        SkippedAttachBp = False
        Erase CallStack
        Set Modules = New Collection
        Set BreakPoints = New Collection
        Set ModuleBpx = New Collection
        
        
        LaunchProcess = CBool(LaunchDebugedProcess(path))
        
        If LaunchProcess Then 'wait until debugee is fully loaded to return
            While Not SkippedAttachBp
                DoEvents
                Sleep 60
                If ActivePID = 0 Then Exit Function
            Wend
        End If
        
End Function
 
Sub StopDbg()
    LoadedFile = Empty
    StopDebugger
    If UseSymbols Then Cleanup
End Sub

Function GetErr() As String
    Dim b As String
    b = Space(500)
    GetErrorMessage b
    GetErr = Mid(b, 1, InStr(b, Chr(0)))
End Function

Private Function GetModLstErr() As String
    Dim b As String
    b = Space(500)
    GetModuleListErrorMsg b
    GetModLstErr = Mid(b, 1, InStr(b, Chr(0)))
End Function

Private Function GetStkWalkErr() As String
    Dim b As String
    b = Space(500)
    GetStackWalkErrMsg b
    GetStkWalkErr = Mid(b, 1, InStr(b, Chr(0)))
End Function


Private Sub Class_Initialize()
    
    Debug.Print "Initilizing CDebug objptr=" & ObjPtr(Me)
    Initilize 0
    
    On Error Resume Next
    
    Events.Add "DEBUG_EVENT", "id:" & 1
    Events.Add "DATATYPE_MISALIGNMENT", "id:" & &H80000002
    Events.Add "SINGLE_STEP", "id:" & &H80000004
    Events.Add "ACCESS_VIOLATION", "id:" & &HC0000005
    Events.Add "BREAKPOINT", "id:" & &H80000003
    Events.Add "ARRAY_BOUNDS_EXCEEDED", "id:" & &HC000008C
    Events.Add "FLT_DIVIDE_BY_ZERO", "id:" & &HC000008E
    Events.Add "FLT_INVALID_OPERATION", "id:" & &HC0000090
    Events.Add "FLT_OVERFLOW", "id:" & &HC0000091
    Events.Add "INT_DIVIDE_BY_ZERO", "id:" & &HC0000094
    Events.Add "ILLEGAL_INSTRUCTION", "id:" & &HC000001D
    Events.Add "PRIV_INSTRUCTION", "id:" & &HC0000096
    Events.Add "CREATE_THREAD", "id:" & 2
    Events.Add "CREATE_PROCESS", "id:" & 3
    Events.Add "EXIT_THREAD", "id:" & 4
    Events.Add "EXIT_PROCESS", "id:" & 5
    Events.Add "LOAD_DLL", "id:" & 6
    Events.Add "UNLOAD_DLL", "id:" & 7
    Events.Add "DEBUG_STRING", "id:" & 8
    Events.Add "IN_PAGE_ERROR ", "id:" & &HC0000006
    Events.Add "NONCONTINUABLE_EXCEPTION", "id:" & &HC0000025
    Events.Add "FLT_DENORMAL_OPERAND", "id:" & &HC000008D
    Events.Add "FLT_INEXACT_RESULT", "id:" & &HC000008F
    Events.Add "FLT_STACK_CHECK ", "id:" & &HC0000092
    Events.Add "FLT_UNDERFLOW", "id:" & &HC0000093
    Events.Add "INT_OVERFLOW", "id:" & &HC0000095
    Events.Add "STATUS_WAIT_0", "id:" & &H0
    Events.Add "STATUS_ABANDONED_WAIT_0", "id:" & &H80
    Events.Add "STATUS_USER_APC", "id:" & &HC0
    Events.Add "STATUS_TIMEOUT", "id:" & &H102
    Events.Add "STATUS_PENDING", "id:" & &H103
    Events.Add "STATUS_SEGMENT_NOTIFICATION", "id:" & &H40000005
    Events.Add "STATUS_GUARD_PAGE_VIOLATION ", "id:" & &H80000001
    Events.Add "STATUS_NO_MEMORY", "id:" & &HC0000017
    Events.Add "STATUS_CONTROL_C_EXIT ", "id:" & &HC000013A
    Events.Add "VC_THROW_SEH", "id:" & &HE06D7363
    
End Sub



Private Sub subclass_MessageReceived(hwnd As Long, wMsg As Long, wParam As Long, lParam As Long, Cancel As Boolean)
    Dim CopyData As COPYDATASTRUCT
    Dim dbgEvent As DEBUG_EVENT
    Dim Buffer(1 To 2048) As Byte
    Dim Temp As String
    
    If wMsg = WM_COPYDATA Then
        CopyMemory CopyData, ByVal lParam, Len(CopyData)
        If CopyData.dwFlag = 3 Then
            CopyMemory dbgEvent, ByVal CopyData.lpData, CopyData.cbSize
            DebugHandler dbgEvent
        End If
    End If
    
End Sub




Private Sub DebugHandler(dbgEvent As DEBUG_EVENT)
    
    'If InternalSingleStep Then Stop
    
    On Error Resume Next

    Dim except As EXCEPTION_DEBUG_INFO
    Dim thread As CREATE_THREAD_DEBUG_INFO
    Dim dll  As LOAD_DLL_DEBUG_INFO

    Dim DllName As String
    Dim dllSize As Long
    Dim v As Variant
    
    Dim lngVal As Long
    Dim noContinue As Boolean
    Dim module As String
    Dim e As CException
    Dim cmod As CModule
    
    Dim msg() As String
    
    ActiveThreadID = dbgEvent.dwThreadId
    
    Select Case dbgEvent.dwDebugEventCode
    
        Case CREATE_PROCESS_DEBUG_EVENT
                Set Threads = New Collection
                CopyMemory ProcessInfo, dbgEvent.Data(0), Len(ProcessInfo)
                Threads.Add ProcessInfo.hThread, "id:" & dbgEvent.dwThreadId
                If UseSymbols Then
                    InitSearchPath SymbolPath, ProcessInfo.hProcess
                End If
                Continue
                
         Case LOAD_DLL_DEBUG_EVENT
               CopyMemory dll, dbgEvent.Data(0), Len(dll)
               If GetDllStats(Me, dll.hFile, dll.lpBaseOfDll, DllName, dllSize) Then
                    If InStr(1, DllName, "kernel32", vbTextCompare) > 1 Then Kernel32Base = dll.lpBaseOfDll
                    AddModule DllName, dll.lpBaseOfDll, dllSize
                    If UseSymbols Then
                        LoadModuleSymbols DllName, dll.lpBaseOfDll, dllSize
                    End If
                    RaiseEvent DllLoad(DllName, dll.lpBaseOfDll, dllSize)
                    If ModuleBpx.Count > 0 Then 'we have some bpx to set on module loading
                        Dim m As CModule
                        For Each m In ModuleBpx
                            If InStr(1, DllName, m.path, 1) > 0 Then
                                SetBreakPoint dll.lpBaseOfDll + m.base
                                RaiseEvent DevMessage("DebugHandler", "ModuleBpx target: " & m.path & " loaded setting bpx at " & Hex(dll.lpBaseOfDll + m.base))
                                'we dont remove the modulebpx cause sometimes dlls will be unloaded/loaded many times
                            End If
                        Next
                    End If
                        
                End If
               Continue
               
        Case CREATE_THREAD_DEBUG_EVENT
                CopyMemory thread, dbgEvent.Data(0), Len(thread)
                Threads.Add thread.hThread, "id:" & dbgEvent.dwThreadId
                RaiseEvent ThreadCreate(dbgEvent.dwThreadId, thread.lpStartAddress)
                Continue
                
        Case EXIT_THREAD_DEBUG_EVENT
                CopyMemory lngVal, dbgEvent.Data(0), 4
                Threads.Remove "id:" & dbgEvent.dwThreadId
                RaiseEvent ThreadDestroy(dbgEvent.dwThreadId, lngVal)
                Continue
                
        Case EXCEPTION_DEBUG_EVENT
                CopyMemory except, dbgEvent.Data(0), Len(except)
                
                If Not SkippedAttachBp And except.ExceptionCode = EXCEPTION_BREAKPOINT Then
                    SkippedAttachBp = True
                    RaiseEvent ReadyToRun
                    'Continue you have to call this manually now from event! (manual ui needs this)
                    Exit Sub
                End If
                
                With except
                        
                        Dim tmpbp As CBreakPoint
                        Dim c As Byte
                        
                        InternalSkipFirstResetCycle = False
                        
                        If InternalSingleStep And .ExceptionCode = EXCEPTION_SINGLE_STEP Then
                               
                                If Not InternalActiveBp Is Nothing Then
                                    If ReadByte2(InternalActiveBp.va, c) Then
                                        WriteByte InternalActiveBp.va, CByte(&HCC) 'todo: check for err writing
                                        InternalActiveBp.OrginalByte = c
                                        InternalActiveBp.isSet = True
                                        'frmLibDebug.List1.AddItem "Reset breakpoint at va " & Hex(InternalActiveBp.va)
                                    End If
                                End If
                                
                                Set InternalActiveBp = Nothing
                                InternalSingleStep = False
                                Continue
                                Exit Sub
                                
                        End If
                                               
                        
                        
                        If except.ExceptionCode = EXCEPTION_BREAKPOINT Then
                            'frmLibDebug.List1.AddItem "Exception Bpx @ " & Hex(.ExceptionAddress)
                            If isUserBpx(.ExceptionAddress, tmpbp) Then
                                'MsgBox "User bp at : " & Hex(.ExceptionAddress)
                                lngVal = ReadRegister(eip) - 1
                                ModifyRegister eip, lngVal
                                If Not tmpbp.oneShot Then InternalRemoveBpx = True
                                RemoveBreakpoint .ExceptionAddress
                            End If
                        End If
                        
                        Set e = New CException
                        e.ExceptionAddress = .ExceptionAddress
                        e.ExceptionCode = .ExceptionCode
                        e.ExceptionFlags = .ExceptionFlags
                        e.NumberParameters = .NumberParameters
                        e.dwFirstChance = .dwFirstChance
                        e.pExceptionRecord = .pExceptionRecord
                        e.Disasm = DisasmVA(.ExceptionAddress)
                        e.CrashInModule = ModuleAtAddress(.ExceptionAddress)
                        e.Enviroment = BuildEnv(dbgEvent.dwThreadId)
                                                
                        If tmpbp Is Nothing Then
                            If .ExceptionCode = EXCEPTION_SINGLE_STEP Then
                                RaiseEvent SingleStep(e)
                            Else
                                RaiseEvent Exception(e)
                            End If
                        Else
                            If InternalStepOver Then
                                InternalStepOver = False 'step over is actually a bpx on next inst but we trigger as singlestep event
                                RaiseEvent SingleStep(e)
                            Else
                                RaiseEvent UserBreakpoint(e)
                            End If
                        End If
                                
                        LastEventAddress = .ExceptionAddress
                        LastEventCode = .ExceptionCode
                        
                        Erase CallStack
                        
                        'If Not tmpbp Is Nothing Then Continue
                        
                End With

        Case EXIT_PROCESS_DEBUG_EVENT
                StopDbg
                If UseSymbols Then Cleanup
                RaiseEvent Terminate
                
        Case OUTPUT_DEBUG_STRING_EVENT
                Dim o As OUTPUT_DEBUG_STRING_INFO
                Dim ts As String
                CopyMemory o, dbgEvent.Data(0), Len(o)
                ts = ParseDbgString(o)
                If Len(ts) > 0 Then RaiseEvent DebugString(ts)
                Continue
                
        Case Else
                Continue
        
    End Select
 
End Sub


Function GethThreadForThreadID(threadID As Long) As Long
    On Error Resume Next
    GethThreadForThreadID = CLng(Threads("id:" & threadID))
End Function



Function NameForDebugEvent(ByVal id As DbgEvents) As String
    On Error GoTo hell
    If Events.Count = 0 Then Class_Initialize
    NameForDebugEvent = Events("id:" & id)
    Exit Function
hell:
    NameForDebugEvent = "0x" & Hex(id)
    
    If InStr(1, NameForDebugEvent, "0xE", vbTextCompare) > 0 Then
        NameForDebugEvent = NameForDebugEvent & "  APPDEFINED_ERRCODE"
    End If

End Function

Function WriteByte(ByVal va As Long, ByVal b As Byte) As Boolean
    WriteByte = IIf(WriteProcessMemory(ProcessInfo.hProcess, ByVal va, b, 1, 0&) = 0, False, True)
End Function

Function WriteLong(ByVal va As Long, ByVal l As Long) As Boolean
    WriteLong = IIf(WriteProcessMemory(ProcessInfo.hProcess, ByVal va, l, 4, 0&) = 0, False, True)
End Function

Function ReadByte2(ByVal va As Long, b As Byte) As Boolean
    If ReadProcessMemory(ProcessInfo.hProcess, va, b, 1, 0) > 0 Then
        ReadByte2 = True
    End If
End Function

Function ReadByte(va As Long) As Byte
    ReadProcessMemory ProcessInfo.hProcess, va, ReadByte, 1, 0
End Function

Function ReadLng(ByVal va As Long, retLng As Long) As Boolean
    Dim b(4) As Byte
    Dim tmp As Long
    If ReadProcessMemory(ProcessInfo.hProcess, va, b(0), 4, 0) > 0 Then
        CopyMemory tmp, b(0), 4
        retLng = tmp
        ReadLng = True
    End If
End Function

Property Get CurrentInstruction(Optional instLen As Long) As String
    Dim ip As Long
    'do we need to watch out for user software breakpoints?
    ip = ReadRegister(eip)
    CurrentInstruction = DisasmVA(ip, instLen)
End Property


Function ReadBuf(ByVal va As Long, ByVal leng As Long, buf() As Byte) As Boolean
    Dim tmp() As Byte, ret As Long
    If leng = 0 Then Exit Function
    ReDim tmp(leng - 1)
    ret = ReadProcessMemory(ProcessInfo.hProcess, va, tmp(0), leng, 0)
    buf() = tmp()
    ReadBuf = IIf(ret <> 0, True, False)
End Function

Function DisasmVA(ByVal va As Long, Optional leng_out As Long, Optional dump_out) As String
    Dim da As t_Disasm
    Dim b()  As Byte
    Dim x As Long
    On Error Resume Next
    'do we need to watch out for user software breakpoints?
    If Not ReadBuf(va, 20, b) Then
        DisasmVA = "?????"
    Else
        leng_out = Disasm(b(0), UBound(b) + 1, va, da)
        dump_out = da.dump
        x = InStr(dump_out, Chr(0))
        If x > 0 Then dump_out = Mid(dump_out, 1, x - 1)
        DisasmVA = Mid(da.result, 1, InStr(da.result, Chr(0)) - 1)
    End If
End Function

'does not do ordial lookups yet
Function ResolveExport(ByVal libName As String, ByVal procName As String) As Long
    
    On Error Resume Next
    Dim c As CModule
    Dim e As CExport
    Dim path As String
    Dim base As String
    Dim n As Long
    
    If InStr(1, exports.CurrentImage, libName, vbTextCompare) > 0 Then
            For Each e In exports.functions
                If LCase(e.FunctionName) = LCase(procName) Then
                    n = GetModuleBase(libName)
                    If n = 0 Then
                        RaiseEvent DevMessage("ResolveExport", "Could not GetModuleBase(" & libName & ") using default")
                        n = exports.offset.ImageBase
                    End If
                    ResolveExport = n + e.FunctionAddress
                    Exit Function
                End If
            Next
    Else
                If InStr(1, libName, ".") < 1 Then libName = libName & ".dll"
                
                If InStr(1, libName, "\") < 1 Then 'we need its full path
                    path = Environ("WinDir") & "\" & libName
                    If Dir(path) = "" Then
                        path = Environ("WinDir") & "\system32\" & libName
                        If Dir(path) = "" Then
                            n = InStrRev(LoadedFile, "\")
                            If n > 0 Then base = Mid(LoadedFile, 1, n)
                            path = base & libName
                        End If
                    End If
                End If
                    
                If exports.LoadExports(path) Then
                    For Each e In exports.functions
                        If LCase(e.FunctionName) = LCase(procName) Then
                            n = GetModuleBase(libName)
                            If n = 0 Then
                                RaiseEvent DevMessage("ResolveExport", "Could not GetModuleBase(" & libName & ") using default")
                                n = exports.offset.ImageBase
                            End If
                            ResolveExport = n + e.FunctionAddress
                            Exit Function
                        End If
                    Next
                End If
                
            
    End If
    
End Function

Function DisasmBlock(ByVal va As Long) As String
    Dim tmp() As String
    Dim tmpVa As Long
    Dim instAfterVa As Long
    Dim bytesBack As Long
    Dim n As Long
    Dim x As String
    
    On Error Resume Next
    
    'MsgBox "VA: " & Hex(va)
    
    tmpVa = va
    bytesBack = DisasmBack(va)
    
    If bytesBack = 0 Then
        Debug.Print "DisasmBack failed to find a solution"
    Else
        tmpVa = va - bytesBack
    End If
    
    Dim n1 As String, d As String, n2 As String, n3 As Long
   
    Do While 1
        x = DisasmVA(tmpVa, n)
        'If InStr(x, "??") > 0 Then Exit Do
        
        If UseSymbols Then
            If InStr(1, x, "call", vbTextCompare) > 0 Then
                n2 = Trim(Mid(x, InStrRev(x, " ")))
                If InStr(n2, "[") > 0 Then
                    n2 = Replace(Replace(n2, "[", ""), "]", "")
                    If IsHex(n2) Then
                        If ReadLng(CLng("&h" & n2), n3) Then
                            If GetSymbolForOffset(n3, n1, d) Then
                                x = x & "  (" & n1 & ")"
                            End If
                        Else
                            If GetSymbolForOffset(CLng("&h" & n2), n1, d) Then
                                x = x & "  (" & n1 & ")"
                            End If
                        End If
                    End If
                Else
                    If IsHex(n2) Then
                        If GetSymbolForOffset(CLng("&h" & n2), n1, d) Then
                            x = Replace(x, n2, n1)
                        End If
                    End If
                End If
            End If
        End If
        
        push tmp, Hex(tmpVa) & vbTab & x
        If tmpVa = va Then
            tmp(UBound(tmp)) = tmp(UBound(tmp)) & vbTab & "  <--- CRASH"
        End If
        
        If n = 0 Then 'bad disasm
            Exit Do
        Else
            tmpVa = tmpVa + n
        End If
        
        If tmpVa >= va Then
            instAfterVa = instAfterVa + 1
            If instAfterVa = 10 Then Exit Do
        End If
    Loop
     
    DisasmBlock = Join(tmp, vbCrLf)
    
End Function

'gives teh number of bytes to jump back to align on an instruction boundry
'for a given va. nBack is an in val for the target num of instr you want to go back
'for the return value..say it with me now...trail and error is fun!
'there must be a better way to do this, I make no guarantees on how well this works!
Function DisasmBack(ByVal va As Long, Optional nBack As Integer = 5) As Integer
    Dim l As Long
    Dim testVa As Long
    Dim testOffset As Long
    Dim res As String
    Dim instCnt As Integer
    Dim leng As Long
    Dim lengs() As Integer
    Dim i As Integer
    
    On Error Resume Next
    
    testOffset = 50 'should be long enough to reduce chance of alt disasm
     
tryAgain:
     If testOffset = 0 Then Exit Function 'we tried all possibilities we suck
      
     Erase lengs
     testVa = va - testOffset
     instCnt = 0
     
    Do While 1
        res = DisasmVA(testVa, leng)
        push lengs, leng 'track each instruction lenght for current solution
        If InStr(res, "?") > 0 Or leng = 0 Then 'error disassembling bad solution
            If testOffset = 0 Then Exit Function
            testOffset = testOffset - 1
            GoTo tryAgain
        Else
            instCnt = instCnt + 1
            testVa = testVa + leng 'move to next inst
            If testVa = va Then 'we reached our known va with valid asm
                If UBound(lengs) > nBack Then 'give the back length for x instr
                    l = 0
                    For i = UBound(lengs) To (UBound(lengs) - nBack) Step -1
                        l = l + lengs(i)
                    Next
                    DisasmBack = l
                Else
                    nBack = instCnt 'we didnt hit our target instruction count (shouldnt happen)
                    DisasmBack = testOffset
                End If
                Exit Function
            ElseIf testVa > va Then 'we passed our mark try again with diff offset
                testOffset = testOffset - 1
                GoTo tryAgain
            End If
        End If
    Loop
    
End Function


Sub SuspendThreads()
    Dim f
    For Each f In Threads
        SuspendThread CLng(f)
    Next
End Sub

Sub ResumeThreads()
   Dim f
   For Each f In Threads
        ResumeThread CLng(f)
   Next
End Sub

Private Sub SetContext(ByVal hThread As Long, NewContext As CONTEXT)
    SetThreadContext hThread, NewContext
End Sub

Private Function GetContext(hThread As Long, Optional flags As ctx_vals) As CONTEXT
    If flags = 0 Then flags = CONTEXT_i486 Or CONTEXT_CONTROL Or CONTEXT_INTEGER Or CONTEXT_SEGMENTS Or CONTEXT_FLOATING_POINT
    GetContext.ContextFlags = flags
     GetThreadContext hThread, GetContext
End Function

Private Function BuildEnv(threadID As Long) As String
    
    Dim c As CONTEXT
    Dim tmp() As String
    Dim b() As Byte
    Dim vars() As String
    Dim hThread As Long
    Dim x
    Dim tib As Long
    
    On Error Resume Next
    hThread = Threads("id:" & threadID)
    
    If hThread = 0 Then
        Debug.Print "Could not get thread handle for " & threadID & " Threads.count=" & Threads.Count
        Exit Function
    End If
    
    c = GetContext(hThread)
    GetCallStack hThread, c
    
    push tmp, "Seh Chain:"
    push tmp, String(50, "-")
    push tmp, GetSehChain(threadID)
    
    push tmp, vbCrLf
    push tmp, pad("Called From") & pad("Returns To")
    push tmp, String(50, "-")

    For Each x In CallStack
        vars = Split(x, ",")
        push tmp, pad(ModuleAtAddress(CLng(vars(1)), , 1) & Hex(vars(1))) & _
                  pad(ModuleAtAddress(CLng(vars(2)), , 1) & Hex(vars(2)))
    Next
        
    push tmp, vbCrLf
    push tmp, "Registers:"
    push tmp, String(50, "-")
        
    With c
        push tmp, "EIP " & tHex(.eip) & GetMemory(.Eax, True)
        push tmp, "EAX " & tHex(.Eax) & GetMemory(.Eax, True)
        push tmp, "EBX " & tHex(.Ebx) & GetMemory(.Ebx, True)
        push tmp, "ECX " & tHex(.Ecx) & GetMemory(.Ecx, True)
        push tmp, "EDX " & tHex(.Edx) & GetMemory(.Edx, True)
        push tmp, "EDI " & tHex(.edi) & GetMemory(.edi, True)
        push tmp, "ESI " & tHex(.Esi) & GetMemory(.Esi, True)
        push tmp, "EBP " & tHex(.ebp) & GetMemory(.ebp, True)
        push tmp, "ESP " & tHex(.esp) & GetMemory(.esp, True)
    End With
     
    push tmp, vbCrLf
    push tmp, "Block Disassembly: "
    push tmp, String(50, "-")
    push tmp, DisasmBlock(c.eip)
    push tmp, vbCrLf
    
    If ReadBuf(c.ebp, 24, b) Then
        push tmp, "ArgDump:"
        push tmp, String(50, "-")
        push tmp, DumpArgs(c.ebp)
        push tmp, vbCrLf
    End If
    
    If ReadBuf(c.esp, 80, b) Then
        push tmp, "Stack Dump:"
        push tmp, String(50, "-")
        push tmp, hexdump(c.esp, b)
        push tmp, vbCrLf
    End If
    
    BuildEnv = Join(tmp, vbCrLf)
    
End Function

Private Function pad(x, Optional l As Long = 30) As String
    Dim Y As Long
    Y = l - Len(x)
    If Y < 1 Then
        pad = x
        Exit Function
    End If
    pad = x & Space(Y)
End Function

Function GetMemory(ByVal va As Long, Optional ByVal asciiDump As Boolean = False) As String
    
    If va = 0 Then Exit Function
    
    Dim r As Long
    Dim b() As Byte
    Dim tmp As String
    Dim i As Long
    Dim isUnicode As Boolean
    Dim oneChance As Boolean
    Dim scanAt As Long
    Dim firstScan As Boolean
    
    If Not ReadLng(va, r) Then Exit Function
    
    GetMemory = " -> " & tHex(r)
    
    firstScan = True
    scanAt = va 'first try direct pointer to string
    
tryAgain:
    
    If Not firstScan Then 'we already tried first mechanism and failed
        If scanAt = r Then 'we failed 2nd too
            Exit Function
        Else
            scanAt = r
        End If
    End If
    
    firstScan = False
    
    If asciiDump Then
        If ReadBuf(va, 50, b) Then
            For i = 0 To UBound(b)
                If b(i) > 20 And b(i) < 120 Then
                    If oneChance Then
                        isUnicode = True
                        oneChance = False
                    End If
                    tmp = tmp & Chr(b(i))
                Else
                    If b(i) = 0 And oneChance = False Then 'needs another ascii to reset so 00 00 will terminate
                        oneChance = True
                    Else
                        Exit For
                    End If
                End If
            Next
            If Len(tmp) > 3 Then
                If isUnicode Then tmp = Replace(tmp, Chr(0), Empty)
                tmp = " -> " & IIf(isUnicode, "Uni: ", "Asc: ") & tmp
                If scanAt = r Then tmp = " -> " & tHex(r) & tmp  '**eax=str
                GetMemory = tmp
            Else
                GoTo tryAgain
            End If
        Else
            i = 1 'marker to move to next trial
            GoTo tryAgain
        End If
    End If
            
            
End Function

Private Function tHex(x As Long) As String
    Dim t As String
    
    t = Hex(x)
    While Len(t) < 8
        t = "0" & t
    Wend
    tHex = t
    
End Function

Function DumpArgs(ByVal ebp As Long, Optional cnt As Integer = 6) As String
    Dim tmp() As String
    Dim i As Integer
    Dim x As Long
    Dim offset As Long
    
    offset = 8
    
    For i = 1 To cnt
        ReadLng (ebp + offset), x
        push tmp, "EBP+" & offset & vbTab & tHex(x) & GetMemory(x, True)
        offset = offset + 4
    Next
    
    DumpArgs = Join(tmp, vbCrLf)
    
End Function

Function hexdump(ByVal base As Long, it() As Byte)
    Dim my, i, c, s, a As Byte, b
    Dim lines() As String
    
    my = ""
    For i = 0 To UBound(it)
        a = it(i)
        c = Hex(a)
        c = IIf(Len(c) = 1, "0" & c, c)
        b = b & IIf(a > 65 And a < 120, Chr(a), ".")
        my = my & c & " "
        If (i + 1) Mod 16 = 0 Then
            push lines(), Hex(base) & " " & my & " [" & b & "]"
            base = base + 16
            my = Empty
            b = Empty
        End If
    Next
    
    If Len(b) > 0 Then
        If Len(my) < 48 Then
            my = my & String(48 - Len(my), " ")
        End If
        If Len(b) < 16 Then
             b = b & String(16 - Len(b), " ")
        End If
        push lines(), my & " [" & b & "]"
    End If
        
    If UBound(it) < 16 Then
        hexdump = Hex(base) & " " & my & " [" & b & "]" & vbCrLf
    Else
        hexdump = Join(lines, vbCrLf)
    End If
    
    
End Function

Private Function GetModuleBase(ByVal name As String) As Long

    On Error Resume Next
    Dim c As CModule
    For Each c In Modules
        If InStr(1, c.path, name, vbTextCompare) > 0 Then
            GetModuleBase = c.base
            Exit Function
        End If
    Next
    
    Debug.Print "Could not find base for module: " & name
    
End Function

Private Function ModuleAtAddress(ByVal va As Long, Optional wrapped As Boolean = False, Optional bare As Integer = 0) As String

    If Modules.Count = 0 Then
        'unused redundant system because now track dlls loading in LoadDLL debug event
        'If GetModuleList(AddressOf ModuleListCallBack) = 0 Then
        '    Debug.Print GetModLstErr
        'End If
    End If
        
    If Modules.Count = 0 Then Exit Function

    Dim c As CModule
    For Each c In Modules
        If va >= c.base And va <= (c.base + c.size) Then
            ModuleAtAddress = c.path
            If bare > 0 Then
                If InStr(c.path, ".") > 0 Then
                    ModuleAtAddress = Mid(c.path, 1, InStrRev(c.path, "."))
                End If
            End If
            If wrapped Then ModuleAtAddress = vbTab & "(" & ModuleAtAddress & ")"
            Exit Function
        End If
    Next

End Function

Friend Sub AddModule(name As String, base As Long, size As Long)
    Dim c As CModule
    On Error GoTo hell
    
    If Not KeyExistsInCollection(Modules, name) Then
        Set c = New CModule
        c.path = name
        c.base = base
        c.size = size
        Modules.Add c, name
    End If
    
    Exit Sub
hell:     Debug.Print "Err in AddModule: " & Err.Description
End Sub



Function GetSehChain(Optional ByVal threadID As Long = 0, Optional ByVal verbose As Boolean = True) As String
    Dim tmp() As String
    Dim b() As Byte
    Dim i As Long
    Dim s As sehRecord
    Dim start As Long
    
    Dim vaTib As Long
    Dim hThread As Long
    Dim n1 As String, d As String
    
   If threadID = 0 Then
        hThread = Threads("id:" & ActiveThreadID)
   Else
        hThread = Threads("id:" & threadID)
   End If
   
   If hThread = 0 Then Exit Function
     
    vaTib = GetTibForThread(hThread)
    
    If Not ReadBuf(vaTib, Len(s), b) Then Exit Function
    CopyMemory s, b(0), Len(s)
    
    Do
        i = i + 1
        If Not ReadBuf(s.pNextRecord, Len(s), b) Then
            Exit Do
        Else
            CopyMemory s, b(0), Len(s) 'this loads next record
            If verbose Then
                If UseSymbols Then
                    If GetSymbolForOffset(s.vaHandler, n1, d) Then n1 = vbTab & "( " & n1 & ")" Else n1 = Empty
                    push tmp, i & " " & vbTab & Hex(s.vaHandler) & " " & vbTab & ModuleAtAddress(s.vaHandler) & n1
                Else
                    push tmp, i & " " & vbTab & Hex(s.vaHandler) & " " & vbTab & ModuleAtAddress(s.vaHandler)
                End If
            Else
                push tmp, Hex(s.vaHandler)
            End If
        End If
    Loop While s.pNextRecord > 0
    
    GetSehChain = Join(tmp, vbCrLf)

End Function

Function ReadRegister(ByVal reg As Registers) As Long
    
   Dim sctx As CONTEXT
   Dim hThread As Long
   
   On Error Resume Next
   
   Dim threadID As Long
     
   If threadID = 0 Then
        hThread = Threads("id:" & ActiveThreadID)
   Else
        hThread = Threads("id:" & threadID)
   End If
   
   If hThread = 0 Then Exit Function
   
   sctx = GetContext(hThread)
   
   With sctx
        Select Case reg
             Case edi: ReadRegister = .edi
             Case Esi: ReadRegister = .Esi
             Case Ebx: ReadRegister = .Ebx
             Case Edx:  ReadRegister = .Edx
             Case Ecx: ReadRegister = .Ecx
             Case Eax: ReadRegister = .Eax
             Case ebp: ReadRegister = .ebp
             Case eip: ReadRegister = .eip
             Case esp: ReadRegister = .esp
             Case EFlags: ReadRegister = .EFlags
        End Select
    End With

End Function

Sub ModifyRegister(ByVal reg As Registers, ByVal valu As Long)
    
   Dim sctx As CONTEXT
   Dim hThread As Long
   On Error Resume Next
   
   Dim threadID As Long
   
   If threadID = 0 Then
        hThread = Threads("id:" & ActiveThreadID)
   Else
        hThread = Threads("id:" & threadID)
   End If
   
   If hThread = 0 Then Exit Sub
   
   sctx = GetContext(hThread)
   
   With sctx
        Select Case reg
             Case edi: .edi = valu
             Case Esi: .Esi = valu
             Case Ebx: .Ebx = valu
             Case Edx: .Edx = valu
             Case Ecx: .Ecx = valu
             Case Eax: .Eax = valu
             Case ebp: .ebp = valu
             Case eip: .eip = valu
             Case esp: .esp = valu
             Case EFlags: .EFlags = valu
        End Select
    End With
   
  SetContext hThread, sctx

End Sub

Private Sub SetSingleStep(Optional ByVal threadID As Long = 0)
    Dim ctx As CONTEXT
    Dim hThread As Long
    
    On Error Resume Next
   

    If threadID = 0 Then
         hThread = Threads("id:" & ActiveThreadID)
    Else
         hThread = Threads("id:" & threadID)
    End If

   
   If hThread = 0 Then Exit Sub
   
    ctx = GetContext(hThread)
    ctx.EFlags = ctx.EFlags Or &H100&
    SetContext hThread, ctx
    
End Sub

Private Sub ClearSingleStep(Optional ByVal threadID As Long = 0)
    Dim ctx As CONTEXT
    Dim hThread As Long
    On Error Resume Next
   
    If threadID = 0 Then
         hThread = Threads("id:" & ActiveThreadID)
    Else
         hThread = Threads("id:" & threadID)
    End If

    If hThread = 0 Then Exit Sub
    
    ctx = GetContext(hThread)
    If (ctx.EFlags And &H100&) = &H100& Then ctx.EFlags = ctx.EFlags Xor &H100&
    SetContext hThread, ctx
    
End Sub

Function Get_ThreadContext(hThread As Long) As CContext
    Dim c As CONTEXT
    Dim cc As New CContext
    c = GetContext(hThread)
    cc.LoadContext c
    Set Get_ThreadContext = cc
End Function

'Main debug loop uses SendMessage to send messages to our debug handler.
'which hangs until our subclassed proc returns, hence we cannot use any
'polling loops in our code waiting for the next debug event because it would
'never happen as debugger is still waiting for debugproc to return before it can
'resume its actions, soo we use a timer to cheat and fire the execution async.
Private Sub tmrUnBlock_Timer()
    tmrUnBlock.Disable
    SetApplicableBreakPoints
    DebugContinue DebugDecision
End Sub

Function GetSymbolForOffset(offset As Long, name As String, decl As String) As Boolean
    Dim ret As Long
    
    name = String(1040, Chr(0))
    decl = String(1040, Chr(0))
    
    ret = GetSymbol(offset, name, decl, 1040)
    If ret = 1 Then GetSymbolForOffset = True
    
    ret = InStr(name, Chr(0))
    If ret > 0 Then name = Mid(name, 1, ret - 1)
    
    ret = InStr(decl, Chr(0))
    If ret > 0 Then decl = Mid(decl, 1, ret - 1)
    
    
End Function

Private Function ParseDbgString(o As OUTPUT_DEBUG_STRING_INFO) As String
    Dim isUni As Boolean
    Dim buf() As Byte
    Dim v, ret As String
    Dim i As Integer
    
    isUni = IIf(o.fUnicode = 0, True, False)
    If o.nDebugStringLength < 1 Then Exit Function
    If Not ReadBuf(o.lpDebugStringData, CLng(o.nDebugStringLength), buf) Then Exit Function
    
    For i = 0 To o.nDebugStringLength - 1
        If buf(i) <> 0 Then ret = ret & Chr(buf(i))
    Next
    
    ParseDbgString = ret
        
End Function
