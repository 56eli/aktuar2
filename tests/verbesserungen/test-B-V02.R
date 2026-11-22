library(sicr)

test_that("B-V02 cal_year2dev_year_v liefert gleiche Dreiecke", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."),
                    "verbesserungen", "B-V02.R"))

   cal_year_triangle <- matrix(c(1000, 0, 0, 200, 800, 0, 100, 100, 900), 3)
   rownames(cal_year_triangle) <- colnames(cal_year_triangle) <- 2012:2014
   expect_equal(cal_year2dev_year_v(cal_year_triangle),
                cal_year2dev_year(cal_year_triangle))

   set.seed(42)
   larger_triangle <- matrix(runif(400), 20, 20)
   rownames(larger_triangle) <- colnames(larger_triangle) <- 2000:2019
   expect_equal(cal_year2dev_year_v(larger_triangle),
                cal_year2dev_year(larger_triangle))
})
