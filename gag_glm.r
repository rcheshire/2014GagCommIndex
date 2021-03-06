
windows(record=T,w=7,h=5.5)
library(MASS)
require(doBy)
require(xtable)
library(matlab)
source('sort.data.frame.r')
source("DeltaGLM-1-7-2-KWS.r")
input='W:/SEDAR/Updates2014/Gag/Indicies/CommHL'
#cpue values from SEDAR10
s10indexYr=1993:2004
s10index=c(0.944,0.907,0.937,1.001,0.768,0.951,1.017,0.912,0.867,1.006,1.342,1.44)
s10indexPred=c(0.86,1.03,1.06,0.92,0.83,0.86,0.98,1.02,0.95,1.05,1.24,1.32)
#  read in data set created by SAS
gagtrips=read.csv(paste(input,'landbymonth.csv',sep='/'),header=TRUE)
#create trip sample size for each method
method1=summaryBy(X_FREQ_~year,data=gagtrips[gagtrips$month%in%c(1,4,5,6,7,8,9,10,11,12),],FUN=sum)
colnames(method1)=c('year','method1')
for(i in 1:dim(method1)[1]){
  if(method1$year[i]>2009){method1$method1[i]='NA'}
}
method2=summaryBy(X_FREQ_~year,data=gagtrips[gagtrips$month%in%5:12,],FUN=sum)
colnames(method2)=c('year','method2')
for(i in 1:dim(method2)[1]){
  if(method2$year[i]>2011){method2$method2[i]='NA'}
}
method3=summaryBy(X_FREQ_~year,data=gagtrips[gagtrips$month%in%c(5,6,7,8,9),],FUN=sum)
colnames(method3)=c('year','method3')


sstable=cbind(method1$year,method1$method1,method2$method2,method3$method3)
sstable=as.data.frame.matrix(sstable)
colnames(sstable)=c('year','method1','method2','method3')
sstable=xtable(sstable,digits=0,display=c('d','d','d','d','d'),align=c('r','r','r','r','r'))
print(sstable,type="html",include.rownames=FALSE)

###########Create Binary Matrix for Stephens and MacCall#####

####################METHOD 1. Jan,Feb, May,Jun,JUl,Aug,Sept,Oct,Nov,Dec through 2009##########
dat=read.csv('W:/SEDAR/Updates2014/Gag/Indicies/CommHL/tripspeciesm1.csv',header=T)
NMFSspp.codes=read.csv('W:/SEDAR/Updates2014/Gag/Indicies/CommHL/NMFSsppcodes.csv',header=T)
spp.codes=sort.data.frame(NMFSspp.codes,~sppcode)

trips=unique(dat$SCHEDULE)
spp.id=spp.codes$sppcode
spp.name=spp.codes$name

mat=matrix(0, nrow=length(trips),ncol=length(spp.id),
           dimnames=list(trip=trips,names=spp.name))
#instead of ind, this could be done using the fcn "match"
ind=1
for (j in 1:length(spp.id)) {
  if (dat$species[1]==spp.id[j]) mat[ind,j]=1
}
tic()
for (i in 2:nrow(dat)) {
  if (dat$SCHEDULE[i]!=dat$SCHEDULE[i-1]) {
    ind=ind+1
  }
  for (j in 1:length(spp.id)) {
    if (dat$species[i]==spp.id[j]) mat[ind,j]=1
  }
  
}
toc()
tic()
write.table(mat,file='W:/SEDAR/Updates2014/Gag/Indicies/CommHL/lgbkm1.dat',quote=F,sep=",")
toc()

#Fit logistic regression to select trips that may have caught focal species
#Implement method from Stephens and McCall.2004. Fisheries Research.
#Kyle Shertzer, 10/24/05
#Last updated, 2/13/2014
#2014 gag update - RTC

#graphics.off()
#rm(list=ls(all=TRUE))
bin.dat=mat
colnames(bin.dat)=make.names(colnames(bin.dat))
bin.dat=as.data.frame.matrix(bin.dat)
#read.csv("BinaryMatrix_HLM.csv", header=TRUE)
bin.dat[is.na(bin.dat)] <- 0
# Remove red snapper and red porgy due to closures
bin.dat=subset(bin.dat,select=-c(Red.snapper,Red.porgy))



################## regression coefficients by species###

target.spp="Gag"
target.spp2="Gag"
target.code=1423

