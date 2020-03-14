library(tidyverse)
library(lubridate)

# 'Corporate' colors used by our TRR 266 Accountinig for Transparency project
# See http://www.accounting-for-transparency.de for more info

lighten <- function(color, factor = 0.5) {
  if ((factor > 1) | (factor < 0)) stop("factor needs to be within [0,1]")
  col <- col2rgb(color)
  col <- col + (255 - col)*factor
  col <- rgb(t(col), maxColorValue=255)
  col
}

trr266_petrol <- rgb(27, 138, 143, 255, maxColorValue = 255)
trr266_blue <- rgb(110, 202, 226, 255, maxColorValue = 255)
trr266_yellow <- rgb(255, 180, 59, 255, maxColorValue = 255)
trr266_red <- rgb(148, 70, 100, 255, maxColorValue = 255)
trr266_lightpetrol <- lighten(trr266_petrol, 0.5)

