# Metagenomic Analysis Pipeline (MAP)

Thanks to the increased cost-effectiveness of high-throughput technologies, the number of studies focusing on microorganisms (bacteria, archaea, microbial eukaryotes, fungi, and viruses) and on their connections with human health and diseases has surged, and, consequently, a plethora of approaches and software has been made available for their study, making it difficult to select the best methods and tools. 

MAP *(Metagenomic Analysis Pipeline)* is a pipeline that, starting from the raw sequencing data and having a strong focus on quality control, allows the data processing up to the generation of the to the functional binning and profiling. Software have been selected based on their performances both in terms of quality of the results and computational requirements, aiming at providing an efficient pipeline that can be routinely used in clinical research. 

MAP is a command-line bash script. It is currently at version 0.9.1, released on
April 7th, 2017. It is compatible with Unix, Linux, and Mac OS operating systems.


## Table of contents

- [The MAP workflow](#the-map-workflow)
- [Dependencies](#dependencies)
- [Other requirements](#other-requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Example](#example)
- [Acknowledgement](#acknowledgement)

## The MAP workflow

<img src="https://sites.google.com/site/populationgenomics/metagenomicpipeline/pipeline.png?attredirects=0" height="800px">

The image above depicts the key steps in the analysis of a metagenomic sample. White rectangles represent data to be provided in input, and blue rectangles those produced in output. Pentagons represent the analysis steps. While the solid lines indicate steps that are already implemented in this version of MAP, the dashed one (assessment of diversity and functional annotation) are under development.

Specifically, the QC (green block, performed by means of several tools from the BBmap suite), allows de-duplication, trimming, and decontamination of metagenomics sequences, and each of these steps is accompanied by the visualisation of the data quality (orange block, performed by means of FastQC). The QC is followed by taxonomic binning and profiling (pink block). The taxonomic binning and profiling is performed by means of MetaPhlAn2, which uses clade-specific markers to both detect the organisms present in a microbiome sample and to estimate their relative abundance.


## Dependencies

- fastQC v0.11.2+ ([http://www.bioinformatics.babraham.ac.uk/projects/fastqc](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
- BBsuite v36.92+ ([https://sourceforge.net/projects/bbmap](https://sourceforge.net/projects/bbmap/))
- Bowtie2 v2.2.9+ ([http://bowtie-bio.sourceforge.net/bowtie2/index.shtml](http://bowtie-bio.sourceforge.net/bowtie2/index.shtml))
- MetaPhlAn2 v2.0+ ([https://bitbucket.org/biobakery/metaphlan2](https://bitbucket.org/biobakery/metaphlan2))

All the software need to be in the system path with execute *and* read permission. 
Notably, MetaPhlAn2 is also available in [bioconda](https://anaconda.org/bioconda/metaphlan2), where it will be installed along with Bowtie2.


## Other requirements

MAP requires a set of databases that are queried during its execution. Same of them should be automatically downloaded when installing the extra software, whilst other should be created by the user. Specifically, you will need:

- a FASTA file listing the adapter sequences to remove in the trimming step. This file should be available within the BBmap installation. If not, please download it from [here](https://github.com/BioInfoTools/BBMap/blob/master/resources/adapters.fa)
- a FASTA file describing the contaminating genome(s). This file should be created by the users according to the contaminants present in their dataset. When analysing human metagenome, we suggest the users to always include the human genome. Please note that this file should be indexed beforehand. This can be done using BBMap, using the following command:
	`bbmap.sh -Xmx24G ref=my_contaminants_genomes.fa.gz`
- the BowTie2 database file for MetaPhlAn2. This file should be available within the MetaPhlAn2 installation. If not, please download it from [here](https://bitbucket.org/biobakery/metaphlan2/src/40d1bf693089836b5895623dd9ab1b21eb9a794c/db_v20/?at=default)


## Installation

Clone the MAP repository in directory of your choice:

```
git clone https://github.com/alesssia/MAP.git
```

The repository includes:
- a folder called `scripts` which includes
	- the main bash script, `MAP.nf`, 
	- the configuration files, `MAP_parameters.sh`
- this `README.md` file
- the `LICENSE.md` file

**Note**: the `MAP_parameters.sh` files includes the parameters that will be (explained and) set in [the Example section](#Example).


## Usage

1. Modify the MAP_parameter.sh file available in the installation archive, specifying:
	- your working directory, that is where the results wiil be saved
	- the full path to your (paired-end) raw data 
	- the input quality offset (33 for ASCII+33, 64 for ASCII+64)
	- the prefix used for the result filenames (that is, all files will be saved as prefix_*) 
	- the full paths to the required databases (listed in the "Other requirement" section)
	- the parameters for trimming, decontamination, and taxonomy binning and profiling (if needed). 
2. From a terminal window run the MAP.sh script using the following command: 
	```
	sh MAP.sh
	```


## Example

We will use here a sample from the MetaHIT's project, whose FASTQ paired-end raw data can be downloaded by running the following commands from the terminal window:

```
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011089/ERR011089_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011089/ERR011089_2.fastq.gz
```

For the sake of simplicity, we suppose that they are downloaded in a folder called `data`, located within the installation folder. This folder will also be our working directory, consequently, we will set the following parameters in the `MAP_parameter.sh` file:

```
WORKINGDIR="./MAP/data" 
SAMPLEFILE1="./MAP/data/ERR011089_1.fastq.gz"
SAMPLEFILE2="./MAP/data/ERR011089_2.fastq.gz"
```

In order to make it clearer that this sample belongs to the MetaHIT's project  and has the ID ERR011089, we will add a prefix to all the result files using the following parameter:

```
prefix="Meta_HIT_ERR011089"
```

this parameter is mostly useful when the user would like to assign a human-readable name to the sample, as it can be done using a more detailed prefix, such as *"obese_patient_ID123"*.

The MetaHIT's project used the Illumina 1.9 encoding, so we will set the quality encoding to ASCII+33 using: 

```
qin=33  
```

Again for the sake of simplicity, we suppose that required additional databases have been saved in another subfolder of the installation folder, called `resources`, and thus  we will set the following parameters in the `MAP_parameter.sh` file:

```
adaptersPath="./MAP/resources/adapters.fa"
referencePath="/MAP/resources/"
bowtie2dbPath="/MAP/resources/bowtie2db/db_v20/mpa_v20_m200"
```

We suggest using 4 threads to speed up the computation and at least 24GB of RAM, in order to be able to run the decontamination step with large genomes, that is, to set the following parameters:

```
threads=4
maxmemory=24G
```

We will then run `MAP.sh`, obtaining three sets of files describing, respectively, the results of the quality assessment of the raw data, namely:

```
Meta_HIT_ERR011089_R1_fastqc.html
Meta_HIT_ERR011089_R1_fastqc.zip
Meta_HIT_ERR011089_R2_fastqc.html
Meta_HIT_ERR011089_R2_fastqc.zip
```

of the trimmed data, namely:

```
Meta_HIT_ERR011089_trimmed_R1_fastqc.htm
Meta_HIT_ERR011089_trimmed_R1_fastqc.zip
Meta_HIT_ERR011089_trimmed_R2_fastqc.htm
Meta_HIT_ERR011089_trimmed_R2_fastqc.zip
```

and of the decontaminated data, namely:

```
Meta_HIT_ERR011089_clean_fastqc.html
Meta_HIT_ERR011089_clean_fastqc.zip. 
```

The script will also return two FASTQ files containing the clean and contaminated reads, 

```
Meta_HIT_ERR011089_clean.fq
Meta_HIT_ERR011089_cont.fq,
```

respectively, and the results of the taxonomic profiling and binning, that is

```
Meta_HIT_ERR011089_metaphlan_bugs_list.tsv
Meta_HIT_ERR011089.biom
```

and the log file, which lists statistics about execution time, deduplication, trimming and decontamination:

```
Meta_HIT_ERR011089.log
```



## Acknowledgement

AV would like to thank Brian Bushnell for his helpful suggestions about how to successfully use the BBmap suite in a metagenomics context and for providing several useful resources.


