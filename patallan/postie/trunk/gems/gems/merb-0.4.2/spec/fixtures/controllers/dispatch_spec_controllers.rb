class Foo < Merb::Controller

  def index
    "index"
  end
  
  def bar
    "bar"
  end
  
  def error
    raise AdminAccessRequired
    "Hello World!"
  end
  
  def raise404
    raise NotFound
  end
end

class Bar < Merb::Controller
  
  def foo(id)
    id
  end
  
  def bar(a, b = "2")
    "#{a} #{b}"
  end
  
  def baz(a, b = "2", c = "3")
    "#{a} #{b} #{c}"
  end
  
end

class Baz < Merb::Controller
  
  def index
  end
  
end

class Bat < Merb::Controller
end

class AdminAccessRequired < Merb::ControllerExceptions::Unauthorized; end

class Exceptions < Merb::Controller
  def admin_access_required
    "oh no!"
  end
end

class Posts < Merb::Controller
  # GET /posts
  # GET /posts.xml
  def index() :index end
  # GET /posts/1
  # GET /posts/1.xml
  def show() :show end
  # GET /posts/new
  def new() :new end
  # GET /posts/1;edit
  def edit() :edit end
  # POST /posts
  # POST /posts.xml
  def create() :create end
  # PUT /posts/1
  # PUT /posts/1.xml
  def update() :update end
  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy() :destroy end
  # GET /posts/1;stats
  # PUT /posts/1;stats
  def stats() :stats end  
  # GET /posts;filter  
  def filter() :filter end  
end

class As < Merb::Controller
  # GET /as
  # GET /as.xml
  def index() :index end
  # GET /as/1
  # GET /as/1.xml
  def show() :show end
  # GET /as/new
  def new() :new end
  # GET /as/1;edit
  def edit() :edit end
  # POST /as
  # POST /as.xml
  def create() :create end
  # PUT /as/1
  # PUT /as/1.xml
  def update() :update end
  # DELETE /as/1
  # DELETE /as/1.xml
  def destroy() :destroy end 
end

class Bs < Merb::Controller
  # GET /as/1/bs
  # GET /as/1/bs.xml
  def index() :index end
  # GET /as/1/bs/1
  # GET /as/1/bs/1.xml
  def show() :show end
  # GET /as/1/bs/new
  def new() :new end
  # GET /as/1/bs/1;edit
  def edit() :edit end
  # POST /as/1/bs
  # POST /as/1/bs.xml
  def create() :create end
  # PUT /as/1/bs/1
  # PUT /as/1/bs/1.xml
  def update() :update end
  # DELETE /as/1/bs/1
  # DELETE /as/1/bs/1.xml
  def destroy() :destroy end 
end

class Cs < Merb::Controller
  # GET /as/1/bs/1/cs
  # GET /as/1/bs/1/cs.xml
  def index() :index end
  # GET /as/1/bs/1/cs/1
  # GET /as/1/bs/1/cs/1.xml
  def show() :show end
  # GET /as/1/bs/1/cs/new
  def new() :new end
  # GET /as/1/bs/1/cs/1;edit
  def edit() :edit end
  # POST /as/1/bs/1/cs
  # POST /as/1/bs/1/cs.xml
  def create() :create end
  # PUT /as/1/bs/1/cs/1
  # PUT /as/1/bs/1/cs/1.xml
  def update() :update end
  # DELETE /as/1/bs/1/cs/1
  # DELETE /as/1/bs/1/cs/1.xml
  def destroy() :destroy end 
end

class Tags < Merb::Controller
  # GET /tags
  # GET /tags.xml
  def index() :index end
  # GET /tags/1
  # GET /tags/1.xml
  def show() :show end
  # GET /tags/new
  def new() :new end
  # GET /tags/1;edit
  def edit() :edit end
  # POST /tags
  # POST /tags.xml
  def create() :create end
  # PUT /tags/1
  # PUT /tags/1.xml
  def update() :update end
  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy() :destroy end
  # GET /tags/1;stats
  # PUT /tags/1;stats
  def stats() :stats end  
  # GET /tags;filter  
  def filter() :filter end  
end

class Comments < Merb::Controller
  # GET /comments
  # GET /comments.xml
  def index() :index end
  # GET /comments/1
  # GET /comments/1.xml
  def show() :show end
  # GET /comments/new
  def new() :new end
  # GET /comments/1;edit
  def edit() :edit end
  # POST /comments
  # POST /comments.xml
  def create() :create end
  # PUT /comments/1
  # PUT /comments/1.xml
  def update() :update end
  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy() :destroy end
  # GET /comments/1;stats
  # PUT /comments/1;stats
  def stats() :stats end  
end

class Icon < Merb::Controller
  # GET /icon
  # GET /icon.xml
  def show() :show end
  # GET /icon/new
  def new() :new end
  # GET /icon;edit
  def edit() :edit end
  # POST /icon
  # POST /icon.xml
  def create() :create end
  # PUT /icon7
  # PUT /icon.xml
  def update() :update end
  # DELETE /icon
  # DELETE /icon.xml
  def destroy() :destroy end
  # GET /icon;stats
  # PUT /icon;stats
  def stats() :stats end
end  

class Profile < Merb::Controller
  def show() :show end
end

# If this throws an error, it's because parameterized args are somehow borked
Merb::Server.load_application