require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
 
describe "/leads/update.js.rjs" do
  include LeadsHelper
  
  before(:each) do
    login_and_assign
    @lead = Factory(:lead, :id => 42, :user => @current_user, :assignee => Factory(:user))
    assigns[:lead] = @lead
    assigns[:users] = [ @current_user ]
    assigns[:campaigns] = [ Factory(:campaign) ]
    assigns[:lead_status_total] = { :contacted => 1, :converted => 1, :new => 1, :rejected => 1, :other => 1, :all => 5 }
  end
 
  it "no errors: should flip [edit_lead] form when called from lead landing page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads/123"

    render "leads/update.js.rjs"
    response.should_not have_rjs("lead_42")
    response.should include_text('crm.flip_form("edit_lead"')
  end

  it "no errors: should update sidebar when called from lead landing page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads/123"

    render "leads/update.js.rjs"
    response.should have_rjs("sidebar") do |rjs|
      with_tag("div[id=summary]")
    end
    response.should include_text('$("summary").visualEffect("shake"')
  end

  it "no errors: should update sidebar when called from leads index page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads"

    render "leads/update.js.rjs"
    response.should have_rjs("sidebar") do |rjs|
      with_tag("div[id=filters]")
      with_tag("div[id=recently]")
    end
    response.should include_text('$("filters").visualEffect("shake"')
  end

  it "no errors: should update recently viewed items when called outside the leads (i.e. embedded)" do
    request.env["HTTP_REFERER"] = "http://localhost/campaigns/123"

    render "leads/update.js.rjs"
    response.should have_rjs("recently") do |rjs|
      with_tag("div[class=caption]")
    end
  end
 
  it "no errors: should replace [Edit Lead] with lead partial and highligh it when called outside lead landing page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads"

    render "leads/update.js.rjs"
    response.should have_rjs("lead_42") do |rjs|
      with_tag("li[id=lead_42]")
    end
    response.should include_text('$("lead_42").visualEffect("highlight"')
  end
 
  it "errors: should redraw the [edit_lead] form and shake it" do
    @lead.errors.add(:error)

    render "leads/update.js.rjs"
    response.should have_rjs("lead_42") do |rjs|
      with_tag("form[class=edit_lead]")
    end
    response.should include_text('$("lead_42").visualEffect("shake"')
    response.should include_text('focus()')
  end

end