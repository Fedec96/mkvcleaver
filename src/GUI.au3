Local $GUI = GUICreate("MKVcleaver " & $version, 733, 628, -1, -1, BitOR($WS_SIZEBOX, $WS_MINIMIZEBOX, $WS_MAXIMIZEBOX), $WS_EX_ACCEPTFILES)
Local $progress1 = GUICtrlCreateProgress(7, 530, 355, 20, $PBS_SMOOTH)
Local $progress2 = GUICtrlCreateProgress(365, 530, 357, 20, $PBS_SMOOTH)
Local $GUI_Number = Number($GUI)
Local $menu = GUICtrlCreateMenu("Settings")
Local $tc_menu = GUICtrlCreateMenu("Timecodes", $menu, 1)
Local $tc_only = GUICtrlCreateMenuItem("Timecodes Only", $tc_menu, 0, 1)
Local $tc_with_tracks = GUICtrlCreateMenuItem("Timecodes With Tracks", $tc_menu, 1, 1)
If IniRead($ini_file, "Files", "tc_tracks", "1") = 0 Then
	GUICtrlSetState($tc_only, $GUI_CHECKED)
	$no_execute = 1
Else
	GUICtrlSetState($tc_with_tracks, $GUI_CHECKED)
EndIf
Local $resize_menu = GUICtrlCreateMenu("Remember Position", $menu, 2)
Local $resize_on = GUICtrlCreateMenuItem("On", $resize_menu, 0, 1)
Local $resize_off = GUICtrlCreateMenuItem("Off", $resize_menu, 1, 1)
GUICtrlSetState($resize_off, $GUI_CHECKED)
Local $sd_menu = GUICtrlCreateMenu("Shutdown PC", $menu, 4)
Local $sd_off = GUICtrlCreateMenuItem("Off", $sd_menu, 0, 1)
Local $sd_once = GUICtrlCreateMenuItem("Shutdown Just This Time", $sd_menu, 1, 1)
Local $sd_on = GUICtrlCreateMenuItem("Shutdown Every Time", $sd_menu, 2, 1)
Local $chapter_opts = GUICtrlCreateMenu("Chapters", $menu, 5)
Local $chapters_simple = GUICtrlCreateMenuItem("Simple Chapters", $chapter_opts, 1, 1)
Local $chapters_xml = GUICtrlCreateMenuItem("XML Chapters", $chapter_opts, 2, 1)
If IniRead($ini_file, "Files", "chapters_s", 0) = 1 Then
	GUICtrlSetState($chapters_simple, $GUI_CHECKED)
	Local $chapters_switch = "-s"
Else
	GUICtrlSetState($chapters_xml, $GUI_CHECKED)
	Local $chapters_switch = ""
EndIf
Local $vfr_opt = GUICtrlCreateMenu("VFR Detection", $menu, 6)
Local $vfr_off = GUICtrlCreateMenuItem("Off", $vfr_opt, 0, 1)
Local $vfr_quick = GUICtrlCreateMenuItem("Quick", $vfr_opt, 1, 1)
Local $vfr_full = GUICtrlCreateMenuItem("Full", $vfr_opt, 2, 1)
$vfr_detect = IniRead($ini_file, "Files", "vfr", 0)
Switch $vfr_detect
	Case 0
		GUICtrlSetState($vfr_off, $GUI_CHECKED)
		Local $vfr_mode
	Case 1
		GUICtrlSetState($vfr_quick, $GUI_CHECKED)
		Local $vfr_mode = "Quick"
	Case 2
		GUICtrlSetState($vfr_full, $GUI_CHECKED)
		Local $vfr_mode = "Full"
EndSwitch
Local $update_options = GUICtrlCreateMenu("Updates Check", $menu, 6)
Local $update_check = GUICtrlCreateMenuItem("Check for Updates", $update_options, 1, 1)
Local $update_not_check = GUICtrlCreateMenuItem("Do Not Check for Updates", $update_options, 2, 1)
Local $log_settings = GUICtrlCreateMenuItem("Log Settings", $menu, 7)
Local $sendtomenu = 1000000 ;random high number
Local $send_to = 1000000 ;random high number
Local $send_to_remove = 1000000 ;random high number
If @Compiled Then
	If FileGetSize(@AutoItExe) > 2097152 Then
		$sendtomenu = GUICtrlCreateMenu('Explorer "Send To" Menu', $menu, 8)
		$send_to = GUICtrlCreateMenuItem('Add To "Send To" Menu', $sendtomenu, 0)
		$send_to_remove = GUICtrlCreateMenuItem('Remove From "Send To" Menu', $sendtomenu, 1)
	EndIf
