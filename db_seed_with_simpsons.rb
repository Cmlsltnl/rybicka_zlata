def create_test_user!(attrs={})
  default_email="john.doe@test.com"
  if attrs[:email].blank?
    if attrs[:name].present?
      attrs[:email]=default_email.gsub("john.doe",attrs[:name].parameterize.dasherize.downcase)
    else
      attrs[:email]=default_email
    end
  end
  
  usrs=User.where(email: attrs[:email])  
  if usrs.blank?
    user=User.new({name: "John Doe", email: default_email, password: "my_Password10"}.merge(attrs))
    user.skip_confirmation!
    raise "User not created! #{user.errors.full_messages.join(";")}" unless user.save
    user
  else
    usrs.first
  end  
end

def create_connection_for(user, conn_hash)  
  conn_name=conn_hash[:name]
  conn_email=conn_hash[:email]

  conns= user.connections.where(name: conn_name)
  if conn_email.present? && conns.present?
    conns=conns.select {|conn| conn.email == conn_email}
  end  

  if conns.blank?
     #lets create it 
     conn_email="#{conn_name}@example.com" if conn_email.blank?
     conn=Connection.new(name: conn_name, email: conn_email, owner_id: user.id)
     raise "Connection not created! #{conn.errors.full_messages.join(";")}" unless conn.save
     user.connections.reload
  elsif conns.size != 1
    raise "Ambiguous match for '#{conn_hash[:connection]}' for user '#{user.username}': #{conns.join("\n")}"
  else
    conn=conns.first  
  end  
  conn
end 

marge=create_test_user!(name: "Marge")
homer=create_test_user!(name: "Homer")
bart=create_test_user!(name: "Bart")
lisa=create_test_user!(name: "Lisa")
maggie=create_test_user!(name: "Maggie")

User::Identity.create!(email: "foton@centrum.cz", provider: User::Identity::LOCAL_PROVIDER, user: bart) # so I can use Github to log on Bart :-)
User::Identity.create!(email: "foton.mndp@gmail.com", provider: User::Identity::LOCAL_PROVIDER, user: lisa) # so I can use Google+ to log on Lisa :-)

marge_to_homer_conn=create_connection_for(marge, {name: "Husband", email: homer.email})  
marge_to_lisa_conn=create_connection_for(marge, {name: "Daughter", email: lisa.email})  
marge_to_bart_conn=create_connection_for(marge, {name: "Son", email: bart.email})  

homer_to_marge_conn=create_connection_for(homer, {name: "Wife", email: marge.email})  
homer_to_lisa_conn=create_connection_for(homer, {name: "MiniHer", email: lisa.email})  
homer_to_bart_conn=create_connection_for(homer, {name: "MiniMe", email: bart.email})  

bart_to_lisa_conn=create_connection_for(bart, {name: "Liiiisaaa", email: lisa.email})  
bart_to_homer_conn=create_connection_for(bart, {name: "Dad", email: homer.email})  
bart_to_marge_conn=create_connection_for(bart, {name: "Mom", email: marge.email})  
bart_to_milhouse_conn=create_connection_for(bart, {name: "Milhouse", email: "milhouse@sprignfield.com"})  
bart_to_otto_conn=create_connection_for(bart, {name: "Otto", email: "bus-driver@sprignfield.com"})  
bart_to_burns_conn=create_connection_for(bart, {name: "Burns", email: "chief@sprignfield-powerplant.com"})  
bart_to_fry_conn=create_connection_for(bart, {name: "PJ Fry", email: "fry@planetexpress.com"})  

lisa_to_bart_conn=create_connection_for(lisa, {name: "Misfit", email: "foton@centrum.cz"})  #using second identity of bart
lisa_to_homer_conn=create_connection_for(lisa, {name: "Dad", email: homer.email})  
lisa_to_marge_conn=create_connection_for(lisa, {name: "Mom", email: marge.email})  
lisa_to_allison_conn=create_connection_for(lisa, {name: "Allison Taylor"})  
lisa_to_ralph_conn=create_connection_for(lisa, {name: "Ralph Wiggum"})  

bart_family=Group.create!(name: "Simpsons", user: bart, connections: [bart_to_homer_conn, bart_to_marge_conn, bart_to_lisa_conn])
bart_friends=Group.create!(name: "Friends", user: bart, connections: [bart_to_milhouse_conn, bart_to_fry_conn, bart_to_otto_conn])

lisa_family=Group.create!(name: "Family", user: lisa, connections: [lisa_to_bart_conn, lisa_to_homer_conn, lisa_to_marge_conn])
lisa_friends=Group.create!(name: "Friends", user: lisa, connections: [lisa_to_allison_conn, lisa_to_ralph_conn])

wish_marge=Wish::FromAuthor.new(
  author: marge, 
  title: "M: Taller hairs ", 
  description: "And deep bluish too! See https://www.google.cz/search?q=marge+hair&client=ubuntu&hs=Dpl&channel=fs&tbm=isch&tbo=u&source=univ&sa=X&ved=0ahUKEwij3oqq8L_LAhWCYpoKHd2mD8kQsAQIGw&biw=1109&bih=663  (Donors: M:Lisa)" 
)
wish_marge.merge_donor_conn_ids([marge_to_lisa_conn.id], marge)
wish_marge.save!  

wish_marge_homer=Wish::FromAuthor.new(
  author: marge, 
  title: "M+H: Your parents on holiday", 
  description: "Nice holiday without children. (Donors: M:Lisa, H:Bart)",
  donee_conn_ids: [marge_to_homer_conn.id] #marge is added automagically as author
)
wish_marge_homer.merge_donor_conn_ids([marge_to_lisa_conn.id], marge)
wish_marge_homer.save!  
wish_marge_homer.merge_donor_conn_ids([homer_to_bart_conn.id], homer)
wish_marge_homer.save!  

wish_bart=Wish::FromAuthor.new(
  author: bart, 
  title: "B: New faster skateboard", 
  description: "The old one is slooooooooooooow! (Donors: B:Lisa, B:Marge, B:Homer )"
)
wish_bart.merge_donor_conn_ids([bart_to_lisa_conn.id, bart_to_homer_conn.id, bart_to_marge_conn.id], bart)
wish_bart.save! 


w=Wish::FromAuthor.new(author: lisa, title: "L+B: Bigger family car", description: "If you want us to go with You (Donors: L:Marge, L:Homer )")
w.donee_conn_ids=[lisa_to_bart_conn.id]
w.merge_donor_conn_ids([lisa_to_marge_conn.id, lisa_to_homer_conn.id], lisa)
w.save

w=Wish::FromAuthor.new(author: bart, title: "bart wish (shown only to homer)", description: "Motorbike, HD Electra Glide ideally ( http://www.autoevolution.com/news/2015-harley-davidson-electra-glide-ultra-classic-low-rumored-85470.html ). bart is donee, homer is donor")
w.merge_donor_conn_ids([bart_to_homer_conn.id], bart)
w.save

w=Wish::FromAuthor.new(author: lisa, title: "lisa wish (shown only to bart)", description: "Tatoo at my spine! Parents will not allow it. lisa is donee, bart is donor")
w.merge_donor_conn_ids([lisa_to_bart_conn.id], lisa)
w.save
