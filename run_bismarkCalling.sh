#!/bin/bash

# Check if bismark_methylation_extractor runs correctly
if ! bismark_methylation_extractor --version &> /dev/null;
then
	echo "Error: bismark_methylation_extractor is not working properly or not found in PATH." >&2
	echo "Please ensure bismark is installed correctly and accessible." >&2
	exit 1
fi

# Check if bismark2bedGraph runs correctly
if ! bismark2bedGraph --version &> /dev/null;
then
	echo "Error: bismark2bedGraph is not working properly or not found in PATH." >&2
	echo "Please ensure bismark is installed correctly and accessible." >&2
	exit 1
fi

# Check if multiqc runs correctly
if ! multiqc --version &> /dev/null;
then
	echo "Error: multiqc is not working properly or not found in PATH." >&2
	echo "Please ensure multiqc is installed correctly and accessible." >&2
	exit 1
fi

# Setup threads
if [ $# -eq 0 ];
then
	threads=5
	echo "No thread count specified, using default: "$threads
else
	threads=$1
	echo "Using specified thread count: "$threads
fi

# Run bismark calling

# | Parameters configuration -------------------------------------------------
samples=(sample1 sample2 sample3 sample4)
workDir=/path/to/your/work/directory
ignoreParams=""	# e.g. "--ignore_3prime 5 --ignore_r2 10 --ignore_3prime_r2 5"
# ----------------------------------------------------------------------------

genomeDir=$workDir/data/ref/
scriptDir=$workDir/scripts/03bismark_calling/
bismarkMappingDir=$workDir/02bismark_mapping/
bismarkCallingDir=$workDir/03bismark_calling/
logDir=$workDir/log/03bismark_calling/

shellMaster="$scriptDir"shell_master_bismarkCalling.sh
echo -e "#!/bin/bash\n" > $shellMaster
shInx=1

for sample in "${samples[@]}";
do
	shWorker=$scriptDir"run_"$shInx"_"$sample"_bismarkCalling.sh"
	shInx=$(($shInx+1))
	outDir=$bismarkCallingDir$sample
	logFile=$logDir$sample"_bismarkCalling.log"
	dedupBAM=$bismarkMappingDir$sample"/"$sample"_bismark.sorted.dedup.bam"
	mkdir -p $logDir
	mkdir -p $outDir
	echo "bash $shWorker" >> $shellMaster
	echo -e "#!/bin/bash\n" > $shWorker
	echo "bismark_methylation_extractor \\" >> $shWorker
	echo " $ignoreParams \\" >> $shWorker
	echo " --paired-end \\" >> $shWorker
	echo " --multicore $threads \\" >> $shWorker
	echo " --no_overlap \\" >> $shWorker
	echo " --comprehensive \\" >> $shWorker
	echo " --gzip \\" >> $shWorker
	echo " --CX \\" >> $shWorker
	echo " --cytosine_report \\" >> $shWorker
	echo " --genome_folder $genomeDir \\" >> $shWorker
	echo " --output_dir $outDir \\" >> $shWorker
	echo " $dedupBAM \\" >> $shWorker
	echo -e " > $logFile 2>&1\n" >> $shWorker
	echo "bismark2bedGraph \\" >> $shWorker
	echo " --output CpG.cov \\" >> $shWorker
	echo " --dir $outDir \\" >> $shWorker
	echo " $outDir/CpG_context_* \\" >> $shWorker
	echo " >> $logFile 2>&1" >> $shWorker
	echo "bismark2bedGraph \\" >> $shWorker
	echo " --output CHG.cov \\" >> $shWorker
	echo " --dir $outDir \\" >> $shWorker
	echo " --CX \\" >> $shWorker
	echo " $outDir/CHG_context_* \\" >> $shWorker
	echo " >> $logFile 2>&1" >> $shWorker
	echo "bismark2bedGraph \\" >> $shWorker
	echo " --output CHH.cov \\" >> $shWorker
	echo " --dir $outDir \\" >> $shWorker
	echo " --CX \\" >> $shWorker
	echo " $outDir/CHH_context_* \\" >> $shWorker
	echo -e " >> $logFile 2>&1\n" >> $shWorker
	echo "gzip -dc $outDir/CpG.cov.gz.bismark.cov.gz 1> $bismarkCallingDir${sample}_CpG.cov.txt 2>> $logFile" >> $shWorker
	echo "gzip -dc $outDir/CHG.cov.gz.bismark.cov.gz 1> $bismarkCallingDir${sample}_CHG.cov.txt 2>> $logFile" >> $shWorker
	echo -e "gzip -dc $outDir/CHH.cov.gz.bismark.cov.gz 1> $bismarkCallingDir${sample}_CHH.cov.txt 2>> $logFile\n" >> $shWorker
done

echo -e "\nmultiqc $bismarkCallingDir -o $bismarkCallingDir" >> $shellMaster
