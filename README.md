# devops_terraform_ip
terraform code to provision nginx webserver on ec2 instances
it uses best practices, including Performance Efficiency, Reliability and high availability
security groups allow inbound traffic only to alb on 80 port which distributes traffic across ec2 instances
ec2 instances are part of asg which based on cpu utilization scale up/down instances
vpc consists of multi az subnets 

**next step, transformation to structure**  
devops_terraform_ip  
│-- modules/

│   ├── vpc/

│   │   ├── main.tf

│   │   ├── variables.tf

│   │   ├── outputs.tf

│   ├── alb/

│   │   ├── main.tf

│   │   ├── variables.tf

│   │   ├── outputs.tf
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   ├── sg/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   ├── s3/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│-- main.tf
│-- README.md
