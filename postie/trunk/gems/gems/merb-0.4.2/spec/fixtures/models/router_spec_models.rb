class Blogposts
  def to_param
    id
  end 
  def id
    42
  end
end     

class Comment
  def to_param
    id
  end 
  def id
    24
  end
  def blogpost_id
    42
  end  
end
