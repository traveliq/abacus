# Abacus

Abacus is a simple counting server.
It counts al kind of things as triples of strings on dates.

The three parts of this service are gathered in a rails project:

 1. A resque worker using a redis queue which work as the data input interface.
 2. A single mysql table on which stored amounts of that triple are incremented and one Model to access the table.
 3. A Controller to provide an API interface to gather the stored counts with diferent sort of requests.


## Installation

- create database abacus\_statistics\_development;
- create database abacus\_statistics\_test;
- adjust varchar width in migration
- bundle install
- rake db:migrate
- rake db:test:prepare
- bundle exec spec spec
- rake resque:work

Intregrate this lines into the code where you want to count things:

    require 'resque'
    require 'ostruct'
    worker = module Worker class StatisticsRecorder; @queue = 'abacus_statistics' end; end

## Counting
After running this initial installation steps you can start pushing data into the redis queue

    Resque.enqueue(worker, {:ns1 => 'search', :ns2 => 'horse', :ns3 => 'website', :year => 2011, :month => 1, :day => 31})
    Resque.enqueue(worker, {:ns1 => 'sale', :ns2 => 'horse', :ns3 => 'iphone', :year => 2011, :month => 1 , :day => 31})
    Resque.enqueue(worker, {:ns1 => 'comment', :ns2 => 'horse', :ns3 => 'iphone', :year => 2011, :month => 1 ,:day => 31})

### Save an amount > 1
    Resque.enqueue(worker, {:ns1 => 'sales_price', :ns2 => 'horse', :ns3 => 'iphone',:amount => 2 :year => 2011, :month => 1 ,:day => 31})

### Of course you can also decrement, for example if a sale is cancelled
    Resque.enqueue(worker, {:ns1 => 'sales_price', :ns2 => 'horse', :ns3 => 'iphone',:amount => -2 :year => 2011, :month => 1 ,:day => 31})

day, month, year can be skipped then the actual date is used
 data is return as array of jason hashes

### Count by post

 You can also count by posting to /statistics
 with curl this looks like this:
 curl -d 'ns1=test_ns1&ns2=test_ns2&ns3=test_ns3' localhost:3000/statistics.json

### Other languages

 Everything that adds correctly formatted data to a redis queue the resque worker is listening on will work for counting.

## Collecting the data
You can  receive the counts by sending http request with triples and date ranges as parameters to the webserver.
The webserver return an Array of json hashes containing the Amount.

### Get a single data set
curl "localhost:3000/statistics?ns1=comment&ns2=horse&ns3=iphone&date_since=2011-01-31&date_till=2011-01-31&granularity=day"

    [{"day":31,"ns1":"comment","month":1,"ns2":"horse","year":2011,"amount":3.0,"ns3":"iphone"}]

### Get data for a date range, 0 amounts are returned for dates without data
curl "localhost:3000/statistics?ns1=comment&ns2=horse&ns3=iphone&date_since=2011-01-29&date_till=2011-01-31&granularity=day"

    [{"day":29,"ns1":"comment","month":1,"ns2":"horse","year":2011,"amount":0.0,"ns3":"iphone"},
     {"day":30,"ns1":"comment","month":1,"ns2":"horse","year":2011,"amount":0.0,"ns3":"iphone"},
     {"day":31,"ns1":"comment","month":1,"ns2":"horse","year":2011,"amount":1.0,"ns3":"iphone"}]

### Data for multi n1, n2 and dates the cartesian product will be returned filling empty triple with 0 amount

curl "http://localhost:3000/statistics?ns1\[\]=comment&ns1\[\]=sale&ns2\[\]=horse&ns2\[\]=camel&ns3=iphone&date_since=2011-01-30&date_till=2011-01-31&granularity=day"

    [{"day":30,"ns1":"comment","month":1,"ns2":"horse","year":2011,"amount":0.0,"ns3":"iphone"},
    {"day":31,"ns1":"comment","month":1,"ns2":"horse","year":2011,"amount":1.0,"ns3":"iphone"},
    {"day":30,"ns1":"comment","month":1,"ns2":"camel","year":2011,"amount":0.0,"ns3":"iphone"},
    {"day":31,"ns1":"comment","month":1,"ns2":"camel","year":2011,"amount":0.0,"ns3":"iphone"},
    {"day":30,"ns1":"sale","month":1,"ns2":"horse","year":2011,"amount":0.0,"ns3":"iphone"},
    {"day":31,"ns1":"sale","month":1,"ns2":"horse","year":2011,"amount":1.0,"ns3":"iphone"},
    {"day":30,"ns1":"sale","month":1,"ns2":"camel","year":2011,"amount":0.0,"ns3":"iphone"},
    {"day":31,"ns1":"sale","month":1,"ns2":"camel","year":2011,"amount":0.0,"ns3":"iphone"}]

### Get data sums for month and year

curl 'http://localhost:3000/statistics?ns1=comment&ns2=horse&ns3=iphone&date_since=2011-01-30&date_till=2011-01-31&granularity=month'

    [{"day":null,"ns1":"comment","month":1,"ns2":"horse","year":2011,"amount":1.0,"ns3":"iphone"}]

curl 'http://localhost:3000/statistics?ns1=comment&ns2=horse&ns3=iphone&date_since=2011-01-30&date_till=2011-01-31&granularity=year'

    [{"day":null,"ns1":"comment","month":null,"ns2":"horse","year":2011,"amount":1.0,"ns3":"iphone"}]

### Get sums of all ns3 by not using the param

curl 'http://localhost:3000/statistics?ns1=comment&ns2=horse&date_since=2011-01-30&date_till=2011-01-31&granularity=year'

    [{"day":null,"ns1":"comment","month":null,"ns2":"horse","year":2011,"amount":1.0,"ns3":null}]

