
import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\cities_by_major_county_with_centers.csv", clear 
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\cities_by_major_county_with_centers.dta", replace

* CO EST DATA

import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\co-est2009-alldata.csv", clear 
gen countynum = state*1000 + county
merge 1:1 countynum using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\cities_by_major_county_with_centers.dta", force
keep if _m == 3
drop _m
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_1.dta", replace


import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\co-est2018-alldata.csv", clear
gen countynum = state*1000 + county
merge 1:1 countynum using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_1.dta", force
keep if _m == 3
drop _m
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_1.dta", replace



* HOUSING

import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\housing\hu-est00int-tot.csv", clear
gen countynum = state*1000 + county
drop if ctyname == ""
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\housing\housing_1.dta", replace
import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\housing\PEP_2018_PEPANNHU_with_ann.csv", clear 
ren geoid2 countynum
merge 1:1 countynum using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\housing\housing_1.dta", force
keep if _m == 3
drop _m

merge 1:1 countynum using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_1.dta", force
keep if _m == 3
drop _m

drop population km latitude longitude geoid geodisplaylabel  countystate county2 region	division	stname sumlev	state	county	ctyname
drop hucen42010 hubase42010 huestbase2000	hucensus2010	huest_2010  census2010pop
order countynum mi  huest_2000 huest_2001 huest_2002 huest_2003 huest_2004 huest_2005 huest_2006 huest_2007 huest_2008 huest_2009 huest72010 huest72011 huest72012 huest72013 huest72014 huest72015 huest72016 huest72017 huest72018

 


order countynum  huest_* popesti* npopchg_* births*  deaths* natural* interna* domesti*  netmig* residual*  gqestim*  rbirth*  rdeath* rnatura* rintern* rdomest*  rnetmig*
drop estimatesbase2010 census2000pop estimatesbase2000 mi 
drop gqestimatesbase2010 gqestimatesbase2000


 

forval i = 2010/2018 {
	ren huest7`i' huest_`i' 
}

reshape long huest_  popestimate npopchg_ births  deaths naturalinc internationalmig domesticmig  netmig residual  gqestimates  rbirth  rdeath rnaturalinc rinternationalmig rdomesticmig  rnetmig, i(countynum) j(date)


sort countynum date

foreach var of varlist rbirth rdeath rnaturalinc rinternationalmig rdomesticmig rnetmig {    
	  
    bysort  countynum   : ipolate `var' date, g(temp)
	replace `var' = temp
	drop temp
	

}

drop if date<2004

sort countynum
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_1.dta", replace






* CC EST DATA
* 2010-2018
import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\cc-est2018-alldata.csv", clear 
gen countynum = state*1000 + county
merge m:1 countynum using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\cities_by_major_county_with_centers.dta", force
keep if _m == 3
drop _m

save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_2.dta", replace

import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\cc_est_2000_2009\cc-est2009-alldata-04.csv", clear 
gen countynum = state*1000 + county
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\cc-est2009-alldata.dta", replace

* 2000-2009
local files : dir "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\cc_est_2000_2009" files "*.csv"
foreach file in `files' {
  dir `file'
  import delimited `file', clear 
  gen countynum = state*1000 + county
  append using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\cc-est2009-alldata.dta"
  save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\cc-est2009-alldata.dta", replace

}

use "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_pop_data\cc-est2009-alldata.dta", replace
duplicates drop state county stname ctyname year agegrp, force

merge m:1 countynum using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\cities_by_major_county_with_centers.dta", force
keep if _m == 3
drop _m

gen data_2000_2009 = 1

append using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_2.dta"
replace data_2000_2009 = 0 if missing(data_2000_2009 )
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_3.dta", replace


use "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_3.dta", replace
drop if year==1 | year==2  
gen date = 1997 + year if data_2000_2009 == 1  
replace date = 2007 + year if data_2000_2009 == 0


drop km sumlev county stname ctyname state year countystate county2 latitude longitude data_2000_2009 population



sort countynum date
levelsof agegrp, local(levels) 
foreach age of local levels {

foreach var of varlist tot_pop tot_male tot_female wa_male wa_female ba_male ba_female ia_male ia_female aa_male aa_female na_male na_female tom_male tom_female wac_male wac_female bac_male bac_female iac_male iac_female aac_male aac_female nac_male nac_female nh_male nh_female nhwa_male nhwa_female nhba_male nhba_female nhia_male nhia_female nhaa_male nhaa_female nhna_male nhna_female nhtom_male nhtom_female nhwac_male nhwac_female nhbac_male nhbac_female nhiac_male nhiac_female nhaac_male nhaac_female nhnac_male nhnac_female h_male h_female hwa_male hwa_female hba_male hba_female hia_male hia_female haa_male haa_female hna_male hna_female htom_male htom_female hwac_male hwac_female hbac_male hbac_female hiac_male hiac_female haac_male haac_female hnac_male hnac_female{
gen `var'_`age'_temp = `var'/mi if agegrp==`age'

by countynum date: egen `var'_`age' = max(`var'_`age'_temp)
drop `var'_`age'_temp
}

}

drop agegrp tot_pop tot_male tot_female wa_male wa_female ba_male ba_female ia_male ia_female aa_male aa_female na_male na_female tom_male tom_female wac_male wac_female bac_male bac_female iac_male iac_female aac_male aac_female nac_male nac_female nh_male nh_female nhwa_male nhwa_female nhba_male nhba_female nhia_male nhia_female nhaa_male nhaa_female nhna_male nhna_female nhtom_male nhtom_female nhwac_male nhwac_female nhbac_male nhbac_female nhiac_male nhiac_female nhaac_male nhaac_female nhnac_male nhnac_female h_male h_female hwa_male hwa_female hba_male hba_female hia_male hia_female haa_male haa_female hna_male hna_female htom_male htom_female hwac_male hwac_female hbac_male hbac_female hiac_male hiac_female haac_male haac_female hnac_male hnac_female
duplicates drop

