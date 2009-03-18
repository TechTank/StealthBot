VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomctl.ocx"
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "richtx32.ocx"
Begin VB.Form frmScript 
   BackColor       =   &H00000000&
   Caption         =   "Scripting UI"
   ClientHeight    =   3090
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   4680
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   ScaleHeight     =   3090
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin MSComctlLib.TreeView trv 
      Height          =   615
      Index           =   0
      Left            =   2880
      TabIndex        =   10
      Top             =   0
      Visible         =   0   'False
      Width           =   735
      _ExtentX        =   1296
      _ExtentY        =   1085
      _Version        =   393217
      Style           =   7
      Appearance      =   1
   End
   Begin VB.CommandButton cmd 
      Height          =   255
      Index           =   0
      Left            =   0
      TabIndex        =   8
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.TextBox txt 
      Height          =   285
      Index           =   0
      Left            =   600
      MultiLine       =   -1  'True
      TabIndex        =   7
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.PictureBox pic 
      Height          =   255
      Index           =   0
      Left            =   960
      ScaleHeight     =   195
      ScaleWidth      =   195
      TabIndex        =   6
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.CheckBox chk 
      Height          =   255
      Index           =   0
      Left            =   1320
      TabIndex        =   5
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.OptionButton opt 
      Height          =   255
      Index           =   0
      Left            =   1680
      TabIndex        =   4
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.ComboBox cmb 
      Height          =   315
      Index           =   0
      Left            =   2040
      TabIndex        =   3
      Top             =   0
      Visible         =   0   'False
      Width           =   390
   End
   Begin VB.ListBox lst 
      Height          =   255
      Index           =   0
      Left            =   2520
      TabIndex        =   2
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin RichTextLib.RichTextBox rtb 
      Height          =   255
      Index           =   0
      Left            =   360
      TabIndex        =   0
      Top             =   360
      Visible         =   0   'False
      Width           =   495
      _ExtentX        =   873
      _ExtentY        =   450
      _Version        =   393217
      Enabled         =   -1  'True
      ScrollBars      =   2
      TextRTF         =   $"frmScript.frx":0000
   End
   Begin MSComctlLib.ImageList iml 
      Index           =   0
      Left            =   960
      Top             =   360
      _ExtentX        =   1005
      _ExtentY        =   1005
      BackColor       =   -2147483643
      MaskColor       =   12632256
      _Version        =   393216
   End
   Begin MSComctlLib.ListView lsv 
      Height          =   375
      Index           =   0
      Left            =   0
      TabIndex        =   1
      Top             =   360
      Visible         =   0   'False
      Width           =   255
      _ExtentX        =   450
      _ExtentY        =   661
      View            =   3
      LabelEdit       =   1
      LabelWrap       =   0   'False
      HideSelection   =   -1  'True
      HideColumnHeaders=   -1  'True
      OLEDragMode     =   1
      _Version        =   393217
      ForeColor       =   -2147483640
      BackColor       =   -2147483643
      BorderStyle     =   1
      Appearance      =   1
      OLEDragMode     =   1
      NumItems        =   0
   End
   Begin VB.Label lbl 
      BackColor       =   &H00000000&
      Caption         =   "lbl"
      ForeColor       =   &H00FFFFFF&
      Height          =   255
      Index           =   0
      Left            =   360
      TabIndex        =   9
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.Shape shp 
      Height          =   255
      Index           =   0
      Left            =   2880
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.Line lin 
      Index           =   0
      Visible         =   0   'False
      X1              =   720
      X2              =   1920
      Y1              =   480
      Y2              =   480
   End
End
Attribute VB_Name = "frmScript"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private m_name      As String
Private m_sc_module As Module
Private m_arrObjs() As modScripting.scObj
Private m_objCount  As Integer
Private m_hidden    As Boolean

Public Function setName(ByVal str As String)

    If (m_name = vbNullString) Then
        m_name = str
    End If

End Function

Public Function getName() As String

    getName = m_name

End Function

Public Function setSCModule(ByRef SCModule As Module)

    If (m_sc_module Is Nothing) Then
        Set m_sc_module = SCModule
    End If

End Function

Public Function getSCModule() As Module

    Set getSCModule = m_sc_module

End Function

