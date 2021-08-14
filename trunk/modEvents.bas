Attribute VB_Name = "modEvents"
'StealthBot Project - modEvents.bas
' Andy T (andy@stealthbot.net) March 2005

Option Explicit
Private Const OBJECT_NAME As String = "modEvents"

Private Const MSG_FILTER_MAX_EVENTS As Long = 100 ' maximum number of storable events
Private Const MSG_FILTER_DELAY_INT  As Long = 500 ' interval for event count measuring
Private Const MSG_FILTER_MSG_COUNT  As Long = 3   ' message count maximums

Private Type MSGFILTER
    UserObj   As Object
    EventObj  As Object
    EventTime As Date
End Type

Private m_arrMsgEvents()  As MSGFILTER
Private m_eventCount      As Integer

Public Sub Event_FlagsUpdate(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, ByVal Ping As Long, Optional QueuedEventID As Integer = 0)
    
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If

    Dim UserObj         As clsUserObj
    Dim PreviousUserObj As clsUserObj
    Dim UserEvent       As clsUserEventObj
    
    Dim UserIndex       As Integer
    Dim i               As Integer
    Dim PreviousFlags   As Long
    Dim parsed          As String
    Dim pos             As Integer
    Dim doUpdate        As Boolean
    Dim Displayed       As Boolean  ' stores whether this event has been displayed by another event in the RTB

    ' if our username is for some reason null, we don't
    ' want to continue, possibly causing further errors
    If (LenB(Username) < 1) Then
        Exit Sub
    End If

    If Not frmChat.ListViewDrawDisabled Then
        frmChat.ListViewDrawDisabled = True
        DisableWindowRedraw frmChat.lvChannel.hWnd
    End If

    If (g_Channel.IsSilent) Then
        Set UserObj = New clsUserObj

        With UserObj
            .Statstring = Message
            .Name = Username
        End With
        
        g_Channel.Users.Add UserObj
        If Config.VoidView Then
            frmChat.AddName UserObj
        End If
    Else
        UserIndex = g_Channel.GetUserIndexEx(CleanUsername(Username))
    
        If (UserIndex > 0) Then
            Set UserObj = g_Channel.Users(UserIndex)
        
            If (QueuedEventID = 0) Then
                If (UserObj.Queue.Count > 0) Then
                    Set UserEvent = New clsUserEventObj
                
                    With UserEvent
                        .EventID = ID_USERFLAGS
                        .Flags = Flags
                        .Ping = Ping
                        .GameID = UserObj.Game
                    End With
                
                    UserObj.Queue.Add UserEvent
                Else
                    PreviousFlags = UserObj.Flags
                End If
            Else
                PreviousFlags = UserObj.Queue(QueuedEventID - 1).Flags
            End If
        Else
            frmChat.AddChat g_Color.ErrorMessageText, StringFormat("Warning! Phantom user {0} has received a flags update.", CleanUsername(Username))
            Exit Sub
        End If
    End If

    ' convert user name
    Username = UserObj.DisplayName
    
    ' Get the current userlist position
    '  This needs to happen before the flags are updated on the user object otherwise it changes.
    pos = g_Channel.GetUserIndexByPriority(UserObj.Name, , True)

    With UserObj
        .Flags = Flags
        .Ping = Ping
    End With
    
    ' are we receiving a flag update for ourselves?
    If (StrComp(Username, GetCurrentUsername, vbBinaryCompare) = 0) Then
        ' assign my current flags to the
        ' relevant internal variable
        MyFlags = Flags
        
        ' assign my current flags to the
        ' relevant scripting variable
        SharedScriptSupport.BotFlags = MyFlags
    End If
    
    If (g_Channel.IsSilent = False) And ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        If (Flags <> PreviousFlags) Then
            If (g_Channel.Self.IsOperator) Then
                If ((StrComp(Username, GetCurrentUsername, vbBinaryCompare) = 0) And (Not frmChat.IsPriorityUser(PreviousFlags))) Then
                    g_Channel.CheckUsers
                Else
                    g_Channel.CheckUser Username
                End If
            End If
            
            If (pos) Then
                Dim NewFlags As Long
                Dim LostFlags As Long
                
                frmChat.AddName UserObj, pos
                
                ' voodoo magic: only show flags that are new
                NewFlags = Not (Flags Imp PreviousFlags)
                LostFlags = Not (PreviousFlags Imp Flags)
                
                ' default to display this event
                Displayed = False
                
                ' check whether it has been
                If QueuedEventID > 0 And UserObj.Queue.Count >= QueuedEventID Then
                    Set UserEvent = UserObj.Queue(QueuedEventID)
                    Displayed = UserEvent.Displayed
                End If
                
                ' display if it has not
                If Not Displayed Then
                    Dim FDescN As String
                    Dim FDescO As String
                    FDescN = frmChat.GetFlagDescription(NewFlags, False)
                    FDescO = frmChat.GetFlagDescription(LostFlags, False)
                    
                    If LenB(FDescN) > 0 And LenB(FDescO) > 0 Then
                        frmChat.AddChat g_Color.JoinUsername, "-- ", g_Color.JoinedChannelName, _
                            Username, g_Color.JoinText, " is now a " & FDescN & " and no longer a " & FDescO & "."
                    ElseIf LenB(FDescN) > 0 Then
                        frmChat.AddChat g_Color.JoinUsername, "-- ", g_Color.JoinedChannelName, _
                            Username, g_Color.JoinText, " is now a " & FDescN & "."
                    ElseIf LenB(FDescO) > 0 Then
                        frmChat.AddChat g_Color.JoinUsername, "-- ", g_Color.JoinedChannelName, _
                            Username, g_Color.JoinText, " is no longer a " & FDescO & "."
                    End If
                End If
            End If
        End If
    End If

    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        RunInAll "Event_FlagUpdate", Username, Flags, Ping
    End If
    
    Exit Sub
    
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_FlagsUpdate()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_JoinedChannel(ByVal ChannelName As String, ByVal Flags As Long)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If

    Dim mailCount   As Integer
    Dim ToANSI      As String
    Dim LastChannel As String
    Dim sChannel    As String
    
    ' if our channel is for some reason null, we don't
    ' want to continue, possibly causing further errors
    If (LenB(ChannelName) = 0) Then
        Exit Sub
    End If
    
    LastChannel = g_Channel.Name
    
    Call frmChat.ClearChannel
    If Not frmChat.ListViewDrawDisabled Then
        frmChat.ListViewDrawDisabled = True
        DisableWindowRedraw frmChat.lvChannel.hWnd
    End If
    
    ' we want to reset our filter
    ' Values() when we join a new channel
    'BotVars.JoinWatch = 0
    
    'frmChat.tmrSilentChannel(0).Enabled = False
    
    'If (StrComp(g_Channel.Name, "Clan " & Clan.Name, vbTextCompare) = 0) Then
    '    PassedClanMotdCheck = False
    'End If

    ' show home channel in menu
    BotVars.LastChannel = LastChannel

    ' if we've just left another channel, call event script
    ' function indicating that we've done so.
    If (LenB(LastChannel) > 0) Then
        On Error Resume Next
        
        RunInAll "Event_ChannelLeave"
        
        On Error GoTo ERROR_HANDLER
    End If
    
    With g_Channel
        .Name = ChannelName
        .Flags = Flags
        .JoinTime = UtcNow
    End With
    
    PrepareHomeChannelMenu
    PrepareQuickChannelMenu
    
    SharedScriptSupport.MyChannel = ChannelName

    frmChat.AddChat g_Color.JoinedChannelText, "-- Joined channel: ", _
        g_Color.JoinedChannelName, ChannelName, g_Color.JoinedChannelText, " --"
    
    SetTitle GetCurrentUsername & ", online in channel " & g_Channel.Name
    
    Call frmChat.UpdateTrayTooltip
    Call frmChat.UpdateListviewLabel
    
    ' have we just joined the void?
    If (g_Channel.IsSilent) Then
        ' if we've joined the void, lets try to grab the list of
        ' users within the channel by attempting to force a user
        ' update message using Battle.net's unignore command.
        If (Config.VoidView) Then
            ' lets inform user of potential lag issues while in this channel
            frmChat.AddChat g_Color.InformationText, "If you experience a lot of lag while within " & _
                    "this channel, try selecting 'Disable Silent Channel View' from the Window menu."
            
            ' Enable timers for handling VoidView state.
            frmChat.tmrSilentChannel(0).Enabled = True
            frmChat.tmrSilentChannel(1).Enabled = True
        
            frmChat.AddQ "/unignore " & GetCurrentUsername
        End If
    Else
        frmChat.tmrSilentChannel(0).Enabled = False
        frmChat.tmrSilentChannel(1).Enabled = False
    End If
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' check for mail
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    mailCount = GetMailCount(GetCurrentUsername)
        
    If (mailCount) Then
        frmChat.AddChat g_Color.ConsoleText, "You have " & _
            mailCount & " new message" & IIf(mailCount = 1, "", "s") & _
                ". Type /inbox to retrieve."
    End If
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' call event script function
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    On Error Resume Next
    
    RunInAll "Event_ChannelJoin", ChannelName, Flags
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_JoinedChannel()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_UserDataReceived(ByRef oRequest As udtServerRequest, ByVal sUsername As String, ByRef Keys() As String, ByRef Values() As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If

    Dim sKeyShort As String
    Dim sValue As String
    Dim aOutput() As String
    Dim i As Integer
    Dim j As Integer
    Dim s As String
    Dim d As Double

    Dim oFT As FILETIME
    Dim oST As SYSTEMTIME

    Const LONG_MAX_VALUE As Double = 2147483647

    RunInAll "Event_UserDataReceived", oRequest.Tag, Keys, Values

    For i = LBound(Keys) To UBound(Keys)
        RunInAll "Event_KeyReturn", Keys(i), Values(i)

        sKeyShort = Mid$(Keys(i), InStr(1, Keys(i), "\", vbTextCompare) + 1)
        sValue = Values(i)

        Select Case oRequest.HandlerType
            Case reqUserInterface
                frmProfile.SetKey Keys(i), sValue
            Case reqUserCommand, reqInternal
                If StrComp(Left$(Keys(i), 7), "System\", vbTextCompare) = 0 Then
                    j = InStr(1, sValue, Space$(1), vbBinaryCompare)

                    If j > 0 Then    ' Probably a FILETIME
                        With oFT
                            .dwLowDateTime = UnsignedToLong(CDbl(Mid$(KillNull(sValue), j + 1)))
                            .dwHighDateTime = UnsignedToLong(CDbl(Left$(sValue, j)))
                        End With

                        FileTimeToSystemTime oFT, oST

                        s = StringFormat("{0}: {1} (Battle.net time)", sKeyShort, SystemTimeToString(oST))
                    ElseIf StrictIsNumeric(sValue) Then
                        s = StringFormat("{0}: {1}", sKeyShort, ConvertTimeInterval(sValue, True))
                    End If

                    If oRequest.HandlerType = reqUserCommand Then
                        oRequest.Command.Respond s
                    Else
                        frmChat.AddChat g_Color.ServerInfoText, s
                    End If
                Else
                    aOutput = Split(sValue, Chr(13))
                    For j = 0 To UBound(aOutput)
                        s = StringFormat("[{0}] {1}", sKeyShort, aOutput(j))

                        If oRequest.HandlerType = reqUserCommand Then
                            oRequest.Command.Respond s
                        Else
                            frmChat.AddChat g_Color.ServerInfoText, s
                        End If
                    Next
                End If
        End Select
    Next
    
    ' If this request was triggered by a command, send the response.
    If oRequest.HandlerType = reqUserCommand Then
        If oRequest.Command.GetResponse().Count = 0 Then
            oRequest.Command.Respond StringFormat("{0} has not configured a profile.", sUsername)
        End If
        oRequest.Command.SendResponse
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_UserDataReceived()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_LeftChatEnvironment()
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    BotVars.LastChannel = g_Channel.Name
    PrepareHomeChannelMenu
    PrepareQuickChannelMenu
    
    frmChat.ClearChannel
    
    SetTitle GetCurrentUsername & ", online on " & BotVars.Gateway
    
    Call frmChat.InitListviewTabs
    
    frmChat.AddChat g_Color.JoinedChannelText, "-- Left channel --"
    
    On Error Resume Next
    
    RunInAll "Event_ChannelLeave"
    
    On Error GoTo ERROR_HANDLER
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_LeftChatEnvironment()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_LoggedOnAs(Username As String, Statstring As String, AccountName As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim sChannel As String
    Dim ShowW3   As Boolean
    Dim ShowD2   As Boolean
    Dim Stats    As clsUserStats

    LastWhisper = vbNullString

    'If InStr(1, Username, "*", vbBinaryCompare) <> 0 Then
    '    Username = Right(Username, Len(Username) - InStr(1, Username, "*", vbBinaryCompare))
    'End If
    
    Call g_Queue.Clear
    
    Set g_Channel = New clsChannelObj
    Set g_Friends = New Collection
    ' reset Clan if we didn't just receive a SID_CLANINFO
    If Not g_Clan.InClan Then
        Set g_Clan = New clsClanObj
    End If
    
    g_Online = True
    ConnectionTickCount = modDateTime.GetTickCountMS()
    
    If AutoReconnectActive Then
        AutoReconnectActive = False
        AutoReconnectTry = 0
    End If
    
    ' in case this wasn't set before
    ds.EnteredChatFirstTime = True
    
    Set Stats = New clsUserStats
    Stats.Statstring = Statstring
    
    CurrentUsername = KillNull(Username)
    
    If (StrComp(Left$(CurrentUsername, 2), "w#", vbTextCompare) = 0) Then
        CurrentUsername = Mid(CurrentUsername, 3)
    End If

    ' if D2 and on a char, we need to tell the whole world this so that Self is known later on
    If (StrComp(Stats.Game, PRODUCT_D2DV, vbBinaryCompare) = 0) Or (StrComp(Stats.Game, PRODUCT_D2XP, vbBinaryCompare) = 0) Then
        If (LenB(Stats.CharacterName) > 0) Then
            CurrentUsername = Stats.CharacterName & "*" & CurrentUsername
        End If
    End If

    ' setup Bot menu game-specific features
    ShowW3 = (StrComp(Stats.Game, PRODUCT_WAR3, vbBinaryCompare) = 0) Or (StrComp(Stats.Game, PRODUCT_W3XP, vbBinaryCompare) = 0)
    ShowD2 = (StrComp(Stats.Game, PRODUCT_D2DV, vbBinaryCompare) = 0) Or (StrComp(Stats.Game, PRODUCT_D2XP, vbBinaryCompare) = 0)
    frmChat.mnuProfile.Enabled = True
    'frmChat.mnuClanCreate.Visible = ShowW3
    frmChat.mnuRealmSwitch.Visible = ShowD2

    SharedScriptSupport.myUsername = GetCurrentUsername
    
    With frmChat
        .AddChat g_Color.InformationText, "[BNCS] Logged on as ", g_Color.SuccessText, Username, _
            g_Color.InformationText, StringFormat(" using {0}.", Stats.ToString)

        Call SetNagelStatus(.sckBNet.SocketHandle, True)

        Call EnableSO_KEEPALIVE(.sckBNet.SocketHandle)

        ' show home channel in menu
        PrepareHomeChannelMenu
        PrepareQuickChannelMenu

        .InitListviewTabs

        .tmrAccountLock.Enabled = False

        If (frmChat.sckBNLS.State <> sckClosed) Then
            frmChat.sckBNLS.Close
        End If

        If Config.FriendsListTab Then
            Call .FriendListHandler.RequestFriendsList
        End If
    End With
    
    RequestSystemKeys reqInternal
    If (LenB(BotVars.Gateway) > 0) Then
        ' PvPGN: we already have our gateway, we're logged on
        SetTitle GetCurrentUsername & ", online in channel " & g_Channel.Name
        
        Call InsertDummyQueueEntry
        
        On Error Resume Next
        
        RunInAll "Event_LoggedOn", CurrentUsername, BotVars.Product
    End If
    
    Set Stats = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_LoggedOnAs()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

' updated 8-10-05 for new logging system
Public Sub Event_LogonEvent(ByVal Action As String, ByVal Result As Long, Optional ByVal ExtraInfo As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim lColor       As Long
    Dim sMessage     As String

    lColor = g_Color.ErrorMessageText
    
    ' get starting text
    Select Case UCase$(Action)
        Case ACCOUNT_MODE_LOGON
            sMessage = "Logon error - "
        Case ACCOUNT_MODE_CREAT
            sMessage = "Account creation error - "
        Case ACCOUNT_MODE_CHPWD
            sMessage = "Password change error - "
    End Select
    
    ' choose result code
    Select Case Result
        Case &H0
            lColor = g_Color.SuccessText
            ' replace with specific success message
            Select Case UCase$(Action)
                Case ACCOUNT_MODE_LOGON
                    sMessage = "Logon successful."
                Case ACCOUNT_MODE_CREAT
                    sMessage = "Account created successfully."
                Case ACCOUNT_MODE_CHPWD
                    sMessage = "Account password changed successfully."
                Case ACCOUNT_MODE_RSPWD
                    sMessage = "Sent the request to reset password. You will receive an email to continue this process."
                Case ACCOUNT_MODE_CHREG
                    sMessage = "Sent the request to change email associated with the account."
            End Select
        Case &H1
            sMessage = sMessage & "account does not exist."
        Case &H2
            Select Case UCase$(Action)
                Case ACCOUNT_MODE_CHPWD
                    sMessage = sMessage & "invalid old password."
                Case Else
                    sMessage = sMessage & "invalid password."
            End Select
        Case &H4
            sMessage = sMessage & "account already exists."
        Case &H5
            sMessage = sMessage & "account requires upgrade."
        Case &H6
            sMessage = sMessage & "account closed - " & ExtraInfo & "."
        Case &H7
            sMessage = sMessage & "name too short."
        Case &H8
            sMessage = sMessage & "name contains invalid characters."
        Case &H9
            sMessage = sMessage & "name contains banned word."
        Case &HA
            sMessage = sMessage & "name contains too few alphanumeric charaters."
        Case &HB
            sMessage = sMessage & "name contains adjacent punctuation."
        Case &HC
            sMessage = sMessage & "name contains too many punctuation characters."
        Case &HE
            sMessage = sMessage & "account email registration."
        Case &HF
            sMessage = sMessage & ExtraInfo & "."
        Case &H3101 ' actually status 0x01 from SID_CHANGEPASSWORD
            sMessage = sMessage & "account does not exist or invalid old password."
        Case &H3D05 ' actually status 0x05 from SID_CREATEACCOUNT2
            sMessage = sMessage & "account is still being created."
        Case -3& ' parameter empty
            Select Case UCase$(Action)
                Case ACCOUNT_MODE_LOGON, ACCOUNT_MODE_CREAT
                    sMessage = sMessage & "username or password not provided."
                Case ACCOUNT_MODE_CHPWD
                    sMessage = sMessage & "new password not provided."
                Case ACCOUNT_MODE_RSPWD
                    sMessage = sMessage & "email address not provided."
                Case ACCOUNT_MODE_CHREG
                    sMessage = sMessage & "new email address not provided."
            End Select
        Case -2& ' time out
            sMessage = sMessage & "timed out."
        Case -1& ' attempt
            lColor = g_Color.InformationText
            ' replace with specific in-progress message
            Select Case UCase$(Action)
                Case ACCOUNT_MODE_LOGON
                    sMessage = "Sending logon information..."
                Case ACCOUNT_MODE_CREAT
                    sMessage = "Attempting to create account..."
                Case ACCOUNT_MODE_CHPWD
                    sMessage = "Attempting to change password..."
            End Select
        Case Else
            sMessage = sMessage & "unknown response code (0x" & Hex(Result) & ": " & ExtraInfo & ")."
    End Select
    
    frmChat.AddChat lColor, "[BNCS] " & sMessage

    Exit Sub

ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_LogonEvent()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_ServerError(ByVal Message As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    frmChat.AddChat g_Color.ErrorMessageText, Message
    
    RunInAll "Event_ServerError", Message
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_ServerError()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_ChannelJoinError(ByVal EventID As Integer, ByVal ChannelName As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim ChannelJoinError As String
    Dim ChannelJoinButtons As VbMsgBoxStyle
    Dim ChannelJoinResult As VbMsgBoxResult
    Dim Message As String
    Dim ChannelCreateOption As String

    'frmChat.AddChat g_Color.ErrorMessageText, Message
    
    If (LenB(BotVars.Gateway) = 0) Then
        ' continue gateway discovery
        SEND_SID_CHATCOMMAND "/whoami"
    Else
        ChannelCreateOption = Config.AutoCreateChannels
    
        Select Case ChannelCreateOption
            Case "ALERT"
                Select Case EventID
                    Case ID_CHANNELDOESNOTEXIST
                        ChannelJoinError = "Channel does not exist." & vbNewLine & "Do you want to create it?"
                        ChannelJoinButtons = vbYesNo Or vbQuestion Or vbDefaultButton1
                    Case ID_CHANNELFULL
                        ChannelJoinError = "Channel is full."
                        ChannelJoinButtons = vbOKOnly Or vbExclamation Or vbDefaultButton1
                    Case ID_CHANNELRESTRICTED
                        ChannelJoinError = "Channel is restricted."
                        ChannelJoinButtons = vbOKOnly Or vbExclamation Or vbDefaultButton1
                End Select
                
                ChannelJoinResult = MsgBox("Failed to join " & ChannelName & ":" & vbNewLine & _
                    ChannelJoinError, ChannelJoinButtons, "StealthBot")
                
                If ChannelJoinResult = vbYes Then
                    Call FullJoin(ChannelName, 2)
                End If
                
            Case Else
            ' "ALWAYS" - handle it as error to bot
            ' "NEVER" - failed to join or create
                Select Case EventID
                    Case ID_CHANNELDOESNOTEXIST
                        Message = "[BNCS] Channel does not exist."
                    Case ID_CHANNELFULL
                        Message = "[BNCS] Channel is full."
                    Case ID_CHANNELRESTRICTED
                        Message = "[BNCS] Channel is restricted."
                End Select
                
                frmChat.AddChat g_Color.ErrorMessageText, Message
                
        End Select
        
        'should we expose?
        'RunInAll "Event_ChannelJoinError", EventID, ChannelName
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_ChannelJoinError()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_ServerInfo(ByVal Username As String, ByVal Message As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If

    Const MSG_WHOIS_1            As String = "You are "
    Const MSG_WHOIS_2            As String = ", using "
    Const MSG_WHOIS_IN_CHANNEL   As String = " in channel "
    Const MSG_WHOIS_IN_GAME      As String = " in game "
    Const MSG_WHOIS_IN_PRIVATE   As String = " a private "

    Const MSG_STILL_AWAY         As String = "You are still marked as away."
    Const MSG_NO_ONE_HEARS       As String = "No one hears you."
    Const MSG_SERVER_WELCOME     As String = "Welcome to Battle.net!"
    Const MSG_SERVER_HOST        As String = "This server is hosted by "
    Const MSG_SERVER_LAST_LOGON  As String = "Last logon: "

    Const MSG_FRIENDSCH_END      As String = " your friends list."
    Const MSG_FRIENDSCH_ADDED    As String = "Added "
    Const MSG_FRIENDSCH_REMOVED  As String = "Removed "
    Const MSG_FRIENDSCH_PROMOTED As String = "Promoted "
    Const MSG_FRIENDSCH_DEMOTED  As String = "Demoted "

    Const MSG_BAN                As String = " was banned by "
    Const MSG_UNBAN              As String = " was unbanned by "
    Const MSG_KICK               As String = " was kicked out of the channel by "

    Const MSG_RECVKICK           As String = " kicked you out of the channel!"

    Const MSG_UNSQUELCH          As String = " has been unsquelched."

    Const MSG_DESIGNATED         As String = " is your new designated heir."

    Const MSG_FRIENDS            As String = "Your friends are:"
    Const MSG_FRIEND_OFFLINE     As String = ", offline"
    
    Dim i      As Integer
    Dim User   As String
    Dim Hidden As Boolean
    Dim ToANSI As String
    
    If (Message = vbNullString) Then
        Exit Sub
    End If
    
    Username = ConvertUsername(Username)

    Hidden = False

    If g_Clan.InClan Then
        If (StrComp(g_Channel.Name, "Clan " & g_Clan.Name, vbTextCompare) = 0) Then
            If (g_Clan.PendingClanMOTD And StrComp(Message, g_Clan.MOTD, vbBinaryCompare) = 0) Then
                Call frmChat.AddChat(g_Color.ServerInfoText, Message)
                g_Clan.PendingClanMOTD = False
                On Error Resume Next
                RunInAll "Event_ServerInfo", Message
                Exit Sub
            End If
        End If
    End If

    If (g_request_receipt) Then ' for .cs and .cb commands
        Caching = True

        ' Changed 08-18-09 - Hdx - Uses the new Channel cache function, Eventually to beremoved to script
        'Call CacheChannelList(Message, 1)
        Call CacheChannelList(enAdd, Message)

        'With frmChat.cacheTimer
        '    .Enabled = False
        '    .Enabled = True
        'End With
    End If

    ' what is our current gateway name?
    If (LenB(BotVars.Gateway) = 0) Then
        If (StrComp(Left$(Message, Len(MSG_WHOIS_1)), MSG_WHOIS_1, vbBinaryCompare) = 0) And (InStr(1, Message, MSG_WHOIS_2, _
                vbBinaryCompare) > 0) Then

            If ((InStr(1, Message, MSG_WHOIS_IN_CHANNEL, vbBinaryCompare) = 0) And _
                    (InStr(1, Message, MSG_WHOIS_IN_GAME, vbBinaryCompare) = 0) And _
                    (InStr(1, Message, MSG_WHOIS_IN_PRIVATE, vbBinaryCompare) = 0)) Then

                i = InStrRev(Message, Space$(1))

                BotVars.Gateway = Mid$(Message, i + 1)

                SetTitle GetCurrentUsername & ", online on " & BotVars.Gateway

                Call DoChannelJoinHome

                Call InsertDummyQueueEntry
                
                On Error Resume Next
                RunInAll "Event_LoggedOn", CurrentUsername, BotVars.Product
                RunInAll "Event_ServerInfo", Message
                Exit Sub
            End If
        End If
    End If

    ' filter "extra" messages: you are still marked as away, no one hears you, and server welcome messages
    If Config.HideExtraServerAlerts Then
        If ((StrComp(Message, MSG_STILL_AWAY, vbBinaryCompare) = 0) Or _
            (StrComp(Message, MSG_NO_ONE_HEARS, vbBinaryCompare) = 0) Or _
            (StrComp(Message, MSG_SERVER_WELCOME, vbBinaryCompare) = 0) Or _
            (StrComp(Left$(Message, Len(MSG_SERVER_HOST)), MSG_SERVER_HOST, vbBinaryCompare) = 0) Or _
            (StrComp(Left$(Message, Len(MSG_SERVER_LAST_LOGON)), MSG_SERVER_LAST_LOGON, vbBinaryCompare) = 0)) Then
            Hidden = True
        End If
    End If

    ' friends list changes: request updates for unsupported FL
    If (StrComp(Right$(Message, Len(MSG_FRIENDSCH_END)), MSG_FRIENDSCH_END, vbBinaryCompare) = 0) And _
        ((StrComp(Left$(Message, Len(MSG_FRIENDSCH_ADDED)), MSG_FRIENDSCH_ADDED, vbBinaryCompare) = 0) Or _
         (StrComp(Left$(Message, Len(MSG_FRIENDSCH_REMOVED)), MSG_FRIENDSCH_REMOVED, vbBinaryCompare) = 0) Or _
         (StrComp(Left$(Message, Len(MSG_FRIENDSCH_PROMOTED)), MSG_FRIENDSCH_PROMOTED, vbBinaryCompare) = 0) Or _
         (StrComp(Left$(Message, Len(MSG_FRIENDSCH_DEMOTED)), MSG_FRIENDSCH_DEMOTED, vbBinaryCompare) = 0)) Then
        
        If Config.FriendsListTab Then
            If Not frmChat.FriendListHandler.SupportsFriendPackets(Config.Game) Then
                Call frmChat.FriendListHandler.RequestFriendsList
            End If
        End If
    End If

    If (InStr(1, Message, Space$(1), vbBinaryCompare) <> 0) Then
        'banned-user tracking
        User = Split(Message, Space$(1))(0)
        ' added 1/21/06 thanks to
        ' http://www.stealthbot.net/forum/index.php?showtopic=24582

        If (Len(User) > 0) Then
            If (InStr(1, Message, MSG_BAN, vbBinaryCompare) > 0) Then
                If (StrComp(User, Left$(Message, (InStr(1, Message, MSG_BAN, vbBinaryCompare) - 1)), vbBinaryCompare) = 0) Then
                    ' " was banned by " must follow User (first word)
                    Dim Reason     As String
                    Dim BanlistObj As clsBanlistUserObj
                    Dim pos        As Integer
                    Dim banpos     As Integer

                    Reason = Mid$(Message, InStr(1, Message, MSG_BAN, vbBinaryCompare) + Len(MSG_BAN) + 1) ' trim out username and banned message
                    If (InStr(1, Reason, " (", vbBinaryCompare)) Then 'Did they give a message?
                        Reason = Mid$(Reason, InStr(1, Reason, " (") + 2) 'trim out the banning name (Note, when banned by a rep using Len(Username) won't work as its banned "By a Blizzard Representative")
                        Reason = Left$(Reason, Len(Reason) - 2) 'Trim off the trailing ")."
                    Else
                        Reason = vbNullString
                    End If

                    If (Len(User) > 0) Then
                        pos = g_Channel.GetUserIndexByPriority(Username)
                        
                        If (pos > 0) Then
                            banpos = g_Channel.IsOnBanList(User, Username)

                            If (banpos > 0) Then
                                g_Channel.Banlist.Remove banpos
                            Else
                                g_Channel.BanCount = (g_Channel.BanCount + 1)
                            End If

                            If ((BotVars.StoreAllBans) Or _
                                    (StrComp(Username, GetCurrentUsername, vbBinaryCompare) = 0)) Then

                                Set BanlistObj = New clsBanlistUserObj

                                With BanlistObj
                                    .Name = User
                                    .Operator = Username
                                    .DateOfBan = UtcNow
                                    .IsDuplicateBan = (g_Channel.IsOnBanList(User) > 0)
                                    .Reason = Reason
                                End With

                                If (BanlistObj.IsDuplicateBan) Then
                                    With g_Channel.Banlist(g_Channel.IsOnBanList(User))
                                        .IsDuplicateBan = False
                                    End With
                                End If

                                g_Channel.Banlist.Add BanlistObj
                            End If
                        End If

                        Call RemoveBanFromQueue(User)
                    End If

                    If (frmChat.mnuHideBans.Checked) Then
                        Hidden = True
                    End If
                End If
            ElseIf (InStr(1, Message, MSG_UNBAN, vbBinaryCompare) > 0) Then
                If (StrComp(User, Left$(Message, (InStr(1, Message, MSG_UNBAN, vbBinaryCompare) - 1)), vbBinaryCompare) = 0) Then
                    ' " was unbanned by " must follow User (first word)
                    Dim rembanpos As Integer

                    If (Len(User) > 0) Then
                        g_Channel.BanCount = (g_Channel.BanCount - 1)

                        Do
                            rembanpos = g_Channel.IsOnBanList(User)

                            If (rembanpos > 0) Then
                                g_Channel.Banlist.Remove rembanpos
                            End If
                        Loop While (rembanpos <> 0)
                    End If
                End If
            ElseIf (InStr(1, Message, MSG_KICK, vbBinaryCompare) > 0) Then
                If (StrComp(User, Left$(Message, (InStr(1, Message, MSG_KICK, vbBinaryCompare) - 1)), vbBinaryCompare) = 0) Then
                    ' " was kicked out of the channel by " must follow User (first word)
                    g_Channel.KickCount = (g_Channel.KickCount + 1)
                End If
            End If
        End If
    End If ' message contains a space

    ' backup channel
    If (StrComp(Right$(Message, Len(MSG_RECVKICK)), MSG_RECVKICK, vbBinaryCompare) = 0) Then
        If (BotVars.UseBackupChan) Then
            If (Len(BotVars.BackupChan) > 0) Then
                frmChat.AddQ "/join " & BotVars.BackupChan
            End If
        Else
            frmChat.AddQ "/join " & g_Channel.Name
        End If
    End If

    ' silent channel unsquelch
    If (StrComp(Right$(Message, Len(MSG_UNSQUELCH)), MSG_UNSQUELCH, vbBinaryCompare) = 0) Then
        If ((g_Channel.IsSilent) And (Config.VoidView)) Then
            frmChat.lvChannel.ListItems.Clear
        End If
    End If

    ' store designated
    If (StrComp(Right$(Message, Len(MSG_DESIGNATED)), MSG_DESIGNATED, vbBinaryCompare) = 0) Then
        g_Channel.OperatorHeir = Left$(Message, Len(Message) - Len(MSG_DESIGNATED))
    End If

    ' friends hiding
    If (StrComp(Message, MSG_FRIENDS, vbBinaryCompare) = 0) Then
        If (Not (BotVars.ShowOfflineFriends)) Then
            ' display it early and append the hiding indicator
            If (Not (Hidden)) Then
                frmChat.AddChat g_Color.ServerInfoText, Message & "  " & Chr$(255) & "ci(StealthBot is hiding your offline friends)"
                ' hide it next time
                Hidden = True
            End If
        End If
    End If
    If (StrComp(Right$(Message, Len(MSG_FRIEND_OFFLINE)), MSG_FRIEND_OFFLINE, vbBinaryCompare) = 0) Then
        If (Not BotVars.ShowOfflineFriends) Then
            Hidden = True
        End If
    End If

    ' display
    If (Not (Hidden)) Then
        frmChat.AddChat g_Color.ServerInfoText, Message
    End If

    RunInAll "Event_ServerInfo", Message
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_ServerInfo()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_UserEmote(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, _
    Optional QueuedEventID As Integer = 0)
    
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
        
    Dim UserEvent   As clsUserEventObj
    Dim UserObj     As clsUserObj
    
    Dim i           As Integer
    Dim ToANSI      As String
    Dim pos         As Integer
    Dim PassedQueue As Boolean
    
    pos = g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    If (pos > 0) Then
        Set UserObj = g_Channel.Users(pos)
        
        If (QueuedEventID = 0) Then
            UserObj.LastTalkTime = UtcNow
            
            If (UserObj.Queue.Count > 0) Then
                Set UserEvent = New clsUserEventObj
                
                With UserEvent
                    .EventID = ID_EMOTE
                    .Flags = Flags
                    .Message = Message
                End With
                
                UserObj.Queue.Add UserEvent
            End If
        End If
    Else
        ' create new user object for invisible representatives...
        Set UserObj = New clsUserObj
        
        ' store user name
        UserObj.Name = Username
    End If
    
    ' convert user name
    Username = UserObj.DisplayName
    
    If (QueuedEventID = 0) Then
        If (g_Channel.Self.IsOperator) Then
            If (GetSafelist(Username) = False) Then
                CheckMessage Username, Message
            End If
        End If
    End If
    
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        If (AllowedToTalk(Username, Message)) Then
            ' catch phrases
            If (Catch(0) <> vbNullString) Then
                CheckPhrase Username, Message, CPEMOTE
            End If

            ' flash window on events
            If (frmChat.mnuFlash.Checked) Then
                FlashWindow
            End If

            ' display to screen
            frmChat.AddChat g_Color.EmoteText, "<", g_Color.EmoteUsernames, Username & _
                    Space$(1), g_Color.EmoteText, Message & ">"

            ' vote check
            If (VoteDuration > 0) Then
                If (InStr(1, LCase(Message), "yes", vbTextCompare) > 0) Then
                    Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDYES, Username)
                ElseIf (InStr(1, LCase(Message), "no", vbTextCompare) > 0) Then
                    Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDNO, Username)
                End If
            End If
        End If
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next

        RunInAll "Event_UserEmote", Username, Flags, Message
    End If

    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_UserEmote()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_UserInChannel(ByVal Username As String, ByVal Flags As Long, ByVal Statstring As String, ByVal Ping As Long, Optional QueuedEventID As Integer = 0)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If

    Dim UserEvent    As clsUserEventObj
    Dim UserObj      As clsUserObj
    Dim found        As ListItem
    
    Dim UserIndex    As Integer
    Dim i            As Integer
    Dim strCompare   As String
    Dim Level        As Byte
    Dim StatUpdate   As Boolean
    Dim Index        As Long
    Dim Stats        As String
    Dim Clan         As String
    Dim pos          As Integer
    Dim showUpdate   As Boolean
    Dim Displayed    As Boolean ' whether this event has been displayed in the RTB (if combined with another)
    Dim AcqOps       As Boolean
    Dim NewIcon      As Long    ' temp store new icon

    If (LenB(Username) < 1) Then
        Exit Sub
    End If

    If Not frmChat.ListViewDrawDisabled Then
        frmChat.ListViewDrawDisabled = True
        DisableWindowRedraw frmChat.lvChannel.hWnd
    End If

    UserIndex = g_Channel.GetUserIndexEx(CleanUsername(Username))

    If (UserIndex > 0) Then
        Set UserObj = g_Channel.Users(UserIndex)
        
        If (QueuedEventID = 0) Then
            If (UserObj.Queue.Count > 0) Then
                If (UserObj.Statstring <> Statstring) Then
                    StatUpdate = True
                
                    Set UserEvent = New clsUserEventObj
                
                    With UserEvent
                        .EventID = ID_USER
                        .Flags = Flags
                        .Ping = Ping
                        .GameID = UserObj.Game
                        .Clan = UserObj.Clan
                        .Statstring = Statstring
                    End With
                
                    UserObj.Queue.Add UserEvent
                Else
                    ' This is likely a phantom user situation. Remove the old user and replace with this new one.
                    If Not g_Channel.HasPhantomUsers Then
                        Call DebugPhantomUser(UserObj, Flags, Statstring, Ping)
                        g_Channel.HasPhantomUsers = True
                    End If
                    
                    Call Event_UserLeaves(Username, Flags, True)
                    Set UserObj = New clsUserObj
                    UserObj.UserlistWeight = g_Channel.JoinCount
                End If
            End If
        End If
        
        StatUpdate = True
    Else
        Set UserObj = New clsUserObj
        g_Channel.JoinCount = g_Channel.JoinCount + 1
        UserObj.UserlistWeight = g_Channel.JoinCount
    End If
    
    With UserObj
        .Flags = Flags
        .Ping = Ping
        .JoinTime = g_Channel.JoinTime
        .Statstring = Statstring
        .Name = Username
    End With
    
    If (UserIndex = 0) Then
        g_Channel.Users.Add UserObj
    End If
    
    Username = UserObj.DisplayName
    
    'ParseStatstring OriginalStatstring, Stats, Clan
    If (StatUpdate = False) Then
        'frmChat.AddChat vbRed, UserObj.Stats.IconCode
        'frmChat.AddChat g_Color.JoinText, "-- User in channel: ", _
        '    g_Color.JoinUsername, Username, _
        '    g_Color.JoinUsername, " [" & Format$(Ping, "#,##0") & "ms]", _
        '    g_Color.JoinText, " is using " & UserObj.Stats.ToString, _
        '    g_Color.JoinText, "."
    
        frmChat.AddName UserObj
        
        Call frmChat.UpdateListviewLabel
        
        DoLastSeen Username
    Else
        If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
            If (JoinMessagesOff = False) Then
                ' default to display this event
                Displayed = False
                
                ' check whether it has been
                If QueuedEventID > 0 And UserObj.Queue.Count >= QueuedEventID Then
                    Set UserEvent = UserObj.Queue(QueuedEventID)
                    Displayed = UserEvent.Displayed
                End If
                
                ' display if it has not already been
                If Not Displayed Then
                    Dim UserColor As Long
                    Dim FDesc As String
                    FDesc = frmChat.GetFlagDescription(Flags, False)
                    
                    If LenB(FDesc) > 0 Then
                        FDesc = " as a " & FDesc
                    End If
                    
                    ' display message
                    If (Flags And USER_BLIZZREP) Then
                        UserColor = RGB(97, 105, 255)
                    ElseIf (Flags And USER_SYSOP) Then
                        UserColor = RGB(97, 105, 255)
                    ElseIf (Flags And USER_CHANNELOP) Then
                        UserColor = g_Color.TalkUsernameOp
                    Else
                        UserColor = g_Color.JoinUsername
                    End If
                    
                    frmChat.AddChat g_Color.JoinText, "-- Stats updated: ", _
                        UserColor, Username, _
                        g_Color.JoinUsername, " [" & Format$(Ping, "#,##0") & "ms]", _
                        g_Color.JoinText, " is using " & UserObj.Stats.ToString, _
                        g_Color.JoinUsername, FDesc, _
                        g_Color.JoinText, "."
                End If
            End If
            
            pos = g_Channel.GetUserIndexByPriority(Username, , True)

            If (pos > 0) Then
            
                Set found = frmChat.lvChannel.ListItems(pos)
                
                ' if the update occured to a D2 user ...
                If ((StrComp(UserObj.Game, PRODUCT_D2DV) = 0) Or (StrComp(UserObj.Game, PRODUCT_D2XP) = 0)) Then
                    ' the username could have changed!
                    If (StrComp(UserObj.DisplayName, found.Text, vbBinaryCompare) <> 0) Then
                        ' it did, so update user name text in channel list
                        found.Text = UserObj.DisplayName
                        
                        ' now check if this is Self
                        If (StrComp(UserObj.Name, CleanUsername(CurrentUsername), vbBinaryCompare) = 0) Then
                            ' it is! we have to do some magic to tell SB we have a new name
                            CurrentUsername = UserObj.Stats.CharacterName & "*" & CleanUsername(CurrentUsername)
                            
                            ' tell scripting
                            SharedScriptSupport.myUsername = GetCurrentUsername
                            
                            ' set form title
                            SetTitle GetCurrentUsername & ", online in channel " & _
                                    g_Channel.Name
                            
                            ' tell tray icon
                            Call frmChat.UpdateTrayTooltip
                        End If
                    End If
                End If
                
                ' if we are showing stats icons ...
                If (BotVars.ShowStatsIcons) Then 'and the icon code is valid
                    If (UserObj.Stats.IconCode <> -1) Then
                        ' if the icon in the list is not the icon found by stats, update
                        NewIcon = frmChat.GetSmallIcon(UserObj.Game, UserObj.Flags, UserObj.Stats.IconCode)
                        If (found.SmallIcon <> NewIcon) Then
                            found.SmallIcon = NewIcon
                        End If
                    End If
                End If
                
                If (found.ListSubItems.Count > 0) Then
                    found.ListSubItems(1).Text = UserObj.Clan
                End If
                
                Set found = Nothing
            End If
        End If
    End If
    
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        RunInAll "Event_UserInChannel", Username, Flags, UserObj.Stats.ToString, Ping, _
            UserObj.Game, StatUpdate
    End If
    
    If (MDebug("statstrings")) Then
        frmChat.AddChat g_Color.InformationText, "Username: " & Username & ", Statstring: " & _
            Statstring
    End If

    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_UserInChannel()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_UserJoins(ByVal Username As String, ByVal Flags As Long, ByVal Statstring As String, ByVal Ping As Long, Optional QueuedEventID As Integer = 0)
                
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim UserObj     As clsUserObj
    Dim UserEvent   As clsUserEventObj
    
    Dim toCheck     As String
    Dim strCompare  As String
    Dim i           As Long
    Dim temp        As Byte
    Dim Level       As Byte
    Dim lMailCount  As Long
    Dim Banned      As Boolean
    Dim f           As Integer
    Dim UserIndex   As Integer
    Dim BanningUser As Boolean
    Dim pStats      As String
    Dim IsBanned    As Boolean
    Dim AcqFlags    As Long
    Dim ToDisplay   As Boolean
    
    If (Len(Username) < 1) Then
        Exit Sub
    End If

    If Not frmChat.ListViewDrawDisabled Then
        frmChat.ListViewDrawDisabled = True
        DisableWindowRedraw frmChat.lvChannel.hWnd
    End If

    UserIndex = g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    If (QueuedEventID > 0) Then
        If (UserIndex = 0) Then
            frmChat.AddChat g_Color.ErrorMessageText, "Error: We have received a queued join event for a user that we " & _
                "couldn't find in the channel."
        
            Exit Sub
        End If
    
        Set UserObj = g_Channel.Users(UserIndex)
    Else
        ' If this user is already in the channel, that instance is probably a phantom. Remove them silently.
        If (UserIndex > 0) Then
            Set UserObj = g_Channel.Users(UserIndex)
            
            If Not g_Channel.HasPhantomUsers Then
                Call DebugPhantomUser(UserObj, Flags, Statstring, Ping)
                g_Channel.HasPhantomUsers = True
            End If
            
            Call Event_UserLeaves(Username, Flags, True)
        End If
        
        g_Channel.JoinCount = g_Channel.JoinCount + 1

        Set UserObj = New clsUserObj

        With UserObj
            .Flags = Flags
            .Ping = Ping
            .JoinTime = UtcNow
            .Statstring = Statstring
            .UserlistWeight = g_Channel.JoinCount
            .Name = Username
        End With

        If (BotVars.ChatDelay > 0) Then
            Set UserEvent = New clsUserEventObj

            With UserEvent
                .EventID = ID_JOIN
                .Flags = Flags
                .Ping = Ping
                .GameID = UserObj.Game
                .Statstring = Statstring
                .Clan = UserObj.Clan
                .IconCode = UserObj.Stats.Icon
            End With

            UserObj.Queue.Add UserEvent
        End If

        g_Channel.Users.Add UserObj
    End If
    
    Username = UserObj.DisplayName
    
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID = 0)) Then
        If (g_Channel.Self.IsOperator) Then
            g_Channel.CheckUser Username, UserObj
        End If
    End If
    
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' GUI
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
        ' if we have join/leaves on
        If (JoinMessagesOff = False) Then

            ' does this event have events delayed after it?
            If QueuedEventID > 0 And UserObj.Queue.Count > 0 Then
                
                ' loop through the events occuring after this one
                For i = QueuedEventID To UserObj.Queue.Count
                
                    ' get the event
                    Set UserEvent = UserObj.Queue(i)
                    
                    ' default to not combine with userjoins
                    ToDisplay = False
                    
                    Select Case UserEvent.EventID
                    
                        ' user flags update
                        Case ID_USERFLAGS
                            ' will combine with userjoins
                            ToDisplay = True
                            
                            AcqFlags = UserEvent.Flags
                            
                        ' user stats update / user in channel
                        Case ID_USER
                            ' will combine with userjoins
                            ToDisplay = True
                            
                            ' is stats different / provided?
                            If LenB(UserEvent.Statstring) > 0 Then
                                If StrComp(UserEvent.Statstring, UserObj.Statstring) Then
                                    
                                    ' store stats update stats in object used in userjoins message generation
                                    UserObj.Statstring = UserEvent.Statstring
                                End If
                            End If
                        
                    End Select
                    
                    ' if we're going to combine this event with userjoins ...
                    If ToDisplay Then 'then set .displayed on the queue'd event so it is not displayed separately
                        UserEvent.Displayed = True
                        
                        ' also update in collection
                        UserObj.Queue.Remove i
                        UserObj.Queue.Add UserEvent, , , i - 1
                    End If
                    
                Next i
                
            End If
            
            If (Not Filters) Or (Not CheckBlock(Username)) Then
                Dim UserColor As Long
                Dim FDesc As String
                FDesc = frmChat.GetFlagDescription(AcqFlags Or Flags, False)
                
                If LenB(FDesc) > 0 Then
                    FDesc = " as a " & FDesc
                End If
                
                ' display message
                If (AcqFlags And USER_BLIZZREP) Or (Flags And USER_BLIZZREP) Then
                    UserColor = RGB(97, 105, 255)
                ElseIf (AcqFlags And USER_SYSOP) Or (Flags And USER_SYSOP) Then
                    UserColor = RGB(97, 105, 255)
                ElseIf (AcqFlags And USER_CHANNELOP) Or (Flags And USER_CHANNELOP) Then
                    UserColor = g_Color.TalkUsernameOp
                Else
                    UserColor = g_Color.JoinUsername
                End If
                
                frmChat.AddChat g_Color.JoinText, "-- ", _
                    UserColor, Username, _
                    g_Color.JoinUsername, " [" & Format$(Ping, "#,##0") & "ms]", _
                    g_Color.JoinText, " has joined the channel using " & UserObj.Stats.ToString, _
                    g_Color.JoinUsername, FDesc, _
                    g_Color.JoinText, "."
            End If
        End If
        
        ' add to user list
        frmChat.AddName UserObj
        
        ' if focus on channel tab, update header
        Call frmChat.UpdateListviewLabel
        
        ' flash window
        If (frmChat.mnuFlash.Checked) Then
            FlashWindow
        End If
        
        ' update last seen info
        Call DoLastSeen(Username)
        
        ' check is banned
        IsBanned = (UserObj.PendingBan)
        
        'frmChat.AddChat vbRed, IsBanned
        
        ' if not banned...
        If (IsBanned = False) Then
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
            ' Greet message
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
            If (BotVars.UseGreet) Then
                If (LenB(BotVars.GreetMsg)) Then
                    If (BotVars.WhisperGreet) Then
                        frmChat.AddQ "/w " & Username & _
                            Space$(1) & DoReplacements(BotVars.GreetMsg, Username, Ping)
                    Else
                        frmChat.AddQ DoReplacements(BotVars.GreetMsg, Username, Ping)
                    End If
                End If
            End If
                
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
            ' Botmail
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
            
            If (mail) Then
                lMailCount = GetMailCount(Username)
                
                If (lMailCount > 0) Then
                    frmChat.AddQ "/w " & Username & " You have " & lMailCount & _
                        " new message" & IIf(lMailCount = 1, "", "s") & ". Type !inbox to retrieve."
                End If
            End If
        End If
            
        ' print their statstring, if desired
        If (MDebug("statstrings")) Then
            frmChat.AddChat g_Color.ErrorMessageText, Statstring
        End If
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        'frmChat.AddChat vbRed, frmChat.SControl.Error.Number
        
        RunInAll "Event_UserJoins", Username, Flags, UserObj.Stats.ToString, Ping, _
            UserObj.Game, UserObj.Stats.Level, Statstring, IsBanned
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_UserJoins()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_UserLeaves(ByVal Username As String, ByVal Flags As Long, Optional ByVal Silent As Boolean = False)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If

    Dim UserObj       As clsUserObj
    Dim UserIndex     As Integer
    Dim pos           As Integer
    Dim PassJoinDelay As Boolean

    UserIndex = g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    If (UserIndex = 0) Then
        frmChat.AddChat g_Color.ErrorMessageText, StringFormat("Warning! Phantom user {0} has left the channel.", CleanUsername(Username))
        Exit Sub
    End If

    If Not frmChat.ListViewDrawDisabled Then
        frmChat.ListViewDrawDisabled = True
        DisableWindowRedraw frmChat.lvChannel.hWnd
    End If
    
    Set UserObj = g_Channel.Users(UserIndex)
    
    If (UserObj.IsOperator) Then
        g_Channel.RemoveBansFromOperator Username
    End If
    
    If (UserObj.Queue.Count = 0) Then
        PassJoinDelay = True
        If ((Not Silent) And (Not JoinMessagesOff) And ((Not Filters) Or (Not CheckBlock(Username)))) Then
            'If (GetVeto = False) Then
            Dim UserColor As Long
            
            ' display message
            If (Flags And USER_BLIZZREP) Then
                UserColor = RGB(97, 105, 255)
            ElseIf (Flags And USER_SYSOP) Then
                UserColor = RGB(97, 105, 255)
            ElseIf (Flags And USER_CHANNELOP) Then
                UserColor = g_Color.TalkUsernameOp
            Else
                UserColor = g_Color.JoinUsername
            End If
            
            frmChat.AddChat g_Color.JoinText, "-- ", _
                UserColor, UserObj.DisplayName, _
                g_Color.JoinText, " has left the channel."
            'End If
        End If
    End If
    
    If (StrComp(Username, g_Channel.OperatorHeir, vbTextCompare) = 0) Then
        g_Channel.OperatorHeir = vbNullString
        
        Call g_Channel.CheckUsers
    End If
    
    Username = UserObj.DisplayName
    
    RemoveBanFromQueue Username
    
    pos = g_Channel.GetUserIndexByPriority(Username, , True)
    
    'Debug.Print "Remove " & Username & " Index: " & UserIndex
    g_Channel.Users.Remove UserIndex
    Set UserObj = Nothing
    
    If (PassJoinDelay And pos > 0) Then
        If (Not Silent) And (frmChat.mnuFlash.Checked) Then
            FlashWindow
        End If
    
        With frmChat.lvChannel
            If pos <= .ListItems.Count Then
                .ListItems.Item(pos).ListSubItems(2).ReportIcon = 0
                .ListItems.Item(pos).SmallIcon = 0
                .ListItems.Remove pos
            End If
        End With
        
        Call frmChat.UpdateListviewLabel
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        If Not Silent Then
            On Error Resume Next
        
            RunInAll "Event_UserLeaves", CleanUsername(Username), Flags
        End If
    End If

    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_UserLeaves()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_UserTalk(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, _
        ByVal Ping As Long, Optional QueuedEventID As Integer = 0)
    
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim UserObj       As clsUserObj
    Dim UserEvent     As clsUserEventObj
    
    Dim strSend       As String
    Dim s             As String
    Dim U             As String
    Dim strCompare    As String
    Dim i             As Integer
    Dim ColIndex      As Integer
    Dim b             As Boolean
    Dim ToANSI        As String
    Dim BanningUser   As Boolean
    Dim UsernameColor As Long
    Dim TextColor     As Long
    Dim CaratColor    As Long
    Dim pos           As Integer
    Dim blnCheck      As Boolean
    
    pos = g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    If (pos > 0) Then
        Set UserObj = g_Channel.Users(pos)
        
        UserObj.LastTalkTime = UtcNow
        
        If (QueuedEventID = 0) Then
            If (UserObj.Queue.Count > 0) Then
                Set UserEvent = New clsUserEventObj
                
                With UserEvent
                    .EventID = ID_TALK
                    .Flags = Flags
                    .Ping = Ping
                    .Message = Message
                End With
                
                UserObj.Queue.Add UserEvent
            End If
        End If
    Else
        ' create new user object for invisible representatives...
        Set UserObj = New clsUserObj
        
        ' store user name
        UserObj.Name = Username
    End If
    
    ' convert user name
    Username = UserObj.DisplayName
    
    If (QueuedEventID = 0) Then
        If (g_Channel.Self.IsOperator) Then
            If (GetSafelist(Username) = False) Then
                CheckMessage Username, Message
            End If
        End If
    End If
    
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        If (Message <> vbNullString) Then
            ' user and message filters
            If (AllowedToTalk(Username, Message)) Then
                ' catch phrases
                If (Catch(0) <> vbNullString) Then
                    CheckPhrase Username, Message, CPTALK
                End If

                ' flash window on events
                If (frmChat.mnuFlash.Checked) Then
                    FlashWindow
                End If

                ' prepare to display, get colors
                ' are we watching the user?
                'If (StrComp(WatchUser, Username, vbTextCompare) = 0) Then
                If (PrepareCheck(Username) Like PrepareCheck(WatchUser)) Then
                    UsernameColor = g_Color.ErrorMessageText
                ' is user an operator?
                ElseIf ((Flags And USER_CHANNELOP&) = USER_CHANNELOP&) Then
                    UsernameColor = g_Color.TalkUsernameOp
                Else
                    UsernameColor = g_Color.TalkUsernameNormal
                End If
                
                If (((Flags And USER_BLIZZREP&) = USER_BLIZZREP&) Or ((Flags And USER_SYSOP&) = _
                        USER_SYSOP&)) Then
                    TextColor = RGB(97, 105, 255)
                    CaratColor = RGB(97, 105, 255)
                Else
                    TextColor = g_Color.TalkNormalText
                    CaratColor = g_Color.Carats
                End If

                ' display to screen
                frmChat.AddChat CaratColor, "<", UsernameColor, Username, CaratColor, "> ", _
                        TextColor, Message

                ' vote check
                If (VoteDuration > 0) Then
                    If (InStr(1, LCase(Message), "yes", vbTextCompare) > 0) Then
                        Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDYES, Username)
                    ElseIf (InStr(1, LCase(Message), "no", vbTextCompare) > 0) Then
                        Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDNO, Username)
                    End If
                End If

                ' process command
                Call ProcessCommand(Username, Message, False, False)
            End If
        End If
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If frmChat.ShuttingDown Then Exit Sub

        On Error Resume Next
        
        ' fudge trigger for scripts?
        If ((BotVars.NoSupportMultiCharTrigger) And (Len(BotVars.TriggerLong) > 1)) Then
            If (StrComp(Left$(Message, Len(BotVars.TriggerLong)), BotVars.TriggerLong, _
                    vbBinaryCompare) = 0) Then
                Message = BotVars.Trigger & Mid$(Message, Len(BotVars.TriggerLong) + 1)
            End If
        End If

        RunInAll "Event_UserTalk", Username, Flags, Message, Ping
    End If

    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_UserTalk()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Private Function CheckMessage(Username As String, Message As String) As Boolean
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim BanningUser As Boolean
    Dim i           As Integer
    
    If (PhraseBans) Then
        For i = LBound(Phrases) To UBound(Phrases)
            If ((Phrases(i) <> vbNullString) And (Phrases(i) <> Space$(1))) Then
                If ((InStr(1, Message, Phrases(i), vbTextCompare)) <> 0) Then
                    Ban Username & " Banned phrase: " & Phrases(i), _
                            (AutoModSafelistValue - 1), Abs(CLng(Config.PhraseKick))
                    
                    BanningUser = True
                    
                    Exit For
                End If
            End If
        Next i
    End If
    
    If (BanningUser = False) Then
        If (BotVars.QuietTime) Then
            Ban Username & " Quiet-time", (AutoModSafelistValue - 1), Abs(CLng(Config.QuietTimeKick))
        Else
            If (BotVars.KickOnYell = 1) Then
                If (Len(Message) > 5) Then
                    If (PercentActualUppercase(Message) > 90) Then
                        Ban Username & " Yelling", (AutoModSafelistValue - 1), 1
                    End If
                End If
            End If
        End If
        
        If ((BotVars.QuietTime) Or (BotVars.KickOnYell = 1)) Then
            BanningUser = True
        End If
    End If
    
    CheckMessage = BanningUser
    
    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.CheckMessage()", Err.Number, Err.Description, OBJECT_NAME))
End Function

Public Sub Event_VersionCheck(Message As Long, ExtraInfo As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Select Case (Message)
        Case 0:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Client version accepted!"
            
            ' if using server finder
            If ((BotVars.BNLS) And (BotVars.UseAltBnls)) Then
                ' save BNLS server so future instances of the bot won't need to get the list, connection succeeded
                If Config.BNLSServer <> BotVars.BNLSServer Then
                    Config.BNLSServer = BotVars.BNLSServer
                    Call Config.Save
                End If
            End If
        
        Case 1:
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Version check failed! " & _
                "The version byte for this attempt was 0x" & Hex(GetVerByte(BotVars.Product)) & "." & _
                IIf(LenB(ExtraInfo) = 0, vbNullString, " Extra Information: " & ExtraInfo)

            If (BotVars.BNLS) Then
                If (frmChat.HandleBnlsError(0, "BNLS has not been updated yet, " & _
                        "or you experienced an error. Try connecting again.")) Then
                    ' if we are using the finder, then don't close all connections
                    Message = 0
                End If
            Else
                frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Please ensure you " & _
                    "have updated your hash files using more current ones from the directory " & _
                        "of the game you're connecting with."
                
                frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] In addition, you can try " & _
                    "choosing ""Update version bytes from StealthBot.net"" from the Bot menu."
            End If
        
        Case 2:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your CD-key is invalid!"
        
        Case 3:
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Version check failed! " & _
                "BNLS has not been updated yet.. Try reconnecting in an hour or two."
        
        Case 4:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your CD-key is for another game."
        
        Case 5:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your CD-key is banned. " & _
                "For more information, visit http://us.blizzard.com/support/article.xml?locale=en_US&articleId=20637 ."
        
        Case 6:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your CD-key is currently in " & _
                "use under the owner name: " & ExtraInfo & "."
        
        Case 7:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your expansion CD-key is invalid."
        
        Case 8:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your expansion CD-key is currently " & _
                "in use under the owner name: " & ExtraInfo & "."
        
        Case 9:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your expansion CD-key is banned. " & _
                "For more information, visit http://us.blizzard.com/support/article.xml?locale=en_US&articleId=20637 ."
        
        Case 10:
            frmChat.AddChat g_Color.SuccessText, "[BNCS] Version check passed!"
            
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Your expansion CD-key is for another game."
        
        Case 11:
            frmChat.AddChat g_Color.ErrorMessageText, "[BNCS] Version check failed! " & _
                "The Battle.net server says your version must be downgraded."
        
        Case Else
            frmChat.AddChat g_Color.ErrorMessageText, "Unhandled 0x51 response! Value: " & Message
    End Select
    
    If (Message > 0) Then
        Call frmChat.DoDisconnect

        If (Message = 6) Then
            ' CD-Key in use?
            Dim MyOwnerName As String
            MyOwnerName = Config.CDKeyOwnerName
            If (LenB(MyOwnerName) = 0) Then
                MyOwnerName = Config.Username
            End If
            If (StrComp(ExtraInfo, MyOwnerName, vbBinaryCompare) = 0) Then
                ' schedule reconnect; don't do the 0-wait one
                Call frmChat.DoScheduleAutoReconnect(False)
            End If
        End If
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_VersionCheck()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

Public Sub Event_WhisperFromUser(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, ByVal Ping As Long)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Const EMAIL_SERVICE_USER As String = "# Email Service #"
    Const MSG_YOUR_FRIEND    As String = "Your friend "
    
    'Dim s       As String
    Dim lCarats As Long
    Dim WWIndex As Integer
    Dim FIndex  As Integer
    Dim Hidden  As Boolean
    Dim SkipPr  As Boolean

    Username = ConvertUsername(Username)

    ' filters...
    SkipPr = False

    ' filter email service?
    If (StrComp(Username, EMAIL_SERVICE_USER, vbBinaryCompare) = 0) Then
        SkipPr = True
        Hidden = (Config.HideExtraServerAlerts)
    End If

    ' filter friend alerts?
    FIndex = frmChat.FriendListHandler.UsernameToFLIndex(Username)
    If FIndex <> 0 Then
        If g_Friends(FIndex).IsMutual Or Not g_Friends(FIndex).IsOnline Then
            If (StrComp(Left$(Message, Len(MSG_YOUR_FRIEND & Username)), MSG_YOUR_FRIEND & Username, vbBinaryCompare) = 0) Then
                SkipPr = True
                Hidden = (Config.HideMutualFriendAlerts)
            End If
        End If
    End If

    ' user and message filters
    If (AllowedToTalk(Username, Message) And Not Hidden) Then
        ' catch phrases
        If (Not SkipPr And Catch(0) <> vbNullString) Then
            Call CheckPhrase(Username, Message, CPWHISPER)
        End If

        ' flash window on events
        If (Not SkipPr And frmChat.mnuFlash.Checked) Then
            FlashWindow
        End If

        ' display to screen
        lCarats = g_Color.WhisperCarats

        If (Flags And &H1) Then
            lCarats = COLOR_BLUE
        End If

        If (Not (frmChat.mnuHideWhispersInrtbChat.Checked)) Then
            frmChat.AddChat lCarats, "<From ", g_Color.WhisperUsernames, _
                Username, lCarats, "> ", g_Color.WhisperText, Message
        End If

        frmChat.AddWhisper lCarats, "<From ", g_Color.WhisperUsernames, _
            Username, lCarats, "> ", g_Color.WhisperText, Message

        ' individual whisper windows
        If (Not SkipPr And frmChat.mnuToggleWWUse.Checked) Then
        'If ((frmChat.mnuToggleWWUse.Checked) And _
            '(frmChat.WindowState <> vbMinimized)) Then
            WWIndex = AddWhisperWindow(Username)
            
            With colWhisperWindows.Item(WWIndex)
                If (.Shown = False) Then
                    'window was previously hidden

                    ShowWW WWIndex
                End If

                .Caption = "Whisper Window: " & Username
                .AddWhisper lCarats, "<", g_Color.WhisperUsernames, _
                    Username, lCarats, "> ", g_Color.WhisperText, Message
            End With
        End If

        ' channel password
        If (Not SkipPr And StrComp(Message, BotVars.ChannelPassword, vbTextCompare) = 0) Then
            lCarats = g_Channel.GetUserIndex(Username)

            If (lCarats > 0) Then
                With g_Channel.Users(lCarats)
                    .PassedChannelAuth = True
                End With

                frmChat.AddQ "/w " & Username & " Password accepted."
            End If
        End If

        ' vote check
        If (Not SkipPr And VoteDuration > 0) Then
            If (InStr(1, Message, "yes", vbTextCompare) > 0) Then
                Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDYES, Username)
            ElseIf (InStr(1, Message, "no", vbTextCompare) > 0) Then
                Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDNO, Username)
            End If
        End If

        '####### Mail check
        If (Not SkipPr And mail) Then
            If (StrComp(Left$(Message, 6), "!inbox", vbTextCompare) = 0) Then
                Dim Msg As udtMail

                If (GetMailCount(Username) > 0) Then
                    Call GetMailMessage(Username, Msg)

                    If (Len(RTrim(Msg.To)) > 0) Then
                        frmChat.AddQ "/w " & Username & " Message from " & _
                            RTrim$(Msg.From) & ": " & RTrim$(Msg.Message)
                    End If
                End If
            End If
        End If
        '#######

        ' process as command
        If (Not SkipPr) Then
            Call ProcessCommand(Username, Message, False, True)
        End If

        ' set last whisper
        If (Not SkipPr) Then
            LastWhisper = Username
            LastWhisperFromTime = Now
        End If
    End If
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' call event script function
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    If frmChat.ShuttingDown Then Exit Sub
    
    On Error Resume Next
    
    RunInAll "Event_WhisperFromUser", Username, Flags, Message, Ping
    'End If

    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_WhisperFromUser()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

