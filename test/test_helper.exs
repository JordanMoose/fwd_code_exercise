Mox.defmock(FwdCodeExercise.PubSubMock, for: FwdCodeExercise.PubSubClient)
Mox.defmock(FwdCodeExercise.HttpClientMock, for: FwdCodeExercise.HttpClient)

Application.put_env(:fwd_code_exercise, :pubsub_client, FwdCodeExercise.PubSubMock)
Application.put_env(:fwd_code_exercise, :http_client, FwdCodeExercise.HttpClientMock)

ExUnit.start(capture_log: true)