Private Function ObjCount(Optional ObjType As String) As Integer
    
    Dim I As Integer ' ...

    If (ObjType <> vbNullString) Then
        For I = 0 To m_objCount - 1
            If (StrComp(ObjType, m_arrObjs(I).ObjType, vbTextCompare) = 0) Then
                ObjCount = (ObjCount + 1)
            End If
        Next I
    Else
        ObjCount = m_objCount
    End If

End Function

Public Function CreateObj(ByVal ObjType As String, ByVal ObjName As String) As Object

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' redefine array size & check for duplicate controls
    If (m_objCount) Then
        Dim I As Integer ' loop counter variable

        For I = 0 To m_objCount - 1
            If (StrComp(m_arrObjs(I).ObjType, ObjType, vbTextCompare) = 0) Then
                If (StrComp(m_arrObjs(I).ObjName, ObjName, vbTextCompare) = 0) Then
                    Set CreateObj = m_arrObjs(I).obj
                
                    Exit Function
                End If
            End If
        Next I
        
        ReDim Preserve m_arrObjs(0 To m_objCount)
    Else
        ReDim m_arrObjs(0)
    End If

    Select Case (UCase$(ObjType))
        Case "BUTTON"
            If (ObjCount(ObjType) > 0) Then
                Load cmd(ObjCount(ObjType))
            End If
            
            Set obj.obj = cmd(ObjCount(ObjType))
        
        Case "CHECKBOX"
            If (ObjCount(ObjType) > 0) Then
                Load chk(ObjCount(ObjType))
            End If
            
            Set obj.obj = chk(ObjCount(ObjType))
        
        Case "COMBOXBOX"
            If (ObjCount(ObjType) > 0) Then
                Load cmb(ObjCount(ObjType))
            End If
            
            Set obj.obj = cmb(ObjCount(ObjType))
        
        Case "IMAGELIST"
            If (ObjCount(ObjType) > 0) Then
                Load iml(ObjCount(ObjType))
            End If
            
            Set obj.obj = iml(ObjCount(ObjType))
        
        Case "LABEL"
            If (ObjCount(ObjType) > 0) Then
                Load lbl(ObjCount(ObjType))
            End If
            
            Set obj.obj = lbl(ObjCount(ObjType))
        
        Case "LISTBOX"
            If (ObjCount(ObjType) > 0) Then
                Load lst(ObjCount(ObjType))
            End If
            
            Set obj.obj = lst(ObjCount(ObjType))
        
        Case "LISTVIEW"
            If (ObjCount(ObjType) > 0) Then
                Load lsv(ObjCount(ObjType))
            End If
            
            Set obj.obj = lsv(ObjCount(ObjType))
        
        Case "OPTIONBUTTON"
            If (ObjCount(ObjType) > 0) Then
                Load opt(ObjCount(ObjType))
            End If
            
            Set obj.obj = opt(ObjCount(ObjType))
        
        Case "PICTUREBOX"
            If (ObjCount(ObjType) > 0) Then
                Load pic(ObjCount(ObjType))
            End If
            
            Set obj.obj = pic(ObjCount(ObjType))
        
        Case "RICHTEXTBOX"
            If (ObjCount(ObjType) > 0) Then
                Load rtb(ObjCount(ObjType))
            End If
            
            Set obj.obj = rtb(ObjCount(ObjType))
            
            EnableURLDetect obj.obj.hWnd
        
        Case "TEXTBOX"
            If (ObjCount(ObjType) > 0) Then
                Load txt(ObjCount(ObjType))
            End If
            
            Set obj.obj = txt(ObjCount(ObjType))
            
        Case "TREEVIEW"
            If (ObjCount(ObjType) > 0) Then
                Load trv(ObjCount(ObjType))
            End If
            
            Set obj.obj = trv(ObjCount(ObjType))
    End Select
    
    ' ...
    obj.obj.Visible = True

    ' store our module name & type
    obj.ObjName = ObjName
    obj.ObjType = ObjType
    
       ' store object
    m_arrObjs(m_objCount) = obj
    
    ' increment object counter
    m_objCount = (m_objCount + 1)

    ' return object
    Set CreateObj = obj.obj

End Function

Public Sub DestroyObjs()

    On Error GoTo ERROR_HANDLER

    Dim I As Integer ' ...
    
    ' ...
    For I = m_objCount - 1 To 0 Step -1
        DestroyObj m_arrObjs(I).ObjName
    Next I
    
    ' ...
    Exit Sub

