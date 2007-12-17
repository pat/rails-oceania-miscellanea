require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "<%= class_name.pluralize %> Controller", "index action" do
  before(:each) do
    @controller = <%= class_name.pluralize %>.build(fake_request)
    @controller.dispatch('index')
  end
end