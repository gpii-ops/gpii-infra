task :configure_kops do
  ENV["S3_BUCKET"] = "gpii-kubernetes-state"
  ENV["KOPS_STATE_STORE"] = "s3://#{ENV['S3_BUCKET']}"
end
