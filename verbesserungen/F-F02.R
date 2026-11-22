# Korrektur F-F02: Legende der Quantilsbaender im Einzelschaden-Backtesting
# Die Werte der Baender sind Q75 = 25%-75%, Q90 = 75%-90%, Q99 = 90%-99%.
# Die Legendenbeschriftung war um zwei Baender verschoben.

backtesting_1y_single_per_dev_year_v <- function(sim_result_series_old,
                                               extended_claims_data_new,
                                               reserve_class,
                                               dev_years,
                                               label = "Claim_id") {

   # Setting arguments to NULL to prevent note in CMD check
   Type <- Development_year <- Entry_reserve_class <- Calendar_year <-
      Claim_id <- Dev_year_since_large <- Value <- Cl_payment_cal <- NULL

   # prepare label name for ggplot
   label_var <-  if(label == "Claim_id") {
      sym("Claim_id")
   } else {
      sym("Origin_year")
   }

   # define colors
   col1 <- "#0446BE"
   col2 <- "#4586FB"
   col3 <- "#C1D7FE"

   # pull additional objects from attributes
   last_orig_year <- attr(sim_result_series_old, "last_orig_year") + 1
   large_claims_list <- attr(sim_result_series_old, "large_claims_list")

   # filter to relevant rows
   relevant_rows <- which(large_claims_list$Exit_reserve_class == reserve_class)
   sim_result_series_old <- sim_result_series_old[relevant_rows, 1, , drop = FALSE]
   large_claims_list <- large_claims_list[relevant_rows, , drop = FALSE]

   # Create dataframe
   df_backtesting <- lapply(dev_years, function(dev_year) {
      v_idx <- which(large_claims_list$Dev_year_since_large == (dev_year - 1))

      if (NROW(v_idx) == 0) {
         tibble(
            Development_year = rep(as.character(dev_year), 7),
            Type = c("Expected", "Q1", "Q10", "Q25", "Q75", "Q90", "Q99"),
            Value = rep(0, 7)
         )
      } else {
         # summarize per reserve class
         series_sum <- sim_result_series_old[v_idx, 1, , drop = TRUE]

         # calculate quantiles
         q <- quantile(series_sum, probs = c(0.01, 0.1, 0.25, 0.75, 0.9, 0.99))

         # combine to tibble
         tibble(
            Development_year = as.character(dev_year),
            Type = c("Expected", "Q1", "Q10", "Q25", "Q75", "Q90", "Q99"),
            Value = c(
               mean(series_sum),
               q[1],
               q[2] - q[1],
               q[3] - q[2],
               q[4] - q[3],
               q[5] - q[4],
               q[6] - q[5]
            )
         )
      }
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
                                  "Expected")),
         Development_year = factor(Development_year,
                                   levels = as.character(dev_years))
      ) %>%
      as.data.frame()

   # Filter new data to desired actual payments
   filtered_extended_claims_data <- filter(extended_claims_data_new,
                                           Entry_reserve_class == reserve_class,
                                           Calendar_year == last_orig_year,
                                           Claim_id %in% large_claims_list$Claim_id,
                                           Dev_year_since_large %in% dev_years)

   # plot
   p <-
      ggplot(df_backtesting,
             aes(
                x = as.factor(Development_year),
                y = Value / 1e6)
      ) +
      geom_bar(
         data = filter(df_backtesting,
                       !(Type %in% c("Expected"))
         ),
         aes(
            fill = Type
         ),
         stat = "identity",
         alpha = 1,
         width = 0.8
      ) +
      geom_segment(
         data = filter(df_backtesting,
                       Type %in% c("Expected")
         ),
         aes(
            x = as.numeric(Development_year) - 0.25,
            xend = as.numeric(Development_year) + 0.25,
            y = Value / 1e6,
            yend = Value / 1e6,
            color = Type
         ),
         linewidth = 1.5
      ) +
      geom_point(
         data = filtered_extended_claims_data,
         aes(
            x = as.factor(Dev_year_since_large),
            y = Cl_payment_cal / 1e6,
            color = "Actual"
         ),
         position = position_dodge2(0.2),
         size = 3,
         shape = 21,
         fill = "darkorange"
      )

   if (requireNamespace("ggrepel", quietly = TRUE)) {
      p <- p + ggrepel::geom_text_repel(
         data = filtered_extended_claims_data,
         aes(
            label = !!label_var,
            x = as.factor(Dev_year_since_large),
            y = Cl_payment_cal / 1e6
         ),
         size = 3
      )
   }

   p <- p +
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
            "Q1" = "",
            "Q10" = "",
            "Q25" = "",
            "Q75" = "25% - 75% Quantil",
            "Q90" = "10% - 90% Quantil",
            "Q99" = "1% - 99% Quantil"
         )
      ) +
      guides(
         fill = guide_legend(
            override.aes = list(
               fill = c(col1,
                        col2,
                        col3,
                        "NA",
                        "NA",
                        "NA"
               )
            ),
            title = "Quantiles",
            order = 2),
         color = guide_legend(
            title = "",
            order = 1,
            override.aes = list(
               shape = c(19, 21),
               linetype = c(1, 1),
               color = c("black", "white"),
               fill = c("NA", "darkorange")
            )
         )
      ) +
      scale_color_manual(values = c("Expected" = "black",
                                    "Actual" = "darkorange")
      ) +
      theme_minimal(
      ) +
      labs(
         x = "Development year as large claim",
         y = "Payments in mio.",
         title = "Actual vs. expected for single large claims",
         subtitle = paste(sep = "",
                          "Reserve class ", reserve_class)
      ) +
      theme(
         plot.title = element_text(hjust = 0.5),
         plot.subtitle = element_text(hjust = 0.5),
         panel.grid.minor.x = element_blank(),
         panel.grid.major.x = element_blank()
      )
   return(p)
}
