#include-once
;~ -------------------------------------------------------------------------------
;~ Name: VK_Desktop_API
;~ Author: Valan4ig
;~ NickName: ---Zak---
;~ Version: 1.4.1.1 (1.4-b1)
;~ Author URI: http://vk.com/id859000
;~ -------------------------------------------------------------------------------
;~ ===============================================================================

 #include <Array.au3>
;~ ===============================================================================
;~ Dim / Global / Local / Const
;~ ===============================================================================

 Global $oRequest = ObjCreate('WinHttp.WinHttpRequest.5.1')
 Global $aFun[0], $UToken, $hTimer, $oErrorHandler
 Global Const $API_VER = '5.53'

;~ ===============================================================================
;~ UDF functions:
;~    _vAPI_OAuth2($VKAPI_login, $VKAPI_pass, $VKAPI_ID = Default, $VKAPI_SCOPE = Default)
;~    _vAPI_GETMethod($VKAPI_METHOD, $VKAPI_PARAM = False)
;~    _vAPI_SENDRequest($fURL)
;~    _vAPI_FORMAction($tHTML, $tSTR = False)
;~    _vAPI_FORMHidden($tHTML)
;~    _vAPI_TOKENParse($tHTML)
;~    _vAPI_SCOPE($iSCOPE = Default)
;~
;~    _ARRS($tSTR, $fFun = Default)
;~    _WinHTTP_FileUpload($_File, $_URL, $_FormName)
;~
;~    _vGUI_CAPTCHA($tHTML)
;~    _vGUI_AUTHCODE()
;~
;~    __JSONDecode($sString)
;~
;~    __ErrFunc()
;~ ===============================================================================

   ;~ = _vAPI_OAuth2 =============================================================
Func _vAPI_OAuth2($VKAPI_login, $VKAPI_pass, $VKAPI_ID = Default, $VKAPI_SCOPE = Default)
 Local $DoFunc = 0

 If (($VKAPI_ID = Default) or ($VKAPI_ID = '')) Then $VKAPI_ID = 2987875
 If (($VKAPI_SCOPE = Default) or ($VKAPI_SCOPE = '')) Then $VKAPI_SCOPE = _vAPI_SCOPE() 	;~ Default = 136232095
 If ($VKAPI_SCOPE = 'offline') Then $VKAPI_SCOPE = _vAPI_SCOPE() + _vAPI_SCOPE('offline')	;~ Default + offline = 136297631

 $oAuth2 = 'https://oauth.vk.com/authorize?' & 'client_id=' & $VKAPI_ID & '&redirect_uri=https://oauth.vk.com/blank.html' & '&display=mobile' & '&scope=' & $VKAPI_SCOPE & '&response_type=token' & '&v=' & $API_VER
 $sTYPE = _vAPI_SENDRequest($oAuth2) 						;~ 	STEP # - oauth.vk.com		| Opening authorization dialogue
 Do
   If $sTYPE[0] == 'data' Then
	  Switch _vAPI_FORMAction($sTYPE[1], 'act')
		 Case 'login'										;~  STEP # - act=login			| Authorization
			 $oAuth2 = _vAPI_FORMAction($sTYPE[1])
			 $hAuth2 = _vAPI_FORMHidden($sTYPE[1])
			   If StringInStr($hAuth2, 'captcha_sid') Then 	;~  STEP # - captcha_sid		| Captcha
				$hAuth2 = $hAuth2 & '&captcha_key=' & _vGUI_CAPTCHA($hAuth2)
			   EndIf
			$sTYPE  = _vAPI_SENDRequest($oAuth2 & $hAuth2  & '&email=' & $VKAPI_login & '&pass=' & $VKAPI_pass)
		 Case 'authcheck_code'								;~  STEP # - act=grant_access	| Allowing access rights
			 $oAuth2 = _vAPI_FORMAction($sTYPE[1])
			 $oAuth2 = 'https://m.vk.com' & $oAuth2 & '&remember=1&code=' & _vGUI_AUTHCODE()
			$sTYPE = _vAPI_SENDRequest($oAuth2)
		 Case 'grant_access'								;~  STEP # - act=grant_access	| Allowing access rights
			 $oAuth2 = _vAPI_FORMAction($sTYPE[1])
			$sTYPE = _vAPI_SENDRequest($oAuth2)
	  EndSwitch
   ElseIf $sTYPE[0] == 'location' Then
	  Select
		 Case StringInStr($sTYPE[1], 'access_token')		;~ STEP # - access_token		| Getting access_token
			$UToken = _vAPI_TOKENParse($sTYPE[1])
			Return $UToken
		 Case Else											;~ STEP # - location
			$sTYPE = _vAPI_SENDRequest($sTYPE[1])
	  EndSelect
   EndIf
   Sleep(100)
   $DoFunc = $DoFunc + 1
 Until $DoFunc >= 7
