#!
version="2.5.1"

directory_of_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#echo $directory_of_script
directory_of_lib="$directory_of_script/lib"
#echo $directory_of_lib
#. $directory_of_lib/logger.sh
#resize -s 40 150
. $directory_of_lib/settings.sh

echo "Please maximize terminal to continue"
while [[ 1 ]]; do
  current_width=$(tput cols)
  current_height=$(tput lines)

  if [ $current_width -gt $MINIMUM_WIDTH -a $current_height -gt $MINIMUM_HEIGHT ]
  then
    break
  fi
  sleep 1
done

while [[ 1 ]];
do
  password=$(whiptail --passwordbox "Enter password" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH --title "Welcome to mArchiver $version" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
      echo "password entered"
  else
      exit
  fi

  passwordsize=${#password}
  if [[ "$passwordsize" == 0 ]]; then
    whiptail --title "Error" --msgbox "Password length must be non zero" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH
    continue
  fi

  confirmPassword=$(whiptail --passwordbox "Confirm password" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH --title "Welcome to mArchiver $version" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
      echo "confirm password entered"
  else
      exit
  fi

  if [[ "$password" != "$confirmPassword" ]]; then
    whiptail --title "Error" --msgbox "Sorry passwords didn't match" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH
    continue
  else
    break
  fi
done

while [[ 1 ]]; do
  args=(--title "mArchiver file browser")
  args+=(  --menu "Current directory: $(pwd) \nChoose file/folder:" $LARGE_BOX_HEIGHT $LARGE_BOX_WIDTH $LARGE_BOX_MAXOPTIONS)

  args+=( ".." "" )

  for i in *
  do
    details=""
    if echo "$i" | grep -q '.gpg'; then
      decoded_file_name=$(bash "$directory_of_lib/namelocker.sh" "$i" "$password")

      # encoded_file_name="${i%.gpg}"
      # decoded_file_name=$(echo "$encoded_file_name" | base64 --decode | openssl aes-256-cbc -a -d -salt -k $password)

      if [ "$decoded_file_name" == "0" ]; then
          continue
      fi

      if [ -f "$i" ]; then
        if echo "$decoded_file_name" | grep -q '.mzip'; then
          decoded_file_name="${decoded_file_name%.mzip}"
          details="|FOLDER|$decoded_file_name"
        else
          details="|FILE|$decoded_file_name"
        fi
      else
        details="|FOLDER|$decoded_file_name"
      fi
    fi
    args+=( "$i" "$details" )
  done

  CHOICE=$(whiptail "${args[@]}" 3>&2 2>&1 1>&3)

  if [ $? == 0 ]; then
    if [ -f "$CHOICE" ]; then
      if echo $CHOICE | grep -q '.gpg'; then
        option=$(whiptail --title "mArchiver file browser" --menu "Choose action" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH 1 "1" "Decrypt" 3>&2 2>&1 1>&3)
        if [ $? != 0 ]; then
            continue
        fi

        bash "$directory_of_lib/lock.sh" "./$CHOICE" "$password"
      else
        option=$(whiptail --title "mArchiver file browser" --menu "Choose action" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH 2 "1" "Open" "2" "Encrypt" 3>&2 2>&1 1>&3)
        if [ $? != 0 ]; then
            continue
        fi
        if [ $option == "1" ]; then
          xdg-open "$CHOICE"
        elif [ $option == "2" ]; then
          bash "$directory_of_lib/lock.sh" "./$CHOICE" "$password"
        fi
      fi
    else
      if [[ "$CHOICE" == ".." || "$CHOICE" == "*" ]]; then
        cd ..
        continue
      fi

      if echo $CHOICE | grep -q '.gpg'; then
        option=$(whiptail --title "mArchiver file browser" --menu "select folder" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH 3 "1" "Open" "2" "Decrypt name" "3" "Decrypt recursively" 3>&2 2>&1 1>&3)
        if [ $? != 0 ]; then
            continue
        fi

        if [ $option == "1" ]; then
          cd "$CHOICE"
        elif [ $option == "2" ]; then
          # encoded_name="${CHOICE%.gpg}"
          # decoded_name=$(echo "$encoded_name" | base64 --decode | openssl aes-256-cbc -a -d -salt -k "$password")

          decoded_name=$(bash "$directory_of_lib/namelocker.sh" "$CHOICE" "$password")

          mv "$CHOICE" "$decoded_name"

        elif [ $option == "3" ]; then
          recurseDecrypt(){
            cd "$1"
            for element in *
            do
              if [ -d "$element" ]; then
                # encoded_name="${element%.gpg}"
                # decoded_name=$(echo "$encoded_name" | base64 --decode | openssl aes-256-cbc -a -d -salt -k "$password")
                if echo "$element" | grep -q '.gpg'; then
                  decoded_name=$(bash "$directory_of_lib/namelocker.sh" "$element" "$password")
                  mv "$element" "$decoded_name"
                  recurseDecrypt "$decoded_name"
                else
                  recurseDecrypt "$element"
                fi
              elif [ -f "$element" ]; then
                if echo "$element" | grep -q '.gpg'; then
                  bash "$directory_of_lib/lock.sh" "./$element" "$password"
                fi
                #statements
              fi
            done
            cd ../
          }
          # encoded_name="${CHOICE%.gpg}"
          # decoded_name=$(echo "$encoded_name" | base64 --decode | openssl aes-256-cbc -a -d -salt -k "$password")

          decoded_name=$(bash "$directory_of_lib/namelocker.sh" "$CHOICE" "$password")

          mv "$CHOICE" "$decoded_name"
          recurseDecrypt "$decoded_name"
        fi
      else
        option=$(whiptail --title "mArchiver file browser" --menu "Selected folder: $CHOICE. Choose action:" $SMALL_BOX_HEIGHT $SMALL_BOX_WIDTH 4 "1" "Open" "2" "Encrypt name only" "3" "Encrypt folder" "4" "Encrypt recursively" 3>&2 2>&1 1>&3)
        if [ $? != 0 ]; then
            continue
        fi

        if [ $option == "1" ]; then
          cd "$CHOICE"
        elif [ $option == "2" ]; then
          # encryptedName=$(echo $CHOICE | openssl aes-256-cbc -a -salt -k "$password" | base64 -w 0)

          encryptedName=$(bash "$directory_of_lib/namelocker.sh" "$CHOICE" "$password")

          mv "$CHOICE" "$encryptedName"
        elif [ $option == "3" ]; then
          bash "$directory_of_lib/lock.sh" "./$CHOICE" "$password"
        elif [ $option == "4" ]; then
          recurse(){
            cd "$1"
            for element in *
            do

              if [ -d "$element" ]; then
                # encryptedName=$(echo "$element" | openssl aes-256-cbc -a -salt -k "$password" | base64 -w 0)
                if echo "$element" | grep -q -v '.gpg'; then
                  encryptedName=$(bash "$directory_of_lib/namelocker.sh" "$element" "$password")
                  mv "$element" "$encryptedName"
                  recurse "$encryptedName"
                else
                  recurse "$element"
                fi

              elif [ -f "$element" ]; then
                if echo "$element" | grep -q -v '.gpg'; then
                  bash "$directory_of_lib/lock.sh" "./$element" "$password"
                fi
                #statementsz
              fi
            done
            cd ../
          }
          # encryptedName=$(echo "$CHOICE" | openssl aes-256-cbc -a -salt -k "$password" | base64 -w 0)
          encryptedName=$(bash "$directory_of_lib/namelocker.sh" "$CHOICE" "$password")
          mv "$CHOICE" "$encryptedName"
          recurse "$encryptedName"
          #statements
        fi
      fi
    fi
  else
     break
  fi
done
