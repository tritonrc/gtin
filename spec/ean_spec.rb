require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe EAN do
  before(:all) do
    @reese_pbc_upc_e = '03444009'
    @reese_pbc_upc_a = '034000004409'
    @reese_pbc_ean_13 = '0034000004409'
  end

  it "should convert ean-13 to upc-a" do
    EAN.to_upc(@reese_pbc_ean_13).should == @reese_pbc_upc_a
  end

  it "should expand an upc-e into an upc-a" do
    EAN.to_upc(EAN.expand_upc_e(@reese_pbc_upc_e)).should == @reese_pbc_upc_a
  end

  it "should compute an upc-a check-digit properly" do
    EAN.compute_check_digit(@reese_pbc_upc_a[0..10]).should == @reese_pbc_upc_a[-1..-1].to_i
  end

  it "should compute an upc-e check-digit properly" do
    EAN.compute_check_digit(@reese_pbc_upc_e[0..6]).should == @reese_pbc_upc_e[-1..-1].to_i
  end

  it "should find the following barcodes valid" do
    valids = [@reese_pbc_upc_e, @reese_pbc_upc_a, @reese_pbc_ean_13].map { |upc| EAN.valid?(upc) }
    valids.should == [true, true, true]
  end
end
