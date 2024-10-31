' CPU temperature getter
' Uses console build of Open Hardware Monitor
' Open Hardware Monitor folder suggested to be added to %PATH% before script starts
' Outputs values to text file
' v 2.0

' CONSTANTS
Const retOHWUnavail = -1 ' OHWMR unavailable

Const LogMaxSize    = 16777216 ' bytes
				    
Const ForReading    = 1
Const ForWriting    = 2
Const ForAppending  = 8
				    
Const LogPath       = "C:\Program Files\Zabbix Agent\\Scripts\ScriptData\Logs\cputemp.log"
Const LogPrevPath   = "C:\Program Files\Zabbix Agent\Scripts\ScriptData\Logs\cputemp_prev.log"
				    
Const OutPath       = "C:\Program Files\Zabbix Agent\Scripts\ScriptData\cputemp_out.txt"

' VARIABLES
Set objFSO          = CreateObject("Scripting.FileSystemObject")

' FUNCTIONS
Function FormatNow
	dnow = Now()
	logday = Day(dnow)
	If logday < 10 Then logday = "0" & logday
	logmonth = Month(dnow)
	If logmonth < 10 Then logmonth = "0" & logmonth
	loghour = Hour(dnow)
	If loghour < 10 Then loghour = "0" & loghour
	logminute = Minute(dnow)
	If logminute < 10 Then logminute = "0" & logminute
	logsec = Second(dnow)
	If logsec < 10 Then logsec = "0" & logsec
	FormatNow = logday & "/" & logmonth & "/" & Year(dnow) & " " & _
				loghour & ":" &logminute & ":" & logsec
End Function

Sub LogAddLine(line)
	If objFSO.FileExists(LogPath) Then
		Set objFile = objFSO.GetFile(LogPath)
		If ObjFile.Size < LogMaxSize Then
			Set objFile = Nothing
			Set outputFile = objFSO.OpenTextFile(LogPath, ForAppending, True, -1)
			outputFile.WriteLine(FormatNow & " - " & line)
			outputFile.Close
			Set outputFile = Nothing
		Else
			Set objFile = Nothing
			objFSO.CopyFile LogPath, LogPrevPath, True
			Set outputFile = objFSO.CreateTextFile(LogPath, ForWriting, True)
			outputFile.WriteLine(FormatNow & " - " & line)
			outputFile.Close
			Set outputFile = Nothing
		End If
	Else
		Set outputFile = objFSO.CreateTextFile(LogPath, True, -1)
		outputFile.WriteLine(FormatNow & " - " & line)
		outputFile.Close
		Set outputFile = Nothing
	End If
End Sub

' SCRIPT
LogAddLine "Script started"
Set objShell = WScript.CreateObject("WScript.Shell")
Set objExecObject = objShell.Exec("cmd /c ohwr")
strOutput = objExecObject.StdOut.ReadAll
If strOutput = "" Then
	LogAddLine "OHWMR files unavailable"
	WScript.Echo retOHWUnavail
	WScript.Quit
End If
strSearch = ""
If InStr(strOutput, "+- CPU Package") <> 0 Then
	LogAddLine "Obtaining packagee temperature"
	strSearch = "+- CPU Package"
Else
	LogAddLine "Obtaining core0 temperature"
	strSearch = "cpu/0/temperature/0"
End If
arrSpl = Split(strOutput, vbCrLf)
For I = 0 To UBound(arrSpl)
	If InStr(arrSpl(I), strSearch) <> 0 Then
		lineSpl = Split(arrSpl(I), " ")
		Exit For
	End If
Next
If lineSpl(UBound(lineSpl) - 3) <> "" and lineSpl(UBound(lineSpl) - 3) <> " " Then
	If Instr (lineSpl(UBound(lineSpl) - 3), ".") <> 0 Then
		cputemp = Split(lineSpl(UBound(lineSpl) - 3), ".")(0)
	Else
		cputemp = Split(lineSpl(UBound(lineSpl) - 3), ",")(0)
	End IF
Else
	If Instr (lineSpl(UBound(lineSpl) - 1), ".") <> 0 Then
		cputemp = Split(lineSpl(UBound(lineSpl) - 1), ".")(0)
	Else
		cputemp = Split(lineSpl(UBound(lineSpl) - 1), ",")(0)
	End IF
End If
LogAddLine "Data requested successfully"
Set outFile = objFSO.CreateTextFile(OutPath, True, False)
outFile.Write cputemp
outFile.Close
Set outFile = Nothing
Set objExecObject = Nothing
Set objShell = Nothing
LogAddLine "Script finished"
Set objFSO = Nothing