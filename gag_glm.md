2014 Gag Commercial Handline Index of Abundance
========================================================

The 2014 update of the SEDAR 10 (2006) South Atlantic gag stock assessment requires recomputation of the commercial handline index of abundance.  The entire time series must be evaluated as recent trends will influence predictions for previous years.  This document describes changes to the methods as well as consideration of the influence of management decisions. 

**Changes from the SEDAR 10 approach**

1.  The Stephens and MacCall method for determining trips with effort in gag habitat but no catch was modified to exclude associated species with prolonged closures during part of the time series (red porgy and red snapper). The species used as factors to determine the probability of catching gag in a trip was defined as those caught in 1% of trips.  SEDAR 10 used a 5% cutoff.  


2.  The starting year for the index was changed from 1992 to 1993.  The 1992 commercial logbook data collection was voluntary.  For this reason 1992 has been excluded from all recent SEDAR assessed species.


3.  The factor for region was aggregated over the Latitude-level used in SEDAR 10 to 3 levels (North Carolina, South Carolina, and Georgia-North Florida).  This change was made to accomodate smaller samples sizes for reduced data sets discussed below.


4.  Management closures to the gag fishery occured for spawning (Jan-Apr) starting in 2010 and in October 2012 for the quota.  Three options for accounting for these changes were evaluated.  (The SEDAR 10 analysis excluded March and April due to a recreational bag limit imposed on commercial fisheries starting in 1999.) 

  *method1: 1993-2009 including all months (most similar to SEDAR 10 index)
  
  *method2:  1993-2011 excluding Jan-Apr trips (allows for longer time series and accounts for spawning closure)
  
  *method3:  1993-2012 excluding Jan-Apr trips and Oct-Dec trips  (allows for full time series and removes bias associated with spawning closure and quota closure)










**Table 1.** Commercial handline trips through 2009 for all months (method1), through 2011 without Jan-Apr (method2), and through 2012 with only May-Sep (method3).

