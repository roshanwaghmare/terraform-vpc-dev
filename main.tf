resource "aws_vpc" "custom_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
      name = "yt-vpc"
    }
  
}

//subnets

variable "vpc_availability_zones" {
type = list(string)
description = "availability zones for subnets"
default = [ "us-east-1a" , "us-east-1b" ]
  
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.custom_vpc.id
    count = length(var.vpc_availability_zones)
    cidr_block = cidrsubnet(aws_vpc.custom_vpc.cidr_block, 8 , count.index+1)
    availability_zone = element(var.vpc_availability_zones, count.index)

    tags = {
      name = "yt public subnet ${count.index+1}"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.custom_vpc.id
    count = length(var.vpc_availability_zones)
    cidr_block = cidrsubnet(aws_vpc.custom_vpc.cidr_block, 8 , count.index+3)
    availability_zone = element(var.vpc_availability_zones, count.index)

    tags = {
      name = "yt private subnet ${count.index+1}"
    }
}

/*
FOR Example : 10.0.0.0/16
cidersubnet(10.0.0.0/16, 8 , 0+1) => 10.0.1.0/24
cidersubnet(10.0.0.0/16, 8 , 1+1) => 10.0.2.0/24
cidersubnet(10.0.0.0/16, 8 , 3+1) => 10.0.2.0/24 check 


/16 + 8 = /24


element block
element means taking value from variable for first element like
default = [ "us-east-1a" , "us-east-1b" ] 
first element us-east-1a
secound element us-east-1b 

    count = length(var.vpc_availability_zones)
which ever zones defined that will be added 
*/


resource "aws_internet_gateway" "igw_vpc" {
    vpc_id = aws_vpc.custom_vpc.id

    tags = {
      name = "yt-igw"
    }
  
}

resource "aws_route_table" "yt_rt_public_subnet" {
  vpc_id = aws_vpc.custom_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc.id
  }

    tags = {
      name = "public subnet rt"
    }
}


resource "aws_route_table_association" "pub_rt_as" {
  route_table_id = aws_route_table.yt_rt_public_subnet.id
  count = length(var.vpc_availability_zones)
  subnet_id = element(aws_subnet.public_subnet[*].id,count.index)

}

resource "aws_eip" "eip" {
    domain = "vpc"
  depends_on = [ aws_internet_gateway.igw_vpc ]
}

resource "aws_nat_gateway" "yt-nat" {
  subnet_id = element(aws_subnet.private_subnet[*].id, 0) # since i want nat in only one subnet 
  allocation_id = "aws_eip.eip.id"
  depends_on = [ aws_internet_gateway.igw_vpc]

  tags = {
    name = "yt-nat-gateway"
  }

}


resource "aws_route_table" "yt_rt_private_subnet" {
  vpc_id = aws_vpc.custom_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.yt-nat.id
  }

    tags = {
      name = "private subnet rt"
    }
}

resource "aws_route_table_association" "pri_rt_as" {
  route_table_id = aws_route_table.yt_rt_private_subnet.id
  count = length(var.vpc_availability_zones)
  subnet_id = element(aws_subnet.private_subnet[*].id,count.index)

}

