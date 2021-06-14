#!/usr/bin/env zsh
#
# Order of loading
# .zshenv
# .zprofile if login
# .zshrc if interactive
# .zlogin if login
# .zlogout
#
# {{{ profiling
# zmodload zsh/datetime
# PS4='+$EPOCHREALTIME %N:%i> '
# exec 3>&2 2>/tmp/zsh_profiling-$$.log
# setopt xtrace promptsubst
# }}}

# Cross Platform .zshrc
# {{{ ENV
# I don't know why `chsh' doesn't work.
# Luckily, `sudo dscl . -change /Users/$USER UserShell /bin/bash /usr/local/bin/bash` works
# Then, still `login' command is used to login onto the Terminal, which is slow
# At least, in iTerm, `Comamnd: /usr/local/bin/zsh --login' is fast enough

typeset -U PATH MANPATH
# local LLVM_PATH=/usr/local/opt/llvm/bin
local LLVM_PATH=/bin
export GOPATH=$HOME/.go
# export PATH=$LLVM_PATH:/usr/local/opt/ccache/libexec:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:/usr/games
export PATH=$PATH:$HOME/.cargo/bin:$GOPATH/bin
# export MANPATH=$MANPATH:/Library/Developer/CommandLineTools/usr/share/man:/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/share/man

export LANG=en_US.UTF-8
export LC_COLLATE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
export LC_MONETARY=en_US.UTF-8
export LC_NUMERIC=en_US.UTF-8
export LC_TIME=en_US.UTF-8

export PYTHONSTARTUP=$HOME/.pythonrc.py
export PYTHONPYCACHEPREFIX=/tmp/__pycache__
export PYTHONBREAKPOINT=ipdb.set_trace
export UA_SAFARI='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/600.3.18 (KHTML, like Gecko) Version/8.0.3 Safari/600.3.18'
export DEFAULT_DNS=1.1.1.1

if [[ $OSTYPE =~ 'darwin*' ]]; then
  export EDITOR="/usr/local/bin/nvim"
  stty -ixon  # for some vim mappings (ctrl-s) to wrok

  eval `/usr/libexec/path_helper -s`
  PATH=$(zsh -fc "typeset -TU P=$PATH p; echo \$P")
  export PATH=$PATH:$(xcode-select -p)/usr/bin
  export MANPATH=$MANPATH:$XCODE_PATH/usr/share/man # FIXME: xcode man path
  export SLIMERJSLAUNCHER=$HOME/Applications/Firefox.app/Contents/MacOS/firefox
  export JAVA_HOME=$(/usr/libexec/java_home)
  export ECLIPSE_HOME=~/Applications/Eclipse.app/Contents/Eclipse

  . /usr/local/opt/fzf/shell/completion.zsh
  . /usr/local/opt/fzf/shell/key-bindings.zsh
elif [[ $OSTYPE =~ 'linux*' ]]; then
  export EDITOR=nvim

  #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
  export SDKMAN_DIR="$HOME/.sdkman"
  local sdkman_init_sh="$HOME/.sdkman/bin/sdkman-init.sh" 
  [[ -s $sdkman_init_sh ]] && source $sdkman_init_sh

  export PATH=$HOME/.ghcup/bin:$HOME/.cabal/bin:$PATH:$HOME/.yarn/bin
  export PATH=$PATH:/snap/bin:/snap/chromium/current/usr/lib/chromium-browser
  # export PATH=$PATH:$(echo $HOME/.gem/ruby/3.*/bin)

  # export NVM_LAZY_LOAD=true
  # [ -d "$HOME/.zsh-nvm" ] && \. "$HOME/.zsh-nvm/zsh-nvm.plugin.zsh"

  if [ -f $HOME/.asdf/asdf.sh ]; then
    source $HOME/.asdf/asdf.sh
    fpath=(${ASDF_DIR}/completions $fpath)
  fi

  autoload bashcompinit && bashcompinit
  local aws_comp=$(whence aws_completer)
  [ -f $aws_comp ] && complete -C $aws_comp aws

  export AWS_VAULT_BACKEND=pass
  alias vault=aws-vault

