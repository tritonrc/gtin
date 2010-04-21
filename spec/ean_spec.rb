require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe EAN do
  before(:all) do
    @reese_pbc_upc_e = '03444009'
    @reese_pbc_upc_a = '034000004409'
    @reese_pbc_ean_13 = '0034000004409'
    @power_gln = '0890552001002'
    @my_gln = '9557891000004'
    @gtin_14 = '00614141453245'
  end

  it "should convert ean-13 to upc-a" do
    EAN.to_upc(@reese_pbc_ean_13).should == @reese_pbc_upc_a
  end

  it "should expand an upc-e into an upc-a" do
    EAN.to_upc(EAN.expand_upc_e(@reese_pbc_upc_e)).should == @reese_pbc_upc_a
  end

  it "should compute an upc-a check-digit properly" do
    EAN.compute_check_digit(@reese_pbc_upc_a[0..-2]).should == @reese_pbc_upc_a[-1..-1].to_i
  end

  it "should compute an upc-e check-digit properly" do
    EAN.compute_check_digit(@reese_pbc_upc_e[0..-2]).should == @reese_pbc_upc_e[-1..-1].to_i
  end

  it "should find the following barcodes valid" do
    valids = [@reese_pbc_upc_e, @reese_pbc_upc_a, @reese_pbc_ean_13, @power_gln, @my_gln].map { |upc| EAN.valid?(upc) }
    valids.should == [true, true, true, true, true]
  end

  it "should compute ean-13 check-digits properly" do
    EAN.compute_check_digit(@my_gln[0..-2]).should == @my_gln[-1..-1].to_i
    EAN.compute_check_digit(@power_gln[0..-2]).should == @power_gln[-1..-1].to_i
  end

  it "should compute gtin-14 check-digits properly" do
    EAN.compute_check_digit(@gtin_14[0..-2]).should == @gtin_14[-1..-1].to_i
  end
end