incidence=data.frame(freq=colSums(bin.dat[,-1],na.rm=TRUE))
incidence$prop.trps=incidence$freq/sum(incidence$freq)

#----define species to be used in GLM-----                 
#minimal proportion of trips in which a species is caught
cutoff=0.01     #0.05
incidence=incidence[incidence$prop.trps>cutoff,]
mat2=bin.dat[,rownames(incidence)]
mat2=as.data.frame.matrix(mat2)
#creage scatter plot of target to other species 
#look for combinations with no overlap and remove
# windows(height=8,width=10,record=T)
# par(mfrow=c(2,4))
# for(i in 2:dim(mat2)[2]){
# with(mat2,plot(jitter(Gag),jitter(mat2[,i]),ylab=colnames(mat2[i]), xlab=target.spp))
# }


#species removed (usually because they never co-occur with target species)
#species to remove: 
#mat2=mat2[,-c(4)]
#mat2=cbind(bin.dat$SCHEDULE,mat2)
totals=colSums(mat2,na.rm=TRUE)

##incidence2=data.frame(name=spp.name[incidence$prop.trps>cutoff],
##            freq=totals,prop.trps=totals/nrow(mat2))
###incidence2.sort=orderBy(~freq,incidence2)
##sp.names=spp.name[incidence$prop.trps>cutoff]
#

#-----fit binomial GLM-----
mat2.df=data.frame(mat2)
id=1:length(colnames(mat2.df))
id.target= id[colnames(mat2.df)==target.spp]
terms.glm=""
for (i in 1:length(id)) {
if (i!=id.target){
if (i==1) terms.glm=paste(terms.glm,colnames(mat2.df)[i],sep="")
else terms.glm=paste(terms.glm,colnames(mat2.df)[i],sep="+")
}
}
#fit the model and use step-wise AIC to choose species to include
model=paste(colnames(mat2.df)[id.target],terms.glm,sep="~")
glm.start <- glm(formula=as.formula(model),family="binomial", data=mat2.df)
glm.step <- stepAIC(glm.start,scope=list(upper = paste('~',terms.glm),lower = ~1),direction="backward")
fit=glm.step
#fit=glm(formula=as.formula(model),family=binomial, data=mat2.df)

coeff=sort(fit$coefficients[-1], decreasing=T)
windows(width=10,height=8,record=T)
par(las=2,cex.lab=1.0,oma=c(0,15,0,0))
barplot(coeff,horiz=T,xlim=c(-1.0,1), xlab='Regression coefficient')
savePlot(file="sppcorr.pdf",type="pdf")
savePlot(file="sppcorr.png",type="png")
#-----evaluate predictions/ choose trips ------------
gt.func=function(x) length(fit$fitted.values[fit$fitted.values>x])
prob.trp=seq(0,1,by=0.001)
num.postrips.pred=rep(0,length(prob.trp))
for (i in 1:length(prob.trp)){num.postrips.pred[i]=gt.func(prob.trp[i])}

abs.dif=abs(num.postrips.pred-totals[target.spp])
windows(width=8,height=4,record=T)
par(mfcol=c(1,2),mar=c(4,4,1.5,0.5),las=2)
plot(prob.trp,abs.dif/1000,type="l",xlab="Probability",main="",ylab="Abs. error (1000)")
min.prob=mean(prob.trp[abs.dif==min(abs.dif)]) #mean in case min is not unique
plot(prob.trp[550:650],abs.dif[550:650]/1000,type="l",
xlab="Probability", ylab="Abs. error (1000)")
savePlot(file="minimum.pdf",type="pdf")
savePlot(file="minimum.png",type="png")

trips.pred=mat2.df[fit$fitted.values>min.prob,]
select.trips=c(rownames(trips.pred))

#-----Create data set for running delta-lognormal GLM ------------
dat.all.U=read.csv('W:/SEDAR/Updates2014/Gag/Indicies/CommHL/sa.sg.hline.U.csv',header=T)
# limit to only trips above cutoff value 
dat.select.U=dat.all.U[as.numeric(dat.all.U$SCHEDULE) %in% as.numeric(select.trips),]

dat.select.U=dat.select.U[,c('cpue','year','month','STATE')]
dat=dat.select.U
dat$year=as.factor(dat$year)
dat$month=as.factor(dat$month)
dat$STATE=as.factor(dat$STATE)

