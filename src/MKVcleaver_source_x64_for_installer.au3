#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=mkv.ico
#AutoIt3Wrapper_Outfile=MKVCleaver.exe
#AutoIt3Wrapper_Outfile_x64=MKVCleaver.exe
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=This application is freeware.
#AutoIt3Wrapper_Res_Description=Extract all/any tracks from MKV files.
#AutoIt3Wrapper_Res_Fileversion=0.8.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Ilia Bakhmoutski (sheck) 2010-2018
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_Run_After=C:\PROGRA~2\Autoit3\Scite\Autoit3Wrapper\ResourceHacker.exe -open "%out%" -save "%out%" -action add -res "%scriptdir%\mkv.bmp" -mask BITMAP,LOGO,0
#AutoIt3Wrapper_Run_After=C:\PROGRA~2\Autoit3\Scite\Autoit3Wrapper\ResourceHacker.exe -open "%out%" -save "%out%" -action add -res "%scriptdir%\line.bmp" -mask BITMAP,LINE,0
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo /rsln /debug
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs
	Copyright (C) 2010-2017  Ilia Bakhmoutski

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	3-rd party tools may have their own Copyright license and are not covered by this notice.
	By using MKVCleaver you also agree to any 3-rd party licenses.
#ce
;#AutoIt3Wrapper_Run_After==C:\PROGRA~2\Autoit3\Aut2Exe\upx.exe --best --compress-resources=0 "%out%"
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <GuiListView.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <array.au3>
#include <file.au3>
#include <TreeViewConstants.au3>
#include <GuiTreeView.au3>
#include <GuiStatusBar.au3>
#include <Misc.au3>
#include <string.au3>
#include <ResourcesEx.au3>
#include <Timers.au3>
#include <GuiComboBox.au3>
#include <GuiEdit.au3>
#include "itaskbarlist.au3"
#include <WinAPI.au3>
#include <ProgressConstants.au3>
#include "dig.au3"
#include "SQLite.au3"
#include "json.au3"
#include <ProcessConstants.au3>
#include <WinAPIProc.au3>
#include <WinAPISys.au3>
#include <WinAPIFiles.au3>
#include <GuiScrollBars.au3>
#include <GuiMenu.au3>
#include <Debug.au3>
#include "Variables.au3"

Opt("GUICloseOnESC", 0)
Opt("MustDeclareVars", 1)
AutoItSetOption("MouseCoordMode", 2)
OnAutoItExitRegister("__OnAutoItExit")
HotKeySet("^+a", "_Select_All")

If $debug = 1 Then
	_DebugSetup("MKVcleaver debug", True, 4, $working_dir & "\DebugLog.txt", True)
EndIf

If @Compiled Then
	If FileGetSize(@AutoItExe) > 2097152 Then
		HotKeySet("+!s", "_Source")
		;#include "portable.au3"
	EndIf
EndIf

For $a = 1 To 16
	$session &= Random(0, 9, 1)
Next

If Not FileExists($working_dir) Then DirCreate($working_dir)

$log_view_filter = IniRead($ini_file, "Files", "log_view_filter", $log_view_filter)
$max_log_age = IniRead($ini_file, "Files", "log_max_age", $max_log_age)
Local $log_rotated_last = IniRead($ini_file, "Files", "log_rotate_last_ran", _NowCalcDate())
Local $date_diff = _DateDiff(StringRight($max_log_age, 1), $log_rotated_last, _NowCalcDate())
If $date_diff >= StringLeft($max_log_age, StringLen($max_log_age) - 1) Or $log_rotated_last = _NowCalcDate() Or $log_rotated_last = "" Then
	Run(@ComSpec & ' /c "' & @ScriptDir & '\LogRotate.exe"', @ScriptDir, @SW_HIDE)
EndIf

#include "sqlite_commands.au3"

If __Tables_Create() = 1 Then
	MsgBox(16, "Database Error", "MKVCleaver cannot run without the database." & @CRLF & @CRLF & "Please contact the developer.")
	Exit
EndIf

If _SQLite_QuerySingleRow($db, "select pid from pid where rowid='1';", $query_result) = $SQLITE_OK Then
	If $query_result[0] <> "" Then
		$recovery = $query_result[0]
		If _Singleton("mkvcleaver", 1) = 0 Then
			MsgBox(16, "Instance Error", "Another instance of MKVCleaver is already running." & @CRLF & @CRLF & "There can be only one !!!")
			OnAutoItExitUnRegister("__OnAutoItExit")
			Exit
		EndIf
	EndIf
EndIf
_SQLite_Exec($db, "delete from pid;" & "insert into pid ('pid') values ('" & @AutoItPID & "');")

$version = FileGetVersion(@AutoItExe)
If @AutoItX64 Then
	$bits = " - 64 bit"
Else
	$bits = " - 32 bit"
EndIf

If $CmdLine[0] > 0 Then
	If $CmdLine[1] = "--help" Or $CmdLine[1] = "-h" Or $CmdLine[1] = "/?" Or $CmdLine[1] = "/h" Or $CmdLine[1] = "/help" Or $CmdLine[1] = "help" Then
		MsgBox(0, "CMD Help", "MKVcleaver - version " & $version & @CR & _
				"Copyright 2017 - Ilia Bakhmoutski" & @CR & @CR & _
				'Usage: MKVcleaver.exe "path\file1.mkv" ["path\file2.mkv"] [...]')
		Exit
	EndIf
EndIf

#include "GUI.au3"

Local $taskbar = _ITaskBar_CreateTaskBarObj()
If Not @error Then
	_ITaskBar_SetProgressState($GUI, 0)
	If @error Then _GUICtrlStatusBar_SetText($statusbar, "Error: Unable to set taskbar progress indicator.")
Else
	_GUICtrlStatusBar_SetText($statusbar, "Error: Unable to set taskbar progress indicator.")
EndIf

If _SQLite_Query($db, "SELECT file FROM 'sessions' order by rowid ASC;", $query) = $SQLITE_OK Then
	If _SQLite_FetchData($query, $query_result) = $SQLITE_OK Then
		_SQLite_QueryReset($query)
		If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
		If IniRead($ini_file, "GUI", "user_saved", "0") = 0 And $recovery <> "recover" Then
			__Log_Write("Previous Session Crashed", 0, $session)
			$iMsgBoxAnswer = MsgBox(292, "Session", "Previous job(s) was not complete due to a crash or an error." & @CRLF & @CRLF & "MKVCleaver can restore your previous session." & @CRLF & @CRLF & _
					"Would you like to restore your previous session ?")
		ElseIf IniRead($ini_file, "GUI", "user_saved", "0") = 1 And $recovery <> "recover" Then
			$iMsgBoxAnswer = MsgBox(292, "Session", "A saved session was found in the database." & @CRLF & @CRLF & "MKVCleaver can restore your previous session." & @CRLF & @CRLF & _
					"Would you like to restore your previous session ?")
		Else
			$iMsgBoxAnswer = 6
			__Log_Write("Previous Session Crashed", 0, $session)
		EndIf
		Select
			Case $iMsgBoxAnswer = 6 ;Yes
				$session_recover = 1
				_GUICtrlStatusBar_SetText($statusbar, "Restoring last session settings...")
				While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
					$files &= "|" & $query_result[0]
				WEnd
				_Add_Files($files, $file_list)
				$files = ""
				_SQLite_Query($db, "select item_handle from sessions where selected='True';", $query)
				While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
					_GUICtrlTreeView_SetChecked($file_list, $query_result[0])
				WEnd
				_SQLite_Query($db, "select item_handle from child_handles where selected='True';", $query)
				While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
					_GUICtrlTreeView_SetChecked($tracklist, $query_result[0])
				WEnd
				_SQLite_Query($db, "select item_handle from sessions;", $query)
				While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
					_SQLite_Exec($db, "update sessions set handle='" & GUICtrlGetHandle($query_result[0]) & "' where item_handle='" & $query_result[0] & "';")
				WEnd
				_SQLite_Query($db, "select item_handle from child_handles;", $query)
				While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
					_SQLite_Exec($db, "update child_handles set handle='" & GUICtrlGetHandle($query_result[0]) & "' where item_handle='" & $query_result[0] & "';")
				WEnd

				Local $temp_batch_item_handles, $rows, $columns
				_GUICtrlTreeView_BeginUpdate($tracklist)
				_SQLite_GetTable2d($db, "select selected,text from temp;", $temp_batch_item_handles, $rows, $columns)
				For $a = 1 To $rows
					If $temp_batch_item_handles[$a][0] = "True" Then
						_SQLite_Exec($db, "update batch_item_handles set 'selected'='True' where text='" & $temp_batch_item_handles[$a][1] & "';")
						If $temp_batch_item_handles[$a][1] = "Segments" Then $temp_batch_item_handles[$a][1] = "Segment UIDs"
						_SQLite_QuerySingleRow($db, "select item_handle from batch_item_handles where handle='" & _GUICtrlTreeView_FindItem($tracklist, $temp_batch_item_handles[$a][1]) & "';", $query_result)
						_GUICtrlTreeView_SetChecked($tracklist, $query_result[0], True)
						$go_go = 1
					EndIf
				Next

				$check_selected = 1
				_SQLite_Exec($db, "drop table temp;")
				_GUICtrlStatusBar_SetText($statusbar, "The last session is now restored.")
				_GUICtrlTreeView_EndUpdate($tracklist)
				If $recovery = "recover" Then
					_SQLite_QuerySingleRow($db, "select pid from pid where rowid='2';", $query_result)
					If $query_result[0] = "execute" Then _Extract()
				EndIf
			Case Else
				__Reset_DB($db)
		EndSelect
	EndIf
	$session_recover = 0
EndIf

IniWrite($ini_file, "GUI", "user_saved", "0")

If $CmdLine[0] > 0 Then
	For $a = 1 To $CmdLine[0]
		$files &= "|" & $CmdLine[$a]
	Next
	_Add_Files($files, $file_list)
	$files = ""
EndIf

#include "Internal_functions.au3"
#include "While_Loop1.au3"