ERROR_HANDLER:
    
    frmChat.AddChat vbRed, _
        "Error (#" & Err.Number & "): " & Err.description & " in frmScript::DestroyObjs()."
        
    Resume Next
    
End Sub

Public Sub DestroyObj(ByVal ObjName As String)

    On Error GoTo ERROR_HANDLER

    Dim I     As Integer ' ...
    Dim Index As Integer ' ...
    
    ' ...
    If (m_objCount = 0) Then
        Exit Sub
    End If
    
    ' ...
    Index = m_objCount
    
    ' ...
    For I = 0 To m_objCount - 1
        If (StrComp(m_arrObjs(I).ObjName, ObjName, vbTextCompare) = 0) Then
            Index = I
        
            Exit For
        End If
    Next I
    
    ' ...
    For I = m_objCount - 1 To 0 Step -1
        Select Case (UCase$(m_arrObjs(I).ObjType))
            Case "BUTTON"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload cmd(m_arrObjs(I).obj.Index)
                Else
                    cmd(0).Visible = False
                End If
            
            Case "CHECKBOX"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload chk(m_arrObjs(I).obj.Index)
                Else
                    chk(0).Visible = False
                End If
            
            Case "COMBOXBOX"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload cmb(m_arrObjs(I).obj.Index)
                Else
                    cmb(0).Visible = False
                End If
            
            Case "IMAGELIST"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload iml(m_arrObjs(I).obj.Index)
                Else
                    iml(0).ListImages.Clear
                End If
            
            Case "LABEL"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload lbl(m_arrObjs(I).obj.Index)
                Else
                    lbl(0).Visible = False
                End If
            
            Case "LISTBOX"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload lst(m_arrObjs(I).obj.Index)
                Else
                    With lst(0)
                        .Clear
                        .Visible = False
                    End With
                End If
            
            Case "LISTVIEW"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload lsv(m_arrObjs(I).obj.Index)
                Else
                    With lsv(0)
                        .ListItems.Clear
                        .Visible = False
                    End With
                End If
            
            Case "OPTIONBUTTON"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload opt(m_arrObjs(I).obj.Index)
                Else
                    opt(0).Visible = False
                End If
            
            Case "PICTUREBOX"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload pic(m_arrObjs(I).obj.Index)
                Else
                    pic(0).Visible = False
                End If
            
            Case "RICHTEXTBOX"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload rtb(m_arrObjs(I).obj.Index)
                Else
                    With rtb(0)
                        .text = ""
                        .Visible = False
                    End With
                End If
            
            Case "TEXTBOX"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload txt(m_arrObjs(I).obj.Index)
                Else
                    With txt(0)
                        .text = ""
                        .Visible = False
                    End With
                End If
                
            Case "TREEVIEW"
                If (m_arrObjs(I).obj.Index > 0) Then
                    Unload trv(m_arrObjs(I).obj.Index)
                Else
                    With trv(0)
                        .Nodes.Clear
                        .Visible = False
                    End With
                End If
        End Select
        
        ' ...
        Set m_arrObjs(I).obj = Nothing
    Next I
    
    ' ...
    If (Index < m_objCount) Then
        For I = Index To ((m_objCount - 1) - 1)
            m_arrObjs(I) = m_arrObjs(I + 1)
        Next I
    End If
    
    ' ...
    If (m_objCount > 1) Then
        ReDim Preserve m_arrObjs(0 To m_objCount - 1)
    Else
        ReDim m_arrObjs(0)
    End If
    
    ' ...
    m_objCount = (m_objCount - 1)
    
    ' ...
    Exit Sub
    
ERROR_HANDLER:
    
    frmChat.AddChat vbRed, _
        "Error (#" & Err.Number & "): " & Err.description & " in frmScript::DestroyObjs()."
        
    Resume Next
    
End Sub

Public Function GetObjByName(ByVal ObjName As String) As Object

    Dim I As Integer ' ...
    
    ' ...
    For I = 0 To m_objCount - 1
        If (StrComp(m_arrObjs(I).ObjName, ObjName, vbTextCompare) = 0) Then
            Set GetObjByName = m_arrObjs(I).obj

            Exit Function
        End If
    Next I
    
End Function

