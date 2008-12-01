require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Participant do
  it "should add a digit to the name on create if the name is already taken" do
    participant = mock(Participant)
    participant.stub!(:name).and_return("taken")
    Participant.stub!(:find).and_return([participant], nil)

    created = Participant.create(:username => "taken", :name => "taken")
    created.name.should == "taken 1"
  end

  it "should increment the digit on the name on create if the name is already taken" do
    p1 = mock(Participant)
    p1.stub!(:name).and_return("taken")

    p2 = mock(Participant)
    p2.stub!(:name).and_return("taken 1")

    Participant.stub!(:find).and_return([p1], [p2], nil)

    created = Participant.create(:username => "taken", :name => "taken")
    created.name.should == "taken 2"
  end

  it "should increment the digit properly if it's over 9" do
    p1 = mock(Participant)
    p1.stub!(:name).and_return("taken 9")

    p2 = mock(Participant)
    p2.stub!(:name).and_return("taken 10")

    Participant.stub!(:find).and_return([p1], [p2], nil)

    created = Participant.create(:username => "taken", :name => "taken 9")
    created.name.should == "taken 11"
  end

  it "should increment the digit properly regardless of case" do
    p1 = mock(Participant)
    p1.stub!(:name).and_return("Taken")

    Participant.stub!(:find).and_return([p1], nil)

    created = Participant.create(:username => "taken", :name => "taken")
    created.name.should == "taken 1"
  end
end