Func _Extract()
	;set local variables
	Local $duplicates = ""
	Local $duplicates_found = 0
	Local $session_id = 0
	Local $item_handle
	Local $log_once = ""

	If $go_go = 0 Then Return
	If $go_go = 1 Then $go_go = 0

	Global $temp_db = _SQLite_Open()

	_SQLite_Exec($temp_db, "create table if not exists 'TEMP' ('key' varchar,'value' varchar);")

	;set up output directory
	$destination = GUICtrlRead($save_path_input)
	If StringMid($destination, StringLen($destination), 1) = "\" Then $destination = StringTrimRight($destination, 1)
	If Not FileExists($destination) And $destination <> "" Then
		If DirCreate($destination) = 0 Then
			MsgBox(16, "Error", 'Could not create "Output Directory"' & @CRLF & @CRLF & "Choose another place where to save the files.")
			Return
		EndIf
	EndIf
	;check dependancies
	If Not FileExists($mkvtlnix_path & "\mkvextract.exe") Or Not FileExists($mkvtlnix_path & "\mkvmerge.exe") Or $no_toolnix = 1 Then
		MsgBox(48, "Warning", "Mkvextract.exe and/or Mkvmerge.exe was not found." & @CRLF & @CRLF & "Make sure that the path to the files is correct.")
		$no_toolnix = 1
		Return
	EndIf

	If $mkvex_version < 17000 Then
		MsgBox(48, "Warning", "Mkvextract.exe on your system is out of date." & @CRLF & @CRLF & "Versions below 17 are not supported.")
		$no_toolnix = 1
		Return
	EndIf

	If $destination <> "" Then
		IniWrite($ini_file, "Files", "dst_path", $destination & "\")
	Else
		IniWrite($ini_file, "Files", "dst_path", "")
	EndIf
	;disable GUI elements during extraction
	GUICtrlSetState($file_list, $GUI_DISABLE)
	GUICtrlSetState($tracklist, $GUI_DISABLE)
	GUICtrlSetState($fn_tr_chk, $GUI_DISABLE)
	GUICtrlSetState($tropt_chk, $GUI_DISABLE)
	GUICtrlSetState($tr_fn_chk, $GUI_DISABLE)
	GUICtrlSetState($save_path_input, $GUI_DISABLE)
	GUICtrlSetState($open_mkvs, $GUI_DISABLE)
	GUICtrlSetState($removemkvs, $GUI_DISABLE)
	GUICtrlSetState($toolnix_path, $GUI_DISABLE)
	GUICtrlSetState($selection_mode, $GUI_DISABLE)
	GUICtrlSetState($menu, $GUI_DISABLE)
	GUICtrlSetState($help_menu, $GUI_DISABLE)
	GUICtrlSetState($tools_menu, $GUI_DISABLE)
	GUICtrlSetState($vfrtocfr, $GUI_DISABLE)
	GUICtrlSetState($fn_custom, $GUI_DISABLE)
	GUICtrlSetData($go, "CANCEL")
	;get max number of video, audio and subs tracks in any file
	Local $rows, $columns
	_SQLite_GetTable($db, "select file from sessions order by rowid ASC;", $query_result, $rows, $columns)
	If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
	Local $files_list = $query_result
	Local $files_list = $query_result
	_ArrayDelete($files_list, "0;1")
	$file_total = UBound($files_list)
	$cancel = 0
	;set multiplyer for progress calculations based on timecodes only option in GUI
	Select
		Case _GUICtrlTreeView_GetChecked($tracklist, $timecodes) = True And $no_execute = 0
			$multiplyer = 2
		Case Else
			$multiplyer = 1
	EndSelect
	;select first imte in GUI file list
	_GUICtrlTreeView_SelectItem($file_list, _GUICtrlTreeView_GetFirstItem($file_list), $TVGN_FIRSTVISIBLE)
	;set up or open log file
	__Log_Write("Extraction started", 0, $session)
	;get first file name on the GUI file list
	$item = _GUICtrlTreeView_GetFirstItem($file_list)

	;find duplicate files on the GUI list
	_SQLite_QuerySingleRow($db, "select display_text from sessions where handle='" & $item & "';", $query_result)
	_SQLite_QuerySingleRow($db, "select count(file) from sessions where file like " & __SQL_Escape("%" & $query_result[0] & "%") & ";", $query_result)
	If $query_result[0] > 1 And $destination <> "" Then
		$duplicates_found = 1
	Else
		$duplicates_found = 0
	EndIf
	;start extraction loop for all files on the GUI list
	Local $working_file
	For $working_file In $files_list
		;display error message to users about duplicte file names
		If $duplicates_found = 1 And $session_id = 0 Then
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Icon=Warning
			If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
			$iMsgBoxAnswer = MsgBox(52, "WARNING !", "You have multiple files with the same name added to the list." & @CRLF & @CRLF & _
					"Since the destination is a single directory, files with the same name may be overwritten." & @CRLF & @CRLF & "It is recommended to clear the Output Directory field." & _
					@CRLF & @CRLF & "Are you sure you want to continue ?")
			Select
				Case $iMsgBoxAnswer = 6 ;Yes
					$session_id = Random(10000, 1000000, 1)
				Case $iMsgBoxAnswer = 7 ;No
					_GUICtrlStatusBar_SetText($statusbar, "Extraction was cancelled by the user.")
					ExitLoop
			EndSelect
			#EndRegion --- CodeWizard generated code Start ---
		EndIf
		;user chose to continue or no duplicates found... start creating commands for mkvextract
		_SQLite_QuerySingleRow($db, "select item_handle from sessions where file=" & __SQL_Escape($working_file) & ";", $query_result)
		If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
		$item_handle = $query_result[0]
		$item = GUICtrlGetHandle($item_handle)
		_SQLite_QuerySingleRow($db, "select display_text from sessions where handle='" & $item & "';", $query_result2)
		If $debug = 1 Then _DebugReportVar("query result2[_extract]", $query_result2, Default, @ScriptLineNumber)
		__Log_Write("File: " & __SQL_Escape($query_result2[0]), 1, $session)
		_SQLite_QuerySingleRow($db, "select count(selected) from child_handles where file=" & __SQL_Escape($working_file) & ";", $query_result)
		If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
		_SQLite_QuerySingleRow($db, "select count(selected) from batch_item_handles where text like '%Video%' or text like '%Audio%' or text like '%Subtitle%';", $query_result2)
		If $debug = 1 Then _DebugReportVar("query result2[_extract]", $query_result2, Default, @ScriptLineNumber)
		If $query_result[0] > 0 Or $query_result2[0] > 0 Then
			If BitAND(GUICtrlRead($tc_with_tracks), $GUI_CHECKED) Then
				__Log_Write("Extracting Tracks", 1, $session)
			Else
				__Log_Write("Extracting Tracks (Timecodes Only Mode)", 1, $session)
			EndIf
		Else
			__Log_Write("Extracting Tracks", 1, $session)
			__Log_Write("Nothing Selected", 2, $session)
		EndIf
		_SQLite_Query($db, "select handle from child_handles where file=" & __SQL_Escape($working_file) & ";", $query)
		If $debug = 1 Then _DebugReportVar("query[_extract]", $query, Default, @ScriptLineNumber)
		While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
			;check if user checked any tracks for a given file and create a command for mkvexctract
			_SQLite_QuerySingleRow($db, "select selected from child_handles where handle='" & $query_result[0] & "';", $query_result2)
			If $debug = 1 Then _DebugReportVar("query result2[_extract]", $query_result2, Default, @ScriptLineNumber)
			If $query_result2[0] = "True" Then
				$command = __SaveFile_Make($item, $query_result[0])
				If $command <> -1 Then $cmd &= $command & "," & @CRLF
				If $cancel = 1 Then
					ExitLoop 2
				EndIf
			EndIf
		WEnd
		;if user hasn't checked any tracks for a given file create a different command for mkvextract based on general track type
		If $cmd = "" Then
			_SQLite_QuerySingleRow($db, "select handle from batch_item_handles where rowid='1';", $query_result)
			If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
			$tracklist_item = $query_result[0]
			For $c = 1 To _GUICtrlTreeView_GetCount($tracklist) - 6
				_SQLite_QuerySingleRow($db, "select selected from batch_item_handles where handle='" & $tracklist_item & "';", $query_result)
				If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
				If $query_result[0] = "True" Then
					$command = __SaveFile_Make($item, "")
					If $cancel = 1 Then
						ExitLoop 2
					EndIf
					If $command <> -1 Then $cmd &= $command & "," & @CRLF
				EndIf
				_SQLite_QuerySingleRow($db, "select handle from batch_item_handles where rowid='" & $c + 1 & "';", $query_result)
				If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
				$tracklist_item = $query_result[0]
			Next
		EndIf
		$call += 1
		_SQLite_QuerySingleRow($db, "select selected from batch_item_handles where text='Timecodes';", $query_result)
		If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
		Select
			;set up full track extraction and time codes
			Case $cmd <> "" And $no_execute = 0
				$full_exec = 1
				;same as above, but based on different options in GUI (user selected tracks for a given file, timecodes are not selected on the general track list, timecodes only option is selected in GUI)
			Case $cmd <> "" And $query_result[0] <> "True" And $no_execute = 1
				$full_exec = 1
				;only extract time codes
			Case Else
				$full_exec = 0
		EndSelect
		;generate track extraction commands for mkvextract
		_SQLite_QuerySingleRow($db, "select file from sessions where handle='" & $item & "';", $query_result)
		If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
		If $full_exec = 1 Then
			$command_file = FileOpen($working_dir & "\mkv_cmd1.json", 266)
			FileWrite($command_file, "[" & @CRLF & '"' & StringReplace($query_result[0], "\", "\\") & '",' & @CRLF & '"tracks",' & @CRLF & StringReplace($cmd, ",", "", -1) & "]")
			FileClose($command_file)
			;execute track extraction
			__Log_Write("Extraction result", 1, $session)
			If __Statusbar_Update(__Execute()) = 0 Then ExitLoop
		EndIf
		$std = ""
		;code to extract extras timecodes, attachments, cuesheets, chapters, tags
		_SQLite_Query($db, "select text from batch_item_handles where selected='True';", $query)
		If $debug = 1 Then _DebugReportVar("query[_extract]", $query, Default, @ScriptLineNumber)
		While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
			If $query_result[0] = "Timecodes" Or $query_result[0] = "Attachments" Or $query_result[0] = "Cuesheets" Or $query_result[0] = "Chapters" Or $query_result[0] = "Tags" Or $query_result[0] = "Segments" Then
				If $log_once = "" Then
					__Log_Write("Extracting Items", 1, $session)
					$log_once = $session
				EndIf
			EndIf
			If $query_result[0] = "Timecodes" And $full_exec = 0 Then
				;Do Nothing
			Else
				_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				__Set_Progress()
			EndIf
			If $query_result[0] = "Timecodes" Then
				If __SaveFile_Make($item, "timecodes") = 0 Then
					_SQLite_QueryFinalize($query)
					ExitLoop 2
				EndIf
				_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				__Set_Progress()
			EndIf
			If $query_result[0] = "Attachments" Then
				If __SaveFile_Make($item, "attachments") = 0 Then
					_SQLite_QueryFinalize($query)
					ExitLoop 2
				EndIf
				_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				__Set_Progress()
			EndIf
			If $query_result[0] = "Cuesheets" Then
				If __SaveFile_Make($item, "cuesheets") = 0 Then
					_SQLite_QueryFinalize($query)
					ExitLoop 2
				EndIf
				_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				__Set_Progress()
			EndIf
			If $query_result[0] = "Chapters" Then
				If __SaveFile_Make($item, "Chapters") = 0 Then
					_SQLite_QueryFinalize($query)
					ExitLoop 2
				EndIf
				_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				__Set_Progress()
			EndIf
			If $query_result[0] = "Tags" Then
				If __SaveFile_Make($item, "Tags") = 0 Then
					_SQLite_QueryFinalize($query)
					ExitLoop 2
				EndIf
				_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				__Set_Progress()
			EndIf
			If $query_result[0] = "Segments" Then
				If __SaveFile_Make($item, "Segments") = 0 Then
					_SQLite_QueryFinalize($query)
					ExitLoop 2
				EndIf
				_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
				__Set_Progress()
			EndIf
		WEnd
		;convert h264 to avi
		#Region avc2avi
		If $h264 <> "" And GUICtrlRead($cntoavi) = $GUI_CHECKED And $no_execute = 0 And $last_error_count = $error_count Then
			Local $utf_convert = 0
			_GUICtrlStatusBar_SetText($statusbar, "Converting H264 track to AVI (This may take a long time, please be patient).")
			_SQLite_QuerySingleRow($db, "select file from sessions where handle='" & $item & "';", $query_result)
			If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
			$fps = __Get_MediaInfo($query_result[0], $media_info_handle, "FrameRate", $track_num - 1, $track_type)
			If $debug = 1 Then _DebugReportVar("media info[_extract]", $fps, Default, @ScriptLineNumber)
			If $fps = "" Then $fps = 30
			$h264 = StringSplit($h264, "/")
			If $debug = 1 Then _DebugReportVar("h264[_extract]", $h264, Default, @ScriptLineNumber)
			If Not IsArray($h264) Then
				__Log_Write("Skipping conversion to AVI due to empty file path", 1, $session)
			Else
				For $d = 2 To UBound($h264) - 1
					__Log_Write("Converting h264 track to AVI", 1, $session)
					If Not StringIsASCII($h264[$d]) Then
						$utf_convert = 1
						Local $utf_name = $h264[$d]
						_PathSplit($h264[$d], $szDrive, $szDir, $szFName, $szExt)
						Local $hex_fname = _StringToHex($szFName)
						FileMove($h264[$d], @TempDir & "\" & $hex_fname & $szExt, 1)
						;$h264[$d] = _PathMake($szDrive, $szDir, $hex_fname, $szExt)
						$h264[$d] = @TempDir & "\" & $hex_fname & $szExt
					EndIf
					$execute = Run(@ComSpec & " /c avc2avi" & " -f " & $fps & " -i " & '"' & $h264[$d] & '"' & " -o " & '"' & StringTrimRight($h264[$d], 5) & ".avi" & '"', @ScriptDir, @SW_HIDE, $STDERR_MERGED)
					If __Statusbar_Update($execute) = 0 Then ExitLoop 2
					If @error Then
						$error_log &= "Error code: " & @extended & @CRLF
						__Log_Write("(error)", 3, $session)
						$error_count += 1
					Else
						$output = ".avi"
					EndIf
					If $utf_convert = 1 Then
						FileMove($h264[$d], _PathMake($szDrive, $szDir, $szFName, $szExt), 1)
						FileMove(StringTrimRight($h264[$d], 5) & ".avi", _PathMake($szDrive, $szDir, $szFName, ".avi"), 1)
					EndIf
				Next
			EndIf
		ElseIf $h264 = "" And GUICtrlRead($cntoavi) = $GUI_CHECKED And $no_execute = 0 And $last_error_count = $error_count Then
			_SQLite_QuerySingleRow($db, "select selected from sessions where handle='" & $item & "';", $query_result)
			If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
			If $query_result[0] = "True" Then
				__Log_Write("Codec is not V_MPEG4/ISO/AVC. Not converting to AVI", 1, $session)
			EndIf
		EndIf
		#EndRegion avc2avi

		If GUICtrlRead($vfrtocfr) = $GUI_CHECKED And GUICtrlRead($cntoavi) = $GUI_UNCHECKED Then GUICtrlSetState($vfrtocfr, $GUI_UNCHECKED)

		If GUICtrlRead($vfrtocfr) = $GUI_CHECKED And $vfr > 0 And $vfrconv <> "" And GUICtrlRead($cntoavi) = $GUI_CHECKED Then
			_GUICtrlStatusBar_SetText($statusbar, "Converting VFR video to CFR (This may take a long time, please be patient).")
			$vfrconv = StringSplit($vfrconv, "/")
			If Not IsArray($vfrconv) Then
				__Log_Write("Skipping conversion to CFR due to empty file path", 1, $session)
			Else
				For $d = 2 To UBound($vfrconv) - 1
					__Log_Write("Converting VFR AVI to CFR AVI", 1, $session)
					$fn_custom_formula = IniRead($ini_file, "Files", "custom_filename", "")
					If $fn_custom_formula <> "" Then
						Local $paths = StringSplit($vfrconv[$d], "|")

						If Not StringIsASCII($paths[1]) Or Not StringIsASCII($paths[2]) Then
							$utf_convert = 1
							Local $utf_name1 = $paths[1]
							Local $utf_name2 = $paths[2]
							_PathSplit($paths[1] & ".avi", $szDrive, $szDir, $szFName, $szExt)
							Local $hex_fname1 = _StringToHex($szFName)
							FileMove($paths[1] & $szExt, @TempDir & "\" & $hex_fname1 & $szExt, 1)
							$paths[1] = @TempDir & "\" & $hex_fname1
							_PathSplit($paths[2] & "_Timecodes_cfr.txt", $szDrive, $szDir, $szFName, $szExt)
							Local $hex_fname2 = _StringToHex($szFName)
							FileMove($paths[2] & "_Timecodes_cfr.txt", @TempDir & "\" & $hex_fname2 & $szExt, 1)
							$paths[2] = @TempDir & "\" & $hex_fname2 & $szExt
						Else
							$paths[2] = $paths[2] & "_Timecodes_cfr.txt"
						EndIf

						$execute = Run(@ComSpec & ' /c tc2cfr 120000/1001 "' & $paths[1] & '.avi" "' & $paths[2] & '" "' & $paths[1] & '_cfr.avi"', @ScriptDir, @SW_HIDE, $STDERR_MERGED)
					Else
						If Not StringIsASCII($vfrconv[$d]) Then
							Local $utf_convert = 1
							Local $utf_name = $vfrconv[$d]
							_PathSplit($utf_name & ".avi", $szDrive, $szDir, $szFName, $szExt)
							Local $hex_fname = _StringToHex($szFName)
							FileMove($vfrconv[$d] & ".avi", @TempDir & "\" & $hex_fname & $szExt, 1)
							FileMove($vfrconv[$d] & "_Timecodes_cfr.txt", @TempDir & "\" & $hex_fname & "txt", 1)
							$vfrconv[$d] = @TempDir & "\" & $hex_fname
						EndIf
						$execute = Run(@ComSpec & ' /c tc2cfr 120000/1001 "' & $vfrconv[$d] & '".avi "' & $vfrconv[$d] & '.txt" "' & $vfrconv[$d] & '_cfr.avi"', @ScriptDir, @SW_HIDE, $STDERR_MERGED)
					EndIf
					If __Statusbar_Update($execute) = 0 Then ExitLoop 2
					If @error Then
						$error_log &= "Error code: " & @extended & @CRLF
						__Log_Write("(error)", 3, $session)
						$error_count += 1
					EndIf
					If $fn_custom_formula <> "" And $utf_convert = 1 Then
						FileMove($paths[1] & ".avi", $utf_name1 & ".avi", 1)
						FileMove($paths[1] & "_cfr.avi", $utf_name1 & "_cfr.avi", 1)
						FileMove($paths[2], $utf_name2 & "_Timecodes_cfr.txt", 1)
					ElseIf $fn_custom_formula = "" And $utf_convert = 1 Then
						FileMove($vfrconv[$d] & ".avi", $utf_name & ".avi", 1)
						FileMove($vfrconv[$d] & "_cfr.avi", $utf_name & "_cfr.avi", 1)
						FileMove($vfrconv[$d] & ".txt", $utf_name & "_Timecodes_cfr.txt", 1)
					EndIf
				Next
			EndIf
		EndIf

		_GUICtrlStatusBar_SetText($statusbar, "Progress: --%" & " | Overall Progress: " & Int((100 / ($file_total * $multiplyer)) + (100 / ($file_total * $multiplyer)) * ($call - 1)) & "%")
		__Set_Progress()
		;start cleanup after extraction and prepare to extract from next file
		_SQLite_Exec($db, "delete from sessions where handle='" & $item & "';")
		_GUICtrlTreeView_Delete($file_list, $item_handle)
		$cmd = ""
		$cmd2 = ""
		$cmd3 = ""
		$continue = 0
		$h264 = ""
		$vfr = 0
		$vfrconv = ""
		$std_mkvm = ""
		If $error_count > $last_error_count Then
			__Log_Write(StringReplace($error_log, "#GUI#error ", "Error: "), 1, $session)
			__Log_Write("Extraction failed", 1, $session)
		ElseIf $warning_count > $last_warning_count Then
			__Log_Write(StringReplace($warning_log, "#GUI#warning ", "Warning: "), 1, $session)
			__Log_Write("Check the extracted files to see if they are usable", 1, $session)
		Else
			__Log_Write("Done", 1, $session)
		EndIf
		$last_error_count = $error_count
		$last_warning_count = $warning_count
		$error_log = ""
		$log_once = ""
		_SQLite_Exec($temp_db, "delete from TEMP;")
	Next
	;post exctraction processes
	_SQLite_QuerySingleRow($db, "select count(file) from sessions;", $query_result)
	If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
	If $query_result[0] = 0 Then
		GUICtrlSetState($removemkvs, $GUI_DISABLE)
		GUICtrlSetState($go, $GUI_DISABLE)
		_GUICtrlTreeView_DeleteAll($tracklist)
		;Local $v_max[1], $a_max[1], $s_max[1], $track_db[1][2]
		_GUICtrlStatusBar_SetText($statusbar, "")
		If $sd = 1 Then
			IniWrite($ini_file, "Shutdown Menu", "shutdown", 0)
			__Log_Write("Extraction finished", 0, $session)
			__Log_Write("Shutting computer down", 0, $session)
			Shutdown(29)
			Exit
		ElseIf $sd = 2 Then
			__Log_Write("Extraction finished", 0, $session)
			__Log_Write("Shutting computer down", 0, $session)
			Shutdown(29)
			Exit
		EndIf
	ElseIf $query_result[0] > 0 Then
		$text = _GUICtrlStatusBar_GetText($statusbar, 0)
		__TrackCount_Update()
		_GUICtrlStatusBar_SetText($statusbar, $text)
	EndIf
	;If IsObj($oTB3) Then $oTB3.SetProgressState($GUI_Number, $TBPF_NOPROGRESS)
	_ITaskBar_SetProgressState($GUI, 0)
	GUICtrlSetData($go, "Extract Tracks !")
	GUICtrlSetState($file_list, $GUI_ENABLE)
	GUICtrlSetState($tracklist, $GUI_ENABLE)
	If IniRead($ini_file, "Files", "custom_filename", "") = "" Then
		GUICtrlSetState($fn_tr_chk, $GUI_ENABLE)
		If GUICtrlRead($fn_tr_chk) = $GUI_CHECKED Then GUICtrlSetState($tropt_chk, $GUI_ENABLE)
		GUICtrlSetState($tr_fn_chk, $GUI_ENABLE)
	EndIf
	GUICtrlSetState($save_path_input, $GUI_ENABLE)
	GUICtrlSetState($open_mkvs, $GUI_ENABLE)
	GUICtrlSetState($removemkvs, $GUI_ENABLE)
	GUICtrlSetState($toolnix_path, $GUI_ENABLE)
	GUICtrlSetState($selection_mode, $GUI_ENABLE)
	GUICtrlSetState($menu, $GUI_ENABLE)
	GUICtrlSetState($help_menu, $GUI_ENABLE)
	GUICtrlSetState($tools_menu, $GUI_ENABLE)
	GUICtrlSetState($fn_custom, $GUI_ENABLE)
	GUICtrlSetState($cntoavi, $GUI_ENABLE)
	If GUICtrlRead($cntoavi) = $GUI_CHECKED Then GUICtrlSetState($vfrtocfr, $GUI_ENABLE)
	$cmd = ""
	$cmd2 = ""
	$cmd3 = ""
	$call = 0
	$continue = 0
	$h264 = ""
	$std_mkvm = ""
	_SQLite_QuerySingleRow($db, "select count(rowid) from sessions where selected='True';", $query_result)
	If $debug = 1 Then _DebugReportVar("query result[_extract]", $query_result, Default, @ScriptLineNumber)
	If $query_result[0] > 0 Then
		GUICtrlSetState($removemkvs, $GUI_ENABLE)
	ElseIf $query_result[0] = 0 Then
		GUICtrlSetState($removemkvs, $GUI_DISABLE)
	EndIf
	If StringInStr(_GUICtrlStatusBar_GetText($statusbar, 0), "Extraction was cancelled by the user.") = 0 Then
		If $error_count = 0 And $warning_count = 0 Then
			_GUICtrlStatusBar_SetText($statusbar, "Extraction finished successfully.")
			__Log_Write("Extraction finished", 0, $session)
		Else
			_GUICtrlStatusBar_SetText($statusbar, "Errors and/or Warnings were encountered.")
			__Log_Write("Extraction finished", 0, $session)
		EndIf
	Else
		If $error_count > $last_error_count Then
			__Log_Write($error_log, 1, $session)
			__Log_Write("Extraction failed", 1, $session)
		ElseIf $warning_count > $last_warning_count Then
			__Log_Write($warning_log, 1, $session)
			__Log_Write("Check the extracted files to see if they are usable", 1, $session)
		EndIf
		__Log_Write("Extraction was cancelled by the user.", 0, $session)
	EndIf
	If $error_count > 0 Then MsgBox(16, "Error", "Errors were encountered while extracting tracks." & @CRLF & @CRLF & "See the log file for details.")
	If $warning_count > 0 Then MsgBox(48, "Warning", "Warnings were encountered while extracting tracks." & @CRLF & @CRLF & "See the log file for details.")
	$error_count = 0
	$warning_count = 0
	$last_error_count = 0
	$last_warning_count = 0
	GUICtrlSetData($progress1, 0)
	GUICtrlSetData($progress2, 0)
	_SQLite_QueryFinalize($query)
	_SQLite_Close($temp_db)
EndFunc   ;==>_Extract

Func _Select_All()
	Local $rows, $columns

	_SQLite_GetTable($db, "select item_handle from sessions;", $query_result, $rows, $columns)
	_ArrayDelete($query_result, "1")
	If $all_checked = 0 Then
		For $a = 1 To UBound($query_result) - 1
			_GUICtrlTreeView_SetChecked($file_list, $query_result[$a], True)
			_SQLite_Exec($db, "update sessions set selected='True' where item_handle='" & $query_result[$a] & "';")
		Next
		$all_checked = 1
		GUICtrlSetState($removemkvs, $GUI_ENABLE)
	Else
		For $a = 1 To UBound($query_result) - 1
			_GUICtrlTreeView_SetChecked($file_list, $query_result[$a], False)
			_SQLite_Exec($db, "update sessions set selected='False' where item_handle='" & $query_result[$a] & "';")
		Next
		$all_checked = 0
		GUICtrlSetState($removemkvs, $GUI_DISABLE)
	EndIf
EndFunc   ;==>_Select_All

Func _Add_Files($files, ByRef $tv_ctrl_id, $full_proc = 1)
	Local $sql_query
	Local $a_lng_string = "", $s_lng_String = ""
	Local $line_title_mod

	If $debug = 1 Then _DebugReportVar("full_proc[_add_files]", $full_proc, Default, @ScriptLineNumber)
	If $full_proc = 1 Then
		$sql_query = _SQLite_Exec($db, "SELECT name FROM sqlite_master WHERE type='table' AND name='sessions';" & _
				"SELECT name FROM sqlite_master WHERE type='table' AND name='child_handles';")
		If $debug = 1 Then _DebugReportVar("sql_query[_add_files]", $sql_query, Default, @ScriptLineNumber)
		If $sql_query <> $SQLITE_OK Then
			__Reset_DB($db)
			If @error Then
				MsgBox(4112, "Database Error", "Unable to write to the database due to an active transaction." & @CRLF & "" & @CRLF & "Please try again in a few seconds.", 10)
				Return
			EndIf
		EndIf
	EndIf

	If $files = "" Then Return
	If StringMid($files, 1, 1) = "|" Then $files = StringTrimLeft($files, 1)
	$files = StringSplit($files, "|")
	If $debug = 1 Then _DebugReportVar("files[_add_files]", $files, Default, @ScriptLineNumber)
	If $full_proc = 1 Then
		If $session_recover = 0 Then _ArraySort($files, 0, 1, 0)
		_GUICtrlTreeView_DeleteAll($tracklist)
		If $session_recover = 0 Then _GUICtrlStatusBar_SetText($statusbar, "Opening MKV Files...")
	EndIf
	Local $childID
	Local $query_result
	GUICtrlSetData($open_mkvs, "Cancel Import")
	For $z = 1 To UBound($files) - 1
		If __GUI_Msg($files[$z]) = 1 Then ExitLoop
		$full_path = $files[$z]
		$split_path = _PathSplit($files[$z], $szDrive, $szDir, $szFName, $szExt)
		_PathSplit(__SQL_Escape($files[$z]), $szDrive, $szDir, $szFName, $szExt)
		;check if file exists in db and add to db if it doesn't
		$sql_query = _SQLite_QuerySingleRow($db, "SELECT rowid FROM sessions WHERE file=" & __SQL_Escape($files[$z]) & ";", $query_result)
		If $debug = 1 Then _DebugReportVar("sql_query[_add_files]", $sql_query, Default, @ScriptLineNumber)
		If $sql_query = $SQLITE_OK And $session_recover = 0 Then ContinueLoop
		$file_format = __Get_MediaInfo($files[$z], $media_info_handle, "General;%Format%")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $file_format, Default, @ScriptLineNumber)
		If Not StringInStr($file_format, "Matroska") And Not StringInStr($file_format, "WebM") Then
			$omit &= $files[$z] & @CRLF
			$omit_count += 1
			ContinueLoop
		EndIf
		$sql_query = _SQLite_Exec($db, "insert into sessions ('file','display_text') values (" & __SQL_Escape($files[$z]) & ",'" & $szFName & $szExt & ");")
		If $debug = 1 Then _DebugReportVar("sql_query[_add_files]", $sql_query, Default, @ScriptLineNumber)
		If $sql_query = $SQLITE_BUSY Or $sql_query = $SQLITE_LOCKED Then
			MsgBox(4112, "Database Error", "Unable to write to the database due to an active transaction." & @CRLF & "" & @CRLF & "Please try again in a few seconds.", 10)
			Return
		EndIf
		$video_count = __Get_MediaInfo($files[$z], $media_info_handle, "General;%VideoCount%")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $video_count, Default, @ScriptLineNumber)
		If $full_proc = 1 Then _SQLite_Exec($db, "update sessions set 'max_video'='" & $video_count & "' where file=" & __SQL_Escape($files[$z]) & ";")
		$audio_count = __Get_MediaInfo($files[$z], $media_info_handle, "General;%AudioCount%")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $audio_count, Default, @ScriptLineNumber)
		If $full_proc = 1 Then _SQLite_Exec($db, "update sessions set 'max_audio'='" & $audio_count & "' where file=" & __SQL_Escape($files[$z]) & ";")
		$subs_count = __Get_MediaInfo($files[$z], $media_info_handle, "General;%TextCount%")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $subs_count, Default, @ScriptLineNumber)
		If $full_proc = 1 Then _SQLite_Exec($db, "update sessions set 'max_subs'='" & $subs_count & "' where file=" & __SQL_Escape($files[$z]) & ";")
		If $line_title <> "" Then
			Local $parameters = _StringBetween($line_title, "[", "]")
			If $debug = 1 Then _DebugReportVar("parameters[_add_files]", $parameters, Default, @ScriptLineNumber)
			If Not @error Then
				Local $line_title_mod = $line_title
				For $a = 0 To UBound($parameters) - 1
					If __GUI_Msg($files[$z]) = 1 Then ExitLoop 2
					Local $parameter = __Get_MediaInfo($files[$z], $media_info_handle, $parameters[$a])
					If $debug = 1 Then _DebugReportVar("media info[_add_files]", $parameter, Default, @ScriptLineNumber)
					If $parameter = "" Or $parameter = "|" Then $parameter = "<Not Set>"
					If $parameter <> "" Then
						$parameter = StringSplit($parameter, "|")
						If $debug = 1 Then _DebugReportVar("parameter[_add_files]", $parameter, Default, @ScriptLineNumber)
						If IsArray($parameter) Then
							$line_title_mod = StringReplace($line_title_mod, "[" & $parameters[$a] & "]", $parameter[1])
						EndIf
					EndIf
				Next
				$line_title_mod = " " & $line_title_mod
			EndIf
		EndIf
		If __GUI_Msg($files[$z]) = 1 Then ExitLoop
		$item = GUICtrlCreateTreeViewItem($split_path[3] & $split_path[4] & $line_title_mod, $tv_ctrl_id)
		_SQLite_Exec($db, "update sessions set item_handle='" & $item & "',handle='" & GUICtrlGetHandle($item) & "' where file=" & __SQL_Escape($files[$z]) & ";")
		$v_codecs_string = __Get_MediaInfo($files[$z], $media_info_handle, "General;%Video_Format_List%")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $v_codecs_string, Default, @ScriptLineNumber)
		$v_codec = StringSplit($v_codecs_string, " / ", 1)
		If $debug = 1 Then _DebugReportVar("v_codec", $v_codec, Default, @ScriptLineNumber)
		$track_id = __Get_MediaInfo($files[$z], $media_info_handle, "Video;%StreamOrder%-")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $track_id)
		$track_id_split = StringSplit($track_id, "-")
		If $debug = 1 Then _DebugReportVar("track_id_split[_add_files]", $track_id_split, Default, @ScriptLineNumber)
		Local $media_info = StringSplit(__Get_MediaInfo($files[$z], $media_info_handle, "Video;%Duration/String3%-"), "-", 1)
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $media_info)
		If IsArray($media_info) Then
			For $a = 1 To $video_count
				If __GUI_Msg($files[$z]) = 1 Then ExitLoop 2
				If $line_video <> "" Then
					Local $parameters = _StringBetween($line_video, "[", "]")
					If $debug = 1 Then _DebugReportVar("parameters[_add_files]", $parameters, Default, @ScriptLineNumber)
					If Not @error Then
						Local $line_video_mod = $line_video
						For $b = 0 To UBound($parameters) - 1
							If __GUI_Msg($files[$z]) = 1 Then ExitLoop 3
							Local $parameter = __Get_MediaInfo($files[$z], $media_info_handle, $parameters[$b], $a - 1, 1)
							If $debug = 1 Then _DebugReportVar("media info[_add_files]", $parameter, Default, @ScriptLineNumber)
							If $parameter = "" Then $parameter = "<Not Set>"
							If $parameter <> "" Then
								$line_video_mod = StringReplace($line_video_mod, "[" & $parameters[$b] & "]", $parameter)
							EndIf
						Next
						$childID = GUICtrlCreateTreeViewItem("Video Track " & $line_video_mod, $item)
					EndIf
				EndIf
				If $media_info[$a] = "" Then
					$media_info[$a] = __Get_MediaInfo($files[$z], $media_info_handle, "General;%Duration/String3%")
					If $debug = 1 Then _DebugReportVar("media info[_add_files]", $media_info[$a], Default, @ScriptLineNumber)
				EndIf
				If $line_video = "" Then
					$childID = GUICtrlCreateTreeViewItem("Video Track [" & $v_codec[$a] & "] (" & $media_info[$a] & ")", $item)
				EndIf
				If $full_proc = 1 Then _SQLite_Exec($db, "insert into child_handles ('file','handle','item_handle','track') values (" & __SQL_Escape($files[$z]) & ",'" & GUICtrlGetHandle($childID) & "','" & $childID & "','" & $track_id_split[$a] & "');")
			Next
		EndIf
		If __GUI_Msg($files[$z]) = 1 Then ExitLoop
		Local $a_track_count = __Get_MediaInfo($files[$z], $media_info_handle, "StreamCount", 0, 2)
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $a_track_count, Default, @ScriptLineNumber)
		$a_lng_string = ""
		For $a = 0 To $a_track_count - 1
			$a_lng_string &= __Get_MediaInfo($files[$z], $media_info_handle, "Language/String", $a, 2) & "/"
			If $debug = 1 Then _DebugReportVar("media info[_add_files]", $a_lng_string, Default, @ScriptLineNumber)
		Next
		$a_lng_string = StringTrimRight($a_lng_string, 1)
		$lng = StringSplit($a_lng_string, "/", 1)
		If $debug = 1 Then _DebugReportVar("lng[_add_files]", $a_lng_string, Default, @ScriptLineNumber)
		$a_codecs_string = __Get_MediaInfo($files[$z], $media_info_handle, "General;%Audio_Format_List%")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $a_codecs_string, Default, @ScriptLineNumber)
		$a_codec = StringSplit($a_codecs_string, " / ", 1)
		If $debug = 1 Then _DebugReportVar("a_codec", $a_codec, Default, @ScriptLineNumber)
		$track_id = __Get_MediaInfo($files[$z], $media_info_handle, "Audio;%StreamOrder%-")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $track_id, Default, @ScriptLineNumber)
		$track_id_split = StringSplit($track_id, "-")
		If $debug = 1 Then _DebugReportVar("track_id_split[_add_files]", $track_id_split, Default, @ScriptLineNumber)
		$channel_count = StringSplit(__Get_MediaInfo($files[$z], $media_info_handle, "Audio;%Channels%-"), "-", 1)
		If $debug = 1 Then _DebugReportVar("channel_count[_add_files]", $channel_count, Default, @ScriptLineNumber)
		For $a = 1 To $audio_count
			If __GUI_Msg($files[$z]) = 1 Then ExitLoop 2
			If $line_audio = "" Then
				If $lng[$a] = "" Then $lng[$a] = "<Not Set>"
				$childID = GUICtrlCreateTreeViewItem("Audio Track [" & $a_codec[$a] & "] (" & $lng[$a] & " - " & $channel_count[$a] & " channels)", $item)
			Else
				Local $parameters = _StringBetween($line_audio, "[", "]")
				If $debug = 1 Then _DebugReportVar("parameters[_add_files]", $parameters, Default, @ScriptLineNumber)
				If Not @error Then
					Local $line_audio_mod = $line_audio
					For $b = 0 To UBound($parameters) - 1
						If __GUI_Msg($files[$z]) = 1 Then ExitLoop 3
						Local $parameter = __Get_MediaInfo($files[$z], $media_info_handle, $parameters[$b], $a - 1, 2)
						If $debug = 1 Then _DebugReportVar("media info[_add_files]", $parameter, Default, @ScriptLineNumber)
						If $parameter = "" Then $parameter = "<Not Set>"
						If $parameter <> "" Then
							$line_audio_mod = StringReplace($line_audio_mod, "[" & $parameters[$b] & "]", $parameter)
						EndIf
					Next
					$childID = GUICtrlCreateTreeViewItem("Audio Track " & $line_audio_mod, $item)
				EndIf
			EndIf
			If $full_proc = 1 Then _SQLite_Exec($db, "insert into child_handles ('file','handle','item_handle','track') values (" & __SQL_Escape($files[$z]) & ",'" & GUICtrlGetHandle($childID) & "','" & $childID & "','" & $track_id_split[$a] & "');")
		Next
		If __GUI_Msg($files[$z]) = 1 Then ExitLoop
		Local $s_track_count = __Get_MediaInfo($files[$z], $media_info_handle, "StreamCount", 0, 3)
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $s_track_count, Default, @ScriptLineNumber)
		$s_lng_String = ""
		For $a = 0 To $s_track_count - 1
			$s_lng_String &= __Get_MediaInfo($files[$z], $media_info_handle, "Language/String", $a, 3) & "/"
			If $debug = 1 Then _DebugReportVar("media info[_add_files]", $s_lng_String, Default, @ScriptLineNumber)
		Next
		$s_lng_String = StringTrimRight($s_lng_String, 1)
		$lng = StringSplit($s_lng_String, "/", 1)
		If $debug = 1 Then _DebugReportVar("lng[_add_files]", $lng, Default, @ScriptLineNumber)
		$s_codecs_string = __Get_MediaInfo($files[$z], $media_info_handle, "General;%Text_Format_List%")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $s_codecs_string, Default, @ScriptLineNumber)
		$s_codec = StringSplit($s_codecs_string, " / ", 1)
		If $debug = 1 Then _DebugReportVar("s_codec[_add_files]", $s_codec, Default, @ScriptLineNumber)
		$track_id = __Get_MediaInfo($files[$z], $media_info_handle, "Text;%StreamOrder%-")
		If $debug = 1 Then _DebugReportVar("media info[_add_files]", $track_id, Default, @ScriptLineNumber)
		$track_id_split = StringSplit($track_id, "-")
		If $debug = 1 Then _DebugReportVar("track_id_split[_add_files]", $track_id_split, Default, @ScriptLineNumber)
		For $a = 1 To $subs_count
			If __GUI_Msg($files[$z]) = 1 Then ExitLoop 2
			If $line_text = "" Then
				If $lng[$a] = "" Then $lng[$a] = "<Not Set>"
				$childID = GUICtrlCreateTreeViewItem("Subtitle Track [" & $s_codec[$a] & "] (" & $lng[$a] & ")", $item)
			Else
				Local $parameters = _StringBetween($line_text, "[", "]")
				If $debug = 1 Then _DebugReportVar("parameters[_add_files]", $parameters, Default, @ScriptLineNumber)
				If Not @error Then
					Local $line_text_mod = $line_text
					For $b = 0 To UBound($parameters) - 1
						If __GUI_Msg($files[$z]) = 1 Then ExitLoop 3
						Local $parameter = __Get_MediaInfo($files[$z], $media_info_handle, $parameters[$b], $a - 1, "Text")
						If $debug = 1 Then _DebugReportVar("media info[_add_files]", $parameter, Default, @ScriptLineNumber)
						If $parameter = "" Then $parameter = "<Not Set>"
						If $parameter <> "" Then
							$line_text_mod = StringReplace($line_text_mod, "[" & $parameters[$b] & "]", $parameter)
						EndIf
					Next
					$childID = GUICtrlCreateTreeViewItem("Subtitle Track " & $line_text_mod, $item)
				EndIf
			EndIf
			If $full_proc = 1 Then _SQLite_Exec($db, "insert into child_handles ('file','handle','item_handle','track') values (" & __SQL_Escape($files[$z]) & ",'" & GUICtrlGetHandle($childID) & "','" & $childID & "','" & $track_id_split[$a] & "');")
		Next
	Next
	If $omit <> "" Then MsgBox(48, "Note", "The following files were omitted, because they were not recognized as Matroska:" & @CRLF & @CRLF & $omit)
	_GUICtrlTreeView_BeginUpdate($tv_ctrl_id)
	_GUICtrlTreeView_EndUpdate($tv_ctrl_id)
	GUICtrlSetData($open_mkvs, "Open MKV files to process...")
	If $full_proc = 1 Then
		If $omit_count <> $files[0] Then
			__TrackCount_Update()
		EndIf
	EndIf
	$omit = ""
	$omit_count = 0
