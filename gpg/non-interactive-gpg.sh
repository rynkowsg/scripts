#!/usr/bin/env bash

# shellcheck disable=SC2155

RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
BLUE=$(printf '\033[34m')
BOLD=$(printf '\033[1m')
RESET=$(printf '\033[m')

function gen_master_key() {
  local home_dir="$(echo "${1}" | jq -r ".home_dir // \"${GNUPGHOME}\"")"
  local passphrase="$(gpg --gen-random --armor 0 24)}"
  local uid="$(echo "${1}" | jq -r '.uid')"
  local algo="$(echo "${1}" | jq -r '.algo // ""')"
  local usage="$(echo "${1}" | jq -r '.usage // ""')"
  local expire="$(echo "${1}" | jq -r '.expire // ""')"
  local output_file="$(mktemp)"
  set -x
  gpg --homedir "${home_dir}" --batch --no-tty \
      --status-fd 1  --passphrase "${passphrase}" \
      --quick-generate-key "${uid}" "${algo}" "${usage}" "${expire}" >"${output_file}" 2>&1
  set +x
  local fingerprint="$(awk '/KEY_CREATED P/ { print $4}' "${output_file}")"
  local revocation_cert_path="$(awk '/revocation/ { print substr($6, 2, length($6)-2) }' "${output_file}")"
  rm -f "${output_file}"
  cat <<-EOF
  {"fingerprint": "${fingerprint}",
   "uid": "${uid}",
   "algo": "${algo}",
   "revocation_cert_path": "${revocation_cert_path}",
   "passphrase": "${passphrase}",
   "home_dir": "${home_dir}"}
EOF
}
# example:
#    gen_master_key '{"fingerprint": "Grzegorz Rynkowski", "algo": "rsa4096", "usage": "cert", "expire": "2090-01-01"}'
#    gen_master_key '{"uid": "Grzegorz Rynkowski", "algo": "rsa4096", "usage": "cert", "expire": "2090-01-01", "home_dir": "/Users/greg/.gnupg"}'

function add_subkey() {
  local home_dir="$(echo "${1}" | jq -r '.home_dir')"
  local passphrase="$(echo "${1}" | jq -r '.passphrase')"
  local master_fpr="$(echo "${1}" | jq -r '.fingerprint')"
  local algo="$(echo "${2}" | jq -r '.algo')"
  local usage="$(echo "${2}" | jq -r '.usage')"
  local expire="$(echo "${2}" | jq -r '.expire')"
  local output_file="$(mktemp)"
  set -x
  gpg --homedir "${home_dir}" --batch \
      --status-fd 1 --pinentry-mode loopback --passphrase "${passphrase}" \
      --quick-add-key "${master_fpr}" "${algo}" "${usage}" "${expire}" >"${output_file}" 2>&1
  set +x
  local fingerprint="$(awk '/KEY_CREATED S/ { print $4}' "${output_file}")"
  rm -f "${output_file}"
  cat <<-EOF
  {"usage": "${usage}",
   "algo": "${algo}",
   "fingerprint": "${fingerprint}"}
EOF
}
# example:
#    add_subkey '{"fingerprint": "45F3 A137 E00E B692 4E43  9BA8 5233 64D1 E23B 68F7", "passphrase": "", "home_dir": "/Users/greg/.gnupg"}' '{"algo": "rsa2048", "usage": "encrypt", "expire": "1y"}'
#    add_subkey '{"fingerprint": "45F3 A137 E00E B692 4E43  9BA8 5233 64D1 E23B 68F7", "passphrase": "", "home_dir": "/Users/greg/.gnupg"}' '{"algo": "rsa2048", "usage": "sign", "expire": "1y"}'
#    add_subkey '{"fingerprint": "45F3 A137 E00E B692 4E43  9BA8 5233 64D1 E23B 68F7", "passphrase": "", "home_dir": "/Users/greg/.gnupg"}' '{"algo": "rsa2048", "usage": "auth", "expire": "1y"}'

