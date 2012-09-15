class Report
  extend Attribute
  attr_reader :queries, :namespace
  attribute :name, :description, :explanation, :search_fields

  def to_h
    methods = [:name, :description, :url, :current?, :css_class_name]
    methods.map do |method|
      key, value = method.to_s.gsub(/\?$/,'').to_sym, send(method)
      value = '' if value.nil?
      value = value.to_data if value.is_a? Array

      [key, value]
    end.to_h
  end

  class << self
    # todo: change this to reports
    def all
      Namespace.all.map(&:report_objects).flatten
    end

    def find_by_name(name)
      all.find { |report| report.name == name.try(:to_sym) }
    end
  end

  def initialize(name,opts={})
    @name = name
    @namespace = opts[:namespace]
    @queries = {}
    @show_all_on_load = false
  end

  # todo: change this to queries
  def query_objects
    queries.values
  end

  def url
    "/reports/#{ name }"
  end

  def query(name, &block)
    warn "warning: overriding query '#{ name }'" if @queries[name]

    @queries[name] = Query.new name
    @queries[name].instance_eval &block
  end

  def show_all_on_load
    @show_all_on_load = true
  end

  def require_search?
    !show_all_on_load?
  end

  def show_all_on_load?
    @show_all_on_load
  end

  def allow_partial_match?
    query_objects.select { |query| query.allow_partial_match? }.present?
  end

  def view_name
    :report
  end

  def current?
    name.eql? Platform.current_report.name
  end

  # todo: think this over, models are probably not a good place for the css class name
  def css_class_name
    current? ? 'active' : 'inactive'
  end
end
