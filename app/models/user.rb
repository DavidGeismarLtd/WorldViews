# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :personas, dependent: :destroy
  has_many :persona_follows, dependent: :destroy
  has_many :followed_personas, through: :persona_follows, source: :persona

  # Helper methods for following personas
  def following?(persona)
    followed_personas.include?(persona)
  end

  def follow(persona)
    followed_personas << persona unless following?(persona)
  end

  def unfollow(persona)
    followed_personas.delete(persona)
  end
end
