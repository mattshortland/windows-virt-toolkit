#! /usr/bin/pwsh

#Region Setup variables for build environment
Set-Location $PSScriptroot

#Guest Specific Variables - setup as necessary
$AdministratorPasswordValue = 'P@ssword'
$oslanguageandlocale = "en-gb"
$numberofautologons = "1"

#Below OS Versions must match the Caption as displayed in Dism get-wiminfo to enable automatic choice of the OS version in Unattend.xml
$Windows10Version = "Windows 10 Enterprise"
$Windows81Version = "Windows 8.1 Enterprise"
$Windows8Version = "Windows 8 Enterprise"
$Windows7Version = "Windows 7 Enterprise"
$Windows7Version = "Windows 7 Enterprise"
$WindowsVistaVersion = "Windows Vista Ultimate"
$WindowsServer2019Version = "Windows Server 2019 SERVERSTANDARD"
$WindowsServer2016Version = "Windows Server 2016 SERVERSTANDARD"
$WindowsServer2012R2Version = "Windows Server 2012 R2 SERVERSTANDARD"
$WindowsServer2012Version = "Windows Server 2012 SERVERSTANDARD"
$WindowsServer2008R2Version = "Windows Server 2012 SERVERSTANDARD"
$WindowsServer2008Version = "Windows Server 2012 SERVERSTANDARD"

#region create autounattend.xml
if (Test-Path "$PSScriptroot/Toolkit/Scripts/")
{Remove-Item "$PSScriptroot/Toolkit/Scripts/*" -Force -Recurse}
if (Test-Path "$PSScriptroot/ISOBuild/")
{Remove-Item "$PSScriptroot/ISOBuild/*" -Force -Recurse}

$uefidiskconfig = @'
<DiskConfiguration>
                <Disk wcm:action="add">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Size>200</Size>
                            <Type>EFI</Type>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Size>128</Size>
                            <Type>MSR</Type>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Extend>true</Extend>
                            <Order>3</Order>
                            <Type>Primary</Type>
                        </CreatePartition>
                    </CreatePartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
                <WillShowUI>OnError</WillShowUI>
                <DisableEncryptedDiskProvisioning>true</DisableEncryptedDiskProvisioning>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/NAME</Key>
                            <Value>OPERATINGSYSTEMIMAGENAME</Value>
                        </MetaData>
                    </InstallFrom>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>3</PartitionID>
                    </InstallTo>
                </OSImage>
            </ImageInstall>
'@


$biosdiskconfig = @'
                <DiskConfiguration>
                    <WillShowUI>OnError</WillShowUI>
                    <Disk wcm:action="add">
                        <DiskID>0</DiskID>
                        <WillWipeDisk>true</WillWipeDisk>
                        <CreatePartitions>
                            <CreatePartition wcm:action="add">
                                <Order>1</Order>
                                <Type>Primary</Type>
                                <Size>100</Size>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>2</Order>
                                <Type>Primary</Type>
                                <Extend>true</Extend>
                            </CreatePartition>
                            </CreatePartitions>
                            <ModifyPartitions>
                            <ModifyPartition wcm:action="add">
                                <Format>NTFS</Format>
                                <Label>System Reserved</Label>
                                <Order>1</Order>
                                <Active>true</Active>
                                <PartitionID>1</PartitionID>
                                <TypeID>0x27</TypeID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Active>true</Active>
                                <Format>NTFS</Format>
                                <Label>OS</Label>
                                <Letter>C</Letter>
                                <Order>2</Order>
                                <PartitionID>2</PartitionID>
                            </ModifyPartition>
                        </ModifyPartitions>
                    </Disk>
                </DiskConfiguration>
                <ImageInstall>
                    <OSImage>
                        <InstallFrom>
                            <MetaData wcm:action="add">
                                <Key>/IMAGE/NAME</Key>
                                <Value>OPERATINGSYSTEMIMAGENAME</Value>
                            </MetaData>
                        </InstallFrom>
                        <InstallTo>
                            <DiskID>0</DiskID>
                            <PartitionID>2</PartitionID>
                        </InstallTo>
                        <WillShowUI>OnError</WillShowUI>
                        <InstallToAvailablePartition>false</InstallToAvailablePartition>
                    </OSImage>
                </ImageInstall>
'@


$autounattendbase = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
DISKCONFIGURATIONANDIMAGEINSTALL
            <UserData>
                <ProductKey>
                    <WillShowUI>Never</WillShowUI>
                </ProductKey>
                <AcceptEula>true</AcceptEula>
            </UserData>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
