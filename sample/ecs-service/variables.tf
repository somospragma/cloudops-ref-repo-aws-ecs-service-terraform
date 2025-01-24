###########################################
########## Common variables ###############
###########################################

variable "profile" {
  type = string
  description = "Profile name containing the access credentials to deploy the infrastructure on AWS"
}

variable "common_tags" {
    type = map(string)
    description = "Common tags to be applied to the resources"
}

variable "aws_region" {
  type = string
  description = "AWS region where resources will be deployed"
}

variable "environment" {
  type = string
  description = "Environment where resources will be deployed"
}

variable "client" {
  type = string
  description = "Client name"
}

variable "project" {
  type = string  
    description = "Project name"
}

variable "application" {
  type = string  
  description = "Application name"
}

variable "functionality" {
  type = string  
  description = "Functionality name"
}

###########################################
############ ALB variables ################
###########################################

variable "port" {
  type = number
  description = "Port number"
}

###########################################
######## ECS service variables ############
###########################################

variable "memory" {
  type = number
  description = "Memory value"
}

variable "cpu" {
  type = number
  description = "CPU value"
}

variable "url_image_respository" {
  type = string
  description = "ARN Image respository"
}