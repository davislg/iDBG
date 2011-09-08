VERSION 5.00
Begin VB.Form frmLibDebug2 
   Caption         =   "Form1"
   ClientHeight    =   4125
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6660
   LinkTopic       =   "Form1"
   ScaleHeight     =   4125
   ScaleWidth      =   6660
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton Command1 
      Caption         =   "Command1"
      Height          =   495
      Left            =   5160
      TabIndex        =   1
      Top             =   3480
      Width           =   1215
   End
   Begin VB.ListBox List1 
      Height          =   3375
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   6615
   End
End
Attribute VB_Name = "frmLibDebug2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim WithEvents dbg As CDebugger
Attribute dbg.VB_VarHelpID = -1

Sub dp(msg)
    List1.AddItem msg
End Sub

Private Sub Command1_Click()
    Dim e As String
    Dim pid As Long
    
    Set dbg = New CDebugger
    
    dbg.UseSymbols = True
    dbg.SymbolPath = "f:\symbols"
    
    On Error Resume Next
    Shell "notepad.exe", vbNormalFocus
    DoEvents
    DoEvents
    DoEvents
    
    
    Dim p As CProcess
    Dim pp As New CProcessInfo
    Dim c As New Collection
    
    Set c = pp.GetRunningProcesses()
    For Each p In c
        If InStr(1, p.path, "notepad.exe", vbTextCompare) > 0 Then
            pid = p.pid
            Exit For
        End If
    Next
    
    If pid = 0 Then pid = InputBox("Enter pid to attach to")
    If pid = 0 Then Exit Sub
        
    If Not dbg.Attach(pid) Then
        MsgBox "attach error:" & dbg.GetErr
    End If
    
End Sub

Private Sub dbg_DebugString(msg As String)
    dp "Debug string: " & msg
End Sub

Private Sub dbg_DevMessage(func As String, msg As String)
    If func = "InjectDll" Then
        MsgBox msg
    Else
        List1.AddItem "DevMsg: " & func & " " & msg
    End If
End Sub

Private Sub dbg_DllLoad(path As String, base As Long, size As Long)
    dp "Loading dll " & path & " at base " & Hex(base)
End Sub

Private Sub dbg_Exception(except As CException) 'you must call continue/step* to resume
  
        
        dp "Exception code " & Hex(except.ExceptionCode) & " at addr 0x" & Hex(except.ExceptionAddress)
             
        If except.ExceptionCode = dbg.LastEventCode And _
            except.ExceptionAddress = dbg.LastEventAddress Then
                dp "Same crash killing"
                dbg.StopDbg
        Else
            If except.ExceptionAddress = &H401050 Then
                MsgBox except.Enviroment
                dbg.Continue DBG_EXCEPTION_NOT_HANDLED
                List1.List(List1.ListCount - 1) = List1.List(List1.ListCount - 1) & " -- passing to its err handlers"
            Else
                dbg.Continue
            End If
        End If
        
   
End Sub

Private Sub dbg_ReadyToRun()

    
    dp "ReadyToRun...injecting dll"
        
    dbg.SetModuleBpx "winmain.dll", &H1020
    dp "Injecting Winmain.dll worked? " & dbg.InjectDLL("C:\winmain\Debug\winmain.dll")
            
            
End Sub

Private Sub dbg_SingleStep(except As CException)
     dp "Single step at addr " & Hex(except.ExceptionAddress) & " disasm = " & except.Disasm & " return value from call was (eax) = " & Hex(dbg.ReadRegister(Eax))
     dbg.Continue
End Sub

Private Sub dbg_Terminate()
    dp "Terminating"
End Sub

Private Sub dbg_ThreadCreate(threadID As Long, startAddress As Long)
    dp "Thread Created: " & threadID & " at " & Hex(startAddress)
End Sub

Private Sub dbg_ThreadDestroy(threadID As Long, exitCode As Long)
    dp "Thread " & threadID & " exited with code " & exitCode
End Sub

Private Sub dbg_UserBreakpoint(except As CException) 'you must call continue/step* to resume
    Dim l As Long
    Dim pFormat As Long
    Dim validPointer As Boolean
    Dim msg As String
    
    l = dbg.ReadRegister(esp)
    If dbg.ReadLng(l, pFormat) Then validPointer = True
    
    msg = "UserBreakpoint @ " & Hex(except.ExceptionAddress) & _
        " Disasm = " & dbg.CurrentInstruction & _
        " Esp = " & Hex(l)
    
    If validPointer Then
        msg = msg & dbg.GetMemory(pFormat, True)
    Else
        msg = msg & dbg.GetMemory(l, True)
    End If
        
    dp msg
    
    dbg.StepOver
    'dbg.Continue
    
End Sub



Private Sub Form_Unload(Cancel As Integer)
  dbg.StopDbg
End Sub
