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
# zmodload zsh/zprof
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
export GOPATH=$HOME/.go
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
  export EDITOR=nvim
  stty -ixon  # for some vim mappings (ctrl-s) to wrok

  PATH=$(zsh -fc "typeset -TU P=$PATH p; echo \$P")
  export PATH=$PATH:$(xcode-select -p)/usr/bin
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # TODO: split this .zshrc into multiple ones by platform
  [ -f $HOME/.zshrc.mac ] && source $HOME/.zshrc.mac

elif [[ $OSTYPE =~ 'linux*' ]]; then
  export EDITOR=nvim

  export PATH=$HOME/.cabal/bin:$PATH:$HOME/.yarn/bin

  autoload bashcompinit && bashcompinit
  local aws_comp=$(whence aws_completer)
  [ -f $aws_comp ] && complete -C $aws_comp aws

  export AWS_VAULT_BACKEND=pass
  alias vault=aws-vault

  alias patchld="cat $NIX_CC/nix-support/dynamic-linker"
  # nix build --impure --expr 'with import (builtins.getFlake "nixpkgs") { }; callPackage ./default.nix { inherit (pkgs) Security; }'

  [ -f $HOME/.zshrc.linux ] && source $HOME/.zshrc.linux
fi

typeset -U fpath
fpath=(
  ~/.local/share/zsh/site-functions  # volatile
  $fpath  # placed at last to be overridden
)
autoload -Uz $fpath[1]/*

typeset -U module_path
module_path=($module_path)
# }}}

# {{{ History
export HISTCONTROL=ignorespace
export SAVEHIST=65536
export HISTSIZE=$SAVEHIST
export HISTFILE=$HOME/.zsh_history
setopt hist_reduce_blanks
setopt hist_ignore_all_dups
setopt hist_ignore_space
# setopt extended_history
setopt share_history
setopt inc_append_history
# }}}

# alias {{{
alias cp='cp -i'
alias ll='ls -l'
alias mv='mv -i'
alias vi=nvim
alias k=kubectl
alias sudo='sudo '
alias mux=tmuxinator
alias tree='tree -C'
alias less='less -R'
alias more='more -R'
alias gdb="gdb --silent"
alias curl='noglob curl'
alias pip3='noglob python3 -m pip'
alias youtube-dl='noglob youtube-dl'
alias p4="ping $DEFAULT_DNS"
alias man='LANG=en_US.UTF-8 man'
alias fuck='$(thefuck $(fc -ln -1))'
alias bc="bc --mathlib --quiet --warn"
alias ipython='ipython --profile=common'
alias hp='http_proxy=http://127.0.0.1:8123'
alias pyinstrument='python3 -m pyinstrument'
alias pylab='ipython --profile=common --pylab'
alias highlight='highlight --out-format=xterm256 --style=molokai --tab=2'
alias urlquote='python -c "import urllib, sys; print(urllib.quote(sys.argv[1]))"'
alias urlunquote='python -c "import urllib, sys; print(urllib.unquote(sys.argv[1]))"'

case $OSTYPE in
  darwin*)
    alias t=trash
    alias ls='ls --color=auto'
    alias eject='diskutil eject'
    alias grep='grep --color=auto'
    alias egrep='egrep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias htop='TERM=xterm-256color htop'
    alias mp='mdfind -onlyin . -name '
    alias js='osascript -l JavaScript'
    alias tempmonitor='tempmonitor -c -a -l'
    alias lsusb='system_profiler SPUSBDataType'
    alias shuf="perl -MList::Util=shuffle -e 'print shuffle <>'"
    alias smc=/Applications/smcFanControl.app/Contents/Resources/smc
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

cheat() {
  curl cheat.sh/"$1"
}

dadjoke() {
  curl --silent --header "Accept: text/plain" https://icanhazdadjoke.com/ && echo
}

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

fzf-store() {
  fd . /nix/store --max-depth=1 --min-depth=1 --type=directory | \
    fzf -m --preview-window right:50% --preview 'nix-store -q --tree {}'
}

upflake() {
  local url="https://monitoring.nixos.org/prometheus/api/v1/query?query=channel_revision" 
  local args='.data.result[] | select(.metric.channel=="nixos-unstable") | .metric.revision'
  local new=$(curl -sL ${url} | jq -r "${args}")
  local old=$(jq -r ".nodes.nixpkgs.locked.rev" flake.lock)

  sed -i s/$old/$new/ flake.lock
  echo "$old -> $new"
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

myip () {
  local ua='User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:106.0) Gecko/20100101 Firefox/106.0'
  curl https://api.myip.com -H "${ua}" 2>/dev/null | jq --raw-output .ip
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

  openedfiles() {
    sudo dtrace -n 'syscall::open*:entry { printf("%s %s",execname,copyinstr(arg0)); }'
  }
  ;;

  linux*)
    wifi-password() {
      sudo nmcli device wifi show-password | awk '$1 == "Password:" {print $2}'
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

setopt interactivecomments
setopt AUTO_PUSHD
setopt PUSHD_SILENT
setopt PUSHD_IGNORE_DUPS
bindkey -e  # emacs style binding
bindkey '^[[Z' reverse-menu-complete
# bindkey '^T' transpose-chars

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
    local nix_logo="%{$fg[blue]%} %{$reset_color%}"
    local nix_prompt
    [[ -n $IN_NIX_SHELL ]] && nix_prompt="${nix_logo}" || nix_prompt=""

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

    # ugly work around
    # IFS=/ read -A pwdarr <<< "$pwd"
    local pwdarr=(${(ps:/:)pwd})
    local dir
    if [[ ${#pwdarr[@]} -le 2 ]]; then
        dir="$pwd"
    else
        dir="${prefix_slash}${pwdarr[1]}/.../${pwdarr[-1]}"
    fi

    prompt=""
    if [[ ${#pwd[@]} -gt 30 ]]; then
      prompt="${prompt}%~"
    else
      prompt="${prompt}${dir}"
    fi
    prompt="${host_info}${nix_prompt}${prompt}${red_dollar} "
  else  # other user
    prompt=${red_at}'%c % '
  fi
  echo -ne "\e[3 q"  # reset cursor to a blinking underscore
}

# Sets GITSTATUS_PROMPT to reflect the state of the current git repository. Empty if not
# in a git repository. In addition, sets GITSTATUS_PROMPT_LEN to the number of columns
# $GITSTATUS_PROMPT will occupy when printed.
#
# Example:
#
#   GITSTATUS_PROMPT='master ⇣42⇡42 ⇠42⇢42 *42 merge ~42 +42 !42 ?42'
#   GITSTATUS_PROMPT_LEN=39
#
#   master  current branch
#      ⇣42  local branch is 42 commits behind the remote
#      ⇡42  local branch is 42 commits ahead of the remote
#      ⇠42  local branch is 42 commits behind the push remote
#      ⇢42  local branch is 42 commits ahead of the push remote
#      *42  42 stashes
#    merge  merge in progress
#      ~42  42 merge conflicts
#      +42  42 staged changes
#      !42  42 unstaged changes
#      ?42  42 untracked files
function _gitstatus_async_callback() {
  # Override the synchronous gitstatus_prompt_update (from nix-managed
  # gitstatus.prompt.zsh) with an async version. The callback fires via
  # zle -F when gitstatusd responds, then redraws the prompt.
  emulate -L zsh
  typeset -g  GITSTATUS_PROMPT=''
  typeset -gi GITSTATUS_PROMPT_LEN=0

  [[ $VCS_STATUS_RESULT == ok-async ]] || {
    zle && zle reset-prompt
    return
  }

  local      clean='%76F'   # green foreground
  local   modified='%178F'  # yellow foreground
  local  untracked='%39F'   # blue foreground
  local conflicted='%196F'  # red foreground
  local p

  local where  # branch name, tag or commit
  if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
    where=$VCS_STATUS_LOCAL_BRANCH
  elif [[ -n $VCS_STATUS_TAG ]]; then
    p+='%f#'
    where=$VCS_STATUS_TAG
  else
    p+='%f@'
    where=${VCS_STATUS_COMMIT[1,8]}
  fi

  (( $#where > 32 )) && where[13,-13]="…"  # truncate long branch names and tags
  p+="${clean}${where//\%/%%}"             # escape %

  # ⇣42 if behind the remote.
  (( VCS_STATUS_COMMITS_BEHIND )) && p+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
  # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
  (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && p+=" "
  (( VCS_STATUS_COMMITS_AHEAD  )) && p+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
  # ⇠42 if behind the push remote.
  (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
  (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" "
  # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
  (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && p+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
  # *42 if have stashes.
  (( VCS_STATUS_STASHES        )) && p+=" ${clean}*${VCS_STATUS_STASHES}"
  # 'merge' if the repo is in an unusual state.
  [[ -n $VCS_STATUS_ACTION     ]] && p+=" ${conflicted}${VCS_STATUS_ACTION}"
  # ~42 if have merge conflicts.
  (( VCS_STATUS_NUM_CONFLICTED )) && p+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
  # +42 if have staged changes.
  (( VCS_STATUS_NUM_STAGED     )) && p+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
  # !42 if have unstaged changes.
  (( VCS_STATUS_NUM_UNSTAGED   )) && p+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
  # ?42 if have untracked files. It's really a question mark, your font isn't broken.
  (( VCS_STATUS_NUM_UNTRACKED  )) && p+=" ${untracked}?${VCS_STATUS_NUM_UNTRACKED}"

  GITSTATUS_PROMPT="${p}%f"
  # The length of GITSTATUS_PROMPT after removing %f and %F.
  GITSTATUS_PROMPT_LEN="${(m)#${${GITSTATUS_PROMPT//\%\%/x}//\%(f|<->F)}}"

  zle && zle reset-prompt
}

# Replaces the synchronous gitstatus_prompt_update registered by gitstatus.prompt.zsh
function gitstatus_prompt_update() {
  emulate -L zsh
  gitstatus_query -t 0 -c _gitstatus_async_callback 'MY' || {
    typeset -g  GITSTATUS_PROMPT=''
    typeset -gi GITSTATUS_PROMPT_LEN=0
  }
}

# RPROMPT uses prompt_subst (set by gitstatus.prompt.zsh) to re-evaluate
# on each render, picking up async updates via zle reset-prompt.
RPROMPT='${GITSTATUS_PROMPT}'

add-zsh-hook precmd my_prompt

# {{{ profiling
# zprof
# turn off tracing
#unsetopt xtrace
# restore stderr to the value saved in FD 3
#exec 2>&3 3>&-
# }}}

# vim: se ft=zsh fdm=marker sw=2 ts=2:
