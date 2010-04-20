require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe GS1::Prefixes do
  before(:all) do
    @product_ean_13 = '0034000004409'
    @book_ean_13 = '9780470043066'
    @coupon_ean_13 = '0570734110332'
  end

  it "should know about products" do
    GS1::Prefixes.product?(@product_ean_13).should == true
  end

  it "should know about countries" do
    GS1::Prefixes.ean_to_country(@product_ean_13).should == :us
  end

  it "should know about books" do
    GS1::Prefixes.book?(@product_ean_13).should == false
    GS1::Prefixes.book?(@book_ean_13).should == true
  end

  it "should know about coupons" do
    GS1::Prefixes.coupon?(@product_ean_13).should == false
    GS1::Prefixes.coupon?(@coupon_ean_13).should == true
  end
end
