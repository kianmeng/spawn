defmodule Statestores.Types.HMAC do
  use Cloak.Ecto.HMAC, otp_app: :statestores

  def init(_config) do
    {:ok,
     [
       algorithm: :sha512,
       secret: decode_env!("SPAWN_STATESTORE_KEY")
     ]}
  end

  defp decode_env!(var) do
    var
    |> System.get_env()
    |> Base.decode64!()
  end
end
