clear
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"




****************************clean the data
clear

use "E:\sand storm\data\data\solar kw\residential_kW.dta", clear

keep VMATCHBK SOLAR_KWAC SOLAR_KWDC SOLAR_DATE

rename VMATCHBK vmatchbk
rename SOLAR_KWAC solar_kwac
rename SOLAR_KWDC solar_kwdc

cd "E:\sand storm\data\data\"

save "residential solar kw.dta", replace



clear

use "E:\sand storm\data\data\solar kw\commercial_kW.dta", clear

keep account_id KWAC KWDC

rename VMATCHBK vmatchbk
rename KWAC solar_kwac
rename KWDC solar_kwdc

cd "E:\sand storm\data\data\"

save "commercial solar kw.dta", replace
