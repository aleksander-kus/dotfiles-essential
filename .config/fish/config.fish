set -U fish_user_paths $fish_user_paths $HOME/.local/bin/
set fish_greeting                      # Supresses fish's intro message
set TERM "xterm-256color"              # Sets the terminal type
#set EDITOR "emacsclient -t -a ''"      # $EDITOR use Emacs in terminal
#set VISUAL "emacsclient -c -a emacs"   # $VISUAL use Emacs in GUI mode
setenv EDITOR vim
setenv VISUAL vim
set -U fish_color_command dfdfdf       # Set the default command color to white

### DEFAULT EMACS MODE OR VI MODE ###
function fish_user_key_bindings
  # fish_default_key_bindings
  fish_vi_key_bindings
end
### END OF VI MODE ###

### FUNCTIONS ###
# Functions needed for !! and !$
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end
# The bindings for !! and !$
if [ $fish_key_bindings = fish_vi_key_bindings ]
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Function for creating a backup file
# ex: backup file.txt
# result: copies file as file.txt.bak
function backup --argument filename
    cp $filename $filename.bak
end

# Function for copying files and directories, even recursively.
# ex: copy DIRNAME LOCATIONS
# result: copies the directory and all of its contents.
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
	set from (echo $argv[1] | trim-right /)
	set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# Function for printing a column (splits input on whitespace)
# ex: echo 1 2 3 | coln 3
# output: 3
function coln
    while read -l input
        echo $input | awk '{print $'$argv[1]'}'
    end
end

# Function for printing a row
# ex: seq 3 | rown 3
# output: 3
function rown --argument index
    sed -n "$index p"
end

# Function for ignoring the first 'n' lines
# ex: seq 10 | skip 5
# results: prints everything but the first 5 lines
function skip --argument n
    tail +(math 1 + $n)
end

# Function for taking the first 'n' lines
# ex: seq 10 | take 5
# results: prints only the first 5 lines
function take --argument number
    head -$number
end

function mkdir-cd
    mkdir $argv && cd $argv
end

function backup --argument filename
    cp $filename $filename.bak
end

