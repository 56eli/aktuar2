# Verbesserung F-V02: Duplikate in plot_reserve_vs_be beseitigen
# Die beiden Balkendiagramme (Reserveklasse / Abwicklungsjahr) waren bis auf
# Gruppierungsvariable, Achsenbeschriftung und Titel identisch. Der gemeinsame
# Aufbau steckt jetzt in einer lokalen Hilfsfunktion; die Grafiken sind gleich.

plot_reserve_vs_be_v <- function(large_claims_list,
                                 sim_result) {
   # Setting arguments to NULL to prevent note in CMD check
   Best_Estimate <- Cl_reserve <- Exit_reserve_class <- Value <- Variable <-
      Dev_year_since_large <- NULL

   large_claims_list$Best_Estimate <- rowSums(sim_result[1:NROW(large_claims_list),
                                                         ,
                                                         c("Claim_payments",
                                                           "Future_annuities_payments")])

   col1 <- rgb(4, 70, 190, maxColorValue = 255)
   col2 <- rgb(191, 191, 191, maxColorValue = 255)

   data_rc <- aggregate(cbind(Best_Estimate, Cl_reserve) ~ Exit_reserve_class,
                        large_claims_list,
                        sum)
   data_dy <- aggregate(cbind(Best_Estimate, Cl_reserve) ~ Dev_year_since_large,
                        large_claims_list,
                        sum)

   make_bar_plot <- function(data, x_col, x_lab, title, x_breaks) {
      data_longer <- pivot_longer(data,
                                  cols = c(Best_Estimate, Cl_reserve),
                                  names_to = "Variable",
                                  values_to = "Value")
      data_longer$Group <- data_longer[[x_col]]
      ggplot(data_longer,
             aes(x = Group, y = Value, fill = Variable)) +
         geom_bar(stat = "identity", position = position_dodge()) +
         labs(x = x_lab,
              y = "Reserves (EUR million)",
              fill = NULL,
              title = title) +
         scale_fill_manual(values = c("Best_Estimate" = col1,
                                      "Cl_reserve" = col2),
                           labels = c("Best_Estimate" = "Best Estimates",
                                      "Cl_reserve" = "Claims reserves")) +
         scale_x_continuous(labels = x_breaks, breaks = x_breaks) +
         scale_y_continuous(labels = function(x) format(x / 1e6,
                                                        big.mark = ".",
                                                        decimal.mark = ",",
                                                        scientific = FALSE)) +
         theme_minimal() +
         theme(legend.position = "right",
               plot.title = element_text(hjust = 0.5),
               panel.grid.minor.y = element_blank(),
               panel.grid.minor.x = element_blank(),
               panel.grid.major.x = element_blank())
   }

   plot_rc <- make_bar_plot(data_rc,
                            "Exit_reserve_class",
                            "Reserve class",
                            "Best estimates und reserves per reserve class",
                            0:(max(data_rc$Exit_reserve_class) + 1))
   plot_dy <- make_bar_plot(data_dy,
                            "Dev_year_since_large",
                            "Development Year",
                            "Best estimates und reserves per development year",
                            1:(max(data_dy$Dev_year_since_large) + 1))

   return(list(plot_rc = plot_rc,
               plot_dy = plot_dy))
}
