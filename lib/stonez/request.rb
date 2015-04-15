# -*- coding: utf-8 -*-
module Stonez
  class Request
    attr_accessor :mensagem, :tipo_erro, :response_xml

    def initialize(params)
      @params = params
    end

    def request_xml
      params_to_xml
    end

    def submit
      xml = params_to_xml

      req = Net::HTTP::Post.new(Stonez.configuration.root_path + request_path)

      req.content_type = 'text/xml'
      req.body = xml

      res = Net::HTTP.start(Stonez.configuration.hostname, Stonez.configuration.port, use_ssl: Stonez.configuration.use_ssl,
                            verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
        https.request(req)
      end

      handle_response res.body
      success?
    end

    def params_to_xml
      raise "Precisa implementar"
    end

    def request_path
      raise "Precisa implementar"
    end

    def handle_response(xml)
      # Parece que muda!
      # TODO: resolver de vez
      begin
        @response_xml = xml.encode 'UTF-8' if xml
      rescue
        @response_xml = xml
      end

      params = Stonez::XmlParser.parse_response xml

      if params.nil?
        @mensagem  = "Erro de servidor ou conexão."
        @tipo_erro = "HTTP"
      elsif params[:tipo_erro].present?
        @mensagem  = params[:mensagem]
        @tipo_erro = params[:tipo_erro]
      else
        @mensagem  = params[:mensagem]
        handle_response_params params
      end
    end

    def handle_response_params(params)
      @resposta = params[:resposta]
    end

    def success?
      @resposta.present? && @resposta != "TECH"
    end

    def error?
      @tipo_erro.present? || @resposta == "TECH"
    end
  end
end