function restore --argument file
    mv $file (echo $file | sed s/.bak//)
end

function row --argument index
    sed -n "$index p"
end

function trim-right --argument char
    sed "s|$char\$||"
end

function is-clean-zip --argument zipfile
    set summary (zip -sf $zipfile | string split0)
    set first_file (echo $summary | row 2 | string trim)
    set first_file_last_char (echo $first_file | string sub --start=-1)
    set n_files (echo $summary | awk NF | tail -1 | coln 2)
    test $n_files = 1 && test $first_file_last_char = /
end

function clean-unzip --argument zipfile
    if not test (echo $zipfile | string sub --start=-4) = .zip
        echo (status function): argument must be a zipfile
        return 1
    end

    if is-clean-zip $zipfile
        unzip $zipfile
    else
        set zipname (echo $zipfile | trim-right '.zip')
        mkdir $zipname || return 1
        unzip $zipfile -d $zipname
    end
end

function unzip-cd --argument zipfile
    clean-unzip $zipfile && cd (echo $zipfile | trim-right .zip)
end

function remove
    set original_args $argv

    argparse r f -- $argv

    if not set -q _flag_r || set -q _flag_f
        rm $original_args
        return
    end

    function confirm-remove --argument message
        if not confirm $message
            echo 'Cancelling.'
            exit 1
        end
    end

    for f in $argv
        set gitdirs (find $f -name .git)
        for gitdir in $gitdirs
            confirm-remove "Remove .git directory $gitdir?"
            rm -rf $gitdir
        end
    end

    rm $original_args
end
### END OF FUNCTIONS ###

### SSH AGENT ###
if test -z (pgrep ssh-agent)
  eval (ssh-agent -c)
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
  set -Ux SSH_AGENT_PID $SSH_AGENT_PID
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
end


### ALIASES ###
# navigation
alias .. 'cd ..' 
alias ... 'cd ../..'
alias .3 'cd ../../..'
alias .4 'cd ../../../..'
alias .5 'cd ../../../../..'

# vim and emacs
alias em '/usr/bin/emacs -nw'
alias emacs "emacsclient -c -a 'emacs'"
alias doomsync "~/.emacs.d/bin/doom sync"
alias doomdoctor "~/.emacs.d/bin/doom doctor"
alias doomupgrade "~/.emacs.d/bin/doom upgrade"
alias doompurge "~/.emacs.d/bin/doom purge"

# Changing "ls" to "exa"
alias ls 'exa --color=always --group-directories-first' # my preferred listing
alias la 'exa -a --color=always --group-directories-first'  # all files and dirs
alias ll 'exa -alg --color=always --group-directories-first'  # long format
alias lt 'exa -aT --color=always --group-directories-first' # tree listing

# pacman and yay
alias pacsyu 'sudo pacman -Syyu'                 # update only standard pkgs
alias update-aur 'yay -Sua --noconfirm'          # update only AUR pkgs
alias update 'yay -Syyu --noconfirm'             # update standard pkgs and AUR pkgs
alias installed 'pacman -Qn'                     # list native packages
alias installed-aur 'pacman -Qm'                 # list AUR packages
alias exinstalled "expac -H M '%011m\t%-20n\t%10d' (comm -23 (pacman -Qqen | sort | psub) (pacman -Qqg base-devel xorg | sort | uniq | psub)) | sort -n"
alias unlock 'sudo rm /var/lib/pacman/db.lck'    # remove pacman lock
alias cleanup 'sudo pacman -Rns (pacman -Qtdq)'  # remove orphaned packages

# get fastest mirrors
alias mirror "sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord "sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors "sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora "sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"

# Colorize grep output (good for log files)
alias grep 'grep --color=auto'

# confirm before overwriting something
alias cp "cp -i"
alias mv 'mv -i'
alias rm 'rm -i'

# defined functions above
alias bk backup
alias re restore
alias mkcd mkdir-cd
alias unzip clean-unzip
alias clu clean-unzip

# recompile and restart xmonad in terminal
alias restart "xmonad --recompile && xmonad --restart"

# adding flags
alias df 'df -h'                          # human-readable sizes
alias free 'free -m'                      # show sizes in MB
alias lynx 'lynx -cfg=~/.lynx/lynx.cfg -lss=~/.lynx/lynx.lss -vikeys'
alias vifm './.config/vifm/scripts/vifmrun'

## get top process eating memory
alias psmem 'ps aux | sort -nr -k 4'
alias psmem10 'ps aux | sort -nr -k 4 | head -10'

## get top process eating cpu ##
alias pscpu 'ps aux | sort -nr -k 3'
alias pscpu10 'ps aux | sort -nr -k 3 | head -10'

# Merge Xresources
alias merge 'xrdb -merge ~/.Xresources'

# get error messages from journalctl
alias jctl "journalctl -p 3 -xb"

# gpg encryption
# verify signature for isos
alias gpg-check "gpg2 --keyserver-options auto-key-retrieve --verify"
# receive the key of a developer
alias gpg-retrieve "gpg2 --keyserver-options auto-key-retrieve --receive-keys"

# switch between shells
alias tobash "sudo chsh $USER -s /bin/bash && echo 'Now log out.'"

# the terminal rickroll
alias rr 'curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'

# Path of Building
alias pob 'wine /home/alex/bin/PathOfBuildingCommunity-Setup-1.4.170.24/Path\ of\ Building.exe'

# Drive mounting
alias ma 'sudo mount -a'
alias umd 'sudo umount /dev/sda1 /dev/sda2'

# git
alias ga "git add"
alias gaa "git add ."
alias gau "git add -u"
alias gai "git add -i"
alias gap "git add -p"
alias gb "git branch"
alias gbd "git branch -d"
alias gc "git commit"
alias gch "git checkout"
alias gcb "git checkout -b"
alias gchm "git checkout master"
alias gd "git diff"
alias gdc "git diff --cached"
alias gf "git fetch"
alias gfnt "git fetch --no-tags"
alias gfpp "git fetch --prune --prune-tags"
alias gi "gitk"
alias gia "gitk --all"
alias gl "git log"
alias glo "git log --oneline"
alias glog "git log --oneline --graph"
alias gloga "git log --oneline --graph --all"
alias gp "git push"
alias gri "git rebase --interactive --rebase-merges"
alias gs "git status"
alias gt "git tag"
alias gta "git tag -a"

# accept autocompletion with Ctrl+F
bind -M insert \cf forward-bigword

# xclip
alias xclip "xclip -selection clipboard"

# quick folder access aliases
alias cra "cd ~/studia/dotnet/CarRentalApp"
alias cras "cd ~/studia/dotnet/CarRentalApiService"
alias startsql "sudo systemctl start mssql-server"
alias stopsql "sudo systemctl stop mssql-server"

### RANDOM COLOR SCRIPT ###
# Arch User Repository: shell-color-scripts
/opt/shell-color-scripts/colorscript.sh random

starship init fish | source
