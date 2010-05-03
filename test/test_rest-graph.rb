
require 'rr'
require 'bacon'

include RR::Adapters::RRMethods
Bacon.summary_on_exit

describe 'test' do
  it 'has got to be right' do
    mock(o = Object.new).to_s{ 'asd' }
    o.to_s.should == 'asd'
  end
end
