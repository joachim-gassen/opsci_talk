# To create this image you need to first install docker (www.docker.com)
# Then, from your command line and being in this folder, run

# docker build -t opsci_talk .

# to force to build, not from cache
# docker build --no-cache -t opsci_talk .

# (do not forget the dot!)

# After the docker image has been built you can run it by

# docker run -d -p 8787:8787 -e PASSWORD=??? --name opsci opsci_talk

# Do not forget to set a password, as depending on your configuration
# the container might be accessible in the network!

# Access your new integrated development environment in your browser
# using the user 'rstudio' and your password from above:

# http://localhost:8787

# If you use docker toolbox, your need to use the IP address of a virtual 
# machine created by docker toolbox instead of localhost. The IP address is 
# displayed in the top of the docker toolbox window with the text

# "docker is configured to use the default machine with IP ...."

# If you do not find it there you can also retrieve it by issuing the following
# command within docker toolbox

# docker-machine ip default

# Access your new integrated development environment in your browser replacing
# XXX.WWW.YYY:ZZZ with your IP adress, the user 'rstudio' and your password from 
# above:

# http://XXX.WWW.YYY.ZZZ:8787


# When you are done, you can stop the container instance

# docker stop opsci

# And (maybe) delete it (ATTENTION: Everything you did in the container is lost)

# docker rm opsci

# If you also want to delete the image that was created from the Dockerfile

# docker image rm opsci_talk


# Below you will find the actual Dockerfile
# It starts with an ubuntu based image that contains RStudio and the tidyverse
# packages

FROM rocker/verse:3.6.2

MAINTAINER Joachim Gassen "gassen@wiwi.hu-berlin.de" 

# Install some additional tools

RUN apt-get update \
  && apt-get install -y --no-install-recommends apt-utils nano curl lbzip2 \
  cargo libudunits2-dev libgdal-dev libproj-dev  \
  python3-pip python3-tk libpython3-dev ffmpeg imagemagick 

# Install some additional tex packages

RUN tlmgr option repository ftp://tug.org/historic/systems/texlive/2018/tlnet-final
RUN tlmgr update --self
RUN tlmgr update --all

RUN tlmgr install multirow xcolor colortbl wrapfig float tabu varwidth \
  threeparttable threeparttablex environ trimspaces ulem makecell endfloat \
  setspace footmisc csquotes beamer translator adjustbox collectbox \
  && tlmgr path add 
  
RUN tlmgr update --self

# Some python packages

RUN pip3 install setuptools wheel 
RUN pip3 install pandas numpy matplotlib scipy seaborn

RUN ln -sf /usr/bin/python3 /usr/bin/python

# And some R packages
# Normally, it would be better to use a snapshot repository to ensure
# reproducibility but mran has been offline from time to time recently
# c(CRAN = 'https://mran.microsoft.com/snapshot/2020-03-12')

RUN  R -e "install.packages(c('ExPanDaR', 'rvest', 'wbstats', 'zoo', \
  'tufte', 'RSelenium', 'knitr', 'kableExtra', 'testthat'), \
  repos = c(CRAN = 'https://cran.uni-muenster.de/'))"

RUN R -e "devtools::install_github('joachim-gassen/rdfanalysis', \
  repos = c(CRAN = 'https://cran.uni-muenster.de/'), upgrade = FALSE)"

# Add TinyTex to R PATH 
RUN chown -R rstudio:staff /opt/TinyTeX
RUN sed -i '/^PATH=/ s/$/:\/opt\/TinyTeX\/bin\/x86_64-linux/' /usr/local/lib/R/etc/Renviron

# The below invalidates the cache whenever the head of the Github repo changes
ADD https://api.github.com/repos/joachim-gassen/opsci_talk/git/refs/heads/master version.json  

# Clone the repository of the Open Science talk and setup a project in RStudio
RUN cd /home/rstudio \
  && sudo -H -u rstudio git clone https://github.com/joachim-gassen/opsci_talk.git

# Copy RStudio project and config files to docker
# container so that RStudio starts directly into the project.
# Created in the docker instance after setting up the project and quitting
# the session:
#
# docker exec  -it --user rstudio opsci /bin/bash
# cd && tar cfvz docker_rstudio_conf.tar.gz .rstudio opsci_talk/.Rproj.user opsci_talk/opsci_talk.Rproj

COPY docker_rstudio_conf.tar.gz /home/rstudio/

RUN cd /home/rstudio \
  && sudo -H -u rstudio tar xfvz docker_rstudio_conf.tar.gz \
  && rm docker_rstudio_conf.tar.gz
  
# delete the slides PDF so that it can be recreated
RUN rm /home/rstudio/opsci_talk/slides/opsci_talk_slides.pdf

