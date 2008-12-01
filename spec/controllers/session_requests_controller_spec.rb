require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SessionRequestsController do
  before(:each) do
    @me = mock(Participant)
    controller.stub!(:whoami).and_return(@me)
  end

  it "should set the sound session variables" do
    xhr :post, :sounds, :room_sounds => "off", :notification_sounds => "off"

    session[:room_sounds].should == "off"
    session[:notification_sounds].should == "off"

    xhr :post, :sounds, :room_sounds => "on", :notification_sounds => "on"

    session[:room_sounds].should == "on"
    session[:notification_sounds].should == "on"

    response.should render_template("session_requests/sounds")
  end
end
