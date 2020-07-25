#! /usr/bin/pwsh

#Region Setup variables for build environment
Set-Location $PSScriptroot

#Guest Specific Variables
$subnet = "192.168.1.0/24" #Format Network/Mask e.g 192.168.1.0/24
$netbiosname = "NEOTRECOGNISED" #Max 16 Characters
$domainname = "notrecognised.com"
$AdministratorPasswordValue = 'P@ssword'
$osinputlanguageandlocale = "en-gb"

#Below OS Versions must match the Caption as displayed in Dism get-wiminfo to enable automatic choice of the OS version in Unattend.xml
$Windows10Version = "Windows 10 Enterprise"
$Windows81Version = "Windows 8.1 Enterprise"
$Windows8Version = "Windows 8 Enterprise"
$Windows7Version = "Windows 7 Enterprise"
$WindowsServer2019Version = "Windows Server 2019 SERVERSTANDARD"
$WindowsServer2016Version = "Windows Server 2016 SERVERSTANDARD"
$WindowsServer2012R2Version = "Windows Server 2012 R2 SERVERSTANDARD"
$WindowsServer2012Version = "Windows Server 2012 SERVERSTANDARD"

#Host Specific Variables
$QEMUNetwork = "ExampleNetwork" # only alphanumeric no spaces . - or _
$QEMUBridgeName = "virbr99" # Only change if you already have a network using this bridge
$VirtInstallArgs = '--cpu EPYC'


$buildlist = Import-Csv $PSScriptroot/buildlist.csv

#endregion

#region generate Computer Info

$vnetwork = (($subnet  -split "\/" | Select-Object -First 1) -split "\." | Select-Object -First 3) -join "."
$vnetmask = $subnet  -split "\/" | Select-Object -Last 1

$Router = $buildlist | Where-Object {$_.role -eq "Router"} | Select-Object -First 1
$PrimaryDC = $buildlist | Where-Object {$_.role -eq "DomainController"} | Select-Object -First 1
$SecondaryDCs = $buildlist | Where-Object {$_.role -eq "DomainController"} | Select-Object -Skip 1
$SCCMServer = $buildlist | Where-Object {$_.role -eq "SCCMServer"} | Select-Object -First 1
$Memberservers = $buildlist | Where-Object {$_.role -eq "Memberserver"} 
$Workstations = $buildlist | Where-Object {$_.role -eq "Workstation"} 

#endregion

#region create directory structure

New-Item -ItemType Directory "$PSScriptroot/Toolkit"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Downloads"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Scripts"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/USBImages"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win10"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win8.1"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win8"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win7"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k19"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k16"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k12r2"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Drivers/win2k12"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/pfSense"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/Certificates"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/QEMUGuestAgent"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/AutoUnattend"
New-Item -ItemType Directory "$PSScriptroot/Toolkit/HostScripts"
New-Item -ItemType Directory "$PSScriptroot/ISOBuild"
New-Item -ItemType Directory "$PSScriptroot/ISO"

#endregion

#region sort ISO files

$isofiles = Get-ChildItem -Path $PSScriptroot -Filter *.iso

foreach ($isofile in $isofiles)
    {
        if ($isofile.basename -like "*_10_*" -and $isofile.basename -like "*64BIT*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win10.iso" }
        if ($isofile.basename -like "*8.1_64BIT*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win8.1.iso" }
        if ($isofile.basename -like "*8_64BIT*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win8.iso" }
        if ($isofile.basename -like "*7_64BIT*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win7.iso" }
        if ($isofile.basename -like "*2019*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win2k19.iso" }
        if ($isofile.basename -like "*2016*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win2k16.iso" }
        if ($isofile.basename -like "*2012_R2_64*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win2k12r2.iso" }
        if ($isofile.basename -like "*2012_64*") {Move-Item $isofile.fullname -Destination "$PSScriptroot/ISO/win2k12.iso" }
    }

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

<#  This doesnt work - need to create USB image


start-process -Filepath "dd" -ArgumentList 'if=/dev/zero of=./Toolkit/USBImages/pfsense.img count=1 bs=100M' -Wait
start-process -Filepath "mkfs.fat" -ArgumentList  '-F 32 ./Toolkit/USBImages/pfsense.img' -wait
#>

#Region Download Tools


$virtdrivers = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
$spicetools = "https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe"
$ssh = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip"
$spicewebdavd = "https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi"
$pfsense = "https://frafiles.pfsense.org/mirror/downloads/pfSense-CE-2.4.5-RELEASE-p1-amd64.iso.gz"

