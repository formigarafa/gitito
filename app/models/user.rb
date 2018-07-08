class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  validates :username, presence: true, format: {with: /\A[a-zA-Z0-9\-_.]*\z/}

  has_many :user_credentials, dependent: :destroy
  has_many :repositories, dependent: :restrict_with_error
  has_many :collaborative_relations, dependent: :destroy, class_name: "Collaborator"

  def gravatar_url
    hash = Digest::MD5.hexdigest(email)
    "http://www.gravatar.com/avatar/#{hash}"
  end
end
