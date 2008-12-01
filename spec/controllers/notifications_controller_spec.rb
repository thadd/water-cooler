require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NotificationsController do
  before(:each) do
    @me = mock(Participant)
    controller.stub!(:whoami).and_return(@me)
  end

  it "should list the notifications for the supplied user" do
    notes = Array.new
    3.times {|i| notes << mock("Notification-#{i}")}

    Notification.should_receive(:find).with(:all).and_return(notes)

    xhr :get, :index, :participant_id => 1

    assigns[:notifications].should == notes
    response.should render_template("notifications/index")
  end
end

