#Region While 1 Loop
While 1
	$nMsg = GUIGetMsg(1)
	If $nMsg[0] = $GUI_EVENT_NONE Then ContinueLoop
	$nMsg_handle = GUICtrlGetHandle($nMsg[0])
	$current = _GUICtrlTreeView_GetSelection($file_list)
	If $current <> $last_current Then
		_SQLite_QuerySingleRow($db, "select file from sessions where handle='" & $current & "';", $query_result)
		If $query_result[0] <> "" Then _GUICtrlStatusBar_SetText($statusbar, $query_result[0])
		$last_current = $current
	EndIf
	If $cancel = 1 Then $cancel = 0
	If $timer <> 0 And _Timer_Diff($timer) > 400 Then
		$timer = 0
		_Timer_KillTimer($GUI, $timer)
	EndIf
	Switch $nMsg[0]
		Case $GUI_EVENT_CLOSE
			If $nMsg[1] = $GUI Then Exit
			If $nMsg[1] = $about_gui Then
				GUISetState(@SW_ENABLE, $GUI)
				GUIDelete($about_gui)
				Sleep(50)
				WinActivate("MKVcleaver " & $version)
				$sheck_link = 0x1
				$autoit_link = 0x1
				$mediainfo_link = 0x1
				$avc2avi_link = 0x1
				$avdump_link = 0x1
				$mkvtoolnix_link = 0x1
				$ogmcleaver_link = 0x1
				$mkvcleaver_link = 0x1
				$nMsg = 0
				ContinueLoop
			EndIf
		Case $about
			$about_gui = GUICreate("About MKVcleaver", 277, 310, -1, -1)
			GUICtrlCreateGroup("", 9, 8, 260, 251)
			GUICtrlCreateGroup("", 14, 90, 250, 164)
			GUICtrlCreateLabel("Product Name : ", 98, 26, 80, 17, $WS_GROUP)
			$mkvcleaver_link = GUICtrlCreateLabel("MKVcleaver", 178, 26, 60, 17, $WS_GROUP)
			GUICtrlSetFont(-1, 8, 400, 4, "MS Sans Serif")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			GUICtrlCreateLabel("Version : " & $version & $bits, 98, 49, 136, 17, $WS_GROUP)
			GUICtrlCreateLabel("License : GPL v3", 98, 71, 148, 17, $WS_GROUP)
			$logo = GUICtrlCreatePic("", 17, 23, 71, 63)
			;_ResourceSetImageToCtrl($logo, "LOGO", $RT_BITMAP)
			_Resource_SetToCtrlID($logo, 'LOGO', $RT_BITMAP, @AutoItExe, False)
			GUICtrlCreateGroup("", -99, -99, 1, 1)
			GUICtrlCreateGroup("", -99, -99, 1, 1)
			GUICtrlCreateLabel("Author : Ilia Bakhmoutski", 17, 101, 130, 19)
			GUICtrlSetFont(-1, 9, 400, 0, "Times New Roman")
			$sheck_link = GUICtrlCreateLabel("(sheck)", 147, 101, 39, 19)
			GUICtrlSetFont(-1, 9, 400, 4, "Times New Roman")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			GUICtrlCreateLabel("Copyright : Ilia Bakhmoutski " & Chr(169) & " 2010-2018", 17, 118, 210, 19)
			GUICtrlSetFont(-1, 9, 400, 0, "Times New Roman")
			GUICtrlCreateLabel("Source Language : ", 17, 135, 92, 19)
			GUICtrlSetFont(-1, 9, 400, 0, "Times New Roman")
			$autoit_link = GUICtrlCreateLabel("AutoIt v3", 106, 135, 52, 19)
			GUICtrlSetFont(-1, 9, 400, 4, "Times New Roman")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			GUICtrlCreateLabel("Reference Tools : ", 17, 152, 91, 19)
			GUICtrlSetFont(-1, 9, 400, 0, "Times New Roman")
			$ogmcleaver_link = GUICtrlCreateLabel("OGMcleaver", 106, 152, 67, 19)
			GUICtrlSetFont(-1, 9, 400, 4, "Times New Roman")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			$hl = GUICtrlCreatePic("", 17, 175, 240, 2)
			;_ResourceSetImageToCtrl($hl, "LINE", $RT_BITMAP)
			_Resource_SetToCtrlID($hl, 'LINE', $RT_BITMAP, @AutoItExe, True)
			GUICtrlCreateLabel("Additional Tools Used : ", 17, 182, 123, 19)
			GUICtrlSetFont(-1, 9, 400, 0, "Times New Roman")
			$mediainfo_link = GUICtrlCreateLabel("MediaInfoDLL", 139, 182, 78, 19)
			GUICtrlSetFont(-1, 9, 400, 4, "Times New Roman")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			$avdump_link = GUICtrlCreateLabel("Avdump2", 139, 198, 47, 19)
			GUICtrlSetFont(-1, 9, 400, 4, "Times New Roman")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			$avc2avi_link = GUICtrlCreateLabel("Avc2Avi_mod", 139, 215, 75, 19)
			GUICtrlSetFont(-1, 9, 400, 4, "Times New Roman")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			$mkvtoolnix_link = GUICtrlCreateLabel("MkvToolNix", 139, 233, 68, 19)
			GUICtrlSetFont(-1, 9, 400, 4, "Times New Roman")
			GUICtrlSetColor(-1, 0x0000FF)
			GUICtrlSetCursor(-1, 0)
			GUICtrlCreateGroup("", -99, -99, 1, 1)
			$about_ok = GUICtrlCreateButton("&OK", 100, 271, 75, 25)
			GUISetState(@SW_SHOW)
			GUISetState(@SW_DISABLE, $GUI)
		Case $sheck_link
			ShellExecute("http://www.autoitscript.com/forum/index.php?showuser=9851")
			GUICtrlSetColor($sheck_link, 0xBA75FF)
		Case $autoit_link
			ShellExecute("http://www.autoitscript.com/autoit3/")
			GUICtrlSetColor($autoit_link, 0xBA75FF)
		Case $ogmcleaver_link
			ShellExecute("http://sites.google.com/site/ogmcleaver/")
			GUICtrlSetColor($ogmcleaver_link, 0xBA75FF)
		Case $mediainfo_link
			ShellExecute("http://mediainfo.sourceforge.net/en/Download/Windows")
			GUICtrlSetColor($mediainfo_link, 0xBA75FF)
		Case $avdump_link
			ShellExecute("http://wiki.anidb.info/w/Avdump2")
			GUICtrlSetColor($avdump_link, 0xBA75FF)
		Case $avc2avi_link
			ShellExecute("http://sourceforge.net/projects/avc2avi/")
			GUICtrlSetColor($avc2avi_link, 0xBA75FF)
		Case $mkvtoolnix_link
			ShellExecute("http://www.bunkus.org/videotools/mkvtoolnix/downloads.html")
			GUICtrlSetColor($mkvtoolnix_link, 0xBA75FF)
		Case $mkvcleaver_link
			ShellExecute("http://blogs.sapib.ca/apps/")
			GUICtrlSetColor($mkvcleaver_link, 0xBA75FF)
		Case $about_ok
			GUISetState(@SW_ENABLE, $GUI)
			GUIDelete($about_gui)
			Sleep(50)
			WinActivate("MKVcleaver " & $version)
		Case $online_help
			ShellExecute("http://blogs.sapib.ca/apps/mkvcleaver/mkvcleaver-how-to/")
		Case $help
			ShellExecute(@ScriptDir & "\MKVcleaver_help.chm")
		Case $online_forum
			ShellExecute("http://forum.doom9.org/showthread.php?t=152108")
		Case $email_me
			ShellExecute("mailto:sheck@sapib.ca")
		Case $donate
			ShellExecute("https://blogs.sapib.ca/apps/mkvcleaver/donations/")
		Case $send_to
			FileCreateShortcut(@AutoItExe, @UserProfileDir & "\SendTo\MKVCleaver.lnk", @ScriptDir, "", "Send mkv files to MKVcleaver", @AutoItExe, "", 0, @SW_SHOWNORMAL)
		Case $send_to_remove
			If @OSVersion = "WIN_XP" Or @OSVersion = "WIN_XPe" Or @OSVersion = "WIN_2000" Then
				FileDelete(@UserProfileDir & "\SendTo\MKVCleaver.lnk")
			ElseIf @OSVersion = "WIN_VISTA" Or @OSVersion = "WIN_7" Or @OSVersion = "WIN_8" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_10" Then
				FileDelete(@UserProfileDir & "\AppData\Roaming\Microsoft\Windows\SendTo\MKVCleaver.lnk")
			EndIf
		Case $open_log
			#Region View Log
			Local $log_lines = ""
			Local $iYear, $iMonth, $iDay
			Local $sql_query

			Local $filter = StringSplit($log_view_filter, ";")
			Switch $filter[2]
				Case "Days Old"
					Local $now = _DateToDayValue(@YEAR, @MON, @MDAY)
					_DayValueToDate($now - $filter[1], $iYear, $iMonth, $iDay)
					$sql_query = _SQLite_Query($db, "select * from log where date >= '" & $iYear & "-" & $iMonth & "-" & $iDay & "' order by date asc;", $query)
				Case "All"
					$sql_query = _SQLite_Query($db, "select * from log order by date asc;", $query)
				Case "This Session"
					$sql_query = _SQLite_Query($db, "select * from log where session='" & $session & "' order by date asc;", $query)
			EndSwitch
			If $sql_query = $SQLITE_LOCKED Or $sql_query = $SQLITE_BUSY Then
				MsgBox(4112, "Database Error", "Unable to write to the database due to an active transaction." & @CRLF & "" & @CRLF & "Please try again in a few seconds.", 10, $GUI)
				ContinueLoop
			EndIf
			While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
				Local $tab = ""
				For $a = 1 To $query_result[2]
					$tab &= @TAB
				Next
				If $query_result[3] = "Done" Or $query_result[3] = "Extraction Failed" Or $query_result[3] = "Extraction Started" Then $query_result[3] &= @CRLF
				If $query_result[3] = "Extraction finished" Or $query_result[3] = "Previous Session Crashed" Or $query_result[3] = "Restarting MKVCleaver" Or $query_result[3] = "Extraction was cancelled by the user." Or $query_result[3] = "Check the extracted files to see if they are usable" Then $query_result[3] &= @CRLF & @CRLF
				$log_lines &= $query_result[0] & ": " & $tab & $query_result[3] & @CRLF
			WEnd
			If $filter[2] <> "Days Old" Then $filter[1] = ""
			If $log_lines = "" Then $log_lines = "No results to display for the current filter."
			Local $log_gui = GUICreate("MKVCleaver Log | Filter: " & $filter[1] & " " & $filter[2], @DesktopWidth / 2, @DesktopHeight / 2, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_MDICHILD, $GUI)
			Local $log_lines_edit = GUICtrlCreateEdit($log_lines, 5, 5, @DesktopWidth / 2 - 10, @DesktopHeight / 2 - 10, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL), $WS_EX_CLIENTEDGE)
			GUICtrlSetBkColor(-1, 0x000000)
			GUISetBkColor(0x000000, $log_gui)
			GUICtrlSetFont($log_lines_edit, 10)
			GUICtrlSetColor($log_lines_edit, 0xffffff)
			GUISetState(@SW_SHOW)
			GUISetState(@SW_DISABLE, $GUI)
			Local $edit = _WinAPI_GetFocus()
			_GUICtrlEdit_SetSel($edit, -1, 0)
			Do
				$nMsg5 = GUIGetMsg(1)
				Switch $nMsg5[0]
					Case $GUI_EVENT_CLOSE
						If $nMsg5[1] = $log_gui Then
							GUISetState(@SW_ENABLE, $GUI)
							GUIDelete($log_gui)
							Sleep(50)
							WinActivate("MKVcleaver " & $version)
							ExitLoop
						Else
							Exit
						EndIf
				EndSwitch
			Until _IsPressed("1B")
			GUIDelete($log_gui)
			#EndRegion View Log
		Case $log_settings
			#Region Log Settings GUI
			Local $log_settings_gui = GUICreate("Log Settings", 320, 120, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_MDICHILD, $GUI)
			GUICtrlCreateLabel("Delete lines older than:", 20, 20, 110, 15, -1, -1)
			Local $log_keep_num = GUICtrlCreateInput("", 20, 37, 36, 21, $ES_NUMBER, $WS_EX_CLIENTEDGE)
			Local $log_keep_num_mod = GUICtrlCreateCombo("", 62, 37, 75, 21, $CBS_DROPDOWNLIST, -1)
			GUICtrlSetData(-1, "Years|Months|Days|Hours|Minutes|Seconds")
			GUICtrlCreateLabel("Filter Log Lines:", 168, 22, 75, 15, -1, -1)
			Local $log_view_num = GUICtrlCreateInput("", 168, 37, 36, 21, $ES_NUMBER, $WS_EX_CLIENTEDGE)
			Local $log_view_num_mod = GUICtrlCreateCombo("", 210, 37, 90, 21, $CBS_DROPDOWNLIST, -1)
			GUICtrlSetData(-1, "All|This Session|Days Old")
			Local $log_settings_save = GUICtrlCreateButton("Save", 210, 71, 90, 30, -1, -1)
			GUICtrlSetData($log_keep_num, StringLeft($max_log_age, StringLen($max_log_age) - 1))
			Switch StringRight($max_log_age, 1)
				Case "D"
					GUICtrlSetData($log_keep_num_mod, "Days")
				Case "M"
					GUICtrlSetData($log_keep_num_mod, "Months")
				Case "Y"
					GUICtrlSetData($log_keep_num_mod, "Years")
				Case "w"
					GUICtrlSetData($log_keep_num_mod, "Weeks")
				Case "h"
					GUICtrlSetData($log_keep_num_mod, "Hours")
				Case "n"
					GUICtrlSetData($log_keep_num_mod, "Minutes")
				Case "s"
					GUICtrlSetData($log_keep_num_mod, "Seconds")
			EndSwitch
			$log_view_filter = StringSplit($log_view_filter, ";")
			If IsArray($log_view_filter) Then
				GUICtrlSetData($log_view_num_mod, $log_view_filter[2])
				GUICtrlSetData($log_view_num, $log_view_filter[1])
				If $log_view_filter[2] = "All" Or $log_view_filter[2] = "This Session" Then
					GUICtrlSetState($log_view_num, $GUI_DISABLE)
				EndIf
			EndIf

			GUISetState(@SW_SHOW, $log_settings_gui)
			GUISetState(@SW_DISABLE, $GUI)

			While 1
				$nMsg5 = GUIGetMsg(1)
				Switch $nMsg5[0]
					Case $GUI_EVENT_CLOSE
						GUISetState(@SW_ENABLE, $GUI)
						GUIDelete($log_settings_gui)
						$log_view_filter = $log_view_filter[1] & ";" & $log_view_filter[2]
						Sleep(50)
						WinActivate("MKVcleaver " & $version)
						ExitLoop
					Case $log_view_num_mod
						Local $selection = GUICtrlRead($log_view_num_mod)
						If $selection = "All" Or $selection = "This Session" Then
							GUICtrlSetState($log_view_num, $GUI_DISABLE)
						Else
							GUICtrlSetState($log_view_num, $GUI_ENABLE)
						EndIf
					Case $log_settings_save
						Switch GUICtrlRead($log_keep_num_mod)
							Case "Days"
								Local $log_keep_num_mod = "D"
							Case "Months"
								Local $log_keep_num_mod = "M"
							Case "Years"
								Local $log_keep_num_mod = "Y"
							Case "Weeks"
								Local $log_keep_num_mod = "w"
							Case "Hours"
								Local $log_keep_num_mod = "h"
							Case "Minutes"
								Local $log_keep_num_mod = "n"
							Case "Seconds"
								Local $log_keep_num_mod = "s"
						EndSwitch
						$max_log_age = GUICtrlRead($log_keep_num) & $log_keep_num_mod
						$log_view_filter = GUICtrlRead($log_view_num) & ";" & GUICtrlRead($log_view_num_mod)
						GUISetState(@SW_ENABLE, $GUI)
						GUIDelete($log_settings_gui)
						Sleep(50)
						WinActivate("MKVcleaver " & $version)
						IniWrite($ini_file, "Files", "log_max_age", $max_log_age)
						IniWrite($ini_file, "Files", "log_view_filter", $log_view_filter)
						ExitLoop
				EndSwitch
			WEnd
			#EndRegion Log Settings GUI
		Case $update_menu_item
			ShellExecute("http://blogs.sapib.ca/apps/")
		Case $report_bugs
			ShellExecute("http://blogs.sapib.ca/apps/bugs-requests/")
			;do not put anything right after this case
		Case $GUI_EVENT_DROPPED
			ContinueCase
		Case $open_mkvs
			If $nMsg[0] = $open_mkvs Then
				$files = FileOpenDialog("Select Files To Open", "", "Matroska (*.mkv; *.mka; *.mks; *.webm)|All (*.*)", 7)
				If @error Then ContinueLoop
				GUICtrlSetData($open_mkvs, "Cancel Import")
				$file_array = StringSplit($files, "|")
				If UBound($file_array) - 1 > 1 Then
					$files = $file_array[1] & "\" & $file_array[2]
					For $a = 3 To UBound($file_array) - 1
						$files &= "|" & $file_array[1] & "\" & $file_array[$a]
						$nMsg2 = GUIGetMsg(1)
						If $nMsg2[0] = $open_mkvs Then
							#Region --- CodeWizard generated code Start ---
							;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Default Button=Second, Icon=Question
							If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
							$iMsgBoxAnswer = MsgBox(292, "Stop Processing ?", "Stop importing files ?")
							Select
								Case $iMsgBoxAnswer = 6 ;Yes
									GUICtrlSetData($open_mkvs, "Open MKV files to process...")
									_GUICtrlStatusBar_SetText($statusbar, "")
									ContinueLoop 2
								Case $iMsgBoxAnswer = 7 ;No

							EndSelect
							#EndRegion --- CodeWizard generated code Start ---
						EndIf
					Next
				EndIf
				$file_array = ""
			ElseIf $nMsg[0] = $GUI_EVENT_DROPPED Then
				If UBound($aDroppedFiles) - 1 = 1 And StringInStr($aDroppedFiles[1], ".txt") Then _FileReadToArray($aDroppedFiles[1], $aDroppedFiles)
				GUICtrlSetData($open_mkvs, "Cancel Import")
				For $a = 1 To UBound($aDroppedFiles) - 1
					Select
						Case StringInStr(FileGetAttrib($aDroppedFiles[$a]), "D")
							$file_array = _FileListToArray($aDroppedFiles[$a], "*.mk*", 1)
							If StringMid($aDroppedFiles[$a], StringLen($aDroppedFiles[$a]), 1) = "\" Then $aDroppedFiles[$a] = StringTrimRight($aDroppedFiles[$a], 1)
							If $file_array <> 0 Then
								$files &= "|" & $aDroppedFiles[$a] & "\" & $file_array[1]
								For $b = 2 To UBound($file_array) - 1
									$files &= "|" & $aDroppedFiles[$a] & "\" & $file_array[$b]
								Next
							EndIf
						Case Else
							$files &= "|" & $aDroppedFiles[$a]
					EndSelect
					$nMsg = GUIGetMsg(1)
					If $nMsg[0] = $open_mkvs Then
						#Region --- CodeWizard generated code Start ---
						;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Default Button=Second, Icon=Question
						If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
						$iMsgBoxAnswer = MsgBox(292, "Stop Processing ?", "Stop importing files ?")
						Select
							Case $iMsgBoxAnswer = 6 ;Yes
								GUICtrlSetData($open_mkvs, "Open MKV files to process...")
								_GUICtrlStatusBar_SetText($statusbar, "")
								ContinueLoop 2
							Case $iMsgBoxAnswer = 7 ;No

						EndSelect
						#EndRegion --- CodeWizard generated code Start ---
					EndIf
				Next
			EndIf
			_Add_Files($files, $file_list)
			GUICtrlSetData($open_mkvs, "Open MKV files to process...")
			_GUICtrlStatusBar_SetText($statusbar, "")
			$files = ""
			$nMsg[0] = 0
		Case $removemkvs
			_Remove_Files()
		Case $toolnix_path
			$dir_select = FileSelectFolder("Point to MKVToolNix Folder", "", 6, "")
			If @error Then ContinueLoop
			If StringMid($dir_select, StringLen($dir_select), 1) = "\" Then $dir_select = StringTrimRight($dir_select, 1)
			$mkvtlnix_path = $dir_select
			IniWrite($ini_file, "Mkvtlnix_Path", "path", $dir_select)
			If Not FileExists($mkvtlnix_path & "\mkvextract.exe") Or Not FileExists($mkvtlnix_path & "\mkvmerge.exe") Then
				MsgBox(48, "Warning", "Mkvextract.exe and/or Mkvmerge.exe was not found." & @CRLF & @CRLF & "Make sure that the path to the files is correct.")
				$no_toolnix = 1
				ContinueLoop
			EndIf
			$no_toolnix = 0
			_SQLite_QuerySingleRow($db, "select count(rowid) from child_handles where selected='True';", $query_result)
			_SQLite_QuerySingleRow($db, "select count(rowid) from batch_item_handles where selected='True';", $query_result2)
			If $query_result[0] > 0 Or $query_result2 > 0 Then GUICtrlSetState($go, $GUI_ENABLE)
			$mkvex_version = FileGetVersion($mkvtlnix_path & "\mkvextract.exe")
			$mkvex_version = StringReplace($mkvex_version, ".", "")
		Case $save_path
			$save_to = FileSelectFolder("Select Output Directory", "", 6, "")
			If @error Then ContinueLoop
			GUICtrlSetData($save_path_input, $save_to)
			IniWrite($ini_file, "Files", "dst_path", $save_to)
		Case $tc_with_tracks
			$no_execute = 0
			GUICtrlSetState($tc_with_tracks, $GUI_CHECKED)
			_SQLite_QuerySingleRow($db, "select item_handle from batch_item_handles where text='Timecodes';", $query_result)
			If IsArray($query_result) Then
				GUICtrlSetColor($query_result[0], 0x7b68ee)
			EndIf
			IniWrite($ini_file, "Files", "tc_tracks", "1")
		Case $tc_only
			$no_execute = 1
			GUICtrlSetState($tc_only, $GUI_CHECKED)
			_SQLite_QuerySingleRow($db, "select item_handle from batch_item_handles where text='Timecodes';", $query_result)
			If IsArray($query_result) Then
				GUICtrlSetColor($query_result[0], 0xff0000)
			EndIf
			IniWrite($ini_file, "Files", "tc_tracks", "0")
		Case $resize_on
			$resize_bit = 1
			GUICtrlSetState($resize_on, $GUI_CHECKED)
		Case $resize_off
			$resize_bit = 0
			GUICtrlSetState($resize_off, $GUI_CHECKED)
		Case $sd_off
			$sd = 0
			IniWrite($ini_file, "Shutdown Menu", "shutdown", 0)
		Case $sd_once
			$sd = 1
			IniWrite($ini_file, "Shutdown Menu", "shutdown", 1)
		Case $sd_on
			$sd = 2
			IniWrite($ini_file, "Shutdown Menu", "shutdown", 2)
		Case $vfr_quick
			$vfr_detect = 1
			GUICtrlSetState($vfr_quick, $GUI_CHECKED)
			IniWrite($ini_file, "Files", "vfr", 1)
			$vfr_mode = "Quick"
		Case $vfr_full
			$vfr_detect = 1
			GUICtrlSetState($vfr_full, $GUI_CHECKED)
			IniWrite($ini_file, "Files", "vfr", 2)
			$vfr_mode = "Full"
		Case $vfr_off
			$vfr_detect = 0
			GUICtrlSetState($vfr_off, $GUI_CHECKED)
			IniWrite($ini_file, "Files", "vfr", 0)
		Case $chapters_xml
			Local $chapters_switch = ""
			GUICtrlSetState($chapters_xml, $GUI_CHECKED)
			IniWrite($ini_file, "Files", "chapters_s", 0)
		Case $chapters_simple
			Local $chapters_switch = "-s"
			GUICtrlSetState($chapters_simple, $GUI_CHECKED)
			IniWrite($ini_file, "Files", "chapters_s", 1)
		Case $update_check
			$update_me = "1"
			GUICtrlSetState($update_check, $GUI_CHECKED)
			IniWrite($ini_file, "Updates", "Auto", "1")
		Case $update_not_check
			$update_me = "0"
			GUICtrlSetState($update_not_check, $GUI_CHECKED)
			IniWrite($ini_file, "Updates", "Auto", "0")
		Case $fn_custom
			GUICtrlSetState($file_list, $GUI_NODROPACCEPTED)
			_Custom_FileName()
			GUICtrlSetState($file_list, $GUI_DROPACCEPTED)
		Case $selection_mode
			GUICtrlSetState($file_list, $GUI_NODROPACCEPTED)
			_Extract_Filter()
			GUICtrlSetState($file_list, $GUI_DROPACCEPTED)
		Case $tropt_chk
			IniWrite($ini_file, "GUI", "fileopts", GUICtrlRead($tropt_chk))
		Case $tr_fn_chk
			GUICtrlSetState($tropt_chk, $GUI_DISABLE)
			IniWrite($ini_file, "GUI", "fileopts", GUICtrlRead($tropt_chk))
			IniWrite($ini_file, "GUI", "filename1", GUICtrlRead($tr_fn_chk))
			IniWrite($ini_file, "GUI", "filename2", GUICtrlRead($fn_tr_chk))
		Case $fn_tr_chk
			GUICtrlSetState($tropt_chk, $GUI_ENABLE)
			IniWrite($ini_file, "GUI", "fileopts", GUICtrlRead($tropt_chk))
			IniWrite($ini_file, "GUI", "filename2", GUICtrlRead($fn_tr_chk))
			IniWrite($ini_file, "GUI", "filename1", GUICtrlRead($tr_fn_chk))
		Case $cntoavi
			If GUICtrlRead($cntoavi) = $GUI_CHECKED Then
				GUICtrlSetState($vfrtocfr, $GUI_ENABLE)
				IniWrite($ini_file, "GUI", "aviconvert", GUICtrlRead($cntoavi))
				IniWrite($ini_file, "GUI", "vfrconvert", GUICtrlRead($vfrtocfr))
			Else
				GUICtrlSetState($vfrtocfr, $GUI_UNCHECKED)
				GUICtrlSetState($vfrtocfr, $GUI_DISABLE)
				IniWrite($ini_file, "GUI", "aviconvert", GUICtrlRead($cntoavi))
				IniWrite($ini_file, "GUI", "vfrconvert", GUICtrlRead($vfrtocfr))
			EndIf
		Case $vfrtocfr
			If GUICtrlRead($vfrtocfr) = $GUI_CHECKED Then MsgBox(4144, "Experimental", "This feature is experimental and may not always work.", 10, $GUI)
		Case $session_save
			GUICtrlSetState($session_save, $GUI_CHECKED)
			GUICtrlSetState($session_not_save, $GUI_UNCHECKED)
			Local $session_saver = 1
			IniWrite($ini_file, "GUI", "session", "1")
		Case $session_not_save
			GUICtrlSetState($session_not_save, $GUI_CHECKED)
			GUICtrlSetState($session_save, $GUI_UNCHECKED)
			Local $session_saver = 0
			IniWrite($ini_file, "GUI", "session", "0")
		Case $xml_converter
			If Not IsDeclared("fps_celltimes") Then Local $fps_celltimes
			$fps_celltimes = InputBox("Enter Frames Per Second", "Enter FPS for the final MPEG files.", "29.970", "", 200, 130)
			Select
				Case @error = 1 ;The Cancel button was pushed
					ContinueLoop
				Case @error = 3 ;The InputBox failed to open
					ContinueLoop
			EndSelect
			Local $xml_files = FileOpenDialog("Open MKV Chapter Files", "My Computer", "MKV XML (*.xml)", 7)
			If Not @error Then
				Local $xml_converter_gui = GUICreate("Xml2CellTimes", 490, 72)
				Local $xml_converter_progress = GUICtrlCreateProgress(16, 8, 457, 25)
				Local $xml_converter_status = GUICtrlCreateLabel("Test", 16, 40, 457, 25, $SS_CENTER)
				GUICtrlSetFont(-1, 6, 600, 0, "MS Sans Serif")
				GUICtrlSetColor(-1, 0x0000FF)
				GUISetState(@SW_SHOW)
				GUISetState(@SW_DISABLE, $GUI)
				If StringInStr($xml_files, "|") Then
					$xml_files = StringSplit($xml_files, "|")
					Local $parts = $xml_files[0]
					For $b = 2 To $xml_files[0]
						_XML2Celltimes($xml_files[1] & "\" & $xml_files[$b])
					Next
				Else
					Local $parts = 1
					Local $dummy_array = $xml_files
					Dim $xml_files[2] = ["", $dummy_array]
					Local $b = 1
					_XML2Celltimes($xml_files[1])
				EndIf
				GUISetState(@SW_ENABLE, $GUI)
				GUIDelete($xml_converter_gui)
				Sleep(50)
				WinActivate("MKVcleaver " & $version)
			EndIf
		Case $codec_get
			$codec_get_file = FileOpenDialog("Select a MKV file.", "My Computer", "Matroska Files (*.mkv; *.mka; *.mks; *.webm) | All Files (*.*)", 3)
			If @error Then ContinueLoop
			$file_format = __Get_MediaInfo($codec_get_file, $media_info_handle, "File;%Format%")
			If Not $file_format = "Matroska" Then
				MsgBox(48, "Wrong File Format", "File was not recognized as Matroska.")
				ContinueLoop
			EndIf

			Local $codec_get_gui = GUICreate("Codec List", 393, 367, -1, -1)
			GUICtrlCreateGroup("Codec List", 10, 12, 372, 342)
			$codec_list = GUICtrlCreateListView("Extension|Codec", 22, 33, 347, 267, BitOR($LVS_EDITLABELS, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS, $WS_VSCROLL), BitOR($WS_EX_CLIENTEDGE, $LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT))
			Local $codec_list_handle = GUICtrlGetHandle($codec_list)
			_GUICtrlListView_SetColumnWidth($codec_list_handle, 0, 342 / 2)
			_GUICtrlListView_SetColumnWidth($codec_list_handle, 1, 342 / 2)
			Local $codec_save = GUICtrlCreateButton("Save", 142, 312, 129, 29, $WS_GROUP)
			GUICtrlCreateGroup("", -99, -99, 1, 1)

			$v_codec = __Get_MediaInfo($codec_get_file, $media_info_handle, "Video;%CodecID%|")
			$v_codecs_string = StringSplit($v_codec, "|")
			For $a = 1 To UBound($v_codecs_string) - 1
				If $v_codecs_string[$a] <> "" And StringInStr(_GUICtrlListView_GetItemText($codec_list_handle, _GUICtrlListView_GetItemCount($codec_list_handle) - 1, 1), $v_codecs_string[$a]) = 0 Then
					Switch $v_codecs_string[$a]
						Case "XVID"
							$v_codecs_string[$a] = "V_MS/VFW/FOURCC, XVID"
					EndSwitch
					GUICtrlCreateListViewItem("|" & $v_codecs_string[$a], $codec_list)
				EndIf
			Next
			$a_codec = __Get_MediaInfo($codec_get_file, $media_info_handle, "Audio;%CodecID%|")
			$a_codecs_string = StringSplit($a_codec, "|")
			For $a = 1 To UBound($a_codecs_string) - 1
				If $a_codecs_string[$a] <> "" And StringInStr(_GUICtrlListView_GetItemText($codec_list_handle, _GUICtrlListView_GetItemCount($codec_list_handle) - 1, 1), $a_codecs_string[$a]) = 0 Then
					GUICtrlCreateListViewItem("|" & $a_codecs_string[$a], $codec_list)
				EndIf
			Next
			$s_codec = __Get_MediaInfo($codec_get_file, $media_info_handle, "Text;%CodecID%|")
			$s_codecs_string = StringSplit($s_codec, "|")
			For $a = 1 To UBound($s_codecs_string) - 1
				If $s_codecs_string[$a] <> "" And StringInStr(_GUICtrlListView_GetItemText($codec_list_handle, _GUICtrlListView_GetItemCount($codec_list_handle) - 1, 1), $s_codecs_string[$a]) = 0 Then
					GUICtrlCreateListViewItem("|" & $s_codecs_string[$a], $codec_list)
				EndIf
			Next
			GUISetState(@SW_SHOW)
			GUISetState(@SW_DISABLE, $GUI)
			While 1
				$nMsg3 = GUIGetMsg()
				$item = _GUICtrlListView_GetSelectedIndices($codec_list_handle, True)
				If $item[0] > 0 Then
					$new_ext = _GUICtrlListView_GetItemText($codec_list_handle, $item[1])
					If StringMid($new_ext, 1, 1) <> "." And $new_ext <> "" Then _GUICtrlListView_SetItemText($codec_list_handle, $item[1], "." & $new_ext)
				EndIf
				Select
					Case _IsPressed("0D")
						Sleep(100)
						If _GUICtrlListView_GetEditControl($codec_list_handle) = 0 And $z = 0 Then
							$item = _GUICtrlListView_GetSelectedIndices($codec_list_handle, True)
							GUIRegisterMsg($WM_NOTIFY, "__WM_NOTIFY")
							If $item[0] > 0 Then
								$ext = _GUICtrlListView_EditLabel($codec_list_handle, $item[1])
								$z = 1
							EndIf
						Else
							$z = 0
						EndIf
					Case _IsPressed("71")
						Sleep(100)
						If _GUICtrlListView_GetEditControl($codec_list_handle) = 0 And $z = 0 Then
							$item = _GUICtrlListView_GetSelectedIndices($codec_list_handle, True)
							GUIRegisterMsg($WM_NOTIFY, "__WM_NOTIFY")
							If $item[0] > 0 Then
								_GUICtrlListView_EditLabel($codec_list_handle, $item[1])
								$z = 1
							EndIf
						EndIf
					Case $nMsg3 = $GUI_EVENT_CLOSE
						GUISetState(@SW_ENABLE, $GUI)
						GUIDelete($codec_get_gui)
						Sleep(50)
						WinActivate("MKVcleaver " & $version)
						ExitLoop
					Case $nMsg3 = $codec_save
						For $a = 0 To _GUICtrlListView_GetItemCount($codec_list_handle) - 1
							If _GUICtrlListView_GetItemText($codec_list_handle, $a) <> "" Then
								IniWriteSection($ini_file, _GUICtrlListView_GetItemText($codec_list_handle, $a, 1), "extension=" & _GUICtrlListView_GetItemText($codec_list_handle, $a))
							EndIf
						Next
						GUISetState(@SW_ENABLE, $GUI)
						GUIDelete($codec_get_gui)
						Sleep(50)
						WinActivate("MKVcleaver " & $version)
						ExitLoop
				EndSelect
			WEnd
		Case $ext_edit
			If $ext_manage_gui <> "" Then GUIDelete($ext_manage_gui)
			Local $ext_manage_gui = GUICreate("Extension Editor", 317, 157, -1, -1, -1)
			Local $ext_group = GUICtrlCreateGroup("Edit Extensions", 7, 10, 303, 131)
			GUICtrlSetColor(-1, 0x0000FF)
			Local $codec_id = GUICtrlCreateCombo("", 21, 53, 130, 25)
			Local $ext = GUICtrlCreateCombo("", 169, 53, 130, 25)
			Local $save_ext = GUICtrlCreateButton("Save", 33, 93, 90, 26, $WS_GROUP)
			Local $codec_lab = GUICtrlCreateLabel("Codec", 21, 33, 35, 17)
			GUICtrlSetColor(-1, 0x0000FF)
			Local $ext_lab = GUICtrlCreateLabel("Extension", 169, 33, 50, 17)
			GUICtrlSetColor(-1, 0x0000FF)
			Local $ext_del = GUICtrlCreateButton("Delete", 193, 93, 90, 26, $WS_GROUP)
			Local $codec_array = IniReadSectionNames($ini_file)
			For $a = 1 To UBound($codec_array) - 1
				$ext_list_item = IniRead($ini_file, $codec_array[$a], "extension", "")
				If $ext_list_item <> "" Then
					_GUICtrlComboBox_AddString(GUICtrlGetHandle($codec_id), $codec_array[$a])
					_GUICtrlComboBox_AddString(GUICtrlGetHandle($ext), $ext_list_item)
				EndIf
			Next
			GUISetState(@SW_SHOW)
			GUISetState(@SW_DISABLE, $GUI)
			Local $hcodec_id = GUICtrlGetHandle($codec_id)
			Local $hext = GUICtrlGetHandle($ext)

			While 1
				$curr_codec = _GUICtrlComboBox_GetCurSel($hcodec_id)
				If $curr_codec <> $last_codec And $curr_codec <> -1 Then
					_GUICtrlComboBox_SetCurSel($hext, $curr_codec)
				EndIf
				$last_codec = $curr_codec
				$curr_ext = _GUICtrlComboBox_GetCurSel($hext)
				If $curr_ext <> $last_ext And $curr_ext <> -1 Then
					_GUICtrlComboBox_SetCurSel($hcodec_id, $curr_ext)
				EndIf
				$last_ext = $curr_ext
				Local $nMsg2 = GUIGetMsg()
				Switch $nMsg2
					Case $GUI_EVENT_CLOSE
						GUISetState(@SW_ENABLE, $GUI)
						GUIDelete($ext_manage_gui)
						Sleep(50)
						WinActivate("MKVcleaver " & $version)
						ExitLoop
					Case $save_ext
						Local $new_codec = _GUICtrlComboBox_GetEditText($hcodec_id)
						Local $new_ext = _GUICtrlComboBox_GetEditText($hext)
						If StringMid($new_ext, 1, 1) <> "." And $new_ext <> "" Then
							$new_ext = "." & $new_ext
						EndIf
						$find = _GUICtrlComboBox_FindString($hcodec_id, $new_codec)
						If $find = -1 Then
							_GUICtrlComboBox_AddString($hcodec_id, $new_codec)
							_GUICtrlComboBox_AddString($hext, $new_ext)
							_GUICtrlComboBox_SetEditText($hext, $new_ext)
						Else
							_GUICtrlComboBox_SetEditText($hext, $new_ext)
							_GUICtrlComboBox_DeleteString($hext, _GUICtrlComboBox_GetCurSel($hcodec_id))
							_GUICtrlComboBox_InsertString($hext, _GUICtrlComboBox_GetEditText($hext), _GUICtrlComboBox_GetCurSel($hcodec_id))
						EndIf
						If $new_ext <> "" Then IniWriteSection($ini_file, $new_codec, "extension=" & $new_ext)
					Case $ext_del
						IniDelete($ini_file, _GUICtrlComboBox_GetEditText($hcodec_id))
						_GUICtrlComboBox_DeleteString($hcodec_id, _GUICtrlComboBox_GetCurSel($hcodec_id))
						_GUICtrlComboBox_DeleteString($hext, _GUICtrlComboBox_GetCurSel($hext))
				EndSwitch
			WEnd
			#cs
				Case $mt_set
				#Region --- CodeWizard generated code Start ---
				;InputBox features: Title=Yes, Prompt=Yes, Default Text=Yes, Input Length=2, Mandatory, Width=300, Height=170
				If Not IsDeclared("sInputBoxAnswer") Then Local $sInputBoxAnswer
				$sInputBoxAnswer = InputBox("Multithreading Settings", "Enter the number of threads for MKVCleaver to run." & @CRLF & @CRLF & "Note: Setting the number too high can result in a hung or a very slow system.", "2", " M2", "300", "170", Default, Default)
				Select
				Case @error = 0 ;OK - The string returned is valid
				IniWrite($ini_file, "Multithreading", "Thread Count", $sInputBoxAnswer)
				$mt_state = $sInputBoxAnswer
				If $sInputBoxAnswer = 0 Then
				GUICtrlSetState($mt_off, $GUI_CHECKED)
				GUICtrlSetState($mt_set, $GUI_UNCHECKED)
				Else
				GUICtrlSetState($mt_off, $GUI_UNCHECKED)
				GUICtrlSetState($mt_set, $GUI_CHECKED)
				EndIf
				Case @error = 1 ;The Cancel button was pushed

				Case @error = 3 ;The InputBox failed to open

				EndSelect
				#EndRegion --- CodeWizard generated code Start ---
			#ce
		Case $file_list_menu_config
			_Custom_FileList_Config()
		Case $go
			_Extract()
		Case $GUI_EVENT_MAXIMIZE
			$maximize = 1
		Case $GUI_EVENT_RESTORE
			$maximize = 0
			;Case $GUI_EVENT_PRIMARYDOWN
		Case $file_list_menu_info
			;$cursor = GUIGetCursorInfo($GUI)
			;If $cursor[4] = $file_list Then
			$detect_item = _GUICtrlTreeView_GetSelection($file_list)
			If $detect_item <> 0 Then
				If _SQLite_QuerySingleRow($db, "select file from sessions where handle='" & $detect_item & "';", $query_result) <> $SQLITE_OK Then ContinueLoop
				Local $raw_data = __Get_MediaInfo($query_result[0], $media_info_handle, "inform")
				$raw_data = StringReplace($raw_data, "  ", "")
				$file_inform_gui = GUICreate("File Information", @DesktopWidth / 2, @DesktopHeight / 2, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_MDICHILD, $GUI)
				GUISetBkColor(0x000000)
				$file_inform = GUICtrlCreateEdit($raw_data, 5, 5, @DesktopWidth / 2 - 10, @DesktopHeight / 2 - 10, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL), $WS_EX_CLIENTEDGE)
				;GUICtrlSetColor(-1, 0x7b68ee)
				GUICtrlSetBkColor(-1, 0x000000)
				GUICtrlSetColor(-1, 0xFFFFFF)
				GUICtrlSetFont(-1, 9)
				GUISetState(@SW_SHOW)
				GUISetState(@SW_DISABLE, $GUI)
				Local $edit = _WinAPI_GetFocus()
				_GUICtrlEdit_SetSel($edit, -1, 0)
				Do
					$nMsg5 = GUIGetMsg(1)
					Switch $nMsg5[0]
						Case $GUI_EVENT_CLOSE
							If $nMsg5[1] = $file_inform_gui Then
								GUISetState(@SW_ENABLE, $GUI)
								GUIDelete($file_inform_gui)
								Sleep(50)
								WinActivate("MKVcleaver " & $version)
								ExitLoop
							Else
								Exit
							EndIf
					EndSwitch
				Until _IsPressed("1B")
				GUIDelete($file_inform_gui)
				_GUICtrlTreeView_SelectItem($file_list, $detect_item, $TVGN_CARET)
			EndIf
			;EndIf
		Case $DebugMenuItemOn
			GUICtrlSetState($DebugMenuItemOff, $GUI_UNCHECKED)
			GUICtrlSetState($DebugMenuItemOn, $GUI_CHECKED)
			IniWrite($ini_file, "Debug", "debug", 1)
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
			MsgBox(64, "Restart Required", "The new settings will be applied next time MKVCleaver is started.")
			#EndRegion --- CodeWizard generated code Start ---
		Case $DebugMenuItemOff
			GUICtrlSetState($DebugMenuItemOff, $GUI_CHECKED)
			GUICtrlSetState($DebugMenuItemOn, $GUI_UNCHECKED)
			IniWrite($ini_file, "Debug", "debug", 0)
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
			MsgBox(64, "Restart Required", "The new settings will be applied next time MKVCleaver is started.")
			#EndRegion --- CodeWizard generated code Start ---
		Case $GUI_EVENT_RESIZED
			$gui_size = WinGetPos("MKVcleaver " & $version)
			If $gui_size[2] < 747 Then
				WinMove("MKVcleaver " & $version, "", $gui_size[0], $gui_size[1], 747, $gui_size[3])
			EndIf
			If $gui_size[3] < 642 Then
				WinMove("MKVcleaver " & $version, "", $gui_size[0], $gui_size[1], $gui_size[2], 642)
			EndIf
	EndSwitch
	If $check_selected = 1 Then
		_SQLite_QuerySingleRow($db, "select count(rowid) from batch_item_handles where selected='True';", $query_result)
		_SQLite_QuerySingleRow($db, "select count(rowid) from child_handles where selected='True';", $query_result2)
		If $query_result[0] = 0 And $query_result2[0] = 0 Then
			GUICtrlSetState($go, $GUI_DISABLE)
		ElseIf $query_result[0] > 0 Or $query_result2[0] > 0 Then
			If $query_result[0] = 1 And _GUICtrlTreeView_GetChecked($tracklist, $timecodes) = True Then
				;do nothing
			Else
				GUICtrlSetState($go, $GUI_ENABLE)
			EndIf
		EndIf
		_SQLite_QuerySingleRow($db, "select count(rowid) from sessions where selected='True';", $query_result)
		If $query_result[0] = 0 Then
			GUICtrlSetState($removemkvs, $GUI_DISABLE)
		ElseIf $query_result[0] > 0 Then
			GUICtrlSetState($removemkvs, $GUI_ENABLE)
		EndIf
		$check_selected = 0
	EndIf

	If $nMsg[0] > 0 Then
		If _SQLite_QuerySingleRow($db, "select rowid from sessions where item_handle='" & $nMsg[0] & "';", $query_result) = $SQLITE_OK Then
			If $query_result[0] > 0 Then
				_SQLite_QuerySingleRow($db, "select count(selected) from sessions where selected='True';", $query_result)
				$state = _GUICtrlTreeView_GetChecked($file_list, $nMsg[0])
				_SQLite_QuerySingleRow($db, "select selected from sessions where item_handle='" & $nMsg[0] & "';", $query)
				Select
					Case $state = True And $query[0] = "True"
						ContinueLoop
					Case $state = False And $query[0] = "False"
						ContinueLoop
					Case $state = False And $query[0] = ""
						ContinueLoop
				EndSelect
				If _SQLite_Exec($db, "update sessions set selected='" & $state & "' where item_handle='" & $nMsg[0] & "';") = $SQLITE_OK Then
					Select
						Case $state = True And $query_result[0] = 0
							GUICtrlSetState($removemkvs, $GUI_ENABLE)
						Case $state = False And $query_result[0] = 1
							GUICtrlSetState($removemkvs, $GUI_DISABLE)
					EndSelect
				EndIf
				$last_nMsg = ""
				ContinueLoop
			EndIf
		EndIf

		If _SQLite_QuerySingleRow($db, "select rowid from batch_item_handles where item_handle='" & $nMsg[0] & "';", $query_result) = $SQLITE_OK Then
			If $query_result[0] > 0 Then
				_SQLite_QuerySingleRow($db, "select count(selected) from batch_item_handles where selected='True';", $query_result)
				$state = _GUICtrlTreeView_GetChecked($tracklist, $nMsg[0])
				_SQLite_QuerySingleRow($db, "select selected from batch_item_handles where item_handle='" & $nMsg[0] & "';", $query)
				Select
					Case $state = True And $query[0] = "True"
						ContinueLoop
					Case $state = False And $query[0] = "False"
						ContinueLoop
					Case $state = False And $query[0] = ""
						ContinueLoop
				EndSelect
				If _SQLite_Exec($db, "update batch_item_handles set selected='" & $state & "' where item_handle='" & $nMsg[0] & "';") = $SQLITE_OK Then
					_SQLite_QuerySingleRow($db, "select count(selected) from child_handles where selected='True';", $query_result2)
					Select
						Case $state = True And $query_result[0] = 0 And $query_result2[0] = 0 And $nMsg[0] <> $timecodes
							GUICtrlSetState($go, $GUI_ENABLE)
							$go_go = 1
						Case $state = True And $query_result[0] = 1 And $query_result2[0] = 0 And _GUICtrlTreeView_GetChecked($tracklist, $timecodes) = True
							GUICtrlSetState($go, $GUI_ENABLE)
							$go_go = 1
						Case $state = False And $query_result[0] = 2 And $query_result2[0] = 0 And _GUICtrlTreeView_GetChecked($tracklist, $timecodes) = True
							GUICtrlSetState($go, $GUI_DISABLE)
							$go_go = 0
						Case $state = False And $query_result[0] = 1 And $query_result2[0] = 0
							GUICtrlSetState($go, $GUI_DISABLE)
							$go_go = 0
					EndSelect
					$last_nMsg = ""
					ContinueLoop
				EndIf
			EndIf
		EndIf
		If _SQLite_QuerySingleRow($db, "select rowid from child_handles where handle='" & $nMsg_handle & "';", $query_result) = $SQLITE_OK Then
			If $query_result[0] > 0 Then
				_SQLite_QuerySingleRow($db, "select count(selected) from child_handles where selected='True';", $query_result)
				$state = _GUICtrlTreeView_GetChecked($file_list, $nMsg[0])
				_SQLite_QuerySingleRow($db, "select selected from child_handles where item_handle='" & $nMsg[0] & "';", $query)
				Select
					Case $state = True And $query[0] = "True"
						ContinueLoop
					Case $state = False And $query[0] = "False"
						ContinueLoop
					Case $state = False And $query[0] = ""
						ContinueLoop
				EndSelect
				If _SQLite_Exec($db, "update child_handles set selected='" & $state & "' where handle='" & $nMsg_handle & "';") = $SQLITE_OK Then
					_SQLite_QuerySingleRow($db, "select count(selected) from batch_item_handles where selected='True';", $query_result2)
					Select
						Case $state = True And $query_result[0] = 0 And $query_result2[0] = 0
							GUICtrlSetState($go, $GUI_ENABLE)
							$go_go = 1
						Case $state = False And $query_result[0] = 1 And $query_result2[0] = 0
							GUICtrlSetState($go, $GUI_DISABLE)
							$go_go = 0
					EndSelect
				EndIf
				$last_nMsg = ""
				ContinueLoop
			EndIf
		EndIf
	EndIf
WEnd
#EndRegion While 1 Loop
