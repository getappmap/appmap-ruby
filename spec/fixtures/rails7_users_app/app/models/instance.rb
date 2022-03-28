# frozen_string_literal: true

class Instance < ApplicationRecord
  belongs_to :course
  has_and_belongs_to_many :instructor
end

