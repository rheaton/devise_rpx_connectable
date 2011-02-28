require 'spec_helper'

Devise.setup do |config|
  config.rpx_identifier_field = :rpx_identifier
  config.rpx_auto_create_account = true
end

describe Devise::Models::RpxConnectable do
  before do
    User.rpx_identifier_field.should == :rpx_identifier
  end

  describe "instance methods" do
    describe "#rpx_connected?" do
      it "is true for users with rpx_identifier_field present" do
        user = User.new
        user.rpx_identifier = "1"
        user.should be_rpx_connected
      end

      it "is false for users with rpx_identifier_field blank" do
        User.new(:rpx_identifier => "").should_not be_rpx_connected
      end
    end

    describe "#store_rpx_credentials!" do
      let(:user) { User.new }
      let(:rpx_params) { {:identifier => "1facebook", :email => "user1@email.com"} }

      it "sets the rpx_identifier field" do
        user.store_rpx_credentials!(rpx_params)
        user.rpx_identifier.should == "1facebook"
      end

      it "sets the email" do
        user.store_rpx_credentials!(rpx_params)
        user.email.should == "user1@email.com"
      end

      it "when no email passed in it sets email to blank" do
        user.store_rpx_credentials!(:identifier => "1fb")
        user.email.should be_blank
      end

      it "sets password and salt to blank if no password set" do
        user.store_rpx_credentials!(:identifier => "1fb")
        user.password_salt.should be_blank
        user.encrypted_password.should be_blank
      end

      it "doesn't change the password if password is set" do
        user.password_salt = "password_salt"
        user.encrypted_password = "password"
        user.store_rpx_credentials!(:identifier => "1fb")

        user.password_salt.should == "password_salt"
        user.encrypted_password.should == "password"
      end
    end
  end

  describe "class methods" do
    describe ".authenticate_with_rpx" do
      context "when identifier is sent" do
        it "returns the first user with the identifier" do
          user = User.new(:email => "mail1@example.com")
          user.rpx_identifier = "1facebook"
          user.save(:validate => false)

          User.authenticate_with_rpx(:identifier => "1facebook").should == user
        end
      end

      context "when no identifier is sent" do
        it "returns nothing" do
          user = User.new(:email => "mail2@example.com")
          user.rpx_identifier = "1facebook"
          user.save(:validate => false)

          User.authenticate_with_rpx.should be_nil
        end
      end
    end
  end
end
