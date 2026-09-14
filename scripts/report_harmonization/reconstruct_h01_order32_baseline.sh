#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: reconstruct_h01_order32_baseline.sh <project-root> <empty-baseline-dir>" >&2
  exit 64
fi

project_root=$(cd "$1" && pwd -P)
baseline_dir=$2

if [ ! -d "$baseline_dir" ]; then
  echo "Baseline directory does not exist: $baseline_dir" >&2
  exit 65
fi

baseline_dir=$(cd "$baseline_dir" && pwd -P)

if [ "$baseline_dir" = "$project_root" ]; then
  echo "Refusing to use the project root as the baseline directory." >&2
  exit 66
fi

if [ -n "$(find "$baseline_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Baseline directory must be empty: $baseline_dir" >&2
  exit 67
fi

patch_dir="$project_root/audit/report_harmonization/h01_order32_baseline_reverse_patches"
series_file="$patch_dir/series-reverse.txt"

if [ ! -f "$series_file" ]; then
  echo "Missing reverse-patch series: $series_file" >&2
  exit 68
fi

current_contract='notebooks/hypotheses/H01.qmd|9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb|93260
audit/hypotheses/H01/H01_analysis_preparation.qmd|ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f|55827
artifacts/12_manifests/H01_reporting_artifacts.csv|dfa9e15f44f0919277264765e84b49b7be78e4822df014abed678b29a9a951b4|11054
artifacts/12_manifests/H01_stage3_reporting_artifacts.csv|e9fe8740785e9f4d29e17c4333fdc0615347299c1dabea1d62ffad1cdafd11f9|26497
artifacts/12_manifests/H01/H01_preparation_report_manifest.csv|cb89845e92b39f5bab7a0524508a3f7e2ce1d19ebbc99afe12f1ebf8eb9aefb5|13841
artifacts/12_manifests/H01_worker_artifacts.csv|0d98bcc4ffe312e27ec89e352fdd84eea4ce1b8b8f9b9169307d314ba466b031|394888'

baseline_contract='notebooks/hypotheses/H01.qmd|31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6|90640
audit/hypotheses/H01/H01_analysis_preparation.qmd|962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8|54405
artifacts/12_manifests/H01_reporting_artifacts.csv|d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079|11054
artifacts/12_manifests/H01_stage3_reporting_artifacts.csv|16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e|26497
artifacts/12_manifests/H01/H01_preparation_report_manifest.csv|bae856c2bb75df317f476e7e993178061628c0fcdbc6795a4b88f78843f8d9d0|13841
artifacts/12_manifests/H01_worker_artifacts.csv|debce70f59c8e2c401ad36291694604246349633079bcd4d706aba6cf4d548c5|393672'

verify_contract() {
  contract=$1
  root_dir=$2
  phase=$3

  printf '%s\n' "$contract" | while IFS='|' read -r relative expected_sha expected_bytes; do
    source_path="$root_dir/$relative"
    if [ ! -f "$source_path" ]; then
      echo "$phase missing file: $relative" >&2
      exit 69
    fi
    observed_sha=$(shasum -a 256 "$source_path" | awk '{print $1}')
    observed_bytes=$(wc -c < "$source_path" | tr -d '[:space:]')
    if [ "$observed_sha" != "$expected_sha" ] || [ "$observed_bytes" != "$expected_bytes" ]; then
      echo "$phase identity mismatch: $relative" >&2
      echo "expected $expected_sha $expected_bytes" >&2
      echo "observed $observed_sha $observed_bytes" >&2
      exit 70
    fi
  done
}

verify_contract "$current_contract" "$project_root" "current"

printf '%s\n' "$current_contract" | while IFS='|' read -r relative _sha _bytes; do
  mkdir -p "$baseline_dir/$(dirname "$relative")"
  cp -p "$project_root/$relative" "$baseline_dir/$relative"
done

while IFS= read -r patch_name; do
  case "$patch_name" in
    ''|'#'*) continue ;;
  esac
  patch_path="$patch_dir/$patch_name"
  if [ ! -f "$patch_path" ]; then
    echo "Missing patch in series: $patch_path" >&2
    exit 71
  fi
  patch -s -R -p1 -d "$baseline_dir" -i "$patch_path"
done < "$series_file"

verify_contract "$baseline_contract" "$baseline_dir" "reconstructed baseline"

unexpected=$(find "$baseline_dir" -type f | sed "s#^$baseline_dir/##" | sort | while IFS= read -r relative; do
  if ! printf '%s\n' "$baseline_contract" | cut -d '|' -f 1 | grep -Fqx "$relative"; then
    printf '%s\n' "$relative"
  fi
done)

if [ -n "$unexpected" ]; then
  echo "Unexpected reconstructed baseline files:" >&2
  printf '%s\n' "$unexpected" >&2
  exit 72
fi

printf 'path\tsha256\tbytes\n'
printf '%s\n' "$baseline_contract" | while IFS='|' read -r relative _sha _bytes; do
  observed_sha=$(shasum -a 256 "$baseline_dir/$relative" | awk '{print $1}')
  observed_bytes=$(wc -c < "$baseline_dir/$relative" | tr -d '[:space:]')
  printf '%s\t%s\t%s\n' "$relative" "$observed_sha" "$observed_bytes"
done
