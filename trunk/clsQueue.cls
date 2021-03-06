VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsQueue"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' clsQueue.cls
' Copyright (C) 2008 Eric Evans

Option Explicit

Private Const MAX_PRIORITY_LEVEL = 100

Private m_QueueObjs() As clsQueueOBj
Private m_objCount    As Long
Private m_lastUser    As String
Private m_lastObjID   As Double

Private Sub Class_Initialize()
    m_lastObjID = 1

    Clear
End Sub

Private Sub Class_Terminate()
    Clear
End Sub 

Public Function Push(ByRef obj As clsQueueOBj)
    On Error GoTo ERROR_HANDLER
    
    Dim Index As Long
    Dim I     As Long
    
    Index = m_objCount
    
    If (m_objCount >= 1) Then
        For I = 0 To m_objCount - 1
            If (obj.PRIORITY < m_QueueObjs(I).PRIORITY) Then
                Index = I
                
                Exit For
            End If
        Next I
    
        ReDim Preserve m_QueueObjs(0 To m_objCount)
    End If

    If (Index < m_objCount) Then
        For I = m_objCount To Index + 1 Step -1
            Set m_QueueObjs(I) = m_QueueObjs(I - 1)
        Next I
    End If
    
    obj.ID = m_lastObjID
    
    Set m_QueueObjs(Index) = obj
    
    m_objCount = (m_objCount + 1)
    m_lastObjID = (m_lastObjID + 1)

    RunInAll "Event_MessageQueued", obj.ID, obj.Message, obj.Tag
    
    Exit Function

ERROR_HANDLER:

    ' overflow - likely due to message id size
    If (Err.Number = 6) Then
        m_lastObjID = 0
        
        Resume Next
    End If

    Call frmChat.AddChat(vbRed, "Error: " & Err.description & " in clsQueue::Push().")

    Exit Function
End Function

Public Function Pop() As clsQueueOBj
    Set Pop = New clsQueueOBj

    Set Pop = m_QueueObjs(0)
    
    RemoveItem 0

End Function ' end function Pop

Public Function Peek() As clsQueueOBj
    Set Peek = New clsQueueOBj

    Set Peek = m_QueueObjs(0)
End Function ' end function Peek

Public Function Item(ByVal Index As Long) As Object
    If ((Index < 0) Or (Index > m_objCount - 1)) Then
        Set Item = New clsQueueOBj
    
        Exit Function
    End If

    Set Item = m_QueueObjs(Index)
End Function

Public Function ItemByID(ByVal I As Double) As Object
    Dim j As Long

    For j = 0 To m_objCount - 1
        If (m_QueueObjs(j).ID = I) Then
            Set ItemByID = m_QueueObjs(j)
        
            Exit Function
        End If
    Next j
    
    Set ItemByID = New clsQueueOBj
End Function

Public Property Get Count() As Long
    Count = m_objCount
End Property

Public Function RemoveLines(ByVal match As String) As Integer
    Dim curQueueObj As clsQueueOBj
    Dim I           As Long   
    Dim found       As Long     
    
    Do
        Set curQueueObj = m_QueueObjs(I)

        If (PrepareCheck(curQueueObj.Message) Like PrepareCheck(match)) Then
            RemoveItem I
            
            found = (found + 1)
            
            I = 0
        Else
            I = (I + 1)
        End If
    Loop While (I < Count())
    
    RemoveLines = found
End Function

Public Sub RemoveItem(ByVal Index As Long)
    Dim I As Long

    If ((Index < 0) Or (Index > m_objCount - 1)) Then
        Exit Sub
    End If

    If (m_objCount > 1) Then
        For I = Index To ((m_objCount - 1) - 1)
            Set m_QueueObjs(I) = m_QueueObjs(I + 1)
        Next I
        
        ReDim Preserve m_QueueObjs(0 To m_objCount - 1)
        
        m_objCount = (m_objCount - 1)
    Else
        Clear
    End If
End Sub

Public Sub RemoveItemByID(ByVal I As Double)
    Dim j As Long
    
    For j = 0 To m_objCount - 1
        If (m_QueueObjs(j).ID = I) Then
            RemoveItem j
            
            Exit Sub
        End If
    Next j
End Sub

Public Sub Clear()
    Dim I As Long

    For I = 0 To m_objCount - 1
        Set m_QueueObjs(I) = Nothing
    Next I

    ReDim m_QueueObjs(0)
    
    Set m_QueueObjs(0) = New clsQueueOBj
    
    m_objCount = 0
    
    KillTimer 0&, QueueTimerID
    
    QueueTimerID = 0
    
    g_BNCSQueue.ClearQueue
End Sub
