require 'active_support'
require 'json'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # Bogus Gateway
    class BogusGateway < Gateway
      AUTHORIZATION = '53433'

      SUCCESS_MESSAGE = "Bogus Gateway: Forced success"
      FAILURE_MESSAGE = "Bogus Gateway: Forced failure"
      ERROR_MESSAGE = "Bogus Gateway: Use CreditCard number ending in 1 for success, 2 for exception and anything else for error"
      UNSTORE_ERROR_MESSAGE = "Bogus Gateway: Use trans_id ending in 1 for success, 2 for exception and anything else for error"
      CAPTURE_ERROR_MESSAGE = "Bogus Gateway: Use authorization number ending in 1 for exception, 2 for error and anything else for success"
      VOID_ERROR_MESSAGE = "Bogus Gateway: Use authorization number ending in 1 for exception, 2 for error and anything else for success"
      REFUND_ERROR_MESSAGE = "Bogus Gateway: Use trans_id number ending in 1 for exception, 2 for error and anything else for success"
      CHECK_ERROR_MESSAGE = "Bogus Gateway: Use bank account number ending in 1 for success, 2 for exception and anything else for error"

      self.supported_countries = ['US']
      self.supported_cardtypes = [:bogus]
      self.homepage_url = 'http://example.com'
      self.display_name = 'Bogus'

      attr_accessor :last_method
      attr_accessor :last_request_body, :last_response_body, :last_exception

      def reset_cached_last_info
        @last_request_body , @last_response_body, @last_exception = [nil,nil,nil]
      end

      def initialize(options = {})
        reset_cached_last_info
        @last_method = __method__

        super
      end

      def authorize(money, paysource, options = {})
        reset_cached_last_info
        @last_method = __method__

        begin
          @last_request_body = build_last_request(:authorize, money, paysource, nil, options)

          money = amount(money)
          case normalize(paysource)
          when /1$/
            @last_response_body = Response.new(true, SUCCESS_MESSAGE, {:authorized_amount => money}, { :test => true, :request_xml => '<foo/>', :response_xml  => '<quux/>', :authorization => AUTHORIZATION } )
          when /2$/
            @last_response_body = Response.new(false, FAILURE_MESSAGE, {:authorized_amount => money, :error => FAILURE_MESSAGE }, { :test => true, :request_xml => '<foo/>', :response_xml  => '<quux/>' } )
          else
            raise Error, error_message(paysource)
          end
        rescue => e
          @last_exception = e
          raise @last_exception
        end
        @last_response_body
      end

      def purchase(money, paysource, options = {})
        reset_cached_last_info
        @last_method = __method__

        begin
          @last_request_body = build_last_request(:purchase, money, paysource, nil, options)

          money = amount(money)
          case normalize(paysource)
          when /1$/, AUTHORIZATION
            @last_response_body = Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, { :test => true, :request_xml => '<foo/>', :response_xml  => '<quux/>', :authorization => AUTHORIZATION } )
          when /2$/
            @last_response_body = Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE }, { :test => true, :request_xml => '<foo/>', :response_xml  => '<quux/>' } )
          else
            raise Error, error_message(paysource)
          end
        rescue => e
          @last_exception = e
          raise @last_exception
        end
        @last_response_body
      end

      def recurring(money, paysource, options = {})
        reset_cached_last_info
        @last_method = __method__

        money = amount(money)
        case normalize(paysource)
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true)
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE },:test => true)
        else
          raise Error, error_message(paysource)
        end
      end

      def credit(money, paysource, options = {})
        reset_cached_last_info
        @last_method = __method__

        if paysource.is_a?(String)
          deprecated CREDIT_DEPRECATION_MESSAGE
          return refund(money, paysource, options)
        end

        money = amount(money)
        case normalize(paysource)
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true )
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, error_message(paysource)
        end
      end

      def refund(money, reference, options = {})
        reset_cached_last_info
        @last_method = __method__

        money = amount(money)
        case reference
        when /1$/
          raise Error, REFUND_ERROR_MESSAGE
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true)
        end
      end

      def capture(money, reference, options = {})
        reset_cached_last_info
        @last_method = __method__

        money = amount(money)
        case reference
        when /1$/
          raise Error, CAPTURE_ERROR_MESSAGE
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true)
        end
      end

      def void(reference, options = {})
        reset_cached_last_info
        @last_method = __method__

        begin
          @last_request_body = build_last_request(:void, nil, nil, reference, options)

          case reference
          when /1$/
            raise Error, VOID_ERROR_MESSAGE
          when /2$/
            @last_response_body = Response.new(false, FAILURE_MESSAGE, {:authorization => reference, :error => FAILURE_MESSAGE }, { :test => true, :request_xml => '<foo/>', :response_xml  => '<quux/>' } )
          else
            @last_response_body = Response.new(true, SUCCESS_MESSAGE, {:authorization => reference}, { :test => true, :request_xml => '<foo/>', :response_xml  => '<quux/>' } )
          end
        rescue => e
          @last_exception = e
          raise @last_exception
        end
        @last_response_body
      end

      def store(paysource, options = {})
        reset_cached_last_info
        @last_method = __method__

        case normalize(paysource)
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {:billingid => '1'}, :test => true, :authorization => AUTHORIZATION)
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:billingid => nil, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, error_message(paysource)
        end
      end

      def unstore(reference, options = {})
        reset_cached_last_info
        @last_method = __method__

        case reference
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {}, :test => true)
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:error => FAILURE_MESSAGE },:test => true)
        else
          raise Error, UNSTORE_ERROR_MESSAGE
        end
      end

      private

      def normalize(paysource)
        if paysource.respond_to?(:account_number) && (paysource.try(:number).blank? || paysource.number.blank?)
          paysource.account_number
        elsif paysource.respond_to?(:number)
          paysource.number
        else
          paysource.to_s
        end
      end

      def error_message(paysource)
        if paysource.respond_to?(:account_number)
          CHECK_ERROR_MESSAGE
        elsif paysource.respond_to?(:number)
          ERROR_MESSAGE
        end
      end

      def build_last_request(action, money = nil, paysource = nil, reference = nil, parameters = {})
        JSON.parse({action: action, money: money, paysource: paysource, reference: reference, parameters: parameters}.to_json).to_xml(:indent => 2, :root => :Request)
      end

    end
  end
end
