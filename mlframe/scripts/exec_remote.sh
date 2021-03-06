#!/bin/bash

# Optionally copies provided script to remote location,
# executes provided script or command.
# Arguments: remove address and command (script name).

# ver 0.1
# 2018 (C) Peter Bryzgalov @ CHITECH Stair Lab

usage=$(cat <<USAGEBLOCK
Usage:
$(basename $0) <remote address> <command>
USAGEBLOCK
)

DEBUG=""
TMP_FILE="remote_command_.sh"

if [[ $# < 2 ]]; then
	echo "ARGs: $@"
	echo "$usage"
	exit 0
fi

REMOTE_ADDRESS="$1"
# If command with arguments supplied as a string, $2 has command with arguments.
# Convert $2 to array and split it into REMOTE_COMMAND and ARGS.
ARGS_arr=($2)
# If ARGS_arr has more than 1 element, then split.
if [ ${#ARGS_arr[@]} -gt 1 ]; then
	REMOTE_COMMAND=${ARGS_arr[0]}
	unset ARGS_arr[0]
	ARGS="${ARGS_arr[@]}"
else
	# Command and argumnets supplied as different parameters
	REMOTE_COMMAND=$2; shift; shift
	ARGS="$@"
fi
SCRIPT_FILE_PATH="$REMOTE_COMMAND"

if [ $DEBUG ]; then
	echo "REMOTE_ADDRESS=$REMOTE_ADDRESS"
	echo "SCRIPT_FILE_PATH=$SCRIPT_FILE_PATH"
	echo "PWD: $(pwd)"
	echo "REMOTE_COMMAND=$REMOTE_COMMAND"
	echo "$(basename $0) arguments: $ARGS"
fi


if [ -x "$SCRIPT_FILE_PATH" ]; then
	# If file exists and is executable
	# ssh script to remote location and run
	if [ $DEBUG ]; then
		echo "Run $SCRIPT_FILE_PATH $ARGS on $REMOTE_ADDRESS"
		scp "$SCRIPT_FILE_PATH" "$REMOTE_ADDRESS:$TMP_FILE"
		ssh "$REMOTE_ADDRESS" "./$TMP_FILE $ARGS && echo \"Exit code \$?\" && rm $TMP_FILE"
	else
		scp "$SCRIPT_FILE_PATH" "$REMOTE_ADDRESS:$TMP_FILE" 2>/dev/null
		ssh "$REMOTE_ADDRESS" "./$TMP_FILE $ARGS && echo \"exitcode=\$?\" && rm $TMP_FILE"
	fi

else
	if [ $DEBUG ]; then
		echo "Run command $REMOTE_COMMAND $ARGS on $REMOTE_ADDRESS"
		ssh "$REMOTE_ADDRESS" $REMOTE_COMMAND $ARGS
	else
		ssh "$REMOTE_ADDRESS" $REMOTE_COMMAND $ARGS 2>/dev/null
	fi
fi

