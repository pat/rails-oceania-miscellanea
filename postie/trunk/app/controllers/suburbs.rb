class Suburbs < Application
  provides :xml, :json, :js
  
  def index
    render
  end
  
  def show(id)
    @localities = Locality.find(
      :all,
      :conditions => "suburb LIKE '%#{unescape(id)}%'"
    )
    render @localities
  end
end