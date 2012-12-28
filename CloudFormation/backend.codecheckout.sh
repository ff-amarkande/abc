#!/bin/bash -ex
#
# CloudEnable code checkout script
#
# Parameters to retrieve the latest tarball with the source
#
APPLICATION_CODE1=IBLogix.war
#APPLICATION_CODE2=dbmigrator.jar
#APPLICATION_CODE3=deployer.jar

# Other parameters
#
DB_SERVER_HOST=`cat /mnt/DB_SERVER_HOST`
FIRSTFUEL_DB_NAME=`cat /mnt/FIRSTFUEL_DB_NAME`
TRANSFORMATION_DB_NAME=`cat /mnt/TRANSFORMATION_DB_NAME`
WEB_APPLICATION_PREFIX=firstfuel

# Add SSH keys we'll probably need down the road
#
cat /mnt/ssh_keys >> ~ec2-user/.ssh/authorized_keys

# Define the deployment root
#
deploy_dir=/usr/share/tomcat6/webapps

# Deploy the backend application
#
mkdir -p $deploy_dir/$WEB_APPLICATION_PREFIX
(cd $deploy_dir/$WEB_APPLICATION_PREFIX; unzip /mnt/$APPLICATION_CODE1)
#cp /mnt/$APPLICATION_CODE2 $deploy_dir
#cp /mnt/$APPLICATION_CODE3 $deploy_dir

# Get the database connection properties file and replace the values in it
#
echo "Configuring database"
sed -i "s/ZZZ_DB_SERVER_HOST_ZZZ/$DB_SERVER_HOST/g" /mnt/iblogix_dbconfig.properties
sed -i "s/ZZZ_FIRSTFUEL_DB_NAME_ZZZ/$FIRSTFUEL_DB_NAME/g" /mnt/iblogix_dbconfig.properties
sed -i "s/ZZZ_TRANSFORMATION_DB_NAME_ZZZ/$TRANSFORMATION_DB_NAME/g" /mnt/iblogix_dbconfig.properties
cp /mnt/iblogix_dbconfig.properties $deploy_dir/$WEB_APPLICATION_PREFIX/WEB-INF/classes

# Copy the healthcheck file
#
mkdir -p $deploy_dir/ROOT/
cp /mnt/healthcheck.html $deploy_dir/ROOT

# Change the owner of everything to tomcat
#
chown -R tomcat:tomcat $deploy_dir

# Finally restart tomcat
#
/etc/init.d/tomcat6 restart
