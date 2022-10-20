#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '



########
### Mine
##
#

export PATH=$PATH:/opt/gnatstudio/bin

source /usr/share/doc/pkgfile/command-not-found.bash



##################
### Bash Variables
##
#

export VISUAL=
export EDITOR=mousepad
export HISTCONTROL=ignoredups



################################
### Useful Aliases and Functions
##
#

function mp()
{
   mousepad "$1" &
}


alias ebrc='mousepad ~/.bashrc &'
alias update_grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias mksrcinfo='makepkg --printsrcinfo > .SRCINFO'
alias gps="gnatstudio &"
alias sgo="smartgit --open ."
alias my_update='pikaur -Syu --disable-download-timeout'

alias update_pacman_mirrors='sudo reflector --sort rate               \
                                            --age 48                  \
                                            --delay 1                 \
                                            --fastest 25              \
                                            --number 25               \
                                            --protocol https          \
                                            --connection-timeout 20   \
                                            --download-timeout 20     \
                                            --verbose'
###################
### Coloured Output
##
#
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
export LESS='-R --use-color -Dd+r$Du+b'
alias ls='ls --color=auto'


