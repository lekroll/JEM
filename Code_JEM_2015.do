capture log close
set more off
log using Stata_Log_ABINDEX_Aktualisierung.smcl , replace

// HINWEISE
//==========
// 1. DER DATENSATZ zur EWT2012 MIT ALLEN Grund- und SV-Variablen muss bereits geöffnet sein
// Falls dies nicht der Fall ist, bitte die nachfolgende Zeile auskommentieren und Pfad anpassen.

* use "BIBBBAuA_2012_spiel_sv.dta" , clear

// 2. ALLE ERGEBNIS-DATEIEN WERDEN IM AKTUELLEN ARBEITSVERZEICHNIS ABGELEGT

// Ändern Sie das Arbeitsverzeichnis durch AUSKOMMENTIERTEN DER NACHFOLGENDEN ZEILE:

* cd "P:\Daten\Publikationen\2015\2015-03-03 Aktualisierung ABINDEX"



// ZUSPIELEN DER TESTDATEN FUER PROBESYNTAX
//====================================
/*
capture clear
use "P:\Daten\Publikationen\2015\2015-03-03 Aktualisierung ABINDEX/ewt2011.dta", clear
gen n = _n 
sort n
preserve
use "P:\Daten\Publikationen\2015\2015-03-03 Aktualisierung ABINDEX/BIBBBAuA_2012_spiel_sv.dta"  , clear
gen n = _n
sort n
tempfile svtestdaten
save `svtestdaten'
restore
merge 1:1 n using `svtestdaten'
*/


// REKODIERUNGEN
//==============
* Hochrechnungsfaktor
gen phrf = Gew2012

* Hintergrundvariablen
gen frau: frau = S1==2
label define frau 0 "Männer" 1 "Frauen"
label var frau "Geschlecht"

gen age = Zpalter  if  Zpalter  <. & Zpalter  >0
label var age "Alter"
keep if inrange(age,15,65)
sum age

gen agegrp = 1 if inrange(age,18,29) 
replace agegrp = 2 if inrange(age,30,39)
replace agegrp = 3 if inrange(age,40,49)
replace agegrp = 4 if inrange(age,50,59)
replace agegrp = 5 if inrange(age,60,80)
label define agegrp 1 "18-29" 2 "30-39" 3 "40-49" 4 "50-59" 5 "60-65"
label value agegrp agegrp
label var agegrp "Altergruppe"

// Bildung
gen     bildung:bildung= 	1 if inrange(Casmin, 1,3)
replace bildung = 			2 if inrange(Casmin, 4,7)
replace bildung = 			2 if inrange(Casmin, 8,9)
label define bildung 1 "1:primär" 2 "2:sekundär" 3 "3:tertiär"
label var bildung "Bildung n. CASMIN"

// Berufsstatuts
xtile q5EB_isei08 = EB_isei08 [aw=phrf] , nq(5)
gen berufsstatus = 1 if q5EB_isei08==1
replace berufsstatus = 2  if inrange(q5EB_isei08,2,4)
replace berufsstatus = 3 if q5EB_isei08==5
lab def nmh 1 niedrig 2 mittel 3 hoch
lab val berufsstatus nmh
lab var berufsstatus Berufsstatus 

// Arbeitszeit
gen teilzeit = F200<35 // Inkl. Selbst. daher keine Missings
replace teilzeit = . if F200==99


// Arbeitsbedingungen
//===================
* Psychisch
global psywrapper "F411"
global psybelwrapper "F412"