DISKCONFIGURATIONANDIMAGEINSTALL
                    <UserData>
                        <ProductKey>
                            <WillShowUI>Never</WillShowUI>
                        </ProductKey>
                        <AcceptEula>true</AcceptEula>
                    </UserData>
                </component>
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en-us</UILanguage>
                <WillShowUI>Never</WillShowUI>
            </SetupUILanguage>
            <InputLocale>OSLANGUAGEANDLOCALE</InputLocale>
            <SystemLocale>OSLANGUAGEANDLOCALE</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>OSLANGUAGEANDLOCALE</UserLocale>
        </component>
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <SetupUILanguage>
            <UILanguage>en-us</UILanguage>
            <WillShowUI>Never</WillShowUI>
        </SetupUILanguage>
        <InputLocale>OSLANGUAGEANDLOCALE</InputLocale>
        <SystemLocale>OSLANGUAGEANDLOCALE</SystemLocale>
        <UILanguage>en-us</UILanguage>
        <UILanguageFallback>en-us</UILanguageFallback>
        <UserLocale>OSLANGUAGEANDLOCALE</UserLocale>
    </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>ADMINISTRATORPASSWORDVALUE</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <LogonCount>NUMBEROFAUTOLOGONS</LogonCount>
                <Username>administrator</Username>
            </AutoLogon>
           <TimeZone>GMT Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <AutoLogon>
            <Password>
                <Value>ADMINISTRATORPASSWORDVALUE</Value>
                <PlainText>true</PlainText>
            </Password>
            <Enabled>true</Enabled>
            <LogonCount>NUMBEROFAUTOLOGONS</LogonCount>
            <Username>administrator</Username>
        </AutoLogon>
       <TimeZone>GMT Standard Time</TimeZone>
    </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>OSLANGUAGEANDLOCALE</InputLocale>
            <SystemLocale>OSLANGUAGEANDLOCALE</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>OSLANGUAGEANDLOCALE</UserLocale>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>OSLANGUAGEANDLOCALE</InputLocale>
            <SystemLocale>OSLANGUAGEANDLOCALE</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>OSLANGUAGEANDLOCALE</UserLocale>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>ADMINISTRATORPASSWORDVALUE</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                <LocalAccount wcm:action="add">
                <Password>
                <Value>ADMINISTRATORPASSWORDVALUE</Value>
                <PlainText>true</PlainText>
                </Password>
                <Description></Description>
                <DisplayName>SetupUser</DisplayName>
                <Group>Administrators</Group>
                <Name>SetupUser</Name>
                </LocalAccount>
            </LocalAccounts>
            </UserAccounts>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d Bypass /f</CommandLine>
                    <Order>2</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c xcopy E:\ C:\setup\ /E/H/C/I</CommandLine>
                    <Order>3</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File c:\Setup\Setup.ps1</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>mkdir c:\setup</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>6</Order>
                    <CommandLine>reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff /f</CommandLine>
                </SynchronousCommand>
            </FirstLogonCommands>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>1</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>ADMINISTRATORPASSWORDVALUE</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                <LocalAccount wcm:action="add">
                <Password>
                <Value>ADMINISTRATORPASSWORDVALUE</Value>
                <PlainText>true</PlainText>
                </Password>
                <Description></Description>
                <DisplayName>SetupUser</DisplayName>
                <Group>Administrators</Group>
                <Name>SetupUser</Name>
                </LocalAccount>
            </LocalAccounts>
            </UserAccounts>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d Bypass /f</CommandLine>
                    <Order>2</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c xcopy E:\ C:\setup\ /E/H/C/I</CommandLine>
                    <Order>3</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File c:\Setup\Setup.ps1</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>mkdir c:\setup</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>6</Order>
                    <CommandLine>reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff /f</CommandLine>
                </SynchronousCommand>
            </FirstLogonCommands>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>1</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>OSLANGUAGEANDLOCALE</InputLocale>
            <SystemLocale>OSLANGUAGEANDLOCALE</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>OSLANGUAGEANDLOCALE</UserLocale>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>OSLANGUAGEANDLOCALE</InputLocale>
            <SystemLocale>OSLANGUAGEANDLOCALE</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>OSLANGUAGEANDLOCALE</UserLocale>
        </component>
    </settings>
    <settings pass="auditSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>ADMINISTRATORPASSWORDVALUE</Value> 
                    <PlainText>true</PlainText> 
                </Password>
                <Username>Administrator</Username> 
                    <Enabled>true</Enabled> 
                    <LogonCount>NUMBEROFAUTOLOGONS</LogonCount> 
            </AutoLogon>
            <UserAccounts>
                <AdministratorPassword>
                <Value>ADMINISTRATORPASSWORDVALUE</Value> 
                <PlainText>true</PlainText> 
                </AdministratorPassword>
            </UserAccounts>
            <FirstLogonCommands>
            <SynchronousCommand wcm:action="add">
                <CommandLine>cmd /c reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d Bypass /f</CommandLine>
                <Order>2</Order>
                <RequiresUserInput>false</RequiresUserInput>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <CommandLine>cmd /c xcopy E:\ C:\setup\ /E/H/C/I</CommandLine>
                <Order>3</Order>
                <RequiresUserInput>false</RequiresUserInput>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>4</Order>
                <RequiresUserInput>false</RequiresUserInput>
                <CommandLine>powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c</CommandLine>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>5</Order>
                <RequiresUserInput>false</RequiresUserInput>
                <CommandLine>%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File c:\Setup\Setup.ps1</CommandLine>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>1</Order>
                <RequiresUserInput>false</RequiresUserInput>
                <CommandLine>mkdir c:\setup</CommandLine>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>6</Order>
                <CommandLine>reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff /f</CommandLine>
            </SynchronousCommand>
        </FirstLogonCommands>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>ADMINISTRATORPASSWORDVALUE</Value> 
                    <PlainText>true</PlainText> 
                </Password>
                <Username>Administrator</Username> 
                    <Enabled>true</Enabled> 
                    <LogonCount>NUMBEROFAUTOLOGONS</LogonCount> 
            </AutoLogon>
            <UserAccounts>
                <AdministratorPassword>
                <Value>ADMINISTRATORPASSWORDVALUE</Value> 
                <PlainText>true</PlainText> 
                </AdministratorPassword>
            </UserAccounts>
            <FirstLogonCommands>
            <SynchronousCommand wcm:action="add">
                <CommandLine>cmd /c reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d Bypass /f</CommandLine>
                <Order>2</Order>
                <RequiresUserInput>false</RequiresUserInput>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <CommandLine>cmd /c xcopy E:\ C:\setup\ /E/H/C/I</CommandLine>
                <Order>3</Order>
                <RequiresUserInput>false</RequiresUserInput>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>4</Order>
                <RequiresUserInput>false</RequiresUserInput>
                <CommandLine>powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c</CommandLine>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>5</Order>
                <RequiresUserInput>false</RequiresUserInput>
                <CommandLine>%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File c:\Setup\Setup.ps1</CommandLine>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>1</Order>
                <RequiresUserInput>false</RequiresUserInput>
                <CommandLine>mkdir c:\setup</CommandLine>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
                <Order>6</Order>
                <CommandLine>reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff /f</CommandLine>
            </SynchronousCommand>
        </FirstLogonCommands>
        </component>
    </settings>
