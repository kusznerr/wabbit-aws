provider "aws"{
  profile = "default"
  region = "us-west-1"
}

resource "aws_key_pair" "example" {
  key_name = "example-key"
  public_key = "ssh public key"
}


resource "aws_security_group" "examplesg" {
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami = "ami-01ed306a12b7d1c96"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.examplesg.id}"]
  //key_name = "${aws_key_pair.example.id}"
  tags = {
    Name = "my-first-ec2-instance"
  }
}