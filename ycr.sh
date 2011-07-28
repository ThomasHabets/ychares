#!/bin/sh
#
# ycr.sh version see-ychares-for-version
#
# Author: Thomas Habets <habets@google.com>
#
# Script that will take the yubikey challenge from the clipboard, send
# it off to the yubikey and send the reply back to the user as if they
# typed it.
#
# Basically it's this command, but accounting for error handling and
# the fact that there's two clipboards in X:
#     clipsniff | ychares | x11type
#
# Example use would be SSH login where a PAM module on the server
# presents the challenge in text. The user would then select that text
# and press a shortcut button that spawns this script.
#
# There is a "bug" in this method though. If both the 'primary' and
# the 'clipboard' contains even number of hex characters (i.e. a valid
# challenge) then since the 'primary' will complete a valid
# challenge-response (even though it's not the one the user intended)
# it will not continue with the 'clipboard'. There is no way to avoid
# this that I can see except "make sure you put the challenge in the
# 'primary'". This means "just select the text and it'll be fine".
#
# This script depends on clipsniff, x11type and ychares being in the
# PATH.
#
# http://github.com/ThomasHabets/clipsniff
# http://github.com/ThomasHabets/x11type
# http://github.com/ThomasHabets/ychares
# (ychares is the same package this script is in)
#
# ------------------------------
# Copyright 2011 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------


fail() {
    xmessage "$1"
    exit 1
}

ychares --help > /dev/null 2>/dev/null || {
    fail "Unable to execute ychares"
}

for clip in primary clipboard; do
    REPLY=$(clipsniff -r $clip | ychares --challenge 2>/dev/null)
    STATUS="$?"

    # ychares could not talk to the yubikey at all
    if [ $STATUS = 2 ]; then
        fail "ychares was unable to communicate with YubiKey. \
Try running ychares from the command line for details."
    fi

    # Did the challenge-response succeed? If so don't continue.
    if [ $STATUS = 0 ]; then
        echo "$REPLY\n" | x11type
        exit 0
    fi
done

fail "No data in any clipboard managed to get a successful reply. \
Are you sure you selected the challenge?"
