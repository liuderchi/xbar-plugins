#!/bin/bash

# show brew update check status: last update time
#   prompt user to update brew if outdated

# ⚠️ When first use this plugin user need to customize $PLUGIN_DIR
PLUGIN_DIR="$HOME/bitbar-plugins/.activated-plugins/"
WARN_THRESHOLD_DAYS=5
WARN_COLOR='#fbbc05'
SIZE_LARGE='18'  # default font size 14
ICON_DEFAULT='.'
ICON_ALERT='🍺'

BREW_BIN='/usr/local/bin/brew'
BREW_UPDATE_CHECK_FLAG="$PLUGIN_DIR/.BREW_UPDATE_CHECK_FLAG"

OUTDATED_FORMULAE_COUNT=$($BREW_BIN outdated | wc -l)
OUTDATED_CASKS_COUNT=$($BREW_BIN cask outdated | wc -l)

NOW=$(date '+%s')  # TIMES in UNIX TIMESTAMP
LAST_UPDATE='0'
if [[ -f "$BREW_UPDATE_CHECK_FLAG" ]]; then
    LAST_UPDATE=$(date -r $BREW_UPDATE_CHECK_FLAG '+%s')
fi


# Handle Menu Item Action
if [ "$1" == 'brewUpdate' ]; then
    (cd $PLUGIN_DIR && \
        $BREW_BIN update && \
        touch $BREW_UPDATE_CHECK_FLAG  # create file at plugin directory
    )
    exit
fi

# brew cask outdated --greedy with parsable output
# https://github.com/bgandon/brew-cask-outdated/blob/master/brew-cask-outdated.sh
brcog() {
  # Resolve the CASKROOM value, supporting its customization
  # with the HOMEBREW_CASK_OPTS environment variable
  local CASKROOM=/opt/homebrew-cask/Caskroom
  if [ -n "$HOMEBREW_CASK_OPTS" ]; then
    opts=($HOMEBREW_CASK_OPTS)
    for opt in "${opts[@]}"; do
      room=$(echo "$opt" | sed -ne 's/^--caskroom=//p')
      if [ -n "$room" ]; then
        CASKROOM=$room
        break
      fi
    done
  fi

  for formula in $($BREW_BIN cask list | grep -Fv '(!)'); do
    info=$($BREW_BIN cask info $formula | sed -ne '1,/^From:/p')
    new_ver=$(echo "$info" | head -n 1 | cut -d' ' -f 2)
    cur_vers=$(echo "$info" \
    | grep '^/usr/local/Caskroom' \
    | cut -d' ' -f 1 \
    | cut -d/ -f 6)
    latest_cur_ver=$(echo "$cur_vers" \
    | tail -n 1)
    cur_vers_list=$(echo "$cur_vers" \
    | tr '\n' ' ' | sed -e 's/ /, /g; s/, $//')
    if [ "$new_ver" != "$latest_cur_ver" ]; then
      echo "$formula ($cur_vers_list) < $new_ver"
    fi
  done
}


render() {
    # icon, plugin status
    if (( ($NOW - $LAST_UPDATE) / (24*60*60) > $WARN_THRESHOLD_DAYS )); then
        echo $ICON_ALERT
        echo '---'
        echo "↓ Brew Update | bash='$0' param1=brewUpdate terminal=false color=$WARN_COLOR"
    else
        echo $ICON_DEFAULT
        echo '---'
        if (( ($NOW - $LAST_UPDATE) / (24*60*60) >= 1)); then
            echo "Brew updated $(( ($NOW - $LAST_UPDATE) / (24*60*60) )) days ago"
        else
            echo '✅ Brew updated today'
        fi
    fi

    # show outdated
    if (( $OUTDATED_FORMULAE_COUNT > 0 )); then
        echo '---'
        echo "$OUTDATED_FORMULAE_COUNT Outdated Formula(s): | color=gray"
        $BREW_BIN outdated \
            | while read line; do echo "$line | color=gray"; done
        echo "↑ Brew Upgrade | bash=brew param1=upgrade color=$WARN_COLOR"
    fi
    if (( $OUTDATED_CASKS_COUNT > 0 )); then
        echo '---'
        echo "$OUTDATED_CASKS_COUNT Outdated Cask(s): | color=gray"
        # parsing `$BREW_BIN cask outdated --greedy` has UNEXPECTED result
        brcog | awk '$0="∙ "$1" ↑ "$4" | bash=brew param1=cask param2=reinstall param3="$1" length=40 terminal=true color=gray"'
        echo "↑ Upgrade All Casks | bash=brew param1=cask param2=upgrade terminal=true color=$WARN_COLOR"
    fi
}

render
