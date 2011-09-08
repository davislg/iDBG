VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomctl.ocx"
Begin VB.Form frmListProcess 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Choose Process"
   ClientHeight    =   3630
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4455
   LinkTopic       =   "frmListProcess"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3630
   ScaleWidth      =   4455
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton Command1 
      Caption         =   "Select"
      Height          =   315
      Left            =   3420
      TabIndex        =   1
      Top             =   3300
      Width           =   975
   End
   Begin MSComctlLib.ListView lv 
      Height          =   3255
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   4455
      _ExtentX        =   7858
      _ExtentY        =   5741
      View            =   3
      LabelEdit       =   1
      LabelWrap       =   -1  'True
      HideSelection   =   -1  'True
      FullRowSelect   =   -1  'True
      GridLines       =   -1  'True
      _Version        =   393217
      ForeColor       =   -2147483640
      BackColor       =   -2147483643
      BorderStyle     =   1
      Appearance      =   1
      NumItems        =   3
      BeginProperty ColumnHeader(1) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         Text            =   "PID"
         Object.Width           =   706
      EndProperty
      BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   1
         Text            =   "USER"
         Object.Width           =   2540
      EndProperty
      BeginProperty ColumnHeader(3) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   2
         Text            =   "PATH"
         Object.Width           =   2540
      EndProperty
   End
End
Attribute VB_Name = "frmListProcess"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'License:   GPL
'Copyright: 2005 iDefense a Verisign Company
'Site:      http://labs.idefense.com
'
'Author:  David Zimmer <david@idefense.com, dzzie@yahoo.com>
'
'         disassembler functionality provided by olly.dll which
'         is a modified version of the OllyDbg GPL source from
'         Oleh Yuschuk Copyright (C) 2001 - http://ollydbg.de
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

Dim selli As ListItem

Private Sub Command1_Click()
    
    If selli Is Nothing Then
        MsgBox "Select processes"
        Exit Sub
    End If

    Me.Visible = False
    
End Sub

Function SelectProcess(c As Collection) As CProcess

    Dim p As CProcess
    Dim li As ListItem
    
    lv.ListItems.Clear
    
    For Each p In c
        Set li = lv.ListItems.Add(, , p.pid)
        Set li.Tag = p
        li.SubItems(1) = p.User
        li.SubItems(2) = p.path
    Next
    
    On Error Resume Next
    Me.Show 1
    
    If selli Is Nothing Then Exit Function
    Set SelectProcess = selli.Tag
    Unload Me
    
End Function
 

Private Sub Form_Unload(Cancel As Integer)
    On Error Resume Next
    Set selli = Nothing
End Sub

Private Sub lv_DblClick()
    Command1_Click
End Sub

Private Sub lv_ItemClick(ByVal Item As MSComctlLib.ListItem)
    Set selli = Item
End Sub
