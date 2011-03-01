require "spec_helper"

RPXNow.api_key = "abcdefgh"

RPX_USER_DATA = { "identifier" => "superpipo_user" }
PARAMS = { :token => "rpx_token" }

describe 'DeviseRpxConnectable' do
  before(:each) do
    @strategy = Devise::RpxConnectable::Strategies::RpxConnectable.new(:user)
    @mapping = mock(:mapping)
    @mapping.should_receive(:to).and_return(User)
    @strategy.should_receive(:mapping).and_return(@mapping)
    @strategy.should_receive(:params).and_return(PARAMS)

    @user = User.new
  end

  it "should fail if RPX returns no valid user" do
    RPXNow.should_receive(:user_data).and_return(nil)
    @strategy.should_receive(:"fail!").with(:rpx_invalid).and_return(true)

    lambda { @strategy.authenticate! }.should_not raise_error
  end

  describe 'when the RPX user is valid' do
    describe "when config.rpx_use_mapping" do
      before do
        Devise.stub!(:rpx_use_mapping).and_return(true)
      end


      context "the user has authenticated before with the same identifier (returns a primaryKey)" do
        before do
          @user = User.new(:email => "email@user.com")
          @user.save(:validate => false)
          user_params = {:identifier => "user", :primaryKey => @user.id, :verifiedEmail => 'email@user.com'}
          RPXNow.should_receive(:user_data).and_return(HashWithIndifferentAccess.new(user_params))
          User.should_receive(:authenticate_with_rpx).with(user_params).and_return(@user)
        end

        it "authenticates" do
          RPXNow.should_not_receive(:map)
          @strategy.should_receive(:"success!").with(@user).and_return(true)

          lambda { @strategy.authenticate! }.should_not raise_error
        end
      end

      context "the user has authenticated before with a different identifier (returns a verifiedEmail)" do
        before do
          @user = User.new(:email => "email@userfour.com")
          @user.save(:validate => false)
          user_params = {:identifier => "user", :verifiedEmail => 'email@userfour.com'}
          RPXNow.should_receive(:user_data).and_return(HashWithIndifferentAccess.new(user_params))
          User.should_receive(:authenticate_with_rpx).with(user_params).and_return(@user)
        end

        it "maps the identifier to the user's primary key and authenticates" do
          RPXNow.should_receive(:map).with("user", @user.id)
          @strategy.should_receive(:"success!").with(@user).and_return(true)

          lambda { @strategy.authenticate! }.should_not raise_error
        end
      end

      context "the user has never authenticated before" do
        before do
          user_params = {
            :identifier => "userfbid",
            :verifiedEmail => 'email15@user.com'
          }
          RPXNow.should_receive(:user_data).and_return(HashWithIndifferentAccess.new(user_params))
          User.should_receive(:authenticate_with_rpx).with(user_params).and_return(nil)
        end

        it "creates a user and maps the identifier to the user, authenticates" do
          RPXNow.should_receive(:map)
          @strategy.should_receive(:"success!").and_return(true)

          lambda { @strategy.authenticate! }.should change(User, :count).by(1)
        end
      end
    end

    describe "when no config.rpx_use_mapping" do
      before(:each) do
        Devise.stub!(:rpx_use_mapping).and_return(false)
        RPXNow.should_receive(:user_data).and_return(RPX_USER_DATA)
      end


      it "should authenticate if a user exists in database" do
        User.should_receive(:authenticate_with_rpx).with({ :identifier => RPX_USER_DATA["identifier"] }).and_return(@user)
        @user.should_receive(:on_before_rpx_success).with(RPX_USER_DATA).and_return(true)
        @strategy.should_receive(:"success!").with(@user).and_return(true)

        lambda { @strategy.authenticate! }.should_not raise_error
      end

      describe 'when no user exists in database' do
        before(:each) do
          User.should_receive(:authenticate_with_rpx).with({ :identifier => RPX_USER_DATA["identifier"] }).and_return(nil)
        end

        it "should fail unless rpx_auto_create_account" do
          User.should_receive(:"rpx_auto_create_account?").and_return(false)
          @strategy.should_receive(:"fail!").with(:rpx_invalid).and_return(true)

          lambda { @strategy.authenticate! }.should_not raise_error
        end

        it "should create a new user and success if rpx_auto_create_account" do
          User.should_receive(:"rpx_auto_create_account?").and_return(true)
          User.should_receive(:new).and_return(@user)
          @user.should_receive(:"store_rpx_credentials!").with({:identifier => RPX_USER_DATA["identifier"], :email => nil}).and_return(true)
          @user.should_receive(:on_before_rpx_auto_create).with(RPX_USER_DATA).and_return(true)
          @user.should_receive(:save).with({ :validate => false }).and_return(true)
          @user.should_receive(:on_before_rpx_success).with(RPX_USER_DATA).and_return(true)

          @strategy.should_receive(:"success!").with(@user).and_return(true)

          lambda { @strategy.authenticate! }.should_not raise_error
        end
      end
    end
  end
end

