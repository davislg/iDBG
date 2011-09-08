VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CContext"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Public Dr0 As Long
Public Dr1 As Long
Public Dr2 As Long
Public Dr3 As Long
Public Dr6 As Long
Public Dr7 As Long
Public SegGs As Long
Public SegFs As Long
Public SegEs As Long
Public SegDs As Long
Public edi As Long
Public Esi As Long
Public Ebx As Long
Public Edx As Long
Public Ecx As Long
Public Eax As Long
Public ebp As Long
Public eip As Long
Public SegCs As Long
Public EFlags As Long
Public esp As Long
Public SegSs As Long

Friend Sub LoadContext(c As CONTEXT)
    
    With c
        Dr0 = .Dr0
        Dr1 = .Dr1
        Dr2 = .Dr2
        Dr3 = .Dr3
        Dr6 = .Dr6
        Dr7 = .Dr7
        SegGs = .SegGs
        SegFs = .SegFs
        SegEs = .SegEs
        SegDs = .SegDs
        edi = .edi
        Esi = .Esi
        Ebx = .Ebx
        Edx = .Edx
        Ecx = .Ecx
        Eax = .Eax
        ebp = .ebp
        eip = .eip
        SegCs = .SegCs
        EFlags = .EFlags
        esp = .esp
        SegSs = .SegSs
    End With
    
End Sub
