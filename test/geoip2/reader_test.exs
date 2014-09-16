defmodule GeoIP2.ReaderTest do
  use ExUnit.Case
  use Bitwise
  alias GeoIP2.Reader, as: DUT

  test "read metadata" do
    path = "MaxMind-DB/test-data/GeoIP2-Country-Test.mmdb"
    fd = File.open!(path, [:read, :binary, :raw])
    stat = File.stat!(path)
    assert {:ok, %{"binary_format_major_version" => 2}} = DUT.read_metadata(fd, stat.size)
  end

  test "read search tree" do
    path = "MaxMind-DB/test-data/GeoIP2-Country-Test.mmdb"
    fd = File.open!(path, [:read, :binary, :raw])
    stat = File.stat!(path)
    {:ok, %{"node_count" => node_count} = metadata} = DUT.read_metadata(fd, stat.size)
    {:ok, search_tree} = DUT.read_search_tree(fd, metadata)
    assert node_count == length(search_tree)
  end

  test "get record for IP" do
    path = "MaxMind-DB/test-data/GeoIP2-Country-Test.mmdb"
    {:ok, reader} = DUT.open(path)
    assert nil == DUT.get(reader, <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>)
  end
end
