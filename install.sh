#!/usr/bin/env bash

brews=(
	awscli
	git
	goofys
	imagemagick
	mas
	python
	python3
	youtube-dl
)

casks=(
	amazon-chime
	amazon-workdocs
	elmedia-player
	google-chrome
	osxfuse
	pycharm
	sublime-text
)

pips=(
	pip
	numpy
	matplotlib
	moviepy
	opencv-contrib-python
)

apps=(
	417375580	#BetterSnapTool
	1209754386	#eDrawings
	1436953057	#Ghostery Lite
	1289583905 	#Pixelmator Pro
	1003160018	#Quip
	930093508	#Shapes
	457622435 	#Yoink
)

git_configs=(
  "user.name clayflannigan"
  "user.email clay.flannigan@gmail.com"
#  "user.signingkey ${gpg_key}"
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
    echo "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo -e "\033[1;31m ERROR: Failed to execute: $exec \033[0m"
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

echo "*** Install xcode comannd line tools ***"
xcode-select --install

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

echo "*** Install homebrew packages ***"
install 'brew_install_or_upgrade' "${brews[@]}"

echo "*** Install cask software ***"
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
  echo "*** Install software from Mac App Store ***"
  install 'mas install' "${apps[@]}"
fi

Echo "*** Set git defaults ***"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

echo "alias python=/usr/local/bin/python3.7" >> ~/.zshrc

echo "*** Cleanup ***"
brew cleanup

echo "Done!"
