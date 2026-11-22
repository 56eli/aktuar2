library(sicr)
source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-V01.R"))

annuities <- sicr::minimal_active_annuities_xmpl[rep(1:3, 100), ]

bench::mark(
   original = sicr::generate_annuity_payments(annuities = annuities,
                                              last_orig_year = 2023),
   verbessert = generate_annuity_payments_v(annuities = annuities,
                                            last_orig_year = 2023),
   check = FALSE,
   iterations = 20)
