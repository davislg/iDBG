VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CDisplayManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit


'this class handles UI display

Public Instructions As Collection

Public MinVA As Long
Public MaxVA As Long
Public Display As PictureBox
Public RegBox As PictureBox
Public Stack As PictureBox
Public Memory As PictureBox

Public ActiveVA As Long

Sub Refresh()
    LoadAddress Form1.dbg.ReadRegister(eip)
    dumpRegisters
    RefreshStack
End Sub

Sub ClearAll()
    Display.Cls
    RegBox.Cls
    Memory.Cls
    Stack.Cls
End Sub

Sub DrawDisasm()
       
    Dim x
    Dim lineNum As Long
    
    Display.Cls
    
    For Each x In Instructions
        Display.Print x
    Next

End Sub

Sub LoadAddress(ByVal base As Long)

    Dim l As Long, i As Long, d, x
    Dim y
    
    MinVA = base
    Set Instructions = New Collection
    
    Form1.Caption = "Process: " & Form1.dbg.LoadedFile & " Current Module: " & Form1.dbg.ModuleAtVA(base)
    
    For i = 0 To 20
        x = Form1.dbg.DisasmVA(base, l, d)
        If Form1.dbg.UseSymbols Then x = x & vbTab & GetSymbolForAsm(base, CStr(x))
        x = Pad(Hex(base), 9) & " " & Pad(d, 24) & x
        Instructions.Add x
        base = base + l
    Next
    
    MaxVA = base
    
    DrawDisasm
    RefreshStack
    
End Sub

Function SimpleSymbol(va) As String
    Dim x As String, d As String
    Form1.dbg.GetSymbolForOffset CLng(va), x, d
    SimpleSymbol = x
End Function

Sub dumpRegisters()


   Dim vals() As String, i As Long
   Dim flags() As String
   
   RegBox.Cls
   
   Dim a As Long, b As Long, c As Long, d As Long, e As Long, f As Long, h As Long, g As Long
   Dim eflags As Long
   
   a = Form1.dbg.ReadRegister(Eax)
   b = Form1.dbg.ReadRegister(Ebx)
   c = Form1.dbg.ReadRegister(Ecx)
   d = Form1.dbg.ReadRegister(Ecx)
   e = Form1.dbg.ReadRegister(Esi)
   f = Form1.dbg.ReadRegister(edi)
   g = Form1.dbg.ReadRegister(esp)
   h = Form1.dbg.ReadRegister(ebp)
   i = Form1.dbg.ReadRegister(eip)
   
   push vals(), "EAX " & p(Hex(a)) & " " & SimpleSymbol(a)
   push vals(), "EBX " & p(Hex(b)) & " " & SimpleSymbol(b)
   push vals(), "ECX " & p(Hex(c)) & " " & SimpleSymbol(c)
   push vals(), "EDX " & p(Hex(d)) & " " & SimpleSymbol(d)
   push vals(), "ESI " & p(Hex(e)) & " " & SimpleSymbol(e)
   push vals(), "EDI " & p(Hex(f)) & " " & SimpleSymbol(f)
   push vals(), "ESP " & p(Hex(g)) & " " & SimpleSymbol(g)
   push vals(), "EBP " & p(Hex(h)) & " " & SimpleSymbol(h)
   push vals(), ""
   push vals(), "EIP " & p(Hex(i)) & " " & SimpleSymbol(i)
    
   For i = 0 To UBound(vals)
        RegBox.Print vals(i)
   Next
 
    eflags = Form1.dbg.ReadRegister(eflags)
    RegBox.Print ""
    
    push flags(), "C  " & (eflags And 1&)
    push flags(), "P  " & ((eflags And 4&) / 4&)
    push flags(), "A  " & ((eflags And 16&) / 16&)
    push flags(), "Z  " & ((eflags And 64&) / 64&)
    push flags(), "S  " & ((eflags And 128&) / 128&)
    push flags(), "T  " & ((eflags And 256&) / 256&)
    push flags(), "O  " & ((eflags And 2048&) / 2048&)

   For i = 0 To UBound(flags)
        RegBox.Print flags(i)
   Next
 


End Sub


Private Function p(x)
    Dim y As Long
    y = 8 - Len(x)
    If y > 0 Then
        p = String(y, "0") & x
    Else
        p = x
    End If
End Function


