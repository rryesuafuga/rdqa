# ============================================================================
# RDQA Web Tool — Dockerfile
# For Hugging Face Spaces or any Docker-based hosting
# ============================================================================
FROM rocker/shiny:4.4.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN install2.r --error --skipinstalled \
    shiny bslib htmltools DT \
    dplyr tidyr purrr lubridate stringr \
    ggplot2 plotly scales \
    rmarkdown knitr \
    httr jsonlite \
    dhis2r khisr remotes

# Install GitHub packages (optional, non-fatal)
RUN R -e "tryCatch(remotes::install_github('pepfar-datim/datimutils', upgrade='never'), error=function(e) message('datimutils skipped'))" && \
    R -e "tryCatch(remotes::install_github('pepfar-datim/datimvalidation', upgrade='never'), error=function(e) message('datimvalidation skipped'))" && \
    R -e "tryCatch(remotes::install_github('grlurton/dhisextractr', upgrade='never'), error=function(e) message('dhisextractr skipped'))"

# Copy app files
RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

# Expose Shiny Server port
EXPOSE 3838

# Run Shiny Server
CMD ["/usr/bin/shiny-server"]
