# Terraform AWS Project

This repository contains the Terraform configuration files to provision an AWS architecture using ECS Fargate, FastAPI, autoscaling, and RDS MySQL. The deployment is managed using Terraform.

## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) 
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials
- An AWS account with necessary permissions
- To get set up, you can follow this tutorial: [Terraform AWS Setup by Hashicorp] (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build)

## Architecture

The architecture consists of the following components:
- **ECS Fargate**: For running the containerized FastAPI application.
- **RDS MySQL**: A managed relational database service.
- **Auto Scaling**: Automatically adjusts the number of ECS tasks based on the load.
- **VPC**: A virtual private cloud to host all resources securely.
- **ALB**: Application Load Balancer in front of the ECS cluster.

## Usage

1. **Clone the repository**:
    ```bash
    git clone https://github.com/EChantler/TerraformAwsFargateRestApi.git
    cd TerraformAwsFargateRestApi
    ```

2. **Initialize Terraform**:
    ```bash
    terraform init
    ```

3. **Apply the Terraform configuration**:
    ```bash
    terraform apply
    ```
4. **View the API SwaggerDocs**:
    Once completed, go the the url for SwaggerDocs printed in your terminal e.g. (ApplicationLoadBalancer-12345678.eu-west-1.elb.amazonaws.com/docs)

5. **Destroy the Terraform configuration**:
    ```bash
    terraform destroy
    ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.