foreach num of numlist 1(1)9 {
	capture: sum ${psybelwrapper}_0`num' if ${psybelwrapper}_0`num' <9 [aw=phrf] , meanonly
	if _rc == 0 {
		local gewicht_0`num' = round(5*(2-r(mean)))
		}
	}
foreach num of numlist 10(1)13 {
	capture: sum ${psybelwrapper}_`num' if ${psybelwrapper}_`num' <9 [aw=phrf] , meanonly
	if _rc == 0 {
		local gewicht_`num' = round(5*(2-r(mean)))
		}
}
gen AB_psy_1  = (${psywrapper}_01==1)*`gewicht_01'  if ${psywrapper}_01 !=9 
gen AB_psy_2  = (${psywrapper}_02==1)*`gewicht_02'  if ${psywrapper}_02 !=9  // low alpha
gen AB_psy_3  = (${psywrapper}_03==1)*`gewicht_03'  if ${psywrapper}_03 !=9  // low alpha
gen AB_psy_4  = (${psywrapper}_04==1)*`gewicht_04'  if ${psywrapper}_04 !=9 
gen AB_psy_5  = (${psywrapper}_05==1) 			    if ${psywrapper}_05 !=9
gen AB_psy_6  = (${psywrapper}_06==1)*`gewicht_06'  if ${psywrapper}_06 !=9 
gen AB_psy_7  = (${psywrapper}_07==1)*`gewicht_07'  if ${psywrapper}_07 !=9 
gen AB_psy_8  = (${psywrapper}_08==1)*`gewicht_08'  if ${psywrapper}_08 !=9 
gen AB_psy_9  = (${psywrapper}_09==1)*`gewicht_09'  if ${psywrapper}_09 !=9 
gen AB_psy_11 = (${psywrapper}_11==1)				if ${psywrapper}_11 !=9 
gen AB_psy_12 = (${psywrapper}_12==1)*`gewicht_11'  if ${psywrapper}_12 !=9 
gen AB_psy_13 = (${psywrapper}_13==1)*`gewicht_12'  if ${psywrapper}_13 !=9 
egen AB_psychisch_MISS = rowmiss(AB_psy_*) 
egen AB_psychisch_Anz = rowtotal(AB_psy_*) if AB_psychisch_MISS==0

label var AB_psy_1 "Termin-Leistungsdruck" 
label var AB_psy_2 "Arbeitsdurchführung genau vorgeschrieben" 
label var AB_psy_3 "Arbeitsgang wiederholt sich " 
label var AB_psy_4 "Neue Aufgaben" 
label var AB_psy_5 "Verbessern von Verfahren" 
label var AB_psy_6 "Bei der Arbeit gestört/unterbrochen werden" 
label var AB_psy_7 "Mindestleistung erfüllen müssen" 
label var AB_psy_8 "Dinge tun, die nicht gelernt" 
label var AB_psy_9 "Verschiedenartige Arbeiten gleichzeitig ausführen" 
label var AB_psy_11 "Kleine Fehler große Folgen" 
label var AB_psy_12 "Bis an Grenze der Leistungsfähigkeit gehen müssen" 
label var AB_psy_13 "Sehr schnell arbeiten müssen" 

alpha AB_psy_* , gen(AB_psychisch_Fac) std casewise item label

* Sozial
global sozwrapper "F700"
global sozbelwrapper "F701"

foreach num of numlist 1(1)9 {
	capture: sum ${sozbelwrapper}_0`num' if ${sozbelwrapper}_0`num' <9 [aw=phrf] , meanonly
	if _rc == 0 {
		local gewicht_0`num' = round(5*(2-r(mean)))
		}
	}
foreach num of numlist 10(1)13 {
	capture: sum ${sozbelwrapper}_`num' if ${sozbelwrapper}_`num' <9 [aw=phrf] , meanonly
	if _rc == 0 {
		local gewicht_`num' = round(5*(2-r(mean)))
		}
}
 gen AB_soz_2  = (${sozwrapper}_02==4)*`gewicht_02'  if ${sozwrapper}_02 !=9 
 gen AB_soz_3  = (${sozwrapper}_03==4)*`gewicht_03'  if ${sozwrapper}_03 !=9  
 gen AB_soz_4  = (${sozwrapper}_04==1)   if ${sozwrapper}_04 !=9 
 gen AB_soz_6  = (${sozwrapper}_06==4)*`gewicht_06'  if ${sozwrapper}_06 !=9 
 gen AB_soz_7  = (${sozwrapper}_07==4)*`gewicht_07'  if ${sozwrapper}_07 !=9 
 gen AB_soz_8  = (${sozwrapper}_08==1)*`gewicht_08'  if ${sozwrapper}_08 !=9 
 gen AB_soz_9  = (${sozwrapper}_09==1)*`gewicht_09'  if ${sozwrapper}_09 !=9 
 gen AB_soz_10 = (${sozwrapper}_10==4)*`gewicht_10'  if ${sozwrapper}_10 !=9 
 gen AB_soz_11 = (${sozwrapper}_11==4)*`gewicht_11'  if ${sozwrapper}_11 !=9 
 gen AB_soz_12 = (${sozwrapper}_12==4)*`gewicht_12'  if ${sozwrapper}_12 !=9 
 gen AB_soz_13 = (${sozwrapper}_13==4)*`gewicht_13'   if ${sozwrapper}_13 !=9 
egen AB_sozial_MISS = rowmiss(AB_soz_*)
egen AB_sozial_Anz = rowtotal(AB_soz_*) if AB_sozial_MISS==0

label var AB_soz_2 "... mangelnde Möglichkeit, Arbeit selbst zu organisieren" 
label var AB_soz_3 "... mangelnden Einfluss auf Arbeitsmenge" 
label var AB_soz_4 "... emotionale Beanspruchung bei Arbeit" 
label var AB_soz_6 "... mangelnde Entscheidungsfreiheit bei Pauseneinteilung" 
label var AB_soz_7 "... mangelndes Gefühl, dass Arbeit wichtig" 
label var AB_soz_8 "... mangelnde Informationen über Entwicklungen im Betrieb" 
label var AB_soz_9 "... mangelnde Informationen zu eigener Tätigkeit" 
label var AB_soz_10 "... mangelndes Gemeinschaftsgefühl" 
label var AB_soz_11 "... schlechte Zusammenarbeit mit Kollegen" 
label var AB_soz_12 "... mangelnde Hilfe/Unterstützung durch Kollegen" 
label var AB_soz_13 "... mangelnde Hilfe/Unterstützung durch direkten Vorgesetzten" 

alpha AB_soz_* , gen(AB_sozial_Fac) std casewise item label


* Zeitlich
gen AB_zeit_1 = F204==4     if F204 !=9  
gen AB_zeit_2 = F214==1     if F214 !=9
gen AB_zeit_3 = F216==1     if F216 !=9 
gen AB_zeit_4 = F218==1     if F218 !=9 
gen AB_zeit_5 = F221==1     if F221 !=9 
gen AB_zeit_6 = F209==2     if F209 !=9
gen AB_zeit_7 = inrange(F210_02,1,30)     
gen AB_zeit_8 = AZ>=48      if AZ<.
egen AB_zeitlich_MISS = rowmiss(AB_zeit_*)
egen AB_zeitlich_Anz = rowtotal(AB_zeit_*) if AB_zeitlich_MISS==0
label var AB_zeit_1 "... Überstunden ohne Ausgleich" 
label var AB_zeit_2 "... Pausen fallen aus" 
label var AB_zeit_3 "... Bereitschaftsdienst/Rufbereitschaft" 
label var AB_zeit_4 "....Samstagsarbeit" 
label var AB_zeit_5 "... Sonntags-/Feiertagsarbeit" 
label var AB_zeit_6 "... zwischen 19 und 7 Uhr"
label var AB_zeit_7 "... mind. 1 Nachtschicht pro Monat"
label var AB_zeit_8 "... Wochenarbeitszeit >=48 Stunden"

alpha AB_zeit_* , gen(AB_zeitlich_Fac) std casewise item label

* Ergonomisch
gen AB_ergo_1 = F600_01==1  if F600_01 !=9 
gen AB_ergo_2 = F600_07a==1 if F600_07a!=9 
gen AB_ergo_3 = F600_03==1  if F600_03 !=9 
gen AB_ergo_4 = F600_07b==1  if F600_07b!=9 
egen AB_ergonomisch_MISS = rowmiss(AB_ergo_*)
egen AB_ergonomisch_Anz = rowtotal(AB_ergo_*) if AB_ergonomisch_MISS==0

label var AB_ergo_1 "... Stehen" 
label var AB_ergo_2 "... Hohe Geschicklichkeit, schnelle Abläufe" 
label var AB_ergo_3 "... Heben und tragen schwerer Lasten" 
label var AB_ergo_4 "... Zwangshaltungen" 

alpha AB_ergo_* , gen(AB_ergonomisch_Fac) std casewise item label

* Umweltbezogen
gen AB_umg_1  = F600_04==1  if F600_04 !=9 
gen AB_umg_2  = F600_05==1  if F600_05 !=9 
gen AB_umg_3  = F600_06==1  if F600_06 !=9 
gen AB_umg_4  = F600_08==1  if F600_08 !=9 
gen AB_umg_5  = F600_09==1  if F600_09 !=9 
gen AB_umg_6  = F600_10==1  if F600_10 !=9 
gen AB_umg_7  = F600_11==1  if F600_11 !=9 
gen AB_umg_8  = F600_12==1  if F600_12 !=9 
gen AB_umg_10 = F601==1  if F601 !=9 
egen AB_umgebung_MISS = rowmiss(AB_umg_*)
egen AB_umgebung_Anz = rowtotal(AB_umg_*) if AB_umgebung_MISS==0

label var AB_umg_1 "... bei Rauch, Staub oder unter Gasen, Dämpfen?" 
label var AB_umg_2 "... Kälte, Hitze, Nässe, Feuchtigkeit, Zugluft?" 
label var AB_umg_3 "... Öl, Fett, Schmutz, Dreck?" 
label var AB_umg_4 "... starken Erschütterungen, Stößen, Schwingungen?" 
label var AB_umg_5 "... grellem Licht oder schlechter Beleuchtung?" 
label var AB_umg_6 "... gefährlichen Stoffen, unter Einwirkung von Strahlung" 
label var AB_umg_7 "... Schutzkleidung oder Schutzausrüstung?" 
label var AB_umg_8 "... Lärm?" 
// label var AB_umg_9 "... mikrobiologischen Stoffen?" 
label var AB_umg_10 "... an einem Platz, an dem geraucht wird?" 

alpha AB_umg_* , gen(AB_umgebung_Fac) std casewise item label

* Sonder-Index 1: ABgHfktRSGD 
gen ABgHfktRSGD = 5-F600_04 if inrange(F600_04,1,4)

* Sonder-Index 2: ABgHfktHuTsL
gen ABgHfktHuTsL = 5-F600_03 if inrange(F600_03,1,4)


// Labeln der Skalen
label var AB_psychisch_A   "Psychische Beanspruchungen (Anzahl)"
label var AB_sozial_A      "Soziale Beanspruchungen (Anzahl)"
label var AB_zeitlich_A    "Zeitliche Beanspruchungen  (Anzahl)"
label var AB_ergonomisch_A "Ergonomische Belastungen (Anzahl)"
label var AB_umgebung_A    "Umgebungsbelastungen (Anzahl)"
label var ABgHfktRSGD 	   "Index Häufigkeit Rauch, Staub, Gase, Dämpfe"

// Dichotome Indikatorvariablen für bereichsspezifische Beanspruchungen
foreach AB of varlist  AB_*_Anz {
	gen d`AB':gmh = 0 if `AB'<.
	replace d`AB' = 1 if `AB'>1 & `AB'<.
	}
	
label define gmh 0 "keine/eine" 1 "mehrere"
label var dAB_zeitlich    "Zeitliche Beanspruchung"
label var dAB_psychisch   "Psychische Beanspruchung"
label var dAB_ergonomisch "Ergonomische Belastung"
label var dAB_umgebung    "Umgebungsbelastung"
label var dAB_sozial      "Soziale Beanspruchung"

// Arbeitszeit
gen arbeitszeit     = 1 if inrange(AZ,1,34)
replace arbeitszeit = 2 if inrange(AZ,35,40)
replace arbeitszeit = 3 if inrange(AZ,41,47)
replace arbeitszeit = 4 if inrange(AZ,48,150)
label define arbeitszeit 1 "<35" 2 "35-40" 3 "41-47" 4 "48+"
label value arbeitszeit arbeitszeit

// Belastung Gesamt
alpha *ac , gen(AB_g_Gesamt) casewise item label

// Psychosoziale und Physische Belastung getrennt
alpha AB_psychis~c  AB_zeitlic~c  AB_sozial_~c , std  gen(AB_g_psychsozial) casewise item label
alpha AB_umgebun~c  AB_ergonom~c , gen(AB_g_physisch) std casewise item label

// Zusammenfassung der Skalen
//============================
sum AB_ergonom~c  AB_umgebun~c  AB_g_phy AB_psychis~c  ///
	AB_sozial_~c  AB_zeitlic~c   AB_g_psy  AB_g_Gesamt 

foreach var of varlist AB_psychisch_Anz AB_sozial_Anz AB_zeitlich_Anz AB_ergonomisch_Anz AB_umgebung_Anz {
quietly: sum `var'
gen z`var' = `var'/r(max) if `var' <.
}	
	
// Belastungsindex
//================
xtile AB_g_Gesamt_Q5 = AB_g_Gesamt [aw=phrf]  , nq(5)
gen BINDEX:BINDEX = 0 if AB_g_Gesamt_Q5<=2
replace BINDEX    = 1 if AB_g_Gesamt_Q5==3
replace BINDEX    = 2 if AB_g_Gesamt_Q5>3  & AB_g_Gesamt_Q5<.
label var BINDEX "Beanspruchung durch Arbeit (Ausmaß)"
label define BINDEX 0 "gering" 1 "mäßig" 2 "stark"

// Berechnung KiBBS für ISCO-CODES / KldB-92 
//================================================
/* Erwerbsberuf ist in Variable F100_XXXX (Erwerbsberuf) abgefragt */
* 5-Steller (nur KldB-2010)
ren f100_kldb2010 KldB2010_5
gen Anforderungsniveau_KldB_2010:Anforderungsniveau_KldB_2010 = KldB2010_5-floor(KldB2010_5/10)*10 if KldB2010_5>0 
lab def Anforderungsniveau_KldB_2010 1 "Helfer- und Anlerntätigkeiten" 2 "fachlich ausgerichtete Tätigkeiten" 3 "komplexe Spezialistentätigkeiten" 4 "hoch komplexe Tätigkeiten"
tab Anforderungsniveau_KldB_2010 , gen(afnkldb2010_)

* 4-Steller
gen KldB2010_4 = floor(KldB2010_5/10)
ren f100_isco88 ISCO88_4
ren f100_isco08 ISCO08_4

* 3-Steller
ren F100_kldb2010_3d KldB2010_3
ren F100_isco88_3d ISCO88_3
ren F100_isco08_3d ISCO08_3

* 2-Steller
ren F100_kldb2010_2d KldB2010_2
ren F100_isco88_2d ISCO88_2
ren F100_isco08_2d ISCO08_2

* KldB-92 
ren f100_kldb92 KldB92_4
gen KldB92_3 = floor(KldB92_4/10)
gen KldB92_2 = floor(KldB92_ 4/100)

foreach var of varlist 	KldB92_? ISCO08_? ISCO88_? KldB2010_? {
	replace `var' = . if `var' <=0
	}

* Berechnung der JEM
//==================
// Variablen für Regression
sum age
gen zage = (age-r(mean))/r(sd)
gen zageXfrau = zage*frau
gen AZu35 = AZ<35
gen lnAZ = ln(AZ) if AZ<.

global Kontrollvariablen "frau zage lnAZ lnseitwannbesch "
gen lnseitwannbesch = ln(2012-F511_j) if F511_j<=2012
replace lnseitwannbesch = ln(1) if (2012-F511_j)==0

ren AB_g_Gesamt ABgGes 
ren AB_g_psychsozial ABgpsy
ren AB_g_physisch ABgphy

// Schleife zur Berechnung für alle Klassifikationen
foreach avar in  ABgGes ABgphy ABgpsy ABgHfktRSGD ABgHfktHuTsL {
	di as result "`avar'"
	di as text "=============================" _newline
	
	// KldB2010
	xtmixed  `avar'  $Kontrollvariablen  ///
		afnkldb2010_2 afnkldb2010_3 afnkldb2010_4  || KldB2010_2 : || KldB2010_3 : || KldB2010_4 : , mle  iterate(40)
	est store `avar'_kldb2010
	local ml1 = e(ll)
	quietly : xtmixed  `avar' if e(sample)
	est store `avar'_kldb2010_m0
	est stat `avar'_kldb2010_m0 `avar'_kldb2010
	local ml0 = e(ll)
	est restore `avar'_kldb2010
	xtmrho
	estat vce , correlation
	local r2p = 1-(`ml1'/`ml0')
	di as text "Pseudo R² nach MacFadden:" as result %5,3f "`r2p'"
	quietly: predict KiBB_ref_* , reff
	d KiBB_ref_*
	* 2 Steller
	quietly: gen KiBB_KldB2010_2_`avar' = _b[`avar':_cons] + KiBB_ref_1
	* 3 Steller
	quietly: gen     KiBB_KldB2010_3_`avar' = KiBB_KldB2010_2_`avar'
	quietly: replace KiBB_KldB2010_3_`avar' = KiBB_KldB2010_3_`avar'   + KiBB_ref_2 if KiBB_ref_2 <.
	* 4 Steller
	quietly: gen     KiBB_KldB2010_4_`avar' = KiBB_KldB2010_3_`avar'
	quietly: replace KiBB_KldB2010_4_`avar' = KiBB_KldB2010_4_`avar' + KiBB_ref_3 if KiBB_ref_3 <.
	* 5 Steller
	quietly: gen     KiBB_KldB2010_5_`avar' = KiBB_KldB2010_4_`avar'
	quietly: replace KiBB_KldB2010_5_`avar' = KiBB_KldB2010_4_`avar' ///
											+ _b[`avar':afnkldb2010_2]*afnkldb2010_2 ///
											+ _b[`avar':afnkldb2010_3]*afnkldb2010_3 ///
											+ _b[`avar':afnkldb2010_4]*afnkldb2010_4 ///
											if afnkldb2010_2<.
	quietly: drop KiBB_ref_*
	
	// KldB92
	xtmixed  `avar'  $Kontrollvariablen  || KldB92_2 : || KldB92_3 : || KldB92_4 : , mle  iterate(40)
	est store `avar'_kldb92
	local ml1 = e(ll)
	quietly : xtmixed  `avar' if e(sample)
	est store `avar'_kldb92_m0
	est stat `avar'_kldb92_m0 `avar'_kldb92
	local ml0 = e(ll)
	est restore `avar'_kldb92
	xtmrho
	estat vce , correlation
	local r2p = 1-(`ml1'/`ml0')
	di as text "Pseudo R² nach MacFadden:" as result %5,3f "`r2p'"
	quietly: predict KiBB_ref_* , reff
	* 2 Steller
	quietly: gen KiBB_KldB92_2_`avar' = _b[`avar':_cons] + KiBB_ref_1
	* 3 Steller
	quietly: gen     KiBB_KldB92_3_`avar' = KiBB_KldB92_2_`avar'
	quietly: replace KiBB_KldB92_3_`avar' = KiBB_KldB92_3_`avar'   + KiBB_ref_2 if KiBB_ref_2 <.
	* 4 Steller
	quietly: gen     KiBB_KldB92_4_`avar' = KiBB_KldB92_3_`avar'
	quietly: replace KiBB_KldB92_4_`avar' = KiBB_KldB92_4_`avar' + KiBB_ref_3 if KiBB_ref_3 <.
	quietly: drop KiBB_ref_*
	
	// ISCO-88
	xtmixed `avar'  $Kontrollvariablen  || ISCO88_2 :   || ISCO88_3 : || ISCO88_4 : , mle iterate(40) 
	est store `avar'_isco88
	local ml1 = e(ll)
	quietly : xtmixed  `avar' if e(sample)
	est store `avar'_isco88_m0
	local ml0 = e(ll)
	est stat `avar'_isco88 `avar'_isco88_m0
	est restore `avar'_isco88
	xtmrho
	estat vce , correlation
	local r2p = 1-(`ml1'/`ml0')
	di as text "Pseudo R² nach MacFadden:" as result %5,3f "`r2p'"
	quietly: predict KiBB_ref_* , reff
	* 2 Steller
	quietly:  gen KiBB_ISCO_88_2_`avar' = _b[`avar':_cons] + KiBB_ref_1
	* 3 Steller
	quietly: gen     KiBB_ISCO_88_3_`avar' = KiBB_ISCO_88_2_`avar'
	quietly:  replace KiBB_ISCO_88_3_`avar' = KiBB_ISCO_88_3_`avar' + KiBB_ref_2 if KiBB_ref_2 <.
	* 4 Steller
	quietly: gen     KiBB_ISCO_88_4_`avar' = KiBB_ISCO_88_3_`avar' 
	quietly: replace KiBB_ISCO_88_4_`avar' = KiBB_ISCO_88_4_`avar' + KiBB_ref_3 if KiBB_ref_3 <.
	quietly: drop KiBB_ref*
	
	// ISCO-08
	xtmixed `avar'  $Kontrollvariablen  || ISCO08_2 :   || ISCO08_3 : || ISCO08_4 : , mle iterate(40) 
	est store `avar'_isco08
	local ml1 = e(ll)
	quietly : xtmixed  `avar' if e(sample)
	est store `avar'_isco08_m0
	local ml0 = e(ll)
	est stat `avar'_isco08 `avar'_isco08_m0
	est restore `avar'_isco08
	xtmrho
	estat vce , correlation
	local r2p = 1-(`ml1'/`ml0')
	di as text "Pseudo R² nach MacFadden:" as result %5,3f "`r2p'"
	quietly: predict KiBB_ref_* , reff
	* 2 Steller
	quietly:  gen KiBB_ISCO_08_2_`avar' = _b[`avar':_cons] + KiBB_ref_1
	* 3 Steller
	quietly: gen     KiBB_ISCO_08_3_`avar' = KiBB_ISCO_08_2_`avar'
	quietly:  replace KiBB_ISCO_08_3_`avar' = KiBB_ISCO_08_3_`avar' + KiBB_ref_2 if KiBB_ref_2 <.
	* 4 Steller
	quietly: gen     KiBB_ISCO_08_4_`avar' = KiBB_ISCO_08_3_`avar' 
	quietly: replace KiBB_ISCO_08_4_`avar' = KiBB_ISCO_08_4_`avar' + KiBB_ref_3 if KiBB_ref_3 <.
	quietly: drop KiBB_ref*
	
	}

foreach KiBB of varlist KiBB_* {
	quietly {
		xtile Q10`KiBB' =  `KiBB' [pw=phrf] , nq(10)
		replace `KiBB' =  Q10`KiBB'
		drop Q10`KiBB'
		compress `KiBB'
		}
	}

sum *KiBB*
est tab *92 *88 , eq(1) b(%4,3f) stat(chi2_c p_c N rho1 rho2 rho3) star 

// Export der Ergebnisse
//======================
keep KldB92_? ISCO08_? ISCO88_? KldB2010_? KiBB_*

foreach klassifikation in KldB92 ISCO08 ISCO88 KldB2010  {
	preserve
	keep `klassifikation'_2 `klassifikation'_3 `klassifikation'_4 KiBB_*
	order `klassifikation'_2 `klassifikation'_3 `klassifikation'_4
	capture order `klassifikation'_2 `klassifikation'_3 `klassifikation'_4 `klassifikation'_5
	if _rc==0 {
		by `klassifikation'_2 `klassifikation'_3 `klassifikation'_4 `klassifikation'_5 , sort: keep if _n==1
		}
	capture order `klassifikation'_2 `klassifikation'_3 `klassifikation'_4 `klassifikation'_5
	if _rc!=0 {
		by `klassifikation'_2 `klassifikation'_3 `klassifikation'_4 , sort: keep if _n==1
		}
	foreach var of varlist KiBB_* {
		local newname = subinstr("`var'","KiBB_","",1)
		ren `var' `newname'
		}
	export excel using "`klassifikation'_Ergebnisse.xlsx", firstrow(variables) nolabel  replace
	restore	
	}

// Abschluss
local Verzeichnis = c(pwd)

di as text "Bitte übersenden Sie mir die vier generierten Excel-Dateien (enthalten keine Individualdaten)"
di as text "und die Datei " as result "Stata_Log_ABINDEX_Aktualisierung.smcl" as text "aus dem Verzeichnis: " as result "`Verzeichnis'" 
di as text "Danke, Lars Kroll (l.kroll@rki.de)."
log close 
exit