function add_uid() {
  local home_dir="$(echo "${1}" | jq -r ".home_dir // \"${GNUPGHOME}\"")"
  local passphrase="$(echo "${1}" | jq -r '.passphrase')"
  local master_fpr="$(echo "${1}" | jq -r '.fingerprint')"
  local uid="$(echo "${2}" | jq -r '.uid')"
  local output_file="$(mktemp)"
  set -x
  gpg --homedir "${home_dir}" --batch \
      --status-fd 1 --pinentry-mode loopback --passphrase "${passphrase}" \
      --quick-add-uid "${master_fpr}" "${uid}" >"${output_file}" 2>&1
  set +x
  rm -f "${output_file}"
}
# example:
#    add_uid '{"fingerprint": "45F3 A137 E00E B692 4E43  9BA8 5233 64D1 E23B 68F7", "passphrase": "", "home_dir": "/Users/greg/.gnupg"}' '{"uid": "Grzegorz Rynkowski <me@example.com>"}'

function set_primary_uid() {
  local home_dir="$(echo "${1}" | jq -r ".home_dir // \"${GNUPGHOME}\"")"
  local master_fpr="$(echo "${1}" | jq -r '.fingerprint')"
  local passphrase="$(echo "${1}" | jq -r '.passphrase')"
  local uid="$(echo "${2}" | jq -r '.uid')"
  local output_file="$(mktemp)"
  set -x
  gpg --homedir "${home_dir}" --batch \
      --status-fd 1 --pinentry-mode loopback --passphrase "${passphrase}" \
      --quick-set-primary-uid "${master_fpr}" "${uid}" >"${output_file}" 2>&1
  set +x
  rm -f "${output_file}"
}
# example:
#    add_uid '{"fingerprint": "45F3 A137 E00E B692 4E43  9BA8 5233 64D1 E23B 68F7", "passphrase": "", "home_dir": "/Users/greg/.gnupg"}' '{"uid": "me@example.com"}'

function add_photo_id() {
  local home_dir="$(echo "${1}" | jq -r ".home_dir // \"${GNUPGHOME}\"")"
  local fpr="$(echo "${1}" | jq -r '.fingerprint')"
  local passphrase="$(echo "${1}" | jq -r '.passphrase')"
  local photo_path="$(echo "${2}" | jq -r '.photo_path')"
  local output_file="$(mktemp)"
  set -x
  printf "${photo_path}\n" | gpg --homedir "${home_dir}" --batch --command-fd 0 \
       --status-fd 1 --pinentry-mode loopback --passphrase "${passphrase}" \
       --edit-key "${fpr}" addphoto save quit >"${output_file}" 2>&1
  set +x
  rm -f "${output_file}"
}
# example:
#    add_photo_id '{"fingerprint": "45F3 A137 E00E B692 4E43  9BA8 5233 64D1 E23B 68F7", "passphrase": "", "home_dir": "/Users/greg/.gnupg"}' '{"photo_path": "/Users/greg/Desktop/photoid.jpg"}'

function delete_uid() {
  local home_dir="$(echo "${1}" | jq -r ".home_dir // \"${GNUPGHOME}\"")"
  local fpr="$(echo "${1}" | jq -r '.fingerprint')"
  local passphrase="$(echo "${1}" | jq -r '.passphrase')"
  local uid_number="$(echo "${2}" | jq -r '.uid_number')"
  local output_file="$(mktemp)"
  set -x
  printf "yes\n" | gpg --homedir "${home_dir}" --batch --command-fd 0 \
       --status-fd 1 --pinentry-mode loopback --passphrase "${passphrase}" \
       --edit-key "${fpr}" uid ${uid_number} deluid save quit >"${output_file}" 2>&1
  set +x
  rm -f "${output_file}"
}
# example:
#   delete_uid '{"fingerprint": "45F3 A137 E00E B692 4E43  9BA8 5233 64D1 E23B 68F7", "passphrase": "", "home_dir": "/Users/greg/.gnupg"}' '{"uid_number": 2}'