Sub RefreshStack()
    
    On Error Resume Next
    
    Dim top As Long
    Dim bottom As Long
    Dim i As Long
    Dim b() As Byte
    
    Stack.Cls
    bottom = Form1.dbg.ReadRegister(esp)
    top = Form1.dbg.ReadRegister(ebp)
        
    If (top - bottom) > 100 Then bottom = top - 100
    If Not Form1.dbg.ReadBuf(bottom, (top - bottom), b) Then Exit Sub
    
    Dim val As Long
    Dim s As String
    
    On Error Resume Next
    For i = 0 To UBound(b) Step 4
        CopyMemory val, b(i), 4
        s = Hex(val)
        While Len(s) < 8: s = "0" & s: Wend
        Stack.Print Hex((bottom + i)) & " " & s
    Next
    
    
  
End Sub

Sub DumpMemory(va As Long)
    Dim b() As Byte
    
    Memory.Cls
    If Not Form1.dbg.ReadBuf(va, 160, b) Then Exit Sub
    
    Memory.Print hexdump(va, b)
    
End Sub

Function GetSymbolForAsm(curva As Long, asm As String) As String
    Dim va As Long
    Dim tmp
    
    On Error Resume Next
    'there is ALLOT more decoding we could do here to recgonize addresses!
    'not to mention decoding known function prototypes and commenting asm!!
    'man thats allot of work...

    If InStr(asm, "CALL") > 0 Then
        If InStr(asm, "[") > 0 Then
            va = GetAddressFromPointer(curva, asm)
            GetSymbolForAsm = SimpleSymbol(va)
        Else
            'if this next line fails its not numeric..must be register CALL EAX
            tmp = Mid(asm, InStr(asm, "CALL") + 5)
            va = CLng("&h" & tmp)
            If Err.Number > 0 And Form1.dbg.ReadRegister(eip) = curva Then
                Select Case UCase(tmp)
                    Case "EAX": va = Form1.dbg.ReadRegister(Eax)
                    Case "EBX": va = Form1.dbg.ReadRegister(Eax)
                    Case "ECX": va = Form1.dbg.ReadRegister(Eax)
                    Case "EDX": va = Form1.dbg.ReadRegister(Eax)
                End Select
            End If
            GetSymbolForAsm = SimpleSymbol(va)
        End If
    ElseIf InStr(asm, "JMP") > 0 Then
        If InStr(asm, "[") > 0 Then
            va = GetAddressFromPointer(curva, asm)
            GetSymbolForAsm = SimpleSymbol(va)
        Else
            'if this next line fails its not numeric..must be register JMP EAX
            tmp = Mid(asm, InStr(asm, "JMP") + 4)
            va = CLng("&h" & tmp)
             If Err.Number > 0 And Form1.dbg.ReadRegister(eip) = curva Then
                Select Case UCase(tmp)
                    Case "EAX": va = Form1.dbg.ReadRegister(Eax)
                    Case "EBX": va = Form1.dbg.ReadRegister(Eax)
                    Case "ECX": va = Form1.dbg.ReadRegister(Eax)
                    Case "EDX": va = Form1.dbg.ReadRegister(Eax)
                End Select
            End If
            GetSymbolForAsm = SimpleSymbol(va)
        End If
    End If
    
End Function

Private Function GetAddressFromPointer(va As Long, cmd As String) As Long
    Dim tmp As String
    Dim s As Long
    Dim e As Long
    Dim adr As Long
    
    On Error Resume Next
    s = InStr(cmd, "[")
    e = InStr(s, cmd, "]")
    
    'if this next line fails its not numeric..must be register CALL [EAX]
    tmp = Mid(cmd, s + 1, e - s - 1)
    adr = CLng("&h" & tmp)
    
    If Err.Number > 0 And Form1.dbg.ReadRegister(eip) = va Then
        Select Case UCase(tmp)
            Case "EAX": adr = Form1.dbg.ReadRegister(Eax)
            Case "EBX": adr = Form1.dbg.ReadRegister(Eax)
            Case "ECX": adr = Form1.dbg.ReadRegister(Eax)
            Case "EDX": adr = Form1.dbg.ReadRegister(Eax)
        End Select
    End If
        
    Form1.dbg.ReadLng adr, adr
    GetAddressFromPointer = adr
hell:
    
End Function

