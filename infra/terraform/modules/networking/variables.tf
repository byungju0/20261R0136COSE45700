# 학생 계정 PIVOT — 본 모듈은 Default VPC를 data source로 lookup만 수행하고
# 신규 자원을 만들지 않음. 따라서 입력 변수 0개 (region은 provider config에서
# 자동 사용, tags는 자원 생성 X로 불필요).
#
# 졸업 후 production 환경에서 custom VPC + Flow Logs + S3 endpoint 자원을 복원할
# 때 다음 변수 정의도 git history에서 함께 복원:
#   variable "region" / "tags" / "vpc_cidr" / "availability_zones" /
#   "public_subnet_cidrs" / "private_subnet_cidrs" / "nat_strategy"
