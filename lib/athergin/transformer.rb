class Transformer
  extend Attribute
  attr_reader :maps
  attribute :defaults, :reduce, :database

  def initialize(name)
    @maps, @reduce = [], []
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

  def map(hash)
    raise 'Please specify collection for Transformer map' if hash[:collection].nil?
    raise 'Please specify values for Transformer map' if hash[:values].nil?
    @maps.push hash
  end

  def sum(field)
    "+= value.#{ field } ? value.#{ field } : 0"
  end

  def mongodb_map_functions
    erb = File.read('mapreduce/mongodb_map.js.erb')
    maps.map do |map|
      database, collection = map[:collection].split('/')
      function = Erubis::Eruby.new(erb).result keys: map[:keys], values: map[:values]
      [database,collection,function]
    end
  end

  def mongodb_reduce_function
    erb = File.read('mapreduce/mongodb_reduce.js.erb')
    Erubis::Eruby.new(erb).result defaults: defaults, fields: reduce
  end

  def run_mapreduce
    puts "Dropping collection #{ Platform.database_name(database) }/#{ collection }"
    Platform.database(database.to_s)[collection.to_s].drop

    mongodb_map_functions.each do |map_database,map_collection,mongodb_map_function|
      puts "Loading #{ Platform.database_name(database.to_s) }/#{ collection } from #{ Platform.database_name(map_database) }/#{ map_collection }"
      Platform.database(map_database)[map_collection].map_reduce mongodb_map_function,
                                                                 mongodb_reduce_function,
                                                                 out: { reduce: collection.to_s, db: Platform.database_name(database.to_s) }
    end

    true
  end
end
