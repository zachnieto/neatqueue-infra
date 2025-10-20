# Terraform Backend Bootstrap

This configuration creates the AWS resources needed for remote Terraform state storage:
- S3 bucket for state files (with versioning and encryption enabled)
- DynamoDB table for state locking

## Usage

1. Initialize and apply this configuration first:
   ```powershell
   cd backend-bootstrap
   terraform init
   terraform apply
   ```

2. Note the output values - you'll need them to configure the backend in your main Terraform configuration.

3. After the resources are created, update your main `providers.tf` with the backend configuration shown in the output.

4. Migrate your existing state to the remote backend:
   ```powershell
   cd ..\ecs
   terraform init -migrate-state
   ```

## Important Notes

- This bootstrap configuration uses local state (by design)
- The S3 bucket has `prevent_destroy = true` to protect your state
- State versioning is enabled for rollback capabilities
- The DynamoDB table uses on-demand billing to minimize costs
