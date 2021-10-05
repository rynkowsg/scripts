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
   "revocationCertPath": "${revocation_cert_path}",
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

function demo() {
  unset GNUPGHOME
  local gnupg_home="$(mktemp -d)"

  # create master key (cert only)
  local master_key_params="$(echo '{"uid": "Grzegorz Rynkowski", "algo": "rsa2048", "usage": "cert", "expire": "2090-01-01"}' \
    | jq --arg home "${gnupg_home}" '. += {"home_dir": $home}')"
  local master_key_info="$(gen_master_key "${master_key_params}")"

  # create subkeys
  local subkey_1_info="$(add_subkey "${master_key_info}" '{"algo": "rsa2048", "usage": "encrypt", "expire": "1y"}')"
  local subkey_2_info="$(add_subkey "${master_key_info}" '{"algo": "rsa2048", "usage": "sign",    "expire": "1y"}')"
  local subkey_3_info="$(add_subkey "${master_key_info}" '{"algo": "rsa2048", "usage": "auth",    "expire": "1y"}')"
  # add uids
  add_uid "${master_key_info}" '{"uid": "Grzegorz Rynkowski <me@example.com>"}'
  add_uid "${master_key_info}" '{"uid": "Grzegorz Rynkowski <me@domain.com>"}'
  set_primary_uid "${master_key_info}" '{"uid": "me@example.com"}'

  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "MASTER" "${master_key_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_1" "${subkey_1_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_2" "${subkey_2_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_3" "${subkey_3_info}"

  printf "\n${YELLOW}${BOLD}%s${RESET}\n" "LIST OF KEYS"
  gpg --homedir "${gnupg_home}" --list-secret-keys

  export fpr="$(echo "${master_key_info}" | jq -r '.fingerprint')"
  local passphrase="$(echo "${master_key_info}" | jq -r '.passphrase')"

  printf "%s\n" "-- FILES SAVED in GNUPGHOME=${gnupg_home}:"
  tree "${gnupg_home}"

#  mkdir -p ~/Desktop/g1
#  sudo chown -R $USER ~/Desktop/g1
#  sudo find ~/Desktop/g1 -type d -exec chmod 700 {} \;
#  sudo find ~/Desktop/g1 -type f -exec chmod 600 {} \;
#  cp -r "${GNUPGHOME}/pubring.kbx" "${GNUPGHOME}/trustdb.gpg" "${GNUPGHOME}/private-keys-v1.d" ~/Desktop/g1
#  tree ~/Desktop/g1
#  gpg --homedir ~/Desktop/g1 --list-secret-keys
#  rm -rf "$HOME/Desktop/g1"
#
#  mkdir -p ~/Desktop/g2
#  sudo chown -R $USER ~/Desktop/g2
#  sudo find ~/Desktop/g2 -type d -exec chmod 700 {} \;
#  sudo find ~/Desktop/g2 -type f -exec chmod 600 {} \;
#  gpg --homedir "${GNUPGHOME}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --output "${GNUPGHOME}/sub.key" --export-secret-keys "$fpr"
#  gpg --homedir "${GNUPGHOME}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --export-ownertrust > "${GNUPGHOME}/trust"
#  gpg --homedir ~/Desktop/g2 --batch --pinentry-mode loopback --passphrase "${passphrase}" --import "${GNUPGHOME}/sub.key"
#  gpg --homedir ~/Desktop/g2 --batch --pinentry-mode loopback --passphrase "${passphrase}" --import "${GNUPGHOME}/trust"
#  tree ~/Desktop/g2
#  gpg --homedir ~/Desktop/g2 --list-secret-keys
#  rm -rf "$HOME/Desktop/g2"
#
#  mkdir -p ~/Desktop/g3
#  sudo chown -R $USER ~/Desktop/g3
#  sudo find ~/Desktop/g3 -type d -exec chmod 700 {} \;
#  sudo find ~/Desktop/g3 -type f -exec chmod 600 {} \;
#  gpg --homedir "${GNUPGHOME}" --batch --pinentry-mode loopback --passphrase "${passphrase}" --export-secret-subkeys "$fpr" | gpg --homedir ~/Desktop/g3 --import
#  ls -al ~/Desktop/g3
#  gpg --homedir ~/Desktop/g3 --list-secret-keys
#  rm -rf "$HOME/Desktop/g3"

  rm -rf "${gnupg_home}"
  set +x
}

demo

# FAQ
# ---
# Q: RSA or DSA:
# A: RSA.
# More: https://superuser.com/questions/13164/what-is-better-for-gpg-keys-rsa-or-dsa
#       https://security.stackexchange.com/questions/72581/new-pgp-key-rsa-rsa-or-dsa-elgamal

# LINKS
# -----
#
# GNU docs:
# - PDF:
#   https://www.gnupg.org/documentation/manuals/gnupg.pdf
# - on status output:
#   https://github.com/gpg/gnupg/blob/master/doc/DETAILS
#
# on non-interactive mode:
# - https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html
# - https://raymii.org/s/articles/GPG_noninteractive_batch_sign_trust_and_send_gnupg_keys.html
# - http://gnupg.10057.n7.nabble.com/Please-fix-batch-mode-for-gpg-edit-key-trust-td48162.html (https://lists.gnupg.org/pipermail/gnupg-users/2016-July/056361.html)
# - http://gnupg.10057.n7.nabble.com/gpg-batch-yes-edit-key-trust-td11463.html  (https://lists.gnupg.org/pipermail/gnupg-users/2010-July/039213.html, https://web.archive.org/web/20201010065002/http://gnupg.10057.n7.nabble.com/gpg-batch-yes-edit-key-trust-td11463.html)
# - https://stackoverflow.com/questions/56582016/gpg-change-passphrase-non-interactively/65516333#65516333
#
# edit-key
# https://www.gnupg.org/gph/en/manual/r899.html
#
#
# NOTES
# -----
#
# gpg --batch --generate-key "batch commands"
# - allows to create only one subkey
#   look issue here: https://dev.gnupg.org/T4514#125569
#
# - quick* commands
#   https://www.gnupg.org/documentation/manuals/gnupg/OpenPGP-Key-Management.html#OpenPGP-Key-Management
