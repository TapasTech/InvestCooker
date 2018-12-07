module AntVodSign
  # @dependency #sign_salt
  def vod_sign(params)
    payload =
      case params
      when String
        params
      when Hash
        params.sort_by { |k, v| k }
              .map { |k, v| "#{k}#{v}" }
              .join
      else
        return nil
      end

      unless ENV['RAILS_ENV'] == 'production'
        puts JSON.pretty_generate({
          sign_payload: payload,
          sign_salt: sign_salt
        })
      end

    Digest::MD5.hexdigest("#{payload}#{sign_salt}")[8...24]
  end
end