EndFunc
   ;~ = _vAPI_GETMethod ==========================================================
Func _vAPI_GETMethod($VKAPI_METHOD, $VKAPI_PARAM = False)
 If Not(IsArray($UToken)) Then Exit
 Local $fTOKEN = $UToken['access_token'][1]
 $hTimer = TimerInit()

   $_QFun = 'https://api.vk.com/method/' & $VKAPI_METHOD & '?access_token=' & $fTOKEN & '&v=' & $API_VER
    If $VKAPI_PARAM Then $_QFun &= '&'&$VKAPI_PARAM
   $sTYPE = _vAPI_SENDRequest($_QFun)
    $sTYPE = StringRegExpReplace($sTYPE[1], '\[(\d+)', '["$1"')
   ReDim $aFun[2][0]
    __JSONDecode($sTYPE)

 While TimerDiff($hTimer) <= 499
   Sleep(100)
 WEnd
   Return $aFun
EndFunc
   ;~ = _vAPI_SENDRequest ========================================================
Func _vAPI_SENDRequest($fURL)
 Local $rFun[2]
 $oErrorHandler = ObjEvent('AutoIt.Error', 'ErrorFunc')
 $oRequest.Option(6) = False
   $oRequest.Open('GET', $fURL, False)
   $oRequest.Send()
   $oRequest.WaitForResponse
   If StringInStr($oRequest.getAllResponseHeaders(), 'Location:') Then
    $rFun[0] = 'location'
    $rFun[1] = $oRequest.GetResponseHeader('Location')
   Else
	$rFun[0] = 'data'
	$rFun[1] = $oRequest.ResponseText
   EndIf
 $oErrorHandler = 0
 Return $rFun
EndFunc
   ;~ = _vAPI_FORMAction =========================================================
Func _vAPI_FORMAction($tHTML, $tSTR = False)
   $tHTML = StringRegExpReplace($tHTML, '(?s).*action=[''"]?(.*?)(?:[''"\s>]).*', '$1')
   If $tSTR Then
	  $tHTML = StringRegExpReplace($tHTML, '(?s).*'&$tSTR&'=(.*?)&.*', '$1')
   EndIf
 Return $tHTML
EndFunc
   ;~ = _vAPI_FORMHidden =========================================================
Func _vAPI_FORMHidden($tHTML)
 Local $rFun
   $rFun = StringRegExp($tHTML, '.*?hidden.*?name=[''"]?(.*?)(?:[''"\s]).*?value=[''"]?(.*?)(?:[''"\s>]).*', 3)
   $tHTML = Null
   For $i = 0 To UBound($rFun) - 1 Step 2
    $tHTML = $tHTML&'&'&$rFun[$i]&'='&$rFun[$i+1]
   Next
  Return $tHTML
EndFunc
   ;~ = _vAPI_TOKENParse =========================================================
Func _vAPI_TOKENParse($tHTML)
 Local $sFun
	If StringInStr($tHTML, '#') Then
		$tHTML = StringRegExpReplace($tHTML, '.*#((?s).*)', '\1')
	EndIf
 Local $aFun = StringSplit($tHTML, '&'), $rFun[UBound($aFun)-1][2]
	For $iFun = 1 To $aFun[0]
		$sFun = StringSplit($aFun[$iFun], '=')
		$rFun[$iFun-1][0] = $sFun[1]
		$rFun[$iFun-1][1] = $sFun[2]
	Next

 Return $rFun
EndFunc
   ;~ = _vAPI_SCOPE ==============================================================
