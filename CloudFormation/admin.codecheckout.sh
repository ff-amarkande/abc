#!/bin/bash -x
#
# CloudEnable code checkout script
#
# Parameters to retrieve the tarball 
FRONTEND_ADMIN_PACKAGE=s3://DEPLOYMENT_BUCKET/frontend-admin-20121106-0939.tar.gz
FRONTEND_COMMON_PACKAGE=s3://DEPLOYMENT_BUCKET/frontend-admin-20121106-0939.tar.gz

## General Variables
deploy_date=$(date "+%Y%m%d%H%M%S")
admin_app_name=frontend-admin.tar.gz
common_app_name=frontend-common.tar.gz

admin_content_dir=/home/ec2-user/admin.firstfuel.com/deployments-admin
admin_current_dir=/home/ec2-user/admin.firstfuel.com/current

common_content_dir=/home/ec2-user/admin.firstfuel.com/deployments-common
common_current_dir=/home/ec2-user/admin.firstfuel.com/releases/common

common_releases_dir=/home/ec2-user/admin.firstfuel.com/releases/
mkdir -p $common_releases_dir

admin_working_dir=$admin_content_dir/working
admin_deploy_dir=$admin_content_dir/$deploy_date

common_working_dir=$common_content_dir/working
common_deploy_dir=$common_content_dir/$deploy_date

## Web document root (may not necessarily be the admin_deploy_dir and common_deploy_dir)
Admin_doc_pointer=$admin_deploy_dir/frontend/admin
Common_doc_pointer=$common_deploy_dir/frontend/common
Common_working_pointer=$admin_deploy_dir/frontend/common

## Working directory (may not necessarily be the admin_deploy_dir and common_deploy_dir)
admin_working_dir_pointer=$admin_deploy_dir
common_working_dir_pointer=$common_deploy_dir

## Find out about the old admin deploy directory
if [ -e $admin_working_dir ]; then
  old_admin_deploy_dir=$(readlink -n $admin_working_dir)
  old_deploy_date=$(basename $old_admin_deploy_dir)
  [ "$old_admin_deploy_dir" == "$admin_content_dir" ] && old_deploy_date=$(basename $(readlink -n $admin_current_dir))
fi

## Find out about the old common deploy directory
if [ -e $common_working_dir ]; then
  old_common_deploy_dir=$(readlink -n $common_working_dir)
  old_deploy_date=$(basename $old_common_deploy_dir)
  [ "$old_common_deploy_dir" == "$common_content_dir" ] && old_deploy_date=$(basename $(readlink -n $common_current_dir))
fi

## General Preparation
echo "General Preparation..."
mkdir -p $admin_content_dir
rm -rf $admin_deploy_dir

mkdir -p $common_content_dir
rm -rf $common_deploy_dir

## Prepare a temporary directory
admin_temp_dir="/tmp/admin_s3_temp_$(date "+%s")"
mkdir -p $admin_temp_dir

common_temp_dir="/tmp/common_s3_temp_$(date "+%s")"
mkdir -p $common_temp_dir

## Retrieve the admin code from S3 and unpack it
echo "Downloading $FRONTEND_ADMIN_PACKAGE & $FRONTEND_COMMON_PACKAGE from S3 BUCKET..."
/usr/bin/s3cmd -c /mnt/.s3cfg get $FRONTEND_ADMIN_PACKAGE $admin_temp_dir/$admin_app_name
/usr/bin/s3cmd -c /mnt/.s3cfg get $FRONTEND_COMMON_PACKAGE $common_temp_dir/$common_app_name
# Check if anything was downloaded.
[ -s $admin_temp_dir/$admin_app_name ] || exit -1
[ -s $common_temp_dir/$common_app_name ] || exit -1

## Release/Deploy date of the application
echo "Prepare to deploy..."
mkdir -p $admin_deploy_dir
chmod 775 $admin_deploy_dir

mkdir -p $common_deploy_dir
chmod 775 $common_deploy_dir

