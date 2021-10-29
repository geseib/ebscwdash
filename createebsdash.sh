if [ $# -lt 2 ]
  then
    printf "Requires 2 arguments: \n\t1) ebs volumeID and \n\t2) a name used for dashboard/cloudformation stack \n\t (ex. ./createebsdash.sh vol-123456788 myEBSDashboard) \n"
    exit 1
fi

region=${3:-us-east-1}
iops=$(aws ec2 describe-volumes --volume-ids $1 --output yaml | grep Iops | cut -d " " -f4)

size=$(aws ec2 describe-volumes --volume-ids $1 --output yaml | grep Size | cut -d " " -f4)

throughput=$(aws ec2 describe-volumes --volume-ids $1 --output yaml | grep Throughput | cut -d " " -f4)

type=$(aws ec2 describe-volumes --volume-ids $1 --output yaml | grep VolumeType | cut -d " " -f4)

instance=$( aws ec2 describe-volumes --volume-ids $1 --output yaml | grep InstanceId | cut -d " " -f6)

if [[ $type = "gp2" ]]
then 
  echo "its tried and true gp2"
  if [[ $size -le 170 ]]
  then
    throughput=128
  else
    throughput=250
  fi
elif [[ $type = "gp2" ]]
then 
  echo "its gotta be  gp3"
  throughput=$(aws ec2 describe-volumes --volume-ids $1 --output yaml | grep Throughput | cut -d " " -f4)
elif [[ $type = "io2" ]]
then 
  echo "you already knew it was  io2"
  throughput=1000
fi

echo "the $type volume has a size of $size GB and has $iops IOPs and a throughput of $throughput, attached to $instance"

aws cloudformation create-stack --stack-name $2 --template-body file://ebsperfv6.yml --parameters ParameterKey=EBSDashboardName,ParameterValue=$2 ParameterKey=EBSVolumeId,ParameterValue=$1 ParameterKey=EBSVolumeMaxBW,ParameterValue=$throughput ParameterKey=EBSVolumeMaxIOPs,ParameterValue=$iops ParameterKey=EBSAttached,ParameterValue=$instance ParameterKey=EBSVolumeSize,ParameterValue=$size --region $region



