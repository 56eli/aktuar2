# Verbesserung F-V01: Poolgroessen im Pool-Ueberblick vektoriell aufbauen
# Die verschachtelte rbind-Schleife ist O(n_rc * n_dy) mit wiederholtem Kopieren
# des data.frame. Die vektorisierte Variante erzeugt dieselben vier Grafiken.

plot_pools_overview_v <- function(pools,
                                large_claims_list) {
   # Setting variables to NULL to prevent note in CMD check
    Development_year <- Observations <- Reserve_class <- Value <- Category <-
       Cl_reserve <- Exit_reserve_class <- NULL

   # define color palette
   palette <- c(rgb(64, 64, 64, maxColorValue = 255),
                rgb(89, 89, 89, maxColorValue = 255),
                rgb(2, 35, 95, maxColorValue = 255),
                rgb(3, 53, 142, maxColorValue = 255),
                rgb(4, 70, 190, maxColorValue = 255),
                rgb(69, 134, 251, maxColorValue = 255),
                rgb(131, 174, 252, maxColorValue = 255),
                rgb(193, 215, 254, maxColorValue = 255),
                rgb(127, 127, 127, maxColorValue = 255),
                rgb(191, 191, 191, maxColorValue = 255),
                rgb(217, 217, 217, maxColorValue = 255))

   # extract parameters from pools
   reserve_classes <- attr(pools, "reserve_classes")
   start_of_tail <- attr(pools, "start_of_tail")
   end_of_tail <- attr(pools, "end_of_tail")


   # pool sizes
   n_rc <- length(reserve_classes)
   n_dy <- start_of_tail - 2
   #pool_sizes <- matrix(nrow = n_dy, ncol = n_rc)
   # Poolgroessen vektoriell statt mit verschachtelter rbind-Schleife
   df_pool_sizes <- do.call(rbind, lapply(n_rc:1, function(rc) {
      data.frame(Reserve_class = factor(rc),
                 Development_year = factor(2:(n_dy + 1)),
                 Observations = vapply(1:n_dy,
                                       function(dy) NROW(pools[[1]][[rc + 1]][[dy]]),
                                       integer(1)))
   }))

   # numbers of observations overview
   plot_obs_numbers <-
      ggplot(
         df_pool_sizes,
         aes(x = Development_year,
             y = Observations,
             fill = Reserve_class)
      ) +
      geom_bar(
         stat = "identity",
         position = "stack"
      ) +
      scale_fill_manual(
         values = palette
      ) +
      labs(
         x = "Development year since large",
         y = NULL,
         title = "Number of historic observations"
      ) +
      theme_minimal() +
      theme(
         plot.title = element_text(hjust = 0.5),
         panel.grid = element_blank()
      ) +
      geom_text(
         aes(label = Observations),
         position = position_stack(vjust = 0.5),
         col = "white",
         size = 3.5,
         fontface = "italic"
      )

   rc_stack <- diff(reserve_classes)
   rc_stack <- c(rc_stack, rc_stack[length(rc_stack)])

   data <- data.frame(Category = factor(paste("RC", c(1:n_rc))),
                      Value = rc_stack * 1e-6)

   # change levels
   data$Category <- factor(data$Category,
                           levels = rev(levels(data$Category)))

   # simple stack plot
   plot_stack <-
      ggplot(data,
             aes(x = 1,
                 y = Value,
                 fill = Category)
      ) +
      geom_bar(
         stat = "identity",
         position = "stack"
      ) +
      labs(
         x = NULL,
         y = "EUR million",
         title = NULL
      ) +
      scale_fill_manual(
         values = palette
      ) +
      theme_minimal() +
      scale_y_continuous(
         breaks = reserve_classes/1e6,
         labels = round(reserve_classes/1e6, 1)
      ) +
      geom_text(
         aes(label = Category),
         position = position_stack(vjust = 0.5),
         col = "white",
         size = 3.5,
         fontface = "bold"
      ) +
      theme(
         axis.text.x = element_blank(),
         axis.ticks.x = element_blank(),
         panel.grid = element_blank(),
         axis.title.x = element_blank(),
         legend.position = "none"
      )

   # Reserves allocation
   reserves_allocation <-
      aggregate(Cl_reserve ~ Exit_reserve_class,
                large_claims_list[large_claims_list$Cl_reserve > 0,],
                sum)

   reserves_allocation$Cl_reserve <-
      reserves_allocation$Cl_reserve / sum(reserves_allocation$Cl_reserve)
   reserves_allocation$Exit_reserve_class <-
      factor(paste("RC",
                   reserves_allocation$Exit_reserve_class,
                   "\n",
                   format(round(reserves_allocation$Cl_reserve * 100, 0), nsmall = 0),
                   "%"))
   reserves_allocation$Exit_reserve_class <-
      factor(reserves_allocation$Exit_reserve_class,
             levels = rev(levels(reserves_allocation$Exit_reserve_class)))

   plot_reserves_allocation <-
      ggplot(
         reserves_allocation,
         aes(x = "",
             y = Cl_reserve,
             fill = Exit_reserve_class)
      ) +
      geom_bar(
         stat = "identity",
         width = 1,
         linewidth = 1,
         color = "white"
      ) +
      coord_polar(theta = "y") +
      scale_fill_manual(values = palette) +
      geom_text(
         aes(label = Exit_reserve_class),
         position = position_stack(vjust = 0.5),
         col = "white",
         size = 3.5,
         fontface = "bold"
      ) +
      labs(
         x = NULL,
         y = NULL,
         title = "Reserves"
      ) +
      theme_minimal() +
      theme(
         plot.title = element_text(hjust = 0.5),
         axis.text.x = element_blank(),
         panel.grid = element_blank(),
         legend.position = "none"
      )

   # Number allocation
   numbers_allocation <-
      aggregate(Cl_reserve/Cl_reserve ~ Exit_reserve_class,
                large_claims_list[large_claims_list$Cl_reserve > 0,],
                sum)
   numbers_allocation$Cl_reserve <-
      numbers_allocation$Cl_reserve / sum(numbers_allocation$Cl_reserve)

   numbers_allocation$Exit_reserve_class <-
      factor(paste("RC",
                   numbers_allocation$Exit_reserve_class,
                   "\n",
                   format(round(numbers_allocation$Cl_reserve * 100, 0), nsmall = 0),
                   "%"))

   numbers_allocation$Exit_reserve_class <-
      factor(numbers_allocation$Exit_reserve_class,
             levels = rev(levels(numbers_allocation$Exit_reserve_class)))


   plot_numbers_allocation <-
      ggplot(
         numbers_allocation,
         aes(
            x = "",
            y = Cl_reserve,
            fill = Exit_reserve_class)
      ) +
      geom_bar(
         stat = "identity",
         width = 1,
         linewidth = 1,
         color = "white"
      ) +
      coord_polar(theta = "y") +
      scale_fill_manual(values = palette) +
      geom_text(
         aes(label = Exit_reserve_class),
         position = position_stack(vjust = 0.5),
         col = "white",
         size = 3.5,
         fontface = "bold"
      ) +
      labs(
         x = NULL,
         y = NULL,
         title = "Number of open claims"
      ) +
      theme_minimal() +
      theme(
         plot.title = element_text(hjust = 0.5),
         axis.text.x = element_blank(),
         panel.grid = element_blank(),
         legend.position = "none"
      )
   return(
      list(
         plot_obs_numbers = plot_obs_numbers,
         plot_stack = plot_stack,
         plot_reserves_allocation = plot_reserves_allocation,
         plot_numbers_allocation = plot_numbers_allocation))
}
