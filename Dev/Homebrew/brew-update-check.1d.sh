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
        $BREW_BIN cask outdated \
            | awk '{out="^ "$1" | bash=brew param1=cask param2=reinstall param3="$1" terminal=true color=gray"; print out;}'
            # c.f. https://github.com/bgandon/brew-cask-outdated/blob/master/brew-cask-outdated.sh
        echo "↑ Brew Cask Upgrade | bash=brew param1=cask param2=upgrade terminal=true color=$WARN_COLOR"
    fi
}

render
