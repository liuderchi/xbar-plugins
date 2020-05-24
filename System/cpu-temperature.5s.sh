#!/bin/bash
# <bitbar.title>CPU Temperature</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Eric Ripa</bitbar.author>
# <bitbar.author.github>eripa</bitbar.author.github>
# <bitbar.desc>This plugin displays the current CPU temperature (requires external 'smc' binary)</bitbar.desc>
# <bitbar.dependencies>smc</bitbar.dependencies>
#
# 'smc' can be downloaded from: http://www.eidac.de/smcfancontrol/smcfancontrol_2_4.zip
# One-liner:
# curl -LO http://www.eidac.de/smcfancontrol/smcfancontrol_2_4.zip && unzip -d temp_dir_smc smcfancontrol_2_4.zip && cp temp_dir_smc/smcFanControl.app/Contents/Resources/smc /usr/local/bin/smc ; rm -rf temp_dir_smc smcfancontrol_2_4.zip

PLUGIN_DIR="$HOME/bitbar-plugins/.activated-plugins"
# linked from smcFanControl
# ln -s /Applications/smcFanControl.app/Contents/Resources/smc .activated-plugins/.bin/smc
SMC_BIN="$PLUGIN_DIR/.bin/smc"

if [[ ! -f "$SMC_BIN" ]]; then
  echo "⚠️"
  echo "Smc binary is not found in $SMC_BIN"
  return
fi

COLOR='#555555'
FAHRENHEIT=false
TEMPERATURE_WARNING_LIMIT=70
TEMPERATURE=$($SMC_BIN -k TC0P -r | sed 's/.*bytes \(.*\))/\1/' |sed 's/\([0-9a-fA-F]*\)/0x\1/g' | perl -ne 'chomp; ($low,$high) = split(/ /); print (((hex($low)*256)+hex($high))/4/64); print "\n";')
TEMP_INTEGER=${TEMPERATURE%.*}

if $FAHRENHEIT ; then
  TEMP_INTEGER=$((TEMP_INTEGER*9/5+32))
  LABEL="°f"
else
  LABEL="°c"
fi

if [ "$TEMP_INTEGER" -gt "$TEMPERATURE_WARNING_LIMIT" ] ; then
  COLOR="#ff9f0a"
fi

echo "$ICON${TEMP_INTEGER} $LABEL| size=13 color=$COLOR"
