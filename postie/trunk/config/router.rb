# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   r.match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   r.match("/books/:book_id/:action").
#     to(:controller => "books")
#   
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   r.match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.

puts "Compiling routes.."
Merb::Router.prepare do |r|
  # RESTful routes
  r.resources :suburbs
  r.resources :postcodes

  # r.default_routes
  
  r.match(%r[^/(\d\d\d\d)(\.(.+))?$]).to(
    :controller => 'postcodes',
    :action     => 'show',
    :id         => '[1]',
    :format     => '[3]'
  )
  r.match(%r[^/([^\.]+)(\.(.+))?$]).to(
    :controller => 'suburbs',
    :action     => 'show',
    :id         => '[1]',
    :format     => '[3]'
  )
  
  # Change this for your home page to be available at /
  r.match('/').to(:controller => 'suburbs', :action => 'index')
end
