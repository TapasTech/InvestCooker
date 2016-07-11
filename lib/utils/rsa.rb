module Utils
  class RSA
    class << self
      DIGEST = OpenSSL::Digest::SHA512.new

      # 签名
      def generate_base64_signiture(data)
        Base64.encode64 cbn_rsa_private.sign(DIGEST, data)
      end

      def verify_base64_signiture(base64_signature, data, sender: :mayi)
        get_rsa_public_key(sender)
          .try :verify,
               DIGEST,
               Base64.decode64(base64_signature),
               data
      end

      private

      def cbn_rsa_private
        OpenSSL::PKey.read(File.open(Settings.rsa.private_keys.cbn))
      end

      def get_rsa_public_key(sender)
        key_file_path = Settings.rsa.public_keys.send(sender)
        return unless key_file_path.present?
        @rsa_public_keys ||= {}
        @rsa_public_keys[sender] ||=
          OpenSSL::PKey.read(File.open(key_file_path))
        @rsa_public_keys[sender]
      end
    end
  end
end
