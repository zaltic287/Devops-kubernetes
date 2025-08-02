#!/usr/bin/bash

###############################################################
#  TITRE: 
#
#  AUTEUR:   Xavier
#  VERSION: 
#  CREATION:  
#  MODIFIE: 
#
#  DESCRIPTION: 
###############################################################



# Variables ###################################################



# Functions ###################################################



# Let's Go !! #################################################

echo "
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=20000

alias vf='cd /home/oki/gitlab.com/vagrant_files/'
alias pres='cd /home/oki/gitlab.com/'
alias ll='ls -laFh --color=auto'
alias la='ls -A'
alias l='ls -larth'
alias gl='git log'
alias gst='git status'
alias gg='git log --oneline --all --graph --name-status'
alias p='sudo su - postgres'
alias s='sudo -s'


clear
echo -e '\033[0;32m
██╗░░██╗░█████╗░██╗░░░██╗██╗░░██╗██╗
╚██╗██╔╝██╔══██╗██║░░░██║██║░██╔╝██║
░╚███╔╝░███████║╚██╗░██╔╝█████═╝░██║
░██╔██╗░██╔══██║░╚████╔╝░██╔═██╗░██║
██╔╝╚██╗██║░░██║░░╚██╔╝░░██║░╚██╗██║
╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝
'
" >> /home/vagrant/.bashrc
