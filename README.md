# NT548 LAB 1 - AWS Infrastructure Automation with Terraform & CloudFormation

**Bài tập thực hành Lab 1 NT548**: Triển khai tự động hạ tầng AWS với Terraform và CloudFormation.

Dự án này cung cấp các module tự động hóa hoàn toàn quá trình triển khai hạ tầng AWS, bao gồm VPC, Subnets, NAT Gateway, EC2 instances và Security Groups.

## Mục lục
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Yêu cầu](#yêu-cầu)
- [Cài đặt nhanh](#cài-đặt-nhanh)
- [Hướng dẫn chi tiết](#hướng-dẫn-chi-tiết)
- [Kiểm tra và test](#kiểm-tra-và-test)
- [Cấu trúc project](#cấu-trúc-project)
- [Yêu cầu đã hoàn thành](#yêu-cầu-đã-hoàn-thành)
- [Xử lý sự cố](#xử-lý-sự-cố)
- [Dọn dẹp](#dọn-dẹp)

## Kiến trúc hệ thống

### Sơ đồ tổng quan
```
┌──────────────────────────────────────────────┐
│  AWS Account                                 │
│  ┌────────────────────────────────────────┐  │
│  │ VPC (10.0.0.0/16)                      │  │
│  │ ┌──────────────┐  ┌──────────────────┐ │  │
│  │ │ Public RT    │  │ Private RT       │ │  │
│  │ │ (→IGW)       │  │ (→NAT Gateway)   │ │  │
│  │ └──────────────┘  └──────────────────┘ │  │
│  │       ↓                    ↓           │  │
│  │ ┌─────────────────┐  ┌──────────────┐  │  │
│  │ │ Public Subnet   │  │Private Subnet│  │  │
│  │ │ 10.0.1.0/24     │  │ 10.0.2.0/24  │  │  │
│  │ │                 │  │              │  │  │
│  │ │ ┌─────────────┐ │  │┌──────────┐  │  │  │
│  │ │ │Public EC2   │ │  ││Private   │  │  │  │
│  │ │ │(Web Server) │─┼──┼→EC2       │  │  │  │
│  │ │ │SSH port 22  │ │  ││(SSH only)   │  │  │
│  │ │ └─────────────┘ │  │└──────────┘  │  │  │
│  │ │                 │  │              │  │  │
│  │ └─────────────────┘  └──────────────┘  │  │
│  │        ↓                               │  │
│  │  Internet Gateway                      │  │
│  │        ↓                               │  │
│  └────────┼───────────────────────────────┘  │
│           ↓                                  │
│  NAT Gateway (Private Subnet access          │
│to Internet)                                  │
│           ↓                                  │
└──────────────────────────────────────────────┘
         ↓
    Internet
```

### Thành phần chi tiết

| Thành phần | CIDR Block | Mô tả |
|----------|-----------|-------|
| **VPC** | 10.0.0.0/16 | Virtual Private Cloud chứa toàn bộ hạ tầng |
| **Public Subnet** | 10.0.1.0/24 | Subnet công khai, kết nối trực tiếp với Internet |
| **Private Subnet** | 10.0.2.0/24 | Subnet riêng, kết nối Internet qua NAT Gateway |
| **Internet Gateway** | - | Cho phép Public Subnet giao tiếp với Internet |
| **NAT Gateway** | - | Cho phép Private Subnet giao tiếp Internet (outbound only) |
| **Public Route Table** | - | Định tuyến: 0.0.0.0/0 → IGW |
| **Private Route Table** | - | Định tuyến: 0.0.0.0/0 → NAT Gateway |
| **Default Security Group** | - | Security Group mặc định cho VPC |

### Security Groups

#### Public EC2 Security Group (Inbound)
| Protocol | Port | Source | Mô tả |
|----------|------|--------|-------|
| TCP | 22 | YOUR_IP/32 | SSH từ IP được phép |
| TCP | 80 | 0.0.0.0/0 | HTTP từ Internet |
| TCP | 443 | 0.0.0.0/0 | HTTPS từ Internet |

#### Private EC2 Security Group (Inbound)
| Protocol | Port | Source | Mô tả |
|----------|------|--------|-------|
| TCP | 22 | Public SG | SSH từ Public instance |
| TCP | 80 | Public SG | HTTP từ Public instance |
| TCP | 443 | Public SG | HTTPS từ Public instance |
| TCP | 8080 | Public SG | App port từ Public instance |

## Yêu cầu

### Bắt buộc
- **AWS Account** có quyền tạo VPC, EC2, NAT Gateway, Security Groups
- **AWS CLI** (v2): [https://aws.amazon.com/cli/](https://aws.amazon.com/cli/)
- **Terraform** (v1.0+): [https://www.terraform.io/downloads.html](https://www.terraform.io/downloads.html)
- **PowerShell** 5.1+ (Windows)

### Tùy chọn (cho SSH testing)
- **Git Bash** hoặc **OpenSSH** (Windows Features)
- **SSH Client**

### Kiểm tra cài đặt
```powershell
# Kiểm tra AWS CLI
aws --version
aws sts get-caller-identity  # Phải thành công

# Kiểm tra Terraform
terraform --version

# Kiểm tra PowerShell (phải >= 5.1)
$PSVersionTable.PSVersion
```

## Cài đặt nhanh

### Bước 1: Chuẩn bị

#### 1.1 Cài đặt công cụ
```powershell
# Kiểm tra AWS CLI
aws --version

# Cấu hình AWS credentials
aws configure
# Nhập: AWS Access Key ID, AWS Secret Access Key, Region (us-east-1), Output format (json)

# Kiểm tra Terraform
terraform --version
```

#### 1.2 Tạo AWS Key Pair
```powershell
# Tạo key pair mới (chỉ làm một lần)
aws ec2 create-key-pair --key-name nt548-keypair --query 'KeyMaterial' --output text > nt548-keypair.pem

# Hoặc sử dụng AWS Console để tạo key pair
# - Mở https://console.aws.amazon.com/ec2/
# - Chọn Key Pairs → Create key pair
# - Download .pem file
```

#### 1.3 Lấy IP Address của bạn
```powershell
# Phương pháp 1: Từ internet
(Invoke-WebRequest -Uri "https://ipinfo.io/ip").Content.Trim()
# Kết quả sẽ là: xxx.xxx.xxx.xxx

# Phương pháp 2: Xem IP local
ipconfig
```

**Lưu ý**: Ghi nhớ IP address này, bạn sẽ cần dùng nó ở bước tạo Terraform variables.

### Bước 2: Triển khai với Terraform

#### 2.1 Cách 1: Dùng Script tự động (Quick Start)
```powershell
# Chạy script từ thư mục gốc
.\quick-start.bat

# Script sẽ:
# 1. Kiểm tra prerequisite (AWS CLI, Terraform, credentials)
# 2. Hỏi bạn chọn Terraform hoặc CloudFormation
# 3. Tự động cấu hình và triển khai
```

#### 2.2 Cách 2: Triển khai thủ công
```powershell
# Bước 1: Vào thư mục terraform
cd terraform

# Bước 2: Sao chép file example
Copy-Item terraform.tfvars.example terraform.tfvars

# Bước 3: Chỉnh sửa terraform.tfvars
notepad terraform.tfvars
# Sửa:
#   - allowed_ssh_ip = "YOUR_IP_ADDRESS/32"  (IP của bạn từ bước 1.3)
#   - key_pair_name = "nt548-keypair"        (tên key pair từ bước 1.2)

# Bước 4: Kiểm tra variables
terraform validate

# Bước 5: Dự tính chi phí
terraform plan

# Bước 6: Triển khai
terraform apply
# Nhập "yes" khi được hỏi

# Bước 7: Lấy outputs
terraform output
```

### Bước 3: Triển khai với CloudFormation

#### 3.1 Chỉnh sửa Parameters
```powershell
# Mở file parameters
notepad cloudformation/parameters/dev.json

# Sửa các giá trị:
# - "ParameterValue": "YOUR_IP_ADDRESS/32"  (SSH allowed IP)
# - "ParameterValue": "nt548-keypair"       (tên key pair)
# - "ParameterValue": "us-east-1a"          (availability zone)
```

#### 3.2 Triển khai
```powershell
# Cách 1: Dùng script PowerShell
.\scripts\deploy-cloudformation.ps1

# Cách 2: Dùng AWS CLI trực tiếp
aws cloudformation create-stack `
  --stack-name nt548-infrastructure `
  --template-body file://cloudformation/templates/main.yaml `
  --parameters file://cloudformation/parameters/dev.json `
  --capabilities CAPABILITY_NAMED_IAM
```

## Kiểm tra và test

### 4.1 Chạy Test Suite
```powershell
# Vào thư mục tests
cd tests

# Chạy toàn bộ tests cho infrastructure
.\run-tests.ps1

# Script sẽ kiểm tra:
# ✅ VPC tồn tại và có trạng thái "available"
# ✅ Public subnet tồn tại
# ✅ Private subnet tồn tại
# ✅ Internet Gateway kết nối
# ✅ NAT Gateway hoạt động
# ✅ Route tables được tạo đúng
# ✅ Default Security Group tồn tại
# ✅ Security Group rules chính xác
# ✅ EC2 instances chạy
```

### 4.2 Kiểm tra Connectivity
```powershell
# Kiểm tra HTTP connectivity
.\test-connectivity.ps1

# Script sẽ kiểm tra:
# ✅ HTTP truy cập được Public EC2 (port 80)
# ✅ SSH port (22) mở
# ✅ SSH connectivity (nếu SSH_KEY_PATH được set)
# ✅ Network ping connectivity
```

### 4.3 Kiểm tra chi tiết từng service

```powershell
# Kiểm tra VPC
aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name`].Value|[0]==`NT548-VPC`]'

# Kiểm tra Subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx" --query 'Subnets[*].[SubnetId,CidrBlock,Tags[?Key==`Name`].Value|[0]]'

# Kiểm tra Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-xxxxx"

# Kiểm tra NAT Gateway
aws ec2 describe-nat-gateways --filters "Name=vpc-id,Values=vpc-xxxxx"

# Kiểm tra EC2 instances
aws ec2 describe-instances --filters "Name=vpc-id,Values=vpc-xxxxx" --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]'

# Kiểm tra Security Groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-xxxxx" --query 'SecurityGroups[*].[GroupId,GroupName,Tags[?Key==`Name`].Value|[0]]'
```

### 4.4 Truy cập EC2 Instances

#### Từ máy tính của bạn:
```powershell
# SSH đến Public EC2 (cần OpenSSH hoặc Git Bash)
ssh -i "path/to/nt548-keypair.pem" ec2-user@PUBLIC_EC2_IP

# Xem web page
curl http://PUBLIC_EC2_IP
# Hoặc mở trong browser: http://PUBLIC_EC2_IP
```

#### Từ Public EC2 đến Private EC2:
```powershell
# Trước tiên, copy private key đến public instance
scp -i "path/to/nt548-keypair.pem" "path/to/nt548-keypair.pem" ec2-user@PUBLIC_EC2_IP:~/.ssh/

# SSH đến public instance
ssh -i "path/to/nt548-keypair.pem" ec2-user@PUBLIC_EC2_IP

# Từ public instance, SSH đến private instance
ssh -i ~/.ssh/nt548-keypair.pem ec2-user@PRIVATE_EC2_IP

# Xem web page trên private instance
curl http://PRIVATE_EC2_IP
```

### 4.5 Xem Terraform Outputs
```powershell
# Tất cả outputs
terraform output

# Output cụ thể
terraform output vpc_id
terraform output public_ec2_ip
terraform output private_ec2_ip
terraform output public_security_group_id
terraform output private_security_group_id

# Format JSON
terraform output -json
```

### 4.6 Xem CloudFormation Outputs
```powershell
# Lấy stack name
$StackName = "nt548-infrastructure"

# Xem outputs
aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[0].Outputs'
```

## Cấu trúc project

```
LAB1_NT548/
├── terraform/
│   ├── main.tf                 # Khai báo modules
│   ├── variables.tf            # Variables chính
│   ├── outputs.tf              # Outputs chính
│   ├── terraform.tfvars.example # Example variables
│   └── modules/
│       ├── vpc/
│       │   ├── main.tf         # VPC, Subnets, IGW, NAT, Routes
│       │   ├── variables.tf    # VPC variables
│       │   └── outputs.tf      # VPC outputs
│       ├── security-groups/
│       │   ├── main.tf         # Security Groups cho Public/Private
│       │   ├── variables.tf    # SG variables
│       │   └── outputs.tf      # SG outputs
│       └── ec2/
│           ├── main.tf         # EC2 instances (Public + Private)
│           ├── variables.tf    # EC2 variables
│           └── outputs.tf      # EC2 outputs
├── cloudformation/
│   ├── templates/
│   │   └── main.yaml           # CloudFormation template đầy đủ
│   └── parameters/
│       └── dev.json            # CloudFormation parameters
├── scripts/
│   ├── deploy-terraform.ps1    # Script triển khai Terraform
│   └── deploy-cloudformation.ps1 # Script triển khai CloudFormation
├── tests/
│   ├── run-tests.ps1           # Test suites (VPC, SG, EC2, etc.)
│   └── test-connectivity.ps1   # HTTP/SSH connectivity tests
├── quick-start.bat             # One-click deployment script
└── README.md                   # Hướng dẫn này
```

## Yêu cầu đã hoàn thành

### VPC Module (3 điểm)
- ✅ Subnets: Public (10.0.1.0/24) + Private (10.0.2.0/24)
- ✅ Internet Gateway: Kết nối Public Subnet với Internet
- ✅ Default Security Group: Được tạo cho VPC

### Route Tables (2 điểm)
- ✅ Public Route Table: Định tuyến 0.0.0.0/0 → Internet Gateway
- ✅ Private Route Table: Định tuyến 0.0.0.0/0 → NAT Gateway

### NAT Gateway (1 điểm)
- ✅ Được tạo trong Public Subnet
- ✅ Cho phép Private Subnet kết nối Internet (outbound)
- ✅ Elastic IP được cấp phát

### EC2 Instances (2 điểm)
- ✅ Public EC2: Trong Public Subnet, có Public IP
- ✅ Private EC2: Trong Private Subnet, chỉ có Private IP
- ✅ Web server chạy trên cả hai instances
- ✅ User data script cài đặt Apache

### Security Groups (2 điểm)
- ✅ Public SG: SSH từ IP cụ thể, HTTP/HTTPS mở
- ✅ Private SG: SSH/HTTP/HTTPS từ Public SG
- ✅ Outbound rules cho cả hai SG
- ✅ Default SG được quản lý

### Modules (Bắt buộc)
- ✅ VPC Module: `terraform/modules/vpc/`
- ✅ Security Groups Module: `terraform/modules/security-groups/`
- ✅ EC2 Module: `terraform/modules/ec2/`

### Test Cases (Bắt buộc)
- ✅ Infrastructure tests: `tests/run-tests.ps1`
- ✅ Connectivity tests: `tests/test-connectivity.ps1`

### Terraform & CloudFormation
- ✅ Terraform configuration hoàn chỉnh
- ✅ CloudFormation template hoàn chỉnh
- ✅ Deployment scripts
- ✅ Quick-start script

## Xử lý sự cố

### PowerShell Execution Policy
```powershell
# Cho phép chạy script
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Kiểm tra
Get-ExecutionPolicy
```

### AWS Credentials Issues
```powershell
# Kiểm tra credentials
aws sts get-caller-identity

# Cấu hình lại credentials
aws configure

# Hoặc dùng environment variables
$env:AWS_ACCESS_KEY_ID = "your-access-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret-key"
$env:AWS_DEFAULT_REGION = "us-east-1"
```

### Terraform State Issues
```powershell
# Xem state
terraform show

# Refresh state
terraform refresh

# Destroy and recreate
terraform destroy
terraform apply
```

### Test Failures
```powershell
# Kiểm tra AWS CLI configuration
aws ec2 describe-vpcs

# Kiểm tra Terraform outputs
cd terraform
terraform output

# Xem logs chi tiết
terraform apply -var-file="terraform.tfvars" -input=false -lock=false -detailed-exitcode
```

### SSH Connection Issues
```powershell
# Kiểm tra key permissions (Linux/Mac)
chmod 400 nt548-keypair.pem

# Kiểm tra security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx

# Test SSH connection
ssh -vvv -i "path/to/key.pem" ec2-user@PUBLIC_IP
```

### NAT Gateway Issues
```powershell
# Kiểm tra NAT Gateway status
aws ec2 describe-nat-gateways

# Kiểm tra Elastic IP
aws ec2 describe-addresses --filters "Name=domain,Values=vpc"

# Kiểm tra private route table
aws ec2 describe-route-tables --filters "Name=tag:Name,Values=NT548-Private-RT"
```

## Dọn dẹp

### Xóa tất cả resources

#### Cách 1: Terraform
```powershell
cd terraform

# Xem gì sẽ bị xóa
terraform plan -destroy

# Xóa tất cả
terraform destroy
# Nhập "yes" khi được hỏi

# Kiểm tra state
terraform state list  # Phải rỗng
```

#### Cách 2: CloudFormation
```powershell
# Xóa stack
aws cloudformation delete-stack --stack-name nt548-infrastructure

# Kiểm tra trạng thái
aws cloudformation describe-stacks --stack-name nt548-infrastructure --query 'Stacks[0].StackStatus'

# Đợi cho đến khi DELETE_COMPLETE
```

#### Cách 3: AWS Console
- Mở https://console.aws.amazon.com/ec2/ hoặc https://console.aws.amazon.com/cloudformation/
- Chọn resources và delete

### Cleanup checklist
- [ ] EC2 instances đã bị terminate
- [ ] NAT Gateway đã được xóa
- [ ] Elastic IP đã được release
- [ ] Internet Gateway đã được detach
- [ ] VPC đã được xóa
- [ ] Terraform state files đã được xóa

## Tài liệu tham khảo
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
