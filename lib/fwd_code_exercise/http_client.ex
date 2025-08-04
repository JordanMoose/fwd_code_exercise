defmodule FwdCodeExercise.HttpClient do
  @moduledoc """
  Behaviour for the Req HTTP client.
  """

  @callback get(binary(), keyword()) :: {:ok, Req.Response.t()} | {:error, any()}

  @spec impl() :: module()
  def impl() do
    Application.get_env(:fwd_code_exercise, :http_client, Req)
  end

  @doc """
  Makes a GET request to the specified URL with the given options.

  ## Parameters
  - `url`: The URL to send the GET request to.
  - `opts`: A keyword list of options to pass to the request, such as query parameters.

  ## Returns
  - `{:ok, response}`: The response from the server.
  - `{:error, reason}`: If the request fails.
  """
  @spec get(binary(), keyword()) :: {:ok, Req.Response.t()} | {:error, any()}
  def get(url, opts \\ []), do: impl().get(url, opts)
end
