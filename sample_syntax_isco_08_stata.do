* Append JEM using  ISCO-08
//=========================
* Save a temporary dataset of your input data
tempfile inputdataset 
capture erase `inputdataset' 
save `inputdataset' , replace

* Create temporary datasets from JEM-Masterfile for 2-, 3- and 4-digit ISCO-08 codes
preserve 
tempfile matchdata4digit
tempfile matchdata3digit
tempfile matchdata2digit

use Kroll_2015_JEM.dta if (classification == "isco08")  & (digit == 4) , clear
drop classification digit
sort code
di _N
compress
save `matchdata4digit' , replace

use Kroll_2015_JEM.dta if (classification == "isco08")  & (digit == 3), clear
drop classification digit
sort code
di _N
compress
save `matchdata3digit' , replace

use Kroll_2015_JEM.dta if (classification == "isco08")  & (digit == 2) , clear
drop classification digit
sort code
di _N
compress
save `matchdata2digit' , replace
restore

// Merge temporary datasets using 4,3,2-digit ISCO-08 Codes to inputdataset
// Note: ISCO-08 vars need to be integers with missing values defined as system missing

use `inputdataset' , clear
gen code = isco_08_4_digit_var if isco_08_4_digit_var<10000
sort code 
merge m:1 code using `matchdata4digit'  , nogen keep(1 3)

replace code = isco_08_3_digit_var if isco_08_3_digit_var<10000
sort code
merge m:1 code using `matchdata3digit' , update keep(1 3 4 5) nogen

replace code = isco_08_2_digit_var if isco_08_2_digit_var<10000
sort code 
merge m:1 code using `matchdata2digit' ,  update keep(1 3 4 5) nogen

drop code 

// Categorize Work Exposure vars
lab def lmh 1 "low" 2 "medium" 3 "high"
foreach var of varlist OJI OPI OSI CAI {
	local vlab : var label `var'
	gen `var'_k:lmh = 1 if inrange(`var',1,2)
	replace `var'_k     = 2 if inrange(`var',3,8)
	replace `var'_k     = 3 if inrange(`var',9,10)
	lab var `var'_k "`vlab'"
	}


