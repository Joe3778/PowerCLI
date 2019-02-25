Dim StdIn, StdOut
Set StdIn = WScript.StdIn
Set StdOut = WScript.StdOut
StdOut.WriteLine "Enter Computer Name:"

ComptInput = StdIn.ReadLine

ComputerName = ComptInput
Set wmiServices = GetObject _
    ("winmgmts:{impersonationLevel=Impersonate}!//" & ComputerName)
Set wmiDiskDrives = wmiServices.ExecQuery _
    ("SELECT DeviceID FROM Win32_DiskDrive")

For Each wmiDiskDrive In wmiDiskDrives
    strEscapedDeviceID = _
        Replace(wmiDiskDrive.DeviceID, "\", "\\", 1, -1, vbTextCompare)
    Set wmiDiskPartitions = wmiServices.ExecQuery _
        ("ASSOCIATORS OF {Win32_DiskDrive.DeviceID=""" & _
            strEscapedDeviceID & """} WHERE " & _
                "AssocClass = Win32_DiskDriveToDiskPartition")

    For Each wmiDiskPartition In wmiDiskPartitions
        Set wmiLogicalDisks = wmiServices.ExecQuery _
            ("ASSOCIATORS OF {Win32_DiskPartition.DeviceID=""" & _
                wmiDiskPartition.DeviceID & """} WHERE " & _
                    "AssocClass = Win32_LogicalDiskToPartition")

        For Each wmiLogicalDisk In wmiLogicalDisks
            WScript.Echo wmiLogicalDisk.DeviceID & " = " & wmiDiskDrive.DeviceID
        Next
    Next
Next