Attribute VB_Name = "Module1"
Option Explicit
 
Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)


Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    Dim x As Long
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = value
    Exit Sub
init:     ReDim ary(0): ary(0) = value
End Sub



Function KeyExistsInCollection(c As Collection, val As String) As Boolean
    On Error GoTo nope
    Dim t
    t = c(val)
    KeyExistsInCollection = True
 Exit Function
nope: KeyExistsInCollection = False
End Function



Function shexdump(it)
    Dim my, i, c, s, a, b
    Dim lines() As String
    
    my = ""
    For i = 1 To Len(it)
        a = Asc(Mid(it, i, 1))
        c = Hex(a)
        c = IIf(Len(c) = 1, "0" & c, c)
        b = b & IIf(a > 65 And a < 120, Chr(a), ".")
        my = my & c & " "
        If i Mod 16 = 0 Then
            push lines(), my & "  [" & b & "]"
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
        push lines(), my & "  [" & b & "]"
    End If
        
    If Len(it) < 16 Then
        shexdump = my & "  [" & b & "]" & vbCrLf
    Else
        shexdump = Join(lines, vbCrLf)
    End If
    
    
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



Function FileExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True _
  Else FileExists = False
End Function

Function Pad(ByVal dat As String, Optional ByVal padLen As Long = 30)
    Dim x As Long
    x = Len(dat)
    padLen = padLen - x
    If padLen < 1 Then
        Pad = dat
    Else
        Pad = dat & Space(padLen)
    End If
End Function


Sub Additem(msg, Optional fresh As Boolean = False)
    If fresh Then Form1.Text1 = Empty
    With Form1.Text1
        .SelStart = Len(.Text)
        .SelLength = 0
        .SelText = msg & vbCrLf
        .SelLength = Len(.Text)
    End With
End Sub

