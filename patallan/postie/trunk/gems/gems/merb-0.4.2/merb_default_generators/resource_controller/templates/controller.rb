<% klass = class_name.singularize -%>
<% ivar = class_name.snake_case.singularize -%>
class <%= class_name %> < Application
  provides :xml, :js, :yaml

  def index
    render
  end
  
  def show
    render
  end
  
  def new
    render
  end
  
  def edit
    render
  end
  
  def create
  end
  
  def update
  end
  
  def destroy
  end
end