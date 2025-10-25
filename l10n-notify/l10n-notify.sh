#!/usr/bin/env bash

# WARNING:
# This script is designed to be executed only when deploying the site using GitHub Actions
# and normally should NOT be executed locally, i.e. on your system.

# This script will perform modifications on the markdown files
# to implement translation outdated notice.

# See more at
# https://github.com/end-4/dots-hyprland-wiki/issues/3

set -e

# Use gojq if possible; else use jq
jq=gojq
which gojq||jq=jq

script_dir=$(dirname $(readlink -f "$0"))
base=$(dirname "$script_dir")/src/content/docs
json_file=$(dirname "$script_dir")/l10n-notify/l10n-notify.json

# ori: Original
# trl: Translated
ori_locale=en
ori_locale_name=English

echo "================================"
echo "================================ STEP 1: Path detection and transforming"
echo "================================"

ori_md_files=()
while IFS= read -r -d $'\0' file; do
    relative_path="${file#./}"
    ori_md_files+=("$relative_path")
done < <(find ./src/content/docs/$ori_locale/ -type f \( -name "*.md" -o -name "*.mdx" \) -print0)

abs_paths=()
for path in "${ori_md_files[@]}";do
  # Transform relative path to absolute path
  abs_path=$(readlink -f "$path") || { echo "[$0]: Failed to get the absolute path of file \"$path\". Aborting..." ; exit 1 ; }
  # Test $abs_path existence
  test -f $abs_path || { echo "[$0]: The file \"$abs_path\" does not exists or is a directory. Aborting..." ; exit 1 ; }
  # Determine if $abs_path is a index.mdx
  echo $abs_path|grep -q "$base/$ori_locale/index.mdx" && { echo "[$0]: The file \"$abs_path\" seems to be index.mdx. Skipping..." ; continue ; }
  # Determine if $abs_path is a Dev Note
  echo $abs_path|grep -q "$base/$ori_locale/dev/" && { echo "[$0]: The file \"$abs_path\" seems to be a Dev Note. Skipping..." ; continue ; }
  # Determine if $abs_path is a doc in $ori_locale_name
  echo $abs_path|grep -q "$base/$ori_locale/" || { echo "[$0]: The file \"$abs_path\" seems not to be a doc in $ori_locale_name. Aborting..." ; exit 1 ; }
  # save path to array $abs_paths
  abs_paths+=("$abs_path")
done

echo "--------------------------------"
echo "-------------------------------- Result of STEP 1"
echo "--------------------------------"
echo "[$0]: Every file path has been transformed into absolute path. Here they are:"
for path in "${abs_paths[@]}";do
  echo "    $path"
done

echo "================================"
echo "================================ STEP 2: Parsing json"
echo "================================"
# Read keys (locale)
while read -r string; do
  # Save to array $locale
  locale+=("$string")
done < <($jq -r 'keys[]' $json_file)

# Find value (notif) corresponding to the key (locale)
notif=()
for key in "${locale[@]}"; do
  echo $key
  value=$($jq -r ".\"$key\"" $json_file)
  # Save to array $notif
  notif+=("$value")
done

