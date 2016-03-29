module InvestCooker
  module JJGCB
    class Client
      def download_rar
        `wget ftp://#{Settings.jjgcb.ftp} \\
              --ftp-user=#{ENV['HUGO_INVEST_SERVER_JJGCB_USERNAME']} \\
              --ftp-password=#{ENV['HUGO_INVEST_SERVER_JJGCB_PASSWORD']} \\
              -P #{rar_path} -r -nv`

        rar_files.each(&::JJGCB::ExtractRARJob.method(:perform_later))
      end

      private

      def rar_files
        dir = File.expand_path(Settings.jjgcb.ftp, rar_path)
        Dir.foreach(dir).
          map    { |name| File.expand_path(name, dir) }.
          select { |name| name =~ /.rar$/ }
      end

      def rar_path
        File.expand_path(Settings.jjgcb.rar_folder, APP_ROOT.call)
      end
    end
  end
end
