VERSION 5.00
Begin VB.Form Form1 
   BackColor       =   &H8000000A&
   Caption         =   "vb_dbg  -  http://sandsprite.com"
   ClientHeight    =   7545
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   11925
   LinkTopic       =   "Form1"
   ScaleHeight     =   7545
   ScaleWidth      =   11925
   StartUpPosition =   3  'Windows Default
   Begin VB.PictureBox pictMem 
      AutoRedraw      =   -1  'True
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   9
         Charset         =   255
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2235
      Left            =   0
      ScaleHeight     =   2235
      ScaleWidth      =   9375
      TabIndex        =   5
      Top             =   3660
      Width           =   9375
   End
   Begin VB.TextBox Text1 
      Appearance      =   0  'Flat
      Height          =   1275
      Left            =   0
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   4
      Top             =   5940
      Width           =   9375
   End
   Begin VB.PictureBox pictStack 
      AutoRedraw      =   -1  'True
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   9
         Charset         =   255
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3555
      Left            =   9480
      ScaleHeight     =   3555
      ScaleWidth      =   2415
      TabIndex        =   3
      Top             =   3660
      Width           =   2415
   End
   Begin VB.TextBox txtCommand 
      Appearance      =   0  'Flat
      BackColor       =   &H00E0E0E0&
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   9
         Charset         =   255
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF0000&
      Height          =   285
      Left            =   0
      TabIndex        =   2
      Top             =   7260
      Width           =   11895
   End
   Begin VB.PictureBox pictDisasm 
      AutoRedraw      =   -1  'True
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   9
         Charset         =   255
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3615
      Left            =   0
      ScaleHeight     =   3615
      ScaleWidth      =   9375
      TabIndex        =   1
      Top             =   0
      Width           =   9375
   End
   Begin VB.PictureBox pictRegBox 
      AutoRedraw      =   -1  'True
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   9
         Charset         =   255
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3615
      Left            =   9480
      ScaleHeight     =   3615
      ScaleWidth      =   2415
      TabIndex        =   0
      Top             =   0
      Width           =   2415
   End
   Begin VB.Line Line1 
      BorderWidth     =   3
      X1              =   13440
      X2              =   0
      Y1              =   3660
      Y2              =   3660
   End
   Begin VB.Line Line2 
      BorderWidth     =   2
      X1              =   9420
      X2              =   9420
      Y1              =   7260
      Y2              =   0
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit


Dim dm As New CDisplayManager
Public WithEvents dbg As CDebugger
Attribute dbg.VB_VarHelpID = -1
Dim entrypoint As Long

Private Sub dbg_DebugString(msg As String)
 Additem "Debug String: " & msg
End Sub

Private Sub dbg_DllLoad(path As String, base As Long, size As Long)
    Additem "DllLoaded: " & Hex(base) & " " & path
End Sub

Private Sub dbg_Exception(except As iDbg.CException)
    Additem "Exception " & except.CrashInModule & " " & Hex(except.ExceptionAddress) & " Code: " & Hex(except.ExceptionCode)
    dm.Refresh
End Sub

Private Sub dbg_ReadyToRun()
    
    
    Dim c As New CPEOffsets
    If c.LoadFile(dbg.LoadedFile) Then
        entrypoint = c.ImageBase + c.AddressOfEntryPoint
        If dbg.SetBreakPoint(entrypoint, True) Then
            Additem "Debugee Loaded at first breakpoint jumping to module entry point " & Hex(entrypoint)
            dbg.dbgContinue
            Exit Sub
        End If
    End If
        
    
    Additem "Debugee loaded and ready to run."
    dm.Refresh
    dm.DumpMemory dbg.ReadRegister(esp)
    
End Sub

Private Sub dbg_SingleStep(except As iDbg.CException)
    Additem "SingleStep " & Hex(except.ExceptionAddress)
    dm.Refresh
End Sub

Private Sub dbg_Terminate()
    Additem "Debugee Terminated"
End Sub

Private Sub dbg_ThreadCreate(threadID As Long, startAddress As Long)
    Additem "New thread id: " & threadID & " Start Addr: " & Hex(startAddress)
End Sub

Private Sub dbg_ThreadDestroy(threadID As Long, exitCode As Long)
    Additem "Thread terminated id: " & threadID
End Sub

Private Sub dbg_UserBreakpoint(except As iDbg.CException)
    If except.ExceptionAddress = entrypoint Then
        Additem "Stopped At program entrypoint."
        dm.DumpMemory dbg.ReadRegister(esp)
    Else
        Additem "Breakpoint " & except.CrashInModule & " " & Hex(except.ExceptionAddress) & " Code: " & Hex(except.ExceptionCode)
    End If
    dm.Refresh
End Sub

