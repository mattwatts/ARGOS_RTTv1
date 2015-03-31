# ARGOS Real Time Tracking rev 1

require(shiny)
require(sqldf)
library(dismo)
library(raster)
library(rgdal)

cat("\n")
cat(sArgosDir)
cat("\n")

FetchARGOS <- function()
{
        # update ARGOSlog.sh so it has the correct day of year indicating 9 days before present
        shfile <- ("ARGOSlog.sh")
        editsh <- unlist(strsplit(readChar(shfile,file.info(shfile)$size),split="\n"))
        prvcmd <- which(regexpr("echo prv/c,,ds,",editsh)==1)
        editsh[prvcmd] <- paste0("echo prv/c,,ds,",as.numeric(strftime(Sys.time(), format = "%j")) - 9)
        writeChar(paste(editsh,collapse="\n"),shfile)

        # call the shell scripts to run a telnet session and generate a logfile
        cat("telnet start\n")
        system("./getARGOS.sh > logfile.txt")
        cat("telnet end\n")
        
        # read the logfile and process it
        infile <- "logfile.txt"
        loglines <- unlist(strsplit(readChar(infile,file.info(infile)$size),split="\r\n"))

        # find the start and end of the positional data
        startend <- which(regexpr("ARGOS READY",loglines)==1)
        if (length(startend) != 2)
        {
            print("bad telnet data")
        } else {
            print("good telnet data")
            iStart <- startend[1] + 2
            iEnd <- startend[2] - 1

            # create output file for positional fixes
            write("ProgramNo,PlatformNo,SatelliteID,LocationClass,Date,Time,Latitude,Longitude",
                  file="tracks.csv")

            # sequentially process the positional data
            iIgnoreLine <- 0
            for (i in iStart:iEnd)
            {
                if (iIgnoreLine == 0)
                {
                    # this line is a positional fix
                    tokens <- unlist(strsplit(loglines[i],split=" "))
                    iIgnoreLine <- as.integer(tokens[3])-1
                    if (length(tokens) == 12)
                    {
                        # this line has positional data
                        # append to output file for positional data
                        write(paste(tokens[1],tokens[2],tokens[5],tokens[6],tokens[7],tokens[8],tokens[9],tokens[10],sep=","),
                              file="tracks.csv",append=TRUE)
                    } else {
                        # this line doesn't have positional data: ignore
                    }
                  } else {
                      # this line contains sensor information: ignore & decriment the ignore line counter
                      iIgnoreLine <- iIgnoreLine - 1
                }
            }
        }
}

shinyServer(function(input, output, session) {

    #if ((.Platform$pkgType != "mac.binary") && (.Platform$pkgType != "mac.binary.mavericks"))
    #{
    #    # If we are running on the cloud, tell shiny server to start a new thread for the next user who requests this app.
    #    system(paste0("touch ",sBaseDir,sAppName,"/restart.txt"))
    #}

    observe({
    
        input$aupdate

        FetchARGOS()
    })

    outputmap <- reactive({

        input$aupdate

        # load the positional fixes
        tracks <- read.table("tracks.csv",header=TRUE, sep=",")
        
        # generate the colour palette for the animals
        animals <<- sqldf("SELECT DISTINCT PlatformNo from tracks")
        apalette <<- rainbow(nrow(animals))
        
        # fetch the google maps tile
        e <<- extent(min(tracks$Longitude),max(tracks$Longitude),
                     min(tracks$Latitude),max(tracks$Latitude))
        g2 <- gmap(e, type=input$gmtype, z=input$gmzoom, lonlat=TRUE)
        
        # filter location class
        if (input$argoslc == "< 250m")
        {
            tracks <- sqldf("SELECT * from tracks WHERE LocationClass = 3")
        }
        if (input$argoslc == "250m to 500m")
        {
            tracks <- sqldf("SELECT * from tracks WHERE LocationClass = 3 or LocationClass = 2")
        }
        if (input$argoslc == "500m to 1500m")
        {
            tracks <- sqldf("SELECT * from tracks WHERE LocationClass = 3 or LocationClass = 2 or LocationClass = 1")
        }
        if (input$argoslc == "> 1500m")
        {
            tracks <- sqldf("SELECT * from tracks WHERE LocationClass = 3 or LocationClass = 2 or LocationClass = 1 or LocationClass = 0")
        }
        
        # plot the positional fixes
        plot(g2)
        if (nrow(tracks) > 0)
        {
            for (i in 1:nrow(animals))
            {
                animal <- sqldf(paste0("SELECT Latitude, Longitude from tracks WHERE PlatformNo = ",animals[i,1]))
                if (nrow(animal) > 0)
                {
                    points(animal$Longitude,animal$Latitude,col=apalette[i],cex=0.5)
                }
            }
        }
	})

    outputtable <- reactive({

        #input$aupdate

        # make a table with the animal names that is colour coded by the animal colour
        thetable <- data.frame(animals)
        for (i in 1:nrow(thetable))
        {
            thetable[i,1] <- HTML(paste0("<FONT COLOR='",apalette[i],"'>",thetable[i,1],"</FONT>"))
        }
        colnames(thetable)[1] <- "Animal"

        return(thetable)
    })

    output$argosmap <- renderPlot({
        print(outputmap())
    }) #, height=450,width=600)
	
    output$argostable <- renderTable({
        dat <- data.frame(outputtable())
        dat
    }, sanitize.text.function = function(x) x)
})
