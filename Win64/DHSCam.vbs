Sub KillAll(ProcessName)
    Dim objWMIService, colProcess
    Dim strComputer, strList, p
    strComputer = "."
    Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2") 
    Set colProcess = objWMIService.ExecQuery ("Select * from Win32_Process Where Name like '" & ProcessName & "'")
    For Each p in colProcess
        p.Terminate             
    Next
End Sub

Set oShell = CreateObject ("Wscript.Shell")
Dim strArgs

strPath = Wscript.ScriptFullName
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.GetFile(strPath)
strFolder = objFSO.GetParentFolderName(objFile)
oShell.CurrentDirectory=strFolder
const DontWaitUntilFinished = false, ShowWindow = 1, DontShowWindow = 0, WaitUntilFinished = true

a=1
Do While a=1:
    strArgs = "conda activate OpenCV-master-py3 && python C:\dependencies\DHSCam.py 5014 192 108 30 192 108 3 3 127.0.0.1 5011 >nul"
	oShell.Run strArgs, DontShowWindow, WaitUntilFinished
	WScript.Sleep 2000
Loop