require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe KeywordsController do
  before(:each) do
    @me = mock(Participant)
    controller.stub!(:whoami).and_return(@me)
  end

  describe "POST requests on :create action" do
    it "should add a new keyword when valid" do
      keywords = mock("keywords")
      keyword = mock(Keyword)

      @me.should_receive(:keywords).and_return(keywords)

      keywords.should_receive(:create).with("text" => "new keyword").and_return(keyword)
      keyword.should_receive(:valid?).and_return(true)

      xhr :post, :create, :keyword => {:text => "new keyword"}

      response.should render_template("keywords/create")
      assigns[:keyword].should == keyword
    end

    it "should not add a new keyword when it is invalid" do
      keywords = mock("keywords")
      keyword = mock(Keyword)

      @me.should_receive(:keywords).and_return(keywords)

      keywords.should_receive(:create).with("text" => "new keyword").and_return(keyword)
      keyword.should_receive(:valid?).and_return(false)

      xhr :post, :create, :keyword => {:text => "new keyword"}

      response.should render_template("keywords/create")
      assigns[:keyword].should be_nil
    end
  end

  describe "DELETE requests on :destroy action" do
    it "should delete a keyword" do
      kw = mock(Keyword)
      Keyword.should_receive(:find).and_return(kw)
      kw.should_receive(:destroy)

      xhr :delete, :destroy, :id => "1"

      response.should render_template("keywords/destroy")
      assigns[:keyword].should == kw
    end
  end
end
