class Postcodes < Application
  provides :xml, :json, :js
  
  def index
    redirect "/postcodes/3070"
  end
  
  def show(id)
    @localities = Locality.find(
      :all,
      :conditions => {:postcode => id}
    )
    render @localities
  end
end