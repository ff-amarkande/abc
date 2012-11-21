#!/bin/bash -x
#
# CloudEnable code checkout script
#
# Parameters to retrieve the tarball 
FRONTEND_CONSUMER_PACKAGE=s3://DEPLOYMENT_BUCKET/frontend-consumer.tar.gz
FRONTEND_COMMON_PACKAGE=s3://DEPLOYMENT_BUCKET/frontend-common.tar.gz

## General Variables
deploy_date=$(date "+%Y%m%d%H%M%S")
consumer_app_name=$(basename $FRONTEND_CONSUMER_PACKAGE)
common_app_name=$(basename $FRONTEND_COMMON_PACKAGE)

consumer_content_dir=/home/ec2-user/customer.firstfuel.com/deployments-consumer
consumer_current_dir=/home/ec2-user/customer.firstfuel.com/current

common_content_dir=/home/ec2-user/customer.firstfuel.com/deployments-common
common_current_dir=/home/ec2-user/customer.firstfuel.com/releases/common

common_releases_dir=/home/ec2-user/customer.firstfuel.com/releases/
mkdir -p $common_releases_dir

consumer_working_dir=$consumer_content_dir/working
consumer_deploy_dir=$consumer_content_dir/$deploy_date

common_working_dir=$common_content_dir/working
common_deploy_dir=$common_content_dir/$deploy_date

## Web document root (may not necessarily be the consumer_deploy_dir and common_deploy_dir)
Consumer_doc_pointer=$consumer_deploy_dir/frontend/customer
Common_doc_pointer=$common_deploy_dir/frontend/common
Common_working_pointer=$consumer_deploy_dir/frontend/common

## Working directory (may not necessarily be the consumer_deploy_dir and common_deploy_dir)
consumer_working_dir_pointer=$consumer_deploy_dir
common_working_dir_pointer=$common_deploy_dir

## Find out about the old consumer deploy directory
if [ -e $consumer_working_dir ]; then
  old_consumer_deploy_dir=$(readlink -n $consumer_working_dir)
  old_deploy_date=$(basename $old_consumer_deploy_dir)
  [ "$old_consumer_deploy_dir" == "$consumer_content_dir" ] && old_deploy_date=$(basename $(readlink -n $consumer_current_dir))
fi

## Find out about the old common deploy directory
if [ -e $common_working_dir ]; then
  old_common_deploy_dir=$(readlink -n $common_working_dir)
  old_deploy_date=$(basename $old_common_deploy_dir)
  [ "$old_common_deploy_dir" == "$common_content_dir" ] && old_deploy_date=$(basename $(readlink -n $common_current_dir))
fi

## General Preparation
echo "General Preparation..."
mkdir -p $consumer_content_dir
rm -rf $consumer_deploy_dir

mkdir -p $common_content_dir
rm -rf $common_deploy_dir

## Prepare a temporary directory
consumer_temp_dir="/tmp/consumer_s3_temp_$(date "+%s")"
mkdir -p $consumer_temp_dir

common_temp_dir="/tmp/common_s3_temp_$(date "+%s")"
mkdir -p $common_temp_dir

## Retrieve the consumer code from S3 and unpack it
echo "Downloading $FRONTEND_CONSUMER_PACKAGE & $FRONTEND_COMMON_PACKAGE from S3 BUCKET..."
/usr/bin/s3cmd -c /mnt/.s3cfg get $FRONTEND_CONSUMER_PACKAGE $consumer_temp_dir/$consumer_app_name
/usr/bin/s3cmd -c /mnt/.s3cfg get $FRONTEND_COMMON_PACKAGE $common_temp_dir/$common_app_name
# Check if anything was downloaded.
[ -s $consumer_temp_dir/$consumer_app_name ] || exit -1
[ -s $common_temp_dir/$common_app_name ] || exit -1

## Release/Deploy date of the application
echo "Prepare to deploy..."
mkdir -p $consumer_deploy_dir
chmod 775 $consumer_deploy_dir

mkdir -p $common_deploy_dir
chmod 775 $common_deploy_dir

