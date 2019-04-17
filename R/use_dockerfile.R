
## from: list of rocker base images to start from

use_dockerfile <-
  function(from = c('R-ver', 'verse', 'shinyverse', 'spatial'), r_version = with(R.version, paste(major, minor, sep = '.'))){
    dockerfile_lines <-
      c(paste0('FROM ', 'rocker/', from[1], ':', r_version),
        "RUN echo \"options(repos = c(CRAN = 'https://cran.rstudio.com/'), prompt='R > ', download.file.method = 'libcurl')\" > /.Rprofile",
        "ENV R 'R --no-environ --no-site-file --no-restore --quiet --no-save'",
        "RUN $R -e \"install.packages('pak')\"",
        "RUN $R -e \"source('https://install-github.me/cole-brokamp/dep')\"",
        "COPY . /workdir",
        "WORKDIR /app",
        "RUN $R -e \"dep::loy('/app')\""
        )

    cat(dockerfile_lines, file = 'Dockerfile', sep = '\n')
  }
