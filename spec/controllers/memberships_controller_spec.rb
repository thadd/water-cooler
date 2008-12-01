require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MembershipsController do
  before(:each) do
    @me = mock(Participant)
    controller.stub!(:whoami).and_return(@me)
  end

  it "should get all the memberships for the current chat room" do
    memberships = Array.new
    4.times do |i|
      memberships << mock("Membership-#{i}")
    end

    Membership.should_receive(:find).and_return(memberships)

    xhr :get, :index, :chat_room => 1

    response.should render_template("memberships/_member_list")
    assigns[:memberships].should == memberships
  end

  it "should delete a membership" do
    memb = mock(Membership)

    Membership.should_receive(:find).and_return(memb)

    memb.should_receive(:destroy)

    xhr :delete, :destroy, :id => 1

    response.should redirect_to(:controller => :chat_rooms, :action => :index)
    assigns[:membership].should == memb
  end

end
