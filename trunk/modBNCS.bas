Attribute VB_Name = "modBNCS"
Option Explicit
Private Const OBJECT_NAME As String = "modBNCS"

Private Declare Sub GetSystemTime Lib "kernel32" (lpSystemTime As SYSTEMTIME)
Private Declare Sub GetLocalTime Lib "kernel32" (lpSystemTime As SYSTEMTIME)
Private Declare Function SystemTimeToFileTime Lib "kernel32" (lpSystemTime As SYSTEMTIME, lpFileTime As FILETIME) As Long


Public Const SID_NULL                   As Byte = &H0
Public Const SID_CLIENTID               As Byte = &H5
Public Const SID_STARTVERSIONING        As Byte = &H6
Public Const SID_REPORTVERSION          As Byte = &H7
Public Const SID_ENTERCHAT              As Byte = &HA
Public Const SID_GETCHANNELLIST         As Byte = &HB
Public Const SID_CHATCOMMAND            As Byte = &HE
Public Const SID_CHATEVENT              As Byte = &HF
Public Const SID_LOCALEINFO             As Byte = &H12
Public Const SID_UDPPINGRESPONSE        As Byte = &H14
Public Const SID_MESSAGEBOX             As Byte = &H19
Public Const SID_LOGONCHALLENGEEX       As Byte = &H1D
Public Const SID_CLIENTID2              As Byte = &H1E
Public Const SID_PING                   As Byte = &H25
Public Const SID_LOGONCHALLENGE         As Byte = &H28
Public Const SID_ICONDATA               As Byte = &H2D
Public Const SID_CDKEY                  As Byte = &H30
Public Const SID_CDKEY2                 As Byte = &H36
Public Const SID_LOGONRESPONSE2         As Byte = &H3A
Public Const SID_CREATEACCOUNT2         As Byte = &H3D
Public Const SID_LOGONREALMEX           As Byte = &H3E
Public Const SID_QUERYREALMS2           As Byte = &H40
Public Const SID_EXTRAWORK              As Byte = &H4C
Public Const SID_AUTH_INFO              As Byte = &H50
Public Const SID_AUTH_CHECK             As Byte = &H51
Public Const SID_AUTH_ACCOUNTCREATE     As Byte = &H52
Public Const SID_AUTH_ACCOUNTLOGON      As Byte = &H53
Public Const SID_AUTH_ACCOUNTLOGONPROOF As Byte = &H54
Public Const SID_SETEMAIL               As Byte = &H59

Public Const BNCS_NLS As Long = 1 'New:    SID_AUTH_*
Public Const BNCS_OLS As Long = 2 'Old:    SID_CLIENTID2
Public Const BNCS_LLS As Long = 3 'Legacy: SID_CLIENTID

Public Const PLATFORM_INTEL   As Long = &H49583836 'IX86
Public Const PLATFORM_POWERPC As Long = &H504D4143 'PMAC
Public Const PLATFORM_OSX     As Long = &H584D4143 'XMAC


Public ds As New clsDataStorage 'Need to rename this -.-

Public Function BNCSRecvPacket(ByVal sData As String) As Boolean
On Error GoTo ERROR_HANDLER:
    Static pBuff As New clsDataBuffer
    
    Dim PacketID As Byte
    
    BNCSRecvPacket = True
    With pBuff
        .Clear
        .Data = sData
        .GetByte
        PacketID = .GetByte
        .GetWord
    End With
    
    Select Case PacketID
        Case SID_NULL:                   'Don't Throw Unknown Error                  '0x00
        Case SID_CLIENTID:               'Don't Throw Unknown Error                  '0x05
        Case SID_STARTVERSIONING:        Call RECV_SID_STARTVERSIONING(pBuff)        '0x06
        Case SID_REPORTVERSION:          Call RECV_SID_REPORTVERSION(pBuff)          '0x07
        Case SID_ENTERCHAT:              Call RECV_SID_ENTERCHAT(pBuff)              '0x0A
        Case SID_GETCHANNELLIST:         Call RECV_SID_GETCHANNELLIST(pBuff)         '0x0B
        Case SID_CHATEVENT:              Call RECV_SID_CHATEVENT(pBuff)              '0x0F
        Case SID_MESSAGEBOX:             Call RECV_SID_MESSAGEBOX(pBuff)             '0x19
        Case SID_LOGONCHALLENGEEX:       Call RECV_SID_LOGONCHALLENGEEX(pBuff)       '0x1D
        Case SID_PING:                   Call RECV_SID_PING(pBuff)                   '0x25
        Case SID_LOGONCHALLENGE:         Call RECV_SID_LOGONCHALLENGE(pBuff)         '0x28
        Case SID_ICONDATA:               'Don't Throw Unknown Error                  '0x2D
        Case SID_CDKEY:                  Call RECV_SID_CDKEY(pBuff)                  '0x30
        Case SID_CDKEY2:                 Call RECV_SID_CDKEY2(pBuff)                 '0x36
        Case SID_LOGONRESPONSE2:         Call RECV_SID_LOGONRESPONSE2(pBuff)         '0x3A
        Case SID_CREATEACCOUNT2:         Call RECV_SID_CREATEACCOUNT2(pBuff)         '0x3D
        Case SID_LOGONREALMEX:           Call RECV_SID_LOGONREALMEX(pBuff)           '0x3C
        Case SID_QUERYREALMS2:           Call RECV_SID_QUERYREALMS2(pBuff)           '0x40
        Case SID_EXTRAWORK:              'Don't Throw Unknown Error                  '0x4C
        Case SID_AUTH_INFO:              Call RECV_SID_AUTH_INFO(pBuff)              '0x50
        Case SID_AUTH_CHECK:             Call RECV_SID_AUTH_CHECK(pBuff)             '0x51
        Case SID_AUTH_ACCOUNTCREATE:     Call RECV_SID_AUTH_ACCOUNTCREATE(pBuff)     '0x52
        Case SID_AUTH_ACCOUNTLOGON:      Call RECV_SID_AUTH_ACCOUNTLOGON(pBuff)      '0x53
        Case SID_AUTH_ACCOUNTLOGONPROOF: Call RECV_SID_AUTH_ACCOUNTLOGONPROOF(pBuff) '0x54
        Case SID_SETEMAIL:               Call RECV_SID_SETEMAIL(pBuff)               '0x59
    
        Case Else:
            BNCSRecvPacket = False
            If (MDebug("debug") And (MDebug("all") Or MDebug("unknown"))) Then
                Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("[BNCS] Unhandled packet 0x{0}", ZeroOffset(CLng(PacketID), 2)))
                Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("[BNCS] Packet data: {0}{1}", vbNewLine, DebugOutput(sData)))
            End If
    
    End Select
    
    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("Error: #{0}: {1} in {2}.BNCSRecvPacket()", Err.Number, Err.description, OBJECT_NAME))
End Function