</unattend>
'@

$VALID_OS = "win7","win8","win8.1","win10","win2k8","win2k8r2","win2k12","win2k12r2","win2k16","win2k19"
$VALID_BIOS = "win7","win8","win8.1","win10","win2k8","win2k8r2","win2k12","win2k12r2","win2k16","win2k19"
$VALID_UEFI = "win8","win8.1","win10","win2k8","win2k8r2","win2k12","win2k12r2","win2k16","win2k19"

$check = $false
while ($check -eq $false)
    {
        $OSType = read-host "Enter The Operating System"
        $UEFIorBIOS = Read-Host "Enter partitioning(UEFI or BIOS)"

        if ($VALID_OS -contains $OSType)
            {
                if ($UEFIorBIOS -eq "uefi")
                    {
                        if ($VALID_UEFI -contains $OSType)
                        {   
                            $check = $true
                        }
                        else {Write-Host "$OSType does not support UEFI"}
                    }
                elseif ($UEFIorBIOS -eq "bios")
                    {
                        if ($VALID_BIOS -contains $OSType)
                        { 
                            $check = $true
                        }
                        else {Write-Host "$OSType does not support BIOS"}
                    }
                else { Write-Host "Invalid option please choose UEFI or BIOS"}
            }
        else 
            {  
                Write-Host "Invalid OS type - ensure you are using libvirt values (valid options are : $VALID_OS)"
                Return    
            }
    }

if ($UEFIorBIOS -eq "uefi")
    {
        $autounattendbase = $autounattendbase -replace "DISKCONFIGURATIONANDIMAGEINSTALL", $uefidiskconfig`
    }
else {
    $autounattendbase = $autounattendbase -replace "DISKCONFIGURATIONANDIMAGEINSTALL", $biosdiskconfig`
    }
        
if ($OSType -eq "win10")
    {   
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows10Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `
    }
if ($OSType -eq "win8.1")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows81Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `
        | Set-Content "$PSScriptroot/Toolkit/AutoUnattend/win8.1.xml"
    }
