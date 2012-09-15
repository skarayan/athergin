class Namespace
  extend Attribute
  attr_reader :reports, :transformers, :display_order
  attribute :name, :description, :explanation

  def to_h
    methods = [:name, :description, :current?, :css_class_name, :report_objects]
    methods.map do |method|
      key, value = method.to_s.gsub(/\?$/,'').to_sym, send(method)
      value = '' if value.nil?
      value = value.to_data if value.is_a? Array

      [key, value]
    end.to_h
  end

  class << self
    def all
      Platform.namespaces.values rescue []
    end

    def displayable
      all.select { |n| n.report_objects.present? }.sort { |a,b| a.display_order <=> b.display_order }
    end

    def find_by_name(name)
      all.find { |namespace| namespace.name == name.try(:to_sym) }
    end
  end

  def initialize(name, display_order)
    @name, @display_order = name, display_order
    @reports = {}
    @transformers = {}
  end

  # todo: change this to reports
  def report_objects
    reports.values
  end

  # todo: change this to transformers
  def transformer_objects
    transformers.values
  end

  def report(name, &block)
    warn "warning: overriding report '#{ name }'" if @reports[name]

    @reports[name] = Report.new name, namespace: self
    @reports[name].instance_eval &block
  end

  def transformer(name, &block)
    warn "warning: overriding transformer '#{ name }'" if @transformers[name]

    @transformers[name] = Transformer.new name
    @transformers[name].instance_eval &block
  end

  def current?
    name.eql? Platform.current_namespace.name
  end

  # todo: think this over, models are probably not a good place for the css class name
  def css_class_name
    current? ? 'active' : 'inactive'
  end
end
