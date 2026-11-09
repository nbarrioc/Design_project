#!/bin/bash -l
#PBS -N basecalling
#PBS -l nodes=1:ppn=16:gpus=1
#PBS -l mem=64gb
#PBS -l walltime=00:30:00
#PBS -j oe

set -e

# Settings: edit these before submitting.
PROJECT="/data/gent/courses/2026/design_project_C003698/groups/group05"
POD5="$PROJECT/Data_Adaptive_Sampling_Subtelomeres_NSF/20260706_218847_SV_UHasselt_Telomere_AS/no_sample_id/20260706_1151_1E_PBM53144_daa32bbe/pod5"
OUTPUT="$PROJECT/basecalled_${USER}_sup_test"
MODEL="$PROJECT/basecalling/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0"
MOD_MODEL="$PROJECT/basecalling/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0_5mC_5hmC@v3"
KIT="SQK-NBD114-24"
MAX_READS=1000  # Use 0 for all reads; increase PBS walltime for a full run.

cd "$PROJECT/basecalling"

# Find available modules (uncomment to explore):
# module spider Miniforge3
# module spider dorado

# Choose the cluster. Basecalling below uses the GPU option.
# module swap cluster/doduo       # CPU jobs: also remove :gpus=1 above.
module swap cluster/accelgor      # GPU jobs
module load dorado/1.1.1-foss-2024a-CUDA-12.6.0  # Loads Dorado and CUDA.
module load Miniforge3/25.3.0-3

# Activate the shared group Python environment.
# The module sets EBROOTMINIFORGE3 to this cluster's Miniforge installation.
source "$EBROOTMINIFORGE3/etc/profile.d/conda.sh"
conda activate --stack /data/gent/courses/2026/design_project_C003698/groups/group05/envs/python

# Basecall DNA and methylation together. Use a new output folder for each run.
mkdir "$OUTPUT"
dorado basecaller "$MODEL" "$POD5" \
    --modified-bases-models "$MOD_MODEL" --modified-bases-threshold 0 \
    --device cuda:all --recursive --kit-name "$KIT" \
    --max-reads "$MAX_READS" > "$OUTPUT/calls.bam"

# Split the reads into a BAM file for each barcode.
dorado demux --no-classify --output-dir "$OUTPUT/barcodes" "$OUTPUT/calls.bam"

# Optional example: run a Python script that makes a small plot.
# python example_plot.py
