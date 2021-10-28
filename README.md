# EBS IOPs performance Cloudwatch dashboard 
This cloudformation template takes the four inputs and creates a dashboard for 1 EBS Volume.
![AWS Console](EBSDash_Dashboard.png)

### Inputs
- Dashboard Name
- EBS Volume ID (Either provide the VolumeID explicitly or from the dropdown select the VolumeID)
- Provisioned IOPS or calculated IOPS for GP2 (for GP2 it will be 3 IOP per GB or storage. i.e. 1TB volume will have 3000 IOPS max. For GP3 or IO2 this number is configured with the volume)
- Max Throughput for the Volume (125MB/s for 170GB GP2 or smaller Volumes and 250MB/s for larger. For GP3 or IO2 this is set with the volume provisioning. see [Table](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html#solid-state-drives))


Download the Cloudformation [template](https://raw.githubusercontent.com/geseib/ebscwdash/master/ebsperfv4.yml) **right click and save locally** and launch it using the following aws-cli (if not already installed, requires [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)):

```
aws cloudformation create-stack --stack-name myEBSIOPSDashboard --template-body file://ebsperfv4.yml --parameters ParameterKey=EBSDashboardName,ParameterValue=EBSDashboard ParameterKey=EBSVolumeID,ParameterValue=vol-123456789abcdefg ParameterKey=EBSVolumeMaxBW,ParameterValue=250 ParameterKey=EBSVolumeMaxIOPs,ParameterValue=3000
```
or run from the [AWS Console](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/template), click **Upload a template file**, and click **Choose file**, choose the YAML file you downloaded above. 

![AWS Console](EBSDash_Parameters.png)

After a minute, you can select the URL from the Outputs tab in the Cloudformation console, or go to the Cloudwatch console and select your new dashboard.

## About the Metrics
In order to get accurate reading we need to grab a few EBS metrics and use the **metric math** feature in **Amazon Cloudwatch**. We will setup two graphs; one for the IOPs and one for the Throughput. 

### EBS IOPs Graph
![EBS Throughput Graph](EBSDash_ThroughputGraph.png)

We will need to calculate the IOPs from the Ops metrics as below.

![EBS Throughput Metrics](EBSDash_ThroughputMetrics.png)

| Visible | **id** | **Label**      | **Details**                                   | **Statistic** | **Period** |
|---------|--------|----------------|-----------------------------------------------|---------------|------------|
|    *    | e1     | Read IOPs      | m1/PERIOD(m1)                                 |               |            |
|    *    | e2     | Write IOPs     | m2/PERIOD(m2)                                 |               |            |
|    *    | e3     | Total IOPs     | e1+e2                                         |               |            |
|         | m1     | VolumeReadOps  | EBS.VolumeReadOps.VolumeId:vol-xxxxxxxxxxxxx  | Sum           | 1 Minute   |
|         | m2     | VolumeWriteOps | EBS.VolumeWriteOps.VolumeId:vol-xxxxxxxxxxxxx | Sum           | 1 Minute   |

Here is the source code for **EBS Volume IOPs** *(be sure to replace **vol-xxxxxxxxxxxxxx** with the VolumeId of your EBS volume)*
```
{
    "metrics": [
        [ { "expression": "m1/PERIOD(m1)", "label": "Read IOPs", "id": "e1", "region": "us-east-1" } ],
        [ { "expression": "m2/PERIOD(m2)", "label": "Writes IOPs", "id": "e2", "region": "us-east-1" } ],
        [ { "expression": "e1+e2", "label": "Total IOPs", "id": "e3", "region": "us-east-1" } ],
        [ "AWS/EBS", "VolumeReadOps", "VolumeId", "vol-xxxxxxxxxxxxxx", { "id": "m1", "visible": false } ],
        [ ".", "VolumeWriteOps", ".", ".", { "id": "m2", "visible": false } ]
    ],
    "view": "timeSeries",
    "stacked": false,
    "region": "us-east-1",
    "stat": "Sum",
    "period": 60,
    "yAxis": {
        "left": {
            "label": "IOPS",
            "showUnits": false
        },
        "right": {
            "label": "",
            "showUnits": false
        }
    },
    "annotations": {
        "horizontal": [
            {
                "label": "IOPs Max",
                "value": 7800
            }
        ]
    },
    "title": "EBS IOPS"
}
```


## EBS Throughput Graph
![EBS Throughput Graph](EBSDash_ThroughputGraph.png)

We will need to calculate the Throughput from the Ops metrics as below.
![EBS Throughput Metrics](EBSDash_ThroughputMetrics.png)

| Visible | Id | Label               | Details                                      | Statistic | **Period** |
|---------|----|---------------------|----------------------------------------------|-----------|------------|
| *       | e4 | MB Read Per Second  | (m3/(1024*1024))/PERIOD(m3)                  |           |            |
| *       | e5 | MB Write Per Second | (m3/(1024*1024))/PERIOD(m3)                  |           |            |
| *       | e6 | Total Throughput    | e4+e5                                        |           |            |
|         | m3 | VolumeReadBytes     | EBS.VolumeReadBytes:VolumeId:volxxxxxxxxxxx  | Sum       | 1 Minute   |
|         | m4 | VolumeWriteBytes    | EBS.VolumeWriteBytes:VolumeId:volxxxxxxxxxxx | Sum       | 1 Minute   |

Here is the source code for **EBS Volume Throughput** *(be sure to replace **vol-xxxxxxxxxxxxxx** with the VolumeId of your EBS volume)*
```
{
    "metrics": [
        [ { "expression": "(m3/(1024*1024))/PERIOD(m3)", "label": "MB Read Per Second", "id": "e4", "region": "us-east-1" } ],
        [ { "expression": "(m4/(1024*1024))/PERIOD(m4)", "label": "MB Write Per Second", "id": "e5", "region": "us-east-1" } ],
        [ { "expression": "e4+e5", "label": "Total Consumed MB/s", "id": "e6", "region": "us-east-1" } ],
        [ "AWS/EBS", "VolumeReadBytes", "VolumeId", "vol-0a2ddbf3ee34e7d2a", { "id": "m3", "visible": false } ],
        [ ".", "VolumeWriteBytes", ".", ".", { "id": "m4", "visible": false } ]
    ],
    "view": "timeSeries",
    "stacked": false,
    "region": "us-east-1",
    "stat": "Sum",
    "period": 60,
    "yAxis": {
        "left": {
            "label": "MB/s",
            "showUnits": false
        },
        "right": {
            "label": "",
            "showUnits": false
        }
    },
    "annotations": {
        "horizontal": [
            {
                "label": "BW Max",
                "value": 250
            }
        ]
    },
    "title": "EBS MB per Second"
}
```
