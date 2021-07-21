variable "client_name" {
  type = string
  description = "NEWCLIENT"
}
variable "this_location"  {
  type = string
  description = "Location under region Azure"
}
variable "resource_group" {
  type = string
  description = "RG"
}
variable "enviroment" {
  type = string
  description = "Enviroment"
}
variable "network" {
  type = string
  description = "Private Network"
}
variable "subnet" {
  type = string
  description = "Subnet we can use"
}
variable "dns1" {
  type = string
  description = "First DNS"
}
variable "dns2" {
  type = string
  description = "Second DNS"
}  
variable "win_admin" {
  type = string
  description = "Add admin user from Win Server"
}
variable "win_password" {
  type = string
  description = "Add admin password from Win Server"
}
variable "win_privateip" {
  type = string
  description = "Add local IP address from Win Server"
}
variable "lb_probe" {
  type = map(object({
    name                = string
    protocol            = string
    port                = number
    interval_in_seconds = number
    number_of_probes    = number
  }))
}
variable "admin_sql_pass" {
  type = string
  description = "Password from SQL Server" 
}
variable "admin_sql_user" {
  type = string
  description = "User from SQL Server" 
}
variable "databases"  {
  type = map(object({
    name                = string
  }))
}