dat.pos=dat[which(dat[,"cpue"]>0),] 
#compare lognormal to gamma and determine factors to include
#Lognormal
pos.ln.start<-glm(cpue~year+month+STATE, data=dat.pos, family=gaussian(link="identity"))
glm.step <- stepAIC(pos.ln.start,direction="backward")
pos.ln.fit=glm.step

#Gamma 
pos.gamma.start<-glm(cpue~year+month+STATE, data=dat.pos, family=Gamma(link="log"))
glm.step <- stepAIC(pos.gamma.start,direction="backward")
pos.gamma.fit=glm.step
#binomial  
dat.bin=dat; dat.bin$cpue[dat$cpue>0]=1.0
bin.start<-glm(cpue~year+month+STATE, data=dat.bin, family="binomial")
glm.step <- stepAIC(bin.start,direction="backward")
bin.fit=glm.step

gagm1.ln=dglm(dat,dist="lognormal", write=T,types=c('C','F','F','F'))
gagm1.gamma=dglm(dat,dist="gamma", write=T,types=c('C','F','F','F'))
#check aic
gagm1.ln$aic
gagm1.gamma$aic


#sg.ind2=dglm(dat,dist="lognormal",write=T,types=c('C','F','F','F','F',"F"),j=F)


####################METHOD 2.  May,Jun,JUl,Aug,Sept,Oct,Nov,Dec through 2011##########
dat=read.csv('W:/SEDAR/Updates2014/Gag/Indicies/CommHL/tripspeciesm2.csv',header=T)
spp.codes=sort.data.frame(NMFSspp.codes,~sppcode)

trips=unique(dat$SCHEDULE)
spp.id=spp.codes$sppcode
spp.name=spp.codes$name

mat=matrix(0, nrow=length(trips),ncol=length(spp.id),
dimnames=list(trip=trips,names=spp.name))
#instead of ind, this could be done using the fcn "match"
ind=1
for (j in 1:length(spp.id)) {
if (dat$species[1]==spp.id[j]) mat[ind,j]=1
}
tic()
for (i in 2:nrow(dat)) {
if (dat$SCHEDULE[i]!=dat$SCHEDULE[i-1]) {
ind=ind+1
}
for (j in 1:length(spp.id)) {
if (dat$species[i]==spp.id[j]) mat[ind,j]=1
}

}
toc()
tic()
write.table(mat,file='W:/SEDAR/Updates2014/Gag/Indicies/CommHL/lgbkm2.dat',quote=F,sep=",")
toc()

#Fit logistic regression to select trips that may have caught focal species
#Implement method from Stephens and McCall.2004. Fisheries Research.
#Kyle Shertzer, 10/24/05
#Last updated, 2/13/2014
#2014 gag update - RTC

#graphics.off()
#rm(list=ls(all=TRUE))
bin.dat=mat
colnames(bin.dat)=make.names(colnames(bin.dat))
bin.dat=as.data.frame.matrix(bin.dat)
#read.csv("BinaryMatrix_HLM.csv", header=TRUE)
bin.dat[is.na(bin.dat)] <- 0
# Remove red snapper and red porgy due to closures
bin.dat=subset(bin.dat,select=-c(Red.snapper,Red.porgy))



################## regression coefficients by species###

target.spp="Gag"
target.spp2="Gag"
target.code=1423

incidence=data.frame(freq=colSums(bin.dat[,-1],na.rm=TRUE))
incidence$prop.trps=incidence$freq/sum(incidence$freq)

#----define species to be used in GLM-----                 
#minimal proportion of trips in which a species is caught
cutoff=0.01     #0.05
incidence=incidence[incidence$prop.trps>cutoff,]
mat2=bin.dat[,rownames(incidence)]
mat2=as.data.frame.matrix(mat2)
#creage scatter plot of target to other species 
#look for combinations with no overlap and remove
# windows(height=8,width=10,record=T)
# par(mfrow=c(2,4))
# for(i in 2:dim(mat2)[2]){
# with(mat2,plot(jitter(Gag),jitter(mat2[,i]),ylab=colnames(mat2[i]), xlab=target.spp))
# }


#species removed (usually because they never co-occur with target species)
#species to remove: 
#mat2=mat2[,-c(4)]
#mat2=cbind(bin.dat$SCHEDULE,mat2)
totals=colSums(mat2,na.rm=TRUE)

##incidence2=data.frame(name=spp.name[incidence$prop.trps>cutoff],
##            freq=totals,prop.trps=totals/nrow(mat2))
###incidence2.sort=orderBy(~freq,incidence2)
##sp.names=spp.name[incidence$prop.trps>cutoff]
#