function gpg_demo() {
  unset GNUPGHOME
  local gnupg_home="$(mktemp -d)"

  # create master key (cert only)
  local master_key_params="$(echo '{"uid": "Grzegorz Rynkowski", "algo": "rsa4096", "usage": "cert", "expire": "10y"}' \
    | jq --arg home "${gnupg_home}" '. += {"home_dir": $home}')"
  local master_key_info="$(gen_master_key "${master_key_params}")"
  local revocation_cert_path="$(echo "${master_key_info}" | jq -r '.revocation_cert_path')"

  # add uids
  #add_uid "${master_key_info}" '{"uid": "Grzegorz Rynkowski <me@example.com>"}'
  #add_uid "${master_key_info}" '{"uid": "Grzegorz Rynkowski <me@domain.com>"}'
  #set_primary_uid "${master_key_info}" '{"uid": "me@example.com"}'
  local script_dir="$(cd "$(dirname "$([ -L "$0" ] && readlink "$0" || echo "$0")")" || exit 1; pwd -P)"
  local photo_path="${script_dir}/gpg-photo-id.jpg"
  local photo_details="$(echo '{}' | jq --arg path "${photo_path}" '. += {"photo_path": $path}')"
  if [ -f "${photo_path}" ]; then
    add_photo_id "${master_key_info}" "${photo_details}"
  else
    printf "\n${RED}Photo file in %s does not exist. Skipping addphoto...${RESET}\n" "${photo_path}"
  fi

  gpg --homedir "${gnupg_home}" --list-keys

  # create subkeys
  local subkey_1_info="$(add_subkey "${master_key_info}" '{"algo": "rsa4096", "usage": "encrypt", "expire": "1y"}')"
  local subkey_2_info="$(add_subkey "${master_key_info}" '{"algo": "rsa4096", "usage": "sign",    "expire": "1y"}')"
  local subkey_3_info="$(add_subkey "${master_key_info}" '{"algo": "rsa4096", "usage": "auth",    "expire": "1y"}')"

  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "MASTER" "${master_key_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_1" "${subkey_1_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_2" "${subkey_2_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_3" "${subkey_3_info}"

  printf "\n${YELLOW}${BOLD}%s${RESET}\n" "LIST OF KEYS"
  gpg --homedir "${gnupg_home}" --list-secret-keys

  printf "\n${YELLOW}${BOLD}%s${RESET}\n" "LINTER REPORT"
  gpg --homedir "${gnupg_home}" --export | hokey lint

  export fpr="$(echo "${master_key_info}" | jq -r '.fingerprint')"
  local passphrase="$(echo "${master_key_info}" | jq -r '.passphrase')"

  local export_dir="${gnupg_home}/exports"
  mkdir -p "${export_dir}"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --export                                       > "${export_dir}/public-${fpr}-$(date +%F).gpg"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --armor --export                               > "${export_dir}/public-${fpr}-$(date +%F).asc"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --export-secret-key "${fpr}"                   > "${export_dir}/private-${fpr}.gpg"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --armor --export-secret-key "${fpr}"           > "${export_dir}/private-${fpr}.asc"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --export-secret-key "${fpr}" | paperkey --output "${export_dir}/private-${fpr}.paper.asc"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --armor --export-secret-subkeys "${fpr}"       > "${export_dir}/private-${fpr}-subkeys.asc"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --export-secret-subkeys "${fpr}"               > "${export_dir}/private-${fpr}-subkeys.gpg"
  cp "${revocation_cert_path}"                                                                                                                 "${export_dir}/revoke-${fpr}.asc"
  gpg --homedir "${gnupg_home}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --export-ownertrust                            > "${export_dir}/trust"

  printf "%s\n" "-- FILES SAVED in GNUPGHOME=${gnupg_home}:"
  tree "${gnupg_home}"

  printf "%s\n" "-- SIZE OF EXPORTS:"
  du -sh "${gnupg_home}/exports"/*

  rm -rf "${gnupg_home}"
  set +x
}
# example:
#   source non-interactive-gpg.sh; gpg_demo
