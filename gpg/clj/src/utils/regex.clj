(ns utils.regex)

(defn named-groups
  "Is looking for groups titled with word like (?<pattern>...) and returns map for each pattern matched."
  [regex text]
  (let [named-groups (->> (re-seq #"\?\<([a-zA-Z0-9]+)\>" (str regex)) (map second))
        matcher      (re-matcher regex text)]
    (if (.matches matcher)
      (->> named-groups
           (map (fn [^String word] {(keyword word) (.group matcher word)}))
           (into {}))
      (throw (ex-info "Can't extract values" {})))))
#_(named-groups #".*(?<year>\d{4})-(?<month>.{2})-monthly.xml" "/Users/greg/Sources/rynkowski/trading-tax-calc/dev/resources/fx/gbp/2017-06-monthly.xml")
