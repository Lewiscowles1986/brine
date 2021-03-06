##
# @file client_building.rb
# Construct a Faraday connection.
##

module Brine

  ##
  # Allow construction of a Faraday connection with some common middleware.
  ##
  module ClientBuilding
    require 'oauth2'

    ##
    # Define OAuth2 middleware configuration.
    #
    # This is essentially a thin wrapper around `https://github.com/oauth-xx/oauth2`
    # to provide a mini-DSL and to facilitate the middleware configuration.
    ##
    class OAuth2Params

      ##
      # Store the token which has been retrieved from the authorization server.
      ##
      attr_accessor :token

      ##
      # Specify the type of OAuth2 token which will be retrieved.
      #
      # Currently only `bearer` is supported.
      ##
      attr_accessor :token_type

      ##
      # Instantiate a new object with default attributes.
      ##
      def initialize
        @token_type = 'bearer'
      end

      ##
      # Fetch an OAuth2 token based on configuration and store as `token`.
      #
      # The parameters are forwarded to OAuth2::Client.new which is used to
      # retrieve the token.
      #
      # @param id [String] Provide the login id credential with which to request authorization.
      # @param secret [String] Provide the secret credential with which to request authorization.
      # @param opts [Hash] Define options with which to create a client,
      #                    see `https://github.com/oauth-xx/oauth2/blob/master/lib/oauth2/client.rb` for full details,
      #                    common options will be duplicated here.
      # @option opts [String] :site Specify the OAuth2 authorization server from which to request a token.
      # @option opts [String] :token_url Specify the absolute or relative path to the Token endpoint on the authorization server.
      # @option opts [Hash] :ssl Provide SSL options to pass through to the transport client,
      #                     `{verify: false}` may be useful for self-signed certificates.
      ##
      def fetch_from(id, secret, opts)
        @token = OAuth2::Client.new(id, secret, opts)
          .client_credentials.get_token.token
      end
    end

    ##
    # Acquire an OAuth2 token with the provided configuration block.
    #
    # @param [Block] Provide logic to execute with an OAuth2Params receiver;
    #                this will normally involve an OAuth2Params#fetch_from call.
    ##
    def use_oauth2_token(&block)
      @oauth2 = OAuth2Params.new
      @oauth2.instance_eval(&block)
    end

    ##
    # Expose the handlers/middleware that will be wired while constructing a client.
    #
    # This is represented as list of functions so that it can be more easily customized for
    # unexpected use cases.
    # It should likely be broken up a bit more sensibly and more useful insertion commands added...
    # but it's likely enough of a power feature and platform specific to leave pretty raw.
    ##
    def connection_handlers
      @connection_handlers ||= [
        proc do |conn|
          conn.request :json
          if @oauth2
            conn.request :oauth2, @oauth2.token, :token_type => @oauth2.token_type
          end
        end,
        proc do |conn|
          if @logging
            conn.response :logger, nil, :bodies => (@logging.casecmp('DEBUG') == 0)
          end
          conn.response :json, :content_type => /\bjson$/
        end,
        proc{|conn| conn.adapter Faraday.default_adapter }
      ]
    end

    ##
    # Return a client which will send requests to `host`.
    #
    # This will configure the client using `#connection_handlers`.
    #
    # @param host [String] Specify the hostname to which this client will send requests.
    # @param logging [String] Indicate the desired logging level for this client.
    # @return [Faraday::Connection] Return the configured client connection.
    ##
    def client_for_host(host, logging: ENV['BRINE_LOG_HTTP'])
      @logging = logging
      Faraday.new(host) do |conn|
        connection_handlers.each{|h| h.call(conn) }
      end
    end

  end

  ##
  # Mix the ClientBuilding module functionality into the main Brine module.
  ##
  include ClientBuilding

end
