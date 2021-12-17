Func __Json_Populate($data)
	Local $json = json_decode($data)
	;$json = $json[0]
	If json_isobject($json) Then
		Local $errors = json_objget($json, "errors")
		If UBound($errors) > 0 Or @error Then
			$error_count += 1
			$error_log = "Error: " & $errors & @CRLF
			Return -1
		EndIf
		Return $json
	Else
		$error_count += 1
		$error_log = StringStripCR($data) & @CRLF
		Return -1
	EndIf
EndFunc   ;==>__Json_Populate

Func __SQL_Escape($string)
	Return _SQLite_Escape($string)
EndFunc   ;==>__SQL_Escape

Func __Reset_DB(ByRef $db)
	Local $sql_query
	Local $clean = 0

	;Step 1
	$sql_query = _SQLite_Exec($db, "drop table if exists 'sessions';" & "drop table if exists 'child_handles';" & "drop table if exists 'batch_item_handles';")
	;Step 2
	If $sql_query <> $SQLITE_OK Then
		$timer = _Timer_Init()
		Do
			$timediff = _Timer_Diff($timer)
			$sql_query = _SQLite_Exec($db, "drop table if exists 'sessions';" & "drop table if exists 'session_settings';" & "drop table if exists 'child_handles';" & "drop table if exists 'batch_item_handles';")
		Until $sql_query = $SQLITE_OK Or $timediff >= 10000
	EndIf
	;Step 3
	If $sql_query <> $SQLITE_OK Then
		SetError(1)
		Return
	Else
		__Tables_Create()
		_SQLite_QuerySingleRow($db, "select * from sessions;", $query_result)
		If $query_result[0] = "" Then $clean += 1
		_SQLite_QuerySingleRow($db, "select * from child_handles;", $query_result)
		If $query_result[0] = "" Then $clean += 1
		If $clean = 2 Then
			SetError(0)
			Return
		Else
			SetError(1)
			Return
		EndIf
	EndIf
EndFunc   ;==>__Reset_DB

Func __Filter_Tracks($type, $file, ByRef $track_num)
	Local $filter_match = 0
	Local $filters_processed = 0
	Local $filter = IniReadSection($ini_file, "Filters")
	Local $data_types = IniReadSection($ini_file, "Parameters")
	Local $matched_rules = ""

	If $type = "" Or $file = "" Or Not IsArray($filter) Or Not IsArray($data_types) Or $track_num = "" Then Return 0

	For $a = 1 To UBound($filter) - 1
		If $filter[$a][1] = "And" Then ContinueLoop
		If $filter[$a][1] = "Or" Then
			If $filter_match > 0 Then
				$matched_rules = StringTrimRight($matched_rules, 1)
				Return 1 & "|" & $matched_rules
			EndIf
			$filter_match = 0
			$filters_processed = 0
			If $filter_match = 0 Then
				ContinueLoop
			EndIf
		EndIf
		Local $filter_line = StringSplit($filter[$a][1], "|")
		If $type = "Text" Then $type = "Subtitles"
		If $type <> $filter_line[1] Then
			Local $grouper = _ArraySearch($filter, "Or", $a, Default, Default, 1)
			If $grouper = -1 Then Return 0
			$filter_match = 0
			$filters_processed = 0
			$a = $grouper
			ContinueLoop
		EndIf
		Local $info_type = _ArraySearch($data_types, $filter_line[2], Default, Default, Default, 1)
		If $info_type = -1 Then Return 0
		Local $data = __Get_MediaInfo($file, $media_info_handle, $data_types[$info_type][1], $track_num - 1, $type)
		If $data = "" Then $data = "null"
		Switch $filter_line[3]
			Case "Is"
				If $data = $filter_line[4] Then
					$filter_match += 1
					$matched_rules &= $a & ","
				EndIf
				$filters_processed += 1
				ContinueLoop
			Case "Is Not"
				If $data <> $filter_line[4] Then
					$filter_match += 1
					$matched_rules &= $a & ","
				EndIf
				$filters_processed += 1
				ContinueLoop
			Case "Contains"
				If StringInStr($data, $filter_line[4]) <> 0 Then
					$filter_match += 1
					$matched_rules &= $a & ","
				EndIf
				$filters_processed += 1
				ContinueLoop
			Case "Does Not Contain"
				If StringInStr($data, $filter_line[4]) = 0 Then
					$filter_match += 1
					$matched_rules &= $a & ","
				EndIf
				$filters_processed += 1
				ContinueLoop
			Case "Greater Than"
				If $data > $filter_line[4] Then
					$filter_match += 1
					$matched_rules &= $a & ","
				EndIf
				$filters_processed += 1
				ContinueLoop
			Case "Less Than"
				If $data < $filter_line[4] Then
					$filter_match += 1
					$matched_rules &= $a & ","
				EndIf
				$filters_processed += 1
				ContinueLoop
			Case "RegEx"
				If StringRegExp($data, $filter_line[4]) = 1 Then
					$filter_match += 1
					$matched_rules &= $a & ","
				EndIf
				$filters_processed += 1
				ContinueLoop
		EndSwitch
	Next
	$matched_rules = StringTrimRight($matched_rules, 1)
	If $filters_processed = $filter_match Then
		Return 1 & "|" & $matched_rules
	Else
		Return 0
	EndIf
EndFunc   ;==>__Filter_Tracks

Func __Execute()
	$execute = Run(@ComSpec & ' /c mkvextract --gui-mode @"' & $working_dir & '\mkv_cmd1.json"', $mkvtlnix_path, @SW_HIDE, $STDERR_MERGED)
	Return $execute
EndFunc   ;==>__Execute

Func __Custom_FileName_Format(ByRef $fn_custom_formula)
	Local $string
	Local $extract_string
	Local $skip = 0
	Local $str_length
	Local $b


	Do
		$string = StringInStr($fn_custom_formula, "[Track#]")
		$str_length = StringLen("Track#]")
		If $string <> 0 Then
			If StringMid($fn_custom_formula, $string - 1, 1) = ">" Then
				$a = 0
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string - $a, 1) = "]" Or StringMid($fn_custom_formula, $string - $a, 1) = "" Or StringMid($fn_custom_formula, $string - $a, 1) = "*"
				$extract_string = StringMid($fn_custom_formula, ($string - $a) + 1, $a + $str_length)
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If StringMid($fn_custom_formula, $string + $str_length + 1, 1) = "<" And $skip = 0 Then
				$a = $str_length
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string + $a, 1) = "[" Or StringMid($fn_custom_formula, $string + $a, 1) = "" Or StringMid($fn_custom_formula, $string + $a, 1) = "*"
				If StringMid($fn_custom_formula, $string + $a, 1) = "" Then
					$b = 0
					Do
						$b += 1
					Until StringMid($fn_custom_formula, $string - $b, 1) = "<"
					$extract_string = StringMid($fn_custom_formula, $string - $b, $b + $a)
				Else
					$extract_string = StringMid($fn_custom_formula, $string, $a)
				EndIf
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf
			If $skip = 0 Then $fn_custom_formula = StringReplace($fn_custom_formula, "[Track#]", "")
		EndIf
	Until $string = 0

	$skip = 0
	Do
		$string = StringInStr($fn_custom_formula, "[TrackType#]")
		$str_length = StringLen("TrackType#]")
		If $string <> 0 Then
			If StringMid($fn_custom_formula, $string - 1, 1) = ">" Then
				$a = 0
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string - $a, 1) = "]" Or StringMid($fn_custom_formula, $string - $a, 1) = "" Or StringMid($fn_custom_formula, $string - $a, 1) = "*"
				$extract_string = StringMid($fn_custom_formula, ($string - $a) + 1, $a + $str_length)
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If StringMid($fn_custom_formula, $string + $str_length + 1, 1) = "<" And $skip = 0 Then
				$a = $str_length
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string + $a, 1) = "[" Or StringMid($fn_custom_formula, $string + $a, 1) = "" Or StringMid($fn_custom_formula, $string + $a, 1) = "*"
				If StringMid($fn_custom_formula, $string + $a, 1) = "" Then
					$b = 0
					Do
						$b += 1
					Until StringMid($fn_custom_formula, $string - $b, 1) = "<"
					$extract_string = StringMid($fn_custom_formula, $string - $b, $b + $a)
				Else
					$extract_string = StringMid($fn_custom_formula, $string, $a)
				EndIf
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If $skip = 0 Then $fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType#]", "")
		EndIf
	Until $string = 0

	$skip = 0
	Do
		$string = StringInStr($fn_custom_formula, "[TrackType]")
		$str_length = StringLen("TrackType]")
		If $string <> 0 Then
			If StringMid($fn_custom_formula, $string - 1, 1) = ">" Then
				$a = 0
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string - $a, 1) = "]" Or StringMid($fn_custom_formula, $string - $a, 1) = "" Or StringMid($fn_custom_formula, $string - $a, 1) = "*"
				$extract_string = StringMid($fn_custom_formula, ($string - $a) + 1, $a + $str_length)
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If StringMid($fn_custom_formula, $string + $str_length + 1, 1) = "<" And $skip = 0 Then
				$a = $str_length
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string + $a, 1) = "[" Or StringMid($fn_custom_formula, $string + $a, 1) = "" Or StringMid($fn_custom_formula, $string + $a, 1) = "*"
				If StringMid($fn_custom_formula, $string + $a, 1) = "" Then
					$b = 0
					Do
						$b += 1
					Until StringMid($fn_custom_formula, $string - $b, 1) = "<"
					$extract_string = StringMid($fn_custom_formula, $string - $b, $b + $a)
				Else
					$extract_string = StringMid($fn_custom_formula, $string, $a)
				EndIf
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If $skip = 0 Then $fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "")
		EndIf
	Until $string = 0

	$skip = 0

	Do
		Select
			Case StringInStr($fn_custom_formula, "[LNGf]")
				$string = StringInStr($fn_custom_formula, "[LNGf]")
				$str_length = StringLen("LNGf]")
			Case StringInStr($fn_custom_formula, "[LNG3]")
				$string = StringInStr($fn_custom_formula, "[LNG3]")
				$str_length = StringLen("LNG3]")
			Case StringInStr($fn_custom_formula, "[LNG]")
				$string = StringInStr($fn_custom_formula, "[LNG]")
				$str_length = StringLen("LNG]")
			Case Else
				$string = 0
		EndSelect
		If $string <> 0 Then
			If StringMid($fn_custom_formula, $string - 1, 1) = ">" Then
				$a = 0
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string - $a, 1) = "]" Or StringMid($fn_custom_formula, $string - $a, 1) = "" Or StringMid($fn_custom_formula, $string - $a, 1) = "*"
				$extract_string = StringMid($fn_custom_formula, ($string - $a) + 1, $a + $str_length)
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If StringMid($fn_custom_formula, $string + $str_length + 1, 1) = "<" And $skip = 0 Then
				$a = $str_length
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string + $a, 1) = "[" Or StringMid($fn_custom_formula, $string + $a, 1) = "" Or StringMid($fn_custom_formula, $string + $a, 1) = "*"
				If StringMid($fn_custom_formula, $string + $a, 1) = "" Then
					$b = 0
					Do
						$b += 1
					Until StringMid($fn_custom_formula, $string - $b, 1) = "<"
					$extract_string = StringMid($fn_custom_formula, $string - $b, $b + $a)
				Else
					$extract_string = StringMid($fn_custom_formula, $string, $a)
				EndIf
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf
			If $skip = 0 Then
				$fn_custom_formula = StringReplace($fn_custom_formula, "[LNG]", "")
				$fn_custom_formula = StringReplace($fn_custom_formula, "[LNG3]", "")
				$fn_custom_formula = StringReplace($fn_custom_formula, "[LNGf]", "")
			EndIf
		EndIf
	Until $string = 0

	$skip = 0

	Do
		$string = StringInStr($fn_custom_formula, "[Delay]")
		$str_length = StringLen("Delay]")
		If $string <> 0 Then
			If StringMid($fn_custom_formula, $string - 1, 1) = ">" Then
				$a = 0
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string - $a, 1) = "]" Or StringMid($fn_custom_formula, $string - $a, 1) = "" Or StringMid($fn_custom_formula, $string - $a, 1) = "*"
				$extract_string = StringMid($fn_custom_formula, ($string - $a) + 1, $a + $str_length)
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If StringMid($fn_custom_formula, $string + $str_length + 1, 1) = "<" And $skip = 0 Then
				$a = $str_length
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string + $a, 1) = "[" Or StringMid($fn_custom_formula, $string + $a, 1) = "" Or StringMid($fn_custom_formula, $string + $a, 1) = "*"
				If StringMid($fn_custom_formula, $string + $a, 1) = "" Then
					$b = 0
					Do
						$b += 1
					Until StringMid($fn_custom_formula, $string - $b, 1) = "<"
					$extract_string = StringMid($fn_custom_formula, $string - $b, $b + $a)
				Else
					$extract_string = StringMid($fn_custom_formula, $string, $a)
				EndIf
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If $skip = 0 Then $fn_custom_formula = StringReplace($fn_custom_formula, "[Delay]", "")
		EndIf
	Until $string = 0

	$skip = 0

	Do
		$string = StringInStr($fn_custom_formula, "[aDelay]")
		$str_length = StringLen("aDelay]")
		If $string <> 0 Then
			If StringMid($fn_custom_formula, $string - 1, 1) = ">" Then
				$a = 0
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string - $a, 1) = "]" Or StringMid($fn_custom_formula, $string - $a, 1) = "" Or StringMid($fn_custom_formula, $string - $a, 1) = "*"
				$extract_string = StringMid($fn_custom_formula, ($string - $a) + 1, $a + $str_length)
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If StringMid($fn_custom_formula, $string + $str_length + 1, 1) = "<" And $skip = 0 Then
				$a = $str_length
				Do
					$a += 1
				Until StringMid($fn_custom_formula, $string + $a, 1) = "[" Or StringMid($fn_custom_formula, $string + $a, 1) = "" Or StringMid($fn_custom_formula, $string + $a, 1) = "*"
				If StringMid($fn_custom_formula, $string + $a, 1) = "" Then
					$b = 0
					Do
						$b += 1
					Until StringMid($fn_custom_formula, $string - $b, 1) = "<"
					$extract_string = StringMid($fn_custom_formula, $string - $b, $b + $a)
				Else
					$extract_string = StringMid($fn_custom_formula, $string, $a)
				EndIf
				$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
				$skip += 1
			EndIf

			If $skip = 0 Then $fn_custom_formula = StringReplace($fn_custom_formula, "[aDelay]", "")
		EndIf
	Until $string = 0

	Local $placeholders = IniReadSection($ini_file, "Placeholders")
	If Not @error Then
		For $x = 1 To $placeholders[0][0]
			$skip = 0
			Local $placeholder_string = StringSplit($placeholders[$x][1], "|")
			Do
				$string = StringInStr($fn_custom_formula, $placeholder_string[1])
				$str_length = StringLen(StringMid($placeholder_string[1], 2, -1))
				If $string <> 0 Then
					If StringMid($fn_custom_formula, $string - 1, 1) = ">" Then
						$a = 0
						Do
							$a += 1
						Until StringMid($fn_custom_formula, $string - $a, 1) = "]" Or StringMid($fn_custom_formula, $string - $a, 1) = "" Or StringMid($fn_custom_formula, $string - $a, 1) = "*"
						$extract_string = StringMid($fn_custom_formula, ($string - $a) + 1, $a + $str_length)
						$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
						$skip += 1
					EndIf

					If StringMid($fn_custom_formula, $string + $str_length + 1, 1) = "<" And $skip = 0 Then
						$a = $str_length
						Do
							$a += 1
						Until StringMid($fn_custom_formula, $string + $a, 1) = "[" Or StringMid($fn_custom_formula, $string + $a, 1) = "" Or StringMid($fn_custom_formula, $string + $a, 1) = "*"
						If StringMid($fn_custom_formula, $string + $a, 1) = "" Then
							$b = 0
							Do
								$b += 1
							Until StringMid($fn_custom_formula, $string - $b, 1) = "<" Or StringMid($fn_custom_formula, $string - $b, 1) = "]" Or StringMid($fn_custom_formula, $string - $b, 1) = "*"
							If StringMid($fn_custom_formula, $string - $b, 1) = "]" Then
								$extract_string = StringMid($fn_custom_formula, $string - ($b - 1), $b + $a)
							Else
								$extract_string = StringMid($fn_custom_formula, $string - $b, $b + $a)
							EndIf
						Else
							$extract_string = StringMid($fn_custom_formula, $string, $a)
						EndIf
						$fn_custom_formula = StringReplace($fn_custom_formula, $extract_string, "")
						$skip += 1
					EndIf

					If $skip = 0 Then $fn_custom_formula = StringReplace($fn_custom_formula, $placeholder_string[1], "")
				EndIf
			Until $string = 0
		Next
	EndIf
	$fn_custom_formula = StringReplace($fn_custom_formula, ">", "")
	$fn_custom_formula = StringReplace($fn_custom_formula, "<", "")
	$fn_custom_formula = StringReplace($fn_custom_formula, "*", "")
