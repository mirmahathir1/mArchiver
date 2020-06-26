success() {
  terminalSize=$(tput cols)
  for (( i = 0; i < $terminalSize; i++ )); do
    echo -ne "\e[1;32m_\e[0m"
  done
  echo -e "\e[1;32mSUCCESS: $1 \e[0m"
  for (( i = 0; i < $terminalSize; i++ )); do
    echo -ne "\e[1;32m_\e[0m"
  done
}

failure() {
  #statements
  terminalSize=$(tput cols)
  for (( i = 0; i < $terminalSize; i++ )); do
    echo -ne "\e[1;31m_\e[0m"
  done
  echo -e "\e[1;31mFAILURE: $1 \e[0m"
  for (( i = 0; i < $terminalSize; i++ )); do
    echo -ne "\e[1;31m_\e[0m"
  done
  whiptail --title "ERROR" --msgbox "$1 operation was unsuccessful." 10 70
  exit
}

completed() {
  if [ $? -eq 0 ]; then
      success "$1"
  else
      failure "$1"
  fi
}

prompt() {
  read -n 1 -s -r -p "Press any key to continue"
}