<!-- html table generated in R 3.0.2 by xtable 1.7-1 package -->
<!-- Thu Feb 20 17:36:44 2014 -->
<TABLE border=1>
<TR> <TH> year </TH> <TH> method1 </TH> <TH> method2 </TH> <TH> method3 </TH>  </TR>
  <TR> <TD align="right"> 1993 </TD> <TD align="right"> 1757 </TD> <TD align="right"> 1524 </TD> <TD align="right"> 996 </TD> </TR>
  <TR> <TD align="right"> 1994 </TD> <TD align="right"> 2176 </TD> <TD align="right"> 1698 </TD> <TD align="right"> 1059 </TD> </TR>
  <TR> <TD align="right"> 1995 </TD> <TD align="right"> 2339 </TD> <TD align="right"> 1876 </TD> <TD align="right"> 1236 </TD> </TR>
  <TR> <TD align="right"> 1996 </TD> <TD align="right"> 2314 </TD> <TD align="right"> 1914 </TD> <TD align="right"> 1229 </TD> </TR>
  <TR> <TD align="right"> 1997 </TD> <TD align="right"> 2156 </TD> <TD align="right"> 1820 </TD> <TD align="right"> 1144 </TD> </TR>
  <TR> <TD align="right"> 1998 </TD> <TD align="right"> 2282 </TD> <TD align="right"> 1877 </TD> <TD align="right"> 1178 </TD> </TR>
  <TR> <TD align="right"> 1999 </TD> <TD align="right"> 1705 </TD> <TD align="right"> 1475 </TD> <TD align="right"> 852 </TD> </TR>
  <TR> <TD align="right"> 2000 </TD> <TD align="right"> 1503 </TD> <TD align="right"> 1365 </TD> <TD align="right"> 847 </TD> </TR>
  <TR> <TD align="right"> 2001 </TD> <TD align="right"> 1746 </TD> <TD align="right"> 1554 </TD> <TD align="right"> 995 </TD> </TR>
  <TR> <TD align="right"> 2002 </TD> <TD align="right"> 1897 </TD> <TD align="right"> 1679 </TD> <TD align="right"> 1036 </TD> </TR>
  <TR> <TD align="right"> 2003 </TD> <TD align="right"> 1672 </TD> <TD align="right"> 1523 </TD> <TD align="right"> 952 </TD> </TR>
  <TR> <TD align="right"> 2004 </TD> <TD align="right"> 1570 </TD> <TD align="right"> 1428 </TD> <TD align="right"> 834 </TD> </TR>
  <TR> <TD align="right"> 2005 </TD> <TD align="right"> 1512 </TD> <TD align="right"> 1380 </TD> <TD align="right"> 934 </TD> </TR>
  <TR> <TD align="right"> 2006 </TD> <TD align="right"> 1486 </TD> <TD align="right"> 1333 </TD> <TD align="right"> 845 </TD> </TR>
  <TR> <TD align="right"> 2007 </TD> <TD align="right"> 1680 </TD> <TD align="right"> 1528 </TD> <TD align="right"> 971 </TD> </TR>
  <TR> <TD align="right"> 2008 </TD> <TD align="right"> 1563 </TD> <TD align="right"> 1410 </TD> <TD align="right"> 908 </TD> </TR>
  <TR> <TD align="right"> 2009 </TD> <TD align="right"> 1623 </TD> <TD align="right"> 1484 </TD> <TD align="right"> 1006 </TD> </TR>
  <TR> <TD align="right"> 2010 </TD> <TD align="right"> NA </TD> <TD align="right"> 1456 </TD> <TD align="right"> 1001 </TD> </TR>
  <TR> <TD align="right"> 2011 </TD> <TD align="right"> NA </TD> <TD align="right"> 1473 </TD> <TD align="right"> 986 </TD> </TR>
  <TR> <TD align="right"> 2012 </TD> <TD align="right"> NA </TD> <TD align="right"> NA </TD> <TD align="right"> 1088 </TD> </TR>
   </TABLE>



```
## elapsed time is 133.290000 seconds
```

```
## elapsed time is 13.930000 seconds
```

Figure 1.  Method 1:  Estimates of species-specific regression coefficients used to estimate a trip's probability of catching gag.



![plot of chunk regcoeffPlotm1](figure/regcoeffPlotm1.png) 

Figure 2.  Method 1:  Absolute difference between observed and predicted number of positive gag trips.  Left and right panels differ only in the range of probabilities shown.

![plot of chunk probabilitym1](figure/probabilitym1.png) 



```
## Start:  AIC=207649
## cpue ~ year + month + STATE
## 
##         Df Deviance    AIC
## <none>      1421601 207649
## - year  16  1433836 207884
## - month  9  1442646 208089
## - STATE  2  1587651 211089
```

```
## Start:  AIC=120620
## cpue ~ year + month + STATE
## 
##         Df Deviance    AIC
## <none>        57419 120620
## - year  16    58301 120780
## - month  9    58844 120912
## - STATE  2    70442 123448
```

```
## Start:  AIC=41157
## cpue ~ year + month + STATE
## 
##         Df Deviance   AIC
## <none>        41101 41157
## - STATE  2    41165 41217
## - month  9    41278 41316
## - year  16    41501 41525
```

```
## [1] "0 (total) records were removed by filter."
## [1] "0 positive records removed by filter."
```

```
## [1] "0 (total) records were removed by filter."
## [1] "0 positive records removed by filter."
```

```
##                    [,1]
## AIC.binomial  4.116e+04
## AIC.lognormal 1.160e+05
## sigma.mle     1.452e+00
```

```
##                   [,1]
## AIC.binomial 4.116e+04
## AIC.gamma    1.198e+05
## shape.mle    6.616e-01
```




```
## elapsed time is 125.000000 seconds
```

