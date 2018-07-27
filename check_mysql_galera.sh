#!/bin/bash

# Default values for variables
HOST=""
USER=""
PASSWORD="fakepass"
COMMAND=""

usage() {
	echo -e ""
	echo -e "check_mysql_galera.sh: Monitor MySQL/MariaDB Galera cluster"
	echo -e -e ""
	echo -e "Usage: check_mysql_galera.sh <options>"
	echo -e ""
	echo -e "Available options:"
	echo -e ""
	echo -e "   --host     Hostname to connect to            (MANDATORY)"
	echo -e "   --user     User to connect as                (MANDATORY)"
	echo -e "   --password User's password to use to connect (MANDATORY)"
	echo -e "   --command  <command>                         (MANDATORY)"
	echo -e "              Available commands:"
	echo -e "              cluster-status   Check state of this host component"
	echo -e "              mysql-connected  Check host is connected to cluster"
	echo -e "              cluster-size     Check number of cluster hosts"
	echo -e "                               Can be used with --warning or --critical"
	echo -e "              thread-count     Total number of wsrep (applier/rollbacker) threads"
	echo -e "              ready            Whether or not the Galera wsrep provider is ready"
	echo -e "              synchronized     Whether or not the local and cluster nodes are in sync"
	echo -e "   --help     Prints this help and exit"
	echo -e "   --critical Number considered as critical limit for result command"
	echo -e "              'cluster-size'"
	echo -e "   --warning  Number considered as a warning limit for result command"
	echo -e "              'cluster-size'"
	echo -e ""
	echo -e "Examples:"
	echo -e ""
	echo -e "    Check Galera cluster is ready:"
	echo -e "    $0 --host localhost --user mysql_user --password s3cr3T --command ready"
	echo -e ""
	echo -e "    Check Galera cluster size is at least 9 nodes. Report warning is under:"
	echo -e "    $0 --host localhost --user mysql_user --password s3cr3T --command cluster-size --warning 9"
	echo -e ""
	echo -e "Authors: Originally written by Sander Petersson (https://github.com/linpopilan)"
	echo -e "         Updated by Emmanuel Quevillon (https://github.com/horkko)"
	echo -e ""
}

# Checks that required mysql options are set
check_connection() {
	if [ "${HOST}" = "" ];then
		error "--host option must be set"
	fi
	if [ "${USER}" = "" ];then
		error "--user option must be set"
	fi
	if [ "${PASSWORD}" = "fakepass" ];then
		error "--password options must be set!"
	fi
	mysql -h "${HOST}" -u "${USER}" --password="${PASSWORD}" -e "quit" || \
		error "Can't connect to mysql server"
}

error() {
	local err
	err=$1
	echo -e "check_mysql_galera: ERROR: ${err}" 1>&2
	echo -e "Try check_mysql_galera --help to get more help" 1>&2
	exit 1
}

mysqlconnect () {
	local cmd
	cmd="${1}"
	mysql -h "${HOST}" -u "${USER}" --password="${PASSWORD}" -s -B -N -e "${cmd}" | sed -e 's/[[:space:]]\{1,\}/,/g' | cut -d"," -f2
}

checkquery () {

	galera_cluster_status () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_cluster_status';")

		case $value in
			Primary )
				echo -e "Status: $value"
				exit 0
				;;

			NON_PRIMARY )
				echo -e "Status: $value"
				exit 2
				;;

			DISCONNECTED )
				echo -e "Status: $value"
				exit 2
				;;

			* )
				echo -e "Status: $value"
				exit 3
				;;
		esac
	}

	galera_connected () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_connected';")

		case $value in
			ON )
				echo -e "Status: $value"
				exit 0
				;;
			OFF )
				echo -e "Status: $value"
				exit 2
				;;
			* )
				echo -e "Status: $value"
				exit 3
				;;
		esac
	}

	galera_cluster_size () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_cluster_size';")

		if [[ $value -le $CRITICAL ]]; then
			echo -e "CRITICAL! Number of nodes connected: $value"
			exit 2
		elif [[ $value -le $WARNING ]]; then
			echo -e "WARNING! Number of nodes connected: $value"
			exit 1
		else
			echo -e "OK! Number of nodes connected: $value"
			exit 0
		fi
	}

	galera_thread_count () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_thread_count';")

		if [[ $value -lt 0 ]]; then
			echo -e "CRITICAL! Galera thread count: $value"
			exit 2
		else
			echo -e "OK! Galera thread count: $value"
			exit 0
		fi
	}

	galera_ready () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_ready';")

		case $value in
			ON )
				echo -e "OK! Galera provider is ready"
				exit 0
				;;
			OFF)
				echo -e "CRITICAL! Galera provider is not ready"
				exit 2
				;;
		esac

	}

	galera_cluster_synced () {
		node_uuid=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_local_state_uuid';")
		cluster_uuid=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_cluster_state_uuid';")

		if [ "${node_uuid}" = "" ] && [ "${cluster_uuid}" = "" ];then
			echo "CRITICAL! Could not get UUID from node nor cluster"
			exit 1
		fi
		if [ "${node_uuid}" = "${cluster_uuid}" ];then
		  echo -e "OK! Node synchronized with cluster"
		  exit 0
		else
		  echo -e "CRITICAL! Node not synchronized with cluster"
		  exit 1
		fi
	}

	case $1 in
		cluster-status )
			galera_cluster_status
			;;
		mysql-connected )
			galera_connected
			;;
		cluster-size )
			galera_cluster_size
			;;
		thread-count )
			galera_thread_count
			;;
		ready )
			galera_ready
			;;
		synchronized )
			galera_cluster_synced
			;;
		* )
			error "Unsupported command '$1'"
	esac

}

[[ "${#}" = "0" ]] && echo -e "To get usage, try --help option." && exit 1

while [[ ${#} > 0 ]]; do

	key="${1}"

	case $key in
		--host )
			HOST="${2}"
			shift
			;;
		--user )
			USER="${2}"
			shift
			;;
		--password )
			PASSWORD="${2}"
			shift
			;;
		--command )
			COMMAND="${2}"
			shift
			;;
		--warning )
			WARNING="${2}"
			shift
			;;
		--critical )
			CRITICAL="${2}"
			shift
			;;
		--help )
			usage
			exit 0
			;;
		* )
			error "Unsupported option $key"
			;;
	esac
	shift

done

{ check_connection && checkquery "${COMMAND}"; } || error "Can't run command ${COMMAND}"

exit 0
