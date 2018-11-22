# Utils::Random
# 随机密码相关的工具类
module Utils
  class Random
    def self.digital_code(length)
      SecureRandom.random_number(('9' * length).to_i).to_s.rjust(length, '0')
    end

    def self.weak_password(length)
      # SecureRandom.urlsafe_base64生成的字串长度 >= length
      # 所以这里取 [0...length]

      head_length = length - 4
      head = SecureRandom.urlsafe_base64(head_length)[0...head_length]
      tail = [
        (0..9).to_a,
        ('a'..'z').to_a,
        ('A'..'Z').to_a,
        ['#', '?', '!', '@', '$', '%', '^', '&', '*', '-']
      ].map(&:sample)
       .map(&:to_s)
       .join

      "#{head}#{tail}"
    end
  end
end
