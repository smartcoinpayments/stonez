# -*- coding: utf-8 -*-
module Stonez
  class Completion < Request
    attr_accessor :ref, :funcao

    def initialize(params)
      @params = params
    end

    def params_to_xml
      Stonez::XmlParser.completion_request(@params)
    end

    def request_path
      "/CompletionAdvice"
    end

    def handle_response_params(params)
      @ref      = params[:transaction_ref]
      @resposta = params[:resposta       ]
      @funcao   = params[:funcao         ]
    end

    def success?
     @resposta == "APPR"
    end
  end

  class Reversal < Completion
    def params_to_xml
      Stonez::XmlParser.reversal_request(@params)
    end
  end
end
