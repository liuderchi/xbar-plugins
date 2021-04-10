#!/bin/bash

set -Eeuo pipefail

PLUGIN_DIR="$HOME/bitbar-plugins"
ACTIVATED_PLUGIN="$PLUGIN_DIR/.activated-plugins"
DISABLED_PLUGIN="$ACTIVATED_PLUGIN/.disabled-plugins"

mkdir -p $ACTIVATED_PLUGIN
mkdir -p $DISABLED_PLUGIN


# enable a plugin
# ln -s path/to/plugin-script.sh $ACTIVATED_PLUGIN

# disable an enabled plugin
# mv $ACTIVATED_PLUGIN/my-plugin.sh $DISABLED_PLUGIN