EndFunc   ;==>_Add_Files

Func _Remove_Files($mode = "selected")
	_GUICtrlTreeView_BeginUpdate($file_list)
	If $mode = "selected" Then
		_SQLite_Query($db, "select item_handle from sessions where selected='True';", $query)
	Else
		_SQLite_Query($db, "select item_handle from sessions;", $query)
	EndIf
	While _SQLite_FetchData($query, $query_result) = $SQLITE_OK
		_GUICtrlTreeView_Delete($file_list, $query_result[0])
		_SQLite_Exec($db, "delete from sessions where item_handle='" & $query_result[0] & "';")
	WEnd
	_GUICtrlTreeView_EndUpdate($file_list)
	_GUICtrlStatusBar_SetText($statusbar, "")

	_SQLite_QuerySingleRow($db, "select count(item_handle) from sessions;", $query_result)
	If $query_result[0] = 0 Then
		GUICtrlSetState($go, $GUI_DISABLE)
		_GUICtrlTreeView_DeleteAll($tracklist)
		_SQLite_Exec($db, "delete from batch_item_handles;")
	Else
		__TrackCount_Update()
		;$check_selected = 1
	EndIf
	GUICtrlSetState($removemkvs, $GUI_DISABLE)
EndFunc   ;==>_Remove_Files

