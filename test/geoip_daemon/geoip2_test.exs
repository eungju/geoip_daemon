defmodule GeoipDaemon.GeoIP2Test do
  use ExUnit.Case
  use Bitwise
  alias GeoipDaemon.GeoIP2, as: DUT

  test "decode string" do
    assert {"Hello", ""} == DUT.Decoder.decode(<<0b01000101>> <> "Hello")
  end

  test "decode double" do
    assert {3.14, ""} == DUT.Decoder.decode(<<0b01101000, 3.14 :: float>>)
  end

  test "decode bytes" do
    assert {<<1, 2>>, ""} == DUT.Decoder.decode(<<0b10000010, 1, 2>>)
  end

  test "decode unsigned 16-bit int" do
    assert {256 - 1, ""} == DUT.Decoder.decode(<<0b10100001, 255>>)
    assert {65536 - 1, ""} == DUT.Decoder.decode(<<0b10100010, 255, 255>>)
  end

  test "decode unsigned 32-bit int" do
    assert {256 - 1, ""} == DUT.Decoder.decode(<<0b11000001, 255>>)
    assert {4294967296 - 1, ""} == DUT.Decoder.decode(<<0b11000100, 255, 255, 255, 255>>)
  end

  test "decode unsigned 64-bit int" do
    assert {(1 <<< 64) - 1, ""} == DUT.Decoder.decode(<<0b00001000, 0b00000010>> <> IO.iodata_to_binary(Enum.take(Stream.cycle([255]), 8)))
  end

  test "decode unsigned 128-bit int" do
    assert {(1 <<< 128) - 1, ""} == DUT.Decoder.decode(<<0b00010000, 0b00000011>> <> IO.iodata_to_binary(Enum.take(Stream.cycle([255]), 16)))
  end

  test "decode map" do
    key = <<0b01000011>> <> "key"
    value = <<0b10100001, 1>>
    assert {%{"key" => 1}, ""} == DUT.Decoder.decode(<<0b11100001>> <> key <> value)
  end

  test "decode array" do
    value = <<0b10100001, 1>>
    assert {[1], ""} == DUT.Decoder.decode(<<0b00000001, 0b00000100>> <> value)
  end

  test "read metadata" do
    path = "data/GeoLite2-Country.mmdb"
    fd = File.open!(path, [:read, :binary, :raw])
    stat = File.stat!(path)
    assert {:ok, %{"binary_format_major_version" => 2}} = DUT.Reader.read_metadata(fd, stat.size)
  end
end
