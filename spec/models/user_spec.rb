require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:personas).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "devise modules" do
    it "includes database_authenticatable" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "includes registerable" do
      expect(User.devise_modules).to include(:registerable)
    end

    it "includes recoverable" do
      expect(User.devise_modules).to include(:recoverable)
    end

    it "includes rememberable" do
      expect(User.devise_modules).to include(:rememberable)
    end

    it "includes validatable" do
      expect(User.devise_modules).to include(:validatable)
    end
  end
end
