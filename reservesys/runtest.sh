#!/bin/sh

# Source the common test script helpers
. /usr/bin/rhts_environment.sh

STOPRHTS()
{
    /sbin/service rhts stop
}

if [ $REBOOTCOUNT -gt 0 ]; then
    STOPRHTS
    exit 0
fi

# Functions
RprtRslt()
{
    ONE=$1
    TWO=$2
    THREE=$3

    # File the results in the database
    report_result $ONE $TWO $THREE
}

MOTD()
{
    FILE=/etc/motd

    mv $FILE $FILE.orig

    echo "**  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **" > $FILE
    echo "                 This System is reserved by $SUBMITTER.               " >> $FILE
    echo "                                                                      " >> $FILE
    echo " To return this system early. You can run the command: return2rhts.sh " >> $FILE
    echo "  Ensure you have your logs off the system before returning to RHTS   " >> $FILE
    echo "                                                                      " >> $FILE
    echo " To extend your reservation time. You can run the command:            " >> $FILE
    echo "  extendtesttime.sh                                                   " >> $FILE
    echo " This is an interactive script. You will be prompted for how many     " >> $FILE
    echo "  hours you would like to extend the reservation.                     " >> $FILE
    echo "  Please use this command responsibly, Everyone uses these machines.  " >> $FILE
    echo "                                                                      " >> $FILE
    echo " You should verify the watchdog was update succesfully after          " >> $FILE
    echo "  you extend your reservation.                                        " >> $FILE
    echo "  http://$RESULT_SERVER/cgi-bin/rhts/watchdog.cgi                     " >> $FILE
    echo "                                                                      " >> $FILE
    echo " For ssh, kvm, serial and power control operations please look here:  " >> $FILE
    if [ -z "$LAB_SERVER" ]; then
	echo "  https://inventory.engineering.redhat.com/view/$HOSTNAME          " >> $FILE
    else
	echo "  http://$LAB_SERVER/cgi-bin/rhts/systems.cgi?fqdn=$HOSTNAME          " >> $FILE
    fi
    echo "                                                                      " >> $FILE
    echo "      RHTS Test information:                                          " >> $FILE
    echo "                         HOSTNAME=$HOSTNAME                           " >> $FILE
    echo "                            JOBID=$JOBID                              " >> $FILE
    echo "                         RECIPEID=$RECIPEID                           " >> $FILE
    echo "                    RESULT_SERVER=$RESULT_SERVER                      " >> $FILE
    echo "                           DISTRO=$DISTRO                             " >> $FILE
    echo "                     ARCHITECTURE=$ARCH                               " >> $FILE
    echo "**  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **  **" >> $FILE
}

RETURNSCRIPT()
{
    SCRIPT=/usr/bin/return2rhts.sh

    echo "#!/bin/sh"                           > $SCRIPT
    echo "export RESULT_SERVER=$RESULT_SERVER" >> $SCRIPT
    echo "export TESTID=$TESTID" >> $SCRIPT
    echo "/usr/bin/rhts-test-update $RESULT_SERVER $TESTID finish" >> $SCRIPT
    echo "touch /var/cache/rhts/$TESTID/done" >> $SCRIPT
    echo "/bin/echo Hit Return to reboot the system and continue any" >> $SCRIPT
    echo "/bin/echo remaining RHTS tests. Or hit CTRL-C now if this" >> $SCRIPT
    echo "/bin/echo is not desired." >> $SCRIPT
    echo "read dummy" >> $SCRIPT
    echo "/usr/bin/rhts-reboot" >> $SCRIPT

    chmod 777 $SCRIPT
}

EXTENDTESTTIME()
{
SCRIPT2=/usr/bin/extendtesttime.sh

cat > $SCRIPT2 <<-EOF
howmany()
{
echo "How many hours would you like to extend the reservation."
echo "             Must be between 1 and 99                   "
read RESPONSE
validint \$RESPONSE 1 99
echo "Extending reservation time \$RESPONSE"
EXTRESTIME=\$(echo \$RESPONSE)h
}

validint()
{
# validate first field.
number="\$1"; min="\$2"; max="\$3"

if [ -z "\$number" ] ; then
echo "You didn't enter anything."
exit 1
fi

if [ "\${number%\${number#?}}" = "-" ] ; then # first char '-' ?
testvalue="\${number#?}" # all but first character
else
testvalue="\$number"
fi
  
nodigits="\$(echo \$testvalue | sed 's/[[:digit:]]//g')"
 
if [ ! -z "\$nodigits" ] ; then
echo "Invalid number format! Only digits, no commas, spaces, etc."
exit 1
fi

if [ ! -z "\$min" ] ; then
if [ "\$number" -lt "\$min" ] ; then
echo "Your value is too small: smallest acceptable value is \$min"
exit 1
fi
fi
if [ ! -z "\$max" ] ; then
if [ "\$number" -gt "\$max" ] ; then
echo "Your value is too big: largest acceptable value is \$max"
exit 1
fi
fi

return 0
}

howmany

export RESULT_SERVER=$RESULT_SERVER
export HOSTNAME=$HOSTNAME
export JOBID=$JOBID
export TEST=$TEST
export TESTID=$TESTID
rhts-test-checkin $RESULT_SERVER $HOSTNAME $JOBID $TEST \$EXTRESTIME $TESTID
logger -s "rhts-test-checkin $RESULT_SERVER $HOSTNAME $JOBID $TEST \$EXTRESTIME $TESTID"
EOF

chmod 777 $SCRIPT2
}

NOTIFY()
{
    /sbin/service sendmail start
    local msg=$(mktemp)

cat > $msg <<-EOF
To: $SUBMITTER
Subject: $HOSTNAME
X-RHTS-test: $TEST

EOF
    cat /etc/motd >>$msg
    cat $msg | sendmail -t
    \rm -f $msg
}

WATCHDOG()
{
    rhts-test-checkin $RESULT_SERVER $HOSTNAME $JOBID $TEST $SLEEPTIME $TESTID
}

if [ -z "$RESERVETIME" ]; then
    SLEEPTIME=24h
else
    SLEEPTIME=$RESERVETIME
fi

if [ -n "$RESERVEBY" ]; then
    SUBMITTER=$RESERVEBY
fi

echo "***** Start of reservesys test *****" > $OUTPUTFILE

# build the /etc/motd file
echo "***** Building /etc/motd *****" >> $OUTPUTFILE
MOTD

# send email to the submitter
echo "***** Sending email to $SUBMITTER *****" >> $OUTPUTFILE
NOTIFY

# set the external watchdog timeout
echo "***** Setting the external watchdog timeout *****" >> $OUTPUTFILE
WATCHDOG

# build /usr/bin/extendtesttime.sh script to allow user
#  to extend the time time.
echo "***** Building /usr/bin/extendtesttime.sh *****" >> $OUTPUTFILE
EXTENDTESTTIME

# build /usr/bin/return2rhts.sh script to allow user
#  to return the system to RHTS early.
echo "***** Building /usr/bin/return2rhts.sh *****" >> $OUTPUTFILE
RETURNSCRIPT

echo "***** End of reservesys test *****" >> $OUTPUTFILE
RprtRslt $TEST PASS 0

# stop rhts service, So that reserve workflow works with test reboot support.
STOPRHTS
