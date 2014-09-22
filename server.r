library(ggplot2)
library(stringr)
library(dplyr)
library(tidyr)
library(dkslider)
library(lubridate)
source("utils.r")

convert90s = function(x) {
  # turn 90min appts into 2*45min
  i=1
  while (i <= nrow(x)) {
    if (x[i, "ApptLength"] == 90) {
      x[i, "ApptLength"] = 45
      x = rbind(x[1:i, ], x[i, ], x[-(1:i),])
    }
    i = i + 1
  }
  return(x)
}

Data2014 = read.csv(file="DataJuly2014.csv", stringsAsFactors=F) %>%
  mutate(RefDate = as.Date(RefDate, format="%d/%m/%Y"), 
         ApptDate = as.Date(ApptDate, format="%d/%m/%Y")) %>%
  filter(CancelFlag=="N")

refs = Data2014 %>%
  select(RefDate, ApptLength, OutpatientFlag) %>%
  filter(year(RefDate)==2013) %>%
  arrange(OutpatientFlag, RefDate) %>%
  convert90s()

cat("Loaded", nrow(refs), "new patient referrals from 1/1/2013 to 31/12/2013\n")

# replicate refs for 10 years
x=refs
for (i in 1:5) {
  x$RefDate = x$RefDate + 365
  refs = rbind(refs, x)
}
cat("Replicated 2013 * 5 times\n")

waiting = Data2014 %>%
  filter(RefDate < as.Date("2013-01-01"), ApptDate > as.Date("2013-01-01")) %>%
  select(RefDate, ApptLength, OutpatientFlag) %>%
  arrange(OutpatientFlag, RefDate) %>%
  convert90s()

cat("Loaded", nrow(waiting),"patients into waiting list as at 1/1/2013\n")

