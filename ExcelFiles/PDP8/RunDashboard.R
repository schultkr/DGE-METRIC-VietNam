# install.packages(c("shiny","bslib","dplyr","tidyr","ggplot2","DT","scales","shinycssloaders"))
libraries <- c(
  "shiny", "bslib", "dplyr", "tidyr", "ggplot2", "DT", "scales", "shinycssloaders"
)

# Install missing packages
lapply(libraries, function(x) {
  if (!(x %in% installed.packages())) install.packages(x)
})

# Load the packages quietly
lapply(libraries, library, quietly = TRUE, character.only = TRUE)

shiny::runApp()
