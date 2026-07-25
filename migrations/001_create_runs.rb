# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:runs) do
      primary_key :id
      String :uuid, null: false
      Time :timestamp, null: false
      Float :distance
      Float :duration
    end
  end
end
