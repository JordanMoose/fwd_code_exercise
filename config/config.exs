import Config

config :logger, :default_formatter,
  format: "$time [$level] [$metadata] $message\n",
  handle_otp_reports: true,
  handle_sasl_reports: true,
  metadata: [:module, :function]

config :fwd_code_exercise,
  websocket_url: "ws://localhost:4000/",
  incidents_endpoint: "https://services.arcgis.com/your_service_id/arcgis/rest/services/your_service_name/FeatureServer/0/query",
  poll_interval: :timer.seconds(60),
  output_file: "wildfire_data.json"
