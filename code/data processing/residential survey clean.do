clear
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"




****************************clean the data
clear

import delimited "E:\sand storm\data\data\high frequency data\household survey\Copy of Residential  Equipment & Technology Excel Data File.csv", clear

keep matchbacknumber v194 squarefeet abouthowmanysquarefeetoflivingsp howoldisyourcurrentresidence banner1ageofresidenceyears

rename matchbacknumber vmatchbk
rename v194 ethnic

cd "E:\sand storm\data\data\"

save "household survey.dta", replace




clear

use "residential solar electricity data.dta", clear

gen year=year(DATE)
gen month=month(DATE)
gen day=day(DATE)

keep vmatchbk year month day householdn householdn household_income zipcode svc_zip holiday weekend

duplicates drop vmatchbk year month day, force

cd "E:\sand storm\data\data\"

save "household characteristics.dta", replace

