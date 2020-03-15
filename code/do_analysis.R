# ------------------------------------------------------------------------------
#
# (c) Joachim Gassen 2020 
#     gassen@wiwi.hu-berlin.de 
#     See LICENSE file for details
#
# This code prepares the sample, runs the analysis and produces the tables
# for the case study used in the talk
# --- Setup --------------------------------------------------------------------

library(dplyr)
library(readr)
library(tidyr)
library(ExPanDaR)

display_html_viewer <- function(raw_html) {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  html_file <- file.path(temp_dir, "index.html")
  writeLines(raw_html, html_file)
  viewer <- getOption("viewer")
  viewer(html_file)
}


# --- Prepare Sample -----------------------------------------------------------

read_csv("data/restrans_data.csv", col_types = cols()) %>%
  mutate_at(c("country", "year"), as.factor) %>%
  mutate_at(c("life_expectancy", "gdp_capita",
              "mn_yrs_school", "unemployment"), list(ln = log)) -> smp_all

smp_no_na <- smp_all %>% na.omit

var_def <- read_csv("data/restrans_data_def.csv", col_types = cols())

for (var in c("life_expectancy", "gdp_capita", 
              "mn_yrs_school", "unemployment")) {
  var_def <- rbind(var_def,
                   list(paste0(var, "_ln"), 
                        paste("Log-transformed version of", var), "numeric", 1))
}


# --- Prepare Descriptive Table ------------------------------------------------

df <- smp_no_na %>% 
  select(life_expectancy, gdp_capita, mn_yrs_school, unemployment) %>%
  mutate(gdp_capita = gdp_capita/1000)

t <- prepare_descriptive_table(df)
display_html_viewer(t$kable_ret)


# --- Prepare Regression Results Table -----------------------------------------

res <-  prepare_regression_table(
  smp_no_na,
  dvs = rep("life_expectancy", 4),
  idvs = list(
    "gdp_capita_ln", 
    c("gdp_capita_ln", "mn_yrs_school_ln", "unemployment_ln"),
    c("gdp_capita_ln", "mn_yrs_school_ln", "unemployment_ln"),
    c("gdp_capita_ln", "mn_yrs_school_ln", "unemployment_ln")
  ),
  feffects = list("", "", "year", c("country", "year")),
  clusters = list("", "", "year", c("country", "year")),
  format = "html"
)

display_html_viewer(res$table)


# --- Confidence Interval of GDP per Capita Effect across all models -----------

min_est = min(confint(res$models[[1]]$model)[2, 1],
              confint(res$models[[2]]$model)[2, 1],
              confint(res$models[[3]]$model)[1, 1],
              confint(res$models[[4]]$model)[1, 1])

max_est = max(confint(res$models[[1]]$model)[2, 2],
              confint(res$models[[2]]$model)[2, 2],
              confint(res$models[[3]]$model)[1, 2],
              confint(res$models[[4]]$model)[1, 2])

cat(sprintf(paste("\nMinium lower CI for effect of 10 %% increase in GDP",
                  "on life expectancy in years: %.2f\n\n"), 
            min_est*log(1.1)))
cat(sprintf(paste("\nMaximum upper CI for effect of 10 %% increase in GDP",
                  "on life expectancy in years: %.2f\n\n"), 
            max_est*log(1.1)))

# --- Start ExPanD for exploration and robustness assessment -------------------

conf_list <- readRDS("raw_data/ExPanD_config.RDS")
ExPanD(smp_no_na, df_def = var_def, config_list = conf_list,
       title = "Explore the Preston Curve", 
       components = c(sample_selection = FALSE, missing_values = FALSE))