EndIf
Local $session_save_ask = GUICtrlCreateMenu("Session Settings", $menu, 9)
Local $session_save = GUICtrlCreateMenuItem("Ask To Save Session", $session_save_ask, 1, 1)
Local $session_not_save = GUICtrlCreateMenuItem("Don't Ask To Save Session", $session_save_ask, 2, 1)
If IniRead($ini_file, "GUI", "session", 1) = 1 Then
	GUICtrlSetState($session_save, $GUI_CHECKED)
	Local $session_saver = 1
Else
	GUICtrlSetState($session_not_save, $GUI_CHECKED)
	Local $session_saver = 0
EndIf
If IniRead($ini_file, "Updates", "Auto", 1) = 1 Then
	GUICtrlSetState($update_check, $GUI_CHECKED)
	Local $update_me = "1"
Else
	GUICtrlSetState($update_not_check, $GUI_CHECKED)
	Local $update_me = "0"
EndIf

;Local $multi_threading_menu = GUICtrlCreateMenu("Multithreding", $menu, 10)
;Local $mt_off = GUICtrlCreateMenuItem("Off", $multi_threading_menu, 1, 1)
;Local $mt_set = GUICtrlCreateMenuItem("Set Number of Threads", $multi_threading_menu, 2, 1)
;If IniRead($ini_file, "Multithreding", "Thread Count", 0) = 0 Then
;	GUICtrlSetState($mt_off, $GUI_CHECKED)
;	Local $mt_state = 0
;Else
;	GUICtrlSetState($mt_set, $GUI_CHECKED)
;	Local $mt_state = IniRead($ini_file, "Multithreding", "Thread Count", 0)
;EndIf

If $update_me = 1 Then
	If @Compiled Then
		Local $dns_query = _dig("sapib.ca", "8.8.8.8", Default, "TXT", Default, Default, Default)
		Local $find_link = _StringBetween($dns_query, '"update_url=', '"')
	Else
		Dim $find_link[1] = ["https://private.sapib.ca/mkvcleaver/version.php"]
	EndIf
	If Not @error Then
		Local $inet
		Local $temp_file = _WinAPI_GetTempFileName(@TempDir)
		$version_online = InetGet($find_link[0] & "?v=2", $temp_file, 3, 1)
		$timer = TimerInit()
		Do
			Sleep(50)
			$timediff = TimerDiff($timer)
			$inet = InetGetInfo($version_online, 3)
		Until $inet = True Or $timediff >= 3000
		InetClose($version_online)
		If $inet = True Then
			$version_online = FileRead($temp_file)
			Local $json = json_decode($version_online)
			If json_isobject($json) Then
				$version_online = json_objget($json, "version")
				If Int($version_online) > Int(StringReplace($version, ".", "")) Or Not @Compiled Then
					Switch json_objget($json, "type")
						Case "major"
							$update_msg = "Major Update Availble"
						Case "minor"
							$update_msg = "Minor Update Availble"
					EndSwitch
					If json_objget($json, "message") <> "None" And json_objget($json, "message") <> "" Then
						#Region --- CodeWizard generated code Start ---
						;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
						MsgBox(64, "Update Message", json_objget($json, "message"), 10)
						WinActivate("MKVcleaver " & $version)
						#EndRegion --- CodeWizard generated code Start ---
					EndIf
				EndIf
			EndIf
			FileDelete($temp_file)
			$temp_file = 0
			$inet = 0
		Else
			MsgBox(16, "No Connection", "Unable to retrieve the update URL." & @CRLF & @CRLF & "Please make sure MKVCleaver can connect to the Internet.", 5)
		EndIf
	Else
		MsgBox(16, "No Connection", "Unable to retrieve the update URL." & @CRLF & @CRLF & "Please make sure MKVCleaver can connect to the Internet.", 5)
	EndIf
