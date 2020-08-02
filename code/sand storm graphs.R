
library(ggplot2)
library(plyr)
library(reshape)
library(foreign)
library(grid)
library(gridExtra)
library(RColorBrewer)
library(scales)
library(ggExtra)
library(fmsb)
library(lattice)
library(ggthemes)
library(ggmap)
library(fields)
library(maptools)
library(sp)
library(rgdal)
library(xlsx)
library(lpSolve)
library(readstata13)
library(tidyverse)
library(quantreg)
library(ggpubr)
library(rpart)

rm(list=ls())
cat("\014")

setwd("F:/sand storm/data/data/")

###################residential

data<-read.xlsx2("final results.xlsx", "residential income ethnic")

data<-melt(data,id="variable")

data$value<-gsub("\\*","",data$value)
data$value<-gsub("\\(","",data$value)
data$value<-gsub("\\)","",data$value)
data$value<-as.numeric(data$value)

names(data)<-c("pollutant", "group", "value")

data_mean<-data[which(data$pollutant=="PM10 concentration" | data$pollutant=="PM2.5 concentration"),]
data_sd<-data[which(data$pollutant=="PM10 concentration sd" | data$pollutant=="PM2.5 concentration sd"),]

data_sd$pollutant<-gsub(" sd","", data_sd$pollutant)


data<-merge(data_mean, data_sd, by=c("pollutant", "group"))

data$upper<-data$value.x+2*data$value.y
data$lower<-data$value.x-2*data$value.y

data<-subset(data, select=-value.y)

data$group<-gsub("\\."," ", data$group)

names(data)<-c("pollutant","group","mean","upper","lower")

data<-reshape(data, 
              varying=c("upper", "lower"),
              v.names="value",
              timevar="boundary",
              times=c("upper", "lower"),
              direction="long")

data$pollutant<-gsub("concentration", "", data$pollutant)

data$group<-factor(data$group, 
                                  levels=c("All","Low income","Middle income","High income", "White","Asian","Hispanic","Other" ), order=T) 

        
residential<-ggplot()
residential<-residential+geom_point(data =data,
                                  aes(x =group,y =mean, color=pollutant), position =position_dodge(width = 0.5), size=7)
residential<-residential+geom_line(data =data,
                                  aes(x =group,y =value, color=pollutant, group=interaction(group, pollutant)), position = position_dodge(width = 0.5), size=2.5)
residential<-residential+theme_bw()+theme(legend.position="bottom",
                                        legend.direction = "horizontal",
                                        panel.grid.major = element_blank(),
                                        panel.grid.minor = element_blank(),
                                        strip.background = element_blank(),
                                        text = element_text(size=25))+ylab("Daily electricity consumption (kWh)") + xlab("Income and ethnic groups")
residential<-residential+geom_hline(yintercept=0, linetype="dashed", size=1)
#residential<-residential+scale_shape_manual(values=1:nlevels(data$Region)) 
residential

jpeg(filename = "residential.jpg",width = 16.2, height=10, units="in", res=300)
residential
dev.off()


#######################commercial

data<-read.xlsx2("final results.xlsx", "commercial sector")

data<-melt(data,id="variable")

data$value<-gsub("\\*","",data$value)
data$value<-gsub("\\(","",data$value)
data$value<-gsub("\\)","",data$value)
data$value<-as.numeric(data$value)

names(data)<-c("pollutant", "group", "value")

data_mean<-data[which(data$pollutant=="PM10 concentration" | data$pollutant=="PM2.5 concentration"),]
data_sd<-data[which(data$pollutant=="PM10 concentration sd" | data$pollutant=="PM2.5 concentration sd"),]

data_sd$pollutant<-gsub(" sd","", data_sd$pollutant)


data<-merge(data_mean, data_sd, by=c("pollutant", "group"))

data$upper<-data$value.x+2*data$value.y
data$lower<-data$value.x-2*data$value.y

data<-subset(data, select=-value.y)

data$group<-gsub("\\."," ", data$group)

names(data)<-c("pollutant","group","mean","upper","lower")

data<-reshape(data, 
              varying=c("upper", "lower"),
              v.names="value",
              timevar="boundary",
              times=c("upper", "lower"),
              direction="long")

data$pollutant<-gsub("concentration", "", data$pollutant)

data$group<-factor(data$group, 
                   levels=c("All","Retail trade","Recreation and services","Others"), order=T) 

		

commercial<-ggplot()
commercial<-commercial+geom_point(data =data,
                                  aes(x =group,y =mean, color=pollutant), position =position_dodge(width = 0.5), size=7)
commercial<-commercial+geom_line(data =data,
                                 aes(x =group,y =value, color=pollutant, group=interaction(group, pollutant)), position = position_dodge(width = 0.5), size=2.5)
