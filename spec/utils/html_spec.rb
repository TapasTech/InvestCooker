require './lib/invest_cooker'
require './lib/utils/image'
require './lib/utils/html'
require './lib/cdn/aliyun_oss'
require 'byebug'

RSpec.describe 'Utils::Html' do
  describe 'replace_content_images_with_cdn' do
    before do
      allow(CDN::AliyunOSS.instance).to receive(:upload).and_return true
      allow(Utils::Image).to receive(:size_of).and_return 1024
    end

    it 'can replace other url to cdn url' do
      cdn_endpoint = 'http://cdn.cbndata.com'
      sample_html = '<img src="https://cf.dtcj.com/26214bf2-6205-4322-b282-5c80cdcc7939.jpg"'

      expect(Utils::Html.replace_content_images_with_cdn(sample_html, cdn_endpoint: cdn_endpoint)).to \
        include cdn_endpoint
    end
  end
end
