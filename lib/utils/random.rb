# Utils::Random
# 随机密码相关的工具类
module Utils
  class Random
    def self.digital_code(length)
    	(SecureRandom.random_number(('9' * length).to_i)).to_s.rjust(length, '0')
    end

    def self.weak_password(length)
      # SecureRandom.urlsafe_base64生成的字串长度 >= length
      # 所以这里取 [0...length]
      SecureRandom.urlsafe_base64(length)[0...length]
    end
  end
end
