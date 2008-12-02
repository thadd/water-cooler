require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Message do
  it "should load the n most recent messages via the limit scope" do
    all_msg = Array.new
    new_msg = Array.new

    10.times do |i|
      m = Message.new(:content => "Message-#{i}")
      m.stub!(:notify_participants)
      m.save
      all_msg << m
      new_msg << m if i > 4
    end

    Message.limit(5).should == new_msg.reverse
  end
end
