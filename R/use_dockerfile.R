
## from: list of rocker base images to start from

use_dockerfile <-
  function(
           from = c('r-ver', 'verse', 'shinyverse', 'spatial'),
           r_version = with(R.version, paste(major, minor, sep = '.'))
           ){
    dockerfile_lines <-
      c(paste0('FROM ', 'rocker/', from[1], ':', r_version),
        "RUN echo \"options(repos = c(CRAN = 'https://cran.rstudio.com/'), prompt='R > ', download.file.method = 'libcurl')\" > /.Rprofile",
        "ENV R 'R --no-environ --no-site-file --no-restore --quiet --no-save'",
        "RUN $R -e \"source('https://install-github.me/cole-brokamp/dep@0.1.1')\"",
        "COPY DESCRIPTION /workdir/",
        "RUN $R -e \"dep::loy('/workdir')\""
        ## RUN useradd --create-home appuser
        ## WORKDIR /home/appuser
        ## USER appuser
        "COPY . /workdir",
        "WORKDIR /workdir",
        "CMD [ \"R\", \"--quiet --no-save --no-restore\" ]"
        )
    ## TODO should the workdir used to install the project contain all the R files and data?
    ## or should only the DESC file be copied over to bootstrap the library and then the other files will be available as a mounted drive?  (drive will have to be mounted anyway to support output files...)

    cat(dockerfile_lines, file = 'Dockerfile', sep = '\n')
  }

use_docker_compose_file <-
  function(){
    ## TODO: write function that will create docker-compose file
    ## this would autofill in the correct defaults for "docker run" and also map $PWD to /workdir in the container
    }