Func _vAPI_SCOPE($iSCOPE = Default)
   If IsInt($iSCOPE) Then Return $iSCOPE
   If IsArray($iSCOPE)  Then Local $aLOCAL = _ArrayUnique($iSCOPE)
   If IsString($iSCOPE) Then Local $aLOCAL[1] = [ $iSCOPE ]

   If ($iSCOPE = '') Then $iSCOPE = Default
   If ($iSCOPE = Default) Then Local $aLOCAL = ['notify', 'friends', 'photos', 'audio', 'video', 'pages', 'status', 'notes', 'messages', 'wall', 'ads', 'docs', 'groups', 'notifications', 'stats', 'market']

 Local $i = 0
 $iSCOPE = 0
   Do
    Switch $aLOCAL[$i]
	  Case 'notify'
		 $iSCOPE += 1
	  Case 'friends'
		 $iSCOPE += 2
	  Case 'photos'
		 $iSCOPE += 4
	  Case 'audio'
		 $iSCOPE += 8
	  Case 'video'
		 $iSCOPE += 16
	  Case 'pages'
		 $iSCOPE += 128
	  Case 'status'
		 $iSCOPE += 1024
	  Case 'notes'
		 $iSCOPE += 2048
	  Case 'messages'
		 $iSCOPE += 4096
	  Case 'wall'
		 $iSCOPE += 8192
	  Case 'ads'
		 $iSCOPE += 32768
	  Case 'docs'
		 $iSCOPE += 131072
	  Case 'groups'
		 $iSCOPE += 262144
	  Case 'notifications'
		 $iSCOPE += 524288
	  Case 'stats'
		 $iSCOPE += 1048576
	  Case 'market'
		 $iSCOPE += 134217728
	  Case 'offline'
		 $iSCOPE += 65536
	  Case Else
    EndSwitch
   $i = $i + 1
   Until $i = UBound($aLOCAL)
   Return $iSCOPE
EndFunc
;~ ===============================================================================

   ;~ = _ARRS ====================================================================
Func _ARRS($tSTR, $fFun = Default)
   If ($fFun = '') Then $fFun = Default
   If ($fFun = Default) Then $fFun = $aFun

   $iSearch = _ArraySearch($fFun, $tSTR, 0, 0, 0, 0, 1, 0, True)
   If @error Then
	  Return SetError(3, 10, "Element array NOT found")
   EndIf
   Return $iSearch
EndFunc
   ;~ = _WinHTTP_FileUpload ======================================================
Func _WinHTTP_FileUpload($_File, $_URL, $_FormName)

	$sFile = FileOpen($_File, 16)
	If $sFile = -1 Then
		MsgBox(0, "", "An error occurred when reading the file.")
		Return 0
	EndIf
	$sFileRead = BinaryToString(FileRead($sFile))
	FileClose($sFile)

    $sFileType = StringRegExpReplace($_File, '^.*\.', '')

    If $sFileType = 'jpg' Then $sFileType = 'jpeg'
	$sBoundary = StringFormat('----------------%s%s%smzF', @MIN, @HOUR, @SEC)
    $sData = '--' & $sBoundary & @CRLF & _
			 'Content-Disposition: form-data; name="' & $_FormName & '"; filename="' & StringRegExpReplace($_File, '^.*\\', '') & '"' & @CRLF & _
			 'Content-Type: image/' & $sFileType & @CRLF & @CRLF & _
			 $sFileRead & @CRLF & '--' & $sBoundary & '--' & @CRLF
	$iDataSize = StringLen($sData)
	$oErrorHandler = ObjEvent('AutoIt.Error', '__ErrFunc')
	 $oRequest.Option(6) = False
	 $_URL = StringRegExpReplace($_URL, '\\', '')
	 $sHOST = StringRegExpReplace($_URL, '(?s).*?http://(.*?)/.*', '$1')
	$oRequest.Open('POST', $_URL&' HTTP/1.1', False)
	 $oRequest.SetRequestHeader("Host", $sHost)
	 $oRequest.SetRequestHeader("Content-Type", 'multipart/form-data; boundary="' & $sBoundary & '"')
	 $oRequest.SetRequestHeader("Content-Length", $iDataSize)
	$oRequest.Send(StringToBinary($sData))
	$oErrorHandler = 0
	$WinHTTPFileUpload = $oRequest.ResponseText

    Return $WinHTTPFileUpload
