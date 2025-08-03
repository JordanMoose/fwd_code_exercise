import Config

config :logger, :default_formatter,
  format: "$time [$level] [$metadata] $message\n",
  handle_otp_reports: true,
  handle_sasl_reports: true,
  metadata: [:module, :function]
