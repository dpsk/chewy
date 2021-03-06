# Test helper class to provide minitest hooks for Chewy::Index testing.
#
# @note Intended to be used in conjunction with a test helper which mocks over the #bulk
#   method on a Chewy::Type class. (See SearchTestHelper)
#
# The class will capture the data from the *param on the Chewy::Type#bulk method and
# aggregate the data for test analysis.
class SearchIndexReceiver
  def initialize
    @mutations = {}
  end

  # @param bulk_params the bulk_params that should be sent to the Chewy::Type#bulk method.
  # @param (Chewy::Type) type the Index::Type executing this query.
  def catch bulk_params, type
    Array.wrap(bulk_params).map {|y| y[:body] }.flatten.each do |update|
      if body = update[:delete]
        mutation_for(type).deletes << body[:_id]
      elsif body = update[:index]
        mutation_for(type).indexes << body
      end
    end
  end

  # @param index return only index requests to the specified Chewy::Type index.
  # @return the index changes captured by the mock.
  def indexes_for index = nil
    if index
      mutation_for(index).indexes
    else
      Hash[
        @mutations.map { |a,b| [a, b.indexes] }
      ]
    end
  end
  alias_method :indexes, :indexes_for

  # @param index return only delete requests to the specified Chewy::Type index.
  # @return the index deletes captured by the mock.
  def deletes_for index = nil
    if index
      mutation_for(index).deletes
    else
      Hash[
        @mutations.map { |a,b| [a, b.deletes] }
      ]
    end
  end
  alias_method :deletes, :deletes_for

  # Check to see if a given object has been indexed.
  # @param (#id) obj the object to look for.
  # @param Chewy::Type what type the object should be indexed as.
  # @return bool if the object was indexed.
  def indexed? obj, type
    indexes_for(type).map {|i| i[:_id]}.include? obj.id
  end

  # Check to see if a given object has been deleted.
  # @param (#id) obj the object to look for.
  # @param Chewy::Type what type the object should have been deleted from.
  # @return bool if the object was deleted.
  def deleted? obj, type
    deletes_for(type).include? obj.id
  end

  # @return a list of Chewy::Type indexes changed.
  def updated_indexes
    @mutations.keys
  end

  private
  # Get the mutation object for a given type.
  # @param (Chewy::Type) type the index type to fetch.
  # @return (#indexes, #deletes) an object with a list of indexes and a list of deletes.
  def mutation_for type
    @mutations[type] ||= OpenStruct.new(indexes: [], deletes: [])
  end

end