EndIf
Local $tools_menu = GUICtrlCreateMenu("Tools")
Local $ext_edit = GUICtrlCreateMenuItem("Edit Extensions", $tools_menu, 0)
Local $codec_get = GUICtrlCreateMenuItem("Get Codec(s) From File", $tools_menu, 1)
Local $open_log = GUICtrlCreateMenuItem("View Log", $tools_menu, 3)
Local $xml_converter = GUICtrlCreateMenuItem("XML2CellTimes Converter", $tools_menu, 4)
Local $help_menu = GUICtrlCreateMenu("Help")
Local $help = GUICtrlCreateMenuItem("Local Help File", $help_menu, 0)
Local $online_help = GUICtrlCreateMenuItem("Online Support", $help_menu, 1)
Local $online_forum = GUICtrlCreateMenuItem("Doom9 Forum", $help_menu, 3)
Local $email_me = GUICtrlCreateMenuItem("Email Support", $help_menu, 2)
Local $report_bugs = GUICtrlCreateMenuItem("Report a Bug", $help_menu, 4)
Local $donate = GUICtrlCreateMenuItem("Donate", $help_menu, 5)
Local $about = GUICtrlCreateMenuItem("About", $help_menu, 6)
Local $ftp = GUICtrlCreateGroup("Files to process", 7, 8, 481, 450, -1)
GUICtrlSetColor(-1, 0x0000FF)
If $update_msg <> "" And $update_me = "1" Then
	Local $update_menu = GUICtrlCreateMenu($update_msg)
	Local $update_menu_item = GUICtrlCreateMenuItem("Get Update", $update_menu)
