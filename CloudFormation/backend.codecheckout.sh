#!/bin/bash -ex
#
# CloudEnable code checkout script
#
# Parameters to retrieve the latest tarball with the source
APPLICATION_CODE1=IBLogix.war
APPLICATION_CODE2=dbmigrator.jar
APPLICATION_CODE3=deployer.jar

# Other parameters
DB_SERVER_HOST=`cat /mnt/DB_SERVER_HOST`
FIRSTFUEL_DB_NAME=coal2_master
TRANSFORMATION_DB_NAME=coal2_transformation
WEB_APPLICATION_PREFIX=firstfuel

## General Variables
deploy_date=$(date "+%Y%m%d%H%M%S")

content_dir=/usr/share/tomcat6/releases
current_dir=/usr/share/tomcat6/webapps
working_dir=$content_dir/working
deploy_dir=$content_dir/$deploy_date

## Web document root (may not necessarily be the deploy_dir)
Web_doc_pointer=$deploy_dir

## Working directory (may not necessarily be the deploy_dir)
working_dir_pointer=$deploy_dir

## Find out about the old deploy directory
if [ -e $working_dir ]; then
  old_deploy_dir=$(readlink -n $working_dir)
  old_deploy_date=$(basename $old_deploy_dir)
  [ "$old_deploy_dir" == "$content_dir" ] && old_deploy_date=$(basename $(readlink -n $current_dir))
fi

## General Preparation
echo "General Preparation..."
mkdir -p $content_dir
rm -rf $deploy_dir

## Release/Deploy date of the application
echo "Prepare to deploy..."
mkdir -p $deploy_dir
chmod 775 $deploy_dir

## Retrieve the code from S3 and unpack it
echo "Downloading $APPLICATION_CODE1, $APPLICATION_CODE2 & $APPLICATION_CODE3 from S3:$APPLICATION_CODE_BUCKET..."
mkdir -p $deploy_dir/$WEB_APPLICATION_PREFIX
(cd $deploy_dir/$WEB_APPLICATION_PREFIX; unzip /mnt/$APPLICATION_CODE1)
mv /mnt/$APPLICATION_CODE2 $deploy_dir
mv /mnt/$APPLICATION_CODE3 $deploy_dir

# Get the database connection properties file and replace the values in it
echo "Configuring database"
sed -i "s/ZZZ_DB_SERVER_HOST_ZZZ/$DB_SERVER_HOST/g" /mnt/iblogix_dbconfig.properties
sed -i "s/ZZZ_FIRSTFUEL_DB_NAME_ZZZ/$FIRSTFUEL_DB_NAME/g" /mnt/iblogix_dbconfig.properties
sed -i "s/ZZZ_TRANSFORMATION_DB_NAME_ZZZ/$TRANSFORMATION_DB_NAME/g" /mnt/iblogix_dbconfig.properties
cp /mnt/iblogix_dbconfig.properties $deploy_dir/$WEB_APPLICATION_PREFIX/WEB-INF/classes

# Check if anything was downloaded.
[ -s $deploy_dir ] || exit -1

## Link the Web document root to the current app dir
echo "Linking the Web document root to the current/working application directory..."
[ -h $working_dir ] && unlink $working_dir
ln -nfs $working_dir_pointer $working_dir
[ -h $current_dir ] && unlink $current_dir
ln -nfs $Web_doc_pointer $current_dir

# Create a health check file

mkdir -p $current_dir/ROOT/
cp /mnt/healthcheck.html $current_dir/ROOT

# Change the owner of everything to tomcat
chown -R tomcat:tomcat $deploy_dir

# Finally restart tomcat

if
ps -ef | grep java | grep -v grep
then
pkill java
rm -rf /usr/share/tomcat6/work/*
sleep 10
/etc/init.d/tomcat6 start
else
/etc/init.d/tomcat6 start
fi

