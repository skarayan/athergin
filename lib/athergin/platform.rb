# todo: module Athergin
module Platform
  class << self
    attr_reader :config, :connections, :namespaces, :eval_queue

    def load_config!(config_file='config/environment.yml')
      @config = Configuration.new config_file
    end

    def connect!
      @connections = {}
      config.environments.each do |env|
        database = config.database_config env
        begin
          pool_size, pool_timeout = database.pool_size || 50, database.pool_timeout || 60
          if database.hosts.present?
            @connections[env] = Mongo::ReplSetConnection.new database.hosts, pool_size: pool_size, pool_timeout: pool_timeout
          else
            @connections[env] = Mongo::Connection.new database.hostname, database.port, pool_size: pool_size, pool_timeout: pool_timeout
          end
        rescue Mongo::ConnectionFailure => e
          warn "Warning (could not connect to the #{ env } environment, skipping): #{ e.message }"
        end
      end
    end

    def namespace(name, opts={}, &block)
      file_execution_order = namespace_display_order = opts[:display_order] || 10_000

      @namespaces = {} if @namespaces.nil?
      @namespaces[name] = Namespace.new(name, namespace_display_order) if @namespaces[name].nil?

      @eval_queue = [] if @eval_queue.nil?
      @eval_queue << [file_execution_order, @namespaces[name], block]
    end

    # execute the files in the right order as specified in the reports directory (for display order in index page and menu)
    def run_eval_queue!
      eval_queue.sort { |a,b| a.first <=> b.first }.each do |file_execution_order,namespace,block|
        namespace.instance_eval &block
      end
    end

    def params
      Thread.current[:params]
    end

    def search_params
      (params[:search] || {}).reject { |param,value| value.blank? }
    end

    def exact_match?
      params[:exact_match].present?
    end

    def query_limit
      params[:limit]
    end

    def query_offset
      params[:offset]
    end

    def cookies
      Thread.current[:cookies] || {}
    end

    def environment
      @environment || cookies['environment'].try(:to_sym) || ENV['REPORTS_ENV'].try(:to_sym) || :development
    end

    def set_environment!(env)
      puts "Setting environment as #{ env }"
      @environment = env.to_sym
    end

    def connected_environments
      # todo: reverse is kind of ugly here
      @connections.keys.reverse rescue []
    end

    def connection
      @connections[environment]
    end

    def database_name(name)
      database_name = Platform.config.database_override.try(name) || name
    end

    def database(name)
      Platform.connection[database_name(name)]
    end

    def current_namespace
      current_report.try(:namespace)
    end

    def current_report
      return unless params[:type].eql? 'reports'
      Report.find_by_name params[:name]
    end

    def current_query
      return unless params[:type].eql? 'queries'
      Query.find_by_name params[:name]
    end
  end
end