#-----fit binomial GLM-----
mat2.df=data.frame(mat2)
id=1:length(colnames(mat2.df))
id.target= id[colnames(mat2.df)==target.spp]
terms.glm=""
for (i in 1:length(id)) {
  if (i!=id.target){
    if (i==1) terms.glm=paste(terms.glm,colnames(mat2.df)[i],sep="")
    else terms.glm=paste(terms.glm,colnames(mat2.df)[i],sep="+")
  }
}
#fit the model and use step-wise AIC to choose species to include
model=paste(colnames(mat2.df)[id.target],terms.glm,sep="~")
glm.start <- glm(formula=as.formula(model),family="binomial", data=mat2.df)
glm.step <- stepAIC(glm.start,scope=list(upper = paste('~',terms.glm),lower = ~1),direction="backward")
fit=glm.step
#fit=glm(formula=as.formula(model),family=binomial, data=mat2.df)

coeff=sort(fit$coefficients[-1], decreasing=T)

windows(width=10,height=8,record=T)
par(las=2,cex.lab=1.0,oma=c(0,15,0,0))
barplot(coeff,horiz=T,xlim=c(-1.0,1), xlab='Regression coefficient')
savePlot(file="sppcorr2.pdf",type="pdf")
savePlot(file="sppcorr2.png",type="png")


#-----evaluate predictions/ choose trips ------------
gt.func=function(x) length(fit$fitted.values[fit$fitted.values>x])
prob.trp=seq(0,1,by=0.001)
num.postrips.pred=rep(0,length(prob.trp))
for (i in 1:length(prob.trp)){num.postrips.pred[i]=gt.func(prob.trp[i])}

abs.dif=abs(num.postrips.pred-totals[target.spp])
windows(width=8,height=4,record=T)
par(mfcol=c(1,2),mar=c(4,4,1.5,0.5),las=2)
plot(prob.trp,abs.dif/1000,type="l",xlab="Probability",main="",ylab="Abs. error (1000)")
min.prob=mean(prob.trp[abs.dif==min(abs.dif)]) #mean in case min is not unique
plot(prob.trp[550:650],abs.dif[550:650]/1000,type="l",
     xlab="Probability", ylab="Abs. error (1000)")
savePlot(file="minimum2.pdf",type="pdf")
savePlot(file="minimum2.png",type="png")

trips.pred=mat2.df[fit$fitted.values>min.prob,]
select.trips=c(rownames(trips.pred))

#-----Create data set for running delta-lognormal GLM ------------
dat.all.U=read.csv('W:/SEDAR/Updates2014/Gag/Indicies/CommHL/sa.sg.hline.U.csv',header=T)
# limit to only trips above cutoff value 
dat.select.U=dat.all.U[as.numeric(dat.all.U$SCHEDULE) %in% as.numeric(select.trips),]
#remove Jan and Feb (march and apr already  removed) due to spawning closure
dat.select.U=dat.select.U[dat.select.U$month%in%c(5,6,7,8,9,10,11,12),]
dat.select.U=dat.select.U[,c('cpue','year','month','STATE')]
dat=dat.select.U
dat$year=as.factor(dat$year)
dat$month=as.factor(dat$month)
dat$STATE=as.factor(dat$STATE)

dat.pos=dat[which(dat[,"cpue"]>0),] 
#compare lognormal to gamma and determine factors to include
#Lognormal
pos.ln.start<-glm(cpue~year+month+STATE, data=dat.pos, family=gaussian(link="identity"))
glm.step <- stepAIC(pos.ln.start,direction="backward")
pos.ln.fit=glm.step

#Gamma 
pos.gamma.start<-glm(cpue~year+month+STATE, data=dat.pos, family=Gamma(link="log"))
glm.step <- stepAIC(pos.gamma.start,direction="backward")
pos.gamma.fit=glm.step
#binomial  
dat.bin=dat; dat.bin$cpue[dat$cpue>0]=1.0
bin.start<-glm(cpue~year+month+STATE, data=dat.bin, family="binomial")
glm.step <- stepAIC(bin.start,direction="backward")
bin.fit=glm.step

gagm2.ln=dglm(dat,dist="lognormal", write=T,types=c('C','F','F','F'))
gagm2.gamma=dglm(dat,dist="gamma", write=T,types=c('C','F','F','F'))
#check aic
gagm2.ln$aic
gagm2.gamma$aic


