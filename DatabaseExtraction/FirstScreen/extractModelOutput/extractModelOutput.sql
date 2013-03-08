select t.subdomain_name as tenantName, bldg.name as buildingName, an.analysis_id, date_format(from_date, '%Y%m%d') fromDate, date_format(to_date, '%Y%m%d') toDate ,
DAY_type,HOUR,HOURLYABS,DBABS,0,0,WINDABS,SUNABS,PREDicted,actual,TEMP,WetBULB,DEWPOINT,WINDSPEED,SKY,DAYLIGHTHOUR,HOLIDAY,date_format(Day,'%m/%d/%Y'),global_horizontal_irradiance
from building bldg join analysis an on an.building_id = bldg.id and bldg.is_archived = 0
join rats_raw_data rrd on rrd.analysis_id = an.analysis_id and rrd.day between from_date and to_date
join tenant_details t
order by analysis_id, day,hour