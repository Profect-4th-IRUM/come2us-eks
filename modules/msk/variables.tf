variable "cluster_name" {}
variable "kafka_version" {}
variable "number_of_broker_nodes" { type = number }
variable "instance_type" {}
variable "client_subnets" { type = list(string) } 
variable "security_groups" { type = list(string) } 
variable "volume_size" { type = number }