########################################################
# Reshaping an excel file issued from doodle
# and sending an reminder email
# the day before the meeting
########################################

library(tidyverse)
library(readxl)
library(gmailr)
library(purrr)

# setwd(getSrcDirectory()[1])

reiterate <- function(x) {
    
    goodIdx <- !is.na(as.character(x) )
    goodVals <- c(NA, x[goodIdx])
    fillIdx <- cumsum(goodIdx) + 1
    final_vector <- goodVals[fillIdx] %>% unlist %>% as.vector
    
    return (final_vector)
    
}

data <-
    read_excel("/Users/Ladislas/Desktop/M2R_Sonja_2017_2018/doodle.xls") %>%
    # remove the two first lines
    slice(3:nrow(.) ) %>%
    # remove the last two lines
    slice(1:(nrow(.)-3) ) %>%
    # remove the first column (pseudo)
    select(-1)

# working on data2 below
data2 <- data
data2[1, ] <- reiterate(data2[1, ])
data2[2, ] <- reiterate(data2[2, ])
data2[3, 2:ncol(data2)] <- substr(data2[3, 2:ncol(data2)], 1, 5)

# split the month and year by space
x <- strsplit(as.character(data2[1, ]), " ", fixed = TRUE)

# rbind it
xx <- do.call(rbind, x) %>% t
data2 <- rbind(xx[2,], xx[1,], data2[2:nrow(data2), ])

# "naming" the first four rows
data2[1:4, 1] <- c("year", "month", "day", "hour")

# reshaping the hours
data2[3, 2:ncol(data2)] <- substr(data2[3, 2:ncol(data2)], 6, 10)

# translatig months
data2[2, 2:ncol(data2)] <- sapply(data2[2, 2:ncol(data2)], FUN = function(x) ifelse(x == "octobre", "October", "November") )

# concatenating rows
data2[1, ] <- t(
    do.call(
        paste, c(as.data.frame(t(data2[1:3, ]), stringsAsFactors = FALSE), sep = ", ")
        )
    )

# transposing it
data3 <- as.data.frame(t(data2), stringsAsFactors = FALSE)
colnames(data3) <- data3[1, ] %>% as.character
data3 <- data3 %>% slice(-1)

# removing old day and month
data3[, 2:3] <- NULL

# transforming to date format
data3[, 1] <- as.Date(data3[, 1], format = "%Y, %B, %d") 

# joining date and time
data3$hour <- ifelse(data3$hour == "9:00 ", "09:00", data3$hour)
data3$hour <- paste0(data3$hour, ":00")
data3$time <- paste(data3[, 1], data3[, 2])
data3$time <- as.POSIXct(data3$time)

# removing old day and time columns
data3[, 1:2] <- NULL
data3 <- data3[, c(ncol(data3), 1:(ncol(data3)-1))]

# matching contact with hours
for (i in 2:ncol(data3) ) {
    
    data3[, i] <- ifelse(data3[, i] == "OK", colnames(data3)[i], NA)

}

# removing NAs

ind <- apply(data3[, 2:ncol(data3)], 1, function(x) all(is.na(x) ) )
data4 <- data3[!ind, ]

for (i in 1:nrow(data4) ) {
    
    data4[i, ] <- data4[i, !is.na(data4[i, ])]
    
}

data4 <- data4[, 1:2] %>% magrittr::set_colnames(c("time", "participant") )

# find participants with no choice

ind <- apply(data[, 2:151], 1, function(x) all(is.na(x) ) )
no_choices <- which(ind == TRUE)

# find participants with more than one choice

multiple_choices <- data[which(duplicated(data[, 1]) ), 1] %>% as.character

################################################################
# sending emails from R
# https://github.com/jennybc/send-email-with-r
#####################################################

# if there is no multiple nor zero choice

if (mean(ind) == 0 & is.na(multiple_choices) ) {
    
    this_hw <- "Experience 'Validation d'un nouveau test de QI'"
    email_sender <- "Ladislas Nalborczyk <ladislas.nalborczyk@gmail.com>"
    optional_bcc <- "Ladislas Nalborczyk <ladislas.nalborczyk@gmail.com>"
    body <- "Bonjour.
    
    Je vous confirme et rappelle votre inscription à l'expérience 'Validation d'un nouveau test de QI', le %s.
    
    L'expérience aura lieu dans le box C du LPNC, au 1er étage du BSHM (Aile D).
    
    Cordialement,
    
    l'équipe de recherche"
    
    edat <-
        data4 %>%
        mutate(
            To = sprintf("<%s>", participant),
            Bcc = optional_bcc,
            From = email_sender,
            Subject = sprintf(this_hw),
            body = sprintf(body, time)
        )
    
    # saving emails
    write.csv(edat, "composed-emails.csv")
    
    # identify participants registered for tomorrow
    today <- Sys.time() %>% as.Date
    tomorrow <- today + 1
    ppts <- which(as.Date(edat$time) == tomorrow) %>% as.numeric
    
    # if participants planned for tomorrow, send emails
    
    if (!is_empty(ppts) ) {
        
        edat2 <- edat[ppts, ]
        
        emails <- edat2 %>% pmap(mime)
        
        safe_send_message <- safely(send_message)
        sent_mail <- emails %>% map(safe_send_message)
        
    }
    
}

quit(save = "no")
