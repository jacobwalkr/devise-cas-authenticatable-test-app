class User < ApplicationRecord
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  devise :trackable, :cas_authenticatable
end
