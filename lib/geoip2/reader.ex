defmodule GeoIP2.Reader do
  use Bitwise, only_operators: true
  alias GeoIP2.Decoder, as: Decoder

  @metadata_limit 128 * 1024
  @metadata_start_marker <<0xAB, 0xCD, 0xEF>> <> "MaxMind.com"

  def open(path) do
    case File.stat(path) do
      {:ok, stat} ->
        fd = File.open!(path, [:read, :binary, :raw])
        case read_metadata(fd, stat.size) do
          {:ok, metadata} ->
            case read_search_tree(fd, metadata) do
              {:ok, search_tree} ->
                {:ok, {fd, metadata, search_tree}}
              {:error, reason} ->
                {:error, reason}
            end
          {:error, reason} ->
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  def close({fd, _, _}) do
    File.close(fd)
  end

  def get({_, _, search_tree}=reader, ip_address) do
    case search_lookup(reader, ip_address, Enum.at(search_tree, 0)) do
      nil -> nil
      pointer -> nil #data_lookup(reader, pointer)
    end
  end

  def search_lookup({_, metadata, search_tree}=reader,
             <<b :: size(1), rest :: bitstring>>, {left, right}) do
    p = case b do
          0 -> left
          1 -> right
        end
    %{"node_count" => node_count} = metadata
    cond do
      p < node_count ->
        search_lookup(reader, rest, Enum.at(search_tree, p))
      p == node_count ->
        nil
      p > node_count ->
        p
    end
  end

  def read_metadata(fd, size) do
    case :file.pread(fd, max(size - @metadata_limit, 0), @metadata_limit) do
      {:ok, data} ->
        case Enum.reverse(:binary.matches(data, @metadata_start_marker)) do
          [{pos, len}|_] ->
            buf_pos = pos + len
            buf = binary_part(data, buf_pos, byte_size(data) - buf_pos)
            {metadata, ""} = Decoder.decode(buf)
            {:ok, metadata}
          [] -> {:error, :no_metadata}
        end
        {:error, reason} -> {:error, reason}
    end
  end

  defp read_search_tree_nodes(_input, _record_size, 0, acc) do
    Enum.reverse(acc)
  end
  defp read_search_tree_nodes(input, record_size, count, acc) do
    node = case record_size do
             24 ->
               <<l :: size(24), r :: size(24), rest :: binary>> = input
               {l, r}
             28 ->
               <<l :: size(24), lm :: size(4), rm :: size(4), r :: size(24), rest :: binary>> = input
               {lm <<< 24 ||| l, rm <<< 24 ||| r}
             32 ->
               <<l :: size(32), r :: size(32), rest :: binary>> = input
               {l, r}
           end
    read_search_tree_nodes(rest, record_size, count - 1, [node|acc])
  end

  def read_search_tree(fd, metadata) do
    %{"record_size" => record_size,
      "node_count" => node_count} = metadata
    section_size = case record_size do
                     28 -> 7
                     _ -> (record_size * 2) / 8
                   end * node_count
    case :file.pread(fd, 0, section_size) do
      {:ok, data} ->
        {:ok, read_search_tree_nodes(data, record_size, node_count, [])}
      {:error, reason} -> {:error, reason}
    end
  end
end
