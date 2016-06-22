
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

TBSSDIR = cmdargs[1];  

OUTDIR = paste(TBSSDIR,'/QC_ENIGMA',sep = '')
CSVFILE = paste(TBSSDIR,'/EXTRAROI/Final/Final_AverageFA_AllSubjects_T.csv',sep = '')

rois="AverageFA;ACR;ALIC;BCC;CC;CGC;CGH;CR;CST;EC;FX;FXST;GCC;IC;IFO;PCR;PLIC;PTR;RLIC;SCC;SCR;SFO;SLF;SS;UNC"
Nrois = 25;

OUTPDF = paste(TBSSDIR,'/QC_ENIGMA/25ROI_histograms.pdf',sep = '')
OUTTXT = paste(TBSSDIR,'/QC_ENIGMA/25ROI_stats.txt',sep = '')

#if (NroiC=="all") {
#  		ROImatrix<-data.matrix(read.table(as.character(Rfile),sep=",",header=T,blank.lines.skip = TRUE,na.strings = "NaN",row.names=1))
#			rownames=row.names(ROImatrix)
#			for (r in 1:length(rownames)) {
#			origcolnames = colnames(DesignMatrix);
#			DesignMatrix[,length(DesignMatrix)+1] = rep(NA,length(as.vector(matchind)))
#			colnames(DesignMatrix)<-c(origcolnames,rownames[r])
#			}


dir.create(OUTDIR)

Table <- read.csv(CSVFILE,header=T, sep = ' ');
colTable = names(Table);

## assigning all rows that have a value of "x" or "X" to "NA"
for (m in seq(1,length(colTable)))
{
  ind = which(Table[,m]=="x");
  ind2 = which(Table[,m]=="X");
  Table[ind] = "NA"
  Table[ind2] = "NA"
}

##get rid of all rows with NAs in them
INDX=which(apply(Table,1,function(x)any(is.na(x))));

##get rid of all rows with NAs in them
if (length(INDX) >0 )
{
  Table<-Table[-which(apply(Table,1,function(x)any(is.na(x)))),]
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
    
    DATA = Table[ROI];
    DATA = unlist(DATA);
    DATA = as.numeric(as.vector(DATA));
    
    mu = mean(DATA);
    sdev = sd(DATA);
    N = length(DATA);
    
    hbins = 20; #floor(N/10);
    
    maxV = max(DATA);
    minV = min(DATA);
    
    i =which(DATA==maxV)
    maxSubj = Table[i,1]
    
    j =which(DATA==minV)
    minSubj = Table[j,1]
    
    stats = c(ROI, N, mu, sdev, maxV, minV);
    
    print(stats)
    
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