EndFunc
;~ ===============================================================================

   ;~ = _vGUI_CAPTCHA ============================================================
Func _vGUI_CAPTCHA($tHTML)
   $tHTML = StringRegExpReplace($tHTML, '.*captcha_sid=(\d+).*', '\1')
   $tHTML = 'http://m.vk.com/captcha.php?sid=' & $tHTML & '&dif=1'
    InetGet($tHTML, @TempDir&'\captcha.jpeg')

   Local $hGUI = GUICreate('captcha', 130, 100)
   Local $idPic = GUICtrlCreatePic(@TempDir&'\captcha.jpeg', 0, 0, 130, 50)

   Local $idInp = GUICtrlCreateInput("", 5, 55, 120, 20)
   Local $idBtn = GUICtrlCreateButton("OK", 20, 75, 85, 25)
    GuiCtrlSetState(-1, 512)

   GUISetState()
   While 1
    $iMsg = GUIGetMsg()
    Select
	  Case $iMsg = -3
	   $idInp = False
	   Exit
	  Case $iMsg = $idBtn
	   $idInp = GUICtrlRead($idInp)
	   ExitLoop
    EndSelect
   WEnd

   GUIDelete($hGUI)
    If Not($idInp) Then Exit
   Return $idInp
EndFunc
   ;~ = _vGUI_AUTHCODE ===========================================================
Func _vGUI_AUTHCODE()
   Local $hGUI = GUICreate('authcheck_code', 130, 100)

   Local $idInp = GUICtrlCreateInput("", 5, 55, 120, 20)
   Local $idBtn = GUICtrlCreateButton("OK", 20, 75, 85, 25)
    GuiCtrlSetState(-1, 512)

   GUISetState()
   While 1
    $iMsg = GUIGetMsg()
    Select
	  Case $iMsg = -3
	   $idInp = False
	   Exit
	  Case $iMsg = $idBtn
	   $idInp = GUICtrlRead($idInp)
	   ExitLoop
    EndSelect
   WEnd

   GUIDelete($hGUI)
    If Not($idInp) Then Exit
   Return $idInp
EndFunc
;~ ===============================================================================

   ;~ = __JSONDecode =============================================================