$urls = @()
$urls += $virtdrivers
$urls += $spicetools
$urls += $ssh
$urls += $ssh32
$urls += $spicewebdavd
$urls += $pfsense
#$urls += $pfsense
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

if (which xorriso -ne $null)
    {
        start-process -Filepath "xorriso" -Argumentlist '-acl on -xattr on -osirrox on -indev ./Toolkit/Downloads/virtio-win.iso -extract / ./Toolkit/virtio' -Wait
        chmod -R u+w $PSScriptroot/Toolkit/virtio
    }

    
else {
        Write-Output "xorriso is not installed please add the libisoburn packages from your package manager and try again"
        end
     }

$virtiofiles = Get-ChildItem $PSScriptroot/Toolkit/virtio -Attributes !Directory -Recurse
$virtiofiles | Where-Object {$_.FullName -like "*/w10/amd64/*" -or $_.FullName -like "*/amd64/w10/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win10"
$virtiofiles | Where-Object {$_.FullName -like "*/w8.1/amd64/*" -or $_.FullName -like "*/amd64/w8.1/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win8.1"
$virtiofiles | Where-Object {$_.FullName -like "*/w8/amd64/*" -or $_.FullName -like "*/amd64/w8/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win8"
$virtiofiles | Where-Object {$_.FullName -like "*/w7/amd64/*" -or $_.FullName -like "*/amd64/w7/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win7"
$virtiofiles | Where-Object {$_.FullName -like "*/2k19/amd64/*" -or $_.FullName -like "*/amd64/2k19/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k19"
$virtiofiles | Where-Object {$_.FullName -like "*/2k16/amd64/*" -or $_.FullName -like "*/amd64/2k16/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k16"
$virtiofiles | Where-Object {$_.FullName -like "*/2k12R2/amd64/*" -or $_.FullName -like "*/amd64/2k12R2/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k12r2"
$virtiofiles | Where-Object {$_.FullName -like "*/2k12/amd64/*" -or $_.FullName -like "*/amd64/2k12/*"} | copy-item -Destination "$PSScriptroot/Toolkit/Drivers/win2k12"
$virtiofiles | Where-Object {$_.FullName -like "*qemu-ga-x86_64.msi*"} | copy-item -Destination $PSScriptroot/Toolkit/QEMUGuestAgent

if (!(test-path $PSScriptroot/Toolkit/OpenSSH-Win64))
    {
        start-process -FilePath "unzip" -ArgumentList "$psscriptroot/Toolkit/Downloads/OpenSSH-Win64.zip" -Wait
        Move-Item $PSScriptroot/OpenSSH-Win64 -Destination "$PSScriptroot/Toolkit" -Force
    }

if (!(test-path $PSScriptroot/ISO/pfsense.iso))
    {
        start-process -FilePath "gunzip" -ArgumentList "$psscriptroot/Toolkit/Downloads/pfSense-CE-2.4.5-RELEASE-p1-amd64.iso.gz" -Wait
        Move-Item "$PSScriptroot/pfSense-CE-2.4.5-RELEASE-p1-amd64.iso" -Destination "$PSScriptroot/ISO/pfsense.iso"
    }




#endregion

#region create base initial setup powershell file

$setupbase = @'
#pause before starting
start-sleep -seconds 15

$OS = (Get-WmiObject win32_operatingsystem)


#region Enable Remote Connections (Install SSH and enable RDP)

copy-item -Path "c:\Setup\OpenSSH-Win64" -Destination "$env:ProgramFiles\OpenSSH-Win64" -Recurse -Force
Rename-Item -Path "$env:ProgramFiles\OpenSSH-Win64" -NewName "$env:ProgramFiles\OpenSSH"
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
	{ Get-ChildItem $PSScriptRoot/drivers/win10 -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait } }
elseif ($OS.Caption -like "*Windows 8.1*" -and $OS.OSArchitecture -eq "64-bit" )
    { Get-ChildItem "$PSScriptRoot/drivers/win8.1" -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows 8 *" -and $OS.OSArchitecture -eq "64-bit" )
    { Get-ChildItem $PSScriptRoot/drivers/win8 -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows 7*" -and $OS.OSArchitecture -eq "64-bit" )
    { Get-ChildItem $PSScriptRoot/drivers/win7 -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2019*" )
    { Get-ChildItem $PSScriptRoot/drivers/win2k19 -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2016*" )
    { Get-ChildItem $PSScriptRoot/drivers/win2k16 -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2012R2*" )
    { Get-ChildItem $PSScriptRoot/drivers/win2k12r2 -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }
elseif ($OS.Caption -like "*Windows Server 2012 *" )
    { Get-ChildItem $PSScriptRoot/drivers/win2k12 -Recurse -Filter "*.inf" | ForEach-Object { start-process "PNPUtil.exe" -Argumentlist "/add-driver $_.FullName /install" -Wait  } }

#endregion

#region install guest tools

cmd.exe --% /C "c:\setup\SpiceGuestTools\spice-guest-tools-latest.exe" /S
Start-Process msiexec.exe -wait -ArgumentList "/i C:\Setup\QEMUGuestAgent\qemu-ga-x86_64.msi /qn"
Start-Process msiexec.exe -wait -ArgumentList "/i c:\setup\SpiceWebDAV\spice-webdavd-x64-latest.msi /qn"

#endregion

#region OS Customization

$MAC = (Get-WmiObject win32_networkadapter).macaddress

switch ($MAC) 

{
LISTOFMACHINESINBUILDLIST
}
'@

$setupbase | Out-File "$PSScriptroot/Toolkit/Scripts/Setup-Base.ps1"

#endregion

#region customize base setup based on buildlist.csv

<# THIS DOESNT WORK GONNA BRUTE FORCE IT - NEED TO REFACTOR IN FUTURE
function Replace-ComputerInfo
    {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)] 
        [String]$subnet,   
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$netbiosname,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$domainname,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$vnetwork,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$vnetmask,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$AdministratorPasswordValue,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$osinputlanguageandlocale,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$mac,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$role,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
        [string]$ip
          )
    Begin {}
    Process {
        
            write-output "$PSBoundParameters"
            }

    End { }  
}#function
#>

$machinemacswitchblock = @()

if ($PrimaryDC -ne $null)
{$PrimaryDCConfig = @'

"PRIMARYDCMAC" { 

   $IP = "VNETWORK.DCIPADDRESS"
   $MaskBits = "VNETMASK"
   $Gateway = "VNETWORK.ROUTERIPADDRESS"
   $Dns = "VNETWORK.DCIPADDRESS"
   $IPType = "IPv4"
   $adapter = Get-NetAdapter
   If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {$adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false}
   If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {$adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false}
   $adapter | New-NetIPAddress -AddressFamily $IPType -IPAddress $IP -PrefixLength $MaskBits -DefaultGateway $Gateway
   $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
   install-windowsfeature AD-Domain-Services, RSAT-ADDS, DHCP -IncludeManageMentTools
   Import-Module ADDSDeployment
   $cred = ConvertTo-SecureString "ADMINISTRATORPASSWORDVALUE" -AsPlainText -Force
   $action = New-ScheduledTaskAction -Execute 'Powershell.exe'-Argument '-NoProfile -WindowStyle Hidden -File c:\Setup\Scripts\SecondLogonPRIMARYDC.ps1'
   $trigger =  New-ScheduledTaskTrigger -AtLogon
   $User = "Administrator"
   Register-ScheduledTask -Action $action -Trigger $trigger -User $User -TaskName "SecondLogon" -Description "Second Logon Script"
   Install-ADDSForest -SkipPreChecks -SafeModeAdministratorPassword $cred -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "Win2012R2" -DomainName "FULLYQUALIFIEDDOMAINNAME" -DomainNetbiosName "NETBIOSDOMAINNAME" -ForestMode "Win2012R2" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true
   }

'@
$PrimaryDCConfig = $PrimaryDCConfig -replace "PRIMARYDCMAC", $primarydc.mac`
-replace 'NETBIOSDOMAINNAME', "$netbiosname" `
-replace 'FULLYQUALIFIEDDOMAINNAME', "$domainname" `
-replace 'ROUTERIPADDRESS', "$($Router.IP)" `
-replace 'DCIPADDRESS', "$($PrimaryDC.IP)" `
-replace 'VNETWORK', "$vnetwork" `
-replace 'VNETMASK', "$vnetmask" `
-replace 'ADMINISTRATORPASSWORDVALUE', $AdministratorPasswordValue
$machinemacswitchblock += $PrimaryDCConfig
}

if ($SecondaryDCs -ne $null)
    {
        foreach ($SecondaryDC in $SecondaryDCs)
            {
                $SecondaryDCConfig = @'

"SECONDARYDCMAC" { 

    $IP = "VNETWORK.SECONDARYDCIP"
    $MaskBits = "VNETMASK"
    $Gateway = "VNETWORK.ROUTERIPADDRESS"
    $Dns = "VNETWORK.DCIPADDRESS"
    $IPType = "IPv4"
    $adapter = Get-NetAdapter
    If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {$adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false}
    If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {$adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false}
    $adapter | New-NetIPAddress -AddressFamily $IPType -IPAddress $IP -PrefixLength $MaskBits -DefaultGateway $Gateway
    $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
    install-windowsfeature AD-Domain-Services, RSAT-ADDS, DHCP -IncludeManageMentTools
    Import-Module ADDSDeployment
    $cred = ConvertTo-SecureString "ADMINISTRATORPASSWORDVALUE" -AsPlainText -Force
    $action = New-ScheduledTaskAction -Execute 'Powershell.exe'-Argument '-NoProfile -WindowStyle Hidden -File c:\Setup\Scripts\SecondLogonSECONDARYDC.ps1'
    $trigger =  New-ScheduledTaskTrigger -AtLogon
    $User = "Administrator"
    Register-ScheduledTask -Action $action -Trigger $trigger -User $User -TaskName "SecondLogon" -Description "Second Logon Script"
    $domainpassword = ConvertTo-SecureString "ADMINISTRATORPASSWORDVALUE" -AsPlainText -Force
    $DomainCred = New-Object System.Management.Automation.PSCredential ("NETBIOSDOMAINNAME\Administrator", $password)
    Install-ADDSDomainController -SkipPreChecks -SafeModeAdministratorPassword $cred -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -InstallDns -Credential $DomainCred -DomainName "FULLYQUALIFIEDDOMAINNAME" -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true
    }

'@
$SecondaryDCConfig = $SecondaryDCConfig -replace "SECONDARYDCMAC", $SecondaryDC.mac`
-replace 'THISPCHOSTNAME', "$($SecondaryDC.name)" `
-replace 'NETBIOSDOMAINNAME', "$netbiosname" `
-replace 'FULLYQUALIFIEDDOMAINNAME', "$domainname" `
-replace 'ROUTERIPADDRESS', "$($Router.IP)" `
-replace 'DCIPADDRESS', "$($PrimaryDC.IP)" `
-replace 'SECONDARYDCIP', "$($SecondaryDC.IP)" `
-replace 'VNETWORK', "$vnetwork" `
-replace 'VNETMASK', "$vnetmask" `
-replace 'ADMINISTRATORPASSWORDVALUE', $AdministratorPasswordValue
$machinemacswitchblock += $SecondaryDCConfig 
        }
    }

    if ($SCCMServer -ne $null)
{$SCCMServerConfig = @'

"SCCMSERVERMAC" {

   $IP = "VNETWORK.SCCMIPADDRESS"
   $MaskBits = "VNETMASK"
   $Gateway = "VNETWORK.ROUTERIPADDRESS"
   $Dns = "VNETWORK.DCIPADDRESS"
   $IPType = "IPv4"
   $adapter = Get-NetAdapter
   If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {$adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false}
   If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {$adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false}
   $adapter | New-NetIPAddress -AddressFamily $IPType -IPAddress $IP -PrefixLength $MaskBits -DefaultGateway $Gateway
   $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
   $action = New-ScheduledTaskAction -Execute 'Powershell.exe'-Argument '-NoProfile -WindowStyle Hidden -File c:\Setup\Scripts\SecondLogonSCCMSERVER.ps1'
   $trigger =  New-ScheduledTaskTrigger -AtLogon
   Register-ScheduledTask -Action $action -Trigger $trigger -User Administrator -TaskName "SecondLogon" -Description "Second Logon Script"
   Rename-Computer -NewName THISPCHOSTNAME -Force -Restart
       }

'@
$SCCMServerConfig = $SCCMServerConfig -replace "SCCMSERVERMAC", $SCCMServer.mac`
-replace 'THISPCHOSTNAME', "$($SCCMServer.name)" `
-replace 'NETBIOSDOMAINNAME', "$netbiosname" `
-replace 'FULLYQUALIFIEDDOMAINNAME', "$domainname" `
-replace 'ROUTERIPADDRESS', "$($Router.IP)" `
-replace 'DCIPADDRESS', "$($PrimaryDC.IP)" `
-replace 'SCCMIPADDRESS', "$($SCCMServer.IP)" `
-replace 'VNETWORK', "$vnetwork" `
-replace 'VNETMASK', "$vnetmask" `
-replace 'ADMINISTRATORPASSWORDVALUE', $AdministratorPasswordValue
$machinemacswitchblock += $SCCMServerConfig
    }

    if ($Memberservers -ne $null)
    {
        foreach ($Memberserver in $Memberservers)
            {
                $MemberserverConfig = @'

"MEMBERSERVERMAC" {

    $DHCPTrue = "MEMBERSERVERIP"
    if ($DHCPTrue -ne "DHCP")
        {
            $IP = "VNETWORK.MEMBERSERVERIP"
            $MaskBits = "VNETMASK"
            $Gateway = "VNETWORK.ROUTERIPADDRESS"
            $Dns = "VNETWORK.DCIPADDRESS"
            $IPType = "IPv4"
            $adapter = Get-NetAdapter
            If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {$adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false}
            If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {$adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false}
            $adapter | New-NetIPAddress -AddressFamily $IPType -IPAddress $IP -PrefixLength $MaskBits -DefaultGateway $Gateway
            $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
        }
        $action = New-ScheduledTaskAction -Execute 'Powershell.exe'-Argument '-NoProfile -WindowStyle Hidden -File c:\Setup\Scripts\SecondLogonMEMBERSERVER.ps1'
        $trigger =  New-ScheduledTaskTrigger -AtLogon
        Register-ScheduledTask -Action $action -Trigger $trigger -User Administrator -TaskName "SecondLogon" -Description "Second Logon Script"
        $domainpassword = ConvertTo-SecureString "ADMINISTRATORPASSWORDVALUE" -AsPlainText -Force
        $DomainCred = New-Object System.Management.Automation.PSCredential ("NETBIOSDOMAINNAME\Administrator", $password)
        Add-Computer -DomainName NETBIOSDOMAINNAME -NewName THISPCHOSTNAME -Credential $DomainCred -Restart -Force
    }

'@
$MemberserverConfig = $MemberserverConfig -replace "MEMBERSERVERMAC", $Memberserver.mac`
-replace 'THISPCHOSTNAME', "$($Memberserver.name)" `
-replace 'NETBIOSDOMAINNAME', "$netbiosname" `
-replace 'FULLYQUALIFIEDDOMAINNAME', "$domainname" `
-replace 'ROUTERIPADDRESS', "$($Router.IP)" `
-replace 'DCIPADDRESS', "$($PrimaryDC.IP)" `
-replace 'MEMBERSERVERIP', "$($Memberserver.IP)" `
-replace 'VNETWORK', "$vnetwork" `
-replace 'VNETMASK', "$vnetmask" `
-replace 'ADMINISTRATORPASSWORDVALUE', $AdministratorPasswordValue
$machinemacswitchblock += $MemberserverConfig 
        }
    }

    if ($Workstations -ne $null)
    {
        foreach ($Workstation in $Workstations)
            {
                $WorkstationConfig = @'

"WORKSTATIONMAC" {

    $DHCPTrue = "WORKSTATIONIP"
    if ($DHCPTrue -ne "DHCP")
        {
            $IP = "VNETWORK.WORKSTATIONIP"
            $MaskBits = "VNETMASK"
            $Gateway = "VNETWORK.ROUTERIPADDRESS"
            $Dns = "VNETWORK.DCIPADDRESS"
            $IPType = "IPv4"
            $adapter = Get-NetAdapter
            If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {$adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false}
            If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {$adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false}
            $adapter | New-NetIPAddress -AddressFamily $IPType -IPAddress $IP -PrefixLength $MaskBits -DefaultGateway $Gateway
            $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
        }
        $action = New-ScheduledTaskAction -Execute 'Powershell.exe'-Argument '-NoProfile -WindowStyle Hidden -File c:\Setup\Scripts\SecondLogonWORKSTATION.ps1'
        $trigger =  New-ScheduledTaskTrigger -AtLogon
        Register-ScheduledTask -Action $action -Trigger $trigger -User Administrator -TaskName "SecondLogon" -Description "Second Logon Script"
        $domainpassword = ConvertTo-SecureString "ADMINISTRATORPASSWORDVALUE" -AsPlainText -Force
        $DomainCred = New-Object System.Management.Automation.PSCredential ("NETBIOSDOMAINNAME\Administrator", $password)
        Add-Computer -DomainName NETBIOSDOMAINNAME -NewName THISPCHOSTNAME -Credential $DomainCred -Restart -Force
    }

'@

$WorkstationConfig = $WorkstationConfig -replace "WORKSTATIONMAC", $Workstation.mac`
-replace 'THISPCHOSTNAME', "$($Workstation.name)" `
-replace 'NETBIOSDOMAINNAME', "$netbiosname" `
-replace 'FULLYQUALIFIEDDOMAINNAME', "$domainname" `
-replace 'ROUTERIPADDRESS', "$($Router.IP)" `
-replace 'DCIPADDRESS', "$($PrimaryDC.IP)" `
-replace 'WORKSTATIONIP', "$($Workstation.IP)" `
-replace 'VNETWORK', "$vnetwork" `
-replace 'VNETMASK', "$vnetmask" `
-replace 'ADMINISTRATORPASSWORDVALUE', $AdministratorPasswordValue
$machinemacswitchblock += $WorkstationConfig 
        }
    }

$destfile =  "$PSScriptroot/Toolkit/Scripts/Setup.ps1"
(Get-Content "$PSScriptroot/Toolkit/Scripts/Setup-Base.ps1") | Foreach-Object {$_ -replace 'LISTOFMACHINESINBUILDLIST', ($machinemacswitchblock) }| Set-Content $destFile


#endregion

#region create AutoUnattend.xml

$autounattendbase = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
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
            <InputLocale>en-gb</InputLocale>
            <SystemLocale>en-gb</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>en-gb</UserLocale>
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
                <LogonCount>2</LogonCount>
                <Username>administrator</Username>
            </AutoLogon>
            <ComputerName>DC1</ComputerName>
            <TimeZone>GMT Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-gb</InputLocale>
            <SystemLocale>en-gb</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>en-gb</UserLocale>
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
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-gb</InputLocale>
            <SystemLocale>en-gb</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>en-gb</UserLocale>
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
                    <LogonCount>2</LogonCount> 
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

if ($buildlist.OS -contains "win10")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows10Version `
        | Set-Content "$PSScriptroot/Toolkit/AutoUnattend/win10.xml"
    }
if ($buildlist.OS -contains "win8.1")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows81Version `
        | Set-Content "$PSScriptroot/Toolkit/AutoUnattend/win8.1.xml"
    }
if ($buildlist.OS -contains "win8")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows8Version `
        | Set-Content "$PSScriptroot/Toolkit/AutoUnattend/win8.xml"
    }
if ($buildlist.OS -contains "win7")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $Windows7Version `
        | Set-Content "$PSScriptroot/Toolkit/AutoUnattend/win7.xml"
    }
if ($buildlist.OS -contains "win2k19")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2019Version `
        | Set-Content "$PSScriptroot/Toolkit/AutoUnattend/win2k19.xml"
    }
if ($buildlist.OS -contains "win2k16")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2016Version `
        | Set-Content $PSScriptroot/Toolkit/AutoUnattend/win2k16.xml
    }
if ($buildlist.OS -contains "win2k12r2")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2012R2Version `
        | Set-Content $PSScriptroot/Toolkit/AutoUnattend/win2k12r2.xml
    }
if ($buildlist.OS -contains "win2k12")
    {
        $autounattendbase -replace "ADMINISTRATORPASSWORDVALUE", $AdministratorPasswordValue`
        -replace 'OPERATINGSYSTEMIMAGENAME', $WindowsServer2012Version `
        | Set-Content $PSScriptroot/Toolkit/AutoUnattend/win2k12.xml
    }

#endregion


#region build ISO files for OS versions

Copy-Item -Path "$PSScriptroot/Toolkit/Certificates" -Recurse -Destination "$PSScriptroot/ISOBuild"
Copy-Item -Path "$PSScriptroot/Toolkit/Drivers" -Recurse -Destination "$PSScriptroot/ISOBuild"
Copy-Item -Path "$PSScriptroot/Toolkit/OpenSSH-Win64" -Recurse -Destination "$PSScriptroot/ISOBuild"
Copy-Item -Path "$PSScriptroot/Toolkit/QEMUGuestAgent" -Recurse -Destination "$PSScriptroot/ISOBuild"
Copy-Item -Path "$PSScriptroot/Toolkit/Scripts" -Recurse -Destination "$PSScriptroot/ISOBuild"
Move-Item -Path "$PSScriptroot/ISOBuild/Scripts/Setup.ps1" -Destination "$PSScriptroot/ISOBuild"
New-Item -ItemType Directory $PSScriptroot/ISOBuild/SpiceGuestTools
New-Item -ItemType Directory $PSScriptroot/ISOBuild/SpiceWebDAV
Copy-Item -Path "$PSScriptroot/Toolkit/Downloads/spice-guest-tools-latest.exe" -Destination "$PSScriptroot/ISOBuild/SpiceGuestTools"
Copy-Item -Path "$PSScriptroot/Toolkit/Downloads/spice-webdavd-x64-latest.msi" -Destination "$PSScriptroot/ISOBuild/SpiceWebDAV"

$isostobuild = Get-ChildItem -Path "$PSScriptroot/Toolkit/AutoUnattend" -filter *.xml

foreach ($isotobuild in $isostobuild)
    {
        copy-item -Path $isotobuild.fullname -Destination "$PSScriptroot/ISOBuild/autounattend.xml" -Force
        start-process -Filepath "xorrisofs" -Argumentlist "-r -J -o $PSScriptroot/ISO/$($isotobuild.basename)-setup.iso $PSScriptroot/ISOBuild/" -Wait
    }

#endregion

#region define Virtual Network
$QEMUDefineNetwork = @"
<network>
  <name>$QEMUNetwork</name>
  <bridge name="$QEMUBridgeName" stp="on" delay="0"/>
  <domain name="$QEMUNetwork"/>
</network>
"@

$QEMUDefineNetwork | Out-File -FilePath "$PSScriptroot/Toolkit/HostScripts/network.xml" -Force

$checknetwork = virsh net-list --all
if ($checknetwork -notmatch $QEMUNetwork)
    {
        Start-Process "virsh" -ArgumentList "net-define --file $PSScriptroot/Toolkit/HostScripts/network.xml" -Wait
        Start-Process "virsh" -ArgumentList "net-start $QEMUNetwork" -Wait
        Start-Process "virsh" -ArgumentList "net-autostart $QEMUNetwork" -Wait
    }


#endregion


#region define Virtual Machines

foreach ($machine in $PrimaryDC)
    {
        start-process -filepath "virt-install" -ArgumentList "--virt-type=kvm --boot machine=q35 --boot uefi --name=$($machine.name) --ram=$($machine.ram) --vcpus=$($machine.vcpu) --os-type=windows --os-variant=$($machine.os) --disk $psscriptroot/$($machine.name).qcow2,size=$($machine.disk),bus=sata,format=qcow2 --disk $psscriptroot/ISO/$($machine.os)-setup.iso,device=cdrom,bus=sata --cdrom=$psscriptroot/ISO/$($machine.os).iso --network=network=$QEMUNetwork,model=virtio,mac=$($machine.mac) --graphics=spice $VirtInstallArgs"
        for ($i=1; $i -le 30; $i++)
            {
                start-process "virsh" -ArgumentList "send-key $($machine.name) KEY_ENTER"
                start-sleep -Milliseconds 200 
            }

            Write-Host "Waiting for 3 minutes for Primary DC to get ahead so other machines can join domain"
            Start-Sleep -Seconds 180
    }



foreach ($machine in ($buildlist | Where-Object $_ -ne $PrimaryDC | Where-Object $_ -ne $Router))
    {
        start-process -filepath "virt-install" -ArgumentList "--virt-type=kvm --boot machine=q35 --boot uefi --name=$($machine.name) --ram=$($machine.ram) --vcpus=$($machine.vcpu) --os-type=windows --os-variant=$($machine.os) --disk $psscriptroot/$($machine.name).qcow2,size=$($machine.disk),bus=sata,format=qcow2 --disk $psscriptroot/ISO/$($machine.os)-setup.iso,device=cdrom,bus=sata --cdrom=$psscriptroot/ISO/$($machine.os).iso --network=network=$QEMUNetwork,model=virtio,mac=$($machine.mac) --graphics=spice $VirtInstallArgs"
        for ($i=1; $i -le 30; $i++)
            {
                start-process "virsh" -ArgumentList "send-key $($machine.name) KEY_ENTER"
                start-sleep -Milliseconds 200 
            }

    }




#endregion
