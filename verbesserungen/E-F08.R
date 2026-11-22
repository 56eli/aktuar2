# E-F08: Korrektur zu add_sicr_worksheet() (R/Excel_Output.R:95)
# Fehler: `options("openxlsx2.string_nums" = TRUE)` setzt eine globale Option der Session und
# wird nie zurueckgesetzt. Nach dem Schreiben eines Worksheets sind damit alle spaeteren
# openxlsx2-Aufrufe des Nutzers (auch fuer andere Arbeitsmappen) still veraendert.
# Korrektur: alten Wert merken und beim Verlassen der Funktion wiederherstellen.

add_sicr_worksheet_v <- function(workbook, sheetname, payments, reserved = NULL) {
   old_option <- getOption("openxlsx2.string_nums")
   on.exit({
      if (is.null(old_option)) {
         options(openxlsx2.string_nums = NULL)
      } else {
         options(openxlsx2.string_nums = old_option)
      }
   }, add = TRUE)

   add_sicr_worksheet(workbook = workbook,
                      sheetname = sheetname,
                      payments = payments,
                      reserved = reserved)
}
