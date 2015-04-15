# -*- coding: utf-8 -*-
module Stonez
  class Authorisation < Stonez::Request
    attr_accessor :id, :tipo_mensagem
    attr_accessor :codigo_autorizacao, :codigo_resposta, :resposta, :capturada

    def params_to_xml
      Stonez::XmlParser.authorisation_request(@params)
    end

    def request_path
      "/Authorize"
    end

    def handle_response_params(params)
      @id                 = params[:id_stone           ]
      @mensagem           = params[:mensagem           ]
      @tipo_mensagem      = params[:tipo_mensagem      ]
      @codigo_autorizacao = params[:codigo_autorizacao ]
      @codigo_resposta    = params[:codigo_resposta    ]
      @resposta           = params[:resposta           ]
      @capturada          = params[:capturada          ]
    end

    def autorizada?
      @resposta == "APPR"
    end

    def capturada?
      @resposta == "APPR" && @capturada
    end

    def reprovada?
      @resposta == "DECL"
    end

    def cancelada?
      false
    end

    def nao_encontrada?
      false
    end
  end
end