shinyServer(function(input, output, session) {
  
  getSimulation = reactive({
    
    simDuration = input$simDuration * 52
    
    progress = shiny::Progress$new(session, min=1, max=simDuration)
    on.exit(progress$close())
    progress$set(message="Simulating...")
    
    # Session timetables
    consultantSessionsPerWeek = input$consultantSessionsPerWeek
    regSessionsPerWeek = input$regSessionsPerWeek
    #consultantTemplate = list(n60=1, n45=3)
    #regTemplate = list(n30=2)
    
    # start vals
    startDate = as.Date("2013-01-01")
    done = data.frame()
    numWaitingTally = c()
    num30WaitingTally = c()
    num45WaitingTally = c()
    num60WaitingTally = c()
    timeWaitingTally = c()
    numNewRefHx = c()
    numApptHx = c()
    defectTally = c()
    
    for (curWeek in 1:simDuration) {
      
      progress$set(value=curWeek)
      
      lastWeek = startDate + ((curWeek - 1) * 7)
      today = startDate + (curWeek * 7)
      
      # get new referrals and add to waiting list
      # TODO randomly generate pts using mean pts / day and sd pts / day
      # x <- sample( LETTERS[1:4], 10000, replace=TRUE, prob=c(0.1, 0.2, 0.65, 0.05) )
      
      newrefs = which(refs$RefDate > lastWeek & refs$RefDate < today)
      waiting = rbind(waiting, refs[newrefs, ])
      waiting = waiting %>%
        arrange(OutpatientFlag, RefDate) # resort waiting list so that new ip refs are ahead of old op refs
      numNewRefHx[curWeek] = length(newrefs)
      
      avail60s = consultantSessionsPerWeek*str_count(input$consultantTemplate, "60") #consultantTemplate$n60
      avail45s = consultantSessionsPerWeek*str_count(input$consultantTemplate, "45") #consultantTemplate$n45
      avail30s = consultantSessionsPerWeek*str_count(input$consultantTemplate, "30") #consultantTemplate$n45
      avail45s = avail45s + regSessionsPerWeek*str_count(input$regTemplate, "45")
      avail30s = avail30s + regSessionsPerWeek*str_count(input$regTemplate, "30") #regTemplate$n30
      
      # TODO: handle 90min appts - use 2 * 45min
      
      # fill 60min appts this week from waiting list
      new60s = which(waiting$ApptLength == 60)
      if (length(new60s) < avail60s) {
        # not enough 60min refs waiting - add a 45 and a 30min
        avail30s = avail30s + (avail60s - length(new60s))
        avail45s = avail45s + (avail60s - length(new60s))
      }
      new60s = new60s[1:min(length(new60s), avail60s)]
      
      # fill 45min appts this week
      new45s = which(waiting$ApptLength == 45)
      if (length(new45s) < avail45s) # not enough 45min refs waiting - add 1 extra 30min
        avail30s = avail30s + 1*(avail45s - length(new45s))
      new45s = new45s[1:min(length(new45s), avail45s)]  
      
      # fill 30min appts this week
      new30s = which(waiting$ApptLength == 30)
      new30s = new30s[1:min(length(new30s), avail30s)]
      
      allNewAppts = c(new60s, new45s, new30s)
      allNewAppts = na.omit(allNewAppts) # remove any NA if eg no new60s this week
      
      thisWeekAppts = waiting[allNewAppts, ]
      thisWeekAppts$ApptDate = rep(today, times=nrow(thisWeekAppts))
      thisWeekAppts$DaysWaiting = thisWeekAppts$ApptDate - thisWeekAppts$RefDate
      numApptHx[curWeek] =nrow(thisWeekAppts)
      
      done = rbind(done, thisWeekAppts) # add this week appts to done list
      waiting = waiting[-allNewAppts, ] # remove this week appts from waiting list
      
      # record waiting list end of week stats
      numWaitingTally[curWeek] = nrow(waiting)
      num30WaitingTally[curWeek] = sum(waiting$ApptLength==30)
      num45WaitingTally[curWeek] = sum(waiting$ApptLength==45)
      num60WaitingTally[curWeek] = sum(waiting$ApptLength==60)

      timeWaitingTally[curWeek] = mean(thisWeekAppts$DaysWaiting) #today-waiting$RefDate)
      defectTally[curWeek] = sum(thisWeekAppts$DaysWaiting > 120)/nrow(thisWeekAppts)*100
      
      cat("End of Week", curWeek, ":", numNewRefHx[curWeek], "new referrals,", numApptHx[curWeek], "new appts,", mean(thisWeekAppts$DaysWaiting), "average days wait,", numWaitingTally[curWeek],"on waiting list.\n")
    }
    
    stats = data.frame(week = 1:simDuration, newRef = numNewRefHx, 
                       appts = numApptHx, mismatch = (numApptHx - numNewRefHx),
                       timeWaiting = timeWaitingTally,
                       defects = defectTally,
                       numWaiting = numWaitingTally, num30Waiting = num30WaitingTally, num45Waiting = num45WaitingTally, num60Waiting = num60WaitingTally)
    return(stats)
  })
  
  observe({
    year = input$referralYear
    if (year == "2011")
      updateDkSlider(session, "apptLengthSlider", values=c(2,60,80))
  }, priority=1)
  
  observe({
    apptLengths = input$apptLengthSlider
    updateNumericInput(session, "appt30", value=apptLengths[1])
    updateNumericInput(session, "appt45", value=apptLengths[2]-apptLengths[1])
    updateNumericInput(session, "appt60", value=apptLengths[3]-apptLengths[2])
    updateNumericInput(session, "appt90", value=100-apptLengths[3])
  }, priority=1)
  
  output$plots <- renderPlot({
    stats = getSimulation() %>%
      mutate(isDefect = defects > 5, isMismatch = mismatch < 0)
    
    x1 = ggplot(stats, aes(x=week, y=numWaiting, group=1)) +
      geom_point() +
      geom_line()
    
    x2 = stats %>%
      gather(key=ApptLength, value=Waiting, num30Waiting:num60Waiting) %>%
        ggplot(., aes(x=week, y=Waiting, group=ApptLength, color=ApptLength)) +
          geom_point() +
          geom_line()
    
    x3 = ggplot(stats, aes(x=week, y=defects, group=1)) +
      geom_point(aes(color=!isDefect)) +
      geom_line() +
      geom_hline(yintercept=5, color="red") +
      guides(color=FALSE)
    
    x4 = ggplot(stats, aes(x=week, y=mismatch, group=1)) +
      geom_point(aes(color=!isMismatch)) +
      geom_line() +
      guides(color=F)
    
    x5 = ggplot(stats, aes(x=week, y=timeWaiting, group=1)) +
      geom_point() +
      geom_line() +
      geom_hline(yintercept=120, color="red")
    
    multiplot(x1,x2,x3, x4,x5, cols=1)
  }, height=800)
  
}
)