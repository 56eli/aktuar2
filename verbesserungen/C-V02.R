# Verbesserung C-V02 (effizienter, weniger Abhaengigkeiten)
# ibnr_transform2dataframe() (R/ibnr.R:233-251) erzeugt aus der gerundeten Matrix
# zunaechst eine Tabelle (as.table/as.data.frame), benennt sie mit dplyr um und
# expandiert sie mit tidyr::uncount(). Das laesst sich direkt mit base-R erledigen:
# expand.grid() in derselben Reihenfolge wie as.vector() (das Anfalljahr laeuft am
# schnellsten, weil die Matrix spaltenweise gefuellt wird) und rep().
# Ergebnis (Spalten, Reihenfolge, Typen) ist identisch, aber ohne dplyr/tidyr und
# ohne den Umweg ueber Faktoren.

ibnr_transform2dataframe_v <- function(expected_rounded_ibnr_numbers){
   last_orig_year <- max(as.integer(rownames(expected_rounded_ibnr_numbers)))

   # Reihenfolge wie as.vector(matrix): Origin_year laeuft am schnellsten
   grid <- expand.grid(Origin_year = as.integer(rownames(expected_rounded_ibnr_numbers)),
                       Dev_year_of_growing_large = as.integer(colnames(expected_rounded_ibnr_numbers)),
                       KEEP.OUT.ATTRS = FALSE,
                       stringsAsFactors = FALSE)
   numbers <- as.vector(expected_rounded_ibnr_numbers)
   grid <- grid[rep(seq_len(NROW(grid)), numbers), , drop = FALSE]

   grid$Dev_year_since_large <- last_orig_year - grid$Origin_year - grid$Dev_year_of_growing_large + 2
   grid <- grid[order(-grid$Origin_year, grid$Dev_year_of_growing_large), , drop = FALSE]

   rownames(grid) <- NULL
   return(grid)
}
