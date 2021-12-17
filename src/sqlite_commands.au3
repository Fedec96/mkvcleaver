#include-once

_SQLite_Startup()
Global $db = _SQLite_Open($db_file_path)
ConsoleWrite("opening db: " & @error & @CRLF)
If $db = 0 Then
	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
	MsgBox(16, "Database Error", "Cannot open database file." & @CRLF & @CRLF & "Error: " & @error & @CRLF & "Extended info: " & @extended)
	#EndRegion --- CodeWizard generated code Start ---
	Exit
EndIf
_SQLite_Exec($db, "pragma foreign_keys=1;")
_SQLite_Exec($db, "pragma journal_mode=wal;")
_SQLite_Exec($db, "pragma automatic_index=no;")
_SQLite_Exec($db, "pragma wal_checkpoint(full);")
_SQLite_Exec($db, "pragma auto_vacuum=1;")

Func __Tables_Create()
	_SQLite_Exec($db, "create table if not exists 'pid' ('pid' varchar);")
	_SQLite_Exec($db, "create table if not exists 'sessions' ('file' varchar primary key, 'display_text' varchar, 'item_handle' blob, 'handle' blob, 'selected' blob, 'max_video' integer, 'max_audio' integer, 'max_subs' integer);")
	If @error Then Return 1
	ConsoleWrite("created table sessions: " & @error & @CRLF)
	;_SQLite_Exec($db, "create table if not exists 'session_settings' ('video' varchar, 'audio' varchar, 'subs' varchar, 'attach' varchar, 'tc' varchar, 'cue' varchar, 'tags' varhar, 'chapters' varchar);")
	_SQLite_Exec($db, "create table if not exists 'child_handles' ('file' varchar, 'track' int, 'item_handle' blob unique, 'handle' blob, 'selected' blob, foreign key(file) references sessions(file) on delete cascade);")
	If @error Then Return 1
	ConsoleWrite("created table child_handles: " & @error & @CRLF)
	_SQLite_Exec($db, "create table if not exists 'log' ('date' datetime, 'session' varchar, 'level' int, 'message' varchar);")
	ConsoleWrite("created table log: " & @error & @CRLF)
	If @error Then Return 1
EndFunc   ;==>_tables_create

Func __Log_Write($message, $level, $session)
	Local $lines = StringSplit($message, @CRLF, 1)
	Select
		Case $lines[0] = 1
			_SQLite_Exec($db, "insert into log ('date','session','level','message') values (strftime('%Y-%m-%d %H:%M:%f', 'now', 'localtime'),'" & $session & _
					"','" & $level & "'," & __SQL_Escape($lines[1]) & ");")
		Case $lines[0] > 1
			For $a = 1 To $lines[0] - 1
				_SQLite_Exec($db, "insert into log ('date','session','level','message') values (strftime('%Y-%m-%d %H:%M:%f', 'now', 'localtime'),'" & $session & _
						"','" & $level & "'," & __SQL_Escape($lines[$a]) & ");")
			Next
	EndSelect
EndFunc   ;==>_log_write
