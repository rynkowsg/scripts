(ns main
  (:require
   [clojure.string :as str]
   [clojure.pprint :refer [pprint]]
   [clojure.java.shell :as sh]
   [me.raynes.fs :as fs]
   [utils.regex :as uregex]))
;[babashka.impl.tasks :as bbt :refer [shell]]))
;#?(:bb  [babashka.tasks :as bbt :refer [shell]]
;   :clj [babashka.impl.tasks :as bbt :refer [shell]])))


;function gen_master_key() {}
;   local output_file="$(mktemp)"
;         local passphrase="$(gpg --gen-random --armor 0 24)}"
;   local uid=$(uid_to_str "$(echo "${1}" | jq -r '.uid')")
;         local algo="$(echo "${1}" | jq -r '.algo // ""')"
;   local usage="$(echo "${1}" | jq -r '.usage // ""')"
;         local expire="$(echo "${1}" | jq -r '.expire // ""')"
;   set -x
;   gpg --batch --status-fd 1 --no-tty --passphrase "${passphrase}" --quick-generate-key "${uid}" "${algo}" "${usage}" "${expire}" >"${output_file}" 2>&1
;         set +x
;         local fingerprint="$(awk '/KEY_CREATED P/ { print $4}' "${output_file}")"
;         local revocation_cert_path="$(awk '/revocation/ { print substr($6, 2, length($6)-2) }' "${output_file}")"
;         rm -f "${output_file}"
;   cat <<-EOF
;   {"fingerprint": "${fingerprint}",
;                                          "uid": "${uid}",
;    "algo": "${algo}",
;                                          "revocationCertPath": "${revocation_cert_path}",
;    "passphrase": "${passphrase}"},
;         "home_dir": ""
;
;   EOF

(defn gen-master-key
  [{:keys [home-dir passphrase uid algo usage expire]}]
  (fs/mkdir home-dir)
  (sh/sh "chmod" "700" home-dir)
  (sh/sh "chmod" "600" (str home-dir "/*"))
  (let [{:keys [exit out err] :as res} (sh/sh "gpg" "--homedir" home-dir
                                              "--batch" "--status-fd" "1" "--no-tty"
                                              "--passphrase" passphrase
                                              "--quick-generate-key" uid algo usage expire)
        _                    (clojure.pprint/pprint res)
        status-created-re    #"^\[GNUPG:\] KEY_CREATED P (?<fpr>[a-zA-Z0-9]{40})$"
        status-considered-re #"^\[GNUPG:\] KEY_CONSIDERED (?<fpr>[a-zA-Z0-9]{40}) \d{1}$"
        status-created       (->> out str/split-lines (filter (partial re-find status-created-re)) first)
        status-considered    (->> out str/split-lines (filter (partial re-find status-considered-re)) first)
        created?             (some? status-created)
        {:keys [fpr]} (uregex/named-groups status-considered-re status-considered)]
    (merge res {:home-dir   home-dir
                :passphrase passphrase
                :created?   created?
                :fpr        fpr})))


(defn add-sub-key
  [{:keys [home-dir passphrase master-fpr algo usage expire] :or {algo "" usage "" expire 0}}]
  (let [{:keys [exit out err] :as res} (sh/sh "gpg" "--homedir" home-dir
                                              "--batch" "--status-fd" "1" "--no-tty"
                                              "--pinentry-mode" "loopback"
                                              "--passphrase" passphrase
                                              "--quick-add-key" master-fpr algo usage expire)
        status-created-re #"^\[GNUPG:\] KEY_CREATED S (?<fpr>[a-zA-Z0-9]{40})$"
        status-created    (->> out str/split-lines (filter (partial re-find status-created-re)) first)
        created?          (some? status-created)
        {:keys [fpr]} (uregex/named-groups status-created-re status-created)]
    (merge res {:home-dir home-dir
                :created? created?
                :fpr      fpr
                :usage usage
                :algo
                :expire})))


; todo: parse
(defn list-keys
  [{:keys [gnupg-home passphrase]}]
  (let [{:keys [exit out err] :as res} (sh/sh "gpg" "--homedir" gnupg-home
                                              "--batch" "--no-tty"
                                              "--with-colons"
                                              "--passphrase" passphrase
                                              "--list-keys")]

    {:res res}))


(defn demo [])


(comment
 (sh/sh "ls" "-al")

 (def home (str (System/getenv "HOME") "/Desktop/gpg-test"))

 (def res (gen-master-key {:home-dir   home
                           :passphrase "random"
                           :uid        "Grzegorz Rynkowski"
                           :algo       "rsa2048"
                           :usage      "cert"
                           :expire     "0"}))
 (def res2 (add-sub-key {:home-dir   (:home-dir res)
                         :passphrase (:passphrase res)
                         :master-fpr (:fpr res)
                         :algo       "rsa2048"
                         :usage      "sign"
                         :expire     "0"}))

 (fs/delete-dir home)

 (list-keys {:gnupg-home home
             :passphrase "random"}))
