### This is run as root

function install_oh_my_zsh {

  local change_user="$1"
  local change_user_home="$2"
  local ohmyzsh_repo='https://raw.githubusercontent.com/robbyrussell/oh-my-zsh'

  # copy zshrc template to .zshrc in user home
  cp "/etc/zsh/newuser.zshrc.recommended" "$change_user_home/.zshrc"
  chown "$change_user:$change_user" "$change_user_home/.zshrc"
  echo "copying zshrc template to $change_user_home/.zshrc"

  # change default shell to zsh
  chsh -s "$(which zsh)" "$change_user"
  echo "default shell changed to zsh for user '$change_user'"

  # download install script
  curl -fsSL "$ohmyzsh_repo/master/tools/install.sh" \
    -o "$change_user_home/install_ohmyzsh.sh"
  echo "oh-my-zsh install script downloaded to" \
       "$change_user_home/install_ohmyzsh.sh"

  # install oh-my-zsh
  if [ ! -d "$change_user_home/.oh-my-zsh" ]; then

    if [ "$change_user" == 'root' ]; then
      sh "$change_user_home/install_ohmyzsh.sh"
    else
      su -c "sh '$change_user_home/install_ohmyzsh.sh'" "$change_user"
    fi

    # change zsh theme
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' \
      "$change_user_home/.zshrc"

    # make sure that .zshrc is owned by user
    chown "$change_user:$change_user" "$change_user_home/.zshrc"

    echo "oh-my-zsh installed for user $change_user"
  else
    echo "oh-my-zsh alredy installed for user $change_user, skipping"
  fi

  # remove install script, goodbye
  rm -f "$change_user_home/install_ohmyzsh.sh"

}

install_oh_my_zsh 'root' '/root'

if ls /home/one; then
  install_oh_my_zsh 'one' '/home/one'
else
  useradd -m one
  echo 'one:8426' | sudo chpasswd
  adduser one sudo
  echo 'one ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
  install_oh_my_zsh 'one' '/home/one'
fi
