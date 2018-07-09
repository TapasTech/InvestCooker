# frozen_string_literal: true
# 提供调用 invest_docs_api 方法
# dependencies:
#   gems:
#     - rest-client
#     - excon
#     - pundit
#   attributes | methods:
#     - request.env['HTTP_AUTHORIZATION']
module InvestDocsStub
  extend ActiveSupport::Concern

  included do
    attr_accessor :invest_docs_aggs
  end

  # 查询已发布稿件的重复文章情况
  def invest_docs_api_info_dups(params)
    resp = invest_docs_request(
      method: :post,
      url: "#{invest_docs_api_url}/info_dups",
      payload: Oj.dump(params.as_json),
      timeout: 5,
      headers: {
        'Content-Type' => 'application/json'
      }
    )

    Oj.load(resp.body, symbol_keys: true)
  end

  # 查询入库稿件的重复文章情况
  def invest_docs_api_doc_dups(params)
    resp = invest_docs_request(
      method: :post,
      url: "#{invest_docs_api_url}/doc_dups",
      payload: Oj.dump(params.as_json),
      timeout: 5,
      headers: {
        'Content-Type' => 'application/json'
      }
    )

    Oj.load(resp.body, symbol_keys: true)
  end

  # 查询导出已发布文章列表
  def invest_docs_api_information_exports(params)
    resp = invest_docs_request(
      method: :post,
      url: "#{invest_docs_api_url}/information_exports",
      payload: Oj.dump(params.as_json),
      timeout: 5,
      headers: {
        Authorization: invest_docs_api_auth,
        'Content-Type' => 'application/json'
      }
    )

    Oj.load(resp.body)
  end

  # 查询急速发稿队列
  def invest_docs_api_document_popups(params)
    resp = invest_docs_request(
      method: :post,
      url: "#{invest_docs_api_url}/document_popups",
      payload: Oj.dump(params.as_json),
      timeout: 5,
      headers: {
        Authorization: invest_docs_api_auth,
        'Content-Type' => 'application/json'
      }
    )

    Oj.load(resp.body)
  end

  # 查询文章统计信息
  def invest_docs_api_multi_aggs(params)
    search = request.params.fetch('search') { '{}' }
    if params[:filter].present?
      search = Oj.load(search)
      search.merge!(params[:filter].as_json)
      search = Oj.dump(search)
    end
    params.merge!(search: search)

    resp = invest_docs_request(
      method: :get,
      url: "#{invest_docs_api_url}/multi_aggs",
      timeout: 5,
      headers: {
        params: params,
        Authorization: invest_docs_api_auth
      }
    )

    Oj.load(resp.body).map do |k, v|
      [k, v.sort_by { |s| -s['count'].to_i }]
    end.to_h
  end

  def invest_docs_request(params)
    path    = params[:url].split('/')[3..-1].join('/')
    timeout = params[:timeout]
    method  = params[:method]
    headers = params[:headers]
    payload = params[:payload]

    query_params = headers.delete(:params)
    query_params && query_params = RestClient::Utils.encode_query_string(query_params)

    $invest_docs_connection ||= ConnectionPool.new(size: 5, timeout: 5) do
      Excon.new(invest_docs_api_url,
        connection_timeout: timeout,
        write_timeout: timeout,
        read_timeout: timeout,
        persistent: true)
    end

    $invest_docs_connection.with do |conn|
      return conn.request(
        idempotent: true, # this request can be repeated safely, so retry on errors up to 3 times
        path: path,
        method: method,
        headers: headers,
        body: payload,
        query: query_params,
        expects: [200, 201]
      )
    end
  rescue Excon::Error::Unauthorized => error
    fail Pundit::NotAuthorizedError, 'Session expired.'
  end

  def invest_docs_api_auth
    request.env['HTTP_AUTHORIZATION']
  end

  def invest_docs_api_url
    "http://#{ENV.fetch('invest_docs_api') { 'docs:3000' }}"
  end
end
