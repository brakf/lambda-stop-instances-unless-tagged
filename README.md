# AWS Lambda EC2 Shutdown Manager

This project contains a Python AWS Lambda function to stop EC2 instances that do not have a specific tag. It also includes Terraform configuration files to deploy the Lambda function and schedule it to run daily.


## Python Lambda Function

The Python script `lambda_function.py` contains a Lambda function that stops any EC2 instances without a tag `DoNotShutDown` set to `true`. 

## Terraform Configuration

The Terraform configuration files in this directory will:

1. Package the Python script into a .zip file.
2. Create an IAM role for the Lambda function with the basic Lambda execution policy.
3. Create an IAM policy that allows `ec2:DescribeInstances` and `ec2:StopInstances` actions and attach it to the IAM role.
4. Create the Lambda function with the specified role and the .zip file as the code.
5. Create a CloudWatch Events rule to trigger the Lambda function daily at 7 PM UTC.
6. Associate the Lambda function with the CloudWatch Events rule.

Remember to replace `'DoNotShutDown'` and `'true'` in the Python script with your desired tag key and value, if different.

## Warning

This function has the potential to stop a large number of instances. Test thoroughly before deploying in a production environment, and use with caution.