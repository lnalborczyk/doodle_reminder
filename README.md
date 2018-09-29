# How to automatically send emails to the participants of a doodle

During my PhD I had to run several experiments with undergraduate students. The most efficient way to recruit them has been to use online schedule managers like doodle. It is common wisdom in psychology labs that human participants tend to forget that they registered for an experiment, and that we should send them reminders. However, for experiments carried out with more than 20 participants, it can become a bit tedious to manually manage all these reminders.

Therefore, I have quickly wrote an R script to send these reminders by e-mails the day preceeding the experiment, based on an .xls file issued from doodle.

## A minimal example

I have set up an example doodle available following this link: https://doodle.com/poll/g7vee2qy2swhmt9g

From there, you can download the calendar as an .xls file by clicking on More > Export to Excel. The first thing to do is to reshape this excel file so that we can automatically send reminders. Basically, we just need the email address as well as the date + hour of the experiment for each partcipant, in a tidy format. This reshaping is done in the first part of the R script (before line 100).

## Sending emails from R

The second part of the script is sending emails automatically to the participants that are registered the subsequent day (see lines 143-145). This part of the script is based on the nice tutorial from Jennifer Bryan: https://github.com/jennybc/send-email-with-r

## Scheduling it (for Mac OSX)

Mac OSX offers a simple way to schedule the execution of an app through the Automator. Use Automator > New document > Calendar alarm. Add a `Run Shell Script` and specify the following line, replacing `your_path` by the path to the `R` script.

```
cd your_path
/usr/local/bin/Rscript --vanilla automatic_email_reminder.R
```

Then, in the Calendar, set the hour at which you want this alarm to run the above `R` script (I have defined to run it every day at 4pm).

See also this link for more information: https://forums.macrumors.com/threads/schedule-automator-workflow-or-app.1996548/

NB: this script might need to be adapted a bit if participants of the doodle can choose multiple (more than one) dates and/or if some participants chose no date.
