require 'test_helper'
require File.expand_path(File.dirname(__FILE__) + '/../../../../lib/active_merchant/billing/gateways/orbital/orbital_soft_descriptors')

class OrbitalSoftDescriptorsTest < Test::Unit::TestCase
  def test_valid_pns_descriptors
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("000002000001", "XYZ Corporation")
    assert soft_descriptors.valid?
  end

  def test_valid_salem_descriptors
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "XYZ", :product_description => "Weebles")
    assert soft_descriptors.valid?
  end

  def test_invalid_merchant_id
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("", "")
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:merchant_id], ["is required and must be either 6 or 12 digits"]

    soft_descriptors.merchant_id = "123"
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:merchant_id], ["is required and must be either 6 or 12 digits"]

    soft_descriptors.merchant_id = "123ABC"
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:merchant_id], ["is required and must be either 6 or 12 digits"]
  end

  def test_missing_merchant_name
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "")
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:merchant_name], ["is required"]
  end

  def test_invalid_pns_merchant_name
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("111222123456", "One really long merchant name")
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:merchant_name], ["is required to be 25 bytes or less"]
  end

  def test_invalid_salem_merchant_name
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "Fail")
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:merchant_name], ["must be either 3, 7, or 12 bytes"]
  end

  def test_valid_salem_product_description
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "Merchan", :product_description => "valid")
    assert soft_descriptors.valid?
  end

  def test_missing_salem_product_description
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "Merchan")
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:product_description], ["is required"]
  end

  def test_invalid_salem_product_description
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "XYZ", :product_description => "Super Duper Long Product Description")
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:product_description], ["is required to be 1 to 18 bytes"]

    soft_descriptors.merchant_name = "Merchan"
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:product_description], ["is required to be 1 to 14 bytes"]

    soft_descriptors.merchant_name = "Merchant 123"
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:product_description], ["is required to be 1 to 9 bytes"]
  end

  def test_merchant_phone
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "Merchan", :product_description => "valid")
    assert soft_descriptors.valid?

    soft_descriptors.merchant_phone = "555-234-1224"
    assert soft_descriptors.valid?

    soft_descriptors.merchant_phone = "555-2341224"
    assert soft_descriptors.valid?

    soft_descriptors.merchant_phone = "5552341224"
    assert !soft_descriptors.valid?
    assert_equal soft_descriptors.errors[:merchant_phone], ["is required to follow \"NNN-NNN-NNNN\" or \"NNN-AAAAAAA\" format"]
  end

  def test_merchant_email
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "Merchan", :product_description => "valid")
    assert soft_descriptors.valid?

    soft_descriptors.merchant_email = "moo@cow.com"
    assert soft_descriptors.valid?

    soft_descriptors.merchant_email = "really@only13allowed.com"
    assert !soft_descriptors.valid?
    assert soft_descriptors.errors[:merchant_email], ["is required to be 13 bytes or less"]
  end

  def test_merchant_url
    soft_descriptors = ActiveMerchant::Billing::OrbitalSoftDescriptors.new("123456", "Merchan", :product_description => "valid")
    assert soft_descriptors.valid?

    soft_descriptors.merchant_email = "www.cow.com"
    assert soft_descriptors.valid?

    soft_descriptors.merchant_email = "www.only13allowed.com"
    assert !soft_descriptors.valid?
    assert soft_descriptors.errors[:merchant_url], ["is required to be 13 bytes or less"]
  end
end