fi

[ -d ~/.zsh/plugins/forgit ] && source ~/.zsh/plugins/forgit/forgit.plugin.zsh
[ -d ~/.zsh/plugins/gitstatus/ ] && source ~/.zsh/plugins/gitstatus/gitstatus.prompt.zsh


# color os ls output is also affected by TERM=xterm-256color
[ -f ~/.zsh/lscolors.sh ] && source ~/.zsh/lscolors.sh

typeset -U fpath
fpath=(
  /usr/local/opt/git/share/zsh/site-functions
  /usr/local/share/zsh-completions
  $HOME/.zsh/zsh-completions/src
  $HOME/.zfunc
  $HOME/.zsh/plugins/{zsh-notify,ansiweather,zsh-async,forgit}
  $fpath  # placed at last to be override
)

typeset -U module_path
module_path=($module_path /usr/local/lib/zpython)
# }}}

# {{{ History
export HISTCONTROL=ignorespace
export SAVEHIST=32768
export HISTSIZE=$SAVEHIST
export HISTFILE=$HOME/.zsh_history
setopt hist_reduce_blanks
setopt hist_ignore_all_dups
setopt hist_ignore_space
# setopt extended_history
setopt share_history
setopt inc_append_history


# Ctrl-r replaced with hstr
export HH_CONFIG=hicolor        # get more colors
# bindkey -s "\C-r" "\eqhh\n"     # bind hh to Ctrl-r (for Vi mode check doc)
# }}}

# alias {{{
alias cp='cp -i'
alias ll='ls -l'
alias mv='mv -i'
alias vi=nvim
alias sudo='sudo '
alias mux=tmuxinator
alias tree='tree -C'
alias less='less -R'
alias more='more -R'
alias cask='brew cask'
alias gdb="gdb --silent"
alias curl='noglob curl'
alias pip3='noglob python3 -m pip'
alias pip2='noglob python -m pip'
alias youtube-dl='noglob youtube-dl'
alias p4="ping $DEFAULT_DNS"
alias man='LANG=en_US.UTF-8 man'
alias fuck='$(thefuck $(fc -ln -1))'
alias bc="bc --mathlib --quiet --warn"
alias ipython='ipython --profile=common'
alias hp='http_proxy=http://127.0.0.1:8123'
alias pyinstrument='python3 -m pyinstrument'
alias pylab='ipython --profile=common --pylab'
alias smc=/Applications/smcFanControl.app/Contents/Resources/smc
alias highlight='highlight --out-format=xterm256 --style=molokai --tab=2'
alias urlquote='python -c "import urllib, sys; print urllib.quote(sys.argv[1])"'
alias urlunquote='python -c "import urllib, sys; print urllib.unquote(sys.argv[1])"'

case $OSTYPE in
  darwin*)
    alias t=trash
    alias ls='ls -G'
    alias rm=safe-rm
    alias ical='icalbuddy -f'
    alias eject='diskutil eject'
    alias grep='grep --color=auto'
    alias egrep='egrep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias mp='mdfind -onlyin . -name '
    alias js='osascript -l JavaScript'
    alias tempmonitor='tempmonitor -c -a -l'
    alias lsusb='system_profiler SPUSBDataType'
    alias shuf="perl -MList::Util=shuffle -e 'print shuffle <>'"
    alias lock='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
    alias airport=/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
    alias debugserver=/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/Resources/debugserver
    alias screen_saver='open -a /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app'
    ;;
  linux*)
    # alias tmux='TERM=cygwin tmux'
    alias open=xdg-open
    alias pbcopy="wl-copy"
    alias pbpaste="wl-paste"
    alias ls='ls --color=auto'
    alias drop_caches='sudo sysctl vm.drop_caches=1'
    alias godoc='godoc -goroot=/usr/share/go-1.15'

    function knitr() {
      local filename="$1"
      local code=$(cat <<- EOF
        require(knitr);
        require(dplyr);
        require(xaringan);
        # knitr::opts_chunk\$set(cache.extra = knitr::rand_seed);
        knitr::opts_chunk\$set(cache = T);
        xaringan::infinite_moon_reader('${filename}');
EOF
      )
      R --quiet -e "${code}"
    }

    function __rmd() {
      local filename="$1"
      R --quiet -e "rmarkdown::render('${filename}')"
    }

    # broot
    # source /home/congee/.config/broot/launcher/bash/br
    ;;
  msys*)
    ;;
  *)
    ;;