####################METHOD 3.  May,Jun,JUl,Aug,Septthrough 2012##########
dat=read.csv('W:/SEDAR/Updates2014/Gag/Indicies/CommHL/tripspeciesm3.csv',header=T)
spp.codes=sort.data.frame(NMFSspp.codes,~sppcode)

trips=unique(dat$SCHEDULE)
spp.id=spp.codes$sppcode
spp.name=spp.codes$name

mat=matrix(0, nrow=length(trips),ncol=length(spp.id),
           dimnames=list(trip=trips,names=spp.name))
#instead of ind, this could be done using the fcn "match"
ind=1
for (j in 1:length(spp.id)) {
  if (dat$species[1]==spp.id[j]) mat[ind,j]=1
}
tic()
for (i in 2:nrow(dat)) {
  if (dat$SCHEDULE[i]!=dat$SCHEDULE[i-1]) {
    ind=ind+1
  }
  for (j in 1:length(spp.id)) {
    if (dat$species[i]==spp.id[j]) mat[ind,j]=1
  }
  
}
toc()
tic()
write.table(mat,file='W:/SEDAR/Updates2014/Gag/Indicies/CommHL/lgbkm3.dat',quote=F,sep=",")
toc()

#Fit logistic regression to select trips that may have caught focal species
#Implement method from Stephens and McCall.2004. Fisheries Research.
#Kyle Shertzer, 10/24/05
#Last updated, 2/13/2014
#2014 gag update - RTC

#graphics.off()
#rm(list=ls(all=TRUE))
bin.dat=mat
colnames(bin.dat)=make.names(colnames(bin.dat))
bin.dat=as.data.frame.matrix(bin.dat)
#read.csv("BinaryMatrix_HLM.csv", header=TRUE)
bin.dat[is.na(bin.dat)] <- 0
# Remove red snapper and red porgy due to closures
bin.dat=subset(bin.dat,select=-c(Red.snapper,Red.porgy))



################## regression coefficients by species###

target.spp="Gag"
target.spp2="Gag"
target.code=1423

incidence=data.frame(freq=colSums(bin.dat[,-1],na.rm=TRUE))
incidence$prop.trps=incidence$freq/sum(incidence$freq)

#----define species to be used in GLM-----                 
#minimal proportion of trips in which a species is caught
cutoff=0.01     #0.05
incidence=incidence[incidence$prop.trps>cutoff,]
mat2=bin.dat[,rownames(incidence)]
mat2=as.data.frame.matrix(mat2)
#creage scatter plot of target to other species 
#look for combinations with no overlap and remove
# windows(height=8,width=10,record=T)
# par(mfrow=c(2,4))
# for(i in 2:dim(mat2)[2]){
# with(mat2,plot(jitter(Gag),jitter(mat2[,i]),ylab=colnames(mat2[i]), xlab=target.spp))
# }


#species removed (usually because they never co-occur with target species)
#species to remove: 
#mat2=mat2[,-c(4)]
#mat2=cbind(bin.dat$SCHEDULE,mat2)

##incidence2=data.frame(name=spp.name[incidence$prop.trps>cutoff],
##            freq=totals,prop.trps=totals/nrow(mat2))
###incidence2.sort=orderBy(~freq,incidence2)
##sp.names=spp.name[incidence$prop.trps>cutoff]
#

#-----fit binomial GLM-----
mat2.df=data.frame(mat2)
id=1:length(colnames(mat2.df))
id.target= id[colnames(mat2.df)==target.spp]
terms.glm=""
for (i in 1:length(id)) {
if (i!=id.target){
if (i==1) terms.glm=paste(terms.glm,colnames(mat2.df)[i],sep="")
else terms.glm=paste(terms.glm,colnames(mat2.df)[i],sep="+")
}
}
#fit the model and use step-wise AIC to choose species to include
model=paste(colnames(mat2.df)[id.target],terms.glm,sep="~")
glm.start <- glm(formula=as.formula(model),family="binomial", data=mat2.df)
glm.step <- stepAIC(glm.start,scope=list(upper = paste('~',terms.glm),lower = ~1),direction="backward")
fit=glm.step
#fit=glm(formula=as.formula(model),family=binomial, data=mat2.df)


windows(width=10,height=8,record=T)
par(las=2,cex.lab=1.0,oma=c(0,15,0,0))
barplot(coeff,horiz=T,xlim=c(-1.0,1), xlab='Regression coefficient')
savePlot(file="sppcorr3.pdf",type="pdf")
savePlot(file="sppcorr3.png",type="png")


