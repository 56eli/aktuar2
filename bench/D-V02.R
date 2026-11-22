library(sicr)
source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-V02.R"))

best_estimate <- rep(1000, 60)
pattern <- c(1.7, 1.3, 1.1, 1.05, rep(1, 45))
dev_year <- 60:1

bench::mark(
   original = sicr:::rollout_best_estimate(best_estimate, pattern, dev_year),
   verbessert = rollout_best_estimate_v(best_estimate, pattern, dev_year),
   check = FALSE,
   iterations = 20)
