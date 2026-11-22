# Korrektur F-F01: Cashflow-Backtesting des ersten Folgejahres
# Die Erwartungswerte der Simulation sind nominal (Zahlungsjahr); die
# Ist-Werte wurden mit Ind_cl_payment_cal auf das Indexjahr deflationiert.
# Korrektur: Vergleich auf nominaler Basis mit Cl_payment_cal.

backtesting_1y_per_reserve_class_v <- function(sim_result_series_old,
                                             extended_claims_data_new) {

   # Setting arguments to NULL to prevent note in CMD check
   Claim_id <- Calendar_year <- Cl_payment_cal <-
      Type <- Reserve_class <- Value <- NULL

   # define colors
   col1 <- "#0446BE"
   col2 <- "#4586FB"
   col3 <- "#C1D7FE"
   # pull additional objects from attributes
   last_orig_year <- attr(sim_result_series_old, "last_orig_year") + 1
   large_claims_list <- attr(sim_result_series_old, "large_claims_list")
   n_rc <- max(large_claims_list$Exit_reserve_class)

   # Create dataframe
   df_backtesting <- lapply(0:n_rc, function(rc) {
      v_idx <- which(large_claims_list$Exit_reserve_class == rc)

      # summarize per reserve class
      series_sum <- colSums(sim_result_series_old[v_idx, 1, , drop = FALSE])

      # calculate quantiles
      q <- quantile(series_sum, probs = c(0.01, 0.1, 0.25, 0.75, 0.9, 0.99))

      # calculate actual value
      actual_val <- extended_claims_data_new %>%
         filter(Claim_id %in% large_claims_list$Claim_id[v_idx],
                Calendar_year == last_orig_year) %>%
         summarise(sum = sum(Cl_payment_cal)) %>%
         pull(sum)

      # combine to tibble
      tibble(
         Reserve_class = as.character(rc),
         Type = c("Expected", "Q1", "Q10", "Q25", "Q75", "Q90", "Q99", "Actual"),
         Value = c(
            mean(series_sum),
            q[1],
            q[2] - q[1],
            q[3] - q[2],
            q[4] - q[3],
            q[5] - q[4],
            q[6] - q[5],
            actual_val
         )
      )
   }) %>%
      bind_rows() %>%
      mutate(
         Type = factor(Type,
                       levels = c("Q99",
                                  "Q90",
                                  "Q75",
                                  "Q25",
                                  "Q10",
                                  "Q1",
                                  "Expected",
                                  "Actual")),
         Reserve_class = factor(Reserve_class,
                                levels = as.character(0:n_rc))
      ) %>%
      as.data.frame()



   ggplot(df_backtesting, aes(x = as.factor(Reserve_class),
                              y = Value / 1e6,
                              fill = Type)) +
      geom_bar(
         data = filter(df_backtesting,
                       !(Type %in% c("Expected", "Actual"))),
         stat = "identity",
         alpha = 1,
         width = 0.8) +
      geom_segment(
         data = filter(df_backtesting,
                       Type %in% c("Expected", "Actual")),
         aes(
            x = as.numeric(Reserve_class) - 0.25,
            xend = as.numeric(Reserve_class) + 0.25,
            y = Value / 1e6,
            yend = Value / 1e6,
            color = Type
         ),
         linewidth = 1.5
      ) +
      scale_fill_manual(
         values = c(
            "Q1" = "NA",
            "Q10" = col3,
            "Q25" = col2,
            "Q75" = col1,
            "Q90" = col2,
            "Q99" = col3
         ),
         labels = c(
            "25% - 75%",
            "10% - 90%",
            "1% - 99%",
            "",
            "",
            ""
         )
      ) +
      scale_color_manual(
         name = "",
         values = c("Expected" = "black", "Actual" = "darkorange"),
         labels = c("Expected" = "Expected", "Actual" = paste("Actual", last_orig_year))
      ) +
      guides(
         fill = guide_legend(
            override.aes = list(
               fill = c(
                  col1,
                  col2,
                  col3,
                  "NA",
                  "NA",
                  "NA"
               ),
               order = 2
            ),
            title = "Quantiles"
         ),
         color = guide_legend(
            order = 1
         )
      ) +
      theme_minimal() +
      labs(
         x = "Reserve class",
         y = "Payments in mio.",
         title = "Actual vs. expected large claims payments"
      ) +
      theme(
         plot.title = element_text(hjust = 0.5),
         panel.grid.minor.x = element_blank(),
         panel.grid.major.x = element_blank()
      )
}


