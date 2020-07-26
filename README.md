# windows-virt-toolkit

Powershell Scripts to automate VM Setup on QEMU / KVM

This script will download dependencies and drivers for QEMU / Spice / SSH and will automatically install your guest OS as well as installing said dependencies

It can also begin building a Domain for rapid implementation of testing

Dependencies required to be able to run this script:
  QEMU/KVM
  libvirt
  virt-manager
  PowerShell
  libisotools
  unzip
  gunzip
  

There are 2 Files necessary to begin installation, first is buildlist.csv which must contain the information about 
the machines to build

                                              :::BUILDLIST INFO:::

NOTE: It is recommended that you use the mac addresses starting "52:54:00" as noted by libvirt documentation
NOTE: It is recommended that you use a pfSense router to connect your isolated network to your prod/home network.
      instructions and XML configs will be provided in future releases.

name,     mac,                  role,             IP,   OS,       vcpu,     ram,    disk
Router,   52:54:00:44:66:00,    Router,           1,    pfsense,  1,        2048,   5
DC1,      52:54:00:44:66:01,    DomainController, 2,    win2k19,  2,        4096,   40

the Role column has 5 possible values - Router, DomainController, SCCMServer, MemberServer, Workstation

the IP column is for entering the final octet of your subnet so for example if you have a 192.168.1.0/24 subnet 
and you enter 55 in the IP column the machine IP will be 192.268.1.55. You can also enter DHCP to set the guest
to DHCP.  You

the OS column must contain the OS version as listed in the libvirt documentation.  Only Windows versions below are 
supported for now - For windows 7 you must have a custom UEFI capable ISO

 win10                | Microsoft Windows 10                               | 10.0     | http://microsoft.com/win/10             
 win2k12              | Microsoft Windows Server 2012                      | 6.3      | http://microsoft.com/win/2k12           
 win2k12r2            | Microsoft Windows Server 2012 R2                   | 6.3      | http://microsoft.com/win/2k12r2         
 win2k16              | Microsoft Windows Server 2016                      | 10.0     | http://microsoft.com/win/2k16           
 win2k19              | Microsoft Windows Server 2019                      | 10.0     | http://microsoft.com/win/2k19              
 win7                 | Microsoft Windows 7                                | 6.1      | http://microsoft.com/win/7              
 win8                 | Microsoft Windows 8                                | 6.2      | http://microsoft.com/win/8   
 win8.1               | Microsoft Windows 8.1                              | 6.3      | http://microsoft.com/win/8.1
 
 
                                             :::VMSETUP INFO::: 

Guest Specific Variables are used to build out the Domain and DNS settings

$subnet = "192.168.1.0/24" 
  Format must be Network/Mask e.g 192.168.1.0/24
$netbiosname = "NEOTRECOGNISED" 
  Max 16 Characters
$domainname = "notrecognised.com"
  does not have to be internet routable so "test.local" would work
$AdministratorPasswordValue = 'P@ssword'
  Super Secure Password
$osinputlanguageandlocale = "en-gb"  
  This will not change the display language of the OS, just the keyboard input and regional settings

Below OS Versions must match the Caption as displayed in Dism get-wiminfo to enable automatic choice of the OS version 
in Unattend.xml, otherwise you will get prompted to choose

$Windows10Version = "Windows 10 Enterprise"
$Windows81Version = "Windows 8.1 Enterprise"
$Windows8Version = "Windows 8 Enterprise"
$Windows7Version = "Windows 7 Enterprise"
$WindowsServer2019Version = "Windows Server 2019 SERVERSTANDARD"
$WindowsServer2016Version = "Windows Server 2016 SERVERSTANDARD"
$WindowsServer2012R2Version = "Windows Server 2012 R2 SERVERSTANDARD"
$WindowsServer2012Version = "Windows Server 2012 SERVERSTANDARD"

#Host Specific Variables
$QEMUNetwork = "ExampleNetwork"
  Creates a new network if the network name does not exist. QEMU only supports alphanumeric no spaces periods underscores or dashes
$QEMUBridgeName = "virbr99"
  This is required to create the XML file to define the new network. Only change if you already have a network using this bridge
$VirtInstallArgs = '--cpu EPYC'
  Additional Arguments to pass to virt-install




