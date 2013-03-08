# script to extract model output data and create model output files.
# The script extracts model output data for all non archived buildings only.
# The command should pass in the tenant name that it wants to process
# NOTE:
# Before running the script please change the DB credentials for appropriate server

use strict;

my $extractModelOpSql = "extractModelOutput.sql";
my $currentTime = `date +%Y%m%d-%H%M`;

# getting rid of the newline character 
chop($currentTime);

my $fileExtractName = "$ARGV[1]_$currentTime";

my $mysqlCmd = "/usr/local/mysql/bin/mysql -u iblogix -piblogix -h $ARGV[0] $ARGV[1] < $extractModelOpSql > $fileExtractName ";



# check arguments.

if (($#ARGV +1) != 2 ) {
    print "usage: Please provide Database Host and Tenant name\neg: extractModelOutput.pl localhost dod\n";
    exit;
}


print "Data extract will be stored in $fileExtractName \n";


# Run mysql command and extract data
print "Mysql command $mysqlCmd \n";

my @bldNames;

eval {
   my $op = system($mysqlCmd);
   
   #print ("sed 's/\t/,/g' $fileExtractName > $fileExtractName.csv");
   
   # convert tab characters to comma   
   system("sed 's/\t/,/g' $fileExtractName > $fileExtractName.csv");
   
   #extract building metadata
   @bldNames = `cut -d ',' -f 1-5 $fileExtractName.csv |sort |uniq`;
};

if ($@) {
    print "ERROR: Failed to execute MYSQL command \n";
}

my $buildingInfo = "";

# iterate through all the buildings and create model output file.

foreach $buildingInfo (@bldNames) {
# print ("$buildingInfo");
 
 my($tenantName, $buildingName, $analysisId, $fromDate, $toDate) = split(',', $buildingInfo);
 
 $buildingName =~ s/\s/_/g;
 
 #remove new line character from the toDate 
 chomp($toDate);
 my $modelOutputFileName = $tenantName."_".$buildingName."_".$analysisId."_".$fromDate."_".$toDate.'.csv';
 
 print ("model output file name: ".$modelOutputFileName."\n");
 
 # print the header to the file
 `echo "DAY,HOUR,HOURLYABS,WBDBDPABS,NULL,NULL,WINDABS,SUNABS,PRED,ELEC,TEMP,WBULB,DEWPOINT,WINDSPEED,SKY,DAYLIGHTHOUR,HOLIDAY,Date,SolarGHR" > $modelOutputFileName`;
 
 #search by analysis id and grep all the records and append to the model output file.
 my $op = `grep $analysisId $fileExtractName.csv |cut -d ',' -f 6-  |sed 's/NULL//g' >> $modelOutputFileName`;
 
}

print "---------------\n";
