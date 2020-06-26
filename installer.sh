#!
if (whiptail --title "mArchiver Installer" --yesno "Do you want to install mArchiver?" 8 78); then
    echo "Initializting installation of mArchiver..."
else
    exit
fi

echo "Creating directories..."
mkdir ~/Softwares
mkdir ~/Softwares/mArchiver
directory_of_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Copying necessary files..."
cp $directory_of_script/mArchiver.sh ~/Softwares/mArchiver/
cp -R $directory_of_script/lib ~/Softwares/mArchiver/
cp $directory_of_script/release.txt ~/Softwares/mArchiver/

echo "Adding script for easy access..."
bashline="alias mArchiver='bash ~/Softwares/mArchiver/mArchiver.sh'"
foundLine=$(grep mArchiver ~/.bashrc)

if [[ $bashline == $foundLine ]]; then
  echo "bashrc doesn't need to be edited"
else
  echo "Copying line to bashrc..."
  echo "alias mArchiver='bash ~/Softwares/mArchiver/mArchiver.sh'" >> ~/.bashrc
  source ~/.bashrc
fi

whiptail --title "mArchiver Installer" --msgbox "Installation complete! Please restart your pc.\nTo start the program, go to terminal and type- mArchiver" 8 78
