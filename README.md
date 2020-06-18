# finalflash
This script is a ``MakeInstall.bat`` alternative for Linux users,    
As of today theres no official gibMacOS support for linux,    
even though it works fine Downloading the macOS image  
it wont create the usb installer on Linux,  
thats when ``finalflash.sh`` comes handy,       
it has to be run from gibMacOS-master just like ``MakeInstall.bat`` on windows  
it will install wget curl and  p7zip,    
and extract the RecoveryHDMetaDmg.pkg,          
then it creates an Apple HFS/HFS+ partition and an EFI partition in the usb drive    
it copies the recovery to the HFS+ partition and downloads the latest OpenCore bootloader  
release from github and extracts it to the EFI partition. 