Func _XML2Celltimes($xml_file)
	FileDelete(StringMid($xml_file, 1, StringLen($xml_file) - 4) & "_ct.txt")
	Local $chapters_content = FileRead($xml_file)
	Local $chapter_times = _StringBetween($chapters_content, "<ChapterTimeStart>", "</ChapterTimeStart>")
	If $chapter_times[0] = "00:00:00.000000000" Then _ArrayDelete($chapter_times, 0)
	For $a = 0 To UBound($chapter_times) - 1
		Local $part1 = StringSplit($chapter_times[$a], ".")
		Local $part2 = StringSplit($part1[1], ":")
		If $part1[2] > "500000000" Then $msecs = 1
		Local $secs = ($part2[1] * 3600) + ($part2[2] * 60) + ($part2[3]) + $msecs
		FileWriteLine(StringMid($xml_file, 1, StringLen($xml_file) - 4) & "_ct.txt", Round($fps_celltimes * $secs))
		$msecs = 0
	Next
	GUICtrlSetData($xml_converter_progress, Int((100 / (UBound($xml_files) - 1)) * ($b - 1)))
	GUICtrlSetData($xml_converter_status, $xml_file)
	Sleep(200)
	Return
EndFunc   ;==>_XML2Celltimes

Func _Custom_FileName()
	Local $last_fn_custom = ""
	Local $fn_custom_formula
	Local $verified
	Local $last_fn_custom_a
	Local $last_fn_custom_v
	Local $last_fn_custom_s
	Local $gui_size
	Local $nMsg4
	Local $ctrl_size
	Local $caret_pos
	Local $current_text_p1, $current_text_p2
	Local $fn_custom_formula_orig
	Local $aiRArrows, $aiLArrows

	$fn_custom_GUI = GUICreate("Custom Filename Form", 426, 334, -1, -1, $WS_SIZEBOX)
	GUICtrlCreateGroup("Customize Extracted File Names", 10, 10, 404, 241)
	Local $fn_custom_lb = GUICtrlCreateLabel("Filename:", 20, 40, 50, 17)
	Local $fn_custom_input = GUICtrlCreateInput("", 70, 36, 335, 21)
	GUICtrlSetData(-1, IniRead($ini_file, "Files", "custom_filename", ""))
	Local $tl_dummy = GUICtrlCreateDummy()
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	Local $tl_list_plchld = GUICtrlCreateListView("Placeholders", 20, 66, 385, 100, BitOR($LVS_SHOWSELALWAYS, $LVS_SINGLESEL, $LVS_NOCOLUMNHEADER, $LVS_NOSORTHEADER, $LVS_SORTASCENDING))
	_GUICtrlListView_SetExtendedListViewStyle($tl_list_plchld, BitOR($LVS_EX_GRIDLINES, $WS_EX_CLIENTEDGE, $LVS_EX_FULLROWSELECT))
	Local $placeholders = IniReadSection($ini_file, "Placeholders")

	If Not @error Then
		For $a = 1 To $placeholders[0][0]
			$item = StringSplit($placeholders[$a][1], "|")
			If Not @error Then
				GUICtrlCreateListViewItem($item[1], $tl_list_plchld)
			EndIf
		Next
	EndIf
	If UBound($placeholders) > 5 Then
		_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, 360)
	Else
		_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, 380)
	EndIf
	Local $example_fn_lb = GUICtrlCreateLabel("Example:", 20, 180, 47, 17)
	Local $example_fn = GUICtrlCreateLabel("", 74, 180, 300, 21)
	Local $example_fn_audio = GUICtrlCreateLabel("", 74, 200, 300, 21)
	Local $example_fn_sub = GUICtrlCreateLabel("", 74, 220, 300, 21)
	Local $fn_custom_vrfy_btn = GUICtrlCreateButton("Verify", 324, 269, 89, 21)
	Local $fn_custom_save_btn = GUICtrlCreateButton("Save", 213, 269, 105, 21)
	GUICtrlSetState(-1, $GUI_DISABLE)
	Local $fn_custom_help_btn = GUICtrlCreateButton("Help", 10, 269, 97, 21)
	Local $fn_custom_user_btn = GUICtrlCreateButton("Customize", 113, 269, 97, 21)

	GUICtrlSetResizing($tl_list_plchld, $GUI_DOCKHEIGHT)
	GUICtrlSetResizing($fn_custom_help_btn, $GUI_DOCKHEIGHT)
	GUICtrlSetResizing($fn_custom_save_btn, $GUI_DOCKHEIGHT)
	GUICtrlSetResizing($fn_custom_vrfy_btn, $GUI_DOCKHEIGHT)
	GUICtrlSetResizing($fn_custom_user_btn, $GUI_DOCKHEIGHT)

	GUISetState(@SW_SHOW, $fn_custom_GUI)
	GUISetState(@SW_DISABLE, $GUI)

	While 1
		$nMsg4 = GUIGetMsg(1)
		Switch $nMsg4[0]
			Case $GUI_EVENT_CLOSE
				GUISetState(@SW_ENABLE, $GUI)
				GUIDelete($fn_custom_GUI)
				Sleep(50)
				WinActivate("MKVcleaver " & $version)
				Return
			Case $fn_custom_help_btn
				Local $help_text = "Placeholders:" & @CRLF & @CRLF & "[Track#] - Insert track number of the track being extracted." & @CRLF & @CRLF & _
						"[TrackType#] - Insert track type number of the track being extracted." & @CRLF & @CRLF & _
						"[TrackType] - Insert track type of the track being extracted." & @CRLF & @CRLF & _
						"[Filename] - Insert filename of the current file." & @CRLF & @CRLF & _
						"[LNG] - Insert 2 leter language code of the current track (Audio and Subs only)." & @CRLF & @CRLF & _
						"[LNG3] - Insert 3 letter language code of the current track (Audio and Subs only)." & @CRLF & @CRLF & _
						"[LNGf] - Insert language of the current track (Audio and Subs only)." & @CRLF & @CRLF & _
						"[Delay] - Insert source Audio or Video track delay." & @CRLF & @CRLF & _
						"[aDelay] - Insert Audio delay relative to the Video track (Audio only)." & @CRLF & @CRLF & _
						"Use > or < to tell MKVCleaver which separator belongs to which placeholder." & @CRLF & "See Help file for more info."
				#Region --- CodeWizard generated code Start ---
				;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=None
				MsgBox(0, "Custom Filename Syntax Help", $help_text, 0, $fn_custom_GUI)
				#EndRegion --- CodeWizard generated code Start ---
			Case $fn_custom_vrfy_btn
				Local $unique = 0
				Local $a, $b

				Local $fn_custom_formula = GUICtrlRead($fn_custom_input)
				Select
					Case $fn_custom_formula = ""
						$unique = 1
					Case StringInStr($fn_custom_formula, "[FileName]") And StringInStr($fn_custom_formula, "[TrackType]") And StringInStr($fn_custom_formula, "[Track#]")
						$unique = 1
					Case StringInStr($fn_custom_formula, "[FileName]") And StringInStr($fn_custom_formula, "[TrackType]") And StringInStr($fn_custom_formula, "[TrackType#]")
						$unique = 1
					Case StringInStr($fn_custom_formula, "[FileName]") And StringInStr($fn_custom_formula, "[Track#]")
						$unique = 1
				EndSelect
				Local $error = 0
				Local $arrow_find = _StringBetween($fn_custom_formula, "]", "[", 1)
				If StringMid($fn_custom_formula, 1, 1) <> "[" Then _ArrayInsert($arrow_find, 0, StringMid($fn_custom_formula, 1, StringInStr($fn_custom_formula, "[") - 1))
				If StringMid($fn_custom_formula, StringLen($fn_custom_formula), 1) <> "]" Then _ArrayAdd($arrow_find, StringMid($fn_custom_formula, StringInStr($fn_custom_formula, "]", Default, UBound($arrow_find) + 1) + 1, StringLen($fn_custom_formula) - StringInStr($fn_custom_formula, "]", Default, UBound($arrow_find))))
				For $a = 0 To UBound($arrow_find) - 1
					If StringInStr($arrow_find[$a], "<") And StringInStr($arrow_find[$a], ">") Then
						$error = 1
						ExitLoop
					EndIf

					If $a = UBound($arrow_find) - 1 Then
						$b = $a
					Else
						$b = $a + 1
					EndIf

					If StringInStr($arrow_find[$a], ">") And StringInStr($arrow_find[$b], "<") Then
						$error = 1
						ExitLoop
					EndIf

					$aiRArrows = StringRegExp($arrow_find[$a], "\>", 3)
					If UBound($aiRArrows) > 1 Then
						$error = 1
						ExitLoop
					EndIf

					$aiLArrows = StringRegExp($arrow_find[$a], "\<", 3)
					If UBound($aiLArrows) > 1 Then
						$error = 1
						ExitLoop
					EndIf
				Next
				If StringInStr($fn_custom_formula, "<[") Or StringInStr($fn_custom_formula, "]>") Then $error = 1
				If $error = 1 Then
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(16, "Configuration Error", "Current filename configuration has errors. " & @CRLF & @CRLF & _
							"You cannot have a single separator point to 2 adjacent placeholders." & @CRLF & _
							"Or 2 separators point to the same placeholder." & @CRLF & @CRLF & _
							"Example: Wrong - [Filename]<-->[Track#] Or [Delay]-->[LNG]<--" & @CRLF & _
							"Example: Correct - [Filename]<--[Track#] Or [Filename]-->[Track#]")
				EndIf

				Local $forbidden = 0
				Select
					Case StringInStr($fn_custom_formula, ":")
						$forbidden = 1
					Case StringInStr($fn_custom_formula, '"')
						$forbidden = 1
					Case StringInStr($fn_custom_formula, "\")
						$forbidden = 1
					Case StringInStr($fn_custom_formula, "/")
						$forbidden = 1
					Case StringInStr($fn_custom_formula, "|")
						$forbidden = 1
					Case StringInStr($fn_custom_formula, "?")
						$forbidden = 1
					Case StringInStr($fn_custom, "*")
						$forbidden = 1
				EndSelect
				If $forbidden = 1 Then
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(16, "Configuration Error", "Current filename configuration has errors. " & @CRLF & @CRLF & _
							"You cannot have any of the following characters in a file name:" & @CRLF & @CRLF & _
							': " \ / | ? *')
				EndIf

				If $unique = 0 Then
					#Region --- CodeWizard generated code Start ---
					;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Default Button=Second, Icon=Question
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(292, "Confirm Configuration", "Current filename configuration does not have a unique variale. " & @CRLF & @CRLF & _
							"Output files of the same type may be overwritten if the destination path is a single directory." & @CRLF & @CRLF & "Do you want to continue ?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes
							$verified = 1
							GUICtrlSetState($fn_custom_save_btn, $GUI_ENABLE)
						Case $iMsgBoxAnswer = 7 ;No
							$verified = 0
							GUICtrlSetState($fn_custom_save_btn, $GUI_DISABLE)
					EndSelect
					#EndRegion --- CodeWizard generated code Start ---
				ElseIf $unique = 1 And $error = 0 And $forbidden = 0 Then
					$verified = 1
					GUICtrlSetState($fn_custom_save_btn, $GUI_ENABLE)
				EndIf
			Case $fn_custom_save_btn
				IniWrite($ini_file, "Files", "custom_filename", GUICtrlRead($fn_custom_input))
				IniDelete($ini_file, "Files", "filename")
				GUICtrlSetState($tr_fn_chk, $GUI_DISABLE)
				GUICtrlSetState($fn_tr_chk, $GUI_DISABLE)
				GUICtrlSetState($tropt_chk, $GUI_DISABLE)
				If GUICtrlRead($fn_custom_input) = "" Then
					GUICtrlSetState($tr_fn_chk, $GUI_ENABLE)
					GUICtrlSetState($fn_tr_chk, $GUI_ENABLE)
					If GUICtrlRead($fn_tr_chk) = $GUI_CHECKED Then
						GUICtrlSetState($tropt_chk, $GUI_ENABLE)
					EndIf
				EndIf
				GUISetState(@SW_ENABLE, $GUI)
				GUIDelete($fn_custom_GUI)
				Return
			Case $fn_custom_user_btn
				_Custom_FileName_Config($fn_custom_GUI, "Custom Filename Form")
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
					$ctrl_size = ControlGetPos("", "", "[CLASSNN:SysListView321]")
					If $placeholders[0][0] * 20 > $ctrl_size[3] Then
						_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, $ctrl_size[2] - 25)
					Else
						_GUICtrlListView_SetColumnWidth($tl_list_plchld, 0, $ctrl_size[2] - 5)
					EndIf
					GUICtrlSetData($fn_custom_input, GUICtrlRead($fn_custom_input))
				EndIf
				_GUICtrlListView_EndUpdate($tl_list_plchld)
			Case $GUI_EVENT_RESIZED
				$gui_size = WinGetPos("Custom Filename Form", "")
				If IsArray($gui_size) Then
					If $gui_size[2] < 426 Then
						WinMove("Custom Filename Form", "", $gui_size[0], $gui_size[1], 426, $gui_size[3])
					EndIf
					If $gui_size[3] > 344 Then
						WinMove("Custom Filename Form", "", $gui_size[0], $gui_size[1], $gui_size[2], 344)
					EndIf
					If $gui_size[3] < 344 Then
						WinMove("Custom Filename Form", "", $gui_size[0], $gui_size[1], $gui_size[2], 344)
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
				GUICtrlSetData($fn_custom_input, GUICtrlRead($fn_custom_input))
			Case $GUI_EVENT_DROPPED
				Local $index = _GUICtrlListView_GetSelectedIndices($tl_list_plchld)
				Local $text = _GUICtrlListView_GetItemText(GUICtrlGetHandle($tl_list_plchld), $index)
				Local $current_text = GUICtrlRead($fn_custom_input)
				$caret_pos = ControlCommand("Custom Filename Form", "", "[CLASSNN:Edit1]", "GetCurrentCol")
				$current_text_p1 = StringMid($current_text, 1, $caret_pos - 1)
				$current_text_p2 = StringMid($current_text, $caret_pos, StringLen($current_text))
				GUICtrlSetData($fn_custom_input, $current_text_p1 & $text & $current_text_p2)
				ContinueLoop
		EndSwitch
		Local $fn_custom_formula = GUICtrlRead($fn_custom_input)
		If $fn_custom_formula_orig <> $fn_custom_formula Then GUICtrlSetState($fn_custom_save_btn, $GUI_DISABLE)
		$fn_custom_formula_orig = $fn_custom_formula
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Track#]", "*01*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType#]", "*01*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*Video*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", "*MKV_File*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Delay]", "*100ms*")
		Local $placeholders = IniReadSection($ini_file, "Placeholders")
		If Not @error Then
			For $a = 1 To $placeholders[0][0]
				Local $placeholder_string = StringSplit($placeholders[$a][1], "|")
				$fn_custom_formula = StringReplace($fn_custom_formula, $placeholder_string[1], "*" & $placeholder_string[3] & "*")
			Next
		EndIf
		__Custom_FileName_Format($fn_custom_formula)
		If $fn_custom_formula <> $last_fn_custom_v Then
			GUICtrlSetData($example_fn, $fn_custom_formula & ".h264")
		EndIf
		$last_fn_custom_v = $fn_custom_formula

		$fn_custom_formula = $fn_custom_formula_orig
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Track#]", "*02*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType#]", "*01*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*Audio*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", "*MKV_File*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[LNG]", "*EN*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[LNG3]", "*ENG*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[LNGf]", "*English*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Delay]", "*100ms*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[aDelay]", "*0ms*")
		If IsArray($placeholders) Then
			For $a = 1 To $placeholders[0][0]
				Local $placeholder_string = StringSplit($placeholders[$a][1], "|")
				$fn_custom_formula = StringReplace($fn_custom_formula, $placeholder_string[1], "*" & $placeholder_string[3] & "*")
			Next
		EndIf
		__Custom_FileName_Format($fn_custom_formula)
		If $fn_custom_formula <> $last_fn_custom_a Then
			GUICtrlSetData($example_fn_audio, $fn_custom_formula & ".aac")
		EndIf
		$last_fn_custom_a = $fn_custom_formula

		$fn_custom_formula = $fn_custom_formula_orig
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Track#]", "*03*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType#]", "*01*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[TrackType]", "*Subtitles*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[Filename]", "*MKV_File*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[LNG]", "*EN*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[LNG3]", "*ENG*")
		$fn_custom_formula = StringReplace($fn_custom_formula, "[LNGf]", "*English*")
		If IsArray($placeholders) Then
			For $a = 1 To $placeholders[0][0]
				Local $placeholder_string = StringSplit($placeholders[$a][1], "|")
				$fn_custom_formula = StringReplace($fn_custom_formula, $placeholder_string[1], "*" & $placeholder_string[3] & "*")
			Next
		EndIf
		__Custom_FileName_Format($fn_custom_formula)
		If $fn_custom_formula <> $last_fn_custom_s Then
			GUICtrlSetData($example_fn_sub, $fn_custom_formula & ".srt")
		EndIf
		$last_fn_custom_s = $fn_custom_formula
	WEnd
EndFunc   ;==>_Custom_FileName

Func _Extract_Filter()
	Local $nMsg6
	Local $data
	Local $y = 40
	Local $ctrl_count = 1
	Local $position
	Local $query_result
	Local $query_result2
	Local $query_result3
	Local $query

	Local $sql_query = _SQLite_Exec($db, "drop table if exists 'control_list';" & "create table if not exists 'control_list' ('ID');")
	If $sql_query <> $SQLITE_OK Then
		MsgBox(4112, "Database Error", "Unable to write to the database due to an active transaction." & @CRLF & "" & @CRLF & "Please try again in a few seconds.", 10)
		Return
	EndIf
	#Region ### START Koda GUI section ### Form=c:\development\mkvcleaver\common\filter_gui.kxf
	$batch_filter_gui = GUICreate("Batch Mode Filter Configuration", 664, 400, -1, -1, $WS_CAPTION + $WS_SYSMENU)
	Local $menu = GUICtrlCreateMenu("Menu")
	Local $filter_types = GUICtrlCreateMenuItem("Parameters Config", $menu, 1)
	Local $save = GUICtrlCreateMenuItem("Save", $menu, 2)
	GUICtrlCreateLabel("Exclude Tracks Where:", 17, 15, 150, 17)
	GUICtrlSetFont(-1, Default, $FW_BOLD)
	Assign("tr_type" & $ctrl_count, GUICtrlCreateCombo("", 17, 40, 128, 25, $CBS_DROPDOWNLIST), 1)
	GUICtrlSetData(-1, "Video|Audio|Subtitles")
	Assign("variable_type" & $ctrl_count, GUICtrlCreateCombo("", 161, 40, 128, 25, $CBS_DROPDOWNLIST), 1)
	Assign("comparitor" & $ctrl_count, GUICtrlCreateCombo("", 305, 40, 128, 25, $CBS_DROPDOWNLIST), 1)
	GUICtrlSetData(-1, "Is|Is Not|Contains|Does Not Contain|Greater Than|Less Than|RegEx")
	Assign("value" & $ctrl_count, GUICtrlCreateInput("", 449, 40, 128, 21), 1)
	Local $add_next = GUICtrlCreateButton("Add", 593, 40, 40, 20)
	#EndRegion ### END Koda GUI section ###

	$sql_query = _SQLite_Exec($db, "insert into 'control_list' ('ID') values ('" & $add_next & "');")
	Local $data_types = IniReadSection($ini_file, "Parameters")
	If Not @error Then GUICtrlSetData(Eval("variable_type" & $ctrl_count), _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))

	Local $filters = IniReadSection($ini_file, "Filters")
	If Not @error Then
		$data = StringSplit($filters[1][1], "|")
		GUICtrlSetData(Eval("tr_type" & $ctrl_count), $data[1])
		GUICtrlSetData(Eval("variable_type" & $ctrl_count), $data[2])
		GUICtrlSetData(Eval("comparitor" & $ctrl_count), $data[3])
		GUICtrlSetData(Eval("value" & $ctrl_count), $data[4])
		If $filters[0][0] > 1 Then
			For $a = 2 To $filters[0][0] Step 2
				$ctrl_count += 1
				$y += 40
				$data = StringSplit($filters[$a + 1][1], "|")
				Assign("operator" & $ctrl_count, GUICtrlCreateCombo("", 17, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, "Or|And")
				GUICtrlSetData(-1, $filters[$a][1])
				$y += 40
				Assign("tr_type" & $ctrl_count, GUICtrlCreateCombo("", 17, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, "Video|Audio|Subtitles")
				GUICtrlSetData(-1, $data[1])
				Assign("variable_type" & $ctrl_count, GUICtrlCreateCombo("", 161, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))
				GUICtrlSetData(-1, $data[2])
				Assign("comparitor" & $ctrl_count, GUICtrlCreateCombo("", 305, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, "Is|Is Not|Contains|Does Not Contain|Greater Than|Less Than|RegEx")
				GUICtrlSetData(-1, $data[3])
				Assign("value" & $ctrl_count, GUICtrlCreateInput("", 449, $y, 128, 21), 1)
				GUICtrlSetData(-1, $data[4])
				GUICtrlSetData($add_next, "Del")
				$add_next = GUICtrlCreateButton("Add", 593, $y, 40, 20)
				_SQLite_Exec($db, "insert into 'control_list' ('ID') values ('" & $add_next & "');")
			Next
		EndIf
	EndIf

	_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)

	_GUIScrollBars_Init($batch_filter_gui, Default, 2.5)
	_GUIScrollBars_ShowScrollBar($batch_filter_gui, $SB_VERT, True)

	GUISetState(@SW_DISABLE, $GUI)
	GUISetState(@SW_SHOW, $batch_filter_gui)

	Local $unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)
	If $query[0] > 4 Then _GUIScrollBars_SetScrollInfoMax($batch_filter_gui, $SB_VERT, Round(($query[0] - 3) * 5, 0))

	While 1
		$nMsg6 = GUIGetMsg(1)
		Select
			Case $nMsg6[0] = $filter_types
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				If $unsaved_changes <> ($ctrl_count + $query[0] + _SQLite_LastInsertRowID($db)) Then
					Local $restore = 1
				Else
					Local $restore = 0
				EndIf
				_Define_Params($batch_filter_gui, "Batch Mode Filter Configuration")
				Local $data_types = IniReadSection($ini_file, "Parameters")
				If IsArray($data_types) Then
					For $a = 1 To $ctrl_count
						Local $old_data = GUICtrlRead(Eval("variable_type" & $a))
						GUICtrlSetData(Eval("variable_type" & $a), "")
						GUICtrlSetData(Eval("variable_type" & $a), _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))
						If $old_data <> "" And _ArraySearch($data_types, $old_data, Default, Default, Default, 2) <> -1 Then GUICtrlSetData(Eval("variable_type" & $a), $old_data)
					Next
				Else
					For $a = 1 To $ctrl_count
						GUICtrlSetData(Eval("variable_type" & $a), "")
					Next
				EndIf
				If $restore = 0 Then
					_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
					$unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)
				EndIf
			Case $nMsg6[0] = $GUI_EVENT_CLOSE
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				If $unsaved_changes <> ($ctrl_count + $query[0] + _SQLite_LastInsertRowID($db)) Then
					#Region --- CodeWizard generated code Start ---
					;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Default Button=Second, Icon=Question
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(292, "Unsaved Changes", "You made changes to the rules." & @CRLF & @CRLF & "Do you want to close the module without saving the rules ?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes

						Case $iMsgBoxAnswer = 7 ;No
							;_SQLite_Exec($db, "delete from 'control_list' where rowid='" & _SQLite_LastInsertRowID($db) & "';")
							ContinueLoop
					EndSelect
					#EndRegion --- CodeWizard generated code Start ---
				EndIf
				GUISetState(@SW_ENABLE, $GUI)
				GUIDelete($batch_filter_gui)
				Sleep(50)
				WinActivate("MKVcleaver " & $version)
				_SQLite_Exec($db, "drop table 'control_list';")
				Return
			Case $nMsg6[0] = $add_next And $nMsg6[0] > 0
				GUISetState(@SW_SHOWNORMAL, $batch_filter_gui)
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				$position = ControlGetPos("", "", "[CLASS:Button; INSTANCE:" & $query[0] & "]")
				$ctrl_count += 1
				$y = $position[1] + 40
				Assign("operator" & $ctrl_count, GUICtrlCreateCombo("", 17, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, "Or|And")
				$y += 40
				Assign("tr_type" & $ctrl_count, GUICtrlCreateCombo("", 17, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, "Video|Audio|Subtitles")
				Assign("variable_type" & $ctrl_count, GUICtrlCreateCombo("", 161, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				If IsArray($data_types) Then GUICtrlSetData(-1, _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))
				Assign("comparitor" & $ctrl_count, GUICtrlCreateCombo("", 305, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, "Is|Is Not|Contains|Does Not Contain|Greater Than|Less Than|RegEx")
				Assign("value" & $ctrl_count, GUICtrlCreateInput("", 449, $y, 128, 21), 1)
				GUICtrlSetData($add_next, "Del")
				$add_next = GUICtrlCreateButton("Add", 593, $y, 40, 20)
				_SQLite_Exec($db, "insert into 'control_list' ('ID') values ('" & $add_next & "');")
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				If $query[0] > 4 Then
					_GUIScrollBars_SetScrollInfoMax($batch_filter_gui, $SB_VERT, Round(($query[0] - 3) * 5, 0))
				Else
					_GUIScrollBars_SetScrollInfoMax($batch_filter_gui, $SB_VERT, 5)
				EndIf
			Case $nMsg6[0] = $save
				Local $save_line
				Local $row = -1

				IniDelete($ini_file, "Filters")
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				_SQLite_Query($db, "select rowid from 'control_list';", $query_result)
				For $a = 1 To $query[0]
					_SQLite_FetchData($query_result, $query_result2)
					$save_line = ""
					$save_line &= GUICtrlRead(Eval("tr_type" & $query_result2[0]))
					$save_line &= "|" & GUICtrlRead(Eval("variable_type" & $query_result2[0]))
					$save_line &= "|" & GUICtrlRead(Eval("comparitor" & $query_result2[0]))
					$save_line &= "|" & GUICtrlRead(Eval("value" & $query_result2[0]))
					Local $save_line_test = StringSplit($save_line, "|")
					Local $save_ok = 1
					For $b = 1 To $save_line_test[0]
						If $save_line_test[$b] = "" Then $save_ok = 0
					Next
					If $save_ok = 1 Then
						If $a > 1 Then
							$save_ok = GUICtrlRead(Eval("operator" & $query_result2[0]))
							If $save_ok <> "" Then
								$row += 1
								IniWrite($ini_file, "Filters", $a + $row, $save_ok)
								IniWrite($ini_file, "Filters", $a + $row + 1, $save_line)
							EndIf
						Else
							IniWrite($ini_file, "Filters", $a, $save_line)
						EndIf
					EndIf
				Next
				_SQLite_QueryFinalize($query_result)
				$unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)
				MsgBox(64, "Saved", "The rules were saved successfully.", 10, $batch_filter_gui)
			Case Else
				_SQLite_QuerySingleRow($db, "select rowid from 'control_list' where ID='" & $nMsg6[0] & "';", $query)
				If $query[0] <> "" And $query[0] <> _SQLite_LastInsertRowID($db) Then
					GUISetState(@SW_SHOWNORMAL, $batch_filter_gui)
					GUICtrlDelete($nMsg6[0])
					GUICtrlDelete(Eval("tr_type" & $query[0]))
					GUICtrlDelete(Eval("variable_type" & $query[0]))
					GUICtrlDelete(Eval("comparitor" & $query[0]))
					GUICtrlDelete(Eval("value" & $query[0]))
					GUICtrlDelete(Eval("operator" & $query[0]))
					Local $rows, $columns
					_SQLite_GetTable($db, "select ID from 'control_list';", $query_result2, $rows, $columns)
					_ArrayDelete($query_result2, "1")
					Local $start = _ArraySearch($query_result2, $nMsg6[0])
					For $a = $start To UBound($query_result2) - 1
						If $a = 1 Then
							_SQLite_Query($db, "select rowid from 'control_list';", $query_result3)
							_SQLite_FetchData($query_result3, $query_result, Default, True)
							_SQLite_FetchData($query_result3, $query_result, Default, True)
							_SQLite_QueryFinalize($query_result3)
							GUICtrlDelete(Eval("operator" & $query_result[0]))
						EndIf
						$position = ControlGetPos("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1)) & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1)) & "]", $position[0], $position[1] - 80)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1) + 1) & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1) + 1) & "]", $position[0], $position[1] - 80)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1) + 2) & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1) + 2) & "]", $position[0], $position[1] - 80)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:Edit; INSTANCE:" & $a & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Edit; INSTANCE:" & $a & "]", $position[0], $position[1] - 80)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:Button; INSTANCE:" & $a & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Button; INSTANCE:" & $a & "]", $position[0], $position[1] - 80)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1) + 3) & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:ComboBox; INSTANCE:" & (4 * ($a - 1) + 3) & "]", $position[0], $position[1] - 80)
						EndIf
					Next
					_SQLite_Exec($db, "delete from 'control_list' where ID='" & $nMsg6[0] & "';")
					_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
					$position = _GUIScrollBars_GetScrollInfoPos($batch_filter_gui, $SB_VERT)
					If $query[0] > 4 Then
						_GUIScrollBars_SetScrollInfoPos($batch_filter_gui, $SB_VERT, $position - 5)
						_GUIScrollBars_SetScrollInfoMax($batch_filter_gui, $SB_VERT, Round(($query[0] - 3) * 5, 0))
					Else
						_GUIScrollBars_SetScrollInfoPos($batch_filter_gui, $SB_VERT, 0)
						_GUIScrollBars_SetScrollInfoMax($batch_filter_gui, $SB_VERT, 5)
					EndIf
				EndIf
		EndSelect
	WEnd

