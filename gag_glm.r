# Set working directory
setwd("W/SEDAR/Updates2014/Gag/Indicies/CommHL/2014GagCommIndex")

# Load packages
require(knitr)
require(markdown)

# Create .md, .html, and .pdf files
knit("gag_glm.rmd")
markdownToHTML('gag_glm.md', 'gag_glm.html', options=c("use_xhml"))
system("pandoc -s gag_glm.html -o gag_glm.pdf")


