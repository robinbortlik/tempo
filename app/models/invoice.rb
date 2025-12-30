# Note: This is a minimal placeholder model to support TimeEntry associations.
# Full implementation will be completed in task 3.5 Invoice Model.
class Invoice < ApplicationRecord
  # Full associations, validations, scopes, and methods will be added in task 3.5
  has_many :time_entries, dependent: :nullify
end