## Unpacking...
echo "Unpacking web application..."
case "$(echo $consumer_app_name | tr A-Z a-z)" in
 *.tar.gz|*.tgz|*.gz)
  echo "Extracting .tar.gz/.tgz/.gz file in $consumer_deploy_dir & $common_deploy_dir..."
  set +e
   tar -xzf $consumer_temp_dir/$consumer_app_name -C $consumer_deploy_dir || exit -1
   tar -xzf $common_temp_dir/$common_app_name -C $common_deploy_dir || exit -1
   exception=$?
  set -e

  if [ "$exception" != "0" ]; then
   echo "Retrying with gzip"
   mv -f $consumer_temp_dir/$consumer_app_name $consumer_deploy_dir
   cd $consumer_deploy_dir && gzip -dv $consumer_app_name
   mv -f $common_temp_dir/$common_app_name $common_deploy_dir
   cd $common_deploy_dir && gzip -dv $common_app_name
  fi
 ;;
 *.tar)
  echo "Extracting .tar file in $consumer_deploy_dir & $common_deploy_dir..."
  tar -xf $consumer_temp_dir/$consumer_app_name -C $consumer_deploy_dir || exit -1
  tar -xf $common_temp_dir/$common_app_name -C $common_deploy_dir || exit -1
 ;;
 *.zip)
  echo "Extracting .zip file in $consumer_deploy_dir & $common_deploy_dir..."
  unzip $consumer_temp_dir/$consumer_app_name -d $consumer_deploy_dir || exit -1
  unzip $common_temp_dir/$common_app_name -d $common_deploy_dir || exit -1
 ;;
 *.war)
  echo "Extracting .war/.jar file in $consumer_deploy_dir & $common_deploy_dir..."
  mv -f $consumer_temp_dir/$consumer_app_name $consumer_deploy_dir
  cd $consumer_deploy_dir && jar -xvf $consumer_app_name || exit -1
  mv -f $common_temp_dir/$common_app_name $common_deploy_dir
  cd $common_deploy_dir && jar -xvf $common_app_name || exit -1
 ;;
 *)
  echo "The file format is currently not supported..."
  exit -1
 ;;
esac

## Cleanup the directory
rm -rf $consumer_temp_dir
rm -rf $common_temp_dir

## Link the Web document root to the current app dir
echo "Linking the Web document root to the current/working application directory..."
[ -h $consumer_working_dir ] && unlink $consumer_working_dir
ln -nfs $consumer_working_dir_pointer $consumer_working_dir
[ -h $consumer_current_dir ] && unlink $consumer_current_dir
ln -nfs $Consumer_doc_pointer $consumer_current_dir

[ -h $common_working_dir ] && unlink $common_working_dir
ln -nfs $common_working_dir_pointer $common_working_dir
[ -h $common_current_dir ] && unlink $common_current_dir
ln -nfs $Common_doc_pointer $common_current_dir
[ -h $Common_working_pointer ] && unlink $Common_working_pointer
ln -nfs $Common_doc_pointer $Common_working_pointer

## Finally copy the config files, cleanup and restart services

if [ -e /mnt/.database.yml ]; then
cp /mnt/.database.yml $consumer_current_dir/config/database.yml
fi
if [ -e $consumer_current_dir/config/settings.yml.sample ]; then
cp $consumer_current_dir/config/settings.yml.sample $consumer_current_dir/config/settings.yml
fi

# Add backend information to the settings.yml file
if [ -e /mnt/.backend.conf ]; then
sed -i '/rest_api_url:.*firstfuel/  c\  rest_api_url: \"http:\/\/'"`cat /mnt/.backend.conf`"'\/firstfuel\/\" ' $consumer_current_dir/config/settings.yml
sed -i '/rest_api_prefix:.*firstfuel/  c\  rest_api_prefix: \"http:\/\/'"`cat /mnt/.backend.conf`"'\/firstfuel\/rest-resource\/\" ' $consumer_current_dir/config/settings.yml
fi

# Finally restart nginx

if
ps -ef | grep nginx | grep -v grep
then
/etc/init.d/nginx restart
else
/etc/init.d/nginx start
fi

# Move the original newrelic.yml
if [ -e $consumer_current_dir/config/newrelic.yml ]; then
mv $consumer_current_dir/config/newrelic.yml $consumer_current_dir/config/newrelic.yml.orig
else
echo "newrelic.yml" file not found
fi

cd $consumer_current_dir
/usr/local/bin/bundle install --without development test &> /tmp/bundle.out
rm -rf $consumer_current_dir/public/assets
cd $consumer_current_dir; /usr/local/bin/ruby  /usr/local/bin/rake assets:precompile RAILS_ENV=production &> /tmp/rake.out 

# Change required permissions
chown -R ec2-user:ec2-user /home/ec2-user/
