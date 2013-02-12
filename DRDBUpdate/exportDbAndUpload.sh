# script export all the database from  a RDS
# 1: The script connects to the database and selects all databases.
# 2: Removes the MYSQL databases names that are not needed to be exported. eg: tmp, performance_schema,innodb,information_schema
# 3: iterates through all the databases and then export them.

# mysql path
#development path
#mysql="/usr/local/mysql/bin/mysql"
#mysqldump="/usr/local/mysql/bin/mysqldump"

# production path
mysql="/usr/bin/mysql"
mysqldump="/usr/bin/mysqldump"

#environment
#Change the variable value to "gsa" or "multitenant" depending on the environment. This is a prefix used for file names to differentiate.
environment="multitenant"

showDbSqlFile="showDb.sql"
tenantNameCsvFile="tenants.csv"

dumpDir="dump/"
latestDbExportFile=$environment"_latest.txt"

fileDumpSuffix="_`date +%y%m%d_%H%M`.sql.gz"
fileDumpPrefix=$environment"_dbExport"

dbExportFileName=$dumpDir$fileDumpPrefix$fileDumpSuffix


hostname=$1
username="iblogix"
passwd="iblogix123"

currentTime=`date`
databases=""


echo "####################################################################"
echo "----------------------$currentTime--------------------------------------"
echo ""

if [ ! -e $mysql ]; then
        echo "ERROR: MYSQL executable not found at $mysql. Please update the path in the script"
        exit
fi

if [ ! -e $mysqldump ]; then
        echo "ERROR: MYSQLDUMP executable not found at $mysqldump. Please update the path in the script"
        exit
fi


echo "Exporting database schemas hosted on $hostname with username: $username"

#getting database names

$mysql -u $username -p$passwd -h $hostname < $showDbSqlFile > $tenantNameCsvFile

while read line
do
        if [[ $line = "mysql" || $line = "Database"  || $line = "tmp" || $line = "performance_schema" || $line = "innodb" || $line = "information_schema" || $line = "iblogix_production" ]] ; then
                echo "INFO: Skipping export of database: $line"
                echo ""
        else
          databases=$databases" $line"

        fi

done < $tenantNameCsvFile

echo "Exporting database: $databases"
# exporting databases 
 $mysqldump -u $username -p$passwd -h $hostname --databases $databases | gzip > $dbExportFileName

echo "Exported data to $dbExportFileName file"

echo "Creating  $dumpDir$latestDbExportFile with latest export file name" 
echo "$fileDumpPrefix$fileDumpSuffix" > $dumpDir$latestDbExportFile


echo "Copying $dbExportFileName to S3 bucket s3://production_db_dumps/ "
s3cmd put $dbExportFileName  s3://production_db_dumps/

#clearing the local disk space as the file is uploaded to S3 now.
rm $dbExportFileName

echo "Copying $latestDbExportFile to S3 bucket s3://production_db_dumps/ "
s3cmd put $dumpDir$latestDbExportFile  s3://production_db_dumps/


#end script
endTime=`date`
echo "----------------------$endTime--------------------------------------"
