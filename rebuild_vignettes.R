# Adapted from https://www.kloppenborg.ca/2021/06/long-running-vignettes/

base_dir <- getwd()

setwd("vignettes/")
knitr::knit("wsMed.Rmd.original", output = "wsMed.Rmd")
knitr::knit("GenerateModelP.Rmd.original", output = "GenerateModelP.Rmd")
knitr::knit("GenerateModelCN.Rmd.original", output = "GenerateModelCN.Rmd")
knitr::knit("GenerateModelCP.Rmd.original", output = "GenerateModelCP.Rmd")
knitr::knit("GenerateModelPC.Rmd.original", output = "GenerateModelPC.Rmd")
knitr::knit("printGM.Rmd.original", output = "printGM.Rmd")
knitr::knit("MEMORE_vs_wsMed.Rmd.original", output = "MEMORE_vs_wsMed.Rmd")
setwd(base_dir)

# For articles

base_dir <- getwd()

setwd("vignettes/articles")

setwd(base_dir)

setwd(rprojroot::find_rstudio_root_file())
