import boto3
import logging

# Setup simple logging for INFO
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Define the connection
    ec2 = boto3.resource('ec2')

    # Get all regions
    regions = [region['RegionName'] for region in boto3.client('ec2').describe_regions()['Regions']]

    # Iterate over each region
    for region in regions:
        ec2 = boto3.resource('ec2', region_name=region)

        # Get all instances that are running
        instances = ec2.instances.filter(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

        for instance in instances:
            # Assume that we should shut down the instance until we find our tag
            shutdown = True
            # Check tags, if they exist
            if instance.tags is not None:
                for tag in instance.tags:
                    # If our tag exists, don't shut down
                    if tag['Key'] == 'DoNotShutDown' and tag['Value'].lower() == 'true':
                        shutdown = False
                        break
            # If we didn't find our tag, shut down the instance
            if shutdown:
                logger.info(f'Shutting down instance: {instance.id}')
                instance.stop()
