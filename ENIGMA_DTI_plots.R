
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                        %%%  ENIGMA DTI %%%
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#%% This is a function to print out images for Quality Control
#%% of DTI_ENIGMA FA images with TBSS (FSL) skeltons overlaid
#%% as well as JHU atlas ROIs
#%%
#%% Please QC your images to make sure they are
#%% correct FA maps and oriented and aligned properly
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#%% Writen by Neda Jahanshad / Kristian Eschenburg / Derrek Hibar 
#%%   last update February 2014
#%%           Questions or Comments??
#%% neda.jahanshad@ini.usc.edu / kristian.eschenburg@ini.usc.edu / derrek.hibar@ini.usc.edu
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

library(dplyr)
library(tidyr)

TBSSDIR = cmdargs[1];  

OUTDIR = paste(TBSSDIR,'/QC_ENIGMA',sep = '')
CSVFILE = paste(TBSSDIR,'/EXTRAROI/Final/Final_AverageFA_AllSubjects_T.csv',sep = '')

rois="AverageFA;ACR;ALIC;BCC;CC;CGC;CGH;CR;CST;EC;FX;FXST;GCC;IC;IFO;PCR;PLIC;PTR;RLIC;SCC;SCR;SFO;SLF;SS;UNC"
Nrois = 25;

OUTPDF = paste(TBSSDIR,'/QC_ENIGMA/25ROI_histograms.pdf',sep = '')
OUTTXT = paste(TBSSDIR,'/QC_ENIGMA/25ROI_stats.txt',sep = '')


dir.create(OUTDIR)

Table <- read.csv(CSVFILE, header = T);
Table.T <- t(Table[,2:ncol(Table)])
colnames(Table.T) <- Table[1,]

data <- select(Table,AverageFA,ACR,ALIC,BCC,CC,CGC,CGH,CR,CST,EC,FX,FXST,GCC,IC,IFO,PCR,PLIC,PTR,RLIC,SCC,SCR,SFO,SLF,SS,UNC) 


colTable = names(data);

## assigning all rows that have a value of "x" or "X" to "NA"
for (m in seq(1,length(data)))
{
	ind = which(data[,m]=="x");
	ind2 = which(data[,m]=="X");
	data[ind] = "NA"
	data[ind2] = "NA"
}

##get rid of all rows with NAs in them
INDX=which(apply(data,1,function(x)any(is.na(x))));

##get rid of all rows with NAs in them
if (length(INDX) >0 )
{
	data<-data[-which(apply(data,1,function(x)any(is.na(x)))),]
}

## parsing through the inputted list of ROIs
if (Nrois > 0)
{
	pdf(file=OUTPDF);
	
	parsedROIs = parse(text=rois);
    
    write("Structure\tNumberIncluded\tMean\tStandDev\tMaxValue\tMinValue", file = OUTTXT);
    
	for (x in seq(1,Nrois,1))
	{
		
	ROI <- as.character(parsedROIs[x]);
	
	DATA = data[ROI];
	DATA = unlist(DATA);
	DATA = as.numeric(as.vector(DATA));
	
	mu = mean(DATA);
	sdev = sd(DATA);
	N = length(DATA);
	
  hbins = 20; #floor(N/10);
	
	maxV = max(DATA);
	minV = min(DATA);
	
	i =which(DATA==maxV)
	maxSubj = data[i,1]
	
	j =which(DATA==minV)
	minSubj = data[j,1]
	
	stats = c(ROI, N, mu, sdev, maxV, minV);

	

	write.table(t(as.matrix(stats)),file = OUTTXT, append=T, quote=F, col.names=F,row.names=F, sep="\t");
	write(paste("      \t      \t      \t      \t     ", maxSubj, "\t", minSubj),file = OUTTXT, append=T);
		
	hist(DATA, breaks = hbins, main = paste(ROI));
	
	## uncomment the following 3 lines if you want to output individual histogram PNGs for each inputted ROI
        # png(paste(OUTDIR,ROI,"hist_data.png"));
        # hist(DATA, breaks = hbins, main = ROI);
        # dev.off()
	}
dev.off()
}



