#!/usr/bin/env bash

# shellcheck disable=SC2155

RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
BLUE=$(printf '\033[34m')
BOLD=$(printf '\033[1m')
RESET=$(printf '\033[m')

function uid_to_str {
  local name="$(echo "${1}" | jq -r '.name // ""')"
  local comment="$(echo "${1}" | jq -r '.comment // ""')"
  local email="$(echo "${1}" | jq -r '.email // ""')"
  [ "${name}" == "" ] && { printf "\n${RED}%s${NC}\n%s\n" "userid has to always have name"; exit 1; }
  local str="${name}"
  [ "${comment}" != "" ] && str="${str} (${comment})"
  [ "${email}" != "" ] && str="${str} (${email})"
  echo "${str}"
}

function gen_master_key {
  local output_file="$(mktemp)"
  local passphrase="$(gpg --gen-random --armor 0 24)}"
  local uid=$(uid_to_str "$(echo "${1}" | jq -r '.uid // ""')")
  local algo="$(echo "${1}" | jq -r '.algo // ""')"
  local usage="$(echo "${1}" | jq -r '.usage // ""')"
  local expire="$(echo "${1}" | jq -r '.expire // ""')"
  set -x
  gpg --batch --status-fd 1 --no-tty --passphrase "${passphrase}" --quick-generate-key "${uid}" "${algo}" "${usage}" "${expire}" > "${output_file}" 2>&1
  set +x
  local fingerprint="$(awk  '/KEY_CREATED P/ { print $4}' "${output_file}")"
  local revocation_cert_path="$(awk  '/revocation/ { print substr($6, 2, length($6)-2) }' "${output_file}")"
  rm -f "${output_file}"
  cat <<- EOF
  {"fingerprint": "${fingerprint}",
   "uid": "${uid}",
   "algo": "${algo}",
   "revocationCertPath": "${revocation_cert_path}",
   "passphrase": "${passphrase}"}
EOF
}

function add_subkey {
  local master_fpr="$(echo "${1}" | jq -r '.fingerprint')"
  local passphrase="$(echo "${1}" | jq -r '.passphrase')"
  local algo="$(echo "${2}" | jq -r '.algo')"
  local usage="$(echo "${2}" | jq -r '.usage')"
  local expire="$(echo "${2}" | jq -r '.expire')"
  local output_file="$(mktemp)"
  set -x
  gpg --batch --status-fd 1 --pinentry-mode loopback --passphrase "${passphrase}" --quick-add-key "${master_fpr}" "${algo}" "${usage}" "${expire}" > "${output_file}" 2>&1
  set +x
  local fingerprint="$(awk  '/KEY_CREATED S/ { print $4}' "${output_file}")"
  rm -f "${output_file}"
  cat <<- EOF
  {"usage": "${usage}",
   "algo": "${algo}",
   "fingerprint": "${fingerprint}"}
EOF
}

function demo {
  export GNUPGHOME="$(mktemp -d)"

  local master_key_params="$(cat <<- EOF
  {"uid": {"name": "Grzegorz Rynkowski", "email": "grzegorz.rynkowski@gmail.com"},
   "algo": "rsa2048",
   "usage": "cert",
   "expire": "5y"
   }
EOF
)"
  local master_key_info="$(gen_master_key "${master_key_params}")"
  local subkey_1_info="$(add_subkey "${master_key_info}" '{"algo": "rsa2048", "usage": "encrypt", "expire": "1y"}')"
  local subkey_2_info="$(add_subkey "${master_key_info}" '{"algo": "rsa2048", "usage": "sign",    "expire": "1y"}')"
  local subkey_3_info="$(add_subkey "${master_key_info}" '{"algo": "rsa2048", "usage": "auth",    "expire": "1y"}')"

  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "MASTER" "${master_key_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_1" "${subkey_1_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_2" "${subkey_2_info}"
  printf "\n${YELLOW}${BOLD}%s${RESET}\n%s\n" "SUBKEY_3" "${subkey_3_info}"

  printf "\n${YELLOW}${BOLD}%s${RESET}\n" "LIST OF KEYS"
  gpg --list-secret-keys

  rm -rf "${GNUPGHOME}"
  set +x
}

demo;


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
# - http://gnupg.10057.n7.nabble.com/Please-fix-batch-mode-for-gpg-edit-key-trust-td48162.html
# - http://gnupg.10057.n7.nabble.com/gpg-batch-yes-edit-key-trust-td11463.html
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
