Attribute VB_Name = "Module1"
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


Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)
Public Declare Function SuspendThread Lib "kernel32" (ByVal hThread As Long) As Long
Public Declare Function ResumeThread Lib "kernel32" (ByVal hThread As Long) As Long

Enum ctx_vals
     CONTEXT_i486 = &H10000 '  // i486
     CONTEXT_CONTROL = 1
     CONTEXT_INTEGER = 2
     CONTEXT_SEGMENTS = 4
     CONTEXT_FLOATING_POINT = 8
     CONTEXT_DEBUG_REGISTERS = 16
     CONTEXT_EXTENDED_REGISTERS = 32
     CONTEXT_EXTENDED_INTEGER = (CONTEXT_INTEGER Or &H10)
     CONTEXT_FULL = (CONTEXT_CONTROL Or CONTEXT_FLOATING_POINT Or CONTEXT_INTEGER Or CONTEXT_EXTENDED_INTEGER)
End Enum

Public Type CONTEXT
    ContextFlags As ctx_vals
    'CONTEXT_DEBUG_REGISTERS is NOT included in CONTEXT_FULL.
    Dr0 As Long
    Dr1 As Long
    Dr2 As Long
    Dr3 As Long
    Dr6 As Long
    Dr7 As Long
    'CONTEXT_FLOATING_POINT.
    FloatSave(111) As Byte
    'CONTEXT_SEGMENTS.
    SegGs As Long
    SegFs As Long
    SegEs As Long
    SegDs As Long
    'flag CONTEXT_INTEGER.
    edi As Long
    Esi As Long
    Ebx As Long
    Edx As Long
    Ecx As Long
    Eax As Long
    'flag CONTEXT_CONTROL.
    ebp As Long
    eip As Long
    SegCs As Long       'MUST BE SANITIZED
    EFlags As Long      'MUST BE SANITIZED 'EFlags=&H100 For Single-Step Execution
    esp As Long
    SegSs As Long
    'CONTEXT_EXTENDED_REGISTERS.
    ExtendedRegisters(512 - 1) As Byte
End Type

Global CallStack() As String


'call backs have to be in public modules
'Sub ModuleListCallBack(ByVal pName As Long, ByVal base As Long, ByVal size As Long)
'    Dim buf() As Byte
'    Dim Name As String
'    Dim n As Long
'
'    ReDim buf(255)
'
'    CopyMemory buf(0), ByVal pName, 255
'    Name = StrConv(buf, vbUnicode)
'    n = InStr(Name, Chr(0))
'    Name = Mid(Name, 1, n - 1)
'
'    'MsgBox "Name" & name & " Base" & Hex(base) & " Size" & Hex(size)
'    frmCrashMon.Crash.AddModule Name, base, size
'
'End Sub

Sub StackWalkCallBack(ByVal frame As Long, ByVal eip As Long, ByVal retAddr As Long, ByVal frameptr As Long, ByVal stackPtr As Long)
    
    If retAddr > 0 Then
        push CallStack, frame & "," & eip & "," & retAddr & "," & frameptr & "," & stackPtr
    End If

End Sub


'generic misc glue functions below
Function StripQuotes(ByVal x)
    x = Replace(x, "'", Empty)
    StripQuotes = Replace(x, """", Empty)
End Function

Function ExpandPath(ByVal fpath As String) As String
    Dim x As Long
    Dim tmp As String
    
    On Error Resume Next
    
    fpath = StripQuotes(fpath)
    x = InStrRev(fpath, "%")
    If x > 0 Then
        env = Mid(fpath, 1, x)
        fpath = Replace(fpath, env, Environ(Replace(env, "%", "")))
    End If
        
    If InStr(LCase(fpath), ":\") < 1 Then
        tmp = Environ("WinDIR") & "\" & fpath
        If fso.FileExists(tmp) Then
            fpath = tmp
        Else
            tmp = Environ("WinDIR") & "\System32\" & fpath
            If fso.FileExists(tmp) Then fpath = tmp
        End If
    End If
    
    ExpandPath = fpath
    
End Function

Sub dbg(msg)
    'debug.Print msg
End Sub

Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    Dim x As Long
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = value
    Exit Sub
init:     ReDim ary(0): ary(0) = value
End Sub



Sub glue(ary, value) 'this modifies parent ary object
    On Error GoTo hell
    ary(UBound(ary)) = ary(UBound(ary)) & " " & value
Exit Sub
hell: push ary, value
      Stop
End Sub



Function AryIsEmpty(ary) As Boolean
  On Error GoTo oops
    Dim i As Long
    i = UBound(ary)  '<- throws error if not initalized
    AryIsEmpty = False
  Exit Function
oops: AryIsEmpty = True
End Function


Function IsIde() As Boolean
    On Error GoTo hell
    Debug.Print 1 / 0
    IsIde = False
    Exit Function
hell: IsIde = True
End Function



Function KeyExistsInCollection(c As Collection, val As String) As Boolean
    On Error GoTo nope
    Dim t
    If IsObject(c(val)) Then
        Set t = c(val)
    Else
        t = c(val)
    End If
    KeyExistsInCollection = True
 Exit Function
nope: KeyExistsInCollection = False
End Function



Function AnyOfTheseInstr(sIn, sCmp) As Boolean
    Dim tmp() As String, i As Integer
    On Error GoTo hell
    tmp() = Split(sCmp, ",")
    For i = 0 To UBound(tmp)
        tmp(i) = Trim(tmp(i))
        If Len(tmp(i)) > 0 And InStr(1, sIn, tmp(i), vbTextCompare) > 0 Then
            AnyOfTheseInstr = True
            Exit Function
        End If
    Next
hell:
End Function


