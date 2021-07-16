# Readme
### Variables to customise client.
'Need edit the files "vars.tf" and "Prod.tfvars"'

## Powershell
### az login
'Login Azure'
### az account set --subscription="SUBSCRIPTION_ID"
'Select SUBSCRIPTION_ID'
### az account list -o table
'Verify select SUBSCRIPTION_ID'
### New-Item -Path "c:/folder/main.tf" -Name "learn-terraform-azure" -ItemType "directory"
'Folder where you will look for the configuration'

## Terraform
### terraform init 	
'Start service terraform'
### terraform plan 	
'Review plan from terraform maked in, and show we change "main.tf"'
### terraform aply
'Apply change like showed plan in "main.tf"'
### terraform show
'Show the changes and state from infrastructure maked from terraform'

## To runn plan     
### terraform plan -var-file .\Prod.tfvars
'Run the plan'
