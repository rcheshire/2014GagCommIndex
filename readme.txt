readme.txt for analysis of commercial handline index for the 2014 gag update
created 2/5/2014 Rob Cheshire
last edit 2/11/2014 Rob Cheshire (rob.cheshire@noaa.gov)
version control through gitHub
data and output files are confidential and cannot be published

Summary of SEDAR 10 Decisions
-Stephens MacCall Approach
-Handline or electric reel (H or E)
-Exclude area South of 29 degrees Latitude 
-Convert all black grouper to gag for latitude 29 and North
-Exclude March and April from all years due to bag limit starting in 1999
-Limited to ammendment 13 species
-Years: 1992-2004

Changes for 2014 update
- Evaluate 3 GLMs 
	1. all months 1993-2009
	2. May-Dec, 1993-2011
	3. May-Sep, 1993-2012
-3 Area factors defined as NC, SC, and GA+FL


2014 Data
The data provided by SEFSC-Dave Gloeckner for the SEDAR 36 standard assessment included all data through 
2012 and will be used for the gag update.

2014 EDA
Explore effect of trip limit regulations.
Explore effect of 2010 January-April spawning closure.


2014 Update Files
W:\Data\logbookCONFIDENTIAL\logbook_05_13_13.sas7bdat (data input file)
W:\SEDAR\Updates2014\Gag\Indicies\CommHL\Amend_13B_species.xlsx (Snapper-grouper species list used to limit species input to stephens and maccall method)

2014 EDA Files (csv files with same name are output from SAS)
W:\SEDAR\Updates2014\Gag\Indicies\CommHL\landbymonth.xlsx 
W:\SEDAR\Updates2014\Gag\Indicies\CommHL\landbyseason.xlsx
W:\SEDAR\Updates2014\Gag\Indicies\CommHL\cpuebyseason.xlsx

Order of files to reproduce analysis
1.  Gag_SA_CreateSet.SAS  (need to change paths for input output (libname and output paths), CONFIDENTIALITY ISSUES)
2.  gag_glm.rmd  (need to change paths for input/output in header, CONFIDENTIALITY ISSUES)

