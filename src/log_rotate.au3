#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=log_rotate_x86.exe
#AutoIt3Wrapper_Outfile_x64=log_rotate_x64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=This application is freeware.
#AutoIt3Wrapper_Res_Description=Rotates MKVCleaver log.
#AutoIt3Wrapper_Res_Fileversion=0.8.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Ilia Bakhmoutski (sheck) 2010-2017
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo /rsln
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
#pragma compile(ProductVersion,0.8.0.0)
#pragma compile(FileVersion,0.8.0.0)
#pragma compile(LegalCopyright,Ilia Bakhmoutski (sheck) 2010-2017)
#pragma compile(FileDescription,Rotates MKVCleaver log.)
#pragma compile(ProductName,Log Rotate)
#include <SQLite.au3>
#include <Date.au3>

Local $query
Local $query_result
Local $diff
Local $error
Local $sqlite_save
Local $rows
Local $columns

If $CmdLine[0] > 0 Then
	If $CmdLine[1] = 1 Then
		$debug = 1
	Else
		$debug = 0
	EndIf
Else
	$debug = 0
EndIf

_SQLite_Startup()
If Not FileExists(@ScriptDir & "\custom.ini") Then
	Local $working_dir = @LocalAppDataDir & "\MKVCleaver"
	$ini_file = $working_dir & "\custom.ini"
Else
	Local $working_dir = @ScriptDir
	$ini_file = @ScriptDir & "\custom.ini"
EndIf
Local $age = IniRead($ini_file, "Files", "log_max_age", "30D")
$db = _SQLite_Open($working_dir & "\mkvcleaver_db.sqlite")
If $debug = 1 Then ConsoleWrite("Opening Database: " & $db & @CRLF)
$sqlite_save = _SQLite_Exec($db, "create table if not exists log_rotate ('date' datetime, 'session' varchar, 'level' int, 'message' varchar);")
If $debug = 1 Then ConsoleWrite("Creating log_rotate table: " & @error & @CRLF)
If $sqlite_save <> $SQLITE_OK Then
	_SQLite_Exec($db, "drop table log_rotate;")
	_SQLite_Close($db)
	_SQLite_Shutdown()
	If $debug = 1 Then ConsoleWrite("Error creating table. Exiting." & @CRLF)
	Exit 1
EndIf
_SQLite_GetTable2d($db, "select * from log order by date asc;", $query_result, $rows, $columns)
If $debug = 1 Then ConsoleWrite("Initiating main query: " & @error & @CRLF)
If Not IsArray($query_result) Then
	_SQLite_Exec($db, "drop table log_rotate;")
	_SQLite_Close($db)
	_SQLite_Shutdown()
	If $debug = 1 Then ConsoleWrite("Error reading log table. Exiting." & @CRLF)
	Exit 1
EndIf
Local $row = 0
_SQLite_Exec($db, "begin transaction;")
For $a = 1 To $rows
	If $debug = 1 Then $row += 1
	If $debug = 1 Then ConsoleWrite("Querying row " & $row & ": " & @error & @CRLF)
	$diff = _DateDiff(StringRight($age, 1), StringReplace(StringLeft($query_result[$a][0], StringLen($query_result[$a][0]) - 4), "-", "/"), _NowCalc())
	$error = @error
	If $debug = 1 And Not @error Then ConsoleWrite("Date difference for row " & $row & ": " & $diff & @CRLF)
	If $debug = 1 And @error Then ConsoleWrite("Date difference error encountered for row " & $row & ": " & $error & @CRLF)
	If $diff <= StringLeft($age, StringLen($age) - 1) And Not $error Then
		$sqlite_save = _SQLite_Exec($db, "insert into log_rotate ('date','session','level','message') values ('" & $query_result[$a][0] & "','" & $query_result[$a][1] & "','" & $query_result[$a][2] & "','" & StringReplace($query_result[$a][3], "'", "''") & "');")
		If $debug = 1 Then ConsoleWrite("Saving row to log_rotate table: " & @error & @CRLF)
		If $sqlite_save <> $SQLITE_OK Then
			_SQLite_Exec($db, "drop table log_rotate;")
			_SQLite_Close($db)
			_SQLite_Shutdown()
			If $debug = 1 Then ConsoleWrite("Error writing to the table. Exiting." & @CRLF)
			Exit 1
		EndIf
	EndIf
Next
_SQLite_Exec($db, "drop table log;")
_SQLite_Exec($db, "alter table log_rotate rename to log;")
If $debug = 1 Then ConsoleWrite("Renaming table log_rotate to log: " & @error & @CRLF)
$sqlite_save = _SQLite_Exec($db, "commit;")
If $debug = 1 Then ConsoleWrite("Commiting all changes: " & @error & @CRLF)
If $sqlite_save <> $SQLITE_OK Then
	_SQLite_Exec($db, "drop table log_rotate;")
	_SQLite_Close($db)
	_SQLite_Shutdown()
	If $debug = 1 Then ConsoleWrite("Error commiting changes. Exiting." & @CRLF)
	Exit 1
EndIf
_SQLite_Close($db)
If $debug = 1 Then ConsoleWrite("Closing database connetion: " & @error & @CRLF)
_SQLite_Shutdown()
IniWrite($ini_file, "Files", "log_rotate_last_ran", _NowCalc())
Exit 0
