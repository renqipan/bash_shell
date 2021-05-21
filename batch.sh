#!/bin/bash

# by defaults, you need to provide 2 arguments,
# $1: the python file use to analyze
# $2: the full path name of dataset

# no.1 step
echo -e "\033[1m==> Checking validity of input parameters...\033[0m"
[[ -z $1 ]] && { echo "	-> Exiting, 1st parameter should not be empty!" && exit 1; }
[[ -z $2 ]] && { echo "	-> Exiting, 2nd parameter should not be empty!" && exit 1; }
[[ ! -f $1 ]] && { echo "	-> Exiting, 1st parameter is not a regular file!" && exit 1; }
[[ -z $CMSSW_BASE ]] && { echo "	-> Exiting, forget to cmsenv inside QCDAnalysis?" && exit 1; }
[[ ! -d $CMSSW_BASE/src/QCDAnalysis ]] && { echo "	-> Exiting, QCDAnalysis doesn't existed!" && exit 1; }

# no.2 step
echo -e "\033[1m==> Checking x509 user proxy...\033[0m"
if [[ ! -f ~/x509up ]]; then # proxy not exist, create it
	voms-proxy-init --voms cms --out ~/x509up
	[[ $? != "0" ]] && { echo "  -> Exiting, with x509 creating error..."; exit 2; }
else # if it's exist, then check it's validity
	voms-proxy-info --file ~/x509up --valid 8:00
	if [[ $? != "0" ]]; then
		voms-proxy-init --voms cms --out ~/x509up
		[[ $? != "0" ]] && { echo "  -> Exiting, with x509 creating error..."; exit 2; }
	fi
fi
export X509_USER_PROXY=~/x509up

# no.3 step
echo -e "\033[1m==> Satisfying build enviroment...\033[0m"
logs_dir=$PWD/logs
# cut the dataset string after the first slash, the back-quote `` is needed
dataset_prefix=`cut -d / -f 2 <<< $2`
public_dir=/eos/user${HOME#*/user}/public/$dataset_prefix
# truncate eos dataset folder caches
[[ -d $public_dir ]] && rm -rf $public_dir
mkdir -p $public_dir
[[ -d $logs_dir ]] && rm -rf $logs_dir
mkdir $logs_dir
# create python file and inroot lists
python_file=$(dirname $(readlink -e $1))/$(basename $1)
inroot_file=$logs_dir/inroot_list.txt
cp $python_file $logs_dir/analyze.py && touch $inroot_file
# creating run.sh
# you can add single quote, e.g. 'EOL' to avoid $ expansions
cat > $logs_dir/run.sh << EOL
#!/bin/bash
cd $logs_dir
eval \$(scramv1 runtime -sh)
cmsRun analyze.py \$1 \$2
EOL
chmod +x $logs_dir/run.sh
# creating condor.sub
cat > $logs_dir/condor.sub << EOL
executable = run.sh
arguments = \$(inroot) $public_dir/Chunk\$(Process).root
log = \$(Cluster).log
output = Chunk\$(Process)/job.out
error = Chunk\$(Process)/job.err
request_memory = 1024
request_disk = 10240
x509userproxy = \$ENV(HOME)/x509up
should_transfer_files = yes
+JobFlavour = "longlunch"

queue inroot from inroot_list.txt
EOL

# no.4 step
echo -e "\033[1m==> Fetching root file list...\033[0m"
dasgoclient -query="file dataset=$2" &>/dev/null
[[ $? != "0" ]] && { echo "  -> Exiting, dasgoclient cannot find root files..."; exit 4; }
dasgoclient -query="file dataset=$2" 1>>$logs_dir/inroot_list.txt
# create all sub-directories
for (( i=0; i<$(cat $logs_dir/inroot_list.txt | wc -l); i++ )); do
	mkdir $logs_dir/Chunk$i
done
