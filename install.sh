#!/usr/bin/env bash

brews=(
  awscli
  git
  imagemagick
  mas
  python
  python3
  youtube-dl
)

casks=(
  istat-menus
)

pips=(
  pip
  numpy
  matplotlib
  opencv-contrib-python
)

######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    #prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  echo "*** Install Homebrew ***"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    echo "*** Update Homebrew ***"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "*** Install packages ***"
install 'brew_install_or_upgrade' "${brews[@]}"

echo "*** Install software ***"
brew tap homebrew/cask-versions
install 'brew cask install' "${casks[@]}"

echo "*** Install secondary packages ***"
install 'pip3 install --upgrade' "${pips[@]}"

echo "*** Update packages ***"
pip3 install --upgrade pip setuptools wheel
if [[ -z "${CI}" ]]; then
  m update install all
fi

if [[ -z "${CI}" ]]; then
  echo "*** Install software from App Store ***"
  mas list
fi

echo "alias python=/usr/local/bin/python3.7" >> ~/.zshrc

echo "*** Cleanup ***"
brew cleanup

echo "Done!"
