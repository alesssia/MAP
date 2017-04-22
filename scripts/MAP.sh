#  Metagenomic analysis pipeline (MAP) version 0.9.1 -- 20170407
#  Copyright (C) 2017 	Dr Alessia Visconti 	(developer, contributor) 
#					  	Ms Tiphaine C. Martin   (contributor)  		      
#        
#  This script is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this script.  If not, see <http://www.gnu.org/licenses/>.
#
#  For any bugs or problems found, please contact us at
#  alessia.visconti@kcl.ac.uk

log()
# Prints a message ($1) to a file ($2)
{
	echo $1 >> $2
}

#Loads the parameters
source MAP_parameters.sh

#Creates a log file
LOGFILE=$WORKINGDIR/$prefix.log


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 0. Prints a log message
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

log "" $LOGFILE	
log "---------------------------------------------" $LOGFILE
log "METAGENOMIC ANALYSIS PIPELINE (version 0.9.1)" $LOGFILE
log "---------------------------------------------" $LOGFILE
log "" $LOGFILE
log "Copyright (C) 2017" $LOGFILE
log "Dr Alessia Visconti   <alessia.visconti@kcl.ac.uk>" $LOGFILE
log "Ms Tiphaine C. Martin <tiphaine.martin@kcl.ac.uk>"  $LOGFILE
log "" $LOGFILE
log "This script is distributed in the hope that it will be useful"  $LOGFILE
log "but WITHOUT ANY WARRANTY. See the GNU GPL v3.0 for more details." $LOGFILE
log "" $LOGFILE
log "Please report comments and bugs to:" $LOGFILE
log "   - alessia.visconti@kcl.ac.uk"     $LOGFILE
log "" $LOGFILE
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE

sysdate=$(date)
log "Analysis starting at $sysdate." $LOGFILE
log "" $LOGFILE	
log "Analysed samples are: $SAMPLEFILE1 and $SAMPLEFILE2" $LOGFILE
log "Working directory set to $WORKINGDIR" $LOGFILE
log "Logs saved at $LOGFILE" $LOGFILE
log "New files will be saved using the '$prefix' prefix" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 1. Quality assessment of the raw data file.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sysdate=$(date)
starttime=$(date +%s.%N)
log "Performing STEP 1 [Assessment of raw data quality] at $sysdate" $LOGFILE
log "" $LOGFILE	

base1=$(basename $SAMPLEFILE1 | cut -d. -f 1)
base2=$(basename $SAMPLEFILE2 | cut -d. -f 1)

### Foward reads
fastqc --quiet --noextract --format fastq --threads $threads --outdir=$WORKINGDIR $SAMPLEFILE1
mv $WORKINGDIR/${base1}_fastqc.html $WORKINGDIR/${prefix}_R1_fastqc.html
mv $WORKINGDIR/${base1}_fastqc.zip $WORKINGDIR/${prefix}_R1_fastqc.zip

### Reverse reads
fastqc --quiet --noextract --format fastq --threads $threads --outdir=$WORKINGDIR $SAMPLEFILE2
mv $WORKINGDIR/${base2}_fastqc.html $WORKINGDIR/${prefix}_R2_fastqc.html
mv $WORKINGDIR/${base2}_fastqc.zip $WORKINGDIR/${prefix}_R2_fastqc.zip

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "           STEP 1 terminated at $sysdate ($exectime seconds)" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 2. De-duplication. Reads having exact duplicates are removed.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sysdate=$(date)
starttime=$(date +%s.%N)
log "Performing STEP 2 [De-duplication] at $sysdate" $LOGFILE
log "" $LOGFILE	

clumpify.sh -Xmx$maxmemory in1=$SAMPLEFILE1 in2=$SAMPLEFILE2 out1=$WORKINGDIR/${prefix}_dedupe_R1.fq.gz out2=$WORKINGDIR/${prefix}_dedupe_R2.fq.gz qin=$qin dedupe subs=0 threads=$threads &> $WORKINGDIR/tmp.log

