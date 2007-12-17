require File.dirname(__FILE__) + '/../spec_helper'

require "merb/session/cookie_store"

class Merb::Controller
  include ::Merb::SessionMixin
end

class TestCookieSessionController < Merb::Controller
  
  def change
    session[:hello] = 'world'
  end
  
  def no_change
    "test"
  end
  
end

Merb::Server.config[:session_secret_key] = 'Secret!'

describe Merb::SessionMixin do
  it "should set the cookie if the cookie is changed" do
    c = new_controller( 'change', TestCookieSessionController)
    c.dispatch(:change)
    c.headers['Set-Cookie'].should =~ %r{_session_id=} # this could be better
  end
end

describe Merb::CookieStore do
  
  before(:each) do
    @secret = 'Keep it secret; keep it safe.'
    @cookies = { 
      :empty => ['BAgw--0686dcaccc01040f4bd4f35fe160afe9bc04c330', {}],
      :a_one => ['BAh7BiIGYWkG--5689059497d7f122a7119f171aef81dcfd807fec', { 'a' => 1 }],
      :typical => ['BAh7ByIMdXNlcl9pZGkBeyIKZmxhc2h7BiILbm90aWNlIgxIZXkgbm93--9d20154623b9eeea05c62ab819be0e2483238759', { 'user_id' => 123, 'flash' => { 'notice' => 'Hey now' }}],
      :flashed => ['BAh7ByIMdXNlcl9pZGkBeyIKZmxhc2h7AA%3D%3D--bf9785a666d3c4ac09f7fe3353496b437546cfbf', { 'user_id' => 123, 'flash' => {} }] 
    }
  end

  it "should raise argument error if missing secret key" do
    lambda { Merb::CookieStore.new(nil, nil) }.should raise_error(ArgumentError)
  end
  
  it "should restore and unmarshal good cookies" do
    @cookies.values_at(:empty, :a_one, :typical).each do |value, expected|
      session = Merb::CookieStore.new(value, @secret)
      session['lazy loads the data hash'].should be_nil
      session.data.should == expected
    end
  end
  
  it "should raise error on tampered cookie" do
    lambda { Merb::CookieStore.new('a--b', @secret) }.should 
      raise_error(Merb::CookieStore::TamperedWithCookie)
  end
  
  it "should raise when data overflows" do
    session =  Merb::CookieStore.new(@cookies[:empty].first, @secret)
    session['overflow'] = 'bye!' * 1024
    lambda { session.read_cookie }.should 
      raise_error(Merb::CookieStore::CookieOverflow)
  end

  it "should delete entries in the session" do
    session = Merb::CookieStore.new(@cookies[:a_one].first, @secret)
    session.delete('a').should == 1
  end
  
end