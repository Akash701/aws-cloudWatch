# AWS Terraform Projects: Cloud Monitoring & Cost Estimation

This repository contains my Terraform projects showcasing **AWS Cloud infrastructure automation**, including CloudWatch log monitoring, alerts, and cost estimation with AWS Budgets.  

## ✅ Features

- **Refactor Terraform into reusable modules**
  - Organized resources into modules for scalability and maintainability.
- **Add tags, dependencies, and outputs**
  - Enables better resource management and outputs for automation.
- **Monitor application logs via AWS CloudWatch**
  - Created Log Groups, Log Streams, Metric Filters.
- **Set up basic alerts (email/SMS)**
  - CloudWatch alarms trigger SNS notifications for errors.
- **Explore cost estimations**
  - Automated cost tracking with AWS Budgets and Terraform Cloud integration.

## 🛠 Technologies

- Terraform
- AWS CloudWatch
- AWS SNS
- AWS IAM
- AWS Budgets

## 📌 How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/Akash701/aws-cloudWatch
2. Initialize Terraform:
   terraform init

3. Apply the configuration
   terraform apply
