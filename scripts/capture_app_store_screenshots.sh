#!/bin/sh

set -eu

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <simulator-udid> <app-path> <output-directory>" >&2
  exit 64
fi

device_udid=$1
app_path=$2
output_directory=$3
bundle_identifier=reactnativenerd.DocScan

mkdir -p "$output_directory"

xcrun simctl boot "$device_udid" 2>/dev/null || true
xcrun simctl bootstatus "$device_udid" -b
xcrun simctl ui "$device_udid" appearance light
xcrun simctl status_bar "$device_udid" override \
  --time 9:41 \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4

xcrun simctl uninstall "$device_udid" "$bundle_identifier" 2>/dev/null || true
xcrun simctl install "$device_udid" "$app_path"

capture() {
  file_name=$1
  shift

  xcrun simctl terminate "$device_udid" "$bundle_identifier" 2>/dev/null || true
  xcrun simctl launch "$device_udid" "$bundle_identifier" "$@" >/dev/null
  sleep 2
  xcrun simctl io "$device_udid" screenshot --type=png "$output_directory/$file_name.png"
}

capture 01-empty
capture 02-archive -seed-preview-data
capture 03-search -seed-preview-data -preview-search utility
capture 04-saved -seed-preview-data -show-saved-preview
capture 05-detail -seed-preview-data -open-preview-detail
capture 06-processing -seed-preview-data -show-processing-preview

xcrun simctl terminate "$device_udid" "$bundle_identifier" 2>/dev/null || true
xcrun simctl status_bar "$device_udid" clear

