clear
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"




****************************clean the data
clear

use "commercial solar electricity data.dta", clear

gen year=year(date)
gen month=month(date)
gen day=day(date)

keep bilacct_k year month day dcharge echarge holiday2 weekend

rename bilacct_k vmatchbk

duplicates drop vmatchbk year month day, force

cd "E:\sand storm\data\data\"

save "commercial characteristics.dta", replace

