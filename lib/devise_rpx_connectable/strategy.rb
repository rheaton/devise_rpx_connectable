# encoding: utf-8

module Devise #:nodoc:
  module RpxConnectable #:nodoc:
    module Strategies #:nodoc:

      # Default strategy for signing in a user using RPX.
      # Redirects to sign_in page if it's not authenticated
      #
      class RpxConnectable < ::Devise::Strategies::Base

        def valid?
          valid_controller? && valid_params? && mapping.to.respond_to?('authenticate_with_rpx')
        end

        # Authenticate user with RPX.
        #
        def authenticate!
          klass = mapping.to
          raise StandardError, "RPXNow API key is not defined, please see the documentation of RPXNow gem to setup it." unless RPXNow.api_key.present?
          begin
            rpx_user = (RPXNow.user_data(params[:token], :extended => klass.rpx_extended_user_data, :additional => klass.rpx_additional_user_data) rescue nil)
            fail!(:rpx_invalid) and return unless rpx_user

            identifier = rpx_user["identifier"]
            primary_key = rpx_user["primaryKey"]
            verified_email = rpx_user["verifiedEmail"]

            user_data = {:identifier => identifier}
            if Devise.rpx_use_mapping
              user_data.merge!(:verifiedEmail => verified_email) if verified_email.present?
              user_data.merge!(:primaryKey => primary_key) if primary_key.present?
            end

            if user = klass.authenticate_with_rpx(user_data)
              user.on_before_rpx_success(rpx_user)
              success!(user)
              map_identifier(user, identifier) unless primary_key
              return
            end

            fail!(:rpx_invalid) and return unless klass.rpx_auto_create_account?

            user = klass.new
            user.store_rpx_credentials!(:email => verified_email || rpx_user["email"], :identifier => identifier)
            user.on_before_rpx_auto_create(rpx_user)

            user.save(:validate => false)
            user.on_before_rpx_success(rpx_user)
            map_identifier(user, identifier)
            success!(user)

          rescue
            fail!(:rpx_invalid)
          end
        end

        protected
        def valid_controller?
          params[:controller].to_s =~ /sessions/
        end

        def valid_params?
          params[:token].present?
        end

        private
        def map_identifier(user, identifier)
          RPXNow.map(identifier, user.id) if Devise.rpx_use_mapping
        end
      end
    end
  end
end

