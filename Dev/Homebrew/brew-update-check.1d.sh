#!/bin/bash

set -Eeo pipefail  # do not set -u to avoid unbound var

# show brew update check status: last update time
#   prompt user to update brew if outdated

renderDoctorButton() {
    # Render brew doctor
    echo "Brew doctor | bash=$0 param1=openTerminal param2='brew doctor' terminal=false"
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
PLUGIN_DIR="$HOME/Library/Application Support/xbar/plugins"
WARN_THRESHOLD_DAYS=5
WARN_COLOR='#fbbc05'
ICON_DEFAULT='.| color=gray'
ICON_ALERT='🍺| size=12'  # default font size 13

BREW_BIN='/usr/local/bin/brew'
BREW_UPDATE_CHECK_FLAG="$PLUGIN_DIR/.BREW_UPDATE_CHECK_FLAG"
BREW_TOGGLE_GREEDY="$PLUGIN_DIR/.BREW_TOGGLE_GREEDY"

OUTDATED_FORMULAE_COUNT=$($BREW_BIN outdated --formula | wc -l)
OUTDATED_CASKS_COUNT='0'

NOW=$(date '+%s')  # TIMES in UNIX TIMESTAMP
LAST_UPDATE='0'

# Handle Menu Item Action
if [ "$1" == 'openTerminal' ]; then
  cmd=$2
  if [ "$(osascript -e 'application "Terminal" is running')" = "false" ]; then
    osascript -e 'tell application "Terminal" to activate'
  else
    osascript -e 'tell application "System Events" to tell process "Terminal" to set frontmost to true'
    osascript -e 'tell application "System Events" to keystroke "t" using command down'
  fi
  osascript -e "tell application \"Terminal\" to do script \"$cmd\" in window 1"
fi
if [ "$1" == 'brewUpdate' ]; then
    (cd "$PLUGIN_DIR" && \
        "$BREW_BIN" update && \
        touch "$BREW_UPDATE_CHECK_FLAG"  # create file at plugin directory
    )
    exit
fi
if [ "$1" == 'toggle' ]; then
    TOGGLE_FILE="$PLUGIN_DIR/.BREW_TOGGLE_$2"
    if [[ -f $TOGGLE_FILE ]]; then
        rm -f "$TOGGLE_FILE"
    else
        touch "$TOGGLE_FILE"
    fi
    exit
fi

# Conditionally set variable values
if [[ -f $BREW_TOGGLE_GREEDY ]]; then
    OUTDATED_CASKS_COUNT=$($BREW_BIN outdated --cask --greedy | wc -l)
else
    OUTDATED_CASKS_COUNT=$($BREW_BIN outdated --cask | wc -l)
fi
if [[ -f "$BREW_UPDATE_CHECK_FLAG" ]]; then
    LAST_UPDATE=$(date -r "$BREW_UPDATE_CHECK_FLAG" '+%s')
fi


renderAll() {
    # icon, plugin status
    if (( ("$NOW" - "$LAST_UPDATE") / (24*60*60) > "$WARN_THRESHOLD_DAYS" )); then
        echo "$ICON_ALERT"
        echo '---'
        echo "↓ Brew update | bash=$0 param1=brewUpdate terminal=false color=$WARN_COLOR refresh=true"
    else
        brewUpdateAction="| bash=$0 param1=openTerminal param2='brew update' terminal=false color=gray"
        echo "$ICON_DEFAULT"
        echo '---'
        if (( ("$NOW" - "$LAST_UPDATE") / (24*60*60) >= 1)); then
            echo "Brew updated $(( (NOW - LAST_UPDATE) / (24*60*60) )) day(s) ago $brewUpdateAction"
        else
            echo "Brew updated today $brewUpdateAction"
        fi
    fi

    # show outdated
    if (( "$OUTDATED_FORMULAE_COUNT" > 0 )); then
        echo '---'
        echo "$OUTDATED_FORMULAE_COUNT Outdated Formula(s): | color=gray"
        $BREW_BIN outdated --formula \
            | while read -r formula; \
            do
                echo "∙ $formula | bash=$0 param1=openTerminal param2='brew upgrade --formula $formula' terminal=false color=gray"
            done
        echo "↑ Brew Upgrade | bash=$0 param1=openTerminal param2='brew upgrade --formula' terminal=false color=$WARN_COLOR"
    fi
    if (( "$OUTDATED_CASKS_COUNT" > 0 )); then
        echo '---'
        echo "$OUTDATED_CASKS_COUNT Outdated Cask(s): | color=gray"

        if [[ -f $BREW_TOGGLE_GREEDY ]]; then
            $BREW_BIN outdated --cask --greedy \
                | while read -r cask; \
                do
                    nextVersion=$(echo "$cask" | xargs $BREW_BIN info --cask | head -n 1 | cut -d' ' -f 2)
                    echo "∙ $cask ↑ $nextVersion | bash=$0 param1=openTerminal param2='brew reinstall --cask $cask' terminal=false color=gray"
                done
        else
            $BREW_BIN outdated --cask \
                | awk "\$0=\"∙ \"\$1\" ↑ | bash=$0 param1=openTerminal param2='brew reinstall --cask \"\$1\"' terminal=false color=gray\""
                # c.f. https://github.com/bgandon/brew-cask-outdated/blob/master/brew-cask-outdated.sh
            echo "↑ Upgrade All Casks | bash=$0 param1=openTerminal param2='brew upgrade --cask' terminal=false color=$WARN_COLOR"
        fi
    fi

    echo '---'
    renderDoctorButton
    renderGreedyModeButton

}

renderAll
