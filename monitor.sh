#!/bin/bash

SUPERVISORCTL_CMD="supervisorctl ${SUPERVISORCTL_ARGS}"
CFD_REFRESH=${CFD_REFRESH:-'/app/cfd_refresh.sh'}
CFD_PROC_NAME=${CFD_PROC_NAME:-'cloudflared'}
VERBOSE_LEVEL=${VERBOSE_LEVEL:-1}

function get_field_from_header() {
	local segments=($1)

	for segment in "${segments[@]}"; do
		if [[ "${segment%%:*}" == "$2" ]]; then
			echo "${segment#*:}"
			break
		fi
	done
}

function write_log() {
	echo "$@" 1>&2
}

function log_0() {
	write_log "0 $@"
}

function log_1() {
	[[ $VERBOSE_LEVEL > 0 ]] && write_log "1 $@"
}

function log_2() {
	[[ $VERBOSE_LEVEL > 1 ]] && write_log "2 $@"
}

declare -A CFD_STATES=(
	[UNKNOWN]="Unknown State"
	[LAUNCHED]="Cloudflared has been launched"
	[CREATED]="Tunnel created"
	[ADDRESSED]="Tunnel URL retrieved"
	[EXPIRED]="Tunnel expired"
)

# A global variable that represent the current state
CFD_STATE=${CFD_STATES[UNKNOWN]}

function enter_cfd_state() {
	if [[ $1 != $CFD_STATE ]]; then
		CFD_STATE="$1"
		log_0 "Entered State: \"$1\""
	fi
}

function on_cfd_starting() {
	enter_cfd_state "${CFD_STATES[LAUNCHED]}"
}

# Process each line of the stderr output
function on_cfd_stderr() {
	local next_state=$CFD_STATE

	case $CFD_STATE in
		"${CFD_STATES[LAUNCHED]}")
			if [[ $1 == *"Your quick Tunnel has been created!"* ]]; then
				next_state=${CFD_STATES[CREATED]}
			fi
		;;

		"${CFD_STATES[CREATED]}")
			TUNNEL_URL=$(echo "$1" | grep -oE "https:\/\/.*[a-z]+.trycloudflare.com" | sed "s#https://##")
			if [[ -n "$TUNNEL_URL" ]]; then
				next_state=${CFD_STATES[ADDRESSED]}
				log_0 "Tunnel URL -> \"$TUNNEL_URL\""

				# Update webpage and subscription
				$CFD_REFRESH "$TUNNEL_URL"
			fi
		;;

		"${CFD_STATES[ADDRESSED]}")
			if [[ $1 == *"Unregistered tunnel connection"* || $1 == *"Unauthorized: Failed to get tunnel"* ]]; then
				next_state=${CFD_STATES[EXPIRED]}

				# Tunnel expired or invalidated by Cloudflare for whatever reasons
				$SUPERVISORCTL_CMD restart $CFD_PROC_NAME > /dev/null

				log_0 "Replacing expired tunnel..."
			fi
		;;

		"${CFD_STATES[EXPIRED]}")
		;;

		*)
			log_1 "Warning: Entered unknown state!"
		;;
	esac

	enter_cfd_state "$next_state"
}

log_0 "$SUPERVISORCTL_CMD"

while :
do
	echo "READY"

	read -r line
	#echo $line 1>&2
	EVENT_NAME=$(get_field_from_header "$line" "eventname")
	BUF_LEN=$(get_field_from_header "$line" "len")

	read -n $BUF_LEN -r line
	#echo $line 1>&2
	PROC=$(get_field_from_header "$line" "processname")
	log_1 "[$PROC] $EVENT_NAME -> $BUF_LEN"

	if [[ $PROC == $CFD_PROC_NAME ]]; then
		case "$EVENT_NAME" in
			"PROCESS_STATE_STARTING")
				on_cfd_starting
			;;

			"PROCESS_LOG_STDERR")
				char_to_be_read=$((BUF_LEN-${#line}-1))
				log_2 "Contents -> $char_to_be_read"

				while ((char_to_be_read > 0)) ; do
					read -r line
					log_2 "STDERR> $line"
					char_to_be_read=$((char_to_be_read-${#line}-1))

					on_cfd_stderr "$line"
				done
			;;

			"PROCESS_STATE_FATAL")
				Sleep 5
				$SUPERVISORCTL_CMD restart $CFD_PROC_NAME > /dev/null
			;;

			*)
			;;
		esac
	fi

	echo -ne "RESULT 2\nOK"

	log_1 "-----------------------------------------------------"
done

