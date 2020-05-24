#!/bin/bash

# forked from real-cpu-usage.10s.sh

# <bitbar.title>Real CPU Usage</bitbar.title>
# <bitbar.author>Mat Ryer and Tyler Bunnell</bitbar.author>
# <bitbar.author.github>matryer</bitbar.author.github>
# <bitbar.desc>Calcualtes and displays real CPU usage stats.</bitbar.desc>
# <bitbar.version>1.0</bitbar.version>

if [ "$1" == "activitymonitor" ]; then
	open -a "Activity Monitor"
	exit
fi

COLOR='#555555'
THRESHOLD=50
IDLE=$(top -F -R -l3 | grep "CPU usage" | tail -1 | egrep -o '[0-9]{0,3}\.[0-9]{0,2}% idle' | sed 's/% idle//')

USED=$(echo 100 - "$IDLE" | bc | xargs printf "%.f\n")
pad='   '

# padding space when 2 or 1 digits
if [ ${#USED} == 2 ] || [ ${#USED} == 1 ]; then
	printf '%*.*s' 0 $((2 - ${#USED})) "$pad"
fi

if [ "$USED" -gt "$THRESHOLD" ] ; then
  COLOR="#ff9f0a"
fi

echo "$USED %| size=13 color=$COLOR"

echo "---"
echo "Open Activity Monitor| bash='$0' param1=activitymonitor terminal=false"
