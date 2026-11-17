require "test_helper"

class PublicKeyTest < ActiveSupport::TestCase
  # A body naming +type+, followed by something standing for the key.
  def body_of(type)
    [ [ type.bytesize, type, 4, "key!" ].pack("Na*Na*") ].pack("m0")
  end

  test "parses the type, the body and the comment of a key" do
    key = PublicKey.parse("ssh-ed25519 #{body_of('ssh-ed25519')} juca@laptop")

    assert_equal "ssh-ed25519", key.type
    assert_equal body_of("ssh-ed25519"), key.body
    assert_equal "juca@laptop", key.comment
  end

  test "parses a key of every type it knows" do
    PublicKey::TYPES.each do |type|
      assert PublicKey.parse("#{type} #{body_of(type)}"), "expected a #{type} key to be parsed"
    end
  end

  test "parses a key without comment" do
    assert_nil PublicKey.parse("ssh-ed25519 #{body_of('ssh-ed25519')}").comment
  end

  test "keeps the spaces of the comment" do
    assert_equal "the laptop of juca", PublicKey.parse("ssh-ed25519 #{body_of('ssh-ed25519')} the laptop of juca").comment
  end

  test "writes the key in one line, without the blanks around or between its parts" do
    body = body_of("ssh-ed25519")

    assert_equal "ssh-ed25519 #{body} juca@laptop", PublicKey.parse(" ssh-ed25519\t#{body}   juca@laptop \r\n").to_s
    assert_equal "ssh-ed25519 #{body}", PublicKey.parse("ssh-ed25519 #{body}\n").to_s
  end

  test "has the same fingerprint whatever the comment" do
    body = body_of("ssh-ed25519")

    assert_equal PublicKey.parse("ssh-ed25519 #{body} one").fingerprint, PublicKey.parse("ssh-ed25519 #{body}").fingerprint
    assert_not_equal PublicKey.parse("ssh-ed25519 #{body}").fingerprint, PublicKey.parse(ssh_key).fingerprint
  end

  test "has the fingerprint ssh-keygen shows" do
    key = PublicKey.parse("ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbFowboGDdo9nzNtsUuX/rvGsiOkd2BAXgvXcf2dipM juca@laptop")

    assert_equal "SHA256:vHVB6Jsc7ongKNgElvLTlTAuu1D6dVhBLhs7U7rkL/Q", key.fingerprint
  end

  test "is not a key" do
    body = body_of("ssh-ed25519")

    {
      "nothing" => nil,
      "blank" => "  ",
      "only a type" => "ssh-ed25519",
      "an unknown type" => "ssh-dss #{body_of('ssh-dss')}",
      "a body that is not base64" => "ssh-ed25519 not*base64",
      "a body of another type" => "ssh-rsa #{body}",
      "a body with nothing after its type" => "ssh-ed25519 #{[ [ 11, 'ssh-ed25519' ].pack('Na*') ].pack('m0')}",
      "a second line" => "ssh-ed25519 #{body} juca\nssh-ed25519 #{body}",
      "a second line after a carriage return" => "ssh-ed25519 #{body} juca\rssh-ed25519 #{body}",
      "a body broken in lines" => "ssh-ed25519 #{body[0, 20]}\n#{body[20..]}",
      "options before the key" => "command=\"/bin/sh\" ssh-ed25519 #{body}",
      "options without blanks before the key" => "no-pty,ssh-ed25519 #{body}",
      "a comment with a control character" => "ssh-ed25519 #{body} ju\0ca",
      "bytes that are not text" => "ssh-ed25519 #{body} \xff"
    }.each do |what, text|
      assert_nil PublicKey.parse(text), "expected #{what} not to be a key"
    end
  end
end
