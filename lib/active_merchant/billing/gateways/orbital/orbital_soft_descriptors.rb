module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class OrbitalSoftDescriptors
      include Validateable

      PHONE_FORMAT_1 = /\A\d{3}-\d{3}-\d{4}\z/
      PHONE_FORMAT_2 = /\A\d{3}-\w{7}\z/

      # ==== Salem Soft Descriptors
      # The Automated Clearing House (ACH) uses two fields to describe the transaction to the consumer.
      # The Merchant Name (15 bytes) will always appear on the consumer’s statement, and the
      # Entry Description (10 bytes) will appear on the consumer’s statement a majority of the time.
      # Both are required fields.
      #
      # Chase Paymentech recommends using the Doing Business As (DBA) description/value in the Merchant Name field
      # and the product information in the Product Description field.
      #
      # When utilizing the Soft Descriptor for ECP transactions, both the Merchant Name and the Product Description are mandatory.
      #
      # ==== Tampa PNS Soft Descriptors
      # The support for Soft Descriptors via the PNS Host is only for customers processing through Chase
      # Paymentech Canada.
      #
      # Unlike Salem, the only value that gets passed on the cardholder statement is the Merchant Name field.
      # And for these customers, it is a maximum of 25 bytes of data.
      #
      # All other Soft Descriptor fields can optionally be sent, but will not be submitted to the settlement host
      # and will not display on the cardholder statement.

      attr_accessor :merchant_id, :merchant_name, :product_description, :merchant_city, :merchant_phone, :merchant_url, :merchant_email

      def initialize(merchant_id, merchant_name, options = {})
        self.merchant_id = merchant_id
        self.merchant_name = merchant_name
        self.merchant_city = options[:merchant_city]
        self.merchant_phone = options[:merchant_phone]
        self.merchant_url = options[:merchant_url]
        self.merchant_email = options[:merchant_email]
        self.product_description = options[:product_description]
      end

      def validate
        unless [6, 12].include?(self.merchant_id.bytesize) && merchant_id =~ /^[0-9]+$/
          errors.add(:merchant_id, "is required and must be either 6 or 12 digits")
        end

        if self.merchant_name.blank?
          errors.add(:merchant_name, "is required")
        elsif self.salem?
          if [3, 7, 12].include?(self.merchant_name.bytesize)
            if self.product_description.blank?
              errors.add(:product_description, "is required")
            else
              case merchant_name.bytesize
                when 3
                  errors.add(:product_description, "is required to be 1 to 18 bytes") if self.product_description.bytesize > 18
                when 7
                  errors.add(:product_description, "is required to be 1 to 14 bytes") if self.product_description.bytesize > 14
                when 12
                  errors.add(:product_description, "is required to be 1 to 9 bytes") if self.product_description.bytesize > 9
              end
            end
          else
            errors.add(:merchant_name, "must be either 3, 7, or 12 bytes")
          end
        elsif self.pns? # Tampa
          errors.add(:merchant_name, "is required to be 25 bytes or less") if self.merchant_name.bytesize > 25
        end

        unless self.merchant_phone.blank? || self.merchant_phone.match(PHONE_FORMAT_1) || self.merchant_phone.match(PHONE_FORMAT_2)
          errors.add(:merchant_phone, "is required to follow \"NNN-NNN-NNNN\" or \"NNN-AAAAAAA\" format")
        end

        [:merchant_email, :merchant_url].each do |attr|
          unless self.send(attr).blank?
            errors.add(attr, "is required to be 13 bytes or less") if self.send(attr).bytesize > 13
          end
        end
      end

      def salem?
        self.merchant_id.size == 6
      end

      def pns?
        self.merchant_id.size == 12
      end

    end
  end
end
