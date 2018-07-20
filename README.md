# check-mysql-galera
Monitor MySQL Galera Cluster

# Synopsis
```
check_mysql_galera.sh: Monitor MySQL/MariaDB Galera cluster

Usage: check_mysql_galera.sh <options>

Available options:

   --host     Hostname to connect to            (MANDATORY)
   --user     User to connect as                (MANDATORY)
   --password User's password to use to connect (MANDATORY)
   --command  <command>                         (MANDATORY)
              Available commands:
              cluster-status   Check state of this host component
              mysql-connected  Check host is connected to cluster
              cluster-size     Check number of cluster hosts
                               Can be used with --warning or --critical
              thread-count     Total number of wsrep (applier/rollbacker) threads
              ready            Whether or not the Galera wsrep provider is ready
              synchronized     Whether or not the local and cluster nodes are in sync
   --help     Prints this help and exit
   --critical Number considered as critical limit for result command
              'cluster-size'
   --warning  Number considered as a warning limit for result command
              'cluster-size'

Examples:

    Check Galera cluster is ready:
    ./check_mysql_galera.sh --host localhost --user mysql_user --password s3cr3T --command ready

    Check Galera cluster size is at least 9 nodes. Report warning is under:
    ./check_mysql_galera.sh --host localhost --user mysql_user --password s3cr3T --command cluster-size --warning 9

Authors: Originally written by Sander Petersson (https://github.com/linpopilan)
         Updated by Emmanuel Quevillon (https://github.com/horkko)
```

# Authors

Originally written by Sander Petersson (https://github.com/linpopilan)

Updated by Emmanuel Quevillon (https://github.com/horkko)
