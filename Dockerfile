FROM rocker/R-ver:3.5.3
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), prompt='R > ', download.file.method = 'libcurl')" > /.Rprofile
ENV R 'R --no-environ --no-site-file --no-restore --quiet --no-save'
RUN $R -e "source('https://install-github.me/cole-brokamp/dep@0.1.1')"
COPY . /workdir
WORKDIR /app
RUN $R -e "dep::loy('/app')"
