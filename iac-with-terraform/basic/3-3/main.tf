resource "local_file" "abc" {
  content  = "123!"
  filename = "${path.module}/abc.txt"
}

data "local_file" "abc" {
  filename = local_file.abc.filename
}

resource "local_file" "def" {
  content  = data.local_file.abc.content
  filename = "${path.module}/def.txt"
}

# resource "aws_instance" "web" {
#   ami           = "ami-a1b2c3d4"
#   instance_type = "t2.micro"
# }
