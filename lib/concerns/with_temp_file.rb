module WithTempFile
  extend ActiveSupport::Concern

  def with_temp_file(data)
    file_path = File.expand_path("tmp/#{Digest::SHA1.hexdigest(data)}_#{Time.zone.now.to_i}", Rails.root)

    File.open(file_path, 'w+') { |f| f.puts data }

    yield file_path
  ensure
    File.delete(file_path)
  end
end
