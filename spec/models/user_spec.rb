# frozen_string_literal: true

require "spec_helper"

describe User do
  def valid_user
    User.new username: "N4m3_W1th-V4l1d.Ch4r", email: "anyone@somedomain.com", password: "1qaz2wsx"
  end

  context "validity" do
    it "validates with valid attributes" do
      expect(valid_user).to be_valid
    end

    it "validates with matching password_confirmation" do
      user = valid_user
      user.password = "p4ssw0rd"
      user.password_confirmation = "p4ssw0rd"
      expect(user).to be_valid
    end

    it "fails with no username" do
      user = valid_user
      user.username = nil
      expect(user).to_not be_valid
    end

    it "fails with no email" do
      user = valid_user
      user.email = nil
      expect(user).to_not be_valid
    end

    it "fails with no password" do
      user = valid_user
      user.password = nil
      expect(user).to_not be_valid
    end

    it "fails when password does not match password_confirmation" do
      user = valid_user
      user.password = "1qaz2wsx"
      user.password_confirmation = "0okm9ijn"
      expect(user).to_not be_valid
    end

    it "fails with complicated username (special characters)" do
      user = valid_user
      user.username = "f*cking_user"
      expect(user).to_not be_valid
    end

    it "fails with spaces on username" do
      user = valid_user
      user.username = "some user name"
      expect(user).to_not be_valid
    end
  end

  context "being destroyed" do
    it "destroys its credentials"
    it "destroys collaborative presence on third party repositories"
    it "destroys its repositories" # think about it...
  end

  it "has relations with collaborative repositories"
  it "generates gravatar url from user email"
end
