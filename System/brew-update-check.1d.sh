#!/bin/bash

# show brew update check status: last update time
#   prompt user to update brew if outdated

# ⚠️ When first use this plugin user need to customize $PLUGIN_DIR
PLUGIN_DIR="$HOME/bitbar-plugins/derek-bitbar-plugin-folder/"
WARN_THRESHOLD_DAYS=5
ICON_DEFAULT='.'
ICON_ALERT='🍺'

BREW_BIN='/usr/local/bin/brew'
BREW_UPDATE_CHECK_FLAG="$PLUGIN_DIR/.BREW_UPDATE_CHECK_FLAG"
OUTDATED_FORMULAE_COUNT=$($BREW_BIN outdated | wc -l)

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
if [ "$1" == 'brewUpgrade' ]; then
	$BREW_BIN upgrade
	exit
fi

# Display in Menu Item
if (( ($NOW - $LAST_UPDATE) / (24*60*60) > $WARN_THRESHOLD_DAYS )); then
    echo $ICON_ALERT
	echo '---'
	echo 'Brew is out of date'
	echo "↓ Brew Update | bash='$0' param1=brewUpdate terminal=false"
else
    echo $ICON_DEFAULT
	echo '---'
	if (( ($NOW - $LAST_UPDATE) / (24*60*60) >= 1)); then
		echo "Brew updated $(( ($NOW - $LAST_UPDATE) / (24*60*60) )) days ago"
	else
		echo 'Brew updated today'
	fi
fi
if (( $OUTDATED_FORMULAE_COUNT > 0 )); then
	echo '---'
    echo "$OUTDATED_FORMULAE_COUNT Outdated formulae: "
	$BREW_BIN outdated
    echo "↑ Brew Upgrade | bash='$0' param1=brewUpgrade terminal=false"
fi
