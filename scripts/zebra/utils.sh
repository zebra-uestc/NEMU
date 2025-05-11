#!/bin/bash

# prepare env

set -x

export NEMU_HOME=$HOME/NEMU
export NEMU=$NEMU_HOME/build/riscv64-nemu-interpreter
export GCPT=$NEMU_HOME/resource/gcpt_restore/build/gcpt.bin
export SIMPOINT=$NEMU_HOME/resource/simpoint/simpoint_repo/bin/simpoint

export WORKLOAD_ROOT_PATH=$HOME/workloads/bbls
export RESULT=$NEMU_HOME/parallel_result
export LOG_PATH=$RESULT/logs
export profiling_result_name=profiling
export PROFILING_RES=$RESULT/$profiling_result_name
export interval=$((20 * 1000 * 1000))

# Profiling
profiling() {
	set -x
	workload=$1
	log=$LOG_PATH/profiling_logs/${workload}
	mkdir -p $log

	data_dir=/root/NEMU/zebra_data/${workload}
	$NEMU ${WORKLOAD_ROOT_PATH}/${workload}-bbl-linux-spec.bin \
		-D $RESULT -w $workload -C $profiling_result_name \
		-b --simpoint-profile --cpt-interval ${interval} \
		--zebra-bb-jump ${data_dir}/bb_addr_start.txt \
		-r $GCPT >$log/${workload}-out.txt 2>${log}/${workload}-err.txt
}
export -f profiling

# Cluster
cluster() {
	set -x
	workload=$1

	export CLUSTER=$RESULT/cluster/${workload}
	mkdir -p $CLUSTER

	random1=$(head -20 /dev/urandom | cksum | cut -c 1-6)
	random2=$(head -20 /dev/urandom | cksum | cut -c 1-6)

	log=$LOG_PATH/cluster_logs/${workload}
	mkdir -p $log

	$SIMPOINT \
		-loadFVFile $PROFILING_RES/${workload}/simpoint_bbv.gz \
		-saveSimpoints $CLUSTER/simpoints0 -saveSimpointWeights $CLUSTER/weights0 \
		-savePreprocessData ${CLUSTER}/reduced-dimension.txt \
		-saveFinalCtrs ${CLUSTER}/centroid.txt \
		-saveLabels ${CLUSTER}/labels.txt \
		-inputVectorsGzipped -maxK 30 -numInitSeeds 2 -iters 1000 -seedkm ${random1} -seedproj ${random2} \
		>$log/${workload}-out.txt 2>$log/${workload}-err.txt
}
export -f cluster

# Checkpointing
checkpoint() {
	set -x
	workload=$1

	export CLUSTER=$RESULT/cluster
	log=$LOG_PATH/checkpoint_logs/${workload}
	mkdir -p $log
	$NEMU ${WORKLOAD_ROOT_PATH}/${workload}-bbl-linux-spec.bin \
		-D $RESULT -w ${workload} -C checkpoint \
		-b -S $CLUSTER --cpt-interval $interval \
		--checkpoint-format zstd \
		-r $GCPT >$log/${workload}-out.txt 2>$log/${workload}-err.txt
}
export -f checkpoint

export workload_list=$NEMU_HOME/scripts/zebra/workload_list/batch2_list.txt

parallel_profiling() {
	export num_threads=24
	cat $workload_list | parallel -a - -j $num_threads profiling {}
}
export -f parallel_profiling

parallel_cluster() {
	export num_threads=24
	cat $workload_list | parallel -a - -j $num_threads cluster {}
}
export -f parallel_cluster

parallel_checkpoint() {
	export num_threads=24
	cat $workload_list | parallel -a - -j $num_threads checkpoint {}
}
export -f parallel_checkpoint

# Usually, I use parallel_<operation> to process a few benchmarks in parallel.

# If you want to process a single workload, you can use the following commands:
# profiling <benchmark>
# cluster <benchmark>
# checkpoint <benchmark>


# parallel_<operation> is used for parallel process
# parallel_profiling
# parallel_cluster
# parallel_checkpoint

# workload_list is used for parallel process
# workload_list is a file that contains the list of workloads to be processed
:<<workload_list_example
perlbench_checkspam
bzip2_chicken
gcc_166
bwaves
gamess_cytosine
milc
gobmk_13x13
hmmer_nph3
workload_list_example
