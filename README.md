# How to automatically send emails to the participants of a doodle

During my PhD I had to run several experiments with undergraduate students. The most efficient way to recruit them has been to use online schedule managers like doodle. It is common wisdow in psychoogy labs than human participants tend to forget that they registered for an experiment and that we should then sned them reminders. However, when experiments are acarried out with sample size > 20, it can be a bit tedious to manually manage all these reminders e-mails.

Therefore, I have quickly wrote an R script to send these reminders the day prceeding the experiment, based on an xls file issued from doodle.

## A minimal example

I have set up an example doodle available following this link: https://doodle.com/poll/g7vee2qy2swhmt9g

From there, you can download the calendard as an xls file by clicking on More > Export to Excel.

The first thing to do is to reshaping this excel file so that we can automatically send reminders. Basically, we just need the email address and the date + hour of the experiment for each partcipant, in a tidy format. This reshaping is done in the first part of the R script (before line 100).

## Sending emails from R

The second part of the script is sending email automatically to the participants that are registered the day after (see lines 148-150). This part of the script is based on the amazing tutorial from Jennifer Bryan: https://github.com/jennybc/send-email-with-r

## Scheduling it (for Mac OSX)

Mac OSX offers a simple way to schedule the execution of an app through the Automator. Use Automator > New document > Calendar alarm. Add a `Run Shell Script` and specify the following line, replacing `your_path` by the path to the `R` script.

`/usr/local/bin/Rscript --vanilla /your_path/automatic_email_reminder.R`

Then, in the Calendar, set the hour at which you want this alarm to run the above `R` script (I have defined to run it every day at 4pm).

See also this link for more information: https://forums.macrumors.com/threads/schedule-automator-workflow-or-app.1996548/

NB: this script might need to be adapted a bit if participants of the doodle can choose multiple (more than one) dates and/or if some participants chose no date.