```
## elapsed time is 13.320000 seconds
```

Figure 3.  Method 2: Estimates of species-specific regression coefficients used to estimate a trip's probability of catching gag.



![plot of chunk regcoeffPlotm2](figure/regcoeffPlotm2.png) 

Figure 4.  Method 2: Absolute difference between observed and predicted number of positive gag trips.  Left and right panels differ only in the range of probabilities shown.

![plot of chunk probabilitym2](figure/probabilitym2.png) 



```
## Error: undefined columns selected
```

```
## Start:  AIC=193893
## cpue ~ year + month + STATE
## 
##         Df Deviance    AIC
## <none>      1376800 193893
## - year  18  1396274 194263
## - month  7  1397844 194317
## - STATE  2  1539077 197112
```

```
## Start:  AIC=112025
## cpue ~ year + month + STATE
## 
##         Df Deviance    AIC
## <none>        54119 112025
## - year  18    55352 112255
## - month  7    55352 112277
## - STATE  2    66446 114688
```

```
## Start:  AIC=38525
## cpue ~ year + month + STATE
## 
##         Df Deviance   AIC
## <none>        38469 38525
## - STATE  2    38584 38636
## - month  7    38639 38681
## - year  18    38849 38869
```

```
## [1] "0 (total) records were removed by filter."
## [1] "0 positive records removed by filter."
```

```
## [1] "0 (total) records were removed by filter."
## [1] "0 positive records removed by filter."
```

```
##                    [,1]
## AIC.binomial  3.852e+04
## AIC.lognormal 1.077e+05
## sigma.mle     1.467e+00
```

```
##                   [,1]
## AIC.binomial 3.852e+04
## AIC.gamma    1.113e+05
## shape.mle    6.525e-01
```



```
## elapsed time is 89.370000 seconds
```

```
## elapsed time is 9.500000 seconds
```

Figure 5.  Method 3: Estimates of species-specific regression coefficients used to estimate a trip's probability of catching gag.



![plot of chunk regcoeffPlotm3](figure/regcoeffPlotm3.png) 

Figure 6.  Method 3: Absolute difference between observed and predicted number of positive gag trips.  Left and right panels differ only in the range of probabilities shown.

![plot of chunk probabilitym3](figure/probabilitym3.png) 



```
## Error: undefined columns selected
```

```
## Start:  AIC=120837
## cpue ~ year + month + STATE
## 
##         Df Deviance    AIC
## <none>       607735 120837
## - month  4   609855 120896
## - year  19   618969 121150
## - STATE  2   661172 122450
```

```
## Start:  AIC=65874
## cpue ~ year + month + STATE
## 
##         Df Deviance   AIC
## <none>        35446 65874
## - month  4    35652 65909
## - year  19    36606 66081
## - STATE  2    42070 67271
```

```
## Start:  AIC=26379
## cpue ~ year + month + STATE
## 
##         Df Deviance   AIC
## <none>        26327 26379
## - STATE  2    26393 26441
## - month  4    26440 26484
## - year  19    26695 26709
```

```
## [1] "0 (total) records were removed by filter."
## [1] "0 positive records removed by filter."
```

```
## [1] "0 (total) records were removed by filter."
## [1] "0 positive records removed by filter."
```

```
##                    [,1]
## AIC.binomial  26378.502
## AIC.lognormal 62411.200
## sigma.mle         1.433
```

```
##                   [,1]
## AIC.binomial 2.638e+04
## AIC.gamma    6.538e+04
## shape.mle    6.599e-01
```

Figure 7.  Estimated index for all three methods using a lognormal error distribution.

```
## Error: object 'gaggm3.ln' not found
```

```
## Error: object 'gaggm3.ln' not found
```

```
## Error: object 'gaggm2.ln' not found
```

```
## Error: object 'gaggm1.ln' not found
```

```
## Error: plot.new has not been called yet
```