commercial<-commercial+theme_bw()+theme(legend.position="bottom",
                                        legend.direction = "horizontal",
                                        panel.grid.major = element_blank(),
                                        panel.grid.minor = element_blank(),
                                        strip.background = element_blank(),
                                        text = element_text(size=25))+ylab("Changes in daily electricity consumption (kWh)") + xlab("Industrial sectors")
#commercial<-commercial+scale_shape_manual(values=1:nlevels(data$Region)) 
commercial<-commercial+geom_hline(yintercept=0, linetype="dashed",size=1)
commercial

jpeg(filename = "commercial.jpg",width = 16.2, height=10, units="in", res=300)
commercial
dev.off()

###################residential hourly
residential_hourly<-read.dta13("coefficient R air pollution and hourly residential electricity use.dta")


residential_hourly_analysis<-ggplot()
residential_hourly_analysis<-residential_hourly_analysis+geom_point(data=residential_hourly[which(residential_hourly$coef=="c"),], aes(x=factor(id), y=estimation_new, group=interaction(variable,withprice), color=interaction(variable,withprice)), size=5, position = position_dodge(width = 0.5))
residential_hourly_analysis<-residential_hourly_analysis+geom_line(data =residential_hourly[which(residential_hourly$coef=="c"),], aes(x=factor(id), y=estimation_new, group=interaction(variable,withprice), color=interaction(variable,withprice)), size=1.5, position = position_dodge(width = 0.5))
residential_hourly_analysis<-residential_hourly_analysis+geom_line(data =residential_hourly[which(residential_hourly$coef=="l" | residential_hourly$coef=="u"),], aes(x=factor(id), y=estimation_new, group=interaction(variable,withprice,id), color=interaction(variable,withprice)), size=2, position = position_dodge(width = 0.5))
residential_hourly_analysis<-residential_hourly_analysis+theme_bw()+theme(axis.text.x = element_text(lineheight=0.5, hjust = 1, vjust=0.5),
                                                                          text = element_text(size=25),
                                                                          legend.text=element_text(size=25),
                                                                          panel.grid.major = element_blank(),
                                                                          panel.grid.minor = element_blank(),
                                                                          strip.background = element_blank(),
                                                                          strip.placement = "outside",
                                                                          legend.position="bottom")
residential_hourly_analysis<-residential_hourly_analysis+labs(x="Hour",y ="Changes in Hourly electricity consumption (kWh)")
residential_hourly_analysis<-residential_hourly_analysis+guides(color=guide_legend(title=NULL,nrow=2))
residential_hourly_analysis<-residential_hourly_analysis+ geom_hline(data=residential_hourly, aes(yintercept=0),  col="black", linetype="dashed", size=1)
residential_hourly_analysis

jpeg(filename = "residential_hourly_analysis.jpg",width = 16.2, height=10, units="in", res=300)
residential_hourly_analysis
dev.off()



###################commercial hourly
commercial_hourly<-read.dta13("coefficient R air pollution and hourly commercial electricity use.dta")


commercial_hourly_analysis<-ggplot()
commercial_hourly_analysis<-commercial_hourly_analysis+geom_point(data=commercial_hourly[which(commercial_hourly$coef=="c"),], aes(x=factor(id), y=estimation_new, group=interaction(variable,withprice), color=interaction(variable,withprice)), size=5, position = position_dodge(width = 0.5))
commercial_hourly_analysis<-commercial_hourly_analysis+geom_line(data =commercial_hourly[which(commercial_hourly$coef=="c"),], aes(x=factor(id), y=estimation_new, group=interaction(variable,withprice), color=interaction(variable,withprice)), size=1.5, position = position_dodge(width = 0.5))
commercial_hourly_analysis<-commercial_hourly_analysis+geom_line(data =commercial_hourly[which(commercial_hourly$coef=="l" | commercial_hourly$coef=="u"),], aes(x=factor(id), y=estimation_new, group=interaction(variable,id,withprice), color=interaction(variable,withprice)), size=2, position = position_dodge(width = 0.5))
commercial_hourly_analysis<-commercial_hourly_analysis+theme_bw()+theme(axis.text.x = element_text(lineheight=0.5, hjust = 1, vjust=0.5),
                                                                        text = element_text(size=25),
                                                                        legend.text=element_text(size=25),
                                                                        panel.grid.major = element_blank(),
                                                                        panel.grid.minor = element_blank(),
                                                                        strip.background = element_blank(),
                                                                        strip.placement = "outside",
                                                                        legend.position="bottom")
commercial_hourly_analysis<-commercial_hourly_analysis+labs(x="Hour",y ="Changes in hourly electricity consumption (kWh)")
commercial_hourly_analysis<-commercial_hourly_analysis+guides(color=guide_legend(title=NULL, nrow=2))
commercial_hourly_analysis<-commercial_hourly_analysis+ geom_hline(data=commercial_hourly, aes(yintercept=0),  col="black", linetype="dashed", size=1)
commercial_hourly_analysis

