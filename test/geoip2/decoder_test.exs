defmodule GeoIP2.DecoderTest do
  use ExUnit.Case
  use Bitwise
  alias GeoIP2.Decoder, as: DUT

  test "decode pointer" do
    assert {{:pointer, 0x01FF}, ""} == DUT.decode(<<0b00100001, 255>>)
    assert {{:pointer, 0x0100FF + 2048}, ""} == DUT.decode(<<0b00101001, 0, 255>>)
    assert {{:pointer, 0x010000FF + 526336}, ""} == DUT.decode(<<0b00110001, 0, 0, 255>>)
    assert {{:pointer, 0x12345678}, ""} == DUT.decode(<<0b00111000, 0x12, 0x34, 0x56, 0x78>>)
  end

  test "decode string" do
    assert {"Hello", ""} == DUT.decode(<<0b01000101>> <> "Hello")
  end

  test "decode double" do
    assert {3.14, ""} == DUT.decode(<<0b01101000, 3.14 :: float>>)
  end

  test "decode bytes" do
    assert {<<1, 2>>, ""} == DUT.decode(<<0b10000010, 1, 2>>)
  end

  test "decode unsigned 16-bit int" do
    assert {256 - 1, ""} == DUT.decode(<<0b10100001, 255>>)
    assert {65536 - 1, ""} == DUT.decode(<<0b10100010, 255, 255>>)
  end

  test "decode unsigned 32-bit int" do
    assert {256 - 1, ""} == DUT.decode(<<0b11000001, 255>>)
    assert {4294967296 - 1, ""} == DUT.decode(<<0b11000100, 255, 255, 255, 255>>)
  end

  test "decode signed 32-bit int" do
    assert {-1, ""} == DUT.decode(<<0b00000001, 0b00000001, 255>>)
    assert {-1, ""} == DUT.decode(<<0b00000100, 0b00000001, 255, 255, 255, 255>>)
  end

  test "decode unsigned 64-bit int" do
    v = (1 <<< 64) - 1
    assert {v, ""} == DUT.decode(<<0b00001000, 0b00000010>> <> <<v :: size(64)>>)
  end

  test "decode unsigned 128-bit int" do
    v = (1 <<< 128) - 1
    assert {v, ""} == DUT.decode(<<0b00010000, 0b00000011>> <> <<v :: size(128)>>)
  end

  test "decode map" do
    key = <<0b01000011>> <> "key"
    value = <<0b10100001, 1>>
    assert {%{"key" => 1}, ""} == DUT.decode(<<0b11100001>> <> key <> value)
  end

  test "decode array" do
    value = <<0b10100001, 1>>
    assert {[1], ""} == DUT.decode(<<0b00000001, 0b00000100>> <> value)
  end
end
