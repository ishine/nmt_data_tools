#!/bin/bash

function func_shard(){
    local workers=$1
    local infile=$2

    lines=`cat $infile | wc -l`
    echo "total lines: $lines"

    shard_lines=$((lines/${workers})) # lines of each shard
    tail_lines=$((lines%${workers})) # lines of remain

    for i in $(seq 0 $(($workers-1)))
    do
      tail -n +$(($i*$shard_lines+1)) $infile | head -n $shard_lines > $infile.${i}
    done
    tail -n +$(($workers*$shard_lines+1))  $infile>> $infile.$(($workers-1))

    echo "--------------File ${inflie} has been divides into ${workers} shards.--------------"

}

function func_merge_shard(){
    local workers=$1
    local shard_prefix=$2
    local outfile=$3

    for i in $(seq 0 $(($workers-1)))
    do
      cat $shard_prefix.${i} >> $outfile
      rm $shard_prefix.${i}
    done

      echo "---------------${workers} shards have been merged into ${outfile}.--------------"

}

function func_paral_process(){
    local workers=$1
    local py_script=$2
    local infile=$3
    local outfile=$4
    # 1.shard [infile->infile.idx]
    func_shard $workers $infile

    # 2.parallel process [infile.idx->infile.tmp.idx]
    for i in $(seq 0 $(($workers-1)))
    do
      (
      echo "----------------------processing shard: ${i}.----------------------"
      python $py_script $infile.${i} $infile.tmp.${i}
      rm $infile.${i}
      )&
    done
    wait

    # 3.merge [infile.tmp.idx->outfile]
    if [ -e $outfile ];then
      rm $outfile
    fi
    func_merge_shard $workers ${infile}.tmp $outfile


}