jpeg(filename = "commercial_hourly_analysis.jpg",width = 16.2, height=10, units="in", res=300)
commercial_hourly_analysis
dev.off()



###################residential, statsby

residential_statsby<-read.dta13("residential statsby.dta")

residential_statsby_analysis_PM10<-ggplot()
residential_statsby_analysis_PM10<-residential_statsby_analysis_PM10+geom_line(data=residential_statsby, 
                                                                      aes(x=rank_PM10, y=b_v_PM10_mean), color="red", size=2)
residential_statsby_analysis_PM10<-residential_statsby_analysis_PM10+geom_line(data =residential_statsby, aes(x=rank_PM10, y=CI_l_PM10), color="grey", linetype="dotted", size=1.5)
residential_statsby_analysis_PM10<-residential_statsby_analysis_PM10+geom_line(data =residential_statsby, aes(x=rank_PM10, y=CI_u_PM10), color="grey", linetype="dotted", size=1.5)
residential_statsby_analysis_PM10<-residential_statsby_analysis_PM10+theme_bw()+theme(axis.text.x = element_text(angle = 90, lineheight=0.5, hjust = 1, vjust=0.5),
                                                                          text = element_text(size=25),
                                                                          legend.text=element_text(size=25),
                                                                          panel.grid.major = element_blank(),
                                                                          panel.grid.minor = element_blank(),
                                                                          strip.background = element_blank(),
                                                                          strip.placement = "outside",
                                                                          legend.position="bottom")
residential_statsby_analysis_PM10<-residential_statsby_analysis_PM10+labs(x="Households",y ="Daily electricity consumption (kWh), PM10")
#residential_statsby_analysis_PM10<-residential_statsby_analysis_PM10+ guides(color=FALSE)
residential_statsby_analysis_PM10<-residential_statsby_analysis_PM10+ geom_hline(data=residential_statsby, aes(yintercept=0),  col="black", linetype="dashed")
residential_statsby_analysis_PM10


residential_statsby_analysis_PM25<-ggplot()
residential_statsby_analysis_PM25<-residential_statsby_analysis_PM25+geom_line(data=residential_statsby, 
                                                                               aes(x=rank_PM25, y=b_v_PM25_mean), color="red", size=2)
residential_statsby_analysis_PM25<-residential_statsby_analysis_PM25+geom_line(data =residential_statsby, aes(x=rank_PM25, y=CI_l_PM25), color="grey", linetype="dotted", size=1.5)
residential_statsby_analysis_PM25<-residential_statsby_analysis_PM25+geom_line(data =residential_statsby, aes(x=rank_PM25, y=CI_u_PM25), color="grey", linetype="dotted", size=1.5)
residential_statsby_analysis_PM25<-residential_statsby_analysis_PM25+theme_bw()+theme(axis.text.x = element_text(angle = 90, lineheight=0.5, hjust = 1, vjust=0.5),
                                                                                      text = element_text(size=25),
                                                                                      legend.text=element_text(size=25),
                                                                                      panel.grid.major = element_blank(),
                                                                                      panel.grid.minor = element_blank(),
                                                                                      strip.background = element_blank(),
                                                                                      strip.placement = "outside",
                                                                                      legend.position="bottom")
residential_statsby_analysis_PM25<-residential_statsby_analysis_PM25+labs(x="Households",y ="Daily electricity consumption (kWh), PM2.5")
#residential_statsby_analysis_PM25<-residential_statsby_analysis_PM25+ guides(color=FALSE)
residential_statsby_analysis_PM25<-residential_statsby_analysis_PM25+ geom_hline(data=residential_statsby, aes(yintercept=0),  col="black", linetype="dashed")
residential_statsby_analysis_PM25

residential_statsby_analysis <- grid.arrange(residential_statsby_analysis_PM10,
                                             residential_statsby_analysis_PM25,
                                            nrow=1)

ggsave("residential_statsby_analysis.jpg", residential_statsby_analysis, width = 16.2, height=10, units="in")

jpeg(filename = "residential_statsby_analysis.jpg",width = 16.2, height=10, units="in", res=300)
residential_statsby_analysis
dev.off()


###################GSOD data
rm(list=ls())
cat("\014")

library(GSODR)

setwd("E:/sand storm/data/data transportation/")

data<-get_GSOD(years=2020,country = "United States")

write.csv(data,"GSOD.csv")

wind_hourly<-read.csv("E:/sand storm/data/data transportation/hourly_WIND_2020/hourly_WIND_2020.csv")

wind_hourly_final<-subset(wind_hourly, select=c(State.Code,County.Code,Site.Num,Latitude,Longitude,Datum))
wind_hourly_final<-unique(wind_hourly_final)
write.csv(wind_hourly_final,"wind hourly station.csv")

vignette("GSODR",package = "GSODR")