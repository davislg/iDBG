VERSION 5.00
Begin VB.Form frmLibDebug 
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
Attribute VB_Name = "frmLibDebug"
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
    Dim pth As String
    
    Set dbg = New CDebugger
    
    dbg.UseSymbols = True
    dbg.SymbolPath = "f:\symbols"
    
    pth = App.path & "\..\test2.exe"
    If Dir(pth) = "" Then
        MsgBox "Path not found " & pth
        Exit Sub
    End If
    
    If Not dbg.LaunchProcess(pth & " aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa") Then
        MsgBox "launch error:" & dbg.GetErr
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

    Dim e As String
    Const va = &H1006AE7
    Const va2 = &H401036
    Dim bp As Long
    
    dp "ReadyToRun...Adding startup bpxs"
        
    bp = va2
    
    If Not dbg.SetBreakPoint(bp) Then
        dp "Error adding at " & Hex(bp) & " error msg: "
    Else
        dp "Set Initial bpx at " & Hex(bp)
    End If
    
    'bp = dbg.ResolveExport("msvcrt", "printf")
    'dp "setting bp on GetProcAddress = 0x" & Hex(bp)
    'dbg.SetBreakPoint bp

    'dp "Injecting Winmain.dll worked? " & dbg.InjectDLL("C:\Documents and Settings\DZimmer\Desktop\dzdbg\winmain.dll")
            
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