Func __JSONDecode($sString)
 Local $iIndex, $aVal, $sOldStr = $sString, $b, $aNextArrayVal
    $sString = StringStripCR(StringStripWS($sString, 7))
    If Not StringRegExp($sString, "(?i)^\{.+}$") Then Return SetError(1, 0, 0)
    Local $aArray[1][2], $iIndex = 0
    $sString = StringMid($sString, 2)
    Do
        $b = False
        $aVal = StringRegExp($sString, '^"([^"]+)"\s*:\s*(["{[]|[-+]?\d+(?:(?:\.\d+)?[eE][+-]\d+)?|true|false|null)', 2) ; Get value & next token
        If @error Then
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
		    ExitLoop
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
            ConsoleWrite("!> StringRegExp Error getting next Value." & @CRLF)
            ConsoleWrite($sString & @CRLF)
            $sString = StringMid($sString, 2) ; maybe it works when the string is trimmed by 1 char from the left ?
            ContinueLoop
		 EndIf
        $aArray[$iIndex][0] = $aVal[1] ; Key
		 ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
		  $uRow = UBound($aFun)
		  $uCol = UBound($aFun,2)
		  $iSearch = _ArraySearch($aFun, $aArray[$iIndex][0], 0, 0, 0, 0, 1, 0, True)
		  If @error Then
			ReDim $aFun[$uRow][$uCol+1]
			$aFun[0][$uCol] = $aArray[$iIndex][0]
		  EndIf
		 ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
        $sString = StringMid($sString, StringLen($aVal[0]))
        Switch $aVal[2] ; Value Type (Array, Object, String) ?
            Case '"' ; String
                ; Value -> Array subscript. Trim String after that.
                $aArray[$iIndex][1] = StringMid($sString, 2, StringInStr($sString, """", 1, 2) - 2)
			    ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
				 $iSearch = _ArraySearch($aFun, $aArray[$iIndex][0], 0, 0, 0, 0, 1, 0, True)
				 If $iSearch >= 0 Then
				  $uRow = UBound($aFun)
				  $aFun[$uRow-1][$iSearch] = $aArray[$iIndex][1]
				 EndIf
			    ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
                $sString = StringMid($sString, StringLen($aArray[$iIndex][1]) + 3)
                ReDim $aArray[$iIndex + 2][2]
                $iIndex += 1
			 Case '{' ; Object
                ; Recursive function call which will decode the object and return it.
                ; Object -> Array subscript. Trim String after that.
                $aArray[$iIndex][1] = __JSONDecode($sString)
                $sString = StringMid($sString, @extended + 2)
                If StringLeft($sString, 1) = "," Then $sString = StringMid($sString, 2)
                $b = True
                ReDim $aArray[$iIndex + 2][2]
                $iIndex += 1
            Case '[' ; Array
                ; Decode Array
                $sString = StringMid($sString, 2)
                Local $aRet[1], $iArIndex = 0 ; create new array which will contain the Json-Array.
                Do
                    $sString = StringStripWS($sString, 3) ; Trim Leading & trailing spaces
                    $aNextArrayVal = StringRegExp($sString, '^\s*(["{[]|\d+(?:(?:\.\d+)?[eE]\+\d+)?|true|false|null)', 2)
                    Switch $aNextArrayVal[1]
                        Case '"' ; String
                            ; Value -> Array subscript. Trim String after that.
                            $aRet[$iArIndex] = StringMid($sString, 2, StringInStr($sString, """", 1, 2) - 2)
                            $sString = StringMid($sString, StringLen($aRet[$iArIndex]) + 3)
                        Case "{" ; Object
						    ; Recursive function call which will decode the object and return it.
                            ; Object -> Array subscript. Trim String after that.
							; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
							If $aArray[0][1] Then
						     $uRow = UBound($aFun)
							 $uCol = UBound($aFun,2)
							 ReDim $aFun[$uRow+1][$uCol]
						    EndIf
						    ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
                            $aRet[$iArIndex] = __JSONDecode($sString)
                            $sString = StringMid($sString, @extended + 2)
                        Case "["
                            MsgBox(0, "", "Array in Array. WTF is up with this JSON shit?")
                            MsgBox(0, "", "This should not happen! Please post this!")
                            Exit 0xDEADBEEF
						Case Else
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
		    ExitLoop
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
                            ConsoleWrite("Array Else (maybe buggy?)" & @CRLF)
                            $aRet[$iArIndex] = $aNextArrayVal[1]
                    EndSwitch
                    ReDim $aRet[$iArIndex + 2]
                    $iArIndex += 1
                    $sString = StringStripWS($sString, 3) ; Leading & trailing
                    If StringLeft($sString, 1) = "]" Then ExitLoop
                    $sString = StringMid($sString, 2)
                Until False
                $sString = StringMid($sString, 2)
                ReDim $aRet[$iArIndex]
                $aArray[$iIndex][1] = $aRet
                ReDim $aArray[$iIndex + 2][2]
                $iIndex += 1
            Case Else ; Number, bool
                ; Value (number (int/flaot), boolean, null) -> Array subscript. Trim String after that.
                $aArray[$iIndex][1] = $aVal[2]
				  ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
				   $iSearch = _ArraySearch($aFun, $aArray[$iIndex][0], 0, 0, 0, 0, 1, 0, True)
				   If $iSearch >= 0 Then
					 $uRow = UBound($aFun)
					 $aFun[$uRow-1][$iSearch] = $aArray[$iIndex][1]
				   EndIf
				  ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
                ReDim $aArray[$iIndex + 2][2]
                $iIndex += 1
                $sString = StringMid($sString, StringLen($aArray[$iIndex][1]) + 2)
        EndSwitch
        If StringLeft($sString, 1) = "}" Then
            StringMid($sString, 2)
            ExitLoop
        EndIf
        If Not $b Then $sString = StringMid($sString, 2)
    Until False
    ReDim $aArray[$iIndex][2]
 Return SetError(0, StringLen($sOldStr) - StringLen($sString), $aArray)
EndFunc
;~ ===============================================================================

   ;~ = __ErrFunc ================================================================
Func __ErrFunc()
    MsgBox(16, 'Error', $oErrorHandler.description)
 Exit 2
EndFunc
