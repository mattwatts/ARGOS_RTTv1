# ARGOS Real Time Tracking rev 1

library(shiny)

cat(paste0("hello\n"))
cat(paste0(getwd(),"\n"))

sBaseName <<- "ARGOS"
sAppName <<- "ARGOS_RTTv1"

# Gfold = Global folder name
setwd("./p")
Gfold <- sprintf("%s",round(runif(1)*1000000))

sPath <- "/mnt/shiny/"

for (ii in 1:100000){
  if(!file.exists(sprintf("%s%s",sPath,Gfold))) {
    system(paste("mkdir ",sprintf("%s%s",sPath,Gfold)))
    break()
  }
}
system(paste("cp -r files/* " , sprintf("%s%s",sPath,Gfold)))
cat(paste0(sPath,Gfold,"\n"))
setwd(sprintf("%s%s",sPath,Gfold))

sUserID <<- Gfold

sArgosDir <- getwd()

#if ((.Platform$pkgType == "mac.binary") || (.Platform$pkgType == "mac.binary.mavericks"))
#{
#    sBaseDir <<- "/Users/matt/Documents/ARGOS_software_10Sept2014/ARGOS_RTTv1/"
#} else {
#    sBaseDir <<- paste0("/var/shiny-server/www/",sBaseName,"/")
#}
