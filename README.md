## A Talk on Open Science (in Business Economics Research)

### Welcome! 

This repository contains the materials for a talk that I (Joachim 
Gassen, Humboldt-Universität zu Berlin and 
[TRR 266 "Accounting for Transparency"](https://www.accounting-for-transparency.de))
have given at the [2020 VHB Conference](https://www.bwl2020.org).

The talk discusses open science related issues and presents a case-study based
open science workflow using a containerized R/RStudio environment. It was 
delivered online as the "offline conference" was canceled due to the COVID-19 
outbreak. 


### TL;DNR

if you are simply looking for the slide deck, it is in the `slides` directory ;-)


### About the repository

In this repo, you will find

-	The code to generate the slides and the slides themselves (`slides`)
- Code for a case study that I use in the talk (`code`). The case study
re-investigates the link between national income and life expectancy
- A docker Makefile that allows you to quickly reproduce all the material 
and analysis contained in the code in a docker container (`docker`).
- Some raw data that the case uses (`raw_data`)
- An empty directory where the code stores data (`data`)
- An empty directory where the code stores output (`output`)


### Reproduce the material of the talk

First you need install docker. When you have a current
new version of MacOS or Windows installed: https://docs.docker.com/get-started/. **Read the introductions
for your operating system.** They are important.

If you happen to have an older version of Windows then docker 
toolbox is your choice: https://docs.docker.com/toolbox/. 
**Read the introductions for your operating system.** They are important.

After installing docker, the quickest way to reproduce the talk is to issue
the following command in your shell/terminal/cmd box. NOTE: Please change
`yourpass` to a meaningful password.

`docker run -d -p 8787:8787 -e PASSWORD=yourpass --name opsci joegassen/opsci_talk`

This will download the docker container and start it up. Alternatively, you can
also build the docker container from scratch using the Dockerfile in the `docker`
directory. Read it for further instructions.

After the docker container has started, use your favorite web browser and
point it to: `https://localhost:8787`. Log in with user 'rstudio' and your 
password from above. Select "Build all" in the top right window. This will 
re-generate the slides.


### Additional things to do

After that you can also take a look at the file `code/case_do_analysis.R`. This
file will generate the base analysis of the case that is also included in the slides
and start an online app based on my 
[ExPanDaR package](https://joachim-gassen.github.io/ExPanDaR/) 
for interactive data exploration.

The code file `code/case_analyze_rdf.R` uses my in-development 
[rdfanalysis package](https://joachim-gassen.github.io/rdfanalysis/index.html) 
to systematically explore the researcher degrees of freedom inherent in the case study. 

If you want to re-pull the case study data from the World Bank and the 
Wittgenstein Center for Demography and Global Human Capital take a look at
`code/case_pull_data.R`. Currently, you cannot re-pull the data simply from within 
docker as the web scraping bit requires an additional docker container to be run.

Feel free to create an issue or a pull request on Github if you have comments
or encounter anything odd.

Enjoy!
