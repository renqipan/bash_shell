#!/bin/bash
# bash script to run MCFM-8.3
# this script is written by Renqi Pan
Cpq3=(0.5 1.0)
Cpu=(0.5 1.0)
ReCup=(1.0 1.5 2.0 )
ImCup=(0.0 0.5 1.0 )

for a1 in ${Cpq3[*]}
do 
for a2 in ${Cpu[*]}
do	
for a3 in ${ReCup[*]} 
do
for a4 in ${ImCup[*]}
do
	echo "Current parameters are: $a1 $a2 $a3 $a4."
	mkdir -p ci$a1$a2$a3$a4
	cp input.DAT ci$a1$a2$a3$a4/
	cd ci$a1$a2$a3$a4
	sed -i "128s/+0.0/$a1/" input.DAT
	sed -i "129s/+0.0/$a2/" input.DAT
	sed -i "130s/+0.0/$a3/" input.DAT
	sed -i "131s/+0.0/$a4/" input.DAT
	sed -i "18s/ci0000/ci$a1$a2$a3$a4/" input.DAT
	cd ../
	nohup ./mcfm_omp ci$a1$a2$a3$a4/ input.DAT >/dev/null  2>log &
done
done
done
done

flag="true"
while [ $flag = "true" ]
do
	ps | grep "mcfm" 
	if [ $? -eq 0 ]; then
		echo "the program is runing."
		sleep 1m
	else 
		echo "the MCFM is finished."
		flag="false"
	fi
done

ps | grep "mcfm" 
if [ $? -ne 0 ]; then
	echo "the program is finished."
	echo "run the .C files via CERN ROOT." 
	echo "move the .root files to a new directory."
	mkdir -p EW_files
	files=$(ls |grep ci)
	for filename in $files
	do
		cd $filename
		sed -i '172s/ci.*_ci/ci/' *.C
		root -l -q -b *.C
		mv *.root ../EW_files/
		cd ../ 
	done
	echo "all files are copied to EW_files."
	cd EW_files/
	rename 's/.*ci/ci/' *.root
	cd ../
	echo "EW corrections files are storied in EW_files."
	rm -rf ci*
fi
