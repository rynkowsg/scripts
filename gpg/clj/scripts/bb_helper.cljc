(ns bb-helper
  (:require
   [clojure.string :as str]
   [clojure.pprint :refer [pprint]]
   #?(:bb  [babashka.tasks :as bbt :refer [shell]]
      :clj [babashka.impl.tasks :as bbt :refer [shell]])))

(defn print-exec [command & [args]]
  (let [full-cmd (concat command args)]
    (println "CMD:" (str/join " " full-cmd))
    (println "---")
    (eval full-cmd)))
