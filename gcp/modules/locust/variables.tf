variable "locust_script" {
  default = "preferences.py"
}

variable "locust_target_host" {
  default = ""
}

variable "locust_swarm_duration" {
  default = 60
}

variable "locust_workers" {
  default = 3
}

variable "locust_users" {
  default = 100
}

variable "locust_hatch_rate" {
  default = 10
}

variable "locust_desired_total_rps" {
  default = 40
}

variable "locust_desired_median_response_time" {
  default = 100
}

variable "locust_desired_max_response_time" {
  default = 800
}

variable "locust_desired_num_failures" {
  default = 0
}
