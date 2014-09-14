defmodule GeoipDaemon.GeoIP2 do
  defmodule Decoder do
    use Bitwise, only_operators: true

    defp decode_unsigned(input, bytes) do
      decode_unsigned(input, bytes, 0)
    end
    defp decode_unsigned(input, 0, acc) do
      {acc, input}
    end
    defp decode_unsigned(<<byte, rest :: binary>>, bytes, acc) do
      decode_unsigned(rest, bytes - 1, acc <<< 8 ||| byte)
    end

    defp decode_signed(input, bytes) do
      decode_signed(input, bytes, 0)
    end
    defp decode_signed(input, 0, acc) do
      {acc, input}
    end
    defp decode_signed(<<byte :: signed, rest :: binary>>, bytes, acc) do
      decode_signed(rest, bytes - 1, acc <<< 8 ||| byte)
    end

    defp decode_uint16(input, size) do
      decode_unsigned(input, size)
    end

    defp decode_uint32(input, size) do
      decode_unsigned(input, size)
    end

    defp decode_uint64(input, size) do
      decode_unsigned(input, size)
    end

    defp decode_uint128(input, size) do
      decode_unsigned(input, size)
    end

    defp decode_int32(input, size) do
      decode_signed(input, size)
    end

    defp decode_double(<<value :: float, rest :: binary>>) do
      {value, rest}
    end

    defp decode_binary(input, bytes) do
      value = binary_part(input, 0, bytes)
      remaining = binary_part(input, bytes, byte_size(input) - bytes)
      {value, remaining}
    end

    defp decode_string(input, size) do
      decode_binary(input, size)
    end

    defp decode_bytes(input, size) do
      decode_binary(input, size)
    end

    defp decode_array(input, size) do
      decode_array(input, size, [])
    end
    defp decode_array(input, 0, acc) do
      {Enum.reverse(acc), input}
    end
    defp decode_array(input, size, acc) do
      {value, remaining} = decode(input)
      decode_array(remaining, size - 1, [value|acc])
    end

    defp decode_map(input, size) do
      decode_map(input, size, %{})
    end
    defp decode_map(input, 0, acc) do
      {acc, input}
    end
    defp decode_map(input, size, acc) do
      {key, remaining} = decode(input)
      {value, remaining} = decode(remaining)
      decode_map(remaining, size - 1, Dict.put(acc, key, value))
    end

    defp decode_extended_type(input, ctrl_type) do
      case ctrl_type do
        0 ->
          <<ext_type, rest :: binary>> = input
          {7 + ext_type, rest}
        _ ->
          {ctrl_type, input}
      end
    end

    defp decode_payload_size(input, ctrl_size) do
      bytes = max(0, ctrl_size - 28)
      {extended_size, remaining} = decode_unsigned(input, bytes)
      case bytes do
        0 -> {ctrl_size, remaining}
        1 -> {29 + extended_size, remaining}
        2 -> {29 + 256 + extended_size, remaining}
        3 -> {29 + 256 + 65536 + extended_size, remaining}
      end
    end

    def decode(<<ctrl_type :: size(3), ctrl_size :: size(5), rest :: binary>>) do
      {type, remaining} = decode_extended_type(rest, ctrl_type)
      {size, remaining} = decode_payload_size(remaining, ctrl_size)
      case type do
        2 -> decode_string(remaining, size)
        3 -> decode_double(remaining)
        4 -> decode_bytes(remaining, size)
        5 -> decode_uint16(remaining, size)
        6 -> decode_uint32(remaining, size)
        8 -> decode_int32(remaining, size)
        9 -> decode_uint64(remaining, size)
        10 -> decode_uint128(remaining, size)
        7 -> decode_map(remaining, size)
        11 -> decode_array(remaining, size)
      end
    end
  end

  defmodule Reader do
    @metadata_limit 128 * 1024
    @metadata_start_marker <<0xAB, 0xCD, 0xEF>> <> "MaxMind.com"

    def open(path) do
      case File.stat(path) do
        {:ok, stat} ->
          fd = File.open!(path, [:read, :binary, :raw])
          case Metadata.read(fd, stat.size) do
            {:ok, metadata} ->
              {:ok, {fd, metadata}}
            {:error, reason} -> {:error, reason}
          end
        {:error, reason} ->
          {:error, reason}
      end
    end

    def close(reader) do
    end

    def get(reader, ip_address) do
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
  end
end
