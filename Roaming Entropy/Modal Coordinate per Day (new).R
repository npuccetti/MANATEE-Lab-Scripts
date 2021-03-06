setwd("C:/Users/treneau/Dropbox/WCMCseed/Analysis/GPX_AnalysisReneau/workspace")

#decimal to round coordinates to#
decimal <- 4

#create matrix for modal coordinates#
modal_matrix <- matrix(nrow = 0, ncol = 3)

master_df <- read.csv("weather_new_all_cohorts.csv",stringsAsFactors=FALSE)

#create a vector of subject names#
rawData3 <- c("01","02","03","05","06","08","09",10,14,15,16,18,19,24,26,31,32,39,40,41,44,49,50,55,59,60,63,65,67,69,70,71,76,81,83,84,91,92,97,98,99)
rawData1 <- c(1287,1530,1533,1555,1673,1738,1749,1837,1879,1958,1965,1996,2020,2022,2024,2025,2026,2027,2028,2029,2030,2032,2033,2034,2037,2039,2040,2041,2042,2043,2044)
rawData2 <- c(62,60,73,85,74,39,42,14,13,"09",34,48,26,21,19,49,"07",50,"03",27,36,16,22,"08",40,18,"06",53,55,"04","05",41,59,65,23,37,31,61,69,63,72,30,81,79,86,76,89,84,68,87,77,83,82,67,80,88,"01",75,12,17)
 rawData <- c(1287,1530)
 cohortIdentifier <- "SC0"

