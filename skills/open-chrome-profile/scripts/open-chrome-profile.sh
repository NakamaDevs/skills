#!/bin/sh
# Open a URL in a specific Google Chrome profile on macOS.
# Usage: open-chrome-profile.sh <profile-email | profile-directory> <url>
#   open-chrome-profile.sh user@example.com "https://example.com/"
#   open-chrome-profile.sh "Profile 1" "https://example.com/"
set -eu

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <profile-email | profile-directory> <url>" >&2
  exit 2
fi

profile=$1
url=$2
app=${CHROME_APP:-Google Chrome}

case $profile in
  *@*) flag="--profile-email=$profile" ;;
  *) flag="--profile-directory=$profile" ;;
esac

# -n is required: without it, macOS drops --args when Chrome is already running.
exec open -na "$app" --args "$flag" "$url"