backtesting_1y_per_origin_year_v <- function(sim_result_series_old,
                                           extended_claims_data_new) {

   # Setting arguments to NULL to prevent note in CMD check
   Claim_id <- Calendar_year <- Cl_payment_cal <- Type <-
      Origin_year <- Value <- NULL

   # define colors
   col1 <- "#0446BE"
   col2 <- "#4586FB"
   col3 <- "#C1D7FE"

   # pull additional objects from attributes
   last_orig_year <- attr(sim_result_series_old, "last_orig_year") + 1
   large_claims_list <- attr(sim_result_series_old, "large_claims_list")
   orig_years <- min(large_claims_list$Origin_year):
      max(large_claims_list$Origin_year)

   # Create dataframe
   df_backtesting <- lapply(orig_years, function(orig_year) {
      v_idx <- which(large_claims_list$Origin_year == orig_year)

      # summarize per reserve class
      series_sum <- colSums(sim_result_series_old[v_idx, 1, , drop = FALSE])

      # calculate quantiles
      q <- quantile(series_sum, probs = c(0.01, 0.1, 0.25, 0.75, 0.9, 0.99))

      # calculate actual value
      actual_val <- extended_claims_data_new %>%
         filter(Claim_id %in% large_claims_list$Claim_id[v_idx],
                Calendar_year == last_orig_year) %>%
         summarise(sum = sum(Cl_payment_cal)) %>%
         pull(sum)

      # combine to tibble
      tibble(
         Origin_year = as.character(orig_year),
         Type = c("Expected", "Q1", "Q10", "Q25", "Q75", "Q90", "Q99", "Actual"),
         Value = c(
            mean(series_sum),
            q[1],
            q[2] - q[1],
            q[3] - q[2],
            q[4] - q[3],
            q[5] - q[4],
            q[6] - q[5],
            actual_val
         )
      )
   }) %>%
      bind_rows() %>%
      mutate(
         Type = factor(Type,
                       levels = c("Q99",
                                  "Q90",
                                  "Q75",
                                  "Q25",
                                  "Q10",
                                  "Q1",
                                  "Expected",
                                  "Actual")),
         Origin_year = factor(Origin_year,
                              levels = as.character(orig_years))
      ) %>%
      as.data.frame()



   ggplot(df_backtesting, aes(x = Origin_year,
                              y = Value / 1e6,
                              fill = Type)) +
      geom_bar(
         data = filter(df_backtesting,
                       !(Type %in% c("Expected", "Actual"))),
         stat = "identity",
         alpha = 1,
         width = 0.8) +
      geom_segment(
         data = filter(df_backtesting,
                       Type %in% c("Expected", "Actual")),
         aes(
            x = as.numeric(as.character(Origin_year)) - min(orig_years) + 1 - 0.25,
            xend = as.numeric(as.character(Origin_year)) - min(orig_years) + 1 + 0.25,
            y = Value / 1e6,
            yend = Value / 1e6,
            color = Type
         ),
         linewidth = 1.5
      ) +
      scale_fill_manual(
         values = c(
            "Q1" = "NA",
            "Q10" = col3,
            "Q25" = col2,
            "Q75" = col1,
            "Q90" = col2,
            "Q99" = col3
         ),
         labels = c(
            "25% - 75%",
            "10% - 90%",
            "1% - 99%",
            "",
            "",
            ""
         )
      ) +
      scale_color_manual(
         name = "",
         values = c("Expected" = "black", "Actual" = "darkorange"),
         labels = c("Expected" = "Expected", "Actual" = paste("Actual", last_orig_year))
      ) +
      guides(
         fill = guide_legend(
            override.aes = list(
               fill = c(
                  col1,
                  col2,
                  col3,
                  "NA",
                  "NA",
                  "NA"
               ),
               order = 2
            ),
            title = "Quantiles"
         ),
         color = guide_legend(
            order = 1
         )
      ) +
      theme_minimal() +
      labs(
         x = "Origin year",
         y = "Payments in mio.",
         title = "Actual vs. expected large claims payments"
      ) +
      theme(
         plot.title = element_text(hjust = 0.5),
         panel.grid.minor.x = element_blank(),
         panel.grid.major.x = element_blank()
      )
}
