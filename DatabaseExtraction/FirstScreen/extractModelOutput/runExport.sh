schema=`mysql -uiblogix -piblogix -h multi-tenant.cq9xayr6xhwg.us-east-1.rds.amazonaws.com -e 'show databases'`
for schemata in ${schema}
do

perl extractModelOutput.pl multi-tenant.cq9xayr6xhwg.us-east-1.rds.amazonaws.com  ${schemata}

done
