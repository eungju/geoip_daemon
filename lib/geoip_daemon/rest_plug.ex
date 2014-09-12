defmodule GeoipDaemon.RestPlug do
  import Plug.Conn
  use Plug.Router

  use Jazz

  plug :match
  plug :dispatch
  if Mix.env == :dev do
    plug PlugCodeReloader.Plug
  end

  def send_404(conn) do
    send_resp(conn, 404, "Not found.")
  end

  get "/databases/country" do
    conn = conn |> fetch_params
    #bad request if the ip parameter is not given.
    ip = Map.fetch!(conn.params, "ip")
    #bad request if the ip is invalid.
    {:ok, ip_address} = :inet.parse_address(to_char_list(ip))
    #not found if the record is nil
    case Geolix.country(ip_address) do
      nil ->
        send_404(conn)
      record ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, JSON.encode!(record))
    end
  end

  match _ do
    send_404(conn)
  end
end