' Flags and ping are deliberately not used at this time
Public Sub Event_WhisperToUser(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, ByVal Ping As Long)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Const FRIEND_MSG_USER As String = "your friends"
    
    Dim lCarats As Long
    Dim WWIndex As Integer
    
    'frmChat.AddChat vbRed, Username
    
    If (StrComp(Username, FRIEND_MSG_USER, vbBinaryCompare) <> 0) Then
        Username = ConvertUsername(Username)
        
        LastWhisperTo = Username
    Else
        LastWhisperTo = "%f%"
    End If
    
    lCarats = g_Color.WhisperCarats

    If (Not (frmChat.mnuHideWhispersInrtbChat.Checked)) Then
        frmChat.AddChat lCarats, "<To ", g_Color.WhisperUsernames, _
            Username, lCarats, "> ", g_Color.WhisperText, Message
    End If
    
    If ((frmChat.mnuHideWhispersInrtbChat.Checked) Or _
        (frmChat.mnuToggleShowOutgoing.Checked)) Then
        
        frmChat.AddWhisper lCarats, "<To ", g_Color.WhisperUsernames, _
            Username, lCarats, "> ", g_Color.WhisperText, Message
    End If

    If (frmChat.mnuToggleWWUse.Checked) Then
        If (StrComp(Username, FRIEND_MSG_USER, vbBinaryCompare) <> 0) Then
            WWIndex = AddWhisperWindow(Username)
            
            If (frmChat.WindowState <> vbMinimized) Then
                Call ShowWW(WWIndex)
            End If
            
            With colWhisperWindows.Item(WWIndex)
                .Caption = "Whisper Window: " & Username
                .AddWhisper lCarats, "<", g_Color.TalkBotUsername, _
                    GetCurrentUsername, lCarats, "> ", g_Color.WhisperText, Message
            End With
        End If
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_WhisperToUser()", Err.Number, Err.Description, OBJECT_NAME))
End Sub


