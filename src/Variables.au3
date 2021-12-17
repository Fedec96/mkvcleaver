Local $GUI
Local $std
Local $szDrive
Local $szDir
Local $szFName
Local $szExt
Local $omit
Local $last_current
Local $all_checked = 0
Local $cmd
Local $output
Local $nMsg, $nMsg2, $nMsg3
Local $process_list
Local $cmd2
Local $session_recover
Local $msecs
Local $check_write
Local $custom_commands
Local $full_path
Local $extract_attachments
Local $execute
Local $attachments
Local $chapters
Local $cuesheets
Local $tags
Local $timecodes
Local $cmd3
Local $multiplyer = 1
Local $call = 0
Local $no_execute = 0
Local $tc_only
Local $tc_with_tracks
Local $cancel = 0
Local $continue = 0
Local $h264
Local $file_split
Local $about_ok = 0x1
Local $about_gui
Local $std_mkvm
Local $version
Local $get_info
Local $statusbar
Local $mkvtlnix_path
Local $media_info_dll
Local $media_info_handle
Local $mkvinfo
Local $current
Local $selection_text
Local $logo
Local $html
Local $codec_get_file
Local $files
Local $path_type
Local $path_split
Local $file_array
Local $file_format
Local $video_count
Local $audio_count
Local $subs_count
Local $split_path
Local $item
Local $v_codecs_string
Local $v_codec
Local $track_id
Local $track_id_split
Local $a_lng_string
Local $lng
Local $codec
Local $codecs_string
Local $a_codecs_string
Local $a_codec
Local $s_lng_String
Local $s_codec
Local $s_codecs_string
Local $index
Local $info_edit
Local $file
Local $one_by_one
Local $del_index
Local $dir_select
Local $save_to
Local $destination
Local $file_total
Local $log_file
Local $child
Local $command
Local $tracklist_item
Local $fps
Local $return
Local $file_name
Local $new_ext
Local $identify
Local $sbText
Local $match
Local $extract_path
Local $attachID
Local $attach_filename
Local $extention_get
Local $return
Local $split_command
Local $track_index
Local $codec_id
Local $track_type
Local $track_num
Local $track_num_sorter
Local $track_sorter
Local $batch_item_split
Local $custom_extension
Local $find
Local $command_path
Local $timecodes_raw
Local $context_menu
Local $context_menu1
Local $avdump_split
Local $std_split
Local $curr_percent
Local $atrack
Local $msg_now
Local $no_toolnix = 0
Local $max_a
Local $max_s
Local $max_v
Local $number
Local $resize_bit = 0
Local $cursor
Local $detect_item
Local $text
Local $info
Local $timediff
Local $timer = 0
Local $item_count
Local $button_state
Local $array_search1
Local $array_search2
Local $true
Local $nMsg_handle
Local $hl
Local $find_error
Local $codec_list
Local $sheck_link = 0x1
Local $autoit_link = 0x1
Local $mediainfo_link = 0x1
Local $avc2avi_link = 0x1
Local $avdump_link = 0x1
Local $mkvtoolnix_link = 0x1
Local $ogmcleaver_link = 0x1
Local $mkvcleaver_link = 0x1
Local $clean
Local $error_count = 0
Local $warning_count = 0
Local $find_warning
Local $max_log_age = "30D"
Local $log_view_filter = "0;This Session"
Local $warning_log
Local $error_log
Local $last_error_count = 0
Local $last_warning_count
Local $channel_count
Local $omit_count = 0
Local $ext_list_item
Local $curr_codec
Local $last_codec
Local $last_ext
Local $curr_ext
Local $mkvex_version
Local $z = 0
Local $full_exec = 1
Local $vfr_detect = 1
Local $std_error = 0
Local $session_file
Local $session_user_set
If @Compiled Then
	If FileGetSize(@AutoItExe) > 2097152 Then
		Local $working_dir = @ScriptDir
	Else
		Local $working_dir = @LocalAppDataDir & "\MKVCleaver"
	EndIf
Else
	Local $working_dir = @LocalAppDataDir & "\MKVCleaver"
EndIf
Local $ini_file = $working_dir & "\custom.ini"
Local $db_file_path = $working_dir & "\mkvcleaver_db.sqlite"
Local $command_file
Local $ext
Local $codec_get_gui
Local $ext_manage_gui
Local $out_file
Local $version_online
Local $update_msg = ""
Local $bits = ""
Local $update_menu_item = 1
Local $fn_custom_GUI
Local $chapters_chkbx
Local $tags_chkbx
Local $gui_size
Local $out_file_check
Local $file_inform
Local $file_inform_gui
Local $nMsg5
Local $row
Local $last_nMsg
Local $query
Local $query_result
Local $query_result2
Local $state
Local $check_selected
Local $session
Local $vfr
Local $vfrconv
Local $redirect_output = 0
Local $recovery
Local $temp_db
Local $codec_list_handle
Local $tv_ctrl_id
Local $utf_convert
Local $go_go
Global $fl_layout_editor
Global $line_title = IniRead($ini_file, "GUI", "line_title", "")
Global $line_video = IniRead($ini_file, "GUI", "line_video", "")
Global $line_audio = IniRead($ini_file, "GUI", "line_audio", "")
Global $line_text = IniRead($ini_file, "GUI", "line_text", "")
Global $batch_filter_gui
Global $cust_filename_gui
Global $fn_custom_GUI
Global $debug = IniRead($ini_file, "Debug", "debug", 0)
Dim $aDroppedFiles[1]