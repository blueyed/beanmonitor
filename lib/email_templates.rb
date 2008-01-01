class EmailTemplates
  def self.admin_template
    tpl = <<-EOF
      Subject: user_beancounters failure detected
      
      The following uids / counters have had a failcount since the last email
      I sent to you:
      <% failures.each do |uid,counters| %>
      UID: <%= uid %>
        <% counters.each do |name,diff| %>
        - <%= name %> (<%= diff %>)
        <% end %>
      <% end %>
      Bye!
    EOF
    return tpl.gsub(/^      /, '')
  end
  
  def self.user_template
    tpl = <<-EOF
      Subject: user_beancounters failure detected
    
      Your server has had resouce problems on the following counters since my
      last email:
      <% counters.each do |name,diff| %>
      - <%= name %> (<%= diff %>)
      <% end %>
      Bye!
    EOF
    return tpl.gsub(/^      /, '')
  end
end