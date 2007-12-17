class <%= class_name %> < Application
<% actions.each do |action| -%>
  
  def <%= action %>
    render
  end
<% end -%>
end