'11/22/07 - Hdx - Pass the channel listing (0x0B) directly off to scriptors for there needs. (What other use is there?)
Public Sub Event_ChannelList(sChannels() As String)
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim x As Integer
    Dim sChannel As String
        
    If (MDebug("all")) Then
        frmChat.AddChat g_Color.InformationText, "Received Channel List: "
    End If
    
    ' save public channels
    Set BotVars.PublicChannels = New Collection
    
    For x = 0 To UBound(sChannels)
        sChannel = sChannels(x)

        If LenB(sChannel) > 0 Then
            BotVars.PublicChannels.Add sChannel
        End If
    Next x
    
    PreparePublicChannelMenu
    
    RunInAll "Event_ChannelList", ConvertStringArray(sChannels)
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_ChannelList()", Err.Number, Err.Description, OBJECT_NAME))
End Sub

'10/01/09 - Hdx - This is for SID_MESSAGEBOX, for now it'll raise it's own event, and Event_ServerError
Public Function Event_MessageBox(lStyle As Long, sText As String, sCaption As String)
On Error GoTo ERROR_HANDLER:
    Call Event_ServerError("[BNCS] " & sCaption & ": " & sText)
    
    RunInAll "Event_MessageBox", lStyle, sText, sCaption

    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Event_MessageBox()", Err.Number, Err.Description, OBJECT_NAME))
