#!/bin/bash

# Check if trim_galore runs correctly
if ! trim_galore --version &> /dev/null;
then
	echo "Error: trim_galore is not working properly or not found in PATH." >&2
	echo "Please ensure trim_galore is installed correctly and accessible." >&2
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

# Run trim_galore

# | Parameters configuration ----------------------------------------------
R1_ext=""	# e.g. "_R1.fq.gz"
R2_ext=""	# e.g. "_R2.fq.gz"
samples=(sample1 sample2 sample3 sample4)
workDir=/path/to/your/work/directory
# -------------------------------------------------------------------------

scriptDir=$workDir/scripts/01trimGalore/
WGBSDir=$workDir/data/WGBS/
trimGaloreDir=$workDir/01trimGalore/
logDir=$workDir/log/01trimGalore/
multiqcDir=$trimGaloreDir"multiqc/"
mkdir -p $multiqcDir
multiqcLog=$multiqcDir"multiqc.log"

shellMaster="$scriptDir"shell_master_trimGalore.sh
echo -e "#!/bin/bash\n" > $shellMaster
shInx=1

for sample in "${samples[@]}";
do
	shWorker=$scriptDir"run_"$shInx"_"$sample"_trimGalore.sh"
	shInx=$(($shInx+1))
	r1=$WGBSDir$sample$R1_ext
	r2=$WGBSDir$sample$R2_ext
	outDir=$trimGaloreDir$sample
	logFile=$logDir$sample"_trimGalore.log"
	mkdir -p $logDir
	mkdir -p $outDir
	echo "bash $shWorker" >> $shellMaster
	echo -e "#!/bin/bash\n" > $shWorker
	echo "trim_galore \\" >> $shWorker
	echo " --fastqc \\" >> $shWorker
	echo " --fastqc_args '--format fastq --outdir $outDir --dir $outDir --threads $threads' \\" >> $shWorker
	echo " --phred33 \\" >> $shWorker
	echo " --gzip \\" >> $shWorker
	echo " --length 20 \\" >> $shWorker
	echo " --output_dir $outDir \\" >> $shWorker
	echo " --core $threads \\" >> $shWorker
	echo " --paired $r1 $r2 \\" >> $shWorker
	echo -e " > $logFile 2>&1\n" >> $shWorker
	echo "cp $outDir/*_fastqc.zip $multiqcDir" >> $shWorker
done

echo "multiqc --outdir $multiqcDir $multiqcDir*fastqc.zip > $multiqcLog 2>&1" >> $shellMaster
