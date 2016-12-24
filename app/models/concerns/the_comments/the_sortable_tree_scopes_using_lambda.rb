require 'active_support/concern'

module TheComments
  module TheSortableTreeScopesUsingLambda
    extend ActiveSupport::Concern

    included do
      scope :nested_set,          lambda { order('lft ASC')  }
      scope :reversed_nested_set, lambda { order('lft DESC') }
    end
  end
end