for(a in 1:3){
  if(a==1){
    rawData <- rawData3
    cohortIdentifier <- "MM10"
  }
  if(a==3){
    rawData <- rawData1
    cohortIdentifier <- "SC0"
  }
  if(a==2){
    rawData <- rawData2
    cohortIdentifier <- "MS10"
  } 
 
#sift through each subject file to extract coordinates and times#
for(q in 1:length(rawData)){
  
#scan file#  
  subjString <- paste(cohortIdentifier,rawData[q], sep = "")
  dataString <- gsub("XX",subjString,"XX_storyline.gpx")
  n <- scan(dataString, character(0), sep = "\n")
  LonVec <- rep(NA,100000)
  LatVec <- rep(NA,100000)
  DateVec <- rep(NA,100000)
  TimeVec <- rep(NA,100000)
  DateTimeVec <- rep(NA,100000)
  TypeVec <- rep(NA,100000)
  a <- 1
  
  #finding data in file and placing it in vectors#
  for(i in 1:length(n)){
    if(grepl("<trkpt ",n[i])){
      
      lonStart <- regexpr('lon="',n[i])[1]
      lonEnd <- regexpr('" ',n[i])[1]
      x <- round(as.numeric(substr(n[i],lonStart+5,lonEnd-1)), digits = decimal)
      
      latStart <- regexpr('lat="',n[i])[1]
      latEnd <- regexpr('">',n[i])[1]
      y <- round(as.numeric(substr(n[i],latStart+5,latEnd-1)), digits = decimal)
      
      dateStart <- regexpr("<time>",n[i+1])[1]
      timeEnd <- regexpr("</time>",n[i+1])[1]
      dateEnd <- regexpr("T",n[i+1])[1]
      dataDate <- substr(n[i+1],dateStart+6,dateEnd-1)
      dataTime <- substr(n[i+1],dateStart+17,timeEnd-1)
      dataDateTime <- substr(n[i+1],dateStart+6,timeEnd-1)
      
      typeEnd <- regexpr("</type>",n[i+2])[1]
      dataType <- substr(n[i+2],15,(typeEnd-1))
      
      if(!is.na(x)&&!is.na(y)&&!is.na(dataDateTime)){
        LonVec[a] <- x
        LatVec[a] <- y
        TypeVec[a] <- dataType
        DateVec[a] <- dataDate
        TimeVec[a] <- dataTime
        DateTimeVec[a] <- dataDateTime
        a <- a+1
      }
    }
  }
  
  LonVec <- LonVec[!is.na(LonVec)]
  LatVec <- LatVec[!is.na(LatVec)]
  DateVec <- DateVec[!is.na(DateVec)]
  TimeVec <- TimeVec[!is.na(TimeVec)]
  DateTimeVec <- DateTimeVec[!is.na(DateTimeVec)]
  TypeVec <- TypeVec[!is.na(TypeVec)]
  
  #create matrix of all coordinates#
  positionMatrix = matrix(
    c(LonVec,LatVec),
    nrow=length(LonVec),
    ncol=2)
  
  #calculate timeframe#
  startDate <- DateVec[1]
  endDate <- DateVec[length(DateVec)]
  totalDays <- as.Date(endDate)-as.Date(startDate)
  
  #calculate total number of minutes during the time of data collection#
  totalMinutes <- as.numeric(totalDays*1440)
  
  #find coordinates with duplicate minutes#
  uniqueMinutes <- 0
  startTime <- TimeVec[1]
  endTime <- TimeVec[length(TimeVec)]
  for(k in 1:length(TimeVec)){
    if(grepl(substr(TimeVec[k],1,5),substr(TimeVec[k+1],1,5))){
      positionMatrix[k,1]<-"remove"
      positionMatrix[k,2]<-"remove"
      DateTimeVec[k] <- "remove"
      DateVec[k] <- "remove"
      TypeVec[k] <- "remove"
    }
    else
      uniqueMinutes <- uniqueMinutes+1
  }
  
  #remove coordinates with duplicate minutes#
  positionMatrix <- positionMatrix[positionMatrix[,1]!="remove",]
  DateTimeVec <-DateTimeVec[DateTimeVec!="remove"]
  DateVec <- DateVec[DateVec!="remove"]
  TypeVec <- TypeVec[TypeVec!="remove"]
  totalDays <- as.Date(endDate)-as.Date(startDate)+1
  
  #create matrix to hold modal coordinate values for all days for that subject#
  REMatrix <- matrix(
    nrow=totalDays,
    ncol=3)
  colnames(REMatrix) <- c("subject","date","avg coordinates")
  date1 <- DateVec[1]
  
  #calculate point matrix for each day#
  for(b in 1:totalDays) {
  
  REMatrix[b,2] <- date1
  REMatrix[b,1] <- subjString
  
  #find data points with given date#
  dataLocation <- character(2000)
  f <- 1
  for (t in 1:length(DateVec)){
    if(DateVec[t]==date1){
      dataLocation[f] <- t
      f <- f +1
    }
  }
  dataLocation <- dataLocation[!dataLocation %in% ""]
  
  #place coordinates in proper timeline (each row of a matrix represents a minute of the timeframe of collected data)#
  if(length(dataLocation) >= 1)
  {
    if(difftime(as.POSIXct(DateTimeVec[as.numeric(dataLocation[length(dataLocation)])],format = "%Y-%m-%dT%H:%M:%S"),as.POSIXct(as.character(date1)),units = "mins")>1440)
      dmsize <- 1500
    else
      dmsize <- 1440
    
    dayMatrix = matrix(
      nrow=dmsize,
      ncol=2
    )
    
    startPoint <- 1
    beginDate <- as.POSIXct(as.character(date1))
    for(u in 1:length(dataLocation)){
      tTest <- as.POSIXct(DateTimeVec[as.numeric(dataLocation[u])],format = "%Y-%m-%dT%H:%M:%S")
      timeInMinutes <- floor(as.numeric(difftime(tTest,beginDate,units = "mins")))+1
      
      if(startPoint==1){
        for(v in 1:(timeInMinutes-1))
          dayMatrix[v,] <- positionMatrix[as.numeric(dataLocation[u]),]
      }
      
      if(u==length(dataLocation)&&startPoint<=dmsize){
        for(w in startPoint:dmsize)
          dayMatrix[w,] <- positionMatrix[as.numeric(dataLocation[u]),]
      }
      
      if(timeInMinutes-startPoint>0&&u!=1&&u!=length(dataLocation)){
        
        previous_lat <- as.numeric(positionMatrix[as.numeric(dataLocation[u])-1,1])
        current_lat <- as.numeric(positionMatrix[as.numeric(dataLocation[u]),1])
        previous_lon <- as.numeric(positionMatrix[as.numeric(dataLocation[u])-1,2])
        current_lon <- as.numeric(positionMatrix[as.numeric(dataLocation[u]),2])
        previous_time <- startPoint-1
        current_time <- timeInMinutes
        avg_lat_velocity <- (current_lat-previous_lat)/(current_time-previous_time)
        avg_lon_velocity <- (current_lon-previous_lon)/(current_time-previous_time)
        
        for(z in startPoint:(timeInMinutes-1)){
          dayMatrix[z,1] <- round((avg_lat_velocity*(z-previous_time)+previous_lat), digits = decimal)
          dayMatrix[z,2] <- round((avg_lon_velocity*(z-previous_time)+previous_lon), digits = decimal)
        }
      }
      
      dayMatrix[timeInMinutes,] <- positionMatrix[as.numeric(dataLocation[u]),]
      startPoint <- timeInMinutes+1  
    }
  }

  #convert matrix to dataframe#
  df <- as.data.frame(dayMatrix,row.names=NULL)
  colnames(df) <- c("lon","lat")
  library(plyr)
  uniquePositions <- ddply(df,.(lon,lat),nrow)
  modal_index <- match(max(uniquePositions$V1),uniquePositions$V1)
  
  #calculate modal longitude and latitude coordinates#
  modeLon <- uniquePositions[modal_index,1]
  modeLat <- uniquePositions[modal_index,2]
  string1 <- as.character(modeLon)
  string2 <- as.character(modeLat)
  finishString <- paste(string2, string1, sep = ",")
  REMatrix[b,3] <- finishString
  date1 <- as.character(as.Date(date1)+1)
  }
  

#bind matrix#
modal_matrix <- rbind(modal_matrix,REMatrix)
}
}
for(g in 1:nrow(master_df)){
  if(!is.na(master_df[g,2])&&master_df[g,2]!=modal_matrix[g,3]){
    master_df[g,2] = modal_matrix[g,3]
    master_df[g,3] = "update"
    master_df[g,4] = "update"
    master_df[g,5] = "update"
    master_df[g,6] = "update"
  }
}
write.csv(master_df, file = "weather_orig_fixed.csv", row.names = FALSE)