## Unpacking...
echo "Unpacking web application..."
case "$(echo $admin_app_name | tr A-Z a-z)" in
 *.tar.gz|*.tgz|*.gz)
  echo "Extracting .tar.gz/.tgz/.gz file in $admin_deploy_dir & $common_deploy_dir..."
  set +e
   tar -xzf $admin_temp_dir/$admin_app_name -C $admin_deploy_dir || exit -1
   tar -xzf $common_temp_dir/$common_app_name -C $common_deploy_dir || exit -1
   exception=$?
  set -e

  if [ "$exception" != "0" ]; then
   echo "Retrying with gzip"
   mv -f $admin_temp_dir/$admin_app_name $admin_deploy_dir
   cd $admin_deploy_dir && gzip -dv $admin_app_name
   mv -f $common_temp_dir/$common_app_name $common_deploy_dir
   cd $common_deploy_dir && gzip -dv $common_app_name
  fi
 ;;
 *.tar)
  echo "Extracting .tar file in $admin_deploy_dir & $common_deploy_dir..."
  tar -xf $admin_temp_dir/$admin_app_name -C $admin_deploy_dir || exit -1
  tar -xf $common_temp_dir/$common_app_name -C $common_deploy_dir || exit -1
 ;;
 *.zip)
  echo "Extracting .zip file in $admin_deploy_dir & $common_deploy_dir..."
  unzip $admin_temp_dir/$admin_app_name -d $admin_deploy_dir || exit -1
  unzip $common_temp_dir/$common_app_name -d $common_deploy_dir || exit -1
 ;;
 *.war)
  echo "Extracting .war/.jar file in $admin_deploy_dir & $common_deploy_dir..."
  mv -f $admin_temp_dir/$admin_app_name $admin_deploy_dir
  cd $admin_deploy_dir && jar -xvf $admin_app_name || exit -1
  mv -f $common_temp_dir/$common_app_name $common_deploy_dir
  cd $common_deploy_dir && jar -xvf $common_app_name || exit -1
 ;;
 *)
  echo "The file format is currently not supported..."
  exit -1
 ;;
esac

## Cleanup the directory
rm -rf $admin_temp_dir
rm -rf $common_temp_dir

## Link the Web document root to the current app dir
echo "Linking the Web document root to the current/working application directory..."
[ -h $admin_working_dir ] && unlink $admin_working_dir
ln -nfs $admin_working_dir_pointer $admin_working_dir
[ -h $admin_current_dir ] && unlink $admin_current_dir
ln -nfs $Admin_doc_pointer $admin_current_dir

[ -h $common_working_dir ] && unlink $common_working_dir
ln -nfs $common_working_dir_pointer $common_working_dir
[ -h $common_current_dir ] && unlink $common_current_dir
ln -nfs $Common_doc_pointer $common_current_dir
[ -h $Common_working_pointer ] && unlink $Common_working_pointer
ln -nfs $Common_doc_pointer $Common_working_pointer

## Finally copy the config files, cleanup and restart services

if [ -e /mnt/.database.yml ]; then
cp /mnt/.database.yml $admin_current_dir/config/database.yml
else
echo "database.yml" file not found
fi
if [ -e $admin_current_dir/config/settings.yml.sample ]; then
cp $admin_current_dir/config/settings.yml.sample $admin_current_dir/config/settings.yml
else
echo "settings.yml" file not found
fi

# Add backend information to the settings.yml file
if [ -e /mnt/.backend.conf ]; then
sed -i '/rest_api_url:.*firstfuel/ c\  rest_api_url: \"http:\/\/'"`cat /mnt/.backend.conf`"'\/firstfuel\/\" ' $admin_current_dir/config/settings.yml
sed -i '/rest_api_prefix:.*firstfuel/ c\  rest_api_prefix: \"http:\/\/'"`cat /mnt/.backend.conf`"'\/firstfuel\/rest-resource\/\" ' $admin_current_dir/config/settings.yml
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
if [ -e $admin_current_dir/config/newrelic.yml ]; then
mv $admin_current_dir/config/newrelic.yml $admin_current_dir/config/newrelic.yml.orig
else
echo "newrelic.yml" file not found
fi

cd $admin_current_dir
/usr/local/bin/bundle install --without development test &> /tmp/bundle.out
rm -rf $admin_current_dir/public/assets
cd $admin_current_dir
/usr/local/bin/ruby /usr/local/bin/rake assets:precompile RAILS_ENV=production &> /tmp/rake.out

# Change required permissions
chown -R ec2-user:ec2-user /home/ec2-user/