EndFunc   ;==>__Custom_FileName_Format


Func __Set_Progress()
	_ITaskBar_SetProgressState($GUI, 2)
	If IsArray($curr_percent) Then
		_ITaskBar_SetProgressValue($GUI, Int((100 / ($file_total * $multiplyer)) * ($curr_percent[0] / 100) + (100 / ($file_total * $multiplyer)) * ($call - 1)), 100)
	Else
		_ITaskBar_SetProgressValue($GUI, Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)), 100)
	EndIf
EndFunc   ;==>__Set_Progress

Func __Pos_Convert($number)
	If StringInStr($number, "-") Then
		Return 0
	Else
		Return $number
	EndIf
EndFunc   ;==>__Pos_Convert

Func __Stb_Resize($hWnd, $iMsg, $iwParam, $ilParam)
	_GUICtrlStatusBar_Resize($statusbar)
	Return $GUI_RUNDEFMSG
EndFunc   ;==>__Stb_Resize

Func __WM_VSCROLL($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam
	Local $iScrollCode = BitAND($wParam, 0x0000FFFF)
	Local $iIndex = -1, $iCharY, $iPosY
	Local $iMin, $iMax, $iPage, $iPos, $iTrackPos

	For $x = 0 To UBound($__g_aSB_WindowInfo) - 1
		If $__g_aSB_WindowInfo[$x][0] = $hWnd Then
			$iIndex = $x
			$iCharY = $__g_aSB_WindowInfo[$iIndex][3]
			ExitLoop
		EndIf
	Next
	If $iIndex = -1 Then Return 0

	; Get all the vertial scroll bar information
	Local $tSCROLLINFO = _GUIScrollBars_GetScrollInfoEx($hWnd, $SB_VERT)
	$iMin = DllStructGetData($tSCROLLINFO, "nMin")
	$iMax = DllStructGetData($tSCROLLINFO, "nMax")
	$iPage = DllStructGetData($tSCROLLINFO, "nPage")
	; Save the position for comparison later on
	$iPosY = DllStructGetData($tSCROLLINFO, "nPos")
	$iPos = $iPosY
	$iTrackPos = DllStructGetData($tSCROLLINFO, "nTrackPos")

	Switch $iScrollCode
		Case $SB_TOP ; user clicked the HOME keyboard key
			DllStructSetData($tSCROLLINFO, "nPos", $iMin)

		Case $SB_BOTTOM ; user clicked the END keyboard key
			DllStructSetData($tSCROLLINFO, "nPos", $iMax)

		Case $SB_LINEUP ; user clicked the top arrow
			DllStructSetData($tSCROLLINFO, "nPos", $iPos - 1)

		Case $SB_LINEDOWN ; user clicked the bottom arrow
			DllStructSetData($tSCROLLINFO, "nPos", $iPos + 1)

		Case $SB_PAGEUP ; user clicked the scroll bar shaft above the scroll box
			DllStructSetData($tSCROLLINFO, "nPos", $iPos - $iPage)

		Case $SB_PAGEDOWN ; user clicked the scroll bar shaft below the scroll box
			DllStructSetData($tSCROLLINFO, "nPos", $iPos + $iPage)

		Case $SB_THUMBTRACK ; user dragged the scroll box
			DllStructSetData($tSCROLLINFO, "nPos", $iTrackPos)
	EndSwitch

	; // Set the position and then retrieve it.  Due to adjustments
	; //   by Windows it may not be the same as the value set.

	DllStructSetData($tSCROLLINFO, "fMask", $SIF_POS)
	_GUIScrollBars_SetScrollInfo($hWnd, $SB_VERT, $tSCROLLINFO)
	_GUIScrollBars_GetScrollInfo($hWnd, $SB_VERT, $tSCROLLINFO)
	;// If the position has changed, scroll the window and update it
	$iPos = DllStructGetData($tSCROLLINFO, "nPos")

	If ($iPos <> $iPosY) Then
		_GUIScrollBars_ScrollWindow($hWnd, 0, $iCharY * ($iPosY - $iPos))
		$iPosY = $iPos
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>__WM_VSCROLL

Func __WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam
	Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $hWndListView, $tInfo
	$hWndListView = $codec_list_handle
	If Not IsHWnd($codec_list_handle) Then $hWndListView = GUICtrlGetHandle($codec_list_handle)

	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $hWndListView
			Switch $iCode
				Case $LVN_ENDLABELEDITA, $LVN_ENDLABELEDITW ; The end of label editing for an item
					$tInfo = DllStructCreate($tagNMLVDISPINFO, $ilParam)
					Local $tBuffer = DllStructCreate("char Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
					If StringLen(DllStructGetData($tBuffer, "Text")) Then Return True
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>__WM_NOTIFY

Func __WM_DROPFILES($hWnd, $msgID, $wParam, $lParam)
	Local $nSize, $pFileName
	Local $nAmt = DllCall("shell32.dll", "int", "DragQueryFileW", "hwnd", $wParam, "uint", 0xFFFFFFFF, "ptr", 0, "uint", 255)
	$aDroppedFiles = 0
	Dim $aDroppedFiles[$nAmt[0] + 1]
	For $i = 0 To $nAmt[0] - 1
		$nSize = DllCall("shell32.dll", "int", "DragQueryFileW", "hwnd", $wParam, "uint", $i, "ptr", 0, "uint", 0)
		$nSize = $nSize[0] + 1
		$pFileName = DllStructCreate("wchar[" & $nSize & "]")
		DllCall("shell32.dll", "int", "DragQueryFileW", "hwnd", $wParam, "uint", $i, "ptr", DllStructGetPtr($pFileName), "uint", $nSize)
		$aDroppedFiles[0] += 1
		$aDroppedFiles[$aDroppedFiles[0]] = DllStructGetData($pFileName, 1)
		$pFileName = 0
	Next
	ReDim $aDroppedFiles[$aDroppedFiles[0] + 1]
EndFunc   ;==>__WM_DROPFILES

Func __Statusbar_Update($execute)
	Local $process
	Local $error_bit

	If _WinAPI_GetVersion() >= 6.0 Then
		$process = _WinAPI_OpenProcess($PROCESS_QUERY_LIMITED_INFORMATION, 0, $execute)
	Else
		$process = _WinAPI_OpenProcess($PROCESS_QUERY_INFORMATION, 0, $execute)
	EndIf

	Do
		If $redirect_output = 1 Then
			Do
				;nothing
			Until Not ProcessExists($execute)
			$std = FileRead(StringReplace($out_file, "\\", "\"))
			$redirect_output = 0
			SetError(1, 0, 0)
		Else
			$std = StdoutRead($execute)
		EndIf
		If @error Then $std_error = 1
		If $std <> "" Then
			$std_split = StringSplit($std, @CRLF)
			$clean = _ArrayFindAll($std_split, "")
			_ArrayInsert($clean, 0, UBound($clean))
			_ArrayDelete($std_split, $clean)
			$curr_percent = _StringBetween(StringStripCR($std_split[UBound($std_split) - 1]), "#GUI#progress ", "%")
			If Not @error And IsArray($curr_percent) Then
				_GUICtrlStatusBar_SetText($statusbar, "Progress: " & $curr_percent[0] & "%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) * ($curr_percent[0] / 100) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				GUICtrlSetData($progress1, $curr_percent[0])
				GUICtrlSetData($progress2, Int((100 / ($file_total * $multiplyer)) * ($curr_percent[0] / 100) + (100 / ($file_total * $multiplyer)) * ($call - 1)))
				__Set_Progress()
			EndIf
			$find_error = _ArraySearch($std_split, "#GUI#error ", 1, 0, 0, 1)
			If $find_error = -1 Then $find_error = _ArraySearch($std_split, "Error: ", 1, 0, 0, 1)
			If $find_error <> -1 Then
				$error_count += 1
				$error_log &= $std_split[$find_error] & @CRLF
				__Log_Write("(error)", 3, $session)
				$error_bit = 1
			EndIf
			$find_warning = _ArraySearch($std_split, "#GUI#warning ", 1, 0, 0, 1)
			If $find_warning = -1 Then $find_error = _ArraySearch($std_split, "Warning: ", 1, 0, 0, 1)
			If $find_warning <> -1 Then
				$warning_count += 1
				$warning_log &= $std_split[$find_warning] & @CRLF
				__Log_Write("(warning)", 3, $session)
			EndIf
		EndIf
		If GUIGetMsg() = $go Then
			Do
				ProcessClose($execute)
			Until Not ProcessExists($execute)
			Do
				Sleep(50)
				$process_list = ProcessList()
				$index = _ArraySearch($process_list, "mkvextract", 1, 0, 0, 1, 1, 0)
				ProcessClose($process_list[__Pos_Convert($index)][1])
			Until $index = -1
			$index = _ArraySearch($process_list, "avc2avi", 1, 0, 0, 1, 1, 0)
			If $index <> -1 Then ProcessClose($process_list[$index][1])
			$index = _ArraySearch($process_list, "tc2cfr", 1, 0, 0, 1, 1, 0)
			If $index <> -1 Then ProcessClose($process_list[$index][1])
			$std = ""
			_GUICtrlStatusBar_SetText($statusbar, "Extraction was cancelled by the user.")
			$cancel = 1
			Return 0
		EndIf
	Until $std_error = 1
	Local $exit_code = _WinAPI_GetExitCodeProcess($process)
	$std_error = 0
	$std = ""
	StdioClose($execute)
	Select
		Case $exit_code = 0
			__Log_Write("(ok)", 3, $session)
			Return SetError(0, 0, 1)
		Case Else
			If $error_bit = 0 Then
				For $a = 1 To UBound($std_split) - 1
					$error_log &= $std_split[$a] & @CRLF
				Next
			EndIf
			Return SetError(1, $exit_code, 1)
	EndSelect
EndFunc   ;==>__Statusbar_Update


Func __CheckVFR($file_to_check, ByRef $vfr_mode)
	$vfr = 0
	Local $timecodes_raw
	Local $duration = 0
	Local $prev_frame_time
	Local $total_frame_time = ""
	Local $frame_rate
	Local $adjust = 0
	Local $nMsg
	Local $process_close = 0

	If $vfr_detect = 0 Then Return
	_SQLite_QuerySingleRow($db, "select selected from batch_item_handles where text='Timecodes';", $query_result)
	$sbText = _GUICtrlStatusBar_GetText($statusbar, 0)
	_GUICtrlStatusBar_SetText($statusbar, "Getting Framerate mode... (This might take a while, depending on the file size).")
	Switch $vfr_mode
		Case "Quick"
			$vfr = __Get_MediaInfo($full_path, $media_info_handle, "FrameRate_Mode", $track_num - 1, 1)
			If $vfr = "VFR" Then $vfr = 1
			If $vfr = "" Then
				__Log_Write("(n/a)", 3, $session)
				Return
			EndIf
			If $vfr = 1 Then
				$command_file = FileOpen($working_dir & "\mkv_cmd2.json", 266)
				FileWrite($command_file, "[" & @CRLF & '"timecodes_v2",' & @CRLF & '"' & StringReplace($full_path, "\", "\\") & '",' & @CRLF & '"' & StringReplace($file_to_check, "\", "\\") & '_Timecodes.txt"' & @CRLF & "]")
				FileClose($command_file)
				$file_to_check = StringMid($file_to_check, StringInStr($file_to_check, ":", 0, 1) + 1, StringLen($file_to_check) - StringInStr($file_to_check, ":", 0, 1)) & '_Timecodes.txt'
				RunWait($mkvtlnix_path & '\mkvextract.exe @' & $working_dir & '\mkv_cmd2.json', $mkvtlnix_path, @SW_HIDE)
				$timecodes_raw = FileReadToArray($file_to_check)
			EndIf
		Case "Full"
			$command_file = FileOpen($working_dir & "\mkv_cmd2.json", 266)
			FileWrite($command_file, "[" & @CRLF & '"timecodes_v2",' & @CRLF & '"' & StringReplace($full_path, "\", "\\") & '",' & @CRLF & '"' & StringReplace($file_to_check, "\", "\\") & '_Timecodes.txt"' & @CRLF & "]")
			FileClose($command_file)
			$file_to_check = StringMid($file_to_check, StringInStr($file_to_check, ":", 0, 1) + 1, StringLen($file_to_check) - StringInStr($file_to_check, ":", 0, 1)) & '_Timecodes.txt'
			$execute = Run($mkvtlnix_path & '\mkvextract.exe @' & $working_dir & '\mkv_cmd2.json', $mkvtlnix_path, @SW_HIDE)
			While ProcessExists($execute)
				$nMsg = GUIGetMsg()
				Switch $nMsg
					Case $go
						ProcessClose($execute)
						$process_close = 1
						$cancel = 1
						_GUICtrlStatusBar_SetText($statusbar, "Extraction was cancelled by the user.")
						ExitLoop
				EndSwitch
			WEnd
			If $process_close = 0 Then $timecodes_raw = FileReadToArray($file_to_check)
			If IsArray($timecodes_raw) Then
				$timecodes_raw[0] = "# timecode format v2"
			Else
				__Log_Write("(n/a)", 3, $session)
				Return
			EndIf
			$frame_rate = Round($timecodes_raw[UBound($timecodes_raw) - 1]) / (UBound($timecodes_raw) - 2)
			$frame_rate = 1000 / $frame_rate

			For $z = 1 To UBound($timecodes_raw) - (Round($frame_rate) + 2) Step Round($frame_rate)
				$total_frame_time = $timecodes_raw[$z + Round($frame_rate)] - $timecodes_raw[$z]
				If (($total_frame_time - $prev_frame_time) / $total_frame_time) * 100 >= 0.3 And $z > 1 Then
					$vfr += 1
				EndIf
				$prev_frame_time = $total_frame_time
			Next
	EndSwitch

	If GUICtrlRead($vfrtocfr) = $GUI_CHECKED And $vfr > 0 Then
		For $z = 2 To UBound($timecodes_raw) - 1
			$msecs = $timecodes_raw[$z] - $timecodes_raw[$z - 1]
			If $msecs < 1 Then
				Local $adjust = 1
				$msecs = 43
			EndIf
			$frame_rate = Round(1000 / $msecs)
			Local $nrst_int, $orig_fps = $frame_rate
			If $frame_rate <> 24 And $frame_rate <> 30 And $frame_rate <> 60 Then
				Do
					$nrst_int = 120 / $frame_rate
					$frame_rate += 1
				Until IsInt(Number($nrst_int)) Or $frame_rate > 120
				Local $fps_up = $frame_rate - 1
				$frame_rate = $orig_fps

				Do
					$nrst_int = 120 / $frame_rate
					$frame_rate -= 1
				Until IsInt(Number($nrst_int)) Or $frame_rate < 2
				Local $fps_down = $frame_rate + 1
				$frame_rate = $orig_fps

				Local $up_count = $fps_up - $orig_fps
				Local $down_count = $orig_fps - $fps_down

				Select
					Case $down_count < $up_count
						$msecs = 1000 / ($fps_down * 1000 / 1001)
					Case $up_count < $down_count
						$msecs = 1000 / ($fps_up * 1000 / 1001)
					Case $up_count = $down_count
						$msecs = 1000 / ($fps_down * 1000 / 1001)
				EndSelect
				$frame_rate = "change"
			EndIf

			If $frame_rate = "change" Then
				$timecodes_raw[$z] = $timecodes_raw[$z - 1] + Round($msecs)
			EndIf
		Next
		FileCopy($file_to_check, StringTrimRight($file_to_check, 4) & "_cfr.txt")
		_FileWriteFromArray(StringTrimRight($file_to_check, 4) & "_cfr.txt", $timecodes_raw, Default, UBound($timecodes_raw) - 2)
	EndIf

	Select
		Case $adjust = 1
			__Log_Write("(possible vfr with broken timecodes)", 3, $session)
		Case $vfr > 0
			__Log_Write("(vfr)", 3, $session)
		Case $vfr = 0
			__Log_Write("(cfr)", 3, $session)
			If $query_result[0] <> "True" Then
				Local $delete = FileDelete($file_to_check)
			EndIf
	EndSelect
	$std = ""
	Dim $timecodes_raw[1]
EndFunc   ;==>__CheckVFR

Func __TrackCount_Update()
	Local $hWnd = ""
	Local $ControlID = ""

	_SQLite_QuerySingleRow($db, "select count(rowid) from sessions;", $query)
	If $query[0] < 1 Then Return
	;need a temp table with the old entries to copy selected items later on
	If $session_recover = 1 Then _SQLite_Exec($db, "drop table if exists 'temp';" & "create table if not exists 'temp' as select * from 'batch_item_handles';")

	Local $test = _SQLite_Exec($db, "drop table if exists batch_item_handles;" & _
			"create table if not exists 'batch_item_handles' ('handle' blob, 'item_handle' blob, 'selected' blob, 'text' varchar);")
	_GUICtrlTreeView_BeginUpdate($tracklist)
	_GUICtrlTreeView_DeleteAll($tracklist)
	_SQLite_QuerySingleRow($db, "select max_video from sessions where max_video !='' and max_video notnull order by max_video desc limit 1;", $query)
	For $a = 1 To $query[0]
		$ControlID = GUICtrlCreateTreeViewItem("Video Track " & $a, $tracklist)
		$hWnd = GUICtrlGetHandle($ControlID)
		_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Video Track " & $a & "','" & $ControlID & "');")
	Next
	_SQLite_QuerySingleRow($db, "select max_audio from sessions where max_audio != '' and max_audio notnull order by max_audio desc limit 1;", $query)
	For $a = 1 To $query[0]
		$ControlID = GUICtrlCreateTreeViewItem("Audio Track " & $a, $tracklist)
		$hWnd = GUICtrlGetHandle($ControlID)
		_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Audio Track " & $a & "','" & $ControlID & "');")
	Next
	_SQLite_QuerySingleRow($db, "select max_subs from sessions where max_subs != '' and max_subs notnull order by max_subs desc limit 1;", $query)
	For $a = 1 To $query[0]
		$ControlID = GUICtrlCreateTreeViewItem("Subtitle Track " & $a, $tracklist)
		$hWnd = GUICtrlGetHandle($ControlID)
		_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Subtitle Track " & $a & "','" & $ControlID & "');")
	Next
	$ControlID = GUICtrlCreateTreeViewItem("Attachments", $tracklist)
	$hWnd = GUICtrlGetHandle($ControlID)
	_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Attachments','" & $ControlID & "');")
	$ControlID = GUICtrlCreateTreeViewItem("Timecodes", $tracklist)
	$hWnd = GUICtrlGetHandle($ControlID)
	If $no_execute = 1 Then
		GUICtrlSetColor($ControlID, 0xff0000)
	EndIf
	$timecodes = $ControlID
	_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Timecodes','" & $ControlID & "');")
	$ControlID = GUICtrlCreateTreeViewItem("Cuesheets", $tracklist)
	$hWnd = GUICtrlGetHandle($ControlID)
	_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Cuesheets','" & $ControlID & "');")
	$ControlID = GUICtrlCreateTreeViewItem("Chapters", $tracklist)
	$hWnd = GUICtrlGetHandle($ControlID)
	_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Chapters','" & $ControlID & "');")
	$ControlID = GUICtrlCreateTreeViewItem("Tags", $tracklist)
	$hWnd = GUICtrlGetHandle($ControlID)
	_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Tags','" & $ControlID & "');")
	$ControlID = GUICtrlCreateTreeViewItem("Segment UIDs", $tracklist)
	$hWnd = GUICtrlGetHandle($ControlID)
	_SQLite_Exec($db, "insert into batch_item_handles ('handle','text','item_handle') values ('" & $hWnd & "','Segments','" & $ControlID & "');")
	_GUICtrlTreeView_EndUpdate($tracklist)
	If $session_recover = 0 Then _GUICtrlStatusBar_SetText($statusbar, "")
	$check_selected = 1
EndFunc   ;==>__TrackCount_Update

Func __SaveFile_Make($itemID, $childID)
	Global $temp_db
	Local $fn_custom_formula = IniRead($ini_file, "Files", "custom_filename", "")
	Local $fn_custom_formula_orig = $fn_custom_formula
	Local $delay
	Local $v_delay
	Local $v_delay_bit = 0
	Local $track_num_sorter2
	Local $json
	Local $parameter

	_SQLite_QuerySingleRow($db, "select display_text from sessions where handle='" & $itemID & "';", $query_result)
	If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
	$file_name = $query_result[0]
	_SQLite_QuerySingleRow($db, "select file from sessions where handle='" & $itemID & "';", $query_result)
	If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
	$full_path = $query_result[0]
	If $childID <> "cuesheets" And $childID <> "tags" And $childID <> "chapters" And $std_mkvm = "" Then
		$command_file = FileOpen($working_dir & "\mkv_cmd1.json", 266)
		FileWrite($command_file, "[" & @CRLF & '"--ui-language",' & @CRLF & '"en",' & @CRLF & '"--redirect-output",' & @CRLF & '"' & StringReplace($working_dir & "\std_out.txt", "\", "\\") & '",' & @CRLF & '"-J", ' & @CRLF & '"' & StringReplace($full_path, "\", "\\") & '" ' & @CRLF & "]")
		FileClose($command_file)
		FileDelete($working_dir & "\std_out.txt")
		RunWait($mkvtlnix_path & '\mkvmerge.exe @' & '"' & $working_dir & '\mkv_cmd1.json' & '"', $mkvtlnix_path, @SW_HIDE)
		Local $std_mkvm_o = FileOpen($working_dir & "\std_out.txt", 128)
		$std_mkvm = FileRead($std_mkvm_o)
		FileClose($std_mkvm_o)
		If $std_mkvm = "" Then
			MsgBox(16, "Error", "Could not get any information from Mkvmerge.exe" & @CRLF & @CRLF & "Download and install the latest version of MkvToolNix.")
			$cancel = 1
			$error_count += 1
			__Log_Write("Error: Unable to read Mkvmerge.exe output. Extraction cancelled.", 0, $session)
			Return
		EndIf
		;uncomment for testing json output
		;FileWrite($working_dir & "\json.txt", $std_mkvm)
		_SQLite_Exec($temp_db, "insert into TEMP ('key','value') values ('json'," & __SQL_Escape($std_mkvm) & ");")
		$json = __Json_Populate($std_mkvm)
		If $debug = 1 Then _DebugReportVar("json[__savefile_make]", $json, Default, @ScriptLineNumber)
		If $json = -1 Then Return -1
	ElseIf $childID <> "cuesheets" And $childID <> "tags" And $childID <> "chapters" And $std_mkvm <> "" Then
		_SQLite_QuerySingleRow($temp_db, "select value from TEMP where key='json';", $query_result)
		If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
		$json = __Json_Populate($query_result[0])
		If $debug = 1 Then _DebugReportVar("json(elseif)[__savefile_make]", $json, Default, @ScriptLineNumber)
		If $json = -1 Then Return -1
	EndIf
	Select
		Case $childID = "attachments"
			$sbText = StatusbarGetText("MKVcleaver " & $version, "")
			_GUICtrlStatusBar_SetText($statusbar, $sbText & " | Extracting Attachments...")
			Local $json_attachments = json_objget($json, "attachments")
			If $debug = 1 Then _DebugReportVar("attachments[__savefile_make]", $json_attachments, Default, @ScriptLineNumber)
			If UBound($json_attachments) = 0 Then
				__Log_Write("Attachments <empty file>", 2, $session)
				__Log_Write("(ok)", 3, $session)
				Return 1
			EndIf
			If $destination = "" Then
				$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
				$extract_path = $szDrive & $szDir
			Else
				$extract_path = $destination & "\"
			EndIf
			For $b = 0 To UBound($json_attachments) - 1
				Local $json_attachment = $json_attachments[$b]
				Local $json_attachmentID = json_objget($json_attachment, "id")
				If $debug = 1 Then _DebugReportVar("json attachment ID[__savefile_make]", $json_attachmentID, Default, @ScriptLineNumber)
				Local $json_attachment_filename = json_objget($json_attachment, "file_name")
				If $debug = 1 Then _DebugReportVar("json attachment filename[__savefile_make]", $json_attachment_filename, Default, @ScriptLineNumber)
				$extention_get = StringSplit($file_name, ".")
				If $debug = 1 Then _DebugReportVar("attachment extension[__savefile_make]", $extention_get, Default, @ScriptLineNumber)
				$extract_attachments &= '"' & $json_attachmentID & ":" & $extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_Attachments\" & $json_attachment_filename & '",' & @CRLF
			Next
			$command_file = FileOpen($working_dir & "\mkv_cmd1.json", 266)
			$full_path = StringReplace($full_path, "\", "\\")
			$extract_attachments = StringReplace($extract_attachments, "\", "\\")
			FileWrite($command_file, "[" & @CRLF & '"' & $full_path & '",' & @CRLF & '"attachments",' & @CRLF & StringReplace($extract_attachments, ",", "", -1) & "]")
			FileClose($command_file)
			__Log_Write("Attachments", 2, $session)
			$return = __Statusbar_Update(__Execute())
			$extract_attachments = ""
			Return $return
		Case $childID = "cuesheets"
			$sbText = StatusbarGetText("MKVcleaver " & $version, "")
			_GUICtrlStatusBar_SetText($statusbar, $sbText & " | Extracting Cuesheets...")
			$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
			If $destination = "" Then
				$extract_path = $szDrive & $szDir
			Else
				$extract_path = $destination & "\"
			EndIf
			$extention_get = StringSplit($file_name, ".")
			If $debug = 1 Then _DebugReportVar("cue extension[__savefile_make]", $extention_get, Default, @ScriptLineNumber)
			$command_file = FileOpen($working_dir & "\mkv_cmd1.json", 266)
			$full_path = StringReplace($full_path, "\", "\\")
			If $fn_custom_formula <> "" Then
				$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*Cuesheet*")
				__Custom_FileName_Format($fn_custom_formula) ;must be called before replacing [filename] placeholder
				$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", $szFName)
				$out_file_check = $extract_path & $fn_custom_formula & ".cue"
				$out_file = StringReplace($extract_path & $fn_custom_formula & ".cue", "\", "\\")
			Else
				$out_file_check = $extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_Cuesheet.cue"
				$out_file = StringReplace($extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_Cuesheet.cue", "\", "\\")
			EndIf
			FileWrite($command_file, "[" & @CRLF & '"' & $full_path & '",' & @CRLF & '"cuesheet",' & @CRLF & '"' & $out_file & '"' & @CRLF & "]")
			FileClose($command_file)
			$redirect_output = 1
			$return = __Statusbar_Update(__Execute())
			If FileRead($out_file_check) = "" Then
				FileDelete($out_file_check)
				_SQLite_QuerySingleRow($db, "select message from log where rowid=(select max(rowid) from log);", $query_result)
				If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
				_SQLite_Exec($db, "delete from log where rowid=(select max(rowid) from log);")
				__Log_Write("Cuesheets <empty file>", 2, $session)
				__Log_Write($query_result[0], 3, $session)
			Else
				_SQLite_QuerySingleRow($db, "select message from log where rowid=(select max(rowid) from log);", $query_result)
				If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
				_SQLite_Exec($db, "delete from log where rowid=(select max(rowid) from log);")
				__Log_Write("Cuesheets", 2, $session)
				__Log_Write($query_result[0], 3, $session)
			EndIf
			Return $return
		Case $childID = "chapters" Or $childID = "tags"
			$sbText = StatusbarGetText("MKVcleaver " & $version, "")
			_GUICtrlStatusBar_SetText($statusbar, $sbText & " | Extracting " & $childID & "...")
			$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
			If $destination = "" Then
				$extract_path = $szDrive & $szDir
			Else
				$extract_path = $destination & "\"
			EndIf
			$extention_get = StringSplit($file_name, ".")
			If $debug = 1 Then _DebugReportVar("chapter/tags extension[__savefile_make]", $extention_get, Default, @ScriptLineNumber)
			If $chapters_switch = "-s" And $childID = "chapters" Then
				$command_file = FileOpen($working_dir & "\mkv_cmd1.json", 266)
				$full_path = StringReplace($full_path, "\", "\\")
				If $fn_custom_formula <> "" Then
					$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*Chapters*")
					__Custom_FileName_Format($fn_custom_formula) ;must be called before replacing [filename] placeholder
					$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", $szFName)
					$out_file_check = $extract_path & $fn_custom_formula & ".txt"
					$out_file = StringReplace($extract_path & $fn_custom_formula & ".txt", "\", "\\")
				Else
					$out_file_check = $extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_" & $childID & ".txt"
					$out_file = StringReplace($extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_" & $childID & ".txt", "\", "\\")
				EndIf
				FileWrite($command_file, "[" & @CRLF & '"' & $full_path & '",' & @CRLF & '"' & StringLower($childID) & '",' & @CRLF & '"' & $chapters_switch & '",' & @CRLF & '"' & $out_file & '"' & @CRLF & "]")
				FileClose($command_file)
			Else
				$command_file = FileOpen($working_dir & "\mkv_cmd1.json", 266)
				$full_path = StringReplace($full_path, "\", "\\")
				$chapters_chkbx = _GUICtrlTreeView_GetChecked($tracklist, $chapters)
				$tags_chkbx = _GUICtrlTreeView_GetChecked($tracklist, $tags)
				If $fn_custom_formula <> "" Then
					$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*" & $childID & "*")
					__Custom_FileName_Format($fn_custom_formula) ;must be called before replacing [filename] placeholder
					$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", $szFName)
					$out_file_check = $extract_path & $fn_custom_formula & ".xml"
					$out_file = StringReplace($extract_path & $fn_custom_formula & ".xml", "\", "\\")
				Else
					$out_file_check = $extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_" & $childID & ".xml"
					$out_file = StringReplace($extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_" & $childID & ".xml", "\", "\\")
				EndIf
				FileWrite($command_file, "[" & @CRLF & '"' & $full_path & '",' & @CRLF & '"' & StringLower($childID) & '",' & @CRLF & '"' & $out_file & '"' & @CRLF & "]")
			EndIf
			$redirect_output = 1
			$return = __Statusbar_Update(__Execute())
			If FileRead($out_file_check) = "" Then
				FileDelete($out_file_check)
				_SQLite_QuerySingleRow($db, "select message from log where rowid=(select max(rowid) from log);", $query_result)
				If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
				_SQLite_Exec($db, "delete from log where rowid=(select max(rowid) from log);")
				__Log_Write($childID & " <empty file>", 2, $session)
				__Log_Write($query_result[0], 3, $session)
			Else
				_SQLite_QuerySingleRow($db, "select message from log where rowid=(select max(rowid) from log);", $query_result)
				If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
				_SQLite_Exec($db, "delete from log where rowid=(select max(rowid) from log);")
				__Log_Write($childID, 2, $session)
				__Log_Write($query_result[0], 3, $session)
			EndIf
			Return $return
		Case $childID = "Segments"
			$sbText = StatusbarGetText("MKVcleaver " & $version, "")
			_GUICtrlStatusBar_SetText($statusbar, $sbText & " | Extracting " & $childID & "...")
			$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
			If $destination = "" Then
				$extract_path = $szDrive & $szDir
			Else
				$extract_path = $destination & "\"
			EndIf
			$extention_get = StringSplit($file_name, ".")
			If $debug = 1 Then _DebugReportVar("segments extension[__savefile_make]", $extention_get, Default, @ScriptLineNumber)
			If $fn_custom_formula <> "" Then
				$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*" & $childID & "*")
				__Custom_FileName_Format($fn_custom_formula) ;must be called before replacing [filename] placeholder
				$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", $szFName)
				$out_file_check = $extract_path & $fn_custom_formula & ".xml"
				$out_file = $extract_path & $fn_custom_formula & ".xml"
			Else
				$out_file_check = $extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_" & $childID & ".xml"
				$out_file = $extract_path & StringTrimRight($file_name, StringLen($extention_get[UBound($extention_get) - 1]) + 1) & "_" & $childID & ".xml"
			EndIf
			If FileExists($out_file) Then FileDelete($out_file)
			FileWrite($out_file, '<?xml version="1.0" encoding="ISO-8859-1"?>' & @CRLF & '<!DOCTYPE Info SYSTEM "matroskasegmentinfo.dtd">' & @CRLF & @CRLF & "<Info>" & @CRLF & @TAB)
			Local $container = json_objget($json, "container")
			If $debug = 1 Then _DebugReportVar("segments json container[__savefile_make]", $container, Default, @ScriptLineNumber)
			Local $properties = json_objget($container, "properties")
			If $debug = 1 Then _DebugReportVar("segments json properties[__savefile_make]", $properties, Default, @ScriptLineNumber)
			Local $suid = json_objget($properties, "segment_uid")
			If $debug = 1 Then _DebugReportVar("segments json uid[__savefile_make]", $suid, Default, @ScriptLineNumber)
			Local $prev_suid = json_objget($properties, "previous_segment_uid")
			If $debug = 1 Then _DebugReportVar("segments json prevuid[__savefile_make]", $prev_suid, Default, @ScriptLineNumber)
			Local $next_suid = json_objget($properties, "next_segment_uid")
			If $debug = 1 Then _DebugReportVar("segments json next uid[__savefile_make]", $next_suid, Default, @ScriptLineNumber)
			FileWrite($out_file, '<SegmentUID format="hex">' & $suid & "</SegmentUID>" & @CRLF)
			If $prev_suid <> "" Then FileWrite($out_file, @TAB & '<PreviousSegmentUID format="hex">' & $prev_suid & "</PreviousSegmentUID>" & @CRLF)
			If $next_suid <> "" Then FileWrite($out_file, @TAB & '<NextSegmentUID format="hex">' & $next_suid & "</NextSegmentUID>" & @CRLF)
			FileWrite($out_file, "</Info>")
			__Log_Write("SegmentUIDs", 2, $session)
			__Log_Write("(ok)", 3, $session)
			Return 1
		Case $childID = "timecodes"
			Local $query_result3
			Local $fn_custom_formula_orig = $fn_custom_formula

			If $cmd = "" And $continue = 1 Then $call += 1
			If $cmd <> "" Then
				If $fn_custom_formula <> "" Then
					$split_command = StringSplit($cmd, @CRLF, 1)
					If $debug = 1 Then _DebugReportVar("split command[__savefile_make]", $split_command, Default, @ScriptLineNumber)
					$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
					If $destination = "" Then
						$extract_path = $szDrive & $szDir
					Else
						$extract_path = $destination & "\"
					EndIf
					_SQLite_QuerySingleRow($db, "select display_text from sessions where file=" & __SQL_Escape($full_path) & ";", $query_result3)
					If $debug = 1 Then _DebugReportVar("query result3[__savefile_make]", $query_result3, Default, @ScriptLineNumber)
					For $c = 1 To UBound($split_command) - 2
						$fn_custom_formula = $fn_custom_formula_orig
						$track_type = ""
						$track_num = StringMid($split_command[$c], 2, StringInStr($split_command[$c], ":", 0, 1, 1) - 2)
						For $b = 1 To 3
							Switch $b
								Case 1
									$track_type = "Video"
								Case 2
									$track_type = "Audio"
								Case 3
									$track_type = "Subtitles"
							EndSwitch
							$track_id = __Get_MediaInfo($full_path, $media_info_handle, $track_type & ";%StreamOrder%-")
							If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $track_id, Default, @ScriptLineNumber)
							If StringInStr($track_id, $track_num) Then ExitLoop
						Next
						Local $stream_count = __Get_MediaInfo($full_path, $media_info_handle, "StreamCount", 0, $b)
						If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $stream_count, Default, @ScriptLineNumber)
						For $d = 1 To $stream_count
							Local $trackID = __Get_MediaInfo($full_path, $media_info_handle, "StreamKindPos", $d - 1, $b)
							If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $trackID, Default, @ScriptLineNumber)
							Local $track_id = __Get_MediaInfo($full_path, $media_info_handle, "StreamOrder", $d - 1, $b)
							If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $track_id, Default, @ScriptLineNumber)
							If $track_id = $track_num Then ExitLoop
						Next
						Select
							Case $track_num < 9
								$track_sorter = "0" & $track_num + 1
							Case $track_num > 8
								$track_sorter = $track_num + 1
						EndSelect
						Select
							Case $trackID = ""
								$track_num_sorter = "01"
							Case $trackID < 10
								$track_num_sorter = "0" & $trackID
							Case $trackID > 9
								$track_num_sorter = $trackID
						EndSelect
						$fn_custom_formula = StringReplace($fn_custom_formula, "[tracktype]", "*" & $track_type & "*")
						$fn_custom_formula = StringReplace($fn_custom_formula, "[tracktype#]", "*" & $track_num_sorter & "*")
						$fn_custom_formula = StringReplace($fn_custom_formula, "[track#]", "*" & $track_sorter & "*")
						__Custom_FileName_Format($fn_custom_formula) ;must be called before replacing [filename] placeholder
						$extention_get = StringSplit($query_result3[0], ".", 1)
						If $debug = 1 Then _DebugReportVar("timecodes extension[__savefile_make]", $extention_get, Default, @ScriptLineNumber)
						$fn_custom_formula = StringReplace($fn_custom_formula, "[filename]", StringTrimRight($query_result3[0], StringLen($extention_get[UBound($extention_get) - 1]) + 1))
						$cmd3 &= '"' & $track_num & ":" & $extract_path & $fn_custom_formula & '_Timecodes.txt",' & @CRLF
					Next
				Else
					$split_command = StringSplit($cmd, @CRLF, 1)
					If $debug = 1 Then _DebugReportVar("split command[__savefile_make]", $split_command, Default, @ScriptLineNumber)
					If IsArray($split_command) Then
						For $b = 1 To UBound($split_command) - 2
							$extention_get = StringSplit($split_command[$b], ".")
							If $debug = 1 Then _DebugReportVar("timecodes extnesion[__savefile_make]", $extention_get, Default, @ScriptLineNumber)
							$cmd3 &= StringTrimRight($split_command[$b], StringLen($extention_get[UBound($extention_get) - 1]) + 1) & '_Timecodes.txt",' & @CRLF
						Next
					EndIf
				EndIf
				$out_file = StringReplace($cmd3, "\", "\\")
				$command_file = FileOpen($working_dir & "\mkv_cmd1.json", 266)
				$full_path = StringReplace($full_path, "\", "\\")
				FileWrite($command_file, "[" & @CRLF & '"' & $full_path & '",' & @CRLF & '"timecodes_v2",' & @CRLF & StringReplace($out_file, ",", "", -1) & "]")
				FileClose($command_file)
				If $no_execute = 0 Then $call += 1
				__Log_Write("Timecodes", 2, $session)
				$return = __Statusbar_Update(__Execute())
				Return $return
			ElseIf $cmd = "" And $continue = 0 Then
				MsgBox(48, "Selection error", '"Timecodes" box cannot be selected by itself.' & @CRLF & @CRLF & "You must select at least one track to get the timecodes from.")
				_GUICtrlStatusBar_SetText($statusbar, "")
				__Log_Write('"Timecodes" box cannot be selected by itself. Select a track to get the timecodes from.', 1, $session)
				$error_count += 1
				Return 0
			EndIf
			Return 1
		Case $childID <> ""
			_SQLite_QuerySingleRow($db, "select track from child_handles where handle='" & $childID & "';", $query_result)
			If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
			Local $trackID = $query_result[0]
			Local $json_tracks = json_objget($json, "tracks")
			If $debug = 1 Then _DebugReportVar("json tracks[__savefile_make]", $json_tracks, Default, @ScriptLineNumber)
			Local $json_type = json_objget($json_tracks[$trackID], "type")
			If $debug = 1 Then _DebugReportVar("json track type[__savefile_make]", $json_type, Default, @ScriptLineNumber)
			Local $track_type = _StringProper($json_type)
			__Log_Write($track_type, 2, $session)
			Local $json_properties = json_objget($json_tracks[$trackID], "properties")
			If $debug = 1 Then _DebugReportVar("json track properties[__savefile_make]", $json_properties, Default, @ScriptLineNumber)
			Local $codec = json_objget($json_properties, "codec_id")
			If $debug = 1 Then _DebugReportVar("json codec[__savefile_make]", $codec, Default, @ScriptLineNumber)
			Local $stream_count = __Get_MediaInfo($full_path, $media_info_handle, "StreamCount", 0, $track_type)
			If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $stream_count, Default, @ScriptLineNumber)
			For $d = 1 To $stream_count
				Local $track_pos = __Get_MediaInfo($full_path, $media_info_handle, "StreamKindPos", $d - 1, $track_type)
				If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $track_pos, Default, @ScriptLineNumber)
				$track_id = __Get_MediaInfo($full_path, $media_info_handle, "StreamOrder", $d - 1, $track_type)
				If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $track_id, Default, @ScriptLineNumber)
				If $track_id = $trackID Then ExitLoop
			Next
			If $track_pos = "" Then $track_pos = 1
			$track_num = $track_pos
			_SQLite_QuerySingleRow($db, "select message from log where rowid='" & _SQLite_LastInsertRowID($db) & "';", $query_result)
			If $debug = 1 Then _DebugReportVar("query result[__savefile_make]", $query_result, Default, @ScriptLineNumber)
			_SQLite_Exec($db, "update log set message='" & $query_result[0] & @TAB & $track_num & "' where rowid='" & _SQLite_LastInsertRowID($db) & "';")
			Dim $codec_id[1] = [$codec]
		Case Else
			_SQLite_QuerySingleRow($db, "select text from batch_item_handles where handle='" & $tracklist_item & "';", $query_result2)
			If $debug = 1 Then _DebugReportVar("query result2[__savefile_make]", $query_result2, Default, @ScriptLineNumber)
			$batch_item_split = StringSplit($query_result2[0], " ")
			If $debug = 1 Then _DebugReportVar("batch item split[__savefile_make]", $batch_item_split, Default, @ScriptLineNumber)
			Local $stream_count = __Get_MediaInfo($full_path, $media_info_handle, "StreamCount", 0, StringReplace($batch_item_split[1], "Subtitle", "Text"))
			If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $stream_count, Default, @ScriptLineNumber)
			If $stream_count < $batch_item_split[3] Then
				$continue = 1
				Return -1
			EndIf
			Local $trackID = __Get_MediaInfo($full_path, $media_info_handle, "StreamOrder", $batch_item_split[3] - 1, $batch_item_split[1])
			If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $trackID, Default, @ScriptLineNumber)
			$track_type = $batch_item_split[1]
			If $track_type = "Subtitle" Then $track_type = "Subtitles"
			__Log_Write($track_type & " " & @TAB & $batch_item_split[3], 2, $session)
			Local $json_tracks = json_objget($json, "tracks")
			If $debug = 1 Then _DebugReportVar("json tracks[__savefile_make]", $json_tracks, Default, @ScriptLineNumber)
			Local $json_properties = json_objget($json_tracks[$trackID], "properties")
			If $debug = 1 Then _DebugReportVar("json track properties[__savefile_make]", $json_properties, Default, @ScriptLineNumber)
			$codec = json_objget($json_properties, "codec_id")
			If $debug = 1 Then _DebugReportVar("json codec[__savefile_make]", $codec, Default, @ScriptLineNumber)
			$track_num = $batch_item_split[3]
			Dim $codec_id[1] = [$codec]
	EndSelect
	;Check track filters
	Local $filter_result = __Filter_Tracks($track_type, $full_path, $track_num)
	$filter_result = StringSplit($filter_result, "|")
	If $debug = 1 Then _DebugReportVar("filter results[__savefile_make]", $filter_result, Default, @ScriptLineNumber)
	If $filter_result[1] = 1 Then
		__Log_Write("Filtered out according to Filter line(s) " & $filter_result[2], 3, $session)
		Return -1
	EndIf

	$custom_extension = IniReadSectionNames($ini_file)
	$find = _ArraySearch($custom_extension, $codec_id[0])
	Select
		Case $find <> -1
			$output = IniRead($ini_file, $custom_extension[$find], "extension", ".undefined")
		Case StringInStr($codec_id[0], "V_REAL/")
			$output = ".rm"
		Case $codec_id[0] = "V_MPEG1"
			$output = ".m1v"
		Case $codec_id[0] = "V_MPEG2"
			$output = ".m2v"
		Case $codec_id[0] = "V_THEORA"
			$output = ".ogm"
		Case $codec_id[0] = "V_MPEG4/ISO/AVC"
			$output = ".h264"
		Case StringInStr($codec_id[0], "V_MS/VFW/FOURCC") Or $codec_id[0] = "V_SNOW" Or StringInStr($codec_id[0], "V_MPEG4/ISO/") Or $codec_id[0] = "V_UNCOMPRESSED" Or $codec_id[0] = "V_MPEG4/MS/V3"
			$output = ".avi"
		Case $codec_id[0] = "V_QUICKTIME"
			$output = ".mov"
		Case $codec_id[0] = "V_VP8"
			$output = ".ivf"
		Case $codec_id[0] = "A_MPEG/L3"
			$output = ".mp3"
		Case $codec_id[0] = "A_MPEG/L2"
			$output = ".mp2"
		Case $codec_id[0] = "V_MPEGH/ISO/HEVC"
			$output = ".h265"
		Case $codec_id[0] = "A_MPEG/L1"
			$output = ".mp1"
		Case StringInStr($codec_id[0], "A_PCM")
			$output = ".wav"
		Case StringInStr($codec_id[0], "A_AC3")
			$output = ".ac3"
		Case $codec_id[0] = "A_DTS"
			$output = ".dts"
		Case $codec_id[0] = "A_FLAC"
			$output = ".flac"
		Case $codec_id[0] = "A_VORBIS" Or $codec_id[0] = "S_KATE"
			$output = ".ogg"
		Case StringInStr($codec_id[0], "A_REAL/")
			$output = ".ra"
		Case $codec_id[0] = "A_MS/ACM"
			$output = ".acm"
		Case StringInStr($codec_id[0], "A_AAC") Or $codec_id[0] = "A_QUICKTIME"
			$output = ".aac"
		Case $codec_id[0] = "A_TTA1"
			$output = ".tta"
		Case $codec_id[0] = "A_WAVPACK4"
			$output = ".wv"
		Case $codec_id[0] = "A_TRUEHD"
			$output = ".truehd"
		Case $codec_id[0] = "A_OPUS"
			$output = ".opus"
		Case $codec_id[0] = "S_TEXT/ASCII" Or $codec_id[0] = "S_TEXT/UTF8"
			$output = ".srt"
		Case $codec_id[0] = "S_TEXT/SSA"
			$output = ".ssa"
		Case $codec_id[0] = "S_TEXT/ASS"
			$output = ".ass"
		Case $codec_id[0] = "S_TEXT/USF"
			$output = ".usf"
		Case $codec_id[0] = "S_VOBSUB"
			$output = ".idx"
		Case $codec_id[0] = "S_HDMV/PGS"
			$output = "_PGS.sup"
		Case Else
			$output = ".undefined"
	EndSelect
	If $track_type = "Audio" Or $track_type = "Text" Or $track_type = "Video" Or $track_type = "Subtitle" Or $track_type = "Subtitles" Then
		If $track_type = "Audio" Or $track_type = "Video" Then
			$delay = __Get_MediaInfo($full_path, $media_info_handle, "Delay", $track_num - 1, $track_type)
			If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $delay, Default, @ScriptLineNumber)
			If $delay = "" Then $delay = "0"
			$fn_custom_formula = StringReplace($fn_custom_formula, "[Delay]", "*" & $delay & "ms*")
			If $track_type = "Audio" Then
				$v_delay = __Get_MediaInfo($full_path, $media_info_handle, "Delay", $track_num - 1, "Video")
				If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $v_delay, Default, @ScriptLineNumber)
				$fn_custom_formula = StringReplace($fn_custom_formula, "[aDelay]", "*" & $delay - $v_delay & "ms*")
			EndIf
		EndIf
		If $track_type = "Audio" Or $track_type = "Text" Or $track_type = "Subtitle" Or $track_type = "Subtitles" Then
			Do
				Select
					Case StringInStr($fn_custom_formula, "[LNG]")
						$lng = __Get_MediaInfo($full_path, $media_info_handle, "Language", $track_num - 1, $track_type)
						If $lng <> "" Then $fn_custom_formula = StringReplace($fn_custom_formula, "[LNG]", "*" & $lng & "*", 1)
					Case StringInStr($fn_custom_formula, "[LNG3]")
						$lng = __Get_MediaInfo($full_path, $media_info_handle, "Language/String3", $track_num - 1, $track_type)
						If $lng <> "" Then $fn_custom_formula = StringReplace($fn_custom_formula, "[LNG3]", "*" & $lng & "*", 1)
					Case StringInStr($fn_custom_formula, "[LNGf]")
						$lng = __Get_MediaInfo($full_path, $media_info_handle, "Language/String", $track_num - 1, $track_type)
						If $lng <> "" Then $fn_custom_formula = StringReplace($fn_custom_formula, "[LNGf]", "*" & $lng & "*", 1)
					Case Else
						$lng = ""
				EndSelect
			Until $lng = ""
		EndIf
	EndIf

	If $fn_custom_formula = "" Then
		If $trackID < 9 Then
			$track_num_sorter = "0" & $trackID + 1
		Else
			$track_num_sorter = $trackID + 1
		EndIf
	Else
		If $track_num < 10 Then
			$track_num_sorter2 = "0" & $track_num
		Else
			$track_num_sorter2 = $track_num
		EndIf
		If $trackID < 9 Then
			$track_num_sorter = "0" & $trackID + 1
		Else
			$track_num_sorter = $trackID + 1
		EndIf
	EndIf
	Local $placeholders = IniReadSection($ini_file, "Placeholders")
	If $debug = 1 Then _DebugReportVar("placeholders[__savefile_make]", $placeholders, Default, @ScriptLineNumber)
	If $destination = "" Then
		Select
			Case $fn_custom_formula <> ""
				$fn_custom_formula = StringReplace($fn_custom_formula, "[Track#]", "*" & $track_num_sorter & "*")
				$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType#]", "*" & $track_num_sorter2 & "*")
				$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*" & $track_type & "*")
				$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
				For $w = 1 To $placeholders[0][0]
					Local $placeholder_string = StringSplit($placeholders[$w][1], "|")
					If $debug = 1 Then _DebugReportVar("placeholder string[__savefile_make]", $placeholder_string, Default, @ScriptLineNumber)
					$parameter = IniRead($ini_file, "Parameters", $placeholder_string[2], "")
					Local $data = __Get_MediaInfo($full_path, $media_info_handle, $parameter, $track_num - 1, $track_type)
					If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $data, Default, @ScriptLineNumber)
					If $data <> "" Then $fn_custom_formula = StringReplace($fn_custom_formula, $placeholder_string[1], "*" & $data & "*")
				Next
				__Custom_FileName_Format($fn_custom_formula)
				__Clean_Path($fn_custom_formula)
				$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", $szFName)
				If $track_type = "Video" Then
					Local $temp_fn = StringReplace(StringReplace(StringReplace($fn_custom_formula_orig, "[TrackType#]", $track_num_sorter2), "[Track#]", "*" & $track_num_sorter & "*"), "[TrackType]", "*" & $track_type & "*")
					__Custom_FileName_Format($temp_fn)
					$temp_fn = StringReplace($temp_fn, "[Filename]", $szFName)
					__CheckVFR($trackID & ":" & $szDrive & $szDir & $temp_fn, $vfr_mode)
				EndIf
				$command_path = _PathMake($szDrive, $szDir, $fn_custom_formula, $output)
				If $track_type = "Video" And $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
				If $track_type = "Video" And $vfr > 0 Then $vfrconv &= "/" & $destination & "\" & $fn_custom_formula & "|" & $destination & "\" & $temp_fn
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
			Case GUICtrlRead($tr_fn_chk) = $GUI_CHECKED
				$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
				$command_path = _PathMake($szDrive, $szDir, "Track" & $track_num_sorter & "_" & $szFName, $output)
				If $track_type = "Video" Then
					__CheckVFR($trackID & ":" & $szDrive & $szDir & "Track" & $track_num_sorter & "_" & $szFName, $vfr_mode)
					If $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
					If $vfr > 0 Then $vfrconv &= "/" & $szDrive & $szDir & "Track" & $track_num_sorter & "_" & $szFName
				EndIf
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
			Case GUICtrlRead($fn_tr_chk) = $GUI_CHECKED And GUICtrlRead($tropt_chk) = $GUI_UNCHECKED
				$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
				$command_path = _PathMake($szDrive, $szDir, $szFName & "_" & "Track" & $track_num_sorter, $output)
				If $track_type = "video" Then
					__CheckVFR($trackID & ":" & $szDrive & $szDir & $szFName & "_" & "Track" & $track_num_sorter, $vfr_mode)
					If $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
					If $vfr > 0 Then $vfrconv &= "/" & $szDrive & $szDir & $szFName & "_" & "Track" & $track_num_sorter
				EndIf
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
			Case GUICtrlRead($fn_tr_chk) = $GUI_CHECKED And GUICtrlRead($tropt_chk) = $GUI_CHECKED
				$path_split = _PathSplit($full_path, $szDrive, $szDir, $szFName, $szExt)
				$command_path = _PathMake($szDrive, $szDir, $szFName & _StringProper("_" & $track_type) & $track_num_sorter, $output)
				If $track_type = "video" Then
					__CheckVFR($trackID & ":" & $szDrive & $szDir & $szFName & _StringProper("_" & $track_type) & $track_num_sorter, $vfr_mode)
					If $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
					If $vfr > 0 Then $vfrconv &= "/" & $szDrive & $szDir & $szFName & _StringProper("_" & $track_type) & $track_num_sorter
				EndIf
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
		EndSelect
	Else
		Select
			Case $fn_custom_formula <> ""
				$fn_custom_formula = StringReplace($fn_custom_formula, "[Track#]", "*" & $track_num_sorter & "*")
				$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType#]", "*" & $track_num_sorter2 & "*")
				$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*" & $track_type & "*")
				For $w = 1 To $placeholders[0][0]
					Local $placeholder_string = StringSplit($placeholders[$w][1], "|")
					If $debug = 1 Then _DebugReportVar("placeholder string[__savefile_make]", $placeholder_string, Default, @ScriptLineNumber)
					$parameter = IniRead($ini_file, "Parameters", $placeholder_string[2], "")
					Local $data = __Get_MediaInfo($full_path, $media_info_handle, $parameter, $track_num - 1, $track_type)
					If $debug = 1 Then _DebugReportVar("media info[__savefile_make]", $data, Default, @ScriptLineNumber)
					If $data <> "" Then $fn_custom_formula = StringReplace($fn_custom_formula, $placeholder_string[1], "*" & $data & "*")
				Next
				__Custom_FileName_Format($fn_custom_formula) ;must be called before replacing [filename] placeholder
				__Clean_Path($fn_custom_formula)
				$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", StringTrimRight($file_name, 4))
				If $track_type = "Video" Then
					Local $temp_fn = StringReplace(StringReplace(StringReplace($fn_custom_formula_orig, "[TrackType#]", $track_num_sorter2), "[Track#]", "*" & $track_num_sorter & "*"), "[TrackType]", "*" & $track_type & "*")
					__Custom_FileName_Format($temp_fn)
					$temp_fn = StringReplace($temp_fn, "[Filename]", StringTrimRight($file_name, 4))
					__CheckVFR($trackID & ":" & $destination & "\" & $temp_fn, $vfr_mode)
				EndIf
				$command_path = $destination & "\" & $fn_custom_formula & $output
				If $track_type = "Video" And $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
				If $track_type = "Video" And $vfr > 0 Then $vfrconv &= "/" & $destination & "\" & $fn_custom_formula & "|" & $destination & "\" & $temp_fn
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
			Case GUICtrlRead($tr_fn_chk) = $GUI_CHECKED
				$command_path = $destination & "\Track" & $track_num_sorter & "_" & StringTrimRight($file_name, 4) & $output
				If $track_type = "Video" Then
					__CheckVFR($trackID & ":" & $destination & "\Track" & $track_num_sorter & "_" & StringTrimRight($file_name, 4), $vfr_mode)
					If $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
					If $vfr > 0 Then $vfrconv &= "/" & $destination & "\Track" & $track_num_sorter & "_" & StringTrimRight($file_name, 4)
				EndIf
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
			Case GUICtrlRead($fn_tr_chk) = $GUI_CHECKED And GUICtrlRead($tropt_chk) = $GUI_UNCHECKED
				$command_path = $destination & "\" & StringTrimRight($file_name, 4) & "_Track" & $track_num_sorter & $output
				If $track_type = "video" Then
					__CheckVFR($trackID & ":" & $destination & "\" & StringTrimRight($file_name, 4) & "_Track" & $track_num_sorter, $vfr_mode)
					If $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
					If $vfr > 0 Then $vfrconv &= "/" & $destination & "\" & StringTrimRight($file_name, 4) & "_Track" & $track_num_sorter
				EndIf
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
			Case GUICtrlRead($fn_tr_chk) = $GUI_CHECKED And GUICtrlRead($tropt_chk) = $GUI_CHECKED
				$command_path = $destination & "\" & StringTrimRight($file_name, 4) & _StringProper("_" & $track_type) & $track_num_sorter & $output
				If $track_type = "video" Then
					__CheckVFR($trackID & ":" & $destination & "\" & StringTrimRight($file_name, 4) & _StringProper("_" & $track_type) & $track_num_sorter, $vfr_mode)
					If $codec_id[0] = "V_MPEG4/ISO/AVC" Then $h264 &= "/" & $command_path
					If $vfr > 0 Then $vfrconv &= "/" & $destination & "\" & StringTrimRight($file_name, 4) & _StringProper("_" & $track_type) & $track_num_sorter
				EndIf
				$command_path = StringReplace($command_path, "\", "\\")
				$command_path = '"' & $trackID & ":" & $command_path & '"'
				Return $command_path
		EndSelect
	EndIf
EndFunc   ;==>__SaveFile_Make

Func __Get_MediaInfo($path, ByRef $media_info_handle, $info_type = Default, $track_num = Default, $track_type = Default)
	Local Static $old_path

	If $info_type = Default Then
		DllCall($media_info_dll, "none", "MediaInfo_Delete", "ptr", $media_info_handle)
		$return = DllCall($media_info_dll, "ptr", "MediaInfo_New")
		Return $return[0]
	EndIf
	If $track_num = Default And $track_type = Default Then
		DllCall($media_info_dll, "int", "MediaInfo_Open", "ptr", $media_info_handle, "wstr", $path)
		Select
			Case $info_type = "info"
				DllCall($media_info_dll, "wstr", "MediaInfo_Option", "ptr", 0, "wstr", "Complete", "wstr", "1")
				$return = DllCall($media_info_dll, "wstr", "MediaInfo_Inform", "ptr", $media_info_handle, "int", 0)
			Case Else
				DllCall($media_info_dll, "wstr", "MediaInfo_Option", "ptr", 0, "wstr", "Inform", "wstr", $info_type)
				$return = DllCall($media_info_dll, "wstr", "MediaInfo_Inform", "ptr", $media_info_handle, "int", 0)
		EndSelect
	Else
		If $old_path <> $path Then DllCall($media_info_dll, "int", "MediaInfo_Open", "ptr", $media_info_handle, "wstr", $path)
		Switch $track_type
			Case "Video"
				$track_type = 1
			Case "Audio"
				$track_type = 2
			Case "Text"
				$track_type = 3
			Case "Subtitles"
				$track_type = 3
			Case "Subtitle"
				$track_type = 3
		EndSwitch
		$return = DllCall($media_info_dll, "wstr", "MediaInfo_Get", "ptr", $media_info_handle, "int", $track_type, "int", $track_num, "wstr", $info_type, "int", 1, "int", 0)
		$old_path = $path
	EndIf
	Return $return[0]
EndFunc   ;==>__Get_MediaInfo

Func __OnAutoItExit()
	Local $iSessionSaved = 0

	If $debug = 1 Then _DebugOut("Exiting MKVcleaver")
	_SQLite_QuerySingleRow($db, "select count(file) from sessions;", $query_result)
	If IsArray($query_result) Then
		If $query_result[0] >= 1 And $session_saver = 1 Then
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Icon=Question, Timeout=15 ss, Miscellaneous=Top-most attribute
			If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
			$iMsgBoxAnswer = MsgBox(262180, "Save Session", "Do you want to save your current session ?", 15)
			Select
				Case $iMsgBoxAnswer = 6 ;Yes
					$iSessionSaved = 1
				Case $iMsgBoxAnswer = 7 ;No
					_SQLite_Exec($db, "drop table if exists 'sessions';" & "drop table if exists 'session_settings';" & "drop table if exists 'child_handles';" & "drop table if exists 'batch_item_handles';")
					$iSessionSaved = 0
				Case $iMsgBoxAnswer = -1 ;Timeout
					$iSessionSaved = 1
			EndSelect
			#EndRegion --- CodeWizard generated code Start ---
		Else
			$iSessionSaved = 0
			_SQLite_Exec($db, "drop table if exists 'sessions';" & "drop table if exists 'session_settings';" & "drop table if exists 'child_handles';" & "drop table if exists 'batch_item_handles';")
		EndIf
	EndIf
	_GUICtrlStatusBar_Destroy($statusbar)
	_ITaskBar_DestroyObject($GUI)
	;_AutoItObject_Shutdown()
	DllCall($media_info_dll, "none", "MediaInfo_Delete", "ptr", $media_info_handle)
	DllClose($media_info_dll)
	Local $position = WinGetPos("MKVcleaver " & FileGetVersion(@AutoItExe))
	If IsArray($position) Then
		IniWriteSection($ini_file, "GUI", "x=" & $position[0] & @LF & "y=" & $position[1] & @LF & "width=" & $position[2] & @LF & "hight=" & $position[3] & @LF & "resize=" & $resize_bit & @LF & "maximized=" & $maximize & _
				@LF & "filename1=" & GUICtrlRead($tr_fn_chk) & @LF & "filename2=" & GUICtrlRead($fn_tr_chk) & @LF & "fileopts=" & GUICtrlRead($tropt_chk) & @LF & "aviconvert=" & GUICtrlRead($cntoavi) & @LF & "vfrconvert=" & GUICtrlRead($vfrtocfr) & @LF & "session=" & $session_saver & @LF & "line_title=" & $line_title & @LF & "line_video=" & $line_video & @LF & "line_audio=" & $line_audio & @LF & "line_text=" & $line_text & @LF & "user_saved=" & $iSessionSaved)
	EndIf
	_SQLite_Exec($db, "drop table if exists 'pid';")
	_SQLite_Close($db)
	_SQLite_Shutdown()
	ConsoleWrite("Exiting MKVCleaver." & @CRLF)
EndFunc   ;==>__OnAutoItExit

Func __Edit_Title_GUI($title, $selection = "all")
	Local $current_text = ""
	Local $nMsg8
	Local $key
	Local $ctrl_size
	Local $caret_pos
	Local $current_text_p1, $current_text_p2
	Local $line

	Switch $selection
		Case "all"
			$key = "line_title"
			Assign("ini_var", $line_title)
			$line = "Title"
		Case "Video"
			$key = "line_video"
			Assign("ini_var", $line_video)
			$line = $selection & " Track"
		Case "Audio"
			$key = "line_audio"
			Assign("ini_var", $line_audio)
			$line = $selection & " Track"
		Case "Text"
			$key = "line_text"
			Assign("ini_var", $line_text)
			$line = $selection & " Track"
	EndSwitch

	GUICtrlSetState($file_list, $GUI_NODROPACCEPTED)
	Global $tl_custom_GUI = GUICreate($title, 430, 250, -1, -1, $WS_SIZEBOX)
	GUICtrlCreateGroup("Customize " & $line & " Line", 10, 10, 408, 180)
	Local $menu = GUICtrlCreateMenu("Menu")
	Local $plch_config = GUICtrlCreateMenuItem("Placeholder Config", $menu, 1)
	Local $save = GUICtrlCreateMenuItem("Save", $menu, 2)
	If $selection = "all" Then
		Local $tl_track_type_select = GUICtrlCreateCombo("Video", 19, 36, 80, 30, $CBS_DROPDOWNLIST)
		GUICtrlSetData(-1, "Audio|Text")
	EndIf
	If $selection = "all" Then
		Local $tl_custom_input = GUICtrlCreateInput("", 109, 36, 300, 21)
	Else
		Local $tl_custom_input = GUICtrlCreateInput("", 19, 36, 390, 21)
	EndIf

	Switch $selection
		Case "all"
			GUICtrlSetData($tl_custom_input, $line_title)
		Case "Video"
			GUICtrlSetData($tl_custom_input, $line_video)
		Case "Audio"
			GUICtrlSetData($tl_custom_input, $line_audio)
		Case "Text"
			GUICtrlSetData($tl_custom_input, $line_text)
	EndSwitch

	Local $tl_dummy = GUICtrlCreateDummy()
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	Local $tl_list_plchld = GUICtrlCreateListView("Placeholders", 19, 66, 390, 100, BitOR($LVS_SHOWSELALWAYS, $LVS_SINGLESEL, $LVS_NOCOLUMNHEADER, $LVS_NOSORTHEADER, $LVS_SORTASCENDING))
	_GUICtrlListView_SetExtendedListViewStyle($tl_list_plchld, BitOR($LVS_EX_GRIDLINES, $WS_EX_CLIENTEDGE, $LVS_EX_FULLROWSELECT))
	Local $placeholders = IniReadSection($ini_file, "Placeholders")

	If Not @error Then
		For $a = 1 To $placeholders[0][0]
			$item = StringSplit($placeholders[$a][1], "|")
			If Not @error Then
				GUICtrlCreateListViewItem($item[1], $tl_list_plchld)
			EndIf
		Next
		If $placeholders[0][0] > 5 Then
			_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, 365)
		Else
			_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, 385)
		EndIf
	EndIf

	GUICtrlSetResizing($tl_list_plchld, $GUI_DOCKAUTO)

	GUISetState(@SW_SHOW, $tl_custom_GUI)
	GUISetState(@SW_HIDE, $fl_layout_editor)

	While 1
		$nMsg8 = GUIGetMsg(1)
		Switch $nMsg8[0]
			Case $GUI_EVENT_CLOSE
				If Eval("ini_var") <> GUICtrlRead($tl_custom_input) Then
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(292, "Unsaved Changes", "You made changes." & @CRLF & @CRLF & "Do you want to close the module without saving ?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes

						Case $iMsgBoxAnswer = 7 ;No
							ContinueLoop
					EndSelect
				EndIf
				GUISetState(@SW_SHOW, $fl_layout_editor)
				GUIDelete($tl_custom_GUI)
				GUICtrlSetState($file_list, $GUI_DROPACCEPTED)
				Return

			Case $plch_config
				_Custom_FileName_Config($tl_custom_GUI, $title)
				_GUICtrlListView_BeginUpdate($tl_list_plchld)
				_GUICtrlListView_DeleteAllItems($tl_list_plchld)
				Local $placeholders = IniReadSection($ini_file, "Placeholders")

				If Not @error Then
					For $a = 1 To $placeholders[0][0]
						$item = StringSplit($placeholders[$a][1], "|")
						If Not @error Then
							GUICtrlCreateListViewItem($item[1], $tl_list_plchld)
						EndIf
					Next
					If $placeholders[0][0] > 5 Then
						_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, 365)
					Else
						_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, 385)
					EndIf
					_GUICtrlListView_EndUpdate($tl_list_plchld)
				EndIf

			Case $GUI_EVENT_DROPPED
				Local $index = _GUICtrlListView_GetSelectedIndices($tl_list_plchld)
				Local $text = _GUICtrlListView_GetItemText(GUICtrlGetHandle($tl_list_plchld), $index)
				$current_text = GUICtrlRead($tl_custom_input)
				If $selection = "all" Then
					Local $track_type = GUICtrlRead($tl_track_type_select)
				EndIf
				Local $parameter = _StringBetween($text, "[", "]")
				$index = _ArraySearch($placeholders, $text, Default, Default, Default, 1)
				If Not @error Then
					Local $placeholder_string = StringSplit($placeholders[$index][1], "|")
					If Not @error Then
						$parameter = IniRead($ini_file, "Parameters", $placeholder_string[2], "")
					EndIf
				EndIf
				If $key = "line_title" Then
					$text = "[" & $track_type & ";%" & $parameter & "%|]"
				Else
					$text = "[" & $parameter & "]"
				EndIf
				$caret_pos = ControlCommand($title, "", "[CLASSNN:Edit1]", "GetCurrentCol")
				$current_text_p1 = StringMid($current_text, 1, $caret_pos - 1)
				$current_text_p2 = StringMid($current_text, $caret_pos, StringLen($current_text))
				GUICtrlSetData($tl_custom_input, $current_text_p1 & $text & $current_text_p2)
				ContinueLoop

			Case $save
				Assign("ini_var", GUICtrlRead($tl_custom_input))
				If $selection = "all" Then
					Local $verify_syntax = StringRegExp(Eval("ini_var"), "(\[[A-Za-z]+;%(?:[A-Za-z0-9]+\/?[A-Za-z0-9])+%\|\])", 3)
				Else
					Local $verify_syntax = StringRegExp(Eval("ini_var"), "(\[(?:[A-Za-z0-9]+\/?[A-Za-z0-9])+\])", 3)
				EndIf
				Local $secondary_verify = _StringBetween(Eval("ini_var"), "[", "]")
				If UBound($verify_syntax) = UBound($secondary_verify) Then
					If IniWrite($ini_file, "GUI", $key, Eval("ini_var")) = 1 Then
						MsgBox(64, "Saved", "The title cusomizations were saved successfully.", 10, $tl_custom_GUI)
					Else
						MsgBox(64, "Error", "Unable to save to Ini file." & @CRLF & @CRLF & "Please check write permissions to the folder." & @CRLF & @CRLF & $ini_file, 10, $tl_custom_GUI)
					EndIf
				Else
					MsgBox(16, "Icorrect syntax", 'The sytax of the line you are trying to save is wrong.' & @CRLF & @CRLF & "All placeholders must be enclosed with [ ] brackets." & @CRLF & @CRLF & "Please correct the syntax and save before closing the dialog.")
				EndIf
				$line_title = IniRead($ini_file, "GUI", "line_title", "")
				$line_video = IniRead($ini_file, "GUI", "line_video", "")
				$line_audio = IniRead($ini_file, "GUI", "line_audio", "")
				$line_text = IniRead($ini_file, "GUI", "line_text", "")

			Case $GUI_EVENT_RESIZED
				$gui_size = WinGetPos($title)
				If Not @error Then
					If $gui_size[2] < 430 Then
						WinMove($title, "", $gui_size[0], $gui_size[1], 430, $gui_size[3])
					EndIf
					If $gui_size[3] < 250 Then
						WinMove($title, "", $gui_size[0], $gui_size[1], $gui_size[2], 262)
					EndIf
				EndIf
				$ctrl_size = ControlGetPos("", "", "[CLASSNN:SysListView321]")
				If IsArray($ctrl_size) And IsArray($placeholders) Then
					If $placeholders[0][0] * 20 > $ctrl_size[3] Then
						_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, $ctrl_size[2] - 25)
					Else
						_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, $ctrl_size[2] - 5)
					EndIf
				EndIf
				GUICtrlSetData($tl_custom_input, GUICtrlRead($tl_custom_input))
		EndSwitch
	WEnd
EndFunc   ;==>__Edit_Title_GUI

Func __GUI_Msg($hFile)
	Local $nMsg
	Local $hHandle

	$nMsg = GUIGetMsg(1)

	Switch $nMsg[0]
		Case $open_mkvs
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Default Button=Second, Icon=Question
			If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
			$iMsgBoxAnswer = MsgBox(292, "Stop Processing ?", "Stop importing files ?")
			Select
				Case $iMsgBoxAnswer = 6 ;Yes
					_SQLite_QuerySingleRow($db, "select item_handle from sessions where file=" & __SQL_Escape($hFile) & ";", $hHandle)
					If IsPtr(GUICtrlGetHandle($hHandle[0])) Then _GUICtrlTreeView_Delete($file_list, $hHandle[0])
					_SQLite_Exec($db, "delete from child_handles where file=" & __SQL_Escape($hFile) & ";")
					_SQLite_Exec($db, "delete from sessions where file=" & __SQL_Escape($hFile) & ";")
					Return 1
				Case $iMsgBoxAnswer = 7 ;No
					Return 0
			EndSelect
			#EndRegion --- CodeWizard generated code Start ---
	EndSwitch
EndFunc   ;==>__GUI_Msg

Func __Clean_Path(ByRef $data)
	$data = StringReplace($data, "<", "")
	$data = StringReplace($data, ">", "")
	$data = StringReplace($data, ":", ".")
	$data = StringReplace($data, '"', "")
	$data = StringReplace($data, "\", "_")
	$data = StringReplace($data, "/", "_")
	$data = StringReplace($data, "|", "_")
	$data = StringReplace($data, "?", ".")
	$data = StringReplace($data, "*", ".")
EndFunc   ;==>__Clean_Path