EndIf
Local $removemkvs = GUICtrlCreateButton("Remove selected files from list", 247, 23, 231, 21, $WS_GROUP)
Local $file_list = GUICtrlCreateTreeView(18, 48, 459, 401, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT, $TVS_CHECKBOXES, $TVS_NOHSCROLL, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
GUICtrlSetState($file_list, $GUI_DROPACCEPTED)
GUICtrlSetTip($file_list, "Right click for more options", "File List", 1)
Local $open_mkvs = GUICtrlCreateButton("Open MKV files to process...", 17, 23, 227, 21, $WS_GROUP)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Local $od = GUICtrlCreateGroup("Output directory (leave blank to extract to the source directory)", 8, 467, 481, 53)
GUICtrlSetColor(-1, 0x0000FF)
Local $save_path_input = GUICtrlCreateInput("", 21, 487, 420, 21)
GUICtrlSetData(-1, IniRead($ini_file, "Files", "dst_path", ""))
Local $save_path = GUICtrlCreateButton("...", 448, 485, 30, 24, $WS_GROUP)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Local $batch_mode_type = GUICtrlCreateGroup("Tracks to extract (Batch Mode)", 499, 41, 222, 260)
GUICtrlSetColor(-1, 0x0000FF)
Local $tracklist = GUICtrlCreateTreeView(509, 57, 202, 233, $TVS_CHECKBOXES, $WS_EX_CLIENTEDGE)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Local $toolnix_path = GUICtrlCreateButton("Locate MKVToolNix...", 499, 15, 125, 21, $WS_GROUP)
Local $selection_mode = GUICtrlCreateButton("Batch Filter", 627, 15, 94, 21, $WS_GROUP)
GUICtrlCreateGroup("Filename options", 499, 306, 222, 81)
GUICtrlSetColor(-1, 0x0000FF)
Local $tr_fn_chk = GUICtrlCreateRadio("Track#_<filename>", 509, 322, 120, 19)
Local $fn_tr_chk = GUICtrlCreateRadio("<filename>_Track#", 509, 339, 120, 19)
Local $tropt_chk = GUICtrlCreateCheckbox("Use 'Video', 'Audio' and 'Subtitle'", 520, 361, 175, 16, $WS_GROUP)
Local $fn_custom = GUICtrlCreateButton("Custom...", 630, 336, 80, 21, $WS_GROUP)
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUICtrlCreateGroup("Video options", 499, 394, 222, 64)
GUICtrlSetColor(-1, 0x0000FF)
Local $cntoavi = GUICtrlCreateCheckbox("Convert H.264 tracks to AVI files", 509, 410, 200, 16, $WS_GROUP)
Local $vfrtocfr = GUICtrlCreateCheckbox("Convert VFR video to CFR", 509, 430, 200, 16, $WS_GROUP)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Local $go = GUICtrlCreateButton("Extract Tracks !", 499, 471, 222, 48, $WS_GROUP)
$statusbar = _GUICtrlStatusBar_Create($GUI)

GUIRegisterMsg($WM_SIZE, "__Stb_Resize")
GUIRegisterMsg($WM_DROPFILES, "__WM_DROPFILES")
GUIRegisterMsg($WM_VSCROLL, "__WM_VSCROLL")

GUICtrlSetFont($file_list, 10, 800, 0, "Arial")
GUICtrlSetColor($file_list, 0x7b68ee)
GUICtrlSetFont($tracklist, 9, 800, 0, "Arial")
GUICtrlSetColor($tracklist, 0x7b68ee)
GUICtrlSetResizing($vfrtocfr, $GUI_DOCKAUTO)
GUICtrlSetResizing($open_mkvs, $GUI_DOCKAUTO)
GUICtrlSetResizing($removemkvs, $GUI_DOCKAUTO)
GUICtrlSetResizing($save_path_input, $GUI_DOCKAUTO + $GUI_DOCKHEIGHT)
GUICtrlSetResizing($save_path, $GUI_DOCKAUTO + $GUI_DOCKHEIGHT)
GUICtrlSetResizing($selection_mode, $GUI_DOCKAUTO)
GUICtrlSetResizing($toolnix_path, $GUI_DOCKAUTO)
GUICtrlSetResizing($go, $GUI_DOCKHEIGHT + $GUI_DOCKAUTO)
GUICtrlSetResizing($cntoavi, $GUI_DOCKAUTO)
GUICtrlSetResizing($fn_custom, $GUI_DOCKAUTO)

Local $sd = IniRead($ini_file, "Shutdown Menu", "shutdown", 0)
Switch $sd
	Case 0
		GUICtrlSetState($sd_off, $GUI_CHECKED)
	Case 1
		GUICtrlSetState($sd_once, $GUI_CHECKED)
	Case 2
		GUICtrlSetState($sd_on, $GUI_CHECKED)
EndSwitch
Local $maximize = IniRead($ini_file, "GUI", "maximized", 0)
Local $resize = IniRead($ini_file, "GUI", "resize", 0)
If $resize = 1 And $maximize = 1 Then
	GUISetState(@SW_MAXIMIZE, $GUI)
	$resize_bit = 1
	GUICtrlSetState($resize_on, $GUI_CHECKED)
	GUICtrlSetState($resize_off, $GUI_UNCHECKED)
EndIf
GUICtrlSetState($go, $GUI_DISABLE)
GUICtrlSetState($removemkvs, $GUI_DISABLE)
$mkvtlnix_path = IniRead($ini_file, "Mkvtlnix_Path", "path", "")
If $mkvtlnix_path = "" Then
	If $bits = " - 64 bit" Then
		$mkvtlnix_path = RegRead("HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\MkvToolNix", "UninstallString")
		If $mkvtlnix_path = "" Then $mkvtlnix_path = RegRead("HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\MkvToolNix", "UninstallString")
	Else
		$mkvtlnix_path = RegRead("HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\MkvToolNix", "UninstallString")
	EndIf
	If $mkvtlnix_path <> "" Then
		_PathSplit($mkvtlnix_path, $szDrive, $szDir, $szFName, $szExt)
		$mkvtlnix_path = StringMid($szDrive & $szDir, 1, StringLen($szDrive & $szDir) - 1)
		IniWrite($ini_file, "Mkvtlnix_Path", "path", $mkvtlnix_path)
	EndIf
EndIf
$media_info_dll = DllOpen(@ScriptDir & "\MediaInfo.dll")
If $media_info_dll = -1 Then
	MsgBox(16, "Error", "MKVcleaver was unable to load MediaInfo DLL." & @CRLF & @CRLF & "Reinstalling the application may fix the issue.")
	Exit
EndIf
$media_info_handle = __Get_MediaInfo("", $media_info_handle)
If $mkvtlnix_path <> "" And Not FileExists($mkvtlnix_path & "\mkvextract.exe") Or $mkvtlnix_path <> "" And Not FileExists($mkvtlnix_path & "\mkvmerge.exe") Then
	MsgBox(48, "Warning", "Mkvextract.exe and/or Mkvmerge.exe was not found." & @CRLF & @CRLF & "Make sure that the path to the files is correct.")
	$no_toolnix = 1
ElseIf $mkvtlnix_path <> "" Then
	$mkvex_version = FileGetVersion($mkvtlnix_path & "\mkvextract.exe")
	$mkvex_version = StringReplace($mkvex_version, ".", "")
	If $mkvex_version < 17000 Then
		MsgBox(48, "Warning", "Mkvextract.exe on your system is out of date." & @CRLF & @CRLF & "Versions below 17 are no longer supported.")
		$no_toolnix = 1
	EndIf
EndIf
GUICtrlSetState($tr_fn_chk, IniRead($ini_file, "GUI", "filename1", $GUI_UNCHECKED))
GUICtrlSetState($fn_tr_chk, IniRead($ini_file, "GUI", "filename2", $GUI_CHECKED))
GUICtrlSetState($tropt_chk, IniRead($ini_file, "GUI", "fileopts", $GUI_UNCHECKED))
GUICtrlSetState($cntoavi, IniRead($ini_file, "GUI", "aviconvert", $GUI_UNCHECKED))
If GUICtrlRead($cntoavi) = $GUI_UNCHECKED Then
	GUICtrlSetState($vfrtocfr, $GUI_UNCHECKED)
Else
	GUICtrlSetState($vfrtocfr, IniRead($ini_file, "GUI", "vfrconvert", $GUI_UNCHECKED))
EndIf

;Version 0.7.0.0 custom filename syntax change notification
If IniRead($ini_file, "Files", "filename", "") <> "" And IniRead($ini_file, "Files", "custom_filename", "0") = "0" Then
	MsgBox(64, "Syntax Change", "Note: The syntax for custom filenames has changed since version 0.7.0.0. Please review the documentation and correct any outdated placeholders.", 10)
	IniWrite($ini_file, "Files", "custom_filename", IniRead($ini_file, "Files", "filename", ""))
EndIf

Local $fn_custom_formula = IniRead($ini_file, "Files", "custom_filename", "")
If $fn_custom_formula <> "" Then
	GUICtrlSetState($tr_fn_chk, $GUI_DISABLE)
	GUICtrlSetState($fn_tr_chk, $GUI_DISABLE)
	GUICtrlSetState($tropt_chk, $GUI_DISABLE)
EndIf
GUISetState(@SW_SHOW)
If GUICtrlRead($fn_tr_chk) = $GUI_UNCHECKED Then GUICtrlSetState($tropt_chk, $GUI_DISABLE)
If GUICtrlRead($cntoavi) = $GUI_UNCHECKED Then GUICtrlSetState($vfrtocfr, $GUI_DISABLE)

Local $position = IniReadSection($ini_file, "GUI")
If Not @error And $resize = 1 And $maximize = 0 Then
	WinMove("MKVcleaver " & FileGetVersion(@AutoItExe), "", $position[1][1], $position[2][1], $position[3][1], $position[4][1])
	$resize_bit = 1
	GUICtrlSetState($resize_on, $GUI_CHECKED)
	GUICtrlSetState($resize_off, $GUI_UNCHECKED)
EndIf
$position = ""

Local $file_list_menu = GUICtrlCreateContextMenu($file_list)
Local $file_list_menu_config = GUICtrlCreateMenuItem("Edit Layout", $file_list_menu)
Local $file_list_menu_info = GUICtrlCreateMenuItem("File Info", $file_list_menu)

Local $DebugMenuItem = GUICtrlCreateMenu("Debug", $menu)
Local $DebugMenuItemOn = GUICtrlCreateMenuItem("On", $DebugMenuItem, 0, 1)
Local $DebugMenuItemOff = GUICtrlCreateMenuItem("Off", $DebugMenuItem, 1, 1)

If IniRead($ini_file, "Debug", "debug", "0") = "0" Then
	GUICtrlSetState($DebugMenuItemOff, $GUI_CHECKED)
	GUICtrlSetState($DebugMenuItemOn, $GUI_UNCHECKED)
Else
	GUICtrlSetState($DebugMenuItemOff, $GUI_UNCHECKED)
	GUICtrlSetState($DebugMenuItemOn, $GUI_CHECKED)
EndIf