order countynum date   mi

save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_4.dta", replace


use "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_4.dta", replace
drop if date<2004
merge 1:1 countynum date using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_1.dta" 
drop _m

replace huest_ = popestimate/huest_

foreach var of varlist npopchg_ births deaths naturalinc internationalmig domesticmig netmig residual gqestimates rbirth rdeath rnaturalinc rinternationalmig rdomesticmig rnetmig {
replace `var' = `var'/popestimate
}

save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_5.dta", replace




* income
import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\income\2004.annual.singlefile.csv", clear 

local var  "04013 04019 06001 06013 06019 06037 06059 06065 06067 06071 06073 06085 12011 12057 12086 12095 12099 12103 13121 15003 17031 19049 24031 26125 26163 27053 29189 32003 36005 36047 36059 36061 36081 36103 36119 37119 37183 39035 39049 42003 42101 48029 48085 48201 48439 48453 49035 51059 51119 53033"
display "`var'"
tokenize "`var'"  
local n: word count `var'  
gen keepit = 0
forvalues i = 1/`n' {    
    replace  keepit = 1 if area_fips== "``i''" 
}
keep if keepit==1
keep if own_code==0 &  industry_code=="10"
drop own_code industry_code agglvl_code size_code   qtr disclosure_code
drop keepit lq_disclosure_code lq_annual_avg_estabs lq_annual_avg_emplvl lq_total_annual_wages lq_taxable_annual_wages lq_annual_contributions lq_annual_avg_wkly_wage lq_avg_annual_pay oty_disclosure_code 
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\income\annual.singlefile.dta", replace

forval file = 2005/2018 {
  import delimited "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\income\`file'.annual.singlefile.csv", clear 

local var  "04013 04019 06001 06013 06019 06037 06059 06065 06067 06071 06073 06085 12011 12057 12086 12095 12099 12103 13121 15003 17031 19049 24031 26125 26163 27053 29189 32003 36005 36047 36059 36061 36081 36103 36119 37119 37183 39035 39049 42003 42101 48029 48085 48201 48439 48453 49035 51059 51119 53033"
display "`var'"
tokenize "`var'"  
local n: word count `var'  
gen keepit = 0
forvalues i = 1/`n' {    
    replace  keepit = 1 if area_fips== "``i''" 
}
keep if keepit==1
keep if own_code==0 &  industry_code=="10"
drop own_code industry_code agglvl_code size_code   qtr disclosure_code
drop keepit lq_disclosure_code lq_annual_avg_estabs lq_annual_avg_emplvl lq_total_annual_wages lq_taxable_annual_wages lq_annual_contributions lq_annual_avg_wkly_wage lq_avg_annual_pay oty_disclosure_code 
 
  append using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\income\annual.singlefile.dta"
  save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\income\annual.singlefile.dta", replace
}

use "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\income\annual.singlefile.dta", replace
duplicates drop
destring(area_fips), g(countynum)
drop area_fips
ren year date
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\income\annual.singlefile.dta", replace

merge 1:1 countynum date using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_5.dta"
drop _m


save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_6.dta", replace
 


* Labor Force data
import excel "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\labor_force\laucnty04.xlsx", sheet("laucnty04") cellrange(A5:J3226) firstrow allstring clear
ren B state
ren C county
drop F
ren J ur_rate
drop if _n == 1
save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\labor_force\laucnty.dta", replace

local var "05 06 07 08 09 10 11 12 13 14 15 16 17 18"
display "`var'"
tokenize "`var'"  
local n: word count `var'  
forvalues i = 1/`n' {     
	import excel "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\labor_force\laucnty``i''.xlsx",   cellrange(A5:J3226) firstrow allstring clear
	ren B state
	ren C county
	drop F
	ren J ur_rate
	drop if _n == 1
	append using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\labor_force\laucnty.dta"
	save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\labor_force\laucnty.dta", replace

  }
  
use "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\labor_force\laucnty.dta", replace

drop Code 
destring(state), replace
destring(county), replace
destring(Year), replace
destring(Force), replace force
destring(Employed), replace force
destring(Unemployed), replace force
destring(ur_rate), replace force
gen countynum = state*1000+ county
drop state  county CountyNameStateAbbreviation
ren Year date
ren Force labor_force
ren Employed employed
ren Unemployed unemployed
drop if missing(countynum)
merge 1:1 countynum date using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_6.dta"
keep if _m==3
drop _m


save "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_7.dta", replace

import excel "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\housing\housing_prices_HPI_AT_BDL_county.xlsx", sheet("county") cellrange(B7:H85480) firstrow clear
destring(Year), g(date)
destring(FIPScode), g(countynum)
destring(AnnualChange), g(HPI_perc_chg)
drop HPI HPIwith1990base HPIwith2000base Year AnnualChange FIPScode
drop if date<2004

merge 1:1 countynum date using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_7.dta"
keep if _m==3
drop _m

order County countynum date


export delimited using "C:\Users\canth\Dropbox\UCLA\A2 Neural Networks\project\county macro data\county_macro_data_8.csv", replace


* Run WGCAN feature select in R to get selected_data.csv

