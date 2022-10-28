variable "region" {
    description = "AWS region"
    default = "eu-north-1"
}

variable "input_bucket_name" {
    description = "Input bucket name which contains videos to be transcoded."
    default = "scoo-video-upload"
    type = string
}

variable "output_bucket_name" {
    description = "Output bucket name which contains videos after transcoding."
    default = "video.emill.fi"
    type = string
}

variable "bucket_event_prefix" {
    description = "Element prefix to trigger lambda function."
    default = "input/"
}

variable "bucket_event_suffix" {
    description = "Element suffix to trigger lambda function."
    default = "*"
}

variable "project_base_name" {
    description = "Project name."
    default = "scoo-video"
}

variable "lambda_zip_path" {
    description = "Path to lambda function and configuration zip."
    default = "./mediaconvert_lambda.zip"
}

variable "speke_server_url" {
    description = "For future versions."
    default = ""
}

variable "speke_system_id" {
    description = "For future versions."
    default = ""
}

variable "mediaconvert_endpoint" {
    description = "AWS Element MediaConvert API endpoint."
    default = "https://gnwesle3b.mediaconvert.eu-north-1.amazonaws.com"
}