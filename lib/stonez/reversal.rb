# -*- coding: utf-8 -*-
module Stonez
  class Reversal < Completion
    def params_to_xml
      Stonez::XmlParser.reversal_request(@params)
    end
  end
end
