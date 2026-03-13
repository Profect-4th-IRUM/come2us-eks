# Public subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.prefix}-public-a"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = var.azs[1]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.prefix}-public-b"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = var.azs[0]

  tags = {
    Name                              = "${var.prefix}-private-a"
    Tier                              = "private"
    "karpenter.sh/discovery"          = "${var.prefix}-eks"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = var.azs[1]

  tags = {
    Name                              = "${var.prefix}-private-b"
    Tier                              = "private"
    "karpenter.sh/discovery"          = "${var.prefix}-eks"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "db_private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_subnet_cidrs[0]
  availability_zone = var.azs[0]

  tags = {
    Name = "${var.prefix}-db-private-a"
    Tier = "db"
  }
}

resource "aws_subnet" "db_private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_subnet_cidrs[1]
  availability_zone = var.azs[1]

  tags = {
    Name = "${var.prefix}-db-private-b"
    Tier = "db"
  }
}
