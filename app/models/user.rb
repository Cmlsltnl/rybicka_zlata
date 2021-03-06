class User < ActiveRecord::Base
  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/
  BASE_CONNECTION_NAME="--base--"

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :omniauthable
         #, :omniauth_providers => [:google_oauth2]
  has_many :identities, -> { order("email ASC") }, class_name: 'User::Identity', dependent: :destroy , inverse_of: :user
  has_many :connections, -> { order("name ASC, email ASC") }, {foreign_key: 'owner_id', dependent: :destroy, inverse_of: :owner}
  has_many :friend_connections, -> { where.not(name: Connection::BASE_CONNECTION_NAME).order("name ASC") }, {class_name: "Connection", foreign_key: 'owner_id'}
  has_many :friends, through: :friend_connections, source: :friend
  has_many :connections_as_friend, -> { order("name ASC, email ASC") }, {class_name: "Connection", foreign_key: 'friend_id'}
  has_many :groups, -> { order("name ASC") }, {dependent: :destroy, inverse_of: :user}

  #wishes where user is author
  has_many :author_wishes,  -> { order("updated_at DESC") }, {class_name: 'Wish::FromAuthor', foreign_key: 'author_id', dependent: :destroy, inverse_of: :author}
  
    
  #has_many :friends, -> { order("name ASC") }, class_name: 'User'
  #has_many :registered_connections, -> { order("name ASC") }, class_name: 'Connection', dependent: :destroy

  after_save :sure_main_identity
  after_save :sure_base_connection

  def displayed_name
    name || email
  end   

  #without connection, user.displayed_name is used
  #with connection watchman-> user , connection.name is used
  def displayed_name_for(watchman)
    conns=watchman.friend_connections.where(friend: self)
    if conns.present?
      conns.first.name
    else
      displayed_name
    end  
  end  

  def anchor
    self.email.parameterize
  end    

  def self.admin
     User.find_by_email("porybny@rybickazlata.cz")
  end  

  def admin?
    (email == "porybny@rybickazlata.cz")
  end  

  #https://www.digitalocean.com/community/tutorials/how-to-configure-devise-and-omniauth-for-your-rails-application
  #inspired from http://sourcey.com/rails-4-omniauth-using-devise-with-twitter-facebook-and-linkedin/
  def self.find_or_create_from_omniauth!(auth, signed_in_resource = nil)
    password = nil
    # Get the identity and user if they exist
    identity = User::Identity.find_for_auth(auth)
    identity = User::Identity.create_from_auth(auth) unless identity.present?

    # If a signed_in_resource is provided it always overrides the existing user
    # to prevent the identity being locked with accidentally created accounts.
    # Note that this may leave zombie accounts (with no associated identity) which
    # can be cleaned up at a later date.
    user = signed_in_resource ? signed_in_resource : identity.user

    if user.blank?
      email=identity.verified_email
      email=identity.email if email.blank?
      user = User.where(:email => email).first if email
    end  
    
    # Create the user if needed
    if user.nil?

      # Get the existing user by email if the provider gives us a verified email.
      # If no verified email was provided we assign a temporary email and ask the
      # user to verify it on the next step via UsersController.finish_signup
      password=Devise.friendly_token[0,20]
      user = User.new(
          name: identity.name,
          #username: auth.info.nickname || auth.uid,
          email: email ? email : identity.temp_email,
          password: password,
          locale: identity.locale||User.new.locale,
          time_zone: identity.time_zone||User.new.time_zone
        )
      user.skip_confirmation!
      unless user.save
        raise "User.not saved: #{user.errors.full_messages}  [#{user.to_json}]"
      end  
      
    end

    # Associate the identity with the user if needed
    if identity.user != user
      identity.user = user
    end
    logger.error("Identity before save:#{identity.to_json}")
    identity.save!
    return user, password
  end

  def base_connection
    connections.base.first
  end  

  #wishes where user is between donees
  def donee_wishes
    dls=DoneeLink.where(connection_id: (connections_as_friend.collect{|c| c.id}) )
    Wish::FromDonee.where(id: (dls.collect {|dl| dl.wish_id}).uniq ).order("updated_at DESC")
  end  

  #wishes where user is between donees
  def donor_wishes
    conns=connections_as_friend-[base_connection]
    dls=DonorLink.where(connection_id: (conns.collect{|c| c.id}) )
    Wish::FromDonor.where(id: (dls.collect {|dl| dl.wish_id}).uniq ).order("updated_at DESC")
  end  


  def is_author_of?(wish)
    wish.is_author?(self)
  end  

  def is_donee_of?(wish)
    wish.is_donee?(self)
  end  

  def is_donor_of?(wish)
    wish.is_donor?(self)
  end  

  def main_identity
    sure_main_identity
    existing_local_idnts=self.identities.where(email: self.email, provider: User::Identity::LOCAL_PROVIDER).order("id ASC")
    if existing_local_idnts.present?
      return existing_local_idnts.first
    else
      return self.identities.where(email: self.email).order("id ASC").first
    end  
  end  
  
  private


    def sure_main_identity
      existing_idnts=self.identities.where(email: self.email)
      if existing_idnts.blank?
        User::Identity.create_for_user!(self)        
      else
        idnt=existing_idnts.first
        if idnt.user != self
          raise "E-mail #{self.email} belongs to user #{idnt.user.id}"
        end  
      end  
    end  


    def sure_base_connection
      if self.base_connection.blank?
        con=Connection.create!(name: Connection::BASE_CONNECTION_NAME, email: self.email, friend: self, owner: self)
      end  
    end  
end
