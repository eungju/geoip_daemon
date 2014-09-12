defmodule GeoipDaemon.RestPlug do
  import Plug.Conn
  use Plug.Router

  alias Poison, as: JSON

  plug :match
  plug :dispatch
  if Mix.env == :dev do
    plug PlugCodeReloader.Plug
  end

  def send_400(conn) do
    send_resp(conn, 400, "Bad request.")
  end

  def send_404(conn) do
    send_resp(conn, 404, "Not found.")
  end

  get "/databases/:db/:ip" do
    conn = conn |> fetch_params
    lookup_record = case db do
                      "country" -> &Geolix.country/1
                      "city" -> &Geolix.city/1
                      _ -> fn _ -> nil end
                    end
    case :inet.parse_address(to_char_list(ip)) do
      {:ok, ip_address} ->
        case lookup_record.(ip_address) do
          nil ->
            #IP_ADDRESS_NOT_FOUND: The supplied IP address is not in the database.
            send_404(conn)
          record ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, JSON.encode!(record))
        end
      {:error, _} ->
        #IP_ADDRESS_REQUIRED: You have not supplied an IP address, which is a required field.
        #IP_ADDRESS_INVALID: You have not supplied a valid IPv4 or IPv6 address.
        send_400(conn)
    end
  end

  match _ do
    send_404(conn)
  end
end
