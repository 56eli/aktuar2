library(sicr)

test_that("B-V01 tail_factor_v liefert dieselben Faktoren wie tail_factor", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."),
                    "verbesserungen", "B-V01.R"))

   dev_years <- c(0, 16, 17, 18, 25, 49, 50, 51, 100, NA_real_)
   expect_equal(tail_factor_v(dev_years, 17, 50),
                tail_factor(dev_years, 17, 50))

   expect_equal(tail_factor_v(c(16, 17, 18), 17, 17),
                tail_factor(c(16, 17, 18), 17, 17))

   expect_equal(tail_factor_v(c(20, 50, 60), 17, 50),
                tail_factor(c(20, 50, 60), 17, 50))
})
