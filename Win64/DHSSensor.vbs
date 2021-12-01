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
    Dim objWMISerial, devices
    Dim strComputerSerial
    strComputerSerial = "."
    Set objWMISerial = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputerSerial & "\root\cimv2") 
    Set devices = objWMISerial.ExecQuery ("SELECT * FROM Win32_SerialPort",,48)
    mydevice=""
	For Each objItem in devices
        mydevice = objItem.DeviceID
	Next
	
    strArgs = "conda activate OpenCV-master-py3 && python C:\dependencies\Win64\DHSSensor.py -c 127.0.0.1:5006 " & CStr(mydevice)
	oShell.Run strArgs, DontShowWindow, WaitUntilFinished
	WScript.Sleep 2000
Loop