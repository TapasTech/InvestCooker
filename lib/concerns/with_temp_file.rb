module WithTempFile
  extend ActiveSupport::Concern

  def with_temp_file(data)
    __file_path__ = File.expand_path("tmp/#{Digest::SHA1.hexdigest(data)}_#{Time.zone.now.to_i}", Rails.root)

    File.open(__file_path__, 'w+') { |f| f.puts data }

    yield __file_path__
  ensure
    File.delete(__file_path__)
  end
end