if ($OSType -eq "win8")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows8Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
if ($OSType -eq "win7")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows7Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
if ($OSType -eq "win2k19")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2019Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
if ($OSType -eq "win2k16")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2016Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
if ($OSType -eq "win2k12r2")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2012R2Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
if ($OSType -eq "win2k12")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2012Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
if ($OSType -eq "win2k8r2")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2008R2Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
if ($OSType -eq "win2k8")
    {
        $autounattendbase = $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2008Version `
        -replace 'OSLANGUAGEANDLOCALE', $oslanguageandlocale `
        -replace 'NUMBEROFAUTOLOGONS', $numberofautologons `

    }
#endregion

#region create powershell logon script

$setupbase = @'
#pause before starting
start-sleep -seconds 15

$OS = (Get-WmiObject win32_operatingsystem)

#region Enable Remote Connections (Install SSH and enable RDP)

if (($OS | Select-Object -expandproperty OSArchitecture) -eq "64-bit")
    {
        New-Item -ItemType Directory -Path "$env:ProgramFiles\OpenSSH"
        copy-item -Path "c:\Setup\OpenSSH-Win64\*" -Destination "$env:ProgramFiles\OpenSSH" -Recurse -Force
    }
elseif (($OS | Select-Object -expandproperty OSArchitecture) -eq "32-bit")
    {
        New-Item -ItemType Directory -Path "$env:ProgramFiles\OpenSSH"
        copy-item -Path "c:\Setup\OpenSSH-Win32" -Destination "$env:ProgramFiles\OpenSSH" -Recurse -Force
    }

start-sleep -Seconds 2
powershell.exe -executionpolicy bypass -noprofile -file 'C:\Program Files\OpenSSH\install-sshd.ps1'
start-sleep -Seconds 2
netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP localport=22
Start-Service sshd
Set-Service sshd -StartupType Automatic
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShellCommandOption -Value "/c" -PropertyType String -Force

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

#endregion

#region install certificates and drivers

Function Import-Certificate
    {
        [cmdletbinding(SupportsShouldProcess=$True)]
        Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('PSComputername','__Server','IPAddress')]
        [string[]]$Computername =   $env:COMPUTERNAME,
        [parameter(Mandatory=$True)]
        [string]$Certificate,
        [System.Security.Cryptography.X509Certificates.StoreName]$StoreName =  'TrustedPublisher',
        [System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation  = 'LocalMachine'
        )
    
        Begin 
            {
                $CertificateObject = New-Object  System.Security.Cryptography.X509Certificates.X509Certificate2
                $CertificateObject.Import($Certificate)
            }
            
        Process  
            {
                ForEach  ($Computer in  $Computername) 
                    {
                        $CertStore  = New-Object   System.Security.Cryptography.X509Certificates.X509Store  -ArgumentList  "\\$($Computername)\$($StoreName)", $StoreLocation
                        $CertStore.Open('ReadWrite')
                        If  ($PSCmdlet.ShouldProcess("$($StoreName)\$($StoreLocation)","Add  $Certificate")) 
                            {
                                $CertStore.Add($CertificateObject)
                            }
                    }
            }
    }

$VMCerts = Get-ChildItem -Path $PSScriptRoot\certificates\ -Filter "*.cer"
foreach  ($vmcert in $vmcerts)
    {
        Import-Certificate -Certificate $vmcert.FullName
    }

Start-Sleep -Seconds 2

if ($OS.Caption -like "*Windows 10*" -and $OS.OSArchitecture -eq "64-bit" )
	{ Get-ChildItem "$PSScriptRoot/drivers/win10-64" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait } }
elseif ($OS.Caption -like "*Windows 8.1*" -and $OS.OSArchitecture -eq "64-bit" )
    { Get-ChildItem "$PSScriptRoot/drivers/win8.1-64" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows 8 *" -and $OS.OSArchitecture -eq "64-bit" )
    { Get-ChildItem "$PSScriptRoot/drivers/win8-64" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows 7*" -and $OS.OSArchitecture -eq "64-bit" )
    { Get-ChildItem "$PSScriptRoot/drivers/win7-64" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows 10*" -and $OS.OSArchitecture -eq "32-bit" )
	{ Get-ChildItem "$PSScriptRoot/drivers/win10-32" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait } }
elseif ($OS.Caption -like "*Windows 8.1*" -and $OS.OSArchitecture -eq "32-bit" )
    { Get-ChildItem "$PSScriptRoot/drivers/win8.1-32" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows 8 *" -and $OS.OSArchitecture -eq "32-bit" )
    { Get-ChildItem "$PSScriptRoot/drivers/win8-32" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows 7*" -and $OS.OSArchitecture -eq "32-bit" )
    { Get-ChildItem "$PSScriptRoot/drivers/win7-32" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2019*" )
    { Get-ChildItem "$PSScriptRoot/drivers/win2k19" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2016*" )
    { Get-ChildItem "$PSScriptRoot/drivers/win2k16" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2012R2*" )
    { Get-ChildItem "$PSScriptRoot/drivers/win2k12r2" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2012 *" )
    { Get-ChildItem "$PSScriptRoot/drivers/win2k12" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2008R2*" )
    { Get-ChildItem "$PSScriptRoot/drivers/win2k8r2-64" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
    elseif ($OS.Caption -like "*Windows Server 2008 *" -and $OS.OSArchitecture -eq "64-bit")
    { Get-ChildItem "$PSScriptRoot/drivers/win2k8-64" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
    elseif ($OS.Caption -like "*Windows Server 2008 *" -and $OS.OSArchitecture -eq "32-bit")
    { Get-ChildItem "$PSScriptRoot/drivers/win2k8-32" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
#endregion

#region install guest tools

cmd.exe --% /C "c:\setup\SpiceGuestTools\spice-guest-tools-latest.exe" /S

if (($OS | Select-Object -expandproperty OSArchitecture) -eq "64-bit")
    {
        Start-Process msiexec.exe -ArgumentList "/i C:\Setup\QEMUGuestAgent\qemu-ga-x86_64.msi /qn" -wait
        Start-Process msiexec.exe -ArgumentList "/i c:\setup\SpiceWebDAV\spice-webdavd-x64-latest.msi /qn" -wait
    }
if (($OS | Select-Object -expandproperty OSArchitecture) -eq "32-bit")
    {
        Start-Process msiexec.exe -ArgumentList "/i C:\Setup\QEMUGuestAgent\qemu-ga-i386.msi /qn" -wait
        Start-Process msiexec.exe -ArgumentList "/i c:\setup\SpiceWebDAV\spice-webdavd-x86-latest.msi /qn" -wait
    }

#endregion

'@

#region create directory structure

New-Item -ItemType Directory "$PSScriptroot/Toolkit" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Downloads" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Scripts" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win10" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win8.1" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win8" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win7" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/winvista" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k19"  -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k16" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k12r2" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k12" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k8r2" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k8" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Certificates" -ErrorAction SilentlyContinue 
New-Item -ItemType Directory "$PSScriptroot/Toolkit/QEMUGuestAgent" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$PSScriptroot/ISOBuild" -ErrorAction SilentlyContinue

#endregion

#region import certificates

<#
How to add other certificates

$Content = Get-Content -Path ./certificate.cer -AsByteStream
$Base64 = [System.Convert]::ToBase64String($Content)
$Base64 | Out-File ./encodedcertificate.txt
Assign that text string to a variable $Encoded
$Content = [System.Convert]::FromBase64String($Encoded)
Set-Content -Path ./decodedcertificate.cer -Value $Content -AsByteStream

#>

$redhat1 = 'MIIFBjCCA+6gAwIBAgIQVsbSZ63gf3LutGA7v4TOpTANBgkqhkiG9w0BAQUFADCBtDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBvZiB1c2UgYXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykxMDEuMCwGA1UEAxMlVmVyaVNpZ24gQ2xhc3MgMyBDb2RlIFNpZ25pbmcgMjAxMCBDQTAeFw0xNjAzMTgwMDAwMDBaFw0xODEyMjkyMzU5NTlaMGgxCzAJBgNVBAYTAlVTMRcwFQYDVQQIEw5Ob3J0aCBDYXJvbGluYTEQMA4GA1UEBxMHUmFsZWlnaDEWMBQGA1UEChQNUmVkIEhhdCwgSW5jLjEWMBQGA1UEAxQNUmVkIEhhdCwgSW5jLjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMA3SYpIcNIEzqqy1PNimjt3bVY1KuIuvDABkx8hKUG6rl9WDZ7ibcW6f3cKgr1bKOAeOsMSDu6i/FzB7Csd9u/a/YkASAIIw48q9iD4K6lbKvd+26eJCUVyLHcWlzVkqIEFcvCrvaqaU/YlX/antLWyHGbtOtSdN3FfY5pvvTbWxf8PJBWGO3nV9CVL1DMK3wSn3bRNbkTLttdIUYdgiX+q8QjbM/VyGz7nA9UvGO0nFWTZRdoiKWI7HA0Wm7TjW3GSxwDgoFb2BZYDDNSlfzQpZmvnKth/fQzNDwumhDw7tVicu/Y8E7BLhGwxFEaP0xZtENTpn+1f0TxPxpzL2zMCAwEAAaOCAV0wggFZMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMCsGA1UdHwQkMCIwIKAeoByGGmh0dHA6Ly9zZi5zeW1jYi5jb20vc2YuY3JsMGEGA1UdIARaMFgwVgYGZ4EMAQQBMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUFBwICMBkMF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMBMGA1UdJQQMMAoGCCsGAQUFBwMDMFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYTaHR0cDovL3NmLnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0cDovL3NmLnN5bWNiLmNvbS9zZi5jcnQwHwYDVR0jBBgwFoAUz5mp6nsm9EvJjo/X8AUm7+PSp50wHQYDVR0OBBYEFL/39F5yNDVDib3B3Uk3I8XJSrxaMA0GCSqGSIb3DQEBBQUAA4IBAQDWtaW0Dar82t1AdSalPEXshygnvh87Rce6PnM2/6j/ijo2DqwdlJBNjIOU4kxTFp8jEq8oM5Td48p03eCNsE23xrZl5qimxguIfHqeiBaLeQmxZavTHPNM667lQWPAfTGXHJb3RTT4siowcmGhxwJ3NGP0gNKCPHW09x3CdMNCIBfYw07cc6h9+Vm2Ysm9MhqnVhvROj+AahuhvfT9K0MJd3IcEpjXZ7aMX78Vt9/vrAIUR8EJ54YGgQsF/G9Adzs6fsfEw5Nrk8R0pueRMHRTMSroTe0VAe2nvuUU6rVI30q8+UjQCxu/ji1/JnitNkUyOPyC46zL+kfHYSnld8U1'
$redhat2 = 'MIIE0zCCA7ugAwIBAgIQShePL66PyVO0HnwjH6XtkzANBgkqhkiG9w0BAQsFADB/MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5bWFudGVjIENsYXNzIDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQTAeFw0xNTExMzAwMDAwMDBaFw0xODEyMjkyMzU5NTlaMGgxCzAJBgNVBAYTAlVTMRcwFQYDVQQIEw5Ob3J0aCBDYXJvbGluYTEQMA4GA1UEBxMHUmFsZWlnaDEWMBQGA1UEChQNUmVkIEhhdCwgSW5jLjEWMBQGA1UEAxQNUmVkIEhhdCwgSW5jLjCCASAwCwYJKoZIhvcNAQEBA4IBDwAwggEKAoIBAQC77K+PJdE6f1B6FkMFdLmkZpEPWXgFQ/XNhfvcm39q8T4iBfto3HvVzox0s/uhDp6JIXFuR9S+74hYjRvZs1Lu4dXQ6KEgLcmo9UqLf0XZSmkVciYN+Joh1I+ovoMjSCLzF6AYjDKsYoTMVpHFbE/+uiLS8H4FCbaHAJFVPi6kXCYn9RCgzqPsYQNzTVpAKdBvukgQzGZ5EcvC09JSbf/+Ua0sdR95f/FRpBtOJLFiXUmaSoLm3kvxW3zYxI3otMNPuZYK+I6aPDDpTdEZgNPcQkOTiT0lFZ0V3f4cx3Z+N+o40H2UOKL4IZ3Z2uTcDMr6NPhv97VLktk1DEbn3HNXAgMBAAGjggFiMIIBXjAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDArBgNVHR8EJDAiMCCgHqAchhpodHRwOi8vc3Yuc3ltY2IuY29tL3N2LmNybDBmBgNVHSAEXzBdMFsGC2CGSAGG+EUBBxcDMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUFBwICMBkMF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMBMGA1UdJQQMMAoGCCsGAQUFBwMDMFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYTaHR0cDovL3N2LnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0cDovL3N2LnN5bWNiLmNvbS9zdi5jcnQwHwYDVR0jBBgwFoAUljtT8Hkzl699g+8uK8zKt4YecmYwHQYDVR0OBBYEFNIhW3BAcnz8Wh/DVwx07qmz7BhHMA0GCSqGSIb3DQEBCwUAA4IBAQBMYtmjHv4V+mMbZZeL0TYpqlSoMfxt89LnxuG7DCo+LrcDl6YdvVrVQuZ1hx3HV0HwjzFut/jEazmM8LiYliHYhHcvw3ffz+CPiZSnf+gBjy9coOiX3eSFhBj4BjkXEgdrNmiStVkMcZf9BgKbu+Xi9i8lzDHROwa/Fu0kY8MD+mEEaJljrUuCgMChIbbcIWQ4AytnGaJeGshoeBxWmVmacB/fSGYSDlcMAm9d2NZutZeOQjLMaPuegsmAQlF83Ne4vp8OcImO8sY8pMhPiSBzWcefvXpYREfgajKhTL9ROEGCXSXS7h3A1kpcbWVLGnHNOVntupOy1DIDCzqlx8+B'
$redhat3 = 'MIIE1jCCA76gAwIBAgIQXRDLGOs6eQCHg6t0d/nTGTANBgkqhkiG9w0BAQsFADCBhDELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMR8wHQYDVQQLExZTeW1hbnRlYyBUcnVzdCBOZXR3b3JrMTUwMwYDVQQDEyxTeW1hbnRlYyBDbGFzcyAzIFNIQTI1NiBDb2RlIFNpZ25pbmcgQ0EgLSBHMjAeFw0xODExMjcwMDAwMDBaFw0yMjAxMjUyMzU5NTlaMGgxCzAJBgNVBAYTAlVTMRcwFQYDVQQIDA5Ob3J0aCBDYXJvbGluYTEQMA4GA1UEBwwHUmFsZWlnaDEWMBQGA1UECgwNUmVkIEhhdCwgSW5jLjEWMBQGA1UEAwwNUmVkIEhhdCwgSW5jLjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN6tLWiLXZXnYDRc6y9qeQrnN59qP5xutjQ4AHZY/m9EaNMRzKOONgalW6YTQRrW6emIscqlweRzvDnrF4hv/u/SfIq16XLqdViL0tZjmFWYhijbtFP1cjEZNeS47m2YnQgTpTsKmZ5A66/oiqzg8ogNbxxilUOojQ+rjzhwsvfJAgnaGhOMeR81ca2YsgzFX3Ywf7iy6A/CtjHIOh78wcwR0MaJW6QvOhOaClVhHGtq8yIUA7k/3k8sCC4xIxci2UqFOXopw0EUvd/xnc5by8m7LYdDO048sOM0lASt2d4PKniOvUkU/LpqiFSYo/6272j+KRBDYCW2IgPCK5HWlZMCAwEAAaOCAV0wggFZMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMCsGA1UdHwQkMCIwIKAeoByGGmh0dHA6Ly9yYi5zeW1jYi5jb20vcmIuY3JsMGEGA1UdIARaMFgwVgYGZ4EMAQQBMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUFBwICMBkMF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMBMGA1UdJQQMMAoGCCsGAQUFBwMDMFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYTaHR0cDovL3JiLnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0cDovL3JiLnN5bWNiLmNvbS9yYi5jcnQwHwYDVR0jBBgwFoAU1MAGIknrOUvdk+JcobhHdglyA1gwHQYDVR0OBBYEFG9GZUQmGAU3flEwvkNB0Dhx23xpMA0GCSqGSIb3DQEBCwUAA4IBAQBX36ARUohDOhdV52T3imb+YRVdlm4k9eX4mtE/Z+3vTuQGeCKgRFo10w94gQrRCRCQdfeyRsJHSvYFbgdGf+NboOxX2MDQF9ARGw6DmIezVvNJCnngv19ULo1VrDDH9tySafmb1PFjkYwcl8a/i2MWQqM/erney9aHFHGiWiGfWu8GWc1fmnZdG0LjlzLWn+zvYKmRE30v/Hb8rRhXpEAUUvaB4tNo8ahQCl00nEBsr7tNKLabf9OfxXLp3oiMRfzWLBG4TavH5gWS5MgXBiP6Wxidf93vMkM3kaYRRj+33lHdchapyKtWzgvhHa8kjDBB5oOXYhc08zqbfMpf9vNm'

$Content = [System.Convert]::FromBase64String($redhat1)
Set-Content -Path "$psscriptroot/Toolkit/Certificates/redhat1.cer" -Value $Content -AsByteStream

$Content = [System.Convert]::FromBase64String($redhat2)
Set-Content -Path "$psscriptroot/Toolkit/Certificates/redhat2.cer" -Value $Content -AsByteStream

$Content = [System.Convert]::FromBase64String($redhat3)
Set-Content -Path "$psscriptroot/Toolkit/Certificates/redhat3.cer" -Value $Content -AsByteStream
#endregion

#Region Download Tools


$virtdrivers = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
$spicetools = "https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe"
$ssh64 = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip"
$ssh32 = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win32.zip"
$spicewebdavd64 = "https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi"
$spicewebdavd32 = "https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x86-latest.msi"

$urls = @()
$urls += $virtdrivers
$urls += $spicetools
$urls += $ssh64
$urls += $ssh32
$urls += $spicewebdavd64
$urls += $spicewebdavd32

foreach ($url in $urls)
    {
       $filename = $url -split "\/" | Select-Object -Last 1
              if (!(Test-Path "$psscriptroot/Toolkit/Downloads/$filename"))
            {
                Invoke-WebRequest -Uri $url -OutFile "$psscriptroot/Toolkit/Downloads/$filename"
            }
    }

#endregion

#Region Extract ISO/ZIPs and organize drivers


start-process -Filepath "xorriso" -Argumentlist '-acl on -xattr on -osirrox on -indev ./Toolkit/Downloads/virtio-win.iso -extract / ./Toolkit/virtio' -Wait
chmod -R u+w $PSScriptroot/Toolkit/virtio


$virtiofiles = Get-ChildItem $PSScriptroot/Toolkit/virtio -Attributes !Directory -Recurse
$virtiofiles | Where-Object {$_.FullName -like "*/w10/amd64/*" -or $_.FullName -like "*/amd64/w10/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win10-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w10/x86/*" -or $_.FullName -like "*/i386/w10/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win10-32" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w8.1/amd64/*" -or $_.FullName -like "*/amd64/w8.1/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win8.1-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w8.1/x86/*" -or $_.FullName -like "*/i386/w8.1/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win8.1-32" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w8/amd64/*" -or $_.FullName -like "*/amd64/w8/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win8-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w8/x86/*" -or $_.FullName -like "*/i386/w8/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win8-32" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w7/amd64/*" -or $_.FullName -like "*/amd64/w7/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win7-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w7/x86/*" -or $_.FullName -like "*/i386/w7/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win7-32" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/2k19/amd64/*" -or $_.FullName -like "*/amd64/2k19/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k19-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/2k16/amd64/*" -or $_.FullName -like "*/amd64/2k16/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k16-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/2k12R2/amd64/*" -or $_.FullName -like "*/amd64/2k12R2/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k12r2-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/2k12/amd64/*" -or $_.FullName -like "*/amd64/2k12/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k12-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w2k8R2/amd64/*" -or $_.FullName -like "*/amd64/w2k8R2/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k8R2-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/w2k8/amd64/*" -or $_.FullName -like "*/amd64/w2k8/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k8-64" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*/win2k8/x86/*" -or $_.FullName -like "*/i386/win2k8/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k8-32" -ErrorAction SilentlyContinue
$virtiofiles | Where-Object {$_.FullName -like "*qemu-ga-x86_64.msi*"} | copy-item -Destination $PSScriptroot/Toolkit/QEMUGuestAgent
$virtiofiles | Where-Object {$_.FullName -like "*qemu-ga-i386.msi*"} | copy-item -Destination $PSScriptroot/Toolkit/QEMUGuestAgent

if (!(test-path $PSScriptroot/Toolkit/OpenSSH-Win64))
    {
        start-process -FilePath "unzip" -ArgumentList "$psscriptroot/Toolkit/Downloads/OpenSSH-Win64.zip" -Wait
        Move-Item $PSScriptroot/OpenSSH-Win64 -Destination "$PSScriptroot/Toolkit" -Force
        start-process -FilePath "unzip" -ArgumentList "$psscriptroot/Toolkit/Downloads/OpenSSH-Win32.zip" -Wait
        Move-Item $PSScriptroot/OpenSSH-Win32 -Destination "$PSScriptroot/Toolkit" -Force
    }

#endregion


#region build ISO files for OS versions
$autounattendbase | Set-Content "$PSScriptroot/ISOBuild/autounattend.xml" -Force
$setupbase | Set-Content "$PSScriptroot/ISOBuild/setup.ps1" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/Certificates" -Recurse -Destination "$PSScriptroot/ISOBuild" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/Drivers" -Recurse -Destination "$PSScriptroot/ISOBuild" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/OpenSSH-Win64" -Recurse -Destination "$PSScriptroot/ISOBuild" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/OpenSSH-Win32" -Recurse -Destination "$PSScriptroot/ISOBuild" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/QEMUGuestAgent" -Recurse -Destination "$PSScriptroot/ISOBuild" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/Scripts" -Recurse -Destination "$PSScriptroot/ISOBuild" -Force
New-Item -ItemType Directory "$PSScriptroot/ISOBuild/SpiceGuestTools" -Force
New-Item -ItemType Directory "$PSScriptroot/ISOBuild/SpiceWebDAV" -Force 
Copy-Item -Path "$PSScriptroot/Toolkit/Downloads/spice-guest-tools-latest.exe" -Destination "$PSScriptroot/ISOBuild/SpiceGuestTools" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/Downloads/spice-webdavd-x64-latest.msi" -Destination "$PSScriptroot/ISOBuild/SpiceWebDAV" -Force
Copy-Item -Path "$PSScriptroot/Toolkit/Downloads/spice-webdavd-x86-latest.msi" -Destination "$PSScriptroot/ISOBuild/SpiceWebDAV" -Force

        if (Test-Path "$PSScriptroot/ISO/$OSType-setup.iso") {Remove-Item "$PSScriptroot/ISO/$OSTYPE-setup.iso" -Force}
        start-process -Filepath "xorrisofs" -Argumentlist "-r -J -o $PSScriptroot/$OSTYPE-setup.iso $PSScriptroot/ISOBuild/" -Wait

Remove-Item "$PSScriptroot/Toolkit/Scripts/*" -Force -Recurse
Remove-Item "$PSScriptroot/ISOBuild/*" -Force -Recurse
#endregion
