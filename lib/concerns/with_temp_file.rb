require 'active_support/concern'
module WithTempFile
  extend ActiveSupport::Concern

  def with_temp_file(data, mode: 'w+')
    __file_path__ = "/tmp/#{Digest::SHA1.hexdigest(data)}"

    File.open(__file_path__, mode) { |f| f.puts data }

    yield __file_path__
  ensure
    File.delete(__file_path__)
  end
end
