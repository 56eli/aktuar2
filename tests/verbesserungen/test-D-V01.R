library(testthat)
library(sicr)

test_that("D-V01: generate_annuity_payments_v liefert dasselbe wie das Original", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-V01.R"))

   annuities <- sicr::minimal_active_annuities_xmpl

   expect_equal(generate_annuity_payments_v(annuities = annuities,
                                            last_orig_year = 2023),
                generate_annuity_payments(annuities = annuities,
                                          last_orig_year = 2023))

   expect_equal(generate_annuity_payments_v(annuities = annuities,
                                            last_orig_year = 2025,
                                            indices = sicr::indices_xmpl),
                generate_annuity_payments(annuities = annuities,
                                          last_orig_year = 2025,
                                          indices = sicr::indices_xmpl))

   # Start in der Vergangenheit, Ende in der Zukunft, Dynamik
   annuity <- annuities[1, ]
   annuity$Annuity_start <- 2019L
   annuity$Annuity_end <- 2026L
   annuity$Dynamic <- 0.03
   expect_equal(generate_annuity_payments_v(annuities = annuity,
                                            last_orig_year = 2023),
                generate_annuity_payments(annuities = annuity,
                                          last_orig_year = 2023))

   # Start in der Zukunft
   annuity$Annuity_start <- 2027L
   annuity$Annuity_end <- 2029L
   annuity$Dynamic <- 0
   expect_equal(generate_annuity_payments_v(annuities = annuity,
                                            last_orig_year = 2023,
                                            indices = sicr::indices_xmpl),
                generate_annuity_payments(annuities = annuity,
                                          last_orig_year = 2023,
                                          indices = sicr::indices_xmpl))

   # Zukunftige Renten aus dem Pool (Eintrittsjahr wird mitgezaehlt)
   expect_equal(generate_annuity_payments_v(annuities = annuities,
                                            last_orig_year = 2023,
                                            indices = sicr::indices_xmpl,
                                            future_annuities = TRUE),
                generate_annuity_payments(annuities = annuities,
                                          last_orig_year = 2023,
                                          indices = sicr::indices_xmpl,
                                          future_annuities = TRUE))

   expect_null(generate_annuity_payments_v(annuities = annuities[0, ],
                                           last_orig_year = 2023))
})
