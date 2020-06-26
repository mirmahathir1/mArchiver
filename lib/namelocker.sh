main_file_name=$1
password=$2

if echo $main_file_name | grep -q '.gpg'; then
  encoded_file_name="${main_file_name%.gpg}"
  decoded_file_name=$(echo "$encoded_file_name" | base64 --decode | openssl aes-256-cbc -a -d -salt -k $password)
  if [ $? != 0 ]; then
    echo 0
  else
    echo "$decoded_file_name"
  fi
else
  encryptedName=$(echo $main_file_name | openssl aes-256-cbc -a -salt -k "$password" | base64 -w 0)
  echo "$encryptedName.gpg"
fi
