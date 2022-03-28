# frozen_string_literal: true

class Instructor < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :instance
end

