require "excon"

module HurleyExcon
  VERSION = "0.0.1"
  METHODS = Hash.new do |hash, key|
    key.to_s.upcase
  end

  METHODS.update(
    :get => "GET",
    :head => "HEAD",
    :put => "PUT",
    :post => "POST",
    :patch => "PATCH",
    :options => "OPTIONS",
    :delete => "DELETE",
  )

  class Connection
    def initialize(options = nil)
      @options = options || {}
    end

    def call(request)
      opts = {}
      configure_ssl(opts, request.ssl_options) if request.url.scheme == Hurley::HTTPS
      configure_request(opts, request.options)
      configure_proxy(opts, request.options)

      Hurley::Response.new(request) do |res|
        excon = perform(res, opts)
        res.status_code = excon.status.to_i
        res.header.update(excon.headers)
        body = excon.body.to_s
        res.receive_body(body) if !body.empty?
      end
    end

    def perform(res, options)
      req = res.request

      req_options = {
        :method  => METHODS[req.verb],
        :headers => req.header,
        :response_block => lambda { |chunk, remaining, total|
          res.receive_body(chunk)
        },
      }

      if body = req.body_io
        req_options[:request_block] = lambda do
          body.read(Excon.defaults[:chunk_size]).to_s
        end
      end

      Excon.new(req.url.to_s, options.merge(@options)).request(req_options)
    rescue ::Excon::Errors::SocketError => err
      if err.message =~ /\btimeout\b/
        raise Hurley::Timeout, err
      elsif err.message =~ /\bcertificate\b/
        raise Hurley::SSLError, err
      else
        raise Hurley::ConnectionFailed, err
      end
    rescue ::Excon::Errors::Timeout => err
      raise Hurley::Timeout, err
    end

    def configure_ssl(opts, ssl)
      opts[:ssl_verify_peer] = !ssl.skip_verification?
      opts[:ssl_ca_path] = ssl.ca_path if ssl.ca_path
      opts[:ssl_ca_file] = ssl.ca_file if ssl.ca_file

      opts[:certificate_path] = ssl.client_cert_path if ssl.client_cert_path
      opts[:certificate] = ssl.client_cert if ssl.client_cert

      opts[:private_key] = ssl.private_key if ssl.private_key
      opts[:private_key_path] = ssl.private_key_path if ssl.private_key_path
      opts[:private_key_pass] = ssl.private_key_pass if ssl.private_key_pass

      # https://github.com/geemus/excon/issues/106
      # https://github.com/jruby/jruby-ossl/issues/19
      opts[:nonblock] = false
    end

    def configure_request(opts, options)
      if t = options.timeout
        opts[:read_timeout] = t
        opts[:connect_timeout] = t
        opts[:write_timeout] = t
      end

      if t = options.open_timeout
        opts[:connect_timeout] = t
        opts[:write_timeout] = t
      end
    end

    def configure_proxy(opts, options)
      return unless proxy = options.proxy
      opts[:proxy] = {
        :host => proxy.host,
        :port => proxy.port,
        :scheme => proxy.scheme,
        :user => proxy.user,
        :password => proxy.password,
      }
    end
  end
end