'*********************************
' SID_CLIENTID (0x05) C->S
'*********************************
' (DWORD) Registration Version
' (DWORD) Registration Authority
' (DWORD) Account Number
' (DWORD) Registration Token
' (STRING) LAN computer name
' (STRING) LAN username
'*********************************
'For legacy login system (JSTR, SSHR).
'*********************************
Public Sub SEND_SID_CLIENTID()
On Error GoTo ERROR_HANDLER:

    Dim pBuff As New clsDataBuffer
    With pBuff
        .InsertDWord 0
        .InsertDWord 0
        .InsertDWord 0
        .InsertDWord 0
        .InsertNTString GetComputerLanName
        .InsertNTString GetComputerUsername
        .SendPacket SID_CLIENTID
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_CLIENTID()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_STARTVERSIONING (0x06) S->C
'*******************************
' (FILETIME) MPQ Filetime
' (STRING) MPQ Filename
' (STRING) ValueString
'*******************************
Public Sub RECV_SID_STARTVERSIONING(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
    With pBuff
        ds.CRevFileTime = .GetRaw(8)
        ds.CRevFileName = .GetString
        ds.CRevSeed = .GetString
    End With
    
    Call frmChat.AddChat(RTBColors.InformationText, "[BNCS] Checking version...")
    If (MDebug("all") Or MDebug("crev")) Then
        frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Name: {0}", ds.CRevFileName)
        frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Time: {0}", ds.CRevFileTime)
        If (InStr(1, ds.CRevFileName, "lockdown", vbTextCompare) > 0) Then
            frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Seed: {0}", StrToHex(ds.CRevSeed))
        Else
            frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Seed: {0}", ds.CRevSeed)
        End If
    End If
    
    If (BotVars.BNLS) Then
        Call modBNLS.SEND_BNLS_VERSIONCHECKEX2(ds.CRevFileTimeRaw, ds.CRevFileName, ds.CRevSeed)
    Else
        Call SEND_SID_REPORTVERSION
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_STARTVERSIONING()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_STARTVERSIONING (0x06) C->S
'*******************************
' (DWORD) Platform ID
' (DWORD) Product ID
' (DWORD) Version Byte
' (DWORD) Unknown (0)
'*******************************
Public Sub SEND_SID_STARTVERSIONING(Optional lVerByte As Long = 0)
On Error GoTo ERROR_HANDLER:

    Dim pBuff As New clsDataBuffer
    
    With pBuff
        .InsertDWord GetDWORDOverride("PlatID", PLATFORM_INTEL)               'Platform ID
        .InsertDWord GetDWORD(BotVars.Product)                                'Product ID
        .InsertDWord IIf(lVerByte = 0, GetVerByte(BotVars.Product), lVerByte) 'VersionByte
        .InsertDWord 0  'Unknown
        .SendPacket SID_STARTVERSIONING
    End With
    
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_STARTVERSIONING()", Err.Number, Err.description, OBJECT_NAME))
End Sub
'*******************************
'SID_REPORTVERSION (0x07) S->C
'*******************************
' (DWORD) Result
' (STRING) Patch path
'*******************************
Private Sub RECV_SID_REPORTVERSION(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    Dim lResult  As Long
    Dim sInfo    As String
    Dim bSuccess As Boolean
    
    lResult = pBuff.GetDWORD
    sInfo = pBuff.GetString
    bSuccess = False
    
    Select Case lResult
        Case 0: Call Event_VersionCheck(1, sInfo) 'Failed Version Check
        Case 1: Call Event_VersionCheck(1, sInfo) 'Old Game Version
        Case 2: 'Success
            bSuccess = True
            Call Event_VersionCheck(0, sInfo)
        Case 3: Call Event_VersionCheck(1, sInfo) '"Reinstall Required", Invalid version
        Case Else:
            Call frmChat.AddChat(RTBColors.ErrorMessageText, "Unknown SID_REPORTVERSION Response: 0x" & ZeroOffset(lResult, 8))
    End Select

    If (frmChat.sckBNet.State = 7 And bSuccess) Then
        If (GetCDKeyCount > 0) Then
            Call frmChat.AddChat(RTBColors.InformationText, "[BNCS] Sending CDKey information...")
            Select Case GetLogonSystem()
                Case BNCS_OLS: Call SEND_SID_CDKEY2
                Case BNCS_LLS: Call SEND_SID_CDKEY
                Case Else:
                    frmChat.AddChat RTBColors.ErrorMessageText, StringFormat("Unknown Logon System Type: {0}", modBNCS.GetLogonSystem())
                    frmChat.AddChat RTBColors.ErrorMessageText, "Please visit http://www.stealthbot.net/sb/issues/?unknownLogonType for information regarding this error."
                    frmChat.DoDisconnect
            End Select
        Else
            Call frmChat.AddChat(RTBColors.InformationText, "[BNCS] Sending login information...")
            frmChat.tmrAccountLock.Enabled = True
            SEND_SID_LOGONRESPONSE2
        End If
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_REPORTVERSION()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_REPORTVERSION (0x07) C->S
'*******************************
' (DWORD) Platform ID
' (DWORD) Product ID
' (DWORD) Version Byte
' (DWORD) EXE Version
' (DWORD) EXE Hash
' (STRING) EXE Information
'*******************************
Public Sub SEND_SID_REPORTVERSION(Optional lVerByte As Long = 0)
On Error GoTo ERROR_HANDLER:

    If (Not BotVars.BNLS) Then
        If (Not CompileCheckrevision()) Then
            frmChat.DoDisconnect
            Exit Sub
        End If
    End If
        
    If (ds.CRevChecksum = 0 Or ds.CRevVersion = 0 Or LenB(ds.CRevResult) = 0) Then
        frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Check Revision Failed, sanity failed"
        frmChat.DoDisconnect
        Exit Sub
    End If
    
    Dim pBuff As New clsDataBuffer
    With pBuff
        .InsertDWord GetDWORDOverride("PlatID", PLATFORM_INTEL)               'Platform ID
        .InsertDWord GetDWORD(BotVars.Product)                                'Product ID
        .InsertDWord IIf(lVerByte = 0, GetVerByte(BotVars.Product), lVerByte) 'VersionByte
        .InsertDWord ds.CRevVersion                                           'Exe Version
        .InsertDWord ds.CRevChecksum                                          'Checksum
        .InsertNTString ds.CRevResult                                         'Result
        .SendPacket SID_REPORTVERSION
    End With
    
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_STARTVERSIONING()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_ENTERCHAT (0x0A) S->C
'*******************************
' (String) Unique name
' (String) Statstring
' (String) Account name
'*******************************
Private Sub RECV_SID_ENTERCHAT(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:

    Call Event_LoggedOnAs(pBuff.GetString, pBuff.GetString, pBuff.GetString)

    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_ENTERCHAT()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_ENTERCHAT (0x0A) C->S
'*******************************
' (STRING) Username *
' (STRING) Statstring **
'*******************************
Private Sub SEND_SID_ENTERCHAT()
On Error GoTo ERROR_HANDLER:
    Dim pBuff As New clsDataBuffer
    pBuff.InsertNTString BotVars.Username
    pBuff.InsertNTString ReadCfg("Override", "SetBotStatstring")
    pBuff.SendPacket SID_ENTERCHAT
    Set pBuff = Nothing

    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_ENTERCHAT()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_GETCHANNELLIST (0x0B) S->C
'*******************************
' (String[]) Channels
'*******************************
Private Sub RECV_SID_GETCHANNELLIST(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:

    Dim sChannels() As String
    sChannels = Split(pBuff.GetRaw(), Chr$(0))
    
    Call Event_ChannelList(sChannels)
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_GETCHANNELLIST()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_GETCHANNELLIST (0x0B) S->C
'*******************************
' (DWORD) Product ID
'*******************************
Private Sub SEND_SID_GETCHANNELLIST()
On Error GoTo ERROR_HANDLER:
    Dim pBuff As New clsDataBuffer
    pBuff.InsertDWord GetDWORD(BotVars.Product)
    pBuff.SendPacket SID_GETCHANNELLIST
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_GETCHANNELLIST()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_CHATCOMMAND (0x0E) S->C
'*******************************
' (STRING) Text
'*******************************
Public Sub SEND_SID_CHATCOMMAND(sText As String)
On Error GoTo ERROR_HANDLER:

    If (LenB(sText) = 0) Then Exit Sub
    
    Dim pBuff As New clsDataBuffer
    pBuff.InsertNTString sText
    pBuff.SendPacket SID_CHATCOMMAND
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_CHATCOMMAND()", Err.Number, Err.description, OBJECT_NAME))
End Sub


'*******************************
'SID_CHATEVENT (0x0F) S->C
'*******************************
' (DWORD) Event ID
' (DWORD) User's Flags
' (DWORD) Ping
' (DWORD) IP Address (Defunct)
' (DWORD) Account number (Defunct)
' (DWORD) Registration Authority (Defunct)
' (STRING) Username
' (STRING) Text
'*******************************
Private Sub RECV_SID_CHATEVENT(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
    Dim EventID   As Long
    Dim lFlags    As Long
    Dim lPing     As Long
    Dim sUsername As String
    Dim sText     As String
    
    Dim sProduct As String
    Dim sParsed  As String
    Dim sClanTag As String
    Dim sW3Icon  As String
    
    EventID = pBuff.GetDWORD
    lFlags = pBuff.GetDWORD
    lPing = pBuff.GetDWORD
    pBuff.GetDWORD 'IP Address
    pBuff.GetDWORD 'Account Number
    pBuff.GetDWORD 'Reg Auth
    sUsername = pBuff.GetString
    sText = pBuff.GetString
    
                
    If (LenB(sText) > 0) Then
        Dim cUserStats As New clsUserStats
        With cUserStats
            .Statstring = sText
            sProduct = .Game
            sParsed = .ToString
            sClanTag = .Clan
        End With
        Set cUserStats = Nothing
    End If
                
    If sProduct = "WAR3" Or sProduct = "W3XP" Then
        If Len(sText) > 4 Then sW3Icon = StrReverse(Mid$(sText, 6, 4))
    End If
                
    Select Case EventID
        Case ID_JOIN:        Call Event_UserJoins(sUsername, lFlags, sParsed, lPing, sProduct, sClanTag, sText, sW3Icon)
        Case ID_LEAVE:       Call Event_UserLeaves(sUsername, lFlags)
        Case ID_USER:        Call Event_UserInChannel(sUsername, lFlags, sParsed, lPing, sProduct, sClanTag, sText, sW3Icon)
        Case ID_WHISPER:     If (Not bFlood) Then Call Event_WhisperFromUser(sUsername, lFlags, sText, lPing)
        Case ID_TALK:        Call Event_UserTalk(sUsername, lFlags, sText, lPing)
        Case ID_BROADCAST:   Call Event_ServerInfo(sUsername, StringFormat("BROADCAST from {0}:{1}", sUsername, sText))
        Case ID_CHANNEL:     Call Event_JoinedChannel(sText, lFlags)
        Case ID_USERFLAGS:   Call Event_FlagsUpdate(sUsername, sText, lFlags, lPing, sProduct)
        Case ID_WHISPERSENT: Call Event_WhisperToUser(sUsername, lFlags, sText, lPing)
        Case ID_CHANNELFULL, ID_CHANNELDOESNOTEXIST, ID_CHANNELRESTRICTED: 'Call Event_ServerError(sText)
        Case ID_INFO:        Call Event_ServerInfo(sUsername, sText)
        Case ID_ERROR:       Call Event_ServerError(sText)
        Case ID_EMOTE:       Call Event_UserEmote(sUsername, lFlags, sText)
        Case Else:
            If MDebug("debug") Then
                Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("Unhandled SID_CHATEVENT Event: 0x{0}", ZeroOffset(EventID, 8)))
                Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("Packet data: {0}{1}", vbNewLine, DebugOutput(pBuff.Data)))
            End If
    End Select
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_CHATEVENT()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*********************************
' SID_LOCALEINFO (0x12) C->S
'*********************************
' (FILETIME) System time
' (FILETIME) Local time
' (DWORD) Timezone bias
' (DWORD) SystemDefaultLCID
' (DWORD) UserDefaultLCID
' (DWORD) UserDefaultLangID
' (STRING) Abbreviated language name
' (STRING) Country Code
' (STRING) Abbreviated country name
' (STRING) Country Name
'*********************************
Public Sub SEND_SID_LOCALEINFO()
On Error GoTo ERROR_HANDLER:
    Const LOCALE_SABBREVLANGNAME As Long = &H3
    Const LOCALE_USER_DEFAULT    As Long = &H400
    Dim LanguageAbr As String
    Dim CountryCode As String
    Dim CountryAbr  As String
    Dim CountryName As String
    Dim lRet        As String
    
    Dim st As SYSTEMTIME
    Dim ft As FILETIME
    
    Dim pBuff As New clsDataBuffer
    
    LanguageAbr = String$(256, 0)
    Call GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SABBREVLANGNAME, LanguageAbr, Len(LanguageAbr))
    LanguageAbr = KillNull(LanguageAbr)
    
    Call GetCountryData(CountryAbr, CountryName, CountryCode)
    If (Len(LanguageAbr) = 0) Then LanguageAbr = "ENU"
    If (Len(CountryCode) = 0) Then CountryCode = "1"
    If (Not Len(CountryAbr) = 3) Then CountryAbr = "USA"
    If (LenB(CountryName) = 0) Then CountryName = "United States"
    
    With pBuff
        Call GetSystemTime(st)
        Call SystemTimeToFileTime(st, ft)
        .InsertDWord ft.dwLowDateTime                                 'SystemTime
        .InsertDWord ft.dwHighDateTime                                'SystemTime
        
        Call GetLocalTime(st)
        Call SystemTimeToFileTime(st, ft)
        .InsertDWord ft.dwLowDateTime                                 'LocalTime
        .InsertDWord ft.dwHighDateTime                                'LocalTime
        
        .InsertDWord GetTimeZoneBias                                  'Time Zone Bias
        If (ReadCfg("Override", "ForceDefaultLocaleID") = "Y") Then
            .InsertDWord 1033                                         'SystemDefaultLCID
            .InsertDWord 1033                                         'UserDefaultLCID
            .InsertDWord 1033                                         'UserDefaultLangID
        Else
            .InsertDWord CLng(GetSystemDefaultLCID)                   'SystemDefaultLCID
            .InsertDWord CLng(GetUserDefaultLCID)                     'UserDefaultLCID
            .InsertDWord CLng(GetUserDefaultLangID)                   'UserDefaultLangID
        End If
        
        .InsertNTString LanguageAbr                                   'Language Abbrev
        .InsertNTString CountryCode                                   'Country Code
        .InsertNTString CountryAbr                                    'Country Abbrev
        .InsertNTString CountryName                                   'Country Name
        
        .SendPacket SID_LOCALEINFO
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_LOCALEINFO()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_UDPPINGRESPONSE (0x14) C->S
'*******************************
' (DWORD) UDP value
'*******************************
Private Sub SEND_SID_UDPPINGRESPONSE()
On Error GoTo ERROR_HANDLER:

    Dim pBuff As New clsDataBuffer

    If Len(ReadCfg("Override", "UDPString")) = 4 Then
        pBuff.InsertNonNTString ReadCfg("Override", "UDPString")
    Else
        pBuff.InsertDWord &H626E6574 'bnet
    End If
    pBuff.SendPacket SID_UDPPINGRESPONSE
    
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_UDPPINGRESPONSE()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_MESSAGEBOX (0x19) S->C
'*******************************
' (DWORD) Style
' (String) Text
' (String) Caption
'*******************************
Private Sub RECV_SID_MESSAGEBOX(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:

    Call Event_MessageBox(pBuff.GetDWORD, pBuff.GetString, pBuff.GetString)
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_MESSAGEBOX()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'********************************
'SID_LOGONCHALLENGEEX (0x1D) S->C
'********************************
' (DWORD) UDP Token
' (DWORD) Server Token
'********************************
Private Sub RECV_SID_LOGONCHALLENGEEX(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
    ds.UDPValue = pBuff.GetDWORD
    ds.ServerToken = pBuff.GetDWORD
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_LOGONCHALLENGEEX()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*********************************
' SID_CLIENTID2 (0x1E) C->S
'*********************************
' (DWORD) Server Version
' For server version 1:
'  (DWORD) Registration Version
'  (DWORD) Registration Authority
' For server version 0:
'  (DWORD) Registration Authority
'  (DWORD) Registration Version
' (DWORD) Account Number
' (DWORD) Registration Token
' (STRING) LAN computer name
' (STRING) LAN username
'*********************************
'This is eww, I don't like hard coding,
'but to get this crap I would need to
'use Storm.dll, which we don't want to
'distribute with the bot.
'*********************************
Public Sub SEND_SID_CLIENTID2()
On Error GoTo ERROR_HANDLER:

    Dim pBuff As New clsDataBuffer
    With pBuff
        .InsertDWord 1
        .InsertDWord 0
        .InsertDWord 0
        .InsertDWord 0
        .InsertDWord 0
        .InsertNTString GetComputerLanName
        .InsertNTString GetComputerUsername
        .SendPacket SID_CLIENTID2
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_CLIENTID2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_PING (0x25) S->C
'*******************************
' (DWORD) Ping value
'*******************************
Private Sub RECV_SID_PING(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:

    If (BotVars.Spoof = 0 Or g_Online) Then
        Call SEND_SID_PING(pBuff.GetDWORD)
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_PING()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_PING (0x25) C->S
'*******************************
' (DWORD) Ping value
'*******************************
Private Sub SEND_SID_PING(lPingValue As Long)
On Error GoTo ERROR_HANDLER:

    Dim pBuff As New clsDataBuffer
    
    SetNagelStatus frmChat.sckBNet.SocketHandle, False
    
    pBuff.InsertDWord lPingValue
    pBuff.SendPacket SID_PING
    
    SetNagelStatus frmChat.sckBNet.SocketHandle, True
    
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_PING()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'********************************
'SID_LOGONCHALLENGE (0x28) S->C
'********************************
' (DWORD) Server Token
'********************************
Private Sub RECV_SID_LOGONCHALLENGE(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
    ds.ServerToken = pBuff.GetDWORD
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_LOGONCHALLENGE()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_CDKEY (0x30) S->C
'*******************************
' (DWORD) Result
' (STRING) Key owner
'*******************************
Private Sub RECV_SID_CDKEY(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    Dim lResult As Long
    Dim sInfo   As String
    
    lResult = pBuff.GetDWORD
    sInfo = pBuff.GetString
    
    Select Case lResult
        Case 1:
            frmChat.AddChat RTBColors.SuccessText, "[BNCS] Your CDKey was accepted!"
            frmChat.AddChat RTBColors.InformationText, "[BNCS] Sending login information..."
            frmChat.tmrAccountLock.Enabled = True
            SEND_SID_LOGONRESPONSE2
            Exit Sub
        Case 2: Call Event_VersionCheck(2, sInfo) 'Invalid CDKey
        Case 3: Call Event_VersionCheck(4, sInfo) 'CDKey is for the wrong product
        Case 4: Call Event_VersionCheck(5, sInfo) 'CDKey is Banned
        Case 5: Call Event_VersionCheck(6, sInfo) 'CDKey is In Use
        Case Else: frmChat.AddChat RTBColors.ErrorMessageText, StringFormat("[BNCS] Unknown SID_CDKEY Response 0x{0}: {1}", ZeroOffset(lResult, 8), sInfo)
    End Select
    CloseAllConnections
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_CDKEY()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_CDKEY (0x30) C->S
'*******************************
' (DWORD) Spawn (0/1)
' (STRING) Key
' (STRING) Key owner
'*******************************
Public Sub SEND_SID_CDKEY()
On Error GoTo ERROR_HANDLER:
    Dim lResult  As Long
    
    Dim pBuff As New clsDataBuffer
    
    lResult = kd_init()
    
    If (lResult = 0) Then
        frmChat.AddChat RTBColors.ErrorMessageText, "BNCSUtil: kd_init() failed! Please use BNLS to connect."
        frmChat.DoDisconnect
    Else
        lResult = kd_create(BotVars.CDKey, Len(BotVars.CDKey))
        If (kd_isValid(lResult) = 0) Then
            frmChat.AddChat RTBColors.ErrorMessageText, "Your CD-Key is invalid."
            frmChat.DoDisconnect
        End If
        Call kd_free(lResult)
    End If
    
    With pBuff
        .InsertDWord IIf(ReadCfg$("Override", "SpawnKey") = "Y", 1, 0)
        .InsertNTString BotVars.CDKey
        
        If (LenB(ReadCfg("Override", "OwnerName")) > 0) Then
            .InsertNTString ReadCfg("Override", "OwnerName")
        Else
            .InsertNTString BotVars.Username
        End If
        .SendPacket SID_CDKEY
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_CDKEY()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_CDKEY2 (0x36) S->C
'*******************************
' (DWORD) Result
' (STRING) Key owner
'*******************************
Private Sub RECV_SID_CDKEY2(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    Dim lResult As Long
    Dim sInfo   As String
    
    lResult = pBuff.GetDWORD
    sInfo = pBuff.GetString
    
    Select Case lResult
        Case 1:
            frmChat.AddChat RTBColors.SuccessText, "[BNCS] Your CDKey was accepted!"
            frmChat.AddChat RTBColors.InformationText, "[BNCS] Sending login information..."
            frmChat.tmrAccountLock.Enabled = True
            SEND_SID_LOGONRESPONSE2
            Exit Sub
        Case 2: Call Event_VersionCheck(2, sInfo) 'Invalid CDKey
        Case 3: Call Event_VersionCheck(4, sInfo) 'CDKey is for the wrong product
        Case 4: Call Event_VersionCheck(5, sInfo) 'CDKey is Banned
        Case 5: Call Event_VersionCheck(6, sInfo) 'CDKey is In Use
        Case Else: frmChat.AddChat RTBColors.ErrorMessageText, StringFormat("[BNCS] Unknown SID_CDKEY2 Response 0x{0}: {1}", ZeroOffset(lResult, 8), sInfo)
    End Select
    CloseAllConnections
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_CDKEY2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_CDKEY2 (0x36) C->S
'*******************************
' (DWORD) Spawn (0/1)
' (DWORD) Key Length
' (DWORD) CDKey Product
' (DWORD) CDKey Value1
' (DWORD) Server Token
' (DWORD) Client Token
' (DWORD) [5] Hashed Data
' (STRING) Key owner
'*******************************
Public Sub SEND_SID_CDKEY2()
On Error GoTo ERROR_HANDLER:
    Dim sHash    As String
    Dim lResult  As Long
    Dim lProduct As Long
    Dim lPrivate As Long
    Dim lPublic  As Long
    
    Dim pBuff As New clsDataBuffer
    
    lResult = kd_init()
    
    If (lResult = 0) Then
        frmChat.AddChat RTBColors.ErrorMessageText, "BNCSUtil: kd_init() failed! Please use BNLS to connect."
        frmChat.DoDisconnect
    Else
        lResult = kd_create(BotVars.CDKey, Len(BotVars.CDKey))
        If (kd_isValid(lResult) = 0) Then
            frmChat.AddChat RTBColors.ErrorMessageText, "Your CD-Key is invalid."
            frmChat.DoDisconnect
        Else
            lProduct = kd_product(lResult)
            lPublic = kd_val1(lResult)
            lPrivate = kd_val2(lResult)
            Call kd_free(lResult)
            
            With pBuff
                .InsertDWord ds.ClientToken
                .InsertDWord ds.ServerToken
                .InsertDWord lProduct
                .InsertDWord lPublic
                .InsertDWord lPrivate
                sHash = String$(20, 0)
                Call modBNCSutil.calcHashBuf(.Data, 20, sHash)
                .Clear
            End With
        End If
    End If
    
    With pBuff
        .InsertDWord IIf(ReadCfg$("Override", "SpawnKey") = "Y", 1, 0)
        .InsertDWord Len(BotVars.CDKey)
        
        .InsertDWord lProduct
        .InsertDWord lPublic
        .InsertDWord ds.ServerToken
        .InsertDWord ds.ClientToken
        .InsertNonNTString sHash
        
        If (LenB(ReadCfg("Override", "OwnerName")) > 0) Then
            .InsertNTString ReadCfg("Override", "OwnerName")
        Else
            .InsertNTString BotVars.Username
        End If
        .SendPacket SID_CDKEY2
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_CDKEY2()", Err.Number, Err.description, OBJECT_NAME))
End Sub


'*******************************
'SID_LOGONRESPONSE2 (0x3A) S->C
'*******************************
' (DWORD) Result
' (STRING) Reason
'*******************************
Private Sub RECV_SID_LOGONRESPONSE2(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    Dim lResult As Long
    Dim sInfo  As String
    
    lResult = pBuff.GetDWORD
    sInfo = pBuff.GetString
    
    Select Case lResult
        Case &H0:  'Login Successful
            Call Event_LogonEvent(2, sInfo)
            
            If (Not ds.WaitingForEmail) Then
                If (Dii And BotVars.UseRealm) Then
                    Call frmChat.AddChat(RTBColors.InformationText, "[BNCS] Asking Battle.net for a list of Realm servers...")
                    frmRealm.Show
                    SEND_SID_QUERYREALMS2
                Else
                    SendEnterChatSequence
                End If
            Else
                frmEMailReg.Show
            End If
            
        Case &H1:  'Nonexistent account.
            Call Event_LogonEvent(0, sInfo)
            Call Event_LogonEvent(3, sInfo)
            SEND_SID_CREATEACCOUNT2
            
        Case &H2:  'Invalid password.
            Call Event_LogonEvent(1, sInfo)
            Call frmChat.DoDisconnect
            
        Case &H6:  'Account has been closed (includes a reason)
            Call Event_LogonEvent(5, sInfo)
            Call frmChat.DoDisconnect
                        
        Case Else:
            frmChat.AddChat RTBColors.ErrorMessageText, StringFormat("[BNCS] Unknown response to SID_LOGONRESPONSE2: 0x{0}", ZeroOffset(lResult, 8))
    End Select
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_LOGONRESPONSE2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_LOGONRESPONSE2 (0x3A) C->S
'*******************************
' (DWORD) Client Token
' (DWORD) Server Token
' (DWORD) [5] Password Hash
' (STRING) Username
'*******************************
Public Sub SEND_SID_LOGONRESPONSE2()
On Error GoTo ERROR_HANDLER:
    Dim sHash As String
    Dim pBuff As New clsDataBuffer
    
    If (ReadCfg("Override", "LowerCasePassword") = "N") Then
        sHash = doubleHashPassword(BotVars.Password, ds.ClientToken, ds.ServerToken)
    Else
        sHash = doubleHashPassword(LCase(BotVars.Password), ds.ClientToken, ds.ServerToken)
    End If
    
    With pBuff
        .InsertDWord ds.ClientToken
        .InsertDWord ds.ServerToken
        .InsertNonNTString sHash
        .InsertNTString BotVars.Username
        .SendPacket SID_LOGONRESPONSE2
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_LOGONRESPONSE2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_CREATEACCOUNT2 (0x3D) S->C
'*******************************
' (DWORD) Status
' (STRING) Account name suggestion
'*******************************
Private Sub RECV_SID_CREATEACCOUNT2(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:

    Dim lResult As Long
    Dim sInfo   As String
    Dim sOut    As String
    
    lResult = pBuff.GetDWORD
    sInfo = pBuff.GetString
    
    Select Case lResult
        Case 0:
            frmChat.AddChat RTBColors.SuccessText, "[BNCS] Account created successfully!"
            modBNCS.SEND_SID_LOGONRESPONSE2
            Exit Sub
            
        Case 2: sOut = "Your desired account name contains invalid characters."
        Case 3: sOut = "Your desired account name contains a banned word."
        Case 4: sOut = "Your desired account name already exists."
        Case 6: sOut = "Your desired account name does not contain enough alphanumeric characters."
        Case Else: sOut = StringFormat("Unknown response to SID_CREATEACCOUNT2. Result code: 0x{0}", ZeroOffset(lResult, 8))
    End Select
    
    frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] There was an error in trying to create a new account."
    frmChat.AddChat RTBColors.ErrorMessageText, StringFormat("[BNCS] {0}", sOut)
             
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_CREATEACCOUNT2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**************************************
'SID_CREATEACCOUNT2 (0x3D) C->S
'**************************************
' (DWORD) [5] Password hash
' (STRING) Username
'**************************************
Private Sub SEND_SID_CREATEACCOUNT2()
On Error GoTo ERROR_HANDLER:
    
    Dim sHash As String
    If (ReadCfg("Override", "LowerCasePassword") = "N") Then
        sHash = hashPassword(BotVars.Password)
    Else
        sHash = hashPassword(LCase(BotVars.Password))
    End If
    
    Dim pBuff As New clsDataBuffer
    With pBuff
        .InsertNonNTString sHash
        .InsertNTString BotVars.Username
        .SendPacket SID_CREATEACCOUNT2
    End With
    Set pBuff = Nothing
        
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_CREATEACCOUNT2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_LOGONREALMEX (0x3E) S->C
'*******************************
' (DWORD) MCP Cookie
' (DWORD) MCP Status
' (DWORD) [2] MCP Chunk 1
' (DWORD) IP
' (DWORD) Port
' (DWORD) [12] MCP Chunk 2
' (STRING) Battle.net unique name
'*******************************
Private Sub RECV_SID_LOGONREALMEX(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    Dim lError   As Long
    Dim sMCPData As String
    Dim sIP      As String
    Dim lPort    As Integer
    Dim x        As Integer
    

    If (Len(pBuff.GetRaw(, True)) > 8) Then
        sMCPData = pBuff.GetRaw(16)
        
        For x = 1 To 4
            sIP = StringFormat("{0}{1}{2}", sIP, pBuff.GetByte, IIf(x = 4, vbNullString, "."))
        Next x
        lPort = ntohs(pBuff.GetDWORD)
        ds.MCPData = StringFormat("{0}{1}", sMCPData, pBuff.GetRaw(48))
        ds.UniqueName = pBuff.GetString
        
        If (Not frmChat.sckMCP.State = 0) Then frmChat.sckMCP.Close
        frmChat.AddChat RTBColors.SuccessText, StringFormat("[REALM] Connecting to Realm server at {0}:{1}", sIP, lPort)
        frmChat.sckMCP.Connect sIP, lPort
    Else
        pBuff.GetDWORD
        lError = pBuff.GetDWORD
        
        Select Case lError
            Case &H80000001: frmChat.AddChat RTBColors.ErrorMessageText, "[REALM] The Diablo II Realm is currently unavailable. Please try again later."
            Case &H80000002: frmChat.AddChat RTBColors.ErrorMessageText, "[REALM] Diablo II Realm logon has failed. Please try again later."
            Case Else:       frmChat.AddChat RTBColors.ErrorMessageText, StringFormat("[REALM] Login to the Diablo II Realm has failed for an unknown reason (0x{0}). Please try again later.", ZeroOffset(lError, 8))
        End Select
        
        Unload frmRealm
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_LOGONREALMEX()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_LOGONREALMEX (0x3E) C->S
'*******************************
' (DWORD) Client Token
' (DWORD) [5] Hashed realm password
' (STRING) Realm title
'*******************************
Private Sub SEND_SID_LOGONREALMEX(sRealmTitle As String)
On Error GoTo ERROR_HANDLER:
    
    If (LenB(sRealmTitle) = 0) Then Exit Sub
    
    Dim pBuff As New clsDataBuffer
    pBuff.InsertDWord ds.ClientToken
    pBuff.InsertNonNTString doubleHashPassword("password", ds.ClientToken, ds.ServerToken)
    pBuff.InsertNTString sRealmTitle
    pBuff.SendPacket SID_LOGONREALMEX
    Set pBuff = Nothing
    
    Call frmChat.AddChat(RTBColors.InformationText, StringFormat("[BNCS] Logging in to the Diablo II Realm {0}...", sRealmTitle))
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_LOGONREALMEX()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_QUERYREALMS2 (0x40) S->C
'*******************************
' (DWORD) Unknown
' (DWORD) Count
' For Each Realm:
'   (DWORD) Unknown
'   (STRING) Realm title
'   (STRING) Realm description
'*******************************
Private Sub RECV_SID_QUERYREALMS2(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
        Dim lCount As Long
        Dim sTitle As String
        Dim sDesc  As String
        Dim i      As Integer
        
        pBuff.GetDWORD 'Unknown
        lCount = pBuff.GetDWORD
        
        If (MDebug("debug") And (MDebug("all") Or MDebug("info"))) Then
            frmChat.AddChat RTBColors.InformationText, "Received Realm List:"
        End If
        For i = 1 To lCount
            pBuff.GetDWORD 'Unknown
            sTitle = pBuff.GetString
            sDesc = pBuff.GetString
            If (MDebug("debug") And (MDebug("all") Or MDebug("info"))) Then
                frmChat.AddChat RTBColors.InformationText, StringFormat("  {0}: {1}", sTitle, sDesc)
            End If
        Next i
        
        Call frmChat.AddChat(RTBColors.SuccessText, "[BNCS] Received Realm list")
        If (LenB(sTitle) > 0) Then
            SEND_SID_LOGONREALMEX sTitle
        Else
            Call frmChat.AddChat(RTBColors.SuccessText, "[BNCS] All Diablo II realms are currently offline")
        End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.Recv_SID_QUERYREALMS2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_QUERYREALMS2 (0x40) C->S
'*******************************
' [Blank]
'*******************************
Private Sub SEND_SID_QUERYREALMS2()
On Error GoTo ERROR_HANDLER:

    Dim pBuff As New clsDataBuffer
    pBuff.SendPacket SID_QUERYREALMS2
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_QUERYREALMS2()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_AUTH_INFO (0x50) S->C
'*******************************
' (DWORD) Logon Type
' (DWORD) Server Token
' (DWORD) UDPValue
' (FILETIME) CRev Archive File Time
' (STRING) CRev Archive File Name
' (STRING) CRev Seed Values
' WAR3/W3XP Only:
'   (VOID) 128-byte Server signature
'*******************************
Private Sub RECV_SID_AUTH_INFO(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:

    ds.LogonType = pBuff.GetDWORD
    ds.ServerToken = pBuff.GetDWORD
    ds.UDPValue = pBuff.GetDWORD
    ds.CRevFileTime = pBuff.GetRaw(8)
    ds.CRevFileName = pBuff.GetString
    ds.CRevSeed = pBuff.GetString
    ds.ServerSig = pBuff.GetRaw(128)
    
    Call frmChat.AddChat(RTBColors.InformationText, "[BNCS] Checking version...")
    
    If (MDebug("all") Or MDebug("crev")) Then
        frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Name: {0}", ds.CRevFileName)
        frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Time: {0}", ds.CRevFileTime)
        If (InStr(1, ds.CRevFileName, "lockdown", vbTextCompare) > 0) Then
            frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Seed: {0}", StrToHex(ds.CRevSeed))
        Else
            frmChat.AddChat RTBColors.InformationText, StringFormat("CRev Seed: {0}", ds.CRevSeed)
        End If
    End If
    
    If (Len(ds.ServerSig) = 128) Then
        If (ds.NLS.VerifyServerSignature(frmChat.sckBNet.RemoteHostIP, ds.ServerSig)) Then
            frmChat.AddChat RTBColors.SuccessText, "[BNCS] Server signature validated!"
        Else
            If (Not BotVars.UseProxy) Then
                frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Warning, Server signature is invalid, this may not be a valid server."
            End If
        End If
    ElseIf (GetProductKey = "W3") Then
        frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Warning, Server signature is missing, this may not be a valid server."
    End If
    
    If (BotVars.BNLS) Then
        modBNLS.SEND_BNLS_VERSIONCHECKEX2 ds.CRevFileTimeRaw, ds.CRevFileName, ds.CRevSeed
    Else
        modBNCS.SEND_SID_AUTH_CHECK
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_AUTH_INFO()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_AUTH_INFO (0x50) C->S
'*******************************
' (DWORD) Protocol ID (0)
' (DWORD) Platform ID
' (DWORD) Product ID
' (DWORD) Version Byte
' (DWORD) Product language
' (DWORD) Local IP for NAT compatibility*
' (DWORD) Time zone bias*
' (DWORD) Locale ID*
' (DWORD) Language ID*
' (STRING) Country abreviation
' (STRING) Country
'*******************************
Public Sub SEND_SID_AUTH_INFO(Optional lVerByte As Long = 0)
On Error GoTo ERROR_HANDLER:

    Dim LocalIP     As Long
    Dim CountryAbr  As String
    Dim CountryName As String
    
    Dim pBuff As New clsDataBuffer
    
    LocalIP = aton(frmChat.sckBNet.LocalIP)

    Call GetCountryData(CountryAbr, CountryName, vbNull)
    If (Not Len(CountryAbr) = 3) Then CountryAbr = "USA"
    If (LenB(CountryName) = 0) Then CountryName = "United States"
    
    With pBuff
    
        .InsertDWord GetLongOverride("ProtID", 0)                             'ProtocolID
        .InsertDWord GetDWORDOverride("PlatID", PLATFORM_INTEL)               'Platform ID
        .InsertDWord GetDWORD(BotVars.Product)                                'Product ID
        .InsertDWord IIf(lVerByte = 0, GetVerByte(BotVars.Product), lVerByte) 'VersionByte
        .InsertDWord GetLongOverride("ProdLang", 0)                           'Product Language
        .InsertDWord LocalIP                                                  'Local IP
        .InsertDWord GetTimeZoneBias                                          'Time Zone Bias
        If (ReadCfg("Override", "ForceDefaultLocaleID") = "Y") Then
            .InsertDWord 1033                                                 'LocalID
            .InsertDWord 1033                                                 'LangID
        Else
            .InsertDWord CLng(GetUserDefaultLCID)                             'LocalID
            .InsertDWord CLng(GetUserDefaultLangID)                           'LangID
        End If
        .InsertNTString CountryAbr                                            'Country abreviation
        .InsertNTString CountryName                                           'Country Name
        .SendPacket SID_AUTH_INFO
    End With
    
    Set pBuff = Nothing
    
    If (BotVars.Spoof = 1) Then
        Call SEND_SID_PING(pBuff.GetDWORD)
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_AUTH_INFO()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_AUTH_CHECK (0x51) S->C
'*******************************
' (DWORD) Result
' (STRING) Additional Information
'*******************************
Private Sub RECV_SID_AUTH_CHECK(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    Dim lResult  As Long
    Dim sInfo    As String
    Dim bSuccess As Boolean
    
    lResult = pBuff.GetDWORD
    sInfo = pBuff.GetString
    bSuccess = False
    
    Select Case lResult
        Case &H0:
            bSuccess = True
            Call Event_VersionCheck(0, sInfo)
            
        Case &H100, &H101: Call Event_VersionCheck(1, sInfo) 'Outdated/Invalid Version
        Case &H200: Call Event_VersionCheck(2, sInfo) 'Invalid CDKey
        Case &H201: Call Event_VersionCheck(6, sInfo) 'CDKey is In Use
        Case &H202: Call Event_VersionCheck(5, sInfo) 'CDKey is Banned
        Case &H203: Call Event_VersionCheck(4, sInfo) 'CDKey is for the wrong product
        Case &H210: Call Event_VersionCheck(7, sInfo) 'Invalid Exp CDKey
        Case &H211: Call Event_VersionCheck(8, sInfo) 'Exp CDKey is In Use
        Case &H212: Call Event_VersionCheck(9, sInfo) 'Exp CDKey is Banned
        Case &H213: Call Event_VersionCheck(10, sInfo) 'Exp CDKey is for the wrong product
        Case Else:
            If (ReadCfg("Override", "Ignore0x51Reply") = "Y") Then bSuccess = True
            Call frmChat.AddChat(RTBColors.ErrorMessageText, "Unknown 0x51 Response: 0x" & ZeroOffset(lResult, 8))
    End Select

    If (frmChat.sckBNet.State = 7 And (Not ds.WaitingForEmail) And bSuccess) Then
        Call frmChat.AddChat(RTBColors.InformationText, "[BNCS] Sending login information...")
        frmChat.tmrAccountLock.Enabled = True
        
        If (ds.LogonType = 2) Then
            ds.NLS.Initialize BotVars.Username, BotVars.Password
            modBNCS.SEND_SID_AUTH_ACCOUNTLOGON
        Else
            modBNCS.SEND_SID_LOGONRESPONSE2
        End If
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_AUTH_CHECK()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_AUTH_CHECK (0x51) C->S
'*******************************
' (DWORD) Client Token
' (DWORD) EXE Version
' (DWORD) EXE Hash
' (DWORD) Number of CD-keys in this packet
' (BOOLEAN) Spawn CD-key
' For Each Key:
'   (DWORD) Key Length
'   (DWORD) CD-key's product value
'   (DWORD) CD-key's public value
'   (DWORD) Unknown (0)
'   (DWORD) [5] Hashed Key Data
' (STRING) Exe Information
' (STRING) CD-Key owner name
'*******************************
Public Sub SEND_SID_AUTH_CHECK()
On Error GoTo ERROR_HANDLER:
    
    Dim pBuff    As New clsDataBuffer
    Dim i        As Long
    Dim keys     As Long
    Dim sKey     As String
    Dim sKeyHash As String
    Dim lKeyPub  As Long
    Dim lKeyProd As Long
    
    If (Not BotVars.BNLS) Then
        If (Not CompileCheckrevision()) Then
            frmChat.DoDisconnect
            Exit Sub
        End If
    End If
        
    If (ds.CRevChecksum = 0 Or ds.CRevVersion = 0 Or LenB(ds.CRevResult) = 0) Then
        frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Check Revision Failed, sanity failed"
        frmChat.DoDisconnect
        Exit Sub
    End If
    
    keys = GetCDKeyCount
    
    With pBuff
        .InsertDWord ds.ClientToken  'Client Token
        .InsertDWord ds.CRevVersion  'CRev Version
        .InsertDWord ds.CRevChecksum 'CRev Checksum
        .InsertDWord keys            'CDKey Count
        .InsertDWord IIf(ReadCfg$("Override", "SpawnKey") = "Y", 1, 0)
        
        For i = 1 To keys
            If (i = 1) Then
                sKey = BotVars.CDKey
            ElseIf (i = 2) Then
                sKey = BotVars.ExpKey
            Else
                sKey = ReadCfg$("Main", StringFormat("CDKey{0}", i))
            End If
            
            Call DecodeCDKey(sKey, ds.ServerToken, ds.ClientToken, sKeyHash, lKeyPub, lKeyProd)
            If (LenB(sKeyHash) = 0) Then Exit Sub 'hash failed
            
            .InsertDWord Len(sKey)
            .InsertDWord lKeyProd
            .InsertDWord lKeyPub
            .InsertDWord 0
            .InsertNonNTString sKeyHash
        Next i
        
        .InsertNTString ds.CRevResult
        If (LenB(ReadCfg("Override", "OwnerName")) > 0) Then
            .InsertNTString ReadCfg("Override", "OwnerName")
        Else
            .InsertNTString BotVars.Username
        End If
        
        .SendPacket SID_AUTH_CHECK
    End With

    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_AUTH_CHECK()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**********************************
'SID_AUTH_ACCOUNTCREATE (0x52) S->C
'**********************************
' (DWORD) Status
'**********************************
Private Sub RECV_SID_AUTH_ACCOUNTCREATE(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
    Dim lResult As Long
    
    lResult = pBuff.GetDWORD
    
    Select Case lResult
        Case &H0:
            Call Event_LogonEvent(4)
            
            If frmChat.sckBNet.State = 7 Then
                Call frmChat.AddChat(RTBColors.InformationText, "[BNCS] Sending login information...")
                SEND_SID_AUTH_ACCOUNTLOGON
                Exit Sub
            End If
            
        Case &H4: frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Account creation failed because your name already exists."
        Case &H7: frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Account creation failed because your name is too short/blank."
        Case &H8: frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Account creation failed because your name contains an illegal character."
        Case &H9: frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Account creation failed because your name contains an illegal word."
        Case &HA: frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Account creation failed because your name contains too few alphanumeric characters."
        Case &HB: frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Account creation failed because your name contains adjacent punctuation characters."
        Case &HC: frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Account creation failed because your name contains too many punctuation characters."
        Case Else
            Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("Account creation failed for an unknown reason: 0x{0}", ZeroOffset(lResult, 8)))
    End Select
    
    Call frmChat.DoDisconnect
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_AUTH_ACCOUNTCREATE()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**********************************
'SID_AUTH_ACCOUNTCREATE (0x52) C->S
'**********************************
' (BYTE[32]) Salt (s)
' (BYTE[32]) Verifier (v)
' (STRING) Username
'**********************************
Private Sub SEND_SID_AUTH_ACCOUNTCREATE()
On Error GoTo ERROR_HANDLER:
    
    Dim pBuff As New clsDataBuffer
    ds.NLS.Initialize BotVars.Username, BotVars.Password
    With pBuff
        .InsertNonNTString ds.NLS.SrpSalt
        .InsertNonNTString ds.NLS.Srpv
        .InsertNTString ds.NLS.Username
        .SendPacket SID_AUTH_ACCOUNTCREATE
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_AUTH_ACCOUNTCREATE()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**********************************
'SID_AUTH_ACCOUNTLOGON (0x53) S->C
'**********************************
' (DWORD) Status
' (BYTE[32]) Salt (s)
' (BYTE[32]) Server Key (B)
'**********************************
Private Sub RECV_SID_AUTH_ACCOUNTLOGON(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
    Dim lResult As Long
    Dim s       As String
    Dim B       As String
    
    lResult = pBuff.GetDWORD
    ds.NLS.SrpSalt = pBuff.GetRaw(32)
    ds.NLS.SrpB = pBuff.GetRaw(32)
    
    Select Case lResult
        Case &H0: 'Accepted, requires proof.
            SEND_SID_AUTH_ACCOUNTLOGONPROOF
                        
        Case &H1: 'Account doesn't exist.
            Call Event_LogonEvent(0)
            Call Event_LogonEvent(3)
            Call SEND_SID_AUTH_ACCOUNTCREATE
                        
        Case &H5: 'Account requires upgrade, Not possible anymore
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNCS] Your account needs to be upgraded. This is no longer possible on Battle.net. Choose a different account."
            
        Case Else
            Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("[BNCS] Unknown response to SID_AUTH_ACCOUNTLOGON: 0x{0}", ZeroOffset(lResult, 8)))
            frmChat.DoDisconnect
    End Select
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_AUTH_ACCOUNTLOGON()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**********************************
'SID_AUTH_ACCOUNTLOGON (0x53) C->S
'**********************************
' (BYTE[32]) Client Key ('A')
' (STRING) Username
'**********************************
Private Sub SEND_SID_AUTH_ACCOUNTLOGON()
On Error GoTo ERROR_HANDLER:
    
    Dim pBuff As New clsDataBuffer
    pBuff.InsertNonNTString ds.NLS.SrpA()
    pBuff.InsertNTString ds.NLS.Username
    pBuff.SendPacket SID_AUTH_ACCOUNTLOGON
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_AUTH_ACCOUNTLOGON()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**************************************
'SID_AUTH_ACCOUNTLOGONPROOF (0x54) S->C
'**************************************
' (DWORD) Status
' (BYTE[20]) Server Password Proof (M2)
' (STRING) Additional information
'**************************************
Private Sub RECV_SID_AUTH_ACCOUNTLOGONPROOF(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:
    
    Dim lResult As Long
    Dim M2      As String
    Dim sInfo   As String
    
    lResult = pBuff.GetDWORD
    M2 = pBuff.GetRaw(20)
    sInfo = pBuff.GetString
    
    Select Case lResult
        Case &H0: 'Logon successful.
            Call Event_LogonEvent(2)
            If (Not ds.NLS.SrpVerifyM2(M2)) Then
                frmChat.AddChat RTBColors.InformationText, "[BNCS] Warning, The server sent an invalid password proof, it may be a fake server."
            End If
            SendEnterChatSequence
                   
        Case &H2: 'Invalid password
            Call Event_LogonEvent(1)
            Call frmChat.DoDisconnect
            
        Case &HE: frmEMailReg.Show 'Email registration requried
        Case &HF: 'Custom message
            Call Event_LogonEvent(5, sInfo)
            Call frmChat.DoDisconnect
                    
                        
        Case Else
            Call frmChat.AddChat(RTBColors.ErrorMessageText, StringFormat("[BNCS] Unknown response to SID_AUTH_ACCOUNTLOGONPROOF: 0x{0}", ZeroOffset(lResult, 8)))
            Call frmChat.DoDisconnect
                        
    End Select
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_AUTH_ACCOUNTLOGONPROOF()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**************************************
'SID_AUTH_ACCOUNTLOGONPROOF (0x54) C->S
'**************************************
' (BYTE[20]) Client Password Proof (M1)
'**************************************
Private Sub SEND_SID_AUTH_ACCOUNTLOGONPROOF()
On Error GoTo ERROR_HANDLER:
    
    Dim pBuff As New clsDataBuffer
    With pBuff
        .InsertNonNTString ds.NLS.SrpM1
        .SendPacket SID_AUTH_ACCOUNTLOGONPROOF
    End With
    Set pBuff = Nothing
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_AUTH_ACCOUNTLOGONPROOF()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'*******************************
'SID_SETEMAIL (0x59) S->C
'*******************************
' [Blank]
'*******************************
Private Sub RECV_SID_SETEMAIL(pBuff As clsDataBuffer)
On Error GoTo ERROR_HANDLER:

    ds.WaitingForEmail = True
    frmEMailReg.Show
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.RECV_SID_SETEMAIL()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'**************************************
'SID_SETEMAIL (0x59) C->S
'**************************************
' (STRING) Email Address
'**************************************
Public Sub SEND_SID_SETEMAIL(sEMailAddress As String)
On Error GoTo ERROR_HANDLER:
    
    Dim pBuff As New clsDataBuffer
    With pBuff
        .InsertNTString sEMailAddress
        .SendPacket SID_SETEMAIL
    End With
    Set pBuff = Nothing
    
    If LenB(sEMailAddress) > 0 Then
        frmChat.AddChat RTBColors.SuccessText, ">> E-mail address registered."
    Else
        frmChat.AddChat RTBColors.SuccessText, ">> E-mail address registration declined."
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SEND_SID_SETEMAIL()", Err.Number, Err.description, OBJECT_NAME))
End Sub

'=======================================================================================================
'This function will attempt to complete the CRev request that Bnet has sent to us.
'Returns True if successful.
Private Function CompileCheckrevision() As Boolean
On Error GoTo ERROR_HANDLER:
    Dim lVersion  As Long
    Dim lChecksum As Long
    Dim sResult   As String
    Dim sHeader   As String
    Dim sFile     As String
    
    sHeader = StringFormat("CRev_{0}", GetProductKey)
    If (Warden_CheckRevision(ds.CRevFileName, ds.CRevFileTimeRaw, ds.CRevSeed, sHeader, lVersion, lChecksum, sResult)) Then
        ds.CRevChecksum = lChecksum
        ds.CRevResult = sResult
        ds.CRevVersion = lVersion
        CompileCheckrevision = True
    Else
        Call frmChat.AddChat(RTBColors.ErrorMessageText, "[BNCS] Local Hashing Failed")
        CompileCheckrevision = False
    End If
    Exit Function
ERROR_HANDLER:
    CompileCheckrevision = False
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.CompileCheckrevision()", Err.Number, Err.description, OBJECT_NAME))
End Function

Public Function GetCDKeyCount(Optional sProduct As String = vbNullString) As Long
On Error GoTo ERROR_HANDLER:

    Dim sOverride As String
    Dim lRet      As Long

    If (LenB(sProduct) = 0) Then sProduct = BotVars.Product
    
    Select Case UCase$(sProduct)
        Case "RATS", "STAR": lRet = 1
        Case "PXES", "SEXP": lRet = 1
        Case "NB2W", "W2BN": lRet = 1
        Case "VD2D", "D2DV": lRet = 1
        Case "PX2D", "D2XP": lRet = 2
        Case "RTSJ", "JSTR": lRet = 1
        Case "3RAW", "WAR3": lRet = 1
        Case "PX3W", "W3XP": lRet = 2
        Case "LTRD", "DRTL": lRet = 0
        Case "RHSD", "DSHR": lRet = 0
        Case "RHSS", "SSHR": lRet = 0
        Case Else:           lRet = &H0
    End Select
    
    sOverride = ReadCfg$("Override", StringFormat("{0}KeyCount", GetProductKey))
    
    If (LenB(sOverride) > 0 And StrictIsNumeric(sOverride)) Then lRet = CLng(sOverride)
    
    GetCDKeyCount = lRet
    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.GetCDKeyCount()", Err.Number, Err.description, OBJECT_NAME))
End Function

Private Function GetHashFiles() As String()
On Error GoTo ERROR_HANDLER:
    Dim sFiles() As String
    Dim sPath As String
    
    ReDim sFiles(0 To 3)
    
    sPath = GetGamePath(BotVars.Product)
    
    sFiles(1) = StringFormat("{0}Storm.dll", sPath)
    sFiles(2) = StringFormat("{0}Battle.snp", sPath)
        

    Select Case (UCase$(BotVars.Product))
        Case "STAR", "RATS", "SEXP", "PXES":
            sFiles(0) = StringFormat("{0}Starcraft.exe", sPath)
            sFiles(3) = StringFormat("{0}STAR.bin", sPath)
            
        Case "W2BN", "NB2W":
            sFiles(0) = StringFormat("{0}Warcraft II BNE.exe", sPath)
            sFiles(3) = StringFormat("{0}W2BN.bin", sPath)
            
        Case "D2DV", "VD2D":
            sFiles(0) = StringFormat("{0}game.exe", sPath)
            sFiles(1) = StringFormat("{0}Bnclient.dll", sPath)
            sFiles(2) = StringFormat("{0}D2Client.dll", sPath)
            sFiles(3) = StringFormat("{0}D2DV.bin", sPath)
            
        Case "D2XP", "PX2D":
            sFiles(0) = StringFormat("{0}game.exe", sPath)
            sFiles(1) = StringFormat("{0}Bnclient.dll", sPath)
            sFiles(2) = StringFormat("{0}D2Client.dll", sPath)
            sFiles(3) = StringFormat("{0}D2XP.bin", sPath)
            
        Case "JSTR", "RTSJ":
            sFiles(0) = StringFormat("{0}StarcraftJ.exe", sPath)
            sFiles(3) = StringFormat("{0}JSTR.bin", sPath)
            
        Case "WAR3", "3RAW", "W3XP", "PX3W":
            sFiles(0) = StringFormat("{0}war3.exe", sPath)
            sFiles(2) = StringFormat("{0}Game.dll", sPath)
            sFiles(3) = StringFormat("{0}WAR3.bin", sPath)
            
        Case "DRTL", "LTRD":
            sFiles(0) = StringFormat("{0}Diablo.exe", sPath)
            sFiles(3) = StringFormat("{0}DRTL.bin", sPath)
            
        Case "DSHR", "RHSD":
            sFiles(0) = StringFormat("{0}Diablo_s.exe", sPath)
            sFiles(3) = StringFormat("{0}DSHR.bin", sPath)
            
        Case "SSHR", "RHSS":
            sFiles(0) = StringFormat("{0}Starcraft_s.exe", sPath)
            sFiles(3) = StringFormat("{0}SSHR.bin", sPath)
    End Select
    GetHashFiles = sFiles
    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.GetHashFiles()", Err.Number, Err.description, OBJECT_NAME))
End Function

Public Function GetLogonSystem(Optional sProduct As String = vbNullString) As Long
On Error GoTo ERROR_HANDLER:

    Dim sOverride As String
    Dim lRet      As Long
    
    ' Temporary short-circuit:
    '  Return BNCS_NLS because no other login sequences are supported
    '  -andy
    'GetLogonSystem = BNCS_NLS
    'Exit Function
    
    If (LenB(sProduct) = 0) Then sProduct = BotVars.Product
    
    ' Many of these login sequences are not supported
    Select Case UCase$(sProduct)
        Case "RATS", "STAR": lRet = BNCS_NLS
        Case "PXES", "SEXP": lRet = BNCS_NLS
        Case "NB2W", "W2BN": lRet = BNCS_OLS
        Case "VD2D", "D2DV": lRet = BNCS_NLS
        Case "PX2D", "D2XP": lRet = BNCS_NLS
        Case "RTSJ", "JSTR": lRet = BNCS_LLS
        Case "3RAW", "WAR3": lRet = BNCS_NLS
        Case "PX3W", "W3XP": lRet = BNCS_NLS
        Case "LTRD", "DRTL": lRet = BNCS_OLS
        Case "RHSD", "DSHR": lRet = BNCS_OLS
        Case "RHSS", "SSHR": lRet = BNCS_LLS
        Case Else:           lRet = &H0
    End Select
    
    sOverride = ReadCfg$("Override", StringFormat("{0}LogonSystem", GetProductKey))
    
    If (LenB(sOverride) > 0 And StrictIsNumeric(sOverride)) Then
        Select Case CLng(sOverride)
            Case BNCS_NLS: lRet = BNCS_NLS
            Case BNCS_LLS: lRet = BNCS_LLS
            Case BNCS_OLS: lRet = BNCS_OLS
        End Select
    End If
    
    GetLogonSystem = lRet
    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.GetLogonSystem()", Err.Number, Err.description, OBJECT_NAME))
End Function

'This will return a Long, that is Overrideable by the config, based on product ID, with a default.
'GetProdLongOverride("ProtId", 0, "DRTL") would return 0, unless the user had D1ProtID= something in there config
Private Function GetLongOverride(sKey As String, lDefault As Long) As Long
On Error GoTo ERROR_HANDLER:

    Dim sOverride As String
    Dim lRet      As Long
    
    lRet = lDefault
    
    sOverride = ReadCfg$("Override", StringFormat("{0}{1}", GetProductKey, sKey))
    
    If (LenB(sOverride) > 0 And StrictIsNumeric(sOverride)) Then lRet = CLng(sOverride)
    
    GetLongOverride = lRet
    Exit Function
ERROR_HANDLER:
    GetLongOverride = lRet
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.GetLongOverride()", Err.Number, Err.description, OBJECT_NAME))
End Function

'Same as above, except converts the override data to a dword (EXA: "68XI" to 0x49583836)
Private Function GetDWORDOverride(sKey As String, lDefault As Long) As Long
On Error GoTo ERROR_HANDLER:

    Dim sOverride As String
    Dim lRet      As Long
    
    lRet = lDefault
    
    sOverride = ReadCfg$("Override", StringFormat("{0}{1}", GetProductKey, sKey))
    
    If (LenB(sOverride) > 0) Then lRet = GetDWORD(sOverride)
    
    GetDWORDOverride = lRet
    Exit Function
ERROR_HANDLER:
    GetDWORDOverride = lRet
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.GetDWORDOverride()", Err.Number, Err.description, OBJECT_NAME))
End Function

Private Function GetDWORD(sData As String) As Long
On Error GoTo ERROR_HANDLER:
    
    sData = Left$(StringFormat("{0}{1}", sData, String$(4, Chr$(0))), 4)
    CopyMemory GetDWORD, ByVal sData, 4
    
    Exit Function
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.GetDWORD()", Err.Number, Err.description, OBJECT_NAME))
End Function

Public Sub SendEnterChatSequence()
On Error GoTo ERROR_HANDLER:
    Dim Num As Integer
    
    If ((Not BotVars.Product = "VD2D") And (Not BotVars.Product = "PX2D") And _
        (Not BotVars.Product = "PX3W") And (Not BotVars.Product = "3RAW")) Then
        
        If (Not BotVars.UseUDP) Then
            SEND_SID_UDPPINGRESPONSE
            'We dont use ICONDATA .SendPacket &H2D
        End If
    End If
    
    SEND_SID_ENTERCHAT
    SEND_SID_GETCHANNELLIST
    
    BotVars.Gateway = ReadCfg("Override", "PredefinedGateway")
    If (LenB(BotVars.Gateway) = 0) Then
        'Why were we joining a random channel?
        Randomize
        Num = (1 + Rnd() * 1000)
        FullJoin BotVars.HomeChannel & ":" & Num, 0
    Else
        'PvPGN: Straight home
        'modEvents.m_skipUICEvents = True
        
        FullJoin BotVars.HomeChannel, 5
    End If
    
    Exit Sub
ERROR_HANDLER:
    Call frmChat.AddChat(RTBColors.ErrorMessageText, _
        StringFormat("Error: #{0}: {1} in {2}.SendEnterChatSequence()", Err.Number, Err.description, OBJECT_NAME))
End Sub
