ssh -M -S ./power -o "ControlPersist=yes" power &
ssh -M -S ./pwr321 -o "ControlPersist=yes" pwr321 &
echo "CM created"
echo "Run scp to power"
scp ./test.sh power:
echo "Run scp to pwr321"
scp ./test.sh pwr321:
echo "Checking"
ssh -O check -S ./power power
ssh -O check -S ./pwr321 pwr321
echo "Checked"
echo "Run test.sh on remote"
ssh power "nohup ./test.sh > test.out.log 2>test.err.log </dev/null &"
ssh pwr321 "nohup ./test.sh > test.out.log 2>test.err.log </dev/null &"
echo "Checking test logs"
for i in {1..5}; do
	ssh power cat test.out.log 2>/dev/null
	ssh pwr321 cat test.out.log 2>/dev/null
	sleep 2
done
echo "Checking CM status"
ssh -O check -S ./power power
ssh -O check -S ./pwr321 pwr321
echo "Checked"
echo "Exit CM"
ssh -O exit -S ./power power
ssh -O exit -S ./pwr321 pwr321
echo "finished"
#scp test.sh pwr321:
