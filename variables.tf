variable "container_image_url" {
  description = "The url for your public container image"
  type        = string
  default     = "public.ecr.aws/j4x1k7z4/restfastapi:latest"
}

variable "cpu_scaling_threshold"{
    description = "Autoscaling percentage CPU threshold"
    type = number
    default = 67.5
}
