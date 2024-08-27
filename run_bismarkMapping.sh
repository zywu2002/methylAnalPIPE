#!/bin/bash

# Check if bismark runs correctly
if ! bismark --version &> /dev/null;
then
	echo "Error: bismark is not working properly or not found in PATH." >&2
	echo "Please ensure bismark is installed correctly and accessible." >&2
	exit 1
fi

# Check if samtools runs correctly
if ! samtools --version &> /dev/null;
then
	echo "Error: samtools is not working properly or not found in PATH." >&2
	echo "Please ensure samtools is installed correctly and accessible." >&2
	exit 1
fi

# Check if deduplicate_bismark runs correctly
if ! deduplicate_bismark --version &> /dev/null;
then
	echo "Error: deduplicate_bismark is not working properly or not found in PATH." >&2
	echo "Please ensure bismark is installed correctly and accessible." >&2
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

# Run bismark mapping

# | Parameters configuration ----------------------------------------------
samples=(sample1 sample2 sample3 sample4)
workDir=/path/to/your/work/directory
# -------------------------------------------------------------------------

R1_ext="_val_1.fq.gz"
R2_ext="_val_2.fq.gz"
genomeDir=$workDir/data/ref/
scriptDir=$workDir/scripts/02bismark_mapping/
trimGaloreDir=$workDir/01trimGalore/
bismarkMappingDir=$workDir/02bismark_mapping/
logDir=$workDir/log/02bismark_mapping/

shellMaster="$scriptDir"shell_master_bismarkMapping.sh
logFile=$logDir"bismark_genome_preparation.log"
echo -e "#!/bin/bash\n" > $shellMaster
echo "bismark_genome_preparation \\" >> $shellMaster
echo " --parallel $threads \\" >> $shellMaster
echo " --verbose \\" >> $shellMaster
echo " $genomeDir \\" >> $shellMaster
echo -e " > $logFile 2>&1\n" >> $shellMaster
shInx=1

for sample in "${samples[@]}";
do
	shWorker=$scriptDir"run_"$shInx"_"$sample"_bismarkMapping.sh"
	shInx=$(($shInx+1))
	r1=$trimGaloreDir$sample"/*"$R1_ext
	r2=$trimGaloreDir$sample"/*"$R2_ext
	outDir=$bismarkMappingDir$sample
	tmpDir=$bismarkMappingDir$sample"/temp"
	logFile=$logDir$sample"_bismarkMapping.log"
	rawBAM=$outDir"/"$sample"_bismark.bam"
	report=$outDir"/"$sample"_bismark_mapping_report.txt"
	sortBAM=$outDir"/"$sample"_bismark.sorted.bam"
	dedupBAM=$outDir"/"$sample"_bismark.sorted.dedup.bam"
	mkdir -p $logDir
	mkdir -p $outDir
	echo "bash $shWorker" >> $shellMaster
	echo -e "#!/bin/bash\n" > $shWorker
	echo "bismark \\" >> $shWorker
	echo " --score_min L,0,-0.6 \\" >> $shWorker
	echo " -N 0 \\" >> $shWorker
	echo  " -L 20 \\" >> $shWorker
	echo " --parallel $threads \\" >> $shWorker
	echo " --temp_dir $tmpDir \\" >> $shWorker
	echo " --output_dir $outDir \\" >> $shWorker
	echo " -1 $r1 \\" >> $shWorker
	echo " -2 $r2 \\" >> $shWorker
	echo " $genomeDir \\" >> $shWorker
	echo -e " >> $logFile 2>&1\n" >> $shWorker
	echo "mv $outDir/*_bismark_bt2*.bam $rawBAM" >> $shWorker
	echo -e "mv $outDir/*_bismark_bt2*_report.txt $report\n" >> $shWorker
	echo "samtools sort \\" >> $shWorker
	echo " -n \\" >> $shWorker
	echo " -o $sortBAM \\" >> $shWorker
	echo " -@ $threads \\" >> $shWorker
	echo " $rawBAM \\" >> $shWorker
	echo -e " >> $logFile 2>&1\n" >> $shWorker
	echo "deduplicate_bismark \\" >> $shWorker
	echo " --paired \\" >> $shWorker
	echo " --bam \\" >> $shWorker
	echo " --outfile $dedupBAM \\" >> $shWorker
	echo " $sortBAM \\" >> $shWorker
	echo -e " >> $logFile 2>&1\n" >> $shWorker
	echo -e "rm -rf $tmpDir\n" >> $shellMaster
done