#Logs some figures about sequences passing de-duplication
log "BBduk's de-duplication stats: " $LOGFILE
log "" $LOGFILE
sed -n '/Reads In:/,/Duplicates Found:/p' $WORKINGDIR/tmp.log >> $LOGFILE
log "" $LOGFILE
totR=$(grep "Reads In:" $WORKINGDIR/tmp.log | cut -f 1 | cut -d: -f 2 | sed 's/ //g')
remR=$(grep "Duplicates Found:" $WORKINGDIR/tmp.log | cut -f 1 | cut -d: -f 2 | sed 's/ //g')
survivedR=$(($totR-$remR))
percentage=$(echo $survivedR $totR | awk '{print $1/$2*100}' )
log "$survivedR out of $totR paired reads survived de-duplication ($percentage%, $remR reads removed)" $LOGFILE

rm $WORKINGDIR/tmp.log

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "" $LOGFILE
log "           STEP 2 terminated at $sysdate ($exectime seconds)" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 3. Trimming of low quality bases and of adapter sequences.
# Short reads are discarded. When either forward or reverse of a paired-end read 
# are discarded, the surviving end is saved on a file of unpaired reads.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sysdate=$(date)
starttime=$(date +%s.%N)
log "Skipping STEP 3 [Trimming] at $sysdate" $LOGFILE
log "" $LOGFILE	

bbduk.sh -Xmx$maxmemory in=$WORKINGDIR/${prefix}_dedupe_R1.fq.gz in2=$WORKINGDIR/${prefix}_dedupe_R2.fq.gz out=$WORKINGDIR/${prefix}_trimmed_R1.fq out2=$WORKINGDIR/${prefix}_trimmed_R2.fq outs=$WORKINGDIR/${prefix}_trimmed_singletons.fq ktrim=r k=$kcontaminants mink=$mink hdist=$hdist qtrim=rl trimq=$phred  minlength=$minlength ref=$adaptersPath qin=$qin threads=$threads tbo tpe ow &> $WORKINGDIR/tmp.log

#Logs some figures about sequences passing trimming
log  "BBduk's trimming stats (trimming adapters and low quality sequences): " $LOGFILE
sed -n '/Input:/,/Result:/p' $WORKINGDIR/tmp.log >> $LOGFILE
log "" $LOGFILE
unpairedR=$(wc -l $WORKINGDIR/${prefix}_trimmed_singletons.fq | cut -d" " -f 1)
unpairedR=$(($unpairedR/4))
log  "$unpairedR singleton reads whose mate was trimmed shorter have been preserved" $LOGFILE
log "" $LOGFILE

rm $WORKINGDIR/tmp.log $WORKINGDIR/${prefix}_dedupe_R1.fq.gz $WORKINGDIR/${prefix}_dedupe_R2.fq.gz

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "         STEP 3 terminated at $sysdate ($exectime seconds)" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 4.  Quality assessment of the trimmed data file.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sysdate=$(date)
starttime=$(date +%s.%N)
log "Performing STEP 4 [Assessment of trimmed data quality] at $sysdate" $LOGFILE
log "" $LOGFILE	

fastqc --quiet --noextract --format fastq --threads $threads --outdir=$WORKINGDIR $WORKINGDIR/${prefix}_trimmed_R1.fq
mv $WORKINGDIR/${prefix}_trimmed_R1.fq_fastqc.html $WORKINGDIR/${prefix}_trimmed_R1_fastqc.html
mv $WORKINGDIR/${prefix}_trimmed_R1.fq_fastqc.zip $WORKINGDIR/${prefix}_trimmed_R1_fastqc.zip

fastqc --quiet --noextract --format fastq --threads $threads --outdir=$WORKINGDIR $WORKINGDIR/${prefix}_trimmed_R2.fq
mv $WORKINGDIR/${prefix}_trimmed_R2.fq_fastqc.html $WORKINGDIR/${prefix}_trimmed_R2_fastqc.html
mv $WORKINGDIR/${prefix}_trimmed_R2.fq_fastqc.zip $WORKINGDIR/${prefix}_trimmed_R2_fastqc.zip

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "           STEP 4 terminated at $sysdate ($exectime seconds)" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 5. Decontamination. Reads mapping to foreign genomes are separated from
# clean metagenomic data
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sysdate=$(date)
starttime=$(date +%s.%N)
log "Performing STEP 5 [Decontamination] at $sysdate" $LOGFILE
log "" $LOGFILE	

