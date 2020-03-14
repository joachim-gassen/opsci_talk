# ------------------------------------------------------------------------------
#
# (c) Joachim Gassen 2020
#     gassen@wiwi.hu-berlin.de
#     See LICENSE file for details
#
# This code pulls the data for the case study used in the talk 
# from public sources
#
# Requires a Selenium docker container to be present to pull the Wittgenstein
# Centre Data
#
# docker run -d -p 4445:4444 
#   -v PROJECTPATH/raw_data:/home/seluser/Downloads 
#   selenium/standalone-firefox:2.53.1
#
# --- Setup --------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(readr)
library(rvest)
library(wbstats)
library(RSelenium)
library(zoo)

# Set the below to TRUE if you want to repull the data from the 'raw_data' 
# directory. 

# NOTE: Scraping the data of the Wittgenstein Center is somewhat flaky and 
# is likely to break as the web page might and will change.

pull_data <- FALSE

if (!pull_data) {
  files <- list.files("raw_data", "restrans_data_def_2", full.names = TRUE)
  invisible(file.copy(files[length(files)], 
                      "data/restrans_data_def.csv", overwrite = TRUE))
  files <- list.files("raw_data", "restrans_data_2", full.names = TRUE)
  invisible(file.copy(files[length(files)], 
                      "data/restrans_data.csv", overwrite = TRUE))
} else {

  # --- Pull world Bank Data ---------------------------------------------------
  
  pull_worldbank_data <- function(vars) {
    new_cache <- wbcache()
    all_vars <- as.character(unique(new_cache$indicators$indicatorID))
    data_wide <- wb(indicator = vars, mrv = 70, return_wide = TRUE)
    new_cache$indicators[new_cache$indicators[,"indicatorID"] %in% vars, ] %>%
      rename(var_name = indicatorID) %>%
      mutate(var_def = paste(indicator, "\nNote:", 
                             indicatorDesc, "\nSource:", sourceOrg)) %>%
      select(var_name, var_def) -> wb_data_def
    
    new_cache$countries %>%
      select(iso3c, iso2c, country, region, income) -> ctries
    
    left_join(data_wide, ctries, by = "iso3c") %>%
      rename(year = date,
             iso2c = iso2c.y,
             country = country.y) %>%
      select(iso3c, iso2c, country, region, income, everything()) %>%
      select(-iso2c.x, -country.x) %>%
      filter(!is.na(NY.GDP.PCAP.KD),
             region != "Aggregates") -> wb_data
    
    wb_data$year <- as.numeric(wb_data$year)
    
    wb_data_def<- left_join(data.frame(var_name = names(wb_data), 
                                       stringsAsFactors = FALSE), 
                            wb_data_def, by = "var_name")
    wb_data_def$var_def[1:6] <- c(
      "Three letter ISO country code as used by World Bank",
      "Two letter ISO country code as used by World Bank",
      "Country name as used by World Bank",
      "World Bank regional country classification",
      "World Bank income group classification",
      "Calendar year of observation"
    )
    wb_data_def$type = c("cs_id", rep("factor",  4), "ts_id",
                         rep("numeric", ncol(wb_data) - 6))
    return(list(wb_data, wb_data_def))
  }
  
  vars <- c("SP.DYN.LE00.IN", "NY.GDP.PCAP.KD", "SL.UEM.TOTL.ZS")
  wb_list <- pull_worldbank_data(vars)
  wb_data <- wb_list[[1]]
  wb_data_def <- wb_list[[2]]
  
  
  # --- Pull Wittgenstein Centre Data ------------------------------------------

  # The Homepage: http://dataexplorer.wittgensteincentre.org/wcde-v2/
  # offers access via a Shiny app. We use a headless browser to download the 
  # data. If you want to download the data by hand make sure that you also 
  # download the two-digit country ISO code (can be selcted in the Data tab)
  
  prefs <- makeFirefoxProfile(list(
    browser.download.dir = "/home/seluser/Downloads",
    "browser.download.folderList" = 2L,
    "browser.download.manager.showWhenStarting" = FALSE,
    "browser.helperApps.neverAsk.saveToDisk" = "application/csv, text/csv"
  ))
  
  rem_dr <- remoteDriver(
    remoteServerAddr = "localhost",
    port = 4445,
    extraCapabilities = prefs, 
    browserName = "firefox"
  )
  
  rem_dr$open(silent = TRUE)
  rem_dr$navigate("http://dataexplorer.wittgensteincentre.org/wcde-v2/")
  
  click_element <- function(selector, dr = rem_dr) {
    web_elem <- dr$findElement(using = "css selector", selector)
    web_elem$clickElement()
    Sys.sleep(max(0.5, rnorm(1, 1, 0.3)))
  } 
  
  tab_id_elem <- rem_dr$findElement(using = "css selector", 
                                    "body > div.container > div")
  tab_no <- unlist(tab_id_elem$getElementAttribute("data-tabsetid"))
  
  tab_data_id_elem <- rem_dr$findElement(
    using = "css selector", 
    sprintf("#tab-%s-1 > div.tabbable > ul", tab_no)
  )
  tab_data_no <- unlist(tab_data_id_elem$getElementAttribute("data-tabsetid"))
  
  
  elements_to_click <- c(
    sprintf('#tab-%s-1 > div > div:nth-child(1) > div:nth-child(5) > div', tab_data_no),
    sprintf(paste(
      '#tab-%s-1 > div > div:nth-child(1) > div:nth-child(5) > div > div >', 
      'div.selectize-dropdown.single.form-control.shiny-bound-input > div >',
      'div:nth-child(2) > div:nth-child(5)'
    ), tab_data_no),
    sprintf('#tab-%s-1 > div > div:nth-child(2) > div:nth-child(6)', tab_data_no),
    sprintf('#tab-%s-1 > div > div:nth-child(2) > div:nth-child(5)  > div', tab_data_no),
    sprintf(paste(
      '#tab-%s-1 > div > div:nth-child(2) > div:nth-child(5) > div > div >', 
      'div.selectize-dropdown.multi.form-control.shiny-bound-input > div >',
      'div.option'
    ), tab_data_no),
    sprintf('#tab-%s-1 > div > div:nth-child(4) > div:nth-child(6)', tab_data_no),
    sprintf('#tab-%s-1 > div.tabbable > ul > li:nth-child(2)', tab_no),
    sprintf('#tab-%s-2 > div.col-sm-3 > div.form-group.shiny-input-container > div', tab_data_no),
    '#data_dl'
  )
  
  Sys.sleep(5)
  invisible(sapply(elements_to_click, click_element))
  Sys.sleep(2)
  rem_dr$close()
  
  witcentdata <- read_csv("raw_data/wicdf.csv", col_types = cols(), skip = 8) %>%
    rename(country = Area,
           year = Year,
           un_m49 = ISOCode,
           mn_yrs_schooling_15p = Years) %>%
    select(un_m49, country, year, mn_yrs_schooling_15p)
  
  
  # --- Merge Data and Store it in data directory --------------------------------
  
  ctry_ids <- read_html("https://unstats.un.org/unsd/methodology/m49/") %>%
    html_table()
  un_m49 <- ctry_ids[[1]]
  colnames(un_m49) <- c("country", "un_m49", "iso3c")
  
  df <- wb_data %>% left_join(un_m49, by = "iso3c") %>%
    left_join(witcentdata, by = c("un_m49", "year")) %>%
    arrange(country.x, year) %>%
    group_by(country.x) %>%
    mutate(mn_yrs_school = na.approx(mn_yrs_schooling_15p, 
                                     maxgap = 4, na.rm = FALSE))
  
  df <- df[,c(1, 3:9, 14)]
  colnames(df)[c(2,6,7,8)] <- c("country", "gdp_capita", "unemployment",
                                "life_expectancy")
  df <- df[, c(1:5, 8, 6, 9, 7)]
  
  write_csv(df, paste0("raw_data/restrans_data_", 
                       substr(Sys.time(), 1, 10), ".csv"))
  write_csv(df, "data/restrans_data.csv")
  
  data_def <- wb_data_def[c(1, 3:6, 9, 7, 8), ] %>%
    add_row(var_name = "mn_yrs_school", 
            var_def = paste(
              "Mean number of years spent in school, age group 15+.",
              "Source: Wittgenstein Centre for Demography and Global Human",
              "Capital (2018). Wittgenstein Centre Data Explorer Version 2.0.",
              "Data between five year intervals are based on linear", 
              "interpolation."
            ), 
            type = "numeric", .after = 7)
  
  data_def$var_name[c(6, 7, 9)] <- c("life_expectancy", "gdp_capita", 
                                     "unemployment")
  
  write_csv(data_def, paste0("raw_data/restrans_data_def_", 
                       substr(Sys.time(), 1, 10), ".csv"))
  write_csv(data_def, "data/restrans_data_def.csv")
}  