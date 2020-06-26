#!
target="$1"
password="$2"

target="${target%\'}"
target="${target#\'}"

directory_of_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#echo $directory_of_script
#directory_of_lib=$directory_of_script/lib
#echo $directory_of_lib
. "$directory_of_script/logger.sh"

root_directory="${target%/*}"
cd "$root_directory"
#echo "Current working directory: "
#pwd

file_name="${target##*/}"
#echo Name of file: $file_name

if echo "$target" | grep -q '.gpg'; then
    echo "This is a locked file/ folder. Unlocking $target..."

    encoded_file_name="${file_name%.gpg}"
    decoded_file_name=$(echo "$encoded_file_name" | base64 --decode | openssl aes-256-cbc -a -d -salt -k "$password")

    gpg --yes --batch --passphrase "$password" --output "$decoded_file_name" "$file_name"
    completed "gpg"

    if echo "$decoded_file_name" | grep -q '.mzip'; then
        decoded_file_name="${decoded_file_name%.mzip}"
        echo "NAME OF THE DECODED FILE IS $decoded_file_name"
        mv "$decoded_file_name.mzip" "$decoded_file_name.zip"
        decoded_file_name="$decoded_file_name.zip"
        unzip -o "$decoded_file_name"
        completed "unzip"

        shred -zvu -n 3 "$decoded_file_name"
        completed "shred"
    fi

    rm "$file_name"
    completed "rm"

else
    echo "This is a regular file/ folder. Continuing to lock $target"

    if [ -f "$target" ]; then
        #echo "This is a file"

        encryptedFileName=$(echo "$file_name" | openssl aes-256-cbc -a -salt -k "$password" | base64 -w 0)

        gpg --yes --passphrase "$password" --batch --symmetric --output "$encryptedFileName.gpg" "$file_name"
        completed "gpg"

        shred -zvu -n 3 "$file_name"
        completed "shred"

    else
        #echo "This is a folder"

        zip -r "$file_name.mzip" "$file_name"
        #mv "$file_name.zip" "$file_name.mzip"
        completed "zip"

        encryptedFileName=$(echo "$file_name".mzip | openssl aes-256-cbc -a -salt -k "$password" | base64 -w 0)

        gpg --yes --passphrase "$password" --batch --symmetric --output "$encryptedFileName.gpg" "$file_name.mzip"
        completed "gpg"

        find "$file_name" -exec shred -zvu -n 3 {} \;
        completed "shred"

        rm -r "$file_name"
        completed "rm"

        shred -zvu -n 3 "$file_name.mzip"
        completed "shred"
    fi
fi

gpg-connect-agent reloadagent /bye

echo "Process complete."

#prompt
