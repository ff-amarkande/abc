# This script download the latest database export from S3 and then imports it into the RDS


# mysql path
#development path
#mysql="/usr/local/mysql/bin/mysql"
#mysqldump="/usr/local/mysql/bin/mysqldump"

# production path
mysql="/usr/bin/mysql"


#environment
#Change the variable value to "gsa" or "multitenant" depending on the environment. This is a prefix used for file names to differentiate.
environment="multitenant"


latestDbExportFile=$environment"_latest.txt"


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


if [ -e $latestDbExportFile ]; then
        echo "INFO: Last data import was from file `cat $latestDbExportFile`"
else        
        echo "INFO: Last data import information not found. Getting the latest export from S3"
fi


echo ""
echo "INFO: Downloading $latestDbExportFile from S3 s3://production_db_dumps/$latestDbExportFile"


s3cmd --force get s3://production_db_dumps/$latestDbExportFile

if [ ! -e $latestDbExportFile ]; then
        echo "ERROR: Last data import information file not found. Aborting import process."
        exit
else        
        echo "INFO: Last data import information found. Getting the latest export from S3"
        
        latestExport=`cat $latestDbExportFile`
        echo "INFO: Downloading $latestExport file from S3. s3://production_db_dumps/$latestExport"
        
        s3cmd get s3://production_db_dumps/$latestExport
        
        if [ ! -e $latestExport ]; then
             echo "ERROR: Latest export file not downloaded from S3. Aborting import process."
             exit
        fi
        
        echo "INFO: Decompressing the database export file."
        gzip -d $latestExport
        
        
        uncompressedFileName=`echo $latestExport | sed s/\.gz$//`
        
        if [ ! -e $uncompressedFileName ]; then
            echo "ERROR: Uncompressed file $uncompressedFileName not found. Aborting import process."
            exit
        fi
        
        echo "INFO: Importing data into RDS from $uncompressedFileName file"
        
        $mysql -u $username -p$passwd -h $hostname < $uncompressedFileName 
        
        echo ""
        echo "INFO: Import data complete."

fi


#end script
endTime=`date`
echo "----------------------$endTime--------------------------------------"
