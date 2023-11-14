module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class RpoeGateway < Gateway
      DEFAULT_POST_HEADERS = {
        "payapi-provider" => "Orbital",
        "payapi-test" => "true",
        "Content-Type" => "application/json"
      }

      class_attribute :transaction_path, :tokenization_path

      self.test_url = 'https://apiqaa.priceline.com'
      self.live_url = ''
      self.transaction_path = '/pmt/pclnpay'
      self.tokenization_path = '/pmt/tokenization/api/tokenizeCreditCard'

      self.supported_countries = ["US", "CA"]
      self.default_currency = 'USD'
      self.supported_cardtypes = [:visa, :master, :american_express, :discover, :diners_club, :jcb]

      self.homepage_url = ''
      self.display_name = 'RPOE Gateway'

      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options = {})
        requires!(options, :auth_token)
        super
      end

      def purchase(money, payment, options={})
        MultiResponse.run do |r|
          r.process { authorize(money, payment, options) }
          r.process { capture(money, r.authorization, options) }
        end
      end

      def tokenize(tokenize_params)
        commit('tokenize', tokenize_params)
      end

      def authorize(money, payment, options={})
        post = authorize_params(options[:rpoe_authorize] || {})
        commit('pay', post)
      end

      def capture(money, authorization, options={})
        post = capture_params(options[:rpoe_capture] || {})
        commit('capture', post)
      end

      def refund(money, authorization, options={})
        post = refund_params(options[:rpoe_refund] || {})
        commit('refund', post)
      end

      def void(authorization, options={})
        post = {}
        post.merge(void_params(options[:rpoe_void] || {}))

        commit('void', post)
      end

      def verify(credit_card, options={})
        MultiResponse.run(:use_first_response) do |r|
          r.process { authorize(100, credit_card, options) }
          r.process(:ignore_result) { void(r.authorization, options) }
        end
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript
      end

      private

      def tokenize_params(rpoe_tokenize_params)
        RPOE::TokenizationRequest.new(rpoe_tokenize_params).to_json
      end

      def authorize_params(rpoe_authorize_params)
        RPOE::AuthorizationRequest.new(rpoe_authorize_params).to_json
      end

      def capture_params(rpoe_capture_params)
        RPOE::CaptureRequest.new(rpoe_capture_params).to_json
      end

      def void_params(rpoe_void_params)
        RPOE::VoidRequest.new(rpoe_void_params).to_json
      end

      def refund_params(rpoe_refund_params)
        RPOE::RefundRequest.new(rpoe_refund_params).to_json
      end

      def parse(body)
        JSON.parse(body)
      end

      def url(action)
        base_uri = (test? ? test_url : live_url)
        path = (action == 'tokenize' ? self.tokenization_path : self.transaction_path + "/#{action}")

        base_uri + path
      end

      def commit(action, parameters)
        url = url(action)
        response = parse(ssl_post(url, parameters, post_headers))

        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          avs_result: AVSResult.new(code: response.dig('payment_details', 'avs_code')),
          cvv_result: CVVResult.new('M'),
          test: test?,
          error_code: error_code_from(response)
        )
      end

      def post_headers
        DEFAULT_POST_HEADERS.merge!({'pclnAuth' => @options[:auth_token]})
      end

      def success_from(response)
        response.dig('summary', 'response_code') == "100" || response["status"] == "SUCCESS"
      end

      def message_from(response)
        response["error_messages"]
      end

      def authorization_from(response)
        response.dig('summary', 'payment_details', 'payment_method_token')
      end

      def error_code_from(response)
        unless success_from(response)
          # TODO: lookup error code for this response
        end
      end
    end
  end
end
