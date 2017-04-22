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


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# General Parameters
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#Number of threads to be used by the applications, and max memory allocated
threads=4
maxmemory=24G

#Where the results should be saved
WORKINGDIR="" 

#The paired-end compressed raw data (FASTQ):
#   SAMPLEFILE1 is the forward strand, 
#	SAMPLEFILE2 is the reverse strand
SAMPLEFILE1=""
SAMPLEFILE2=""

#Used as prefix for all the results
prefix="mysample"

# Input quality offset: 33 (ASCII+33) or 64 (ASCII+64)
# ASCII+33 is used by the Sanger/Illumina 1.9+ encoding, whilst ASCII+64 by the
# Illumina 1.5 encoding 
qin=33  

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Database parameters
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#Path to the BBmap FASTA file for adapter (available when installing BBmap, or at
#https://github.com/BioInfoTools/BBMap/blob/master/resources/adapters.fa)
adaptersPath=""
#Path to the reference genome used for decontamination (run specific)
referencePath=""
#Path the BowTie2 database file of the MetaPhlAn2 database (available when installing
# MetaPhlAn2, or at https://bitbucket.org/biobakery/metaphlan2/src/40d1bf693089836b5895623dd9ab1b21eb9a794c/db_v20/?at=default)
bowtie2dbPath=""

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Trimming parameters (see BBduk guide for details)
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#Regions with average quality BELOW this will be trimmed  
phred=10 
#Reads shorter than this after trimming will be discarded
minlength=60 
#Shorter kmers at read tips to look for 
mink=11 
#Maximum Hamming distance for ref kmers   
hdist=1  

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Decontamination parameters (see BBduk guide for details)
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#k-mer length used for finding contaminants	
kcontaminants=23
#Approximate minimum alignment identity to look for 
mind=0.95
#Longest indel to look for
maxindel=3
#Restrict alignment band to this
bwr=0.16 

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Profiling parameters (see MetaPhlAn2 guide for details)
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#presets options for BowTie2
bt2options="very-sensitive"

