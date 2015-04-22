module Stonez
  class Cancellation < Stonez::Request
    def params_to_xml
      Stonez::XmlParser.cancellation_request(@params)
    end

    def request_path
      "/Cancellation"
    end

    def success?
      @resposta == "APPR"
    end
  end
end
