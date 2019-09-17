resource "aws_instance" "ec2_public" {
  ami           = "ami-00b2d3ea9077fcebf" # ap-south-1
  instance_type = "t2.micro"
  key_name		= "AWS_Green"
  subnet_id		= "subnet-042260b8038c360ae"
  vpc_security_group_ids = ["sg-0e8cb204ccedd3c4e"]
  associate_public_ip_address = true
  source_dest_check = false
  tags = {
    Name = "terraform_ec2_pub"
  }
}