# Korrektur zu C-F02
# xl_cashflow() (R/reinsurance.R:255-326) prueft in Zeile 310-313 die Gueltigkeit von
# 'output'. Dort steht 'output == "future"' (Vergleich, wirkungslos) statt einer
# Zuweisung. Ein ungueltiger 'output' wird deshalb NICHT auf "future" gesetzt; die
# Funktion faellt in den abschliessenden else-Zweig und liefert die volle Matrix
# (history + future) zurueck, obwohl die Warnung "set to 'future'" meldet.
# Hier wird nur diese eine Zeile korrigiert.

xl_cashflow_v <- function(future_payments,
                          claims_list,
                          history,
                          reinsurance,
                          indices = NULL,
                          xl_indices_per_claim = NULL,
                          output = "future"){

   if (is.null(indices) & is.null(xl_indices_per_claim)) {
      stop("One of the parameters indices and xl_indices_per_claim has to be not NULL")
   }

   first_orig_year <- min(as.integer(colnames(history)))
   last_orig_year <- max(as.integer(colnames(history)))

   if (is.null(xl_indices_per_claim)) {
      xl_indices_per_claim <- generate_xl_indices_per_claim(claims_list = claims_list,
                                                            reinsurance = reinsurance,
                                                            indices = indices,
                                                            first_orig_year = first_orig_year,
                                                            last_orig_year = last_orig_year)}

   # Expand history by sampled future payments
   expanded_history <- cbind(history, future_payments)

   # cumulate expanded_history and minimize to 0, because a negative sum would lead to an error
   cum_gross_cashflow <- pmax(inc2cum(expanded_history), 0)

   # same operation on indexed expanded history
   indexed_cum_gross_cashflow <- pmax(inc2cum(expanded_history/xl_indices_per_claim), 0)

   # further operations are only applied to elements > 0
   idx <- which(cum_gross_cashflow > 0)

   # Calculate adjustment factor for priority and retention
   adj_factor <- rep(1, nrow(expanded_history) * ncol(expanded_history))
   adj_factor[idx] <- cum_gross_cashflow[ idx ] / indexed_cum_gross_cashflow[ idx ]

   # look up row index of the origin years in dataframe reinsurance
   origin_years <- match(claims_list$Origin_year, reinsurance$Origin_year)

   # Calculate indexed priority and limit
   ind_prio <- reinsurance$Priority[origin_years] * adj_factor
   ind_limit <- reinsurance$Limit[origin_years] * adj_factor

   # apply quota share to get basis for xl
   cum_gross_cashflow_after_quota <- cum_gross_cashflow * (1 - reinsurance$Quota_share[origin_years])

   # Calculate xl
   xl <- cum2inc(pmax(pmin(cum_gross_cashflow_after_quota - ind_prio,
                           ind_limit),
                      0))

   if (!output %in% c("future", "history", "total")) {
      output <- "future"   # Korrektur: war 'output == "future"' (wirkungsloser Vergleich)
      warning("Parameter 'output' not valid and set to 'future'")
   }

   if (output == "future") {
      # Reduce ouptut to future calendar years
      return(xl[,(ncol(history) + 1):ncol(expanded_history), drop = FALSE])
   }

   if (output == "history") {
      # Reduce ouptut to expired calendar years
      return(xl[,1:ncol(history), drop = FALSE])
   } else {
      return(xl)
   }
}