bbwrap.sh -Xmx$maxmemory mapper=bbmap append=t in1=$WORKINGDIR/${prefix}_trimmed_R1.fq,$WORKINGDIR/${prefix}_trimmed_singletons.fq in2=$WORKINGDIR/${prefix}_trimmed_R2.fq,null outu=$WORKINGDIR/${prefix}_clean.fq outm=$WORKINGDIR/${prefix}_cont.fq minid=$mind maxindel=$maxindel bwr=$bwr bw=12 minhits=2 qtrim=rl trimq=$phred path=$referencePath qin=$qin threads=$threads untrim quickmatch fast ow &> $WORKINGDIR/tmp.log
	
#Logs some figures about decontaminated/contaminated reads
log  "BBmap's decontamination stats (paired reads): " $LOGFILE
sed -n '/Read 1 data:/,/N Rate:/p' $WORKINGDIR/tmp.log | head -17 >> $LOGFILE		 
log "" $LOGFILE	
sed -n '/Read 2 data:/,/N Rate:/p' $WORKINGDIR/tmp.log >> $LOGFILE
log "" $LOGFILE	
log  "BBmap's decontamination stats (singletons reads): " $LOGFILE
sed -n '/Read 1 data:/,/N Rate:/p' $WORKINGDIR/tmp.log | tail -17 >> $LOGFILE		 
log "" $LOGFILE	
	
nClean=$(wc -l $WORKINGDIR/${prefix}_clean.fq | cut -d" " -f 1)
nClean=$(($nClean/4))
nCont=$(wc -l $WORKINGDIR/${prefix}_cont.fq | cut -d" " -f 1)
nCont=$(($nCont/4))
log "$nClean reads survived decontamination ($nCont reads removed)" $LOGFILE
log "" $LOGFILE	

rm $WORKINGDIR/tmp.log $WORKINGDIR/${prefix}_trimmed_R1.fq $WORKINGDIR/${prefix}_trimmed_R2.fq $WORKINGDIR/${prefix}_trimmed_singletons.fq

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "           STEP 5 terminated at $sysdate ($exectime seconds)" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 6. Quality assessment of the decontaminated data file.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sysdate=$(date)
starttime=$(date +%s.%N)
log "Performing STEP 6 [Assessment of decontaminated data quality] at $sysdate" $LOGFILE
log "" $LOGFILE	

fastqc --quiet --noextract --format fastq --threads $threads --outdir=$WORKINGDIR $WORKINGDIR/${prefix}_clean.fq
mv $WORKINGDIR/${prefix}_clean.fq_fastqc.html $WORKINGDIR/${prefix}_clean_fastqc.html
mv $WORKINGDIR/${prefix}_clean.fq_fastqc.zip $WORKINGDIR/${prefix}_clean_fastqc.zip

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "           STEP 6 terminated at $sysdate ($exectime seconds)" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# STEP 7. Taxonomic binning and profiling.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sysdate=$(date)
starttime=$(date +%s.%N)
log "Performing STEP 7 [Taxonomic binning and profiling] at $sysdate" $LOGFILE
log "" $LOGFILE	

metaphlan2.py --input_type fastq --tmp_dir=$WORKINGDIR --biom  $WORKINGDIR/${prefix}.biom  --bowtie2db $bowtie2dbPath --bt2_ps $bt2options --nproc $threads $WORKINGDIR/${prefix}_clean.fq $WORKINGDIR/${prefix}_metaphlan_bugs_list.tsv

rm $WORKINGDIR/${prefix}_clean.fq.bowtie2out.txt

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "           STEP 7 terminated at $sysdate ($exectime seconds)" $LOGFILE
log "" $LOGFILE	
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $LOGFILE
log "" $LOGFILE	

endtime=$(date +%s.%N)
exectime=$(echo "$endtime - $starttime" | bc)
sysdate=$(date)
log "Analysis terminated at $sysdate." $LOGFILE
log "" $LOGFILE	