Private Function GetSCObjByIndex(ByVal ObjType As String, ByVal Index As Integer) As scObj

    Dim I As Integer ' ...

    For I = 0 To m_objCount - 1
        If (StrComp(ObjType, m_arrObjs(I).ObjType, vbTextCompare) = 0) Then
            If (m_arrObjs(I).obj.Index = Index) Then
                GetSCObjByIndex = m_arrObjs(I)
                
                Exit For
            End If
        End If
    Next I
    
End Function

Public Sub ClearObjs()

    On Error GoTo ERROR_HANDLER

    Dim I As Integer ' ...
    
    ' ...
    For I = m_objCount - 1 To 0 Step -1
        Select Case (UCase$(m_arrObjs(I).ObjType))
            Case "CHECKBOX"
                chk(m_arrObjs(I).obj.Index).Value = vbUnchecked
                
            Case "COMBOXBOX"
                cmb(m_arrObjs(I).obj.Index).text = ""
            
            Case "IMAGELIST"
                iml(m_arrObjs(I).obj.Index).ListImages.Clear
            
            Case "LISTBOX"
                lst(m_arrObjs(I).obj.Index).Clear
            
            Case "LISTVIEW"
                lsv(m_arrObjs(I).obj.Index).ListItems.Clear
            
            Case "OPTIONBUTTON"
                opt(m_arrObjs(I).obj.Index).Value = False

            Case "PICTUREBOX"
                pic(m_arrObjs(I).obj.Index).Picture = Nothing

            Case "RICHTEXTBOX"
                rtb(m_arrObjs(I).obj.Index).text = ""
                
                DisableURLDetect m_arrObjs(I).obj.hWnd
                
            Case "TEXTBOX"
                txt(m_arrObjs(I).obj.Index).text = ""
        End Select
    Next I

    Exit Sub

ERROR_HANDLER:
    
    frmChat.AddChat vbRed, _
        "Error (#" & Err.Number & "): " & Err.description & " in ClearObjs()."
        
    Resume Next
    
End Sub

Public Sub AddChat(ByVal rtbName As String, ParamArray saElements() As Variant)

    Dim arr() As Variant ' ...
    
    ' ...
    arr() = saElements
    
    ' ...
    Call DisplayRichText(GetObjByName(rtbName), arr)
    
End Sub

'//////////////////////////////////////////////////////
'//Events
'//////////////////////////////////////////////////////

Public Sub Initialize()

    On Error Resume Next
    
    ' ...
    m_sc_module.Run m_name & "_Initialize"

    ' ...
    m_sc_module.Run m_name & "_Load"

End Sub

Private Sub Form_Activate()

    On Error Resume Next
    
    ' ...
    m_sc_module.Run m_name & "_Activate"

End Sub

Private Sub Form_Click()

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_Click"

End Sub

Private Sub Form_DblClick()

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_DblClick"

End Sub

Private Sub Form_Deactivate()

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_Deactivate"

End Sub

Private Sub Form_GotFocus()

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_GotFocus"

End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_KeyDown", KeyCode, Shift

End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_KeyPress", KeyAscii

End Sub

