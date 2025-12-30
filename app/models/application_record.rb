class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.newest(column: :created_at, count: 1)
    order(column => :desc).first(count)
  end

  def self.oldest(column: :created_at, count: 1)
    order(column => :desc).last(count)
  end
end
