output "private-subnet-group-name" {
    value = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
}

output "vpc_id" {
    value = aws_vpc.main.id
}

output "public-subnet-group-name" {
    value = "${aws_subnet.public_subnet.*.id}"
}