End Function

Public Function CleanUsername(ByVal Username As String, Optional ByVal PrependNamingStar As Boolean = False) As String
    #If (COMPILE_DEBUG <> 1) Then
        On Error GoTo ERROR_HANDLER
    #End If
    
    Dim tmp As String
    Dim pos As Integer
    
    tmp = Username
    
    If (tmp <> vbNullString) Then
        pos = InStr(1, tmp, "*", vbBinaryCompare)
    
        If (pos > 0) Then
            If (Right$(tmp, 1) = ")") Then
                ' fixed so that usernames actually ending in
                ' ")" don't get trimmed (ultimately messing up
                ' such bots with ops). ~Ribose/2009-11-15
                If pos > 3 Then
                    ' blah (*blah)
                    '     ^^^
                    If Mid$(tmp, pos - 2, 3) = " (*" Then
                        tmp = Left$(tmp, Len(tmp) - 1)
                    End If
                End If
            End If
            
            tmp = Mid$(tmp, pos + 1)
        End If
    End If
    
    If (Dii And PrependNamingStar And BotVars.UseD2Naming = False) Then
        tmp = "*" & tmp
    End If

    CleanUsername = tmp
    
    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.CleanUsername()", Err.Number, Err.Description, OBJECT_NAME))
End Function

'Private Function GetDiablo2CharacterName(ByVal Username As String) As String
'
'    Dim tmp As String
'    Dim Pos As Integer
'
'    Pos = InStr(1, Username, "*", vbBinaryCompare)
'
'    If (Pos > 0) Then
'        tmp = Mid$(Username, 1, Pos - 1)
'    End If
'
'    GetDiablo2CharacterName = tmp
'
'End Function

Public Sub DebugPhantomUser(ByRef User As clsUserObj, ByVal Flags As Long, ByVal Statstring As String, ByVal Ping As Long)
    Call frmChat.AddChat(g_Color.ErrorMessageText, _
        StringFormat("NOTICE! A phantom user has been detected in the channel. Name: {0} - joined: {1}", User.DisplayName, modDateTime.UtcToLocal(User.JoinTime)))
        
    If User.Flags <> Flags Then
        Call frmChat.AddChat(g_Color.ErrorMessageText, StringFormat(" - Flags: 0x{0} -> 0x{1}", Hex(User.Flags), Hex(Flags)))
    End If
    If User.Ping <> Ping Then
        Call frmChat.AddChat(g_Color.ErrorMessageText, StringFormat(" - Ping: {0} -> {1}", User.Ping, Ping))
    End If
    If User.Statstring <> Statstring Then
        Dim NewStats As New clsUserStats
        NewStats.Statstring = Statstring
        
        Call frmChat.AddChat(g_Color.ErrorMessageText, StringFormat(" - Stats: {0} -> {1}", User.Stats.ToString(), NewStats.ToString()))
    End If
End Sub