esac
# }}}

# {{{ Completion
###############################################################################
autoload -Uz compinit promptinit color
# compinit -u does full regeneration, not good.
# https://gist.github.com/ctechols/ca1035271ad134841284
setopt extendedglob
if [[ -n ${ZDOTDIR:-${HOME}}/.zcompdump(#qN.mh+24) ]]; then
  compinit;  # do a full check if the .zcompdump is older than 24hrs
else
  compinit -C;  # no check. see man 1 zcompsys, "Use of compinit"
fi;
unsetopt extendedglob

promptinit
###############################################################################


[[ -d /usr/local/opt/coreutils/bin ]] &&\
  find /usr/local/opt/coreutils/bin\
  -print0 | xargs -0 basename | compdef _gnu_generic

# zstyle ':completion:function:completer:command:argument:tag'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:cd:*' menu yes select
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:pkill:*' menu yes select
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w"
zstyle ':completion:*:default' list-prompt '%S%M matches%s' # page it for huge list
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}  # color code completion
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s

compgen() { bash -c "compgen $*" }

compdef _precommand proxychains4
#alias proxychains4='proxychains4 -q'
autoload -U +X bashcompinit && bashcompinit
local __terraform_cmd=$(which terraform)
[ $? -eq 0 ] && complete -o nospace -C "${__terraform_cmd}" terraform

# A bug of systemd 245. Should remove this once a new version is released
# https://github.com/ohmyzsh/ohmyzsh/issues/8751
_systemctl_unit_state() {
  typeset -gA _sys_unit_state
  _sys_unit_state=( $(__systemctl list-unit-files "$PREFIX*" | awk '{print $1, $2}') )
}

# }}}

# {{{ Custom functions

c() {
  # https://github.com/ryanmjacobs/c
  local tmp=$(mktemp --dry-run)
  clang++ -g -std=c++17 -fsanitize=address -fno-omit-frame-pointer $@ -o $tmp
  $tmp
  rm $tmp
}

dadjoke() {
  curl --silent --header "Accept: text/plain" https://icanhazdadjoke.com/ && echo
}

gh() {
  local result=$(git remote get-url origin 2>/dev/null)
  if [[ $result =~ 'youngalfred' ]]; then
    GH_CONFIG_DIR=$HOME/.config/gh-youngalfred command gh "$@"
  else
    command gh "$@"
  fi
}

# aprod() {
#   export AWS_PROFILE=production
# }

# adev() {
#   export AWS_PROFILE=development
# }

bluethooth() {
  [[ -z $1 ]] && type -f bluethooth && return 1
  case $1 in
    status)
      defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState | \
        awk '{ if($1 != 0) {print "Bluetooth: ON"} else { print "Bluetooth: OFF" }  }'
              ;;
    enable)
      sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 1
      ;;
    disable)
      sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0 && sudo killall -HUP blued
      ;;
    *)
      type -f bluethooth
      ;;
  esac
}


global-socks-proxy() {
  local	usage='usage: global-socks-proxy [on|off]'
  [[ -z $1 ]] && echo $usage && return 1
  case $1 in
    on)
      sudo networksetup -setsocksfirewallproxystate Wi-Fi on
      ;;
    off)
      sudo networksetup -setsocksfirewallproxystate Wi-Fi off
      ;;
    *)
      echo $usage
      return 1
      ;;
  esac
}

