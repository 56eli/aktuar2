library(sicr)
source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."),
                 "verbesserungen", "B-V02.R"))

set.seed(1)
cal_year_triangle <- matrix(runif(300 * 300), 300, 300)
rownames(cal_year_triangle) <- colnames(cal_year_triangle) <- 1:300

bench::mark(
   original = cal_year2dev_year(cal_year_triangle),
   verbessert = cal_year2dev_year_v(cal_year_triangle),
   check = FALSE,
   iterations = 20
)