echo "--------------------------------"
echo "-------------------------------- Result of STEP 2"
echo "--------------------------------"
echo "[$0]: json parsed, notifications for different locales have been loaded. Here they are:"
for ((i=0; i<${#locale[@]}; i++)); do
  echo "-- Entry $i: "
  echo "--   ├─locale = \"${locale[i]}\""
  echo "--   ├─notif  = \"${notif[i]}\""
  echo "--   └─root   = \"$base/${locale[i]}\""
done

echo "================================"
echo "================================ STEP 3: Processing translation file"
echo "================================"
h="       │   └─"
h2="       │   ├─"
# For every element in array $locale
for ((i=0; i<${#locale[@]}; i++)); do
echo "--------------------------"
echo "-- Now processing: "
echo "--   ├─locale = \"${locale[i]}\""
echo "--   ├─notif  = \"${notif[i]}\""
echo "--   └─root   = \"$base/${locale[i]}\""
  # Skipping original language
  if [ "${locale[i]}" = "$ori_locale" ]; then echo "   Translation directory \"$base/${locale[i]}\" is of ${ori_locale_name}, skipping..."; continue ; fi
  # Skipping none-existence translation directory
  test -d "$base/${locale[i]}" || { echo "   Translation directory \"$base/${locale[i]}\" does not exists, skipping..."; continue ; }

  # For every element in array $abs_paths
  for ori_path in "${abs_paths[@]}";do
    # Get ori_lastUpdated
    ori_frontmatter=$(sed -n '/^---$/,/^---$/p' "$ori_path")
    ori_lastUpdated=$(awk '/^lastUpdated:/ {print $2}' <<< "$ori_frontmatter")
    ori_lastUpdated_norm=$(awk '/^lastUpdated:/ {gsub(/[^0-9]/,"",$2); print $2}' <<< "$ori_frontmatter")
    if [[ ! "$ori_lastUpdated_norm" =~ ^[0-9]{8}$ ]]; then
      echo "Error: \"$ori_path\" has a weird lastUpdated value: $ori_lastUpdated" >&2 ;exit 1
    fi
    # Transform from original path to translated path (trl_path)
    trl_path="$base/${locale[i]}/"$(realpath --relative-to="$base/$ori_locale/" "$ori_path")
    echo "++     ├─file = \"$trl_path\""
    # Skipping non-existent $trl_path
    test -f $trl_path || { echo "${h}loc file not exists. Skipping..." ; continue ; }
    # Get trl_lastUpdated
    trl_frontmatter=$(sed -n '/^---$/,/^---$/p' "$trl_path")
    trl_lastUpdated=$(awk '/^lastUpdated:/ {print $2}' <<< "$trl_frontmatter")
    trl_lastUpdated_norm=$(awk '/^lastUpdated:/ {gsub(/[^0-9]/,"",$2); print $2}' <<< "$trl_frontmatter")
    if [[ ! "$trl_lastUpdated_norm" =~ ^[0-9]{8}$ ]]; then
      echo "Error: \"$trl_path\" has a weird lastUpdated value: $trl_lastUpdated" >&2 ;exit 1
    fi
    # If trl_lastUpdated less than ori_lastUpdated, it's outdated.
    echo "${h2}ori_lastUpdated: $ori_lastUpdated"
    echo "${h2}trl_lastUpdated: $trl_lastUpdated"
    [ $trl_lastUpdated_norm -lt $ori_lastUpdated_norm ] || { echo "${h}Outdated: False. Skipping..." ; continue ; }
    echo "${h2}Outdated: True"
    notif_final=${notif[i]}
    notif_final=${notif_final/LASTUPDATED_OF_ORIGINAL/$ori_lastUpdated}
    notif_final=${notif_final/LASTUPDATED_OF_TRANSLATED/$trl_lastUpdated}
    echo "${h2}notif_final: ${notif_final}"
    # Match unique marks
    line_beg=$(awk '/^:::danger\[l10n-notify\]$/{print NR;exit}' $trl_path)
    line_end=$(awk '/^:::$/{print NR;exit}' $trl_path)

    # If unique mark not found
    if [ -z "$line_beg" ]; then
      echo "${h2}Mark string not found."
      # Then find the frontmatter, which both starts and ends with "---"
      fr_end=$(awk '/^---$/{count++; if(count==2) {print NR; exit}}' "$trl_path")
      if [ -z "$fr_end" ]; then
        echo "${h}Frontmatter not found or not ended. Aborting...";exit 1
      else
        echo "${h}Frontmatter end at $fr_end ."
      # And create the danger aside right after the frontmatter, which ends with "---"
        sed -i "$((fr_end+1))i:::" "$trl_path"
        sed -i "$((fr_end+1))i${notif_final}" "$trl_path"
        sed -i "$((fr_end+1))i:::danger[l10n-notify]" "$trl_path"
      fi

    # If unique mark found, but it has no end (weird...), then abort
    elif [ -z "$line_end" ]; then
      echo "${h}Mark string found at line $line_beg, but the aside has no end, something must be wrong. Aborting..."; exit 1
    # If unique mark found, and this aside contains nothing,
    elif [ $line_end -eq $(($line_beg+1)) ]; then
      echo "${h}Mark string found at line $line_beg, and the aside end at line $line_end, i.e. it contains nothing."
      # Then directly add the notification.
      sed -i "${line_end}i${notif_final}" "$trl_path"
    # If unique mark found, and this aside contains one line,
    elif [ $line_end -eq $(($line_beg+2)) ]; then
      echo "${h}Mark string found at line $line_beg, and the aside end at line $line_end, i.e. it contains one line."
      # Then replace this line with newest notif.
      sed -i "${line_end}i${notif_final}" "$trl_path"
      sed -i "$((line_beg+1))d" "$trl_path"
    # If unique mark found, and this aside contains multiple lines
    else
      # Then sth is wrong... Abort.
      echo "${h}Mark string found at line $line_beg, but the aside end at line $line_end, something must be wrong. Aborting..."; exit 1
    fi
  done
done