Private Sub Form_Load()

    Set dbg = New CDebugger
    Set dm.Display = pictDisasm
    Set dm.RegBox = pictRegBox
    Set dm.Stack = pictStack
    Set dm.Memory = pictMem
    
    Dim sp As String
    sp = Environ("_NT_SYMBOL_PATH")
    If Len(sp) > 0 Then
        dbg.UseSymbols = True
        dbg.SymbolPath = sp
    End If
    
    Additem "iDbg Test UI v" & App.Major & "." & App.Minor & " Enter command into textbox below. Type ? for help"
    
End Sub

Private Sub txtCommand_KeyDown(KeyCode As Integer, Shift As Integer)
    
    'single key commands
    Select Case KeyCode
        Case 46: txtCommand = Empty         'delete key = clear
        Case 118: dbg.StepInto              'F7 single step
        Case 119: dbg.StepOver              'F8 step over
        Case 116: dbg.dbgContinue           'F5 run
    End Select
    
    If KeyCode <> 13 Then Exit Sub 'return key = process string command
        
    Dim x() As String
    x = Split(Trim(txtCommand), " ")
    
    On Error GoTo hell
    
    Select Case UCase(x(0))
        Case "ATTACH":
                        Dim c As CProcess
                        If dbg.SelectProcess(c) Then
                            Additem "Attaching to: " & c.path & " result = " & dbg.Attach(c.pid)
                        End If
                        
        Case "STOP", "QUIT", "Q": dbg.StopDbg: dm.ClearAll
        Case "END": dbg.StopDbg: Unload Me
        Case "LOAD": Additem "", True: dbg.LaunchProcess x(1)
        Case "RUN": dbg.dbgContinue
        Case "STEP", "S": dbg.StepInto
        Case "STEPOVER", "SO", "O": dbg.StepOver
        Case "BPX", "BP": dbg.SetBreakPoint CLng("&h" & x(1))
        Case "GO": dbg.SetBreakPoint CLng("&h" & x(1)): dbg.dbgContinue
        Case "BC": dbg.RemoveBreakpoint CLng("&h" & x(1))
        Case "REFRESH": dm.Refresh
        Case "WRITEB": dbg.WriteByte CLng("&h" & x(1)), CByte("&h" & x(2)): dm.Refresh
        Case "EIP": dbg.ModifyRegister eip, CLng("&h" & x(1)): dm.Refresh
        Case "EAX": dbg.ModifyRegister Eax, CLng("&h" & x(1)): dm.Refresh
        Case "EBX":  dbg.ModifyRegister Ebx, CLng("&h" & x(1)): dm.Refresh
        Case "ECX":  dbg.ModifyRegister Ecx, CLng("&h" & x(1)): dm.Refresh
        Case "EDX":  dbg.ModifyRegister Edx, CLng("&h" & x(1)): dm.Refresh
        Case "WRITEL": dbg.WriteLong CLng("&h" & x(1)), CLng("&h" & x(2)): dm.Refresh
        Case "PAUSE", "BREAK": dbg.SuspendThreads: dm.Refresh
        Case "RESUME": dbg.ResumeThreads
        Case "BL": Additem Join(BreakpointList, vbCrLf), True
        Case "MODS": Additem Join(GetMods, vbCrLf), True
        Case "THREADS": Additem Join(GetThreads, vbCrLf), True
        Case "MEM": dm.DumpMemory CLng("&h" & x(1))
        Case "CLEAR", "CLS": Text1 = Empty
        Case "INJECT", "INJ": Additem ("Injected: " & x(1) & " ? " & dbg.InjectDLL(CStr(x(1))))
        Case "HELP", "?": MsgBox "This is a minimal interface around the iDbg debugger library. You can use it as a template for a debug interface to pop up when  you want to probe manually during automated debugging.", vbExclamation
        Case Else: MsgBox "Unknown Cmd:" & x(0)
    End Select
        
    Exit Sub
hell: MsgBox "Error: " & Err.Description, vbInformation
           
End Sub

Function BreakpointList() As String()
    Dim b As CBreakPoint
    Dim ret() As String
    For Each b In dbg.BreakPoints
        push ret, Hex(b.va) & " isSet? " & b.isSet
    Next
    BreakpointList = ret
End Function

Function GetMods() As String()
     Dim m As CModule
     Dim ret() As String
     For Each m In dbg.Modules
        push ret, Hex(m.base) & " " & m.path
     Next
     GetMods = ret
End Function

Function GetThreads()
    Dim t, ret() As String, i, cc As CContext
    For Each t In dbg.Threads
        i = i + 1
        Set cc = dbg.Get_ThreadContext(CLng(t))
        push ret, i & " Thread Handle: " & Hex(t) & " eip= " & Hex(cc.eip)
    Next
    GetThreads = ret
End Function
   