Private Sub Form_KeyUp(KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_KeyUp", KeyCode, Shift

End Sub

Private Sub Form_LostFocus()

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_LostFocus"

End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub Form_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub Form_Paint()

    On Error Resume Next
    
    ' ...
    If (m_hidden = True) Then
        m_sc_module.Run m_name & "_Load"
        
        m_hidden = False
    End If

    ' ...
    m_sc_module.Run m_name & "_Paint"

End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_QueryUnload", UnloadMode

End Sub

Private Sub Form_Resize()

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_Resize"

End Sub

Private Sub Form_Terminate()

    On Error Resume Next

    ' ...
    m_sc_module.Run m_name & "_Terminate"

End Sub

Public Sub Form_Unload(Cancel As Integer)

    On Error Resume Next

    ' ...
    If (m_hidden = False) Then
        ' ...
        Me.Hide
        
        ' ...
        m_sc_module.Run m_name & "_Unload", Cancel
        
        ' ...
        m_hidden = True
        
        ' ...
        Cancel = 1
    End If

End Sub

Private Sub cmd_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub cmd_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub cmd_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub cmd_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub cmd_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Index, Button, Shift, X, Y

End Sub

Private Sub cmd_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub cmd_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub cmd_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub cmd_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Button", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub lbl_Change(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Label", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Change"

End Sub

Private Sub lbl_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Label", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub lbl_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Label", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub lbl_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Label", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub lbl_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Label", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub lbl_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("Label", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub lst_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"
    
End Sub

Private Sub lst_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub lst_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub lst_ItemCheck(Index As Integer, Item As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_ItemCheck", Item

End Sub

Private Sub lst_ItemClick(Index As Integer, Item As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_ItemClick", Item

End Sub

Private Sub lst_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode

End Sub

Private Sub lst_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub lst_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub lst_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub lst_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub lst_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub lst_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub lst_Scroll(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Scroll"

End Sub

Private Sub lsv_ColumnClick(Index As Integer, ByVal ColumnHeader As ColumnHeader)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_ColumnClick", ColumnHeader

End Sub

Private Sub lsv_AfterLabelEdit(Index As Integer, Cancel As Integer, NewString As String)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_AfterLabelEdit", Cancel, NewString

End Sub

Private Sub lsv_BeforeLabelEdit(Index As Integer, Cancel As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_BeforeLabelEdit", Cancel

End Sub

Private Sub lsv_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub lsv_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub lsv_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub lsv_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub lsv_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub lsv_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub lsv_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub lsv_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub lsv_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub lsv_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ListView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub opt_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub opt_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub opt_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub opt_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub opt_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub opt_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub opt_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub opt_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub opt_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub opt_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("OptionButton", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub pic_Change(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Change"

End Sub

Private Sub pic_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub pic_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub pic_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub pic_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub pic_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub pic_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub pic_LinkClose(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LinkClose"

End Sub

Private Sub pic_LinkError(Index As Integer, LinkErr As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LinkError", LinkErr

End Sub

Private Sub pic_LinkNotify(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LinkNotify"

End Sub

Private Sub pic_LinkOpen(Index As Integer, Cancel As Integer)

     On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LinkOpen", Cancel

End Sub

Private Sub pic_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub pic_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub pic_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub pic_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)
 
    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub pic_Paint(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Paint"

End Sub

Private Sub pic_Resize(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("PictureBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Resize"
    
End Sub

Private Sub rtb_Change(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Change"

End Sub

Private Sub rtb_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub rtb_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub rtb_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub rtb_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub rtb_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii
End Sub

Private Sub rtb_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub rtb_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub rtb_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub rtb_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)
 
    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub rtb_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub rtb_SelChange(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("RichTextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_SelChange"

End Sub

Private Sub txt_Change(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)

    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Change"

End Sub

Private Sub txt_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub txt_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub txt_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub txt_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub txt_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y

End Sub

Private Sub txt_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)
    
    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub txt_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub txt_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub txt_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub txt_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TextBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub chk_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub chk_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub chk_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub chk_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub chk_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub chk_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub chk_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseDown", Button, Shift, X, Y

End Sub

Private Sub chk_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseMove", Button, Shift, X, Y
End Sub

Private Sub chk_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("CheckBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_MouseUp", Button, Shift, X, Y

End Sub

Private Sub cmb_Change(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Change"

End Sub

Private Sub cmb_Click(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Click"

End Sub

Private Sub cmb_DblClick(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_DblClick"

End Sub

Private Sub cmb_GotFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_GotFocus"

End Sub

Private Sub cmb_KeyDown(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyDown", KeyCode, Shift

End Sub

Private Sub cmb_KeyPress(Index As Integer, KeyAscii As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyPress", KeyAscii

End Sub

Private Sub cmb_KeyUp(Index As Integer, KeyCode As Integer, Shift As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_KeyUp", KeyCode, Shift

End Sub

Private Sub cmb_LostFocus(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_LostFocus"

End Sub

Private Sub cmb_Scroll(Index As Integer)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("ComboBox", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_Scroll"

End Sub

Private Sub trv_AfterLabelEdit(Index As Integer, Cancel As Integer, NewString As String)

    On Error Resume Next

    Dim obj As scObj ' ...
    
    ' ...
    obj = GetSCObjByIndex("TreeView", Index)
    
    ' ...
    m_sc_module.Run m_name & "_" & obj.ObjName & "_AfterLabelEdit", Cancel, NewString

End Sub

