# An SSH public key, as ssh-keygen prints it and sshd reads it from the
# authorized keys file: "<type> <body> <comment>", all in one line.
#
# Nothing else is a key: not two lines, not a line starting with options
# such as command="...", not a body that says it is of another type.
class PublicKey
  TYPES = %w[
    ssh-ed25519
    ssh-rsa
    ecdsa-sha2-nistp256
    ecdsa-sha2-nistp384
    ecdsa-sha2-nistp521
    sk-ssh-ed25519@openssh.com
    sk-ecdsa-sha2-nistp256@openssh.com
  ].freeze

  LINE = /\A(?<type>\S+)[ \t]+(?<body>\S+)(?:[ \t]+(?<comment>[^[:cntrl:]]*))?\z/

  class << self
    # The key written in +text+, or nil when it is not one. Blanks around it,
    # as left by pasting into a form, are not part of the key.
    def parse(text)
      text = text.to_s
      match = text.valid_encoding? && LINE.match(text.strip)
      return unless match && TYPES.include?(match[:type])

      blob = decode(match[:body])
      return unless blob && of_type?(blob, match[:type])

      new(type: match[:type], body: match[:body], comment: match[:comment].presence, blob: blob)
    end

    private

    def decode(body)
      body.unpack1("m0")
    rescue ArgumentError
      nil
    end

    # The body starts by naming its type, and has the key after it.
    def of_type?(blob, type)
      header = [ type.bytesize, type ].pack("Na*")
      blob.start_with?(header) && blob.bytesize > header.bytesize
    end
  end

  attr_reader :type, :body, :comment

  def initialize(type:, body:, comment:, blob:)
    @type = type
    @body = body
    @comment = comment
    @blob = blob
  end

  # The same for the same key whatever its comment, as ssh-keygen -l shows it.
  def fingerprint
    "SHA256:#{Digest::SHA256.base64digest(@blob).delete('=')}"
  end

  # The one line of the key.
  def to_s
    [ type, body, comment ].compact.join(" ")
  end
end
