class Query
  extend Attribute
  attribute :name, :description, :explanation, :database, :filters, :fields, :field_groups, :search_mapping
  attr_accessor :partial_search_fields # todo: clean this up
  attr_accessor :results_block, :query_block, :transform_block, :callback_blocks # todo: rename all these *_block attributes to remove the '_block' from the name

  class << self
    # todo: change this to queries
    def all
      Report.all.map(&:query_objects).flatten
    end

    def find_by_name(name)
      all.find { |query| query.name == name.try(:to_sym) }
    end
  end

  def initialize(name)
    @name = name
    @fields = {}
    @search_mapping = {}
    @partial_search_fields = []
    @default_sort_fields = {}
    @filters = {}
    @show_all_on_load = false
    @transform_block = Proc.new { raise 'Please implement the transform block in your query.' }
    @results_block = Proc.new { query.to_a.map { |row| self.instance_exec row, &transform_block } }
    @callback_blocks = {}
  end

  def collection(name=nil)
    if name
      if name.is_a? Symbol
        @collection = name
      elsif name.is_a? String
        db,tbl = name.split('/').map(&:to_sym)
        database db
        collection tbl
      end
    else
      @collection
    end
  end

  # todo: change naming of this method to make it more consistent
  def allow_partial_search_for(*fields)
    @partial_search_fields = fields.map(&:to_sym)
  end

  # todo: refactor to use attribute for consistency
  def limit_results_to(count)
    @limit = count
  end

  def params
    Platform.search_params
  end

  def limit
    Platform.query_limit || @limit || 1000
  end

  def offset
    Platform.query_offset || @offset || 0
  end

  def exact_match
    Platform.exact_match? || @exact_match || false
  end

  def partial_match
    !exact_match
  end

  # todo: remove to_sym (everywhere in code), use hash_with_indifferent_attributes
  def allow_partial_match?(field=nil)
    if field.present?
      partial_match && partial_search_fields.include?(field.to_sym)
    else
      @partial_search_fields.present?
    end
  end

  def where
    params.map do |field,value|
      field = search_mapping[field.to_sym]
      next if field.nil?

      value = /#{ value }/i if allow_partial_match? field
      [field,value]
    end.compact.to_h.merge @filters
  end

  # todo: refactor @filters and @default_sort_fields to method calls
  def query
    return self.instance_eval(&query_block) if query_block

    # todo: add namespace and report name in error message
    raise "No collection specified for '#{ name }'" if collection.nil?
    raise "No database specified for '#{ name }'" if database.nil?

    puts "find: #{ Platform.database_name(database.to_s) }/#{ collection } -> #{ where.inspect }"
    Platform.database(database.to_s)[collection.to_s].find(where).sort(@default_sort_fields).limit(limit).skip(offset)
  end

  def define_query(&block)
    @query_block = block
  end

  def results(&block)
    @results_block = block
  end

  def transform(&block)
    @transform_block = block
  end

  def data
    self.instance_eval &results_block
  end

  # todo: rename for consistensy
  def default_sort_by(sort_fields)
    @default_sort_fields = sort_fields
  end

  # todo: review since it is redundant in both Report and Query
  def show_all_on_load
    @show_all_on_load = true
  end

  def require_search?
    !show_all_on_load?
  end

  def show_all_on_load?
    @show_all_on_load
  end

  def view_name
    :query
  end

  def listen_for(callback,&block)
    @callback_blocks[callback] = block
  end

# todo: cleanup
=begin
  def to_tsv
    results.unshift(self.class.fields).map { |row| row.join("\t") }.join("\n")
  end

  def save(filename)
    File.open(filename, 'w') { |f| f.write to_tsv }
  end

  class << self
    def from(collection_name)
      db,tbl = collection_name.split('/')
      define_singleton_method(:from_database) { db }
      define_singleton_method(:from_collection) { tbl }
    end

    def group_by(field_name)
      define_singleton_method(:group_by_field) { field_name }
    end

    def aggregate(fields)
      define_singleton_method(:aggregate_fields) { fields }
    end

    def javascript_aggregate_map_function
      erb = File.read('mapreduce/aggregate_map.js.erb')
      Erubis::Eruby.new(erb).result group_by: group_by_field, aggregate: aggregate_fields
    end

    def javascript_aggregate_reduce_function
      erb = File.read('mapreduce/aggregate_reduce.js.erb')
      Erubis::Eruby.new(erb).result aggregate: aggregate_fields
    end

    def run
      m, r = javascript_aggregate_map_function, javascript_aggregate_reduce_function
      Platform.database(from_database)[from_collection].map_reduce m, r, out: { replace: collection, db: database }
    end
  end
=end
end