EndFunc   ;==>_Extract_Filter

Func _Define_Params($gui_to_hide, $title)
	Local $ctrl_count = 1
	Local $query
	Local $rows, $columns
	Local Static $mi_params_gui
	Local $y = 60
	Local $test_files
	Local $index = 0
	Local $nMsg7

	Local $sql_query = _SQLite_Exec($db, "drop table if exists 'control_list_params';" & "create table if not exists 'control_list_params' ('ID');")
	If $sql_query <> $SQLITE_OK Then
		MsgBox(4112, "Database Error", "Unable to write to the database due to an active transaction." & @CRLF & "" & @CRLF & "Please try again in a few seconds.", 10, $GUI)
		Return
	EndIf

	If $mi_params_gui <> "" Then GUIDelete($mi_params_gui)

	#Region ### START Koda GUI section ### Form=c:\development\mkvcleaver\common\filter_gui.kxf
	$mi_params_gui = GUICreate("MediaInfo Parameters Configuration", 379, 400, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_ACCEPTFILES)
	Local $menu = GUICtrlCreateMenu("Menu")
	Local $help = GUICtrlCreateMenuItem("Parameter List", $menu, 1)
	Local $test = GUICtrlCreateMenuItem("Test Parameters", $menu, 2)
	Local $save = GUICtrlCreateMenuItem("Save", $menu, 3)
	GUICtrlCreateLabel("Filter Parameters:", 17, 15, 150, 17)
	GUICtrlSetFont(-1, Default, $FW_BOLD)
	GUICtrlCreateLabel("Name", 17, 40, 150, 17)
	GUICtrlCreateLabel("MediaInfo Parameter", 161, 40, 150, 17)
	Assign("name" & $ctrl_count, GUICtrlCreateInput("", 17, 60, 128, 21), 1)
	Assign("parameter" & $ctrl_count, GUICtrlCreateInput("", 161, 60, 128, 21), 1)
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	Local $add_next = GUICtrlCreateButton("Add", 305, 60, 40, 20)
	#EndRegion ### END Koda GUI section ###

	_SQLite_Exec($db, "insert into 'control_list_params' ('ID') values ('" & $add_next & "');")

	Local $data_types = IniReadSection($ini_file, "Parameters")
	If Not @error Then
		GUICtrlSetData(Eval("name" & $ctrl_count), $data_types[1][0])
		GUICtrlSetData(Eval("parameter" & $ctrl_count), $data_types[1][1])
		For $a = 2 To $data_types[0][0]
			$ctrl_count += 1
			$y += 40
			Assign("name" & $ctrl_count, GUICtrlCreateInput($data_types[$a][0], 17, $y, 128, 21), 1)
			Assign("parameter" & $ctrl_count, GUICtrlCreateInput($data_types[$a][1], 161, $y, 128, 21), 1)
			GUICtrlSetState(-1, $GUI_DROPACCEPTED)
			GUICtrlSetData($add_next, "Del")
			$add_next = GUICtrlCreateButton("Add", 305, $y, 40, 20)
			_SQLite_Exec($db, "insert into 'control_list_params' ('ID') values ('" & $add_next & "');")
		Next
	EndIf

	_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
	If $query[0] > 8 Then
		_GUIScrollBars_Init($mi_params_gui, Default, Round($query[0] * 2.8, 0))
		_GUIScrollBars_ShowScrollBar($mi_params_gui, $SB_VERT, True)
	Else
		_GUIScrollBars_Init($mi_params_gui, Default, 2.5)
		_GUIScrollBars_ShowScrollBar($mi_params_gui, $SB_VERT, True)
	EndIf

	GUISetState(@SW_SHOW, $mi_params_gui)
	GUISetState(@SW_HIDE, $gui_to_hide)

	Local $unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)

	While 1
		$nMsg7 = GUIGetMsg(1)
		Switch $nMsg7[0]
			Case $GUI_EVENT_CLOSE
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
				If $unsaved_changes <> ($ctrl_count + $query[0] + _SQLite_LastInsertRowID($db)) Then
					#Region --- CodeWizard generated code Start ---
					;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Default Button=Second, Icon=Question
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(292, "Unsaved Changes", "You made changes to the parameters." & @CRLF & @CRLF & "Do you want to close the module without saving the changes ?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes

						Case $iMsgBoxAnswer = 7 ;No
							ContinueLoop
					EndSelect
					#EndRegion --- CodeWizard generated code Start ---
				EndIf
				GUISetState(@SW_SHOW, $gui_to_hide)
				GUIDelete($mi_params_gui)
				WinActivate($title)
				Local $sql_query = _SQLite_Exec($db, "drop table if exists 'control_list_params';")
				Return
			Case $help
				If Not FileExists(@ScriptDir & "\mediainfo_params.sqlite") Then
					MsgBox(16, "Error", "MKVcleaver was unable to load mediainfo_params.sqlite." & @CRLF & @CRLF & "Reinstalling the application may fix the issue.")
					ContinueLoop
				EndIf
				Local $track_type = "Video"
				Local $edit_focus = ControlGetFocus("")
				Local $mi_params_helper_gui = GUICreate("MediaInfo Parameters List", 600, 435, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_ACCEPTFILES)
				Local $db_mi = _SQLite_Open(@ScriptDir & "\mediainfo_params.sqlite", $SQLITE_OPEN_READONLY)
				_SQLite_GetTable2d($db_mi, "select * from " & $track_type & ";", $query, $rows, $columns)
				GUICtrlCreateGroup("Available Parameters", 10, 12, 580, 375)
				GUICtrlCreateLabel("Track Type: ", 25, 40, 80, 30)
				Local $track_type_select = GUICtrlCreateCombo("Video", 95, 37, 80, 30, $CBS_DROPDOWNLIST)
				GUICtrlSetData(-1, "Audio|Subtitles")
				Local $search = GUICtrlCreateInput("", 215, 37, 160, 21)
				GUICtrlSetState(-1, $GUI_DROPACCEPTED)
				Local $search_btn = GUICtrlCreateButton("Search", 395, 37, 40, 20, $BS_DEFPUSHBUTTON)
				Local $list_view = _GUICtrlListView_Create($mi_params_helper_gui, "Parameter|Description", 25, 77, 550, 293, BitOR($LVS_REPORT, $LVS_NOSORTHEADER, $LVS_SINGLESEL), BitOR($WS_EX_CLIENTEDGE, $WS_EX_STATICEDGE, $WS_EX_DLGMODALFRAME))
				_GUICtrlListView_SetExtendedListViewStyle($list_view, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT, $WS_EX_CLIENTEDGE))
				For $a = 1 To UBound($query) - 1
					_GUICtrlListView_AddItem($list_view, $query[$a][0])
					_GUICtrlListView_AddSubItem($list_view, $a - 1, $query[$a][1], 1)
				Next
				Local $insert = GUICtrlCreateButton("Insert", 497, 395, 80, 25)
				GUISetState(@SW_SHOW, $mi_params_helper_gui)
				_GUICtrlListView_SetColumnWidth($list_view, 0, $LVSCW_AUTOSIZE)
				_GUICtrlListView_SetColumnWidth($list_view, 1, $LVSCW_AUTOSIZE)
				While 1
					Local $nMsg8 = GUIGetMsg(1)
					Switch $nMsg8[0]
						Case $GUI_EVENT_CLOSE
							If $nMsg8[1] = $mi_params_helper_gui Then
								GUISetState(@SW_ENABLE, $mi_params_gui)
								GUIDelete($mi_params_helper_gui)
								_SQLite_Close($db_mi)
								ExitLoop
							EndIf
						Case $search_btn
							Local $text = GUICtrlRead($search)
							$index = _GUICtrlListView_FindInText($list_view, $text, $index)
							ControlFocus("", "", "[CLASS:SysListView32; INSTANCE:1]")
							If $index <> -1 Then
								_GUICtrlListView_Scroll($list_view, 0, -1000000)
								_GUICtrlListView_Scroll($list_view, 0, Round($index * 16.5, 0))
								_GUICtrlListView_SetItemSelected($list_view, $index, True, True)
							EndIf
						Case $insert, $GUI_EVENT_DROPPED
							Local $index = _GUICtrlListView_GetSelectedIndices($list_view)
							Local $text = _GUICtrlListView_GetItemText($list_view, $index)
							If $nMsg8[0] <> $GUI_EVENT_DROPPED Then
								GUIDelete($mi_params_helper_gui)
								_SQLite_Close($db_mi)
							EndIf
							Local $edit_instance = StringRight($edit_focus, StringLen($edit_focus) - 4)
							Local $current_text = GUICtrlRead(Eval("parameter" & $edit_instance / 2))
							If StringInStr($edit_focus, "Edit") And Not IsFloat($edit_instance / 2) And $current_text = "" And $nMsg8[0] <> $GUI_EVENT_DROPPED Then
								ControlSend("", "", "[CLASS:Edit; INSTANCE:" & $edit_instance & "]", $text, 1)
							ElseIf $nMsg8[0] <> $GUI_EVENT_DROPPED Then
								ClipPut($text)
								MsgBox(64, "Info", "The selected parameter was copied to the clipboard.", 5)
							EndIf
							If $nMsg8[0] = $GUI_EVENT_DROPPED Then
								GUICtrlSetData(@GUI_DropId, $text)
								ContinueLoop
							EndIf
							ExitLoop
						Case $track_type_select
							Local $track_type = GUICtrlRead($track_type_select)
							_GUICtrlListView_BeginUpdate($list_view)
							_GUICtrlListView_DeleteAllItems($list_view)
							_SQLite_GetTable2d($db_mi, "select * from " & $track_type & ";", $query, $rows, $columns)
							For $a = 1 To UBound($query) - 1
								_GUICtrlListView_AddItem($list_view, $query[$a][0])
								_GUICtrlListView_AddSubItem($list_view, $a - 1, $query[$a][1], 1)
								_GUICtrlListView_SetColumnWidth($list_view, 0, $LVSCW_AUTOSIZE)
								_GUICtrlListView_SetColumnWidth($list_view, 1, $LVSCW_AUTOSIZE)
							Next
							_GUICtrlListView_EndUpdate($list_view)
					EndSwitch
				WEnd
			Case $add_next
				GUISetState(@SW_SHOW, $mi_params_gui)
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
				$position = ControlGetPos("", "", "[CLASS:Button; INSTANCE:" & $query[0] & "]")
				$ctrl_count += 1
				$y = $position[1] + 40
				Assign("name" & $ctrl_count, GUICtrlCreateInput("", 17, $y, 128, 21), 1)
				Assign("parameter" & $ctrl_count, GUICtrlCreateInput("", 161, $y, 128, 21), 1)
				GUICtrlSetState(-1, $GUI_DROPACCEPTED)
				GUICtrlSetData($add_next, "Del")
				$add_next = GUICtrlCreateButton("Add", 305, $y, 40, 20)
				_SQLite_Exec($db, "insert into 'control_list_params' ('ID') values ('" & $add_next & "');")
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
				If $query[0] > 8 Then
					_GUIScrollBars_SetScrollInfoMax($mi_params_gui, $SB_VERT, Round($query[0] * 2.8, 0))
					;_GUIScrollBars_ShowScrollBar($mi_params_gui, $SB_VERT, True)
				Else
					_GUIScrollBars_SetScrollInfoMax($mi_params_gui, $SB_VERT, 22)
					;_GUIScrollBars_ShowScrollBar($mi_params_gui, $SB_VERT, True)
				EndIf
				GUISetState(@SW_SHOW, $mi_params_gui)
			Case $save
				Local $item = 0

				IniDelete($ini_file, "Parameters")
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
				_SQLite_Query($db, "select rowid from 'control_list_params';", $query_result)
				For $a = 1 To $query[0]
					_SQLite_FetchData($query_result, $query_result2)
					Local $save_line = ""
					$save_line &= GUICtrlRead(Eval("name" & $query_result2[0]))
					$save_line &= "|" & GUICtrlRead(Eval("parameter" & $query_result2[0]))
					Local $save_line_test = StringSplit($save_line, "|")
					Local $save_ok = 1
					For $b = 1 To $save_line_test[0]
						If $save_line_test[$b] = "" Then $save_ok = 0
					Next
					If $save_ok = 1 Then IniWrite($ini_file, "Parameters", $save_line_test[1], $save_line_test[2])
				Next

				Local $filters = IniReadSection($ini_file, "Filters")
				Local $data_types = IniReadSection($ini_file, "Parameters")
				If IsArray($filters) Then
					For $a = 1 To $filters[0][0]
						If $filters[$a][1] = "And" Or $filters[$a][1] = "Or" Or $filters[$a][1] = "" Then ContinueLoop
						Local $filter = StringSplit($filters[$a][1], "|")
						Local $index = _ArraySearch($data_types, $filter[2], Default, Default, Default, 2, Default, 0)
						If $index = -1 Then
							Select
								Case $a >= 1 And $filters[0][0] > 1 And $a < $filters[0][0]
									$filters[$a][1] = ""
									$filters[$a + 1][1] = ""
								Case $a = $filters[0][0] And $filters[0][0] > 1
									$filters[$a][1] = ""
									$filters[$a - 1][1] = ""
								Case $filters[0][0] = 1
									$filters[$a][1] = ""
							EndSelect
						EndIf
					Next
					$index = _ArrayFindAll($filters, "", 1, Default, Default, Default, 1)
					_ArrayInsert($index, 0, UBound($index))
					_ArrayDelete($filters, $index)
					For $a = 1 To UBound($filters) - 1
						$filters[$a][0] = $a
					Next
					IniWriteSection($ini_file, "Filters", $filters)
				EndIf
				_SQLite_QueryFinalize($query_result)
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
				$unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)
				MsgBox(64, "Saved", "The parameters were saved successfully.", 10, $mi_params_gui)
			Case $test
				Local $item = 0

				#Region Test Files
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
				If $query[0] = 1 Then
					_SQLite_QuerySingleRow($db, "select ID from 'control_list_params' where rowid=1;", $query_result)
					If GUICtrlRead($query_result[0] - 1) = "" Then
						MsgBox(16, "Error", "No parameters found for testing.")
						ContinueLoop
					EndIf
				EndIf
				If $test_files = "" Then
					Local $test_files = FileOpenDialog("Open Files To Read", "", "MKV (*.mkv; *.mka; *.mks)|WebM (*.webm)|All (*.*)", 7)
					If @error Then ContinueLoop
				EndIf
				If Not IsArray($test_files) Then $test_files = StringSplit($test_files, "|")
				Local $mi_params_test_gui = GUICreate("MediaInfo Parameters Testing", 664, 400, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_MDICHILD, $GUI)
				GUICtrlCreateGroup("Test Results", 10, 12, 644, 376)
				Local $list_view = _GUICtrlListView_Create($mi_params_test_gui, "File|Track Type|Parameter|Result", 20, 32, 624, 342, BitOR($LVS_REPORT, $LVS_NOSORTHEADER), BitOR($WS_EX_CLIENTEDGE, $WS_EX_STATICEDGE, $WS_EX_DLGMODALFRAME))
				_GUICtrlListView_SetExtendedListViewStyle($list_view, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT))
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
				If $test_files[0] > 1 Then
					Local $start = 2
				Else
					Local $start = 1
				EndIf
				For $a = $start To $test_files[0]
					If $test_files[0] > 1 Then
						Local $path = $test_files[1] & "\" & $test_files[$a]
						Local $file = $test_files[$a]
					Else
						Local $path = $test_files[1]
						Local $file = StringSplit($test_files[$a], "\")
						$file = $file[$file[0]]
					EndIf
					$full_path = $path
					_GUICtrlListView_AddItem($list_view, $file)
					$item += 1
					For $b = 1 To 3
						Switch $b
							Case 1
								Local $track_type = "Video"
							Case 2
								Local $track_type = "Audio"
							Case 3
								Local $track_type = "Subtitles"
						EndSwitch
						Local $stream_count = __Get_MediaInfo($path, $media_info_handle, "StreamCount", 0, $track_type)
						For $c = 1 To $stream_count
							_GUICtrlListView_AddItem($list_view, "")
							_GUICtrlListView_AddSubItem($list_view, $item, $track_type, 1)
							$item += 1
							For $d = 1 To $query[0]
								Local $info_type = GUICtrlRead(Eval("parameter" & $d))
								_GUICtrlListView_AddItem($list_view, "")
								_GUICtrlListView_AddSubItem($list_view, $item, "", 1)
								_GUICtrlListView_AddSubItem($list_view, $item, $info_type, 2)
								Local $data = __Get_MediaInfo($path, $media_info_handle, $info_type, $c - 1, $track_type)
								If $data = "" Then
									_GUICtrlListView_AddSubItem($list_view, $item, "<No Data>", 3)
								Else
									_GUICtrlListView_AddSubItem($list_view, $item, $data, 3)
								EndIf
								$item += 1
							Next
						Next
					Next
				Next
				_GUICtrlListView_SetColumnWidth($list_view, 0, $LVSCW_AUTOSIZE)
				_GUICtrlListView_SetColumnWidth($list_view, 2, $LVSCW_AUTOSIZE)
				_GUICtrlListView_SetColumnWidth($list_view, 3, $LVSCW_AUTOSIZE)

				GUISetState(@SW_DISABLE, $mi_params_gui)
				GUISetState(@SW_SHOW, $mi_params_test_gui)
				While 1
					Local $nMsg8 = GUIGetMsg(1)
					If $nMsg8[1] = $mi_params_test_gui Then
						Switch $nMsg8[0]
							Case $GUI_EVENT_CLOSE
								GUISetState(@SW_ENABLE, $mi_params_gui)
								GUIDelete($mi_params_test_gui)
								ExitLoop
						EndSwitch
					EndIf
				WEnd
				#EndRegion Test Files
			Case Else
				_SQLite_QuerySingleRow($db, "select rowid from 'control_list_params' where ID='" & $nMsg7[0] & "';", $query)
				If $query[0] <> "" And $query[0] <> _SQLite_LastInsertRowID($db) Then
					GUISetState(@SW_SHOWNORMAL, $mi_params_gui)
					GUICtrlDelete($nMsg7[0])
					GUICtrlDelete(Eval("name" & $query[0]))
					GUICtrlDelete(Eval("parameter" & $query[0]))
					_SQLite_GetTable($db, "select ID from 'control_list_params';", $query_result2, $rows, $columns)
					_ArrayDelete($query_result2, "1")
					Local $start = _ArraySearch($query_result2, $nMsg7[0])
					For $a = $start To UBound($query_result2) - 2
						$position = ControlGetPos("", "", "[CLASS:Edit; INSTANCE:" & $a * 2 - 1 & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Edit; INSTANCE:" & $a * 2 - 1 & "]", $position[0], $position[1] - 40)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:Edit; INSTANCE:" & $a * 2 & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Edit; INSTANCE:" & $a * 2 & "]", $position[0], $position[1] - 40)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:Button; INSTANCE:" & $a & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Button; INSTANCE:" & $a & "]", $position[0], $position[1] - 40)
						EndIf
					Next
					_SQLite_Exec($db, "delete from 'control_list_params' where ID='" & $nMsg7[0] & "';")
					_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list_params';", $query)
					$position = _GUIScrollBars_GetScrollInfoPos($mi_params_gui, $SB_VERT)
					If $query[0] > 8 Then
						_GUIScrollBars_SetScrollInfoPos($mi_params_gui, $SB_VERT, $position - 5)
						_GUIScrollBars_SetScrollInfoMax($mi_params_gui, $SB_VERT, Round($query[0] * 2.8, 0))
					Else
						_GUIScrollBars_SetScrollInfoPos($mi_params_gui, $SB_VERT, 0)
						_GUIScrollBars_SetScrollInfoMax($mi_params_gui, $SB_VERT, 22)
					EndIf
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>_Define_Params

