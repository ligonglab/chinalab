terraform {
  required_version = ">= 1.5.0"
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.81.0"
    }
  }
}

# 텐센트 클라우드 Provider (환경 변수로 SecretId, SecretKey 자동 주입)
provider "tencentcloud" {
  region = var.target_region
}

# 1. 중국 VPC 및 서브넷
resource "tencentcloud_vpc" "china_vpc" {
  name       = "hq-managed-beijing-vpc"
  cidr_block = "10.0.0.0/16"
}

resource "tencentcloud_subnet" "china_subnet" {
  vpc_id            = tencentcloud_vpc.china_vpc.id
  name              = "hq-managed-beijing-subnet"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-beijing-3"
}

# 2. [중국 규제 준수] COS 버킷 생성 (저장 데이터 AES256 서버 암호화 적용)
resource "tencentcloud_cos_bucket" "compliance_storage" {
  # 텐센트 버킷명 규칙: {name}-{appid}
  bucket               = "hq-audit-storage-${var.tencent_appid}"
  acl                  = "private"
  encryption_algorithm = "AES256"
}

# 3. [보안/정책 검증 테스트용 보안그룹]
resource "tencentcloud_security_group" "china_bastion_sg" {
  name        = "china-bastion-sg"
  description = "Managed Bastion Security Group"
}

# 🚨 1차 테스트: cidr_ip를 "0.0.0.0/0"으로 두어 차단되는지 확인합니다.
# 🛡️ 2차 테스트: 차단 확인 후 "10.0.0.0/16"으로 변경하여 배포합니다.
resource "tencentcloud_security_group_rule" "ingress_ssh" {
  security_group_id = tencentcloud_security_group.china_bastion_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "tcp"
  port_range        = "22"
  policy            = "accept"
  description       = "SSH Ingress rule"
}