# Korrektur F-F03: Mehrjahres-Backtesting bei fehlendem Folgejahr
# Ohne Kalenderjahr nach dem Reservierungsjahr wurde die Schleife 1:0
# durchlaufen und ein zusaetzliches, erfundenes Jahr gezeichnet.

backtesting_multiyears_v <- function(sim_result_series_old,
                                   extended_claims_data_new,
                                   reserve_classes = NULL,
                                   dev_years = NULL) {

   # Setting arguments to NULL to prevent note in CMD check
   Year <- Expected <- NULL

   # define colors
   col1 <- "#0446BE"
   col2 <- "#4586FB"
   col3 <- "#C1D7FE"

   # pull additional objects from attributes
   reserving_year <- attr(sim_result_series_old, "last_orig_year")
   large_claims_list <- attr(sim_result_series_old, "large_claims_list")

   if (is.null(reserve_classes)) {reserve_classes <- unique(large_claims_list$Exit_reserve_class)}
   if (is.null(dev_years)) {dev_years <- unique(large_claims_list$Dev_year_since_large)}
   claim_ids <-
      large_claims_list$Claim_id[
         large_claims_list$Exit_reserve_class %in% reserve_classes &
            large_claims_list$Dev_year_since_large %in% dev_years]

   row_ind <- which(large_claims_list$Claim_id %in% claim_ids)
   n_years <- max(extended_claims_data_new$Calendar_year) - reserving_year

   if (n_years < 1) {
      stop("extended_claims_data_new must contain at least one calendar year after the reserving year")
   }

   expected <- q1 <- q10 <- q25 <- q50 <- q75 <- q90 <- q99 <- actual <- n_years
   for (year in 1:n_years) {
      values <- colSums(colSums(sim_result_series_old[row_ind, 1:year, , drop = FALSE]))
      expected[year] <- mean(values)
      q1[year] <- quantile(values, 0.01)
      q10[year] <- quantile(values, 0.1)
      q25[year] <- quantile(values, 0.25)
      q50[year] <- quantile(values, 0.5)
      q75[year] <- quantile(values, 0.75)
      q90[year] <- quantile(values, 0.9)
      q99[year] <- quantile(values, 0.99)
      actual[year] <-
         sum(
            extended_claims_data_new$Cl_payment_cal[
               extended_claims_data_new$Claim_id %in% claim_ids &
                  extended_claims_data_new$Calendar_year %in% (reserving_year + 1):(reserving_year + year)])
   }

   data <- data.frame(Year = (reserving_year + 1):(reserving_year + n_years),
                      Expected = expected,
                      Median = q50)
   # Erstellen des ggplot Diagramms
   ggplot(data,
          aes(
             x = Year,
             y = Expected)
   ) +
      geom_ribbon(
         aes(
            ymin = q1,
            ymax = q99,
            fill = "1% - 99%"
         ),
         alpha = 0.5) +
      geom_ribbon(
         aes(
            ymin = q10,
            ymax = q90,
            fill = "10% - 90%"
         ),
         alpha = 0.5) +
      geom_ribbon(
         aes(
            ymin = q25,
            ymax = q75,
            fill = "25% - 75%"
         ),
         alpha = 0.5) +
      geom_line(
         aes(
            y = q50,
            color = "Median"
         ),
         linewidth = 2) +
      geom_line(
         aes(
            y = expected,
            color = "Expected"
         ),
         linewidth = 2) +
      geom_point(
         aes(
            y = actual,
            shape = "Actual"),
         size = 6,
         stroke = 1.5,
         color = "black",
         fill = "darkorange",
         alpha = 1) +
      labs(
         x = "Year",
         y = "predicted payments in mio.",
         title = paste("Actual vs. Expected for reserve classes",
                       if (min(reserve_classes) == max(reserve_classes)) {
                          min(reserve_classes)
                       } else {
                          paste(min(reserve_classes), "to", max(reserve_classes))
                       },
                       "and dev. years",
                       if (min(dev_years) == max(dev_years)) {
                          min(dev_years)
                       } else {
                          paste(min(dev_years), "to", max(dev_years))
                       }
         ),
         subtitle = paste("Reserving year", reserving_year)
      ) +
      theme_minimal(
      ) +
      scale_y_continuous(
         labels = function(x) format(
            x / 1e6,
            big.mark = ".",
            decimal.mark = ",",
            nsmall = 1,
            trim = TRUE
         )
      ) +
      scale_x_continuous(
         labels = reserving_year + (1:n_years),
         breaks = reserving_year + (1:n_years)
      ) +
      scale_fill_manual(
         values = c("25% - 75%" = col1,
                    "10% - 90%" = col2,
                    "1% - 99%" = col3)
      ) +
      scale_color_manual(
         values = c("Median" = col3,
                    "Expected" = "black"),
         labels = c("Expected" = "Mean expected",
                    "Median" = "Median expected")
      ) +
      scale_shape_manual(
         values = c("Actual" = 21)) +
      guides(
         fill = guide_legend(
            title = "Quantile",
            order = 3),
         color = guide_legend(
            title = "",
            override.aes = list(shape = NA),
            order = 2),
         shape = guide_legend(
            title = "",
            order = 1)) +
      theme(
         plot.title = element_text(hjust = 0.5),
         plot.subtitle = element_text(hjust = 0.5),
         panel.grid.minor.y = element_blank(),
         panel.grid.minor.x = element_blank(),
         panel.grid.major.x = element_blank()
      )
}