Func _Source()
	If @Compiled Then
		If FileGetSize(@AutoItExe) > 2097152 Then
			;uncoment the line below if compiling a portable version
			;#include "source.au3"
		EndIf
	EndIf
EndFunc   ;==>_Source

#cs
	Func __HungApp($iParam1, $iParam2)
	_SQLite_QuerySingleRow($db, "select pid from pid;", $query_result)
	_SQLite_Exec($db, "update pid set pid='recover';")
	Local $sql_query = _SQLite_QuerySingleRow($temp_db, "select * from TEMP;", $query_result2)
	If $sql_query = $SQLITE_OK Then _SQLite_Exec($db, "insert into pid ('pid') values ('execute');")
	_SQLite_Exec($db, "delete from sessions where file='" & $full_path & "';")
	__Log_Write("File " & $full_path & " caused MKVCleaver to crash. That file will be removed from the list." & @CRLF & "Restarting MKVCleaver" & @CRLF, 0, $session)
	If @Compiled Then
	Run(@AutoItExe, @ScriptDir)
	Else
	Run(@AutoItExe & ' "' & @ScriptFullPath & '"', @ScriptDir)
	EndIf
	ProcessClose($query_result[0])
	EndFunc   ;==>__HungApp
#ce

Func _Custom_FileName_Config($gui_to_hide, $title)
	Local $nMsg6
	Local $data
	Local $y = 64
	Local $ctrl_count = 1
	Local $position
	Local $query_result
	Local $query_result2
	Local $query_result3
	Local $query
	Local $error = 0
	Dim $lines[1][2]

	Local $sql_query = _SQLite_Exec($db, "drop table if exists 'control_list';" & "create table if not exists 'control_list' ('ID');")
	If $sql_query <> $SQLITE_OK Then
		MsgBox(4112, "Database Error", "Unable to write to the database due to an active transaction." & @CRLF & "" & @CRLF & "Please try again in a few seconds.", 10)
		WinActivate($title)
		Return
	EndIf
	#Region ### START Koda GUI section ### Form=c:\development\mkvcleaver\common\filter_gui.kxf
	$cust_filename_gui = GUICreate("Custom Filename Configuration", 520, 300, -1, -1, $WS_CAPTION + $WS_SYSMENU)
	Local $menu = GUICtrlCreateMenu("Menu")
	Local $filter_types = GUICtrlCreateMenuItem("Parameters Config", $menu, 1)
	Local $save = GUICtrlCreateMenuItem("Save", $menu, 2)
	GUICtrlCreateLabel("Edit Filename Placeholders:", 17, 5, 250, 20)
	GUICtrlSetFont(-1, Default, $FW_BOLD)
	GUICtrlCreateLabel("Name", 17, 42, 250, 17)
	GUICtrlCreateLabel("Parameter", 161, 42, 250, 17)
	GUICtrlCreateLabel("Example", 305, 42, 250, 17)
	Assign("place_holder" & $ctrl_count, GUICtrlCreateInput("", 17, $y, 128, 20), 1)
	Assign("variable_type" & $ctrl_count, GUICtrlCreateCombo("", 161, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
	Assign("example" & $ctrl_count, GUICtrlCreateInput("", 305, $y, 128, 20), 1)
	Local $add_next = GUICtrlCreateButton("Add", 448, 64, 40, 20)
	#EndRegion ### END Koda GUI section ###

	$sql_query = _SQLite_Exec($db, "insert into 'control_list' ('ID') values ('" & $add_next & "');")
	Local $data_types = IniReadSection($ini_file, "Parameters")
	If Not @error Then GUICtrlSetData(Eval("variable_type" & $ctrl_count), _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))

	Local $placeholders = IniReadSection($ini_file, "Placeholders")
	If Not @error Then
		$data = StringSplit($placeholders[1][1], "|")
		GUICtrlSetData(Eval("place_holder" & $ctrl_count), $data[1])
		GUICtrlSetData(Eval("variable_type" & $ctrl_count), $data[2])
		GUICtrlSetData(Eval("example" & $ctrl_count), $data[3])
		If $placeholders[0][0] > 1 Then
			For $a = 2 To $placeholders[0][0]
				$ctrl_count += 1
				$y += 40
				$data = StringSplit($placeholders[$a][1], "|")
				Assign("place_holder" & $ctrl_count, GUICtrlCreateInput("", 17, $y, 128, 20), 1)
				GUICtrlSetData(-1, $data[1])
				Assign("variable_type" & $ctrl_count, GUICtrlCreateCombo("", 161, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				GUICtrlSetData(-1, _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))
				GUICtrlSetData(-1, $data[2])
				Assign("example" & $ctrl_count, GUICtrlCreateInput("", 305, $y, 128, 20), 1)
				GUICtrlSetData(-1, $data[3])
				GUICtrlSetData($add_next, "Del")
				$add_next = GUICtrlCreateButton("Add", 448, $y, 40, 20)
				_SQLite_Exec($db, "insert into 'control_list' ('ID') values ('" & $add_next & "');")
			Next
		EndIf
	EndIf

	_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)

	_GUIScrollBars_Init($cust_filename_gui, Default, 2.5)
	_GUIScrollBars_ShowScrollBar($cust_filename_gui, $SB_VERT, True)

	GUISetState(@SW_SHOW, $cust_filename_gui)
	GUISetState(@SW_HIDE, $gui_to_hide)

	Local $unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)
	If $query[0] > 4 Then _GUIScrollBars_SetScrollInfoMax($cust_filename_gui, $SB_VERT, Round(($query[0] - 3) * 2.5, 0))

	While 1
		$nMsg6 = GUIGetMsg(1)
		Select
			Case $nMsg6[0] = $filter_types
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				If $unsaved_changes <> ($ctrl_count + $query[0] + _SQLite_LastInsertRowID($db)) Then
					Local $restore = 1
				Else
					Local $restore = 0
				EndIf
				_Define_Params($cust_filename_gui, "Custom Filename Configuration")
				Local $data_types = IniReadSection($ini_file, "Parameters")
				If IsArray($data_types) Then
					For $a = 1 To $ctrl_count
						Local $old_data = GUICtrlRead(Eval("variable_type" & $a))
						GUICtrlSetData(Eval("variable_type" & $a), "")
						GUICtrlSetData(Eval("variable_type" & $a), _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))
						If $old_data <> "" And _ArraySearch($data_types, $old_data, Default, Default, Default, 2) <> -1 Then GUICtrlSetData(Eval("variable_type" & $a), $old_data)
					Next
				Else
					For $a = 1 To $ctrl_count
						GUICtrlSetData(Eval("variable_type" & $a), "")
					Next
				EndIf
				If $restore = 0 Then
					_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
					$unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)
				EndIf
			Case $nMsg6[0] = $GUI_EVENT_CLOSE
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				If $unsaved_changes <> ($ctrl_count + $query[0] + _SQLite_LastInsertRowID($db)) Or $error = 1 Then
					#Region --- CodeWizard generated code Start ---
					;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Default Button=Second, Icon=Question
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(292, "Unsaved Changes", "You made changes to the placeholders." & @CRLF & @CRLF & "Do you want to close the module without saving the placeholders ?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes

						Case $iMsgBoxAnswer = 7 ;No
							;_SQLite_Exec($db, "delete from 'control_list' where rowid='" & _SQLite_LastInsertRowID($db) & "';")
							ContinueLoop
					EndSelect
					#EndRegion --- CodeWizard generated code Start ---
				EndIf
				GUISetState(@SW_SHOW, $gui_to_hide)
				GUIDelete($cust_filename_gui)
				WinActivate($title)
				_SQLite_Exec($db, "drop table 'control_list';")
				Return
			Case $nMsg6[0] = $add_next And $nMsg6[0] > 0
				GUISetState(@SW_SHOW, $cust_filename_gui)
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				$position = ControlGetPos("", "", "[CLASS:Button; INSTANCE:" & $query[0] & "]")
				$ctrl_count += 1
				$y = $position[1] + 40
				Assign("place_holder" & $ctrl_count, GUICtrlCreateInput("", 17, $y, 128, 20), 1)
				Assign("variable_type" & $ctrl_count, GUICtrlCreateCombo("", 161, $y, 128, 25, $CBS_DROPDOWNLIST), 1)
				If IsArray($data_types) Then GUICtrlSetData(-1, _ArrayToString($data_types, Default, 1, $data_types[0][0], "|", 0, 0))
				Assign("example" & $ctrl_count, GUICtrlCreateInput("", 305, $y, 128, 20), 1)
				GUICtrlSetData($add_next, "Del")
				$add_next = GUICtrlCreateButton("Add", 448, $y, 40, 20)
				_SQLite_Exec($db, "insert into 'control_list' ('ID') values ('" & $add_next & "');")
				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				If $query[0] > 4 Then
					_GUIScrollBars_SetScrollInfoMax($cust_filename_gui, $SB_VERT, Round(($query[0] - 3) * 2.5, 0))
				Else
					_GUIScrollBars_SetScrollInfoMax($cust_filename_gui, $SB_VERT, 5)
				EndIf
			Case $nMsg6[0] = $save
				Local $save_line
				Local $row = -1

				_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
				_SQLite_Query($db, "select rowid from 'control_list';", $query_result)
				For $a = 1 To $query[0]
					_SQLite_FetchData($query_result, $query_result2, Default, True)
					$save_line = ""
					If GUICtrlRead(Eval("place_holder" & $query_result2[0])) = "" Or GUICtrlRead(Eval("variable_type" & $query_result2[0])) = "" Then ContinueLoop
					$save_line = GUICtrlRead(Eval("place_holder" & $query_result2[0]))
					Select
						Case StringInStr($save_line, ">")
							$error = 1
						Case StringInStr($save_line, "<")
							$error = 1
						Case StringInStr($save_line, "+")
							$error = 1
						Case Not StringRegExp($save_line, "(^\[.+\]$)")
							$error = 1
						Case StringInStr($save_line, "[tracktype#]")
							$error = 1
						Case StringInStr($save_line, "[track#]")
							$error = 1
						Case StringInStr($save_line, "[tracktype]")
							$error = 1
						Case StringInStr($save_line, "[filename]")
							$error = 1
						Case StringInStr($save_line, "[lng]")
							$error = 1
						Case StringInStr($save_line, "[lng3]")
							$error = 1
						Case StringInStr($save_line, "[lngf]")
							$error = 1
						Case StringInStr($save_line, "[delay]")
							$error = 1
						Case StringInStr($save_line, "[adelay]")
							$error = 1
						Case Else
							$error = 0
					EndSelect
					If $error = 1 Then
						#Region --- CodeWizard generated code Start ---
						;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
						MsgBox(16, "Error", "Icorrect syntax." & @CRLF & @CRLF & 'Placeholder name(s) you entered has wrong sytax.' & @CRLF & @CRLF & "The name must be enclosed with [ ] brackets and exclude " & @CRLF & "< > and + characters. Built-in placeholders are not allowed." & @CRLF & @CRLF & "Please correct the syntax and save before closing the dialog.")
						#EndRegion --- CodeWizard generated code Start ---
						ExitLoop
					EndIf
					$save_line &= "|" & GUICtrlRead(Eval("variable_type" & $query_result2[0]))
					$save_line &= "|" & GUICtrlRead(Eval("example" & $query_result2[0]))
					_ArrayAdd($lines, $a & "+" & $save_line, Default, "+")
				Next
				_SQLite_QueryFinalize($query_result)
				If $error = 0 Then
					IniDelete($ini_file, "Placeholders")
					IniWriteSection($ini_file, "Placeholders", $lines, 1)
					$unsaved_changes = $query[0] + $ctrl_count + _SQLite_LastInsertRowID($db)
					MsgBox(64, "Saved", "The placeholders were saved successfully.", 10, $cust_filename_gui)
				EndIf
				Dim $lines[1][2]
			Case Else
				_SQLite_QuerySingleRow($db, "select rowid from 'control_list' where ID='" & $nMsg6[0] & "';", $query)
				If $query[0] <> "" And $query[0] <> _SQLite_LastInsertRowID($db) Then
					GUISetState(@SW_SHOWNORMAL, $cust_filename_gui)
					GUICtrlDelete($nMsg6[0])
					GUICtrlDelete(Eval("place_holder" & $query[0]))
					GUICtrlDelete(Eval("variable_type" & $query[0]))
					GUICtrlDelete(Eval("example" & $query[0]))
					Local $rows, $columns
					_SQLite_GetTable($db, "select ID from 'control_list';", $query_result2, $rows, $columns)
					_ArrayDelete($query_result2, "1")
					Local $start = _ArraySearch($query_result2, $nMsg6[0])
					For $a = $start To UBound($query_result2) - 1
						If $a = 1 Then
							_SQLite_Query($db, "select rowid from 'control_list';", $query_result3)
							_SQLite_FetchData($query_result3, $query_result, Default, True)
							_SQLite_QueryFinalize($query_result3)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:Edit; INSTANCE:" & (2 * ($a - 1) + 1) & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Edit; INSTANCE:" & (2 * ($a - 1) + 1) & "]", $position[0], $position[1] - 40)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:ComboBox; INSTANCE:" & $a & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:ComboBox; INSTANCE:" & $a & "]", $position[0], $position[1] - 40)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:Edit; INSTANCE:" & (2 * ($a - 1) + 2) & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Edit; INSTANCE:" & (2 * ($a - 1) + 2) & "]", $position[0], $position[1] - 40)
						EndIf
						$position = ControlGetPos("", "", "[CLASS:Button; INSTANCE:" & $a & "]")
						If IsArray($position) Then
							ControlMove("", "", "[CLASS:Button; INSTANCE:" & $a & "]", $position[0], $position[1] - 40)
						EndIf
					Next
					_SQLite_Exec($db, "delete from 'control_list' where ID='" & $nMsg6[0] & "';")
					_SQLite_QuerySingleRow($db, "select count(rowid) from 'control_list';", $query)
					$position = _GUIScrollBars_GetScrollInfoPos($cust_filename_gui, $SB_VERT)
					If $query[0] > 4 Then
						_GUIScrollBars_SetScrollInfoPos($cust_filename_gui, $SB_VERT, $position - 5)
						_GUIScrollBars_SetScrollInfoMax($cust_filename_gui, $SB_VERT, Round(($query[0] - 3) * 2.5, 0))
					Else
						_GUIScrollBars_SetScrollInfoPos($cust_filename_gui, $SB_VERT, 0)
						_GUIScrollBars_SetScrollInfoMax($cust_filename_gui, $SB_VERT, 5)
					EndIf
				EndIf
		EndSelect
	WEnd

