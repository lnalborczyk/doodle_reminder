########################################################
# Reshaping an excel file issued from doodle
# and sending an reminder email
# the day before the meeting
############################################

library(tidyverse)
library(readxl)
library(gmailr)
library(purrr)

# NB: this won't work if executed from RStudio, but will work if the script if sourced
# getting the directory of the current script

setwd(getSrcDirectory()[1])

reiterate <- function(x) {
    
    goodIdx <- !is.na(as.character(x) )
    goodVals <- c(NA, x[goodIdx])
    fillIdx <- cumsum(goodIdx) + 1
    final_vector <- goodVals[fillIdx] %>% unlist %>% as.vector
    
    return (final_vector)
    
}

data <-
    # importing the xls file from doodle
    read_excel("Doodle.xls") %>%
    # remove the two first lines
    slice(3:nrow(.) ) %>%
    # remove the first column (pseudo)
    select(-1)

# filling NAs of the first two lines with the last value
data[1, ] <- reiterate(data[1, ])
data[2, ] <- reiterate(data[2, ])

# keeping only the time of the beginning of the meeting
data[3, 2:ncol(data)] <- substr(data[3, 2:ncol(data)], 1, 5)

# split the month and year, rbind it and transpose it
x <- strsplit(as.character(data[1, ]), " ", fixed = TRUE) %>% do.call(rbind, .) %>% t

# rbind it
data <- rbind(x[2,], x[1,], data[2:nrow(data), ])

# "naming" the first four rows
data[1:4, 1] <- c("year", "month", "day", "hour")

# extractong the day number
data[3, 2:ncol(data)] <- substr(data[3, 2:ncol(data)], 4, 6)

# concatenating rows
data[1, ] <- t(
    do.call(
        paste, c(as.data.frame(t(data[1:3, ]), stringsAsFactors = FALSE), sep = ", ")
        )
    )

# transposing it
data <- as.data.frame(t(data), stringsAsFactors = FALSE)

# using the first row as column names
colnames(data) <- data[1, ] %>% as.character
data <- data %>% slice(-1)

# removing old day and month
data[, 2:3] <- NULL

# transforming to date format
data[, 1] <- as.Date(data[, 1], format = "%Y, %B, %d") 

# joining date and time
data$hour <- ifelse(data$hour == "9:00 ", "09:00", data$hour)
data$hour <- paste0(data$hour, ":00")
data$time <- paste(data[, 1], data[, 2])
data$time <- as.POSIXct(data$time)

# removing old day and time columns
data[, 1:2] <- NULL
data <- data[, c(ncol(data), 1:(ncol(data) - 1) )]

# matching contact with hours
for (i in 2:ncol(data) ) {
    
    data[, i] <- ifelse(data[, i] == "OK", colnames(data)[i], NA)

}

# removing NAs
ind <- apply(data[, 2:ncol(data)], 1, function(x) all(is.na(x) ) )
data <- data[!ind, ]

for (i in 1:nrow(data) ) {
    
    data[i, ] <- data[i, !is.na(data[i, ])]
    
}

# keeping only the first two columns and renaming them
data <- data[, 1:2] %>% magrittr::set_colnames(c("time", "participant") )

# find participants with no choice
# ind <- apply(data[, 2:151], 1, function(x) all(is.na(x) ) )
# no_choices <- which(ind == TRUE)

# find participants with more than one choice
# multiple_choices <- data[which(duplicated(data[, 1]) ), 1] %>% as.character

################################################
# sending emails from R
################################

# title of the mail
this_hw <- "Experience 'Validation d'un nouveau test de QI'"

# sender (you)
email_sender <- "Ladislas Nalborczyk <ladislas.nalborczyk@gmail.com>"

# optional bcc
optional_bcc <- "Ladislas Nalborczyk <ladislas.nalborczyk@gmail.com>"

# body of the mail
body <- "Bonjour.

Je vous confirme et rappelle votre inscription à l'expérience ..., le %s.

L'expérience aura lieu ...

Cordialement,

l'équipe de recherche"

# putting all the info in a single dataframe
edat <-
    data %>%
    mutate(
        To = sprintf("<%s>", participant),
        Bcc = optional_bcc,
        From = email_sender,
        Subject = sprintf(this_hw),
        body = sprintf(body, time)
    )

# identify participants registered for tomorrow
today <- Sys.time() %>% as.Date
tomorrow <- today + 1
ppts <- which(as.Date(edat$time) == tomorrow+2) %>% as.numeric

# if some participants are planned for tomorrow, send emails
if (!is_empty(ppts) ) {
    
    edat2 <- edat[ppts, ]
    
    emails <- edat2 %>% pmap(mime)
    
    safe_send_message <- safely(send_message)
    sent_mail <- emails %>% map(safe_send_message)
    
}

# quitting the sourced script
quit(save = "no")
