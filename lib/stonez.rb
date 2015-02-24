#require 'active_support/core_ext/string'
#require 'active_support/core_ext/object/with_options'
#require 'active_support/core_ext/module/attribute_accessors'
#require 'active_model'
require 'nokogiri'

require 'stonez/request'
require 'stonez/xml_parser'
require 'stonez/transaction_status'
require 'stonez/authorisation'
require 'stonez/completion'
require 'stonez/reversal'
require 'stonez/configuration'

module Stonez
  class << self
    attr_accessor :configuration

    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end
