# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100804141020) do

  create_table "statistics", :force => true do |t|
    t.string  "ns1",    :limit => 50, :null => false
    t.string  "ns2",    :limit => 50, :null => false
    t.string  "ns3",    :limit => 50
    t.integer "year",   :limit => 2
    t.integer "month",  :limit => 2
    t.integer "day",    :limit => 2
    t.float   "amount"
  end

  add_index "statistics", ["ns1", "ns2", "ns3", "year", "month", "day"], :name => "item_type", :unique => true

end
