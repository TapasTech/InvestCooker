require 'mail'

# 发送邮件的 Client
# 实际发送邮件的 end-point
module Utils
  class Email
    class << self

      # @deprecated
      def send_report_email!(data)
        $debug_logger.warn 'deprecated method'
      end

      def send_welcome_email!(data)
        data = to_hash(data)
        subject = 'DT财经-投研资讯系统-欢迎'
        email = data[:email]
        name = data[:name]
        password = data[:password]

        body = <<~BODY
          #{name}，你好!
          已为你开通投研资讯系统的账号，欢迎使用！
          帐号：#{email}
          初始密码：#{password}
          登录地址：#{site_url}
          请尽快登录网站并修改密码，谢谢！
        BODY

        send_email(email: email, subject: subject, text_body: body)
      end

      def site_url
        Rails.configuration.host
      end

      def send_reset_password_email!(data)
        data = to_hash(data)
        token = data[:token]
        email = data[:email]
        subject = 'DT财经-投研资讯系统-重置密码'
        url = "#{site_url}/resetpwd?token=#{token}&email=#{email}"
        body = %Q(
          <p>请点击下面的链接重新设置密码：</p>
          <p><a href="#{url}" target=_blank>#{url}</a></p>
          <p>如果链接无效请复制以下内容到浏览器打开：</p>
          <pre>#{url}</pre>
        ).strip!

        send_email(email: email, subject: subject, html_body: body)
      end

      def to_hash(data)
        return data if data.is_a?(Hash)
        return Oj.load(data, symbol_keys: true) if data.is_a?(String)

        fail "invalid data: #{data.inspect}"
      end

      def send_email(email:, subject:, text_body: '', html_body: '', attach_path: nil)
        user_name = ENV['HUGO_INVEST_SERVER_MAILER_USERNAME']
        password = ENV['HUGO_INVEST_SERVER_MAILER_PASSWORD']

        smtp = { address: 'smtp.dtcj.com',
          port: 25,
          domain: 'dtcj.com',
          user_name: user_name,
          password: password,
          enable_starttls_auto: true,
          openssl_verify_mode: 'none' }

        Mail.defaults { delivery_method :smtp, smtp }

        receiver = email

        mail = Mail.new do
          from user_name
          to receiver
          subject subject
          mail.add_file = attach_path if attach_path.present?
        end

        if text_body.present?
          text_part = Mail::Part.new do
            body text_body
          end

          mail.text_part = text_part
        end

        if html_body.present?
          html_part = Mail::Part.new do
            content_type 'text/html; charset=UTF-8'
            body html_body
          end

          mail.html_part = html_part
        end

        mail.deliver!
      end
    end
  end
end