#-----evaluate predictions/ choose trips ------------
gt.func=function(x) length(fit$fitted.values[fit$fitted.values>x])
prob.trp=seq(0,1,by=0.001)
num.postrips.pred=rep(0,length(prob.trp))
for (i in 1:length(prob.trp)){num.postrips.pred[i]=gt.func(prob.trp[i])}

abs.dif=abs(num.postrips.pred-totals[target.spp])
windows(width=8,height=4,record=T)
par(mfcol=c(1,2),mar=c(4,4,1.5,0.5),las=2)
plot(prob.trp,abs.dif/1000,type="l",xlab="Probability",main="",ylab="Abs. error (1000)")
min.prob=mean(prob.trp[abs.dif==min(abs.dif)]) #mean in case min is not unique
plot(prob.trp[550:650],abs.dif[550:650]/1000,type="l",
xlab="Probability", ylab="Abs. error (1000)")
savePlot(file="minimum3.pdf",type="pdf")
savePlot(file="minimum3.png",type="png")

trips.pred=mat2.df[fit$fitted.values>min.prob,]
select.trips=c(rownames(trips.pred))

#-----Create data set for running delta-lognormal GLM ------------
dat.all.U=read.csv('W:/SEDAR/Updates2014/Gag/Indicies/CommHL/sa.sg.hline.U.csv',header=T)
# limit to only trips above cutoff value 
dat.select.U=dat.all.U[as.numeric(dat.all.U$SCHEDULE) %in% as.numeric(select.trips),]
#remove Jan and Feb (march and apr already  removed) due to spawning closure
#remove Oct-Dec due to closure in 2012
dat.select.U=dat.select.U[dat.select.U$month%in%c(5,6,7,8,9),]
dat.select.U=dat.select.U[,c('cpue','year','month','STATE')]
dat=dat.select.U
dat$year=as.factor(dat$year)
dat$month=as.factor(dat$month)
dat$STATE=as.factor(dat$STATE)

dat.pos=dat[which(dat[,"cpue"]>0),] 
#compare lognormal to gamma and determine factors to include
#Lognormal
pos.ln.start<-glm(cpue~year+month+STATE, data=dat.pos, family=gaussian(link="identity"))
glm.step <- stepAIC(pos.ln.start,direction="backward")
pos.ln.fit=glm.step

#Gamma 
pos.gamma.start<-glm(cpue~year+month+STATE, data=dat.pos, family=Gamma(link="log"))
glm.step <- stepAIC(pos.gamma.start,direction="backward")
pos.gamma.fit=glm.step
#binomial  
dat.bin=dat; dat.bin$cpue[dat$cpue>0]=1.0
bin.start<-glm(cpue~year+month+STATE, data=dat.bin, family="binomial")
glm.step <- stepAIC(bin.start,direction="backward")
bin.fit=glm.step

gagm3.ln=dglm(dat,dist="lognormal", write=T,types=c('C','F','F','F'))
gagm3.gamma=dglm(dat,dist="gamma", write=T,types=c('C','F','F','F'))
#check aic
gagm3.ln$aic
gagm3.gamma$aic

plot(rownames(gagm3.ln$deltaGLM.index),gagm3.ln$deltaGLM.index$index/mean(gagm3.ln$deltaGLM.index$index),type='n',xlab='',ylab='Pounds/hook-hr')
lines(rownames(gagm3.ln$deltaGLM.index),gagm3.ln$deltaGLM.index$index/mean(gagm3.ln$deltaGLM.index$index),lty=1,lwd=2,col='blue')
lines(rownames(gagm2.ln$deltaGLM.index),gagm2.ln$deltaGLM.index$index/mean(gagm2.ln$deltaGLM.index$index),lty=1,lwd=2,col='darkorange')
lines(rownames(gagm1.ln$deltaGLM.index),gagm1.ln$deltaGLM.index$index/mean(gagm1.ln$deltaGLM.index$index),lty=1,lwd=2,col='darkgreen')
lines(s10indexYr,s10index,lty=1,lwd=2,col='red')
legend('topleft',lty=c(1,1,1,1),lwd=c(2,2,2,2), col=c('blue','darkorange','darkgreen','red'),legend=c('method 3', 'method 2', 'method 1', 'SEDAR 10'))
savePlot(file="compareMethods.pdf",type="pdf")
savePlot(file="compareMethods.png",type="png")


