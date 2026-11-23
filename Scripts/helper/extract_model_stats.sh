#!/usr/bin/env bash
set -euo pipefail

input="${1:-tree.model.gz}"
output="${2:-best_models.tsv}"

gzip -cd "$input" | awk '
BEGIN {
    OFS = "\t"
    print "gene", "best_model_AIC", "best_model_AICc", \
          "best_model_BIC", "best_score_AIC", \
          "best_score_AICc", "best_score_BIC"
}

function emit() {
    if (gene != "") {
        print gene, model_aic, model_aicc, model_bic, \
              score_aic, score_aicc, score_bic
    }
}

function reset() {
    model_aic = model_aicc = model_bic = "NA"
    score_aic = score_aicc = score_bic = "NA"
}

/^[[:space:]]*[0-9]+\.fna:/ {
    emit()
    gene = $1
    sub(/:$/, "", gene)
    reset()
    next
}

{
    key = $1
    sub(/:$/, "", key)
    value = $2

    if      (key == "best_model_AIC")   model_aic = value
    else if (key == "best_model_AICc")  model_aicc = value
    else if (key == "best_model_BIC")   model_bic = value
    else if (key == "best_score_AIC")   score_aic = value
    else if (key == "best_score_AICc")  score_aicc = value
    else if (key == "best_score_BIC")   score_bic = value
}

END { emit() }
' > "$output"

echo "Saved: $output"
