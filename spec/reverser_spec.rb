require "reverser"

describe Reverser do
  it "should reverse a string" do
    expect(Reverser.reverse "hello").to eq("olleh")
  end
end

