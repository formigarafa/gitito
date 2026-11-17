class User < ApplicationRecord
  # Devise appended this pepper to passwords before hashing them. It is only
  # used to recognise digests created before the move to has_secure_password.
  DEVISE_PEPPER = %w[
    eca9c1d94fac7006211e41b5e7cc6f3f63e370dbf498b21e23a2a52b404334ad9f6a85a75
    0e9716a78292575bb8cdd8e9e4139bc06054cf20ec54aba135cc98a
  ].join

  has_secure_password reset_token: { expires_in: 2.hours }

  normalizes :email, with: ->(email) { email.strip.downcase }

  # The username is the folder of the user's repositories, so two users cannot
  # share one and it cannot point outside the repositories root.
  validates :username, presence: true, format: { with: /\A[a-zA-Z0-9\-_.]*\z/ },
    uniqueness: true, exclusion: { in: %w[. ..] }
  validates :email, presence: true, uniqueness: true, format: { with: /\A[^@\s]+@[^@\s]+\z/, allow_blank: true }
  validates :password, length: { minimum: 6 }, allow_nil: true

  has_many :sessions, dependent: :destroy
  has_many :user_credentials, dependent: :destroy
  has_many :repositories, dependent: :restrict_with_error
  has_many :collaborative_relations, dependent: :destroy, class_name: "Collaborator"

  # Accepts passwords hashed by Devise too, rehashing them without the pepper
  # the first time they are used.
  def authenticate_password(unencrypted_password)
    return self if super
    return false unless super("#{unencrypted_password}#{DEVISE_PEPPER}")

    self.password = unencrypted_password
    save!(validate: false)
    self
  end
  alias_method :authenticate, :authenticate_password

  def track_sign_in(ip_address)
    now = Time.current
    update_columns(
      sign_in_count: sign_in_count.to_i + 1,
      last_sign_in_at: current_sign_in_at || now,
      last_sign_in_ip: current_sign_in_ip || ip_address,
      current_sign_in_at: now,
      current_sign_in_ip: ip_address,
    )
  end

  def gravatar_url
    hash = Digest::MD5.hexdigest(email)
    "http://www.gravatar.com/avatar/#{hash}"
  end
end