EndFunc   ;==>_Custom_FileName_Config

Func _Custom_FileList_Config()
	Local $file
	Local $file_format
	Local $nMsg7, $nMsg8
	Local $item
	Local $width
	Local $reload = 0
	Local $main_db = $db
	Local $prev_file

	#Region ### START Koda GUI section ### Form=n:\mkvcleaver\common\file list editor.kxf
	$fl_layout_editor = GUICreate("File List Layout Editor", 626, 268, -1, -1, -1, -1, $GUI)
	Global $example_tv = GUICtrlCreateTreeView(16, 16, 593, 233, BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_CHECKBOXES, $WS_HSCROLL, $WS_VSCROLL, $WS_BORDER))
	GUICtrlSetTip(-1, "Right click for more options", "Example Window", 1)
	Local $example_tvcontext = GUICtrlCreateContextMenu($example_tv)
	Local $fl_load_file = GUICtrlCreateMenuItem("Load MKV", $example_tvcontext)
	Local $fl_title_edit = GUICtrlCreateMenuItem("Edit Title", $example_tvcontext)
	Local $fl_si_edit_menu = GUICtrlCreateMenu("Edit Sub-Items", $example_tvcontext)
	Local $fl_video = GUICtrlCreateMenuItem("Video", $fl_si_edit_menu)
	Local $fl_audio = GUICtrlCreateMenuItem("Audio", $fl_si_edit_menu)
	Local $fl_subs = GUICtrlCreateMenuItem("Subs", $fl_si_edit_menu)

	GUISetState(@SW_DISABLE, $GUI)
	GUISetState(@SW_SHOW, $fl_layout_editor)
	#EndRegion ### END Koda GUI section ###

	$db = _SQLite_Open()
	__Tables_Create()

	While 1
		If $reload = 0 Then $nMsg7 = GUIGetMsg(1)
		If $file = "" Then $file = $prev_file
		Switch $nMsg7[0]
			Case $GUI_EVENT_CLOSE
				GUISetState(@SW_ENABLE, $GUI)
				GUIDelete($fl_layout_editor)
				Sleep(50)
				WinActivate("MKVcleaver " & $version)
				$db = $main_db
				Return
			Case $fl_load_file
				If $reload = 0 Then
					$file = FileOpenDialog("Select Files To Open", "", "Matroska (*.mkv; *.mka; *.mks; *.webm)|All (*.*)", 3)
					If @error Then ContinueLoop
					$prev_file = $file
				EndIf
				_GUICtrlTreeView_DeleteAll($example_tv)
				$reload = 0
				If $file = "" Then ContinueLoop
				$file_format = __Get_MediaInfo($file, $media_info_handle, "General;%Format%")
				If Not StringInStr($file_format, "Matroska") And Not StringInStr($file_format, "WebM") Then
					#Region --- CodeWizard generated code Start ---
					;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
					MsgBox(16, "Unrecognized Format", "Selected file does not appear to be Matroska.", 5)
					#EndRegion --- CodeWizard generated code Start ---
					ContinueLoop
				EndIf
				_Add_Files($file, $example_tv, 0)
			Case $fl_title_edit
				__Edit_Title_GUI("Custom Title Form", "all")
				_SQLite_Exec($db, "delete from sessions where file='" & $file & "';")
				$reload = 1
				$nMsg7[0] = $fl_load_file
			Case $fl_video
				__Edit_Title_GUI("Custom Video Item Form", "Video")
				_SQLite_Exec($db, "delete from sessions where file='" & $file & "';")
				$reload = 1
				$nMsg7[0] = $fl_load_file
			Case $fl_audio
				__Edit_Title_GUI("Custom Audio Item Form", "Audio")
				_SQLite_Exec($db, "delete from sessions where file='" & $file & "';")
				$reload = 1
				$nMsg7[0] = $fl_load_file
			Case $fl_subs
				__Edit_Title_GUI("Custom Subtitles Item Form", "Text")
				_SQLite_Exec($db, "delete from sessions where file='" & $file & "';")
				$reload = 1
				$nMsg7[0] = $fl_load_file
		EndSwitch
	WEnd
EndFunc   ;==>_Custom_FileList_Config

