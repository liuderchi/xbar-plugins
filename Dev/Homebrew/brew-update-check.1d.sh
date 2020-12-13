#!/bin/bash

set -e

# show brew update check status: last update time
#   prompt user to update brew if outdated

# brew outdated --cask --greedy with parsable output
# https://github.com/bgandon/brew-cask-outdated/blob/master/brew-cask-outdated.sh
brocg() {
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
      # TODO add black list for not showing (use in app upgrade, e.g. chrome canary)
      echo "$formula ($cur_vers_list) < $new_ver"
    fi
  done
}

renderRefreshButton() {
    # Refresh this plugin
    echo "♻️ Refresh | refresh=true"
}

renderDoctorButton() {
    # Render brew doctor
    echo "Brew doctor | bash=brew param1=doctor terminal=true"
}

renderGreedyModeButton() {
    # Render greedy mode status
    if [[ -f $BREW_TOGGLE_GREEDY ]]; then
        echo "Greedy Mode is On 🍏| bash=$0 param1=toggle param2=GREEDY terminal=false refresh=true"
    else
        echo "Greedy Mode is Off | bash=$0 param1=toggle param2=GREEDY terminal=false refresh=true color=gray"
    fi
}


# ⚠️ When first use this plugin user need to customize $PLUGIN_DIR
PLUGIN_DIR="$HOME/bitbar-plugins/.activated-plugins"
WARN_THRESHOLD_DAYS=5
WARN_COLOR='#fbbc05'
SIZE_LARGE='18'  # default font size 14
ICON_DEFAULT='.| size=13 color=#555555'
ICON_ALERT='🍺'

BREW_BIN='/usr/local/bin/brew'
BREW_UPDATE_CHECK_FLAG="$PLUGIN_DIR/.BREW_UPDATE_CHECK_FLAG"
BREW_TOGGLE_GREEDY="$PLUGIN_DIR/.BREW_TOGGLE_GREEDY"

OUTDATED_FORMULAE_COUNT=$($BREW_BIN outdated --formula | wc -l)
OUTDATED_CASKS_COUNT='0'

NOW=$(date '+%s')  # TIMES in UNIX TIMESTAMP
LAST_UPDATE='0'

# Handle Menu Item Action
if [ "$1" == 'brewUpdate' ]; then
    (cd $PLUGIN_DIR && \
        $BREW_BIN update && \
        touch $BREW_UPDATE_CHECK_FLAG  # create file at plugin directory
    )
    exit
fi
if [ "$1" == 'toggle' ]; then
    TOGGLE_FILE="$PLUGIN_DIR/.BREW_TOGGLE_$2"
    if [[ -f $TOGGLE_FILE ]]; then
        rm -f $TOGGLE_FILE
    else
        touch $TOGGLE_FILE
    fi
    exit
fi

# Conditionally set variable values
if [[ -f $BREW_TOGGLE_GREEDY ]]; then
    OUTDATED_CASKS_COUNT=$(brocg | wc -l)
else
    OUTDATED_CASKS_COUNT=$($BREW_BIN outdated --cask | wc -l)
fi
if [[ -f "$BREW_UPDATE_CHECK_FLAG" ]]; then
    LAST_UPDATE=$(date -r $BREW_UPDATE_CHECK_FLAG '+%s')
fi


renderAll() {
    # icon, plugin status
    if (( ($NOW - $LAST_UPDATE) / (24*60*60) > $WARN_THRESHOLD_DAYS )); then
        echo $ICON_ALERT
        echo '---'
        echo "↓ Brew Update | bash='$0' param1=brewUpdate terminal=false color=$WARN_COLOR refresh=true"
    else
        echo $ICON_DEFAULT
        echo '---'
        if (( ($NOW - $LAST_UPDATE) / (24*60*60) >= 1)); then
            echo "Brew updated $(( ($NOW - $LAST_UPDATE) / (24*60*60) )) day(s) ago"
        else
            echo 'Brew updated today'
        fi
    fi

    # show outdated
    if (( $OUTDATED_FORMULAE_COUNT > 0 )); then
        echo '---'
        echo "$OUTDATED_FORMULAE_COUNT Outdated Formula(s): | color=gray"
        $BREW_BIN outdated --formula \
            | while read line; do echo "$line | color=gray"; done
        echo "↑ Brew Upgrade | bash=brew param1=upgrade terminal=true color=$WARN_COLOR"
    fi
    if (( $OUTDATED_CASKS_COUNT > 0 )); then
        echo '---'
        echo "$OUTDATED_CASKS_COUNT Outdated Cask(s): | color=gray"

        if [[ -f $BREW_TOGGLE_GREEDY ]]; then
            # parsing `$BREW_BIN outdated --cask --greedy` has UNEXPECTED result
            brocg | awk '$0="∙ "$1" ↑ "$4" | bash=brew param1=cask param2=reinstall param3="$1" length=40 terminal=true color=gray"'
        else
            $BREW_BIN outdated --cask \
                | awk '{out="∙ "$1" | bash=brew param1=cask param2=reinstall param3="$1" terminal=true color=gray"; print out;}'
                # c.f. https://github.com/bgandon/brew-cask-outdated/blob/master/brew-cask-outdated.sh
            echo "↑ Upgrade All Casks | bash=brew param1=cask param2=upgrade terminal=true color=$WARN_COLOR"
        fi
    fi

    echo '---'
    renderRefreshButton
    echo '---'
    renderDoctorButton
    renderGreedyModeButton

}

renderAll
