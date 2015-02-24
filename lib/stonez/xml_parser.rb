# -*- coding: utf-8 -*-
module Stonez
  class XmlParser
    def self.parse_response(xml)
      tipo = response_type xml
      case tipo
      when "AcceptorRejection"
        parse_error xml
      when "AcceptorAuthorisationResponse"
        parse_authorisation_response xml
      when "AcceptorCompletionAdviceResponse"
        parse_completion_response xml
      when "AcceptorTransactionStatusReportResponse"
        parse_transaction_status_response xml
      end
    end

    def self.parse_error xml
      doc = Nokogiri::XML(xml, nil, 'UTF-8')
      msg = doc.css('AddtlInf').try(:text)
      begin
        msg = msg.encode 'UTF-8' if msg
      rescue => e
        puts e
      end

      {
        tipo_erro: doc.css('RjctRsn').try(:text),
        mensagem:  msg
      }
    end

    def self.parse_authorisation_response(xml)
      doc = Nokogiri::XML(xml, nil, 'UTF-8')
      {
        id_stone:           doc.css('RcptTxId').try(:text),
        mensagem:           doc.css('MsgCntt').try(:text),
        tipo_mensagem:      doc.css('ActnTp').try(:text),
        codigo_autorizacao: doc.css('AuthstnCd').try(:text),
        codigo_resposta:    doc.css('RspnRsn').try(:text),
        resposta:           doc.css('Rspn').try(:text),
        capturada:          doc.css('CmpltnReqrd').try(:text) != "true",
      }
    end

    def self.parse_completion_response(xml)
      doc = Nokogiri::XML(xml, nil, 'UTF-8')
      {
        transaction_ref:  doc.css('TxRef').try(:text),
        funcao:           doc.css('MsgFctn').try(:text),
        resposta:         doc.css('Rspn').try(:text),
      }
    end

    def self.parse_transaction_status_response(xml)
      doc = Nokogiri::XML(xml, nil, 'UTF-8')
      {
        id_stone:           doc.css('RcptTxId').try(:text),
        tipo:               doc.css('AcctTp').try(:text),
        valor:              doc.css('TtlAmt').try(:text),
        parcelas:           doc.css('TtlNbOfPmts').try(:text),
        status:             doc.css('TxSts').try(:text),
        codigo_autorizacao: doc.css('AuthstnCd').try(:text),
        codigo_resposta:    doc.css('RspnRsn').try(:text),
        resposta:           doc.css('Rspn').try(:text),
        capturada:          doc.css('CmpltnReqrd').try(:text) != "true",
      }
    end

    def self.authorisation_request(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Document(xmlns: "urn:AcceptorAuthorisationRequestV02.1") do
          xml.AccptrAuthstnReq do
            xml.Hdr do
              xml.MsgFctn    "AUTQ"
              xml.PrtcolVrsn "2.0"
            end
            xml.AuthstnReq do
              xml.Envt do
                xml.Mrchnt do
                  xml.Id do
                    xml.Id        Stonez.configuration.merchant_id
                    xml.ShortName params[:short_name]
                  end
                end
                xml.Card do
                  xml.PlainCardData do
                    xml.PAN    params[:pan]
                    xml.XpryDt params[:expiration_date]
                    if params[:cvv].present? and false
                      xml.CardSctyCd do
                        xml.CSCVal params[:cvv]
                      end
                    end
                  end
                end
                if params[:cardholder_name].present?
                  xml.Crdhldr do
                    xml.Nm params[:cardholder_name]
                  end
                end
              end
              xml.Cntxt do
                xml.PmtCntxt do
                  xml.CardDataNtryMd "PHYS" # TODO: usar MGST com leitor? Alex Carvalho: vc só deve alterar para MGST se vc enviar os dados das trilhas
                  xml.TxChanl        "ECOM" # Somente com PHYS; não usar com MGST
                end
              end
              xml.Tx do
                xml.InitrTxId params[:transaction_id]
                xml.TxCaptr   params[:capture]
                xml.TxId do
                  xml.TxDtTm  params[:transaction_dtime]
                  xml.TxRef   params[:transaction_ref]
                end
                xml.TxDtls do
                  xml.Ccy 986
                  xml.TtlAmt params[:total_amount]
                  xml.AcctTp "CRDT"
                  xml.RcrngTx do
                    xml.InstlmtTp   params[:parcelas] > 1 ? "MCHT" : "NONE"
                    xml.TtlNbOfPmts params[:parcelas] > 1 ? params[:parcelas] : 0
                  end
                end
              end
            end
          end
        end
      end

      builder.to_xml
    end

    def self.completion_request(params)
      acceptor_completion_advice params, true
    end

    def self.reversal_request(params)
      acceptor_completion_advice params, false
    end

    def self.acceptor_completion_advice(params, capture)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Document(xmlns: "urn:AcceptorCompletionAdviceV02.1") do
          xml.AccptrCmpltnAdvc do
            xml.Hdr do
              xml.MsgFctn    capture ? "CMPV" : "RVRA"
              xml.PrtcolVrsn "2.0"
            end
            xml.CmpltnAdvc do
              xml.Envt do
                xml.Mrchnt do
                  xml.Id do
                    xml.Id       Stonez.configuration.merchant_id
                  end
                end
              end
              xml.Tx do
                xml.TxId do
                  xml.TxDtTm     params[:transaction_dtime]
                  xml.TxRef      params[:transaction_ref]
                end
                xml.OrgnlTx do
                  if params[:transaction_id].present?
                    xml.InitrTxId  params[:transaction_id]
                  else
                    xml.RcptTxId   params[:id_stone]
                  end
                end
                xml.TxDtls do
                  xml.Ccy        "986"
                  xml.TtlAmt     params[:total_amount]
                end
              end
            end
          end
        end
      end

      builder.to_xml
    end

    def self.transaction_status_request(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Document(xmlns: "urn:AcceptorTransactionStatusReportRequestV02.1") do
          xml.AccptrTxStsRptRq do
            xml.Hdr do
              xml.MsgFctn    "TSRR"
              xml.PrtcolVrsn "2.0"
              # Dá preferência ao id da Stone - pode ter mais que uma tx com mesmo ID da PagPop!
              if params[:id_stone].present?
                xml.XchgId     "001"
              else
                xml.XchgId     "002"
              end
            end
            xml.TxStsRpt do
              xml.Envt do
                xml.Mrchnt do
                  xml.Id do
                    xml.Id   Stonez.configuration.merchant_id
                  end
                end
              end
              xml.DataSet do
                xml.DataSetId do
                  if params[:id_stone].present?
                    xml.Tp    "RTVF"
                  else
                    xml.Tp    "ITVF"
                  end
                end
                xml.Tx do
                  xml.OrgnlTx do
                    if params[:id_stone].present?
                      xml.RcptTxId   params[:id_stone]
                    else
                      xml.InitrTxId  params[:transaction_id]
                    end
                  end
                end
              end
            end
          end
        end
      end

      builder.to_xml
    end

    def self.response_type xml
      begin
        xml_enc = xml.encode 'UTF-8' if xml
      rescue
        xml_enc = xml
      end
      [
       "AcceptorRejection",
       "AcceptorAuthorisationRequest",
       "AcceptorAuthorisationResponse",
       "AcceptorCompletionAdvice",
       "AcceptorCompletionAdviceResponse",
       "AcceptorCancellationRequest",
       "AcceptorCancellationResponse",
       "AcceptorCancellationAdvice",
       "AcceptorCancellationAdviceResponse",
       "AcceptorTransactionStatusReportRequest",
       "AcceptorTransactionStatusReportResponse",
       "StatusReport",
       "ManagementPlanReplacement",
       "TerminalManagementRejection",
       "AcceptorDiagnosticRequest",
       "AcceptorDiagnosticResponse"
      ].each do |type|
        return type if xml_enc.include? "#{type}V"
      end
    end
  end
end
