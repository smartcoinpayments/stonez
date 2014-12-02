# -*- coding: utf-8 -*-
module Stonez
  class TransactionStatus < Stonez::Request
    attr_accessor :id, :tipo, :valor, :parcelas, :codigo_autorizacao
    attr_accessor :status, :codigo_resposta, :resposta, :capturada

    def params_to_xml
      Stonez::XmlParser.transaction_status_request(@params)
    end

    def request_path
      # Dá preferência ao id da Stone - pode ter mais que uma tx com mesmo ID da PagPop!
      tipo = @params[:id_stone].present? ? 0 : 2
      "/TransactionStatusReport?i=#{tipo}"
    end

    def handle_response_params(params)
      @id                 = params[:id_stone           ]
      @valor              = params[:valor              ].try(:to_i)
      @parcelas           = params[:parcelas           ].try(:to_i)
      @status             = params[:status             ]
      @codigo_autorizacao = params[:codigo_autorizacao ]
      @codigo_resposta    = params[:codigo_resposta    ]
      @resposta           = params[:resposta           ]
      @capturada          = params[:capturada          ]
    end

    def autorizada?
      # TODO: tratar "PART"
      @resposta == "APPR" && !@capturada && !cancelada?
    end

    def capturada?
      @resposta == "APPR" && @capturada && !cancelada?
    end

    def cancelada?
      @status == "REVT"
    end

    def reprovada?
      @status == "DECL"
    end

    def nao_encontrada?
      false #TODO
    end
  end
end
