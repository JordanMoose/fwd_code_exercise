import Config

config :logger, :default_formatter,
  format: "$time [$level] [$metadata] $message\n",
  handle_otp_reports: true,
  handle_sasl_reports: true,
  metadata: [:module, :function]

config :fwd_code_exercise,
  websocket_url: "ws://localhost:4000/",
  incidents_endpoint: "https://services9.arcgis.com/RHVPKKiFTONKtxq3/ArcGIS/rest/services/USA_Wildfires_v1/FeatureServer/0/query",
  poll_interval: :timer.minutes(15),
  output_filepath: "wildfire_updates/wildfire_data"
