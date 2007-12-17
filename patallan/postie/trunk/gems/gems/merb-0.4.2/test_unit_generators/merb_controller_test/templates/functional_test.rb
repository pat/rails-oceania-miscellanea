require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
class <%= class_name.pluralize %>; def rescue_action(e) raise e end; end

class <%= class_name.pluralize %>Test < Test::Unit::TestCase

  def setup
    @controller = <%= class_name.pluralize %>.build(fake_request)
    @controller.dispatch('index')
  end

  # Replace this with your real tests.
  def test_should_be_setup
    assert false
  end
end