docker-ip() {
  docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
}

docker-pid() {
  docker inspect --format '{{ .State.Pid }}' "$@"
}

top10() {  # most frequently used commands
  cut -d' ' -f1 ~/.zsh_history | sort | uniq -c | sort -nr | head
}

mkcd() {
  [[ -n "${1}" ]] && mkdir -p "${1}" && cd "${1}";
}

title() {
  [[ -z "$1" ]] && title=$1 || title=$(basename $SHELL)
  echo -n -e "\033]0;$title\007"
}

ptpython() {
  command ptpython $@;
  local ret=$?
  title
  return ret
}

undozip() {
  unzip -l "$1" |  awk '
  BEGIN { OFS="" ; ORS="" };

  {
    for ( i=4; i<NF; i++ )
      print $i " ";
      print $NF "\n"
  }' | xargs -I{} rm -r {}
}

taobao_ip () {
  #INTERNEL_IP=$(ifconfig en0 inet | fgrep inet | cut -d' ' -f2) 
  INTERNEL_IP=$(ipconfig getifaddr en0)
  echo INTERNEL_IP="${INTERNEL_IP}"
  EXTERNEL_IP_INFO=$(
  curl --silent\
    'http://ip.taobao.com/service/getIpInfo2.php' \
    -H 'Accept: */*' \
    -H 'Accept-Language: en-us,zh-cn;q=0.5' \
    -H 'Cache-Control: no-cache' \
    -H 'charset=UTF-8' \
    -H 'Host: ip.taobao.com' \
    -H 'Pragma: no-cache' \
    -H 'Referer: http://ip.taobao.com/ipSearch.php' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:35.0) Gecko/20100101 Firefox/35.0' \
    -H 'X-Requested-With: XMLHttpRequest' \
    --data 'ip=myip' \
    | jq .)

  EXTERNEL_IP=$(echo ${EXTERNEL_IP_INFO} | jq ' .["data"]["ip"]' | tr -d \")
  echo EXTERNEL_IP=$EXTERNEL_IP
}

myip () {
  curl https://api.myip.com 2>/dev/null| jq --raw-output .ip
}

case $OSTYPE in
  darwin*)
    dim() {
      sips $1 -g pixelWidth -g pixelHeight
    }

  md() {
    if [[ $# != 2 ]]; then
      echo "path & name required."
      return 1
    fi
    mdfind -onlyin "$1" -name "$2"
  }

  mans() {
    man "$1" | grep -iC2 --color=always "$2" | less
  }

  taobaoip() {
    curl --silent "http://ip.taobao.com/service/getIpInfo.php?ip=${1}" | jq .
  }

  wifi() {
    # TODO: add more options with zsh completion
    [[ $# -eq 0 ]] && type -f wifi && return
    case $1 in
      on)
        networksetup -setairportpower en0 on
        ;;
      off)
        networksetup -setairportpower en0 off
        ;;
      *)
        networksetup -setairportnetwork en0 $1
        ;;
    esac
  }

  fan() {
    local usage='usage: fan speed(rpm)'
    [[ -z $1 ]] && echo $usage && return 1
    local value=$(([##16]$1 * 4))
    /Applications/smcFanControl.app/Contents/Resources/smc -k F0Mn -w $value
  }

  changedns() {
    local original_dns=$(scutil --dns | tail -6 | grep 'nameserver\[[0-9]+\]' | cut -d' ' -f5 | uniq)
    sudo networksetup -setdnsservers Wi-Fi $original_dns $DEFAULT_DNS
  }

  anybar() { echo -n $1 | nc -4u -w0 localhost ${2:-1738}; }

  show_active_interface() {
    scutil --nwi | sed -n 3p
  }

  openedfiles() {
    sudo dtrace -n 'syscall::open*:entry { printf("%s %s",execname,copyinstr(arg0)); }'
  }
  ;;

  *)
    ;;
esac
# }}}

# {{{ Miscellaneous

# access online help
unalias run-help 2>/dev/null
autoload run-help
export HELPDIR=/usr/local/share/zsh/help

setopt interactivecomments
setopt AUTO_PUSHD
setopt PUSHD_SILENT
setopt PUSHD_IGNORE_DUPS
bindkey -e  # emacs style binding
bindkey '^[[Z' reverse-menu-complete
#bindkey 'ƒ'  forward-word		# OSX iTerm2 Opiton-F
#bindkey '∫'  backward-word	# OSX iTerm2 Opiton-B

# nix programs.fzf enables it already
#
# FZF CTRL-R - Paste the selected command from history into the command line
# bindkey -r '^R'  # remove default binding for history-incremental-search-backward
# fzf-history-widget() {
# local selected num
# setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
# selected=( $(fc -rl 1 |
#   FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
#   local ret=$?
#   if [ -n "$selected" ]; then
#     num=$selected[1]
#     if [ -n "$num" ]; then
#       zle vi-fetch-history -n $num
#     fi
#   fi
#   zle reset-prompt
#   return $ret
# }
# zle     -N   fzf-history-widget
# bindkey '^R' fzf-history-widget  # must be after `bindkey -e`
# bindkey '^T' transpose-chars

#
# Ctrl+X Ctrl+E
autoload edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

autoload -U url-quote-magic
zle -N self-insert url-quote-magic

# placed after zsh-syntax-highlighting
#. ~/.zsh/zsh-autosuggestions/autosuggestions.zsh
#zle-line-init() {
#	zle autosuggest-start
#}
#zle -N zle-line-init

autoload -U colors && colors

my_prompt() {
  local red_at="%{$fg[red]%}@%{$reset_color%}"
  local red_dollar="%{$fg[red]%}$%{$reset_color%}"
  local host_info
  [[ -n $SSH_CONNECTION ]] && host_info="$USER${red_at}$HOST "

  if [[ $USER == "CC" || $USER == "congee" || $USER == "cwu" ]]; then
    # number of chracters of the path of the prompt is less 30
    # use '~' to represent $HOME as long as possible
    local prefix_slash
    local pwd
    if [[ $PWD =~ $HOME ]]; then
      pwd="${PWD[@]//$HOME/~}"
    else
      pwd=$PWD
      prefix_slash=/
    fi

    local nix_logo="%{$fg[blue]%} %{$reset_color%}"
    local nix_prompt
    [[ -n $IN_NIX_SHELL ]] && nix_prompt="${nix_logo}" || nix_prompt=""

    # ugly work around
    # IFS=/ read -A pwdarr <<< "$pwd"
    local pwdarr=(${(ps:/:)pwd})

    RPROMPT="${GITSTATUS_PROMPT}"

    prompt=""
    if [[ ${#pwd[@]} -le 30 ]]; then
      prompt="${prompt}%~"
    else
      prompt="${prompt}${prefix_slash}${host_info}${pwdarr[1]}/.../${pwdarr[-1]}"
    fi
    prompt="${nix_prompt}${prompt}${red_dollar} "
  else  # other user
    prompt=${red_at}'%c % '
  fi
  echo -ne "\e[3 q"  # reset cursor to a blinking underscore
}

# $GITSTATUS_PROMPT is set by gitstatus prior to my_prompt
add-zsh-hook precmd my_prompt


case $OSTYPE in
  darwin*)
    . /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    # . /usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh
    # bindkey '^[[A' history-substring-search-up
    # bindkey '^[[B' history-substring-search-down
    ;;
  *)
    ;;
esac
# }}}

# {{{ profiling
# turn off tracing
#unsetopt xtrace
# restore stderr to the value saved in FD 3
#exec 2>&3 3>&-
# }}}

# vim: se ft=zsh fdm=marker sw=2 ts=2:
