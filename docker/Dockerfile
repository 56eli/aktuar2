# Reproduzierbare R-Umgebung für die sicr-Analyse (ARM64 und AMD64)
FROM rocker/r-ver:4.4.2
RUN apt-get update && apt-get install -y --no-install-recommends \
      pandoc git pkg-config zlib1g-dev libxml2-dev libssl-dev libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*
# Laufzeitabhängigkeiten von sicr
RUN install2.r --error --skipinstalled --ncpus 2 data.table dplyr tidyr openxlsx2 ggplot2
# Werkzeuge der Analyse: Tests, Benchmarks, Berichte, Code-Metriken
RUN install2.r --error --skipinstalled --ncpus 2 testthat bench knitr rmarkdown ggrepel gridExtra remotes
RUN install2.r --error --skipinstalled --ncpus 2 lintr cyclocomp
RUN R -q -e "remotes::install_github('dskowasch/sicr', ref = 'c0ad2ade80dad83b1d6faec1bd4e34bd20233c92', dependencies = FALSE, upgrade = 'never')" \
    && R -q -e "library(sicr); cat('sicr', as.character(packageVersion('sicr')), '\n')"
ENV HOME=/tmp
WORKDIR /work
