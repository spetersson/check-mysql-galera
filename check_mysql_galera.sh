#!/bin/bash

mysqlconnect () {

	mysql -h $HOST -u $USER --password="$PASSWORD" -s -B -N -e "$1" | sed -e 's/[[:space:]]\{1,\}/,/g' | cut -d"," -f2

}

checkquery () {

	galera_cluster_status () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_cluster_status';")

		case $value in
			Primary )
				echo "Status: $value"
				exit 0
				;;

			NON_PRIMARY )
				echo "Status: $value"
				exit 2
				;;

			DISCONNECTED )
				echo "Status: $value"
				exit 2
				;;

			* )
				echo "Status: $value"
				exit 3
				;;
		esac
	}

	galera_connected () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_connected';")

		case $value in
			ON )
				echo "Status: $value"
				exit 0
				;;
			OFF )
				echo "Status: $value"
				exit 2
				;;
			* )
				echo "Status: $value"
				exit 3
				;;
		esac
	}

	galera_cluster_size () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_cluster_size';")

		if [[ $value -le $CRITICAL ]]; then
			echo "CRITICAL! Number of nodes connected: $value"
			exit 2
		elif [[ $value -le $WARNING ]]; then
			echo "WARNING! Number of nodes connected: $value"
			exit 1
		else
			echo "OK! Number of nodes connected: $value"
			exit 0
		fi
	}

	galera_thread_count () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_thread_count';")

		if [[ $value -lt 0 ]]; then
			echo "CRITICAL! Galera thread count: $value"
			exit 2
		else
			echo "OK! Galera thread count: $value"
			exit 0
		fi
	}

	galera_ready () {
		value=$(mysqlconnect "SHOW STATUS LIKE 'wsrep_ready';")

		case $value in
			ON )
				echo "OK! Galera provider is ready"
				exit 0
				;;
			OFF)
				echo "CRITICAL! Galera provider is not ready"
				exit 2
				;;
		esac

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
	esac

}

while [[ $# > 1 ]]; do

	key="$1"

	case $key in
		--host )
			HOST="$2"
			shift
			;;
		--user )
			USER="$2"
			shift
			;;
		--password )
			PASSWORD="$2"
			shift
			;;
		--command )
			checkquery $2
			shift
			;;
		--warning )
			WARNING="$2"
			shift
			;;
		--critical )
			CRITICAL="$2"
			shift
			;;
		* )
			;;
	esac
	shift

done
