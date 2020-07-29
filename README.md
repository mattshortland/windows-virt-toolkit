# windows-virt-toolkit

Powershell Scripts to automate VM Setup on QEMU / KVM

This script will download dependencies and drivers for QEMU / Spice / SSH and will create an ISO to automatically install your guest OS

Dependencies required to be able to run this script:
  QEMU/KVM
  libvirt
  virt-manager
  PowerShell
  libisotools
  unzip
  gunzip
  

SETUP INFO

Only Windows versions below are supported for now

 
 win2k8               | Microsoft Windows Server 2008                      | 6.0      | http://microsoft.com/win/2k8
 win2k8r2             | Microsoft Windows Server 2008 R2                   | 6.1      | http://microsoft.com/win/2k8r2
 win2k12              | Microsoft Windows Server 2012                      | 6.3      | http://microsoft.com/win/2k12
 win2k12r2            | Microsoft Windows Server 2012 R2                   | 6.3      | http://microsoft.com/win/2k12r2
 win2k16              | Microsoft Windows Server 2016                      | 10.0     | http://microsoft.com/win/2k16
 win2k19              | Microsoft Windows Server 2019                      | 10.0     | http://microsoft.com/win/2k19 
 win10                | Microsoft Windows 10                               | 10.0     | http://microsoft.com/win/10
 win8.1               | Microsoft Windows 8.1                              | 6.3      | http://microsoft.com/win/8.1
 win8                 | Microsoft Windows 8                                | 6.2      | http://microsoft.com/win/8 
 win7                 | Microsoft Windows 7                                | 6.1      | http://microsoft.com/win/7
  
Guest Specific Variables are used in the powershell script - please modify them if you want to change from the defaults
$AdministratorPasswordValue = 'P@ssword'   -- Set a Super Secure Password
$osinputlanguageandlocale = "en-gb"    -- This will not change the display language of the OS, just the keyboard language / regional settings

Below OS Versions must match the Caption as displayed in "Dism /get-wiminfo" to enable automatic choice of the OS version 
in Unattend.xml, you can change these to other versions if you like, if you blank them or write unsupported data you will
get prompted to choose during install

$Windows10Version = "Windows 10 Enterprise"
$Windows81Version = "Windows 8.1 Enterprise"
$Windows8Version = "Windows 8 Enterprise"
$Windows7Version = "Windows 7 Enterprise"
$WindowsServer2019Version = "Windows Server 2019 SERVERSTANDARD"
$WindowsServer2016Version = "Windows Server 2016 SERVERSTANDARD"
$WindowsServer2012R2Version = "Windows Server 2012 R2 SERVERSTANDARD"
$WindowsServer2012Version = "Windows Server 2012 SERVERSTANDARD"

USING THE SCRIPT

first make the script executable ( chmod +x createautobuildcd.ps1 )
then run it ( ./createautobuildcd.ps1 )
script will prompt for the OS version and if you want UEFI or BIOS, and verify this will work
script will check for exisiting downloaded support files, and if they dont exist fetch them into a Toolkit folder
Script will then extract the drivers and support files for all OS versions
Script will then create an ISO file in the script directory called %osversion%-setup.iso (for example win7-setup.iso)

ADDING THE ISO TO YOUR VM

I will assume if you are using QEMU / VIRSH you know how to do this

When you create your vm in Virtual Machine Manager, choose "customize configuration before install" on the last page
Choose Add Hardware > Storage > Device Type > CDROM
choose the setup iso that was created, click finish then choose Install Now

Windows will begin installation and when completed will log on and finish installing the tools 


