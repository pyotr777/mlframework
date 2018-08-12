#!/bin/bash

#Execute command concurrently on multiple machines over ssh
command="./test.sh 777"
ssh -M -S ./power -o "ControlPersist=yes" power &
ssh -M -S ./pwr321 -o "ControlPersist=yes" pwr321 &
echo "CM created"
echo "Run scp to power"
scp ./test.sh ./parent.sh power:
echo "Run scp to pwr321"
scp ./test.sh ./parent.sh pwr321:
echo "Checking"
ssh -O check -S ./power power
ssh -O check -S ./pwr321 pwr321
echo "Checked"
echo "Run test.sh on remote"
ssh power "nohup ./parent.sh $command > test.out.log 2>test.err.log </dev/null &"
ssh pwr321 "nohup ./parent.sh $command > test.out.log 2>test.err.log </dev/null &"
echo "Checking test logs"
for i in {1..7}; do
	ssh power "tail \$HOME/.stdout.log" 2>/dev/null
	ssh pwr321 "tail \$HOME/.stdout.log" 2>/dev/null
	sleep 2
done
echo "Check exit codes"
ssh power "cat \$HOME/.exit_code"
ssh pwr321 "cat \$HOME/.exit_code"
echo "Checking CM status"
ssh -O check -S ./power power
ssh -O check -S ./pwr321 pwr321
echo "Checked"
echo "Exit CM"
ssh -O exit -S ./power power
ssh -O exit -S ./pwr321 pwr321
echo "finished"
#scp test.sh pwr321:
