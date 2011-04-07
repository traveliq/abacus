require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../db/migrate/20100420120906_add_statistics')

describe Statistic, 'validity' do

  before :each do
    @stat = Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :amount => 7.0, :month => '10', :year => '2010', :day => '3', })
  end

  it 'should be valid' do
    @stat.should be_valid
  end
  
  after(:each) do
    Statistic.delete_all
  end

end

describe Statistic, 'incrementing values' do

  before :each do
    @stat = Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :amount => 7.0})
  end

  it 'should increment all relevant values' do
    t = Time.now
    expected_args = [
      {:ns2 => 'ns2', :ns1 => 'ns1', :amount => 7.0, :ns3 => 'ns3', :year => t.year, :month => t.month, :day => t.day},
      {:ns2 => 'ns2', :ns1 => 'ns1', :amount => 7.0, :ns3 => 'ns3', :year => t.year, :month => t.month, :day => nil},
      {:ns2 => 'ns2', :ns1 => 'ns1', :amount => 7.0, :ns3 => 'ns3', :year => t.year, :month => nil,     :day => nil},
      {:ns2 => 'ns2', :ns1 => 'ns1', :amount => 7.0, :ns3 => nil,         :year => t.year, :month => t.month, :day => t.day},
      {:ns2 => 'ns2', :ns1 => 'ns1', :amount => 7.0, :ns3 => nil,         :year => t.year, :month => t.month, :day => nil},
      {:ns2 => 'ns2', :ns1 => 'ns1', :amount => 7.0, :ns3 => nil,         :year => t.year, :month => nil,     :day => nil},
      ]
    expected_args.each do |expected_arg|
      Statistic.should_receive(:increment!).with(expected_arg, 7.0).once
    end
    @stat.increment_all!
  end

  after(:each) do
    Statistic.delete_all
  end

end

describe Statistic, 'write and read dates' do

  before(:each) do
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
    
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 27}).increment_all!
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 6,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2011, :month => 6,:day => 26}).increment_all!    
  end
    
  it 'should filter by date' do
    repl = Statistic.find_by_date_range(Date.parse('2010-05-25'), Date.parse('2010-05-25'), ['ns1'],['ns2'], 'ns3', 'day')
    repl.length.should == 1
    repl.first.amount.should == 0
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns1'],['ns2'], 'ns3', 'day')
    repl.length.should == 1
    repl.first.amount.should == 2
    repl = Statistic.find_by_date_range(Date.parse('2010-05-27'), Date.parse('2010-05-27'), ['ns1'],['ns2'], 'ns3', 'day')
    repl.length.should == 1
    repl.first.amount.should == 1
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-27'), ['ns1'],['ns2'], 'ns3', 'day')
    repl.length.should == 2
    repl.first.amount.should == 2
    repl.last.amount.should == 1
    repl = Statistic.find_by_date_range(Date.parse('2010-05-28'), Date.parse('2010-05-28'), ['ns1'],['ns2'], 'ns3', 'day')
    repl.length.should == 1
    repl.first.amount.should == 0
  end

  it 'should filter by month granularity' do
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns1'],['ns2'], 'ns3', 'month')
    repl.length.should == 1
    repl.first.amount.should == 3
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-06-01'), ['ns1'],['ns2'], 'ns3', 'month')
    repl.length.should == 2
    repl.first.amount.should == 3
    repl.first.month.should == 5
    repl.last.amount.should == 1
    repl.last.month.should == 6
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2011-06-01'), ['ns1'],['ns2'], 'ns3', 'month')
    repl.length.should == 14
    repl.first.amount.should == 3
    repl.first.month.should == 5
    repl[1].amount.should == 1
    repl[1].month.should == 6
    repl[1].year.should == 2010
    repl[13].amount.should == 1
    repl[13].month.should == 6
    repl[13].year.should == 2011
  end
  
  it 'should filter by year granularity' do
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns1'],['ns2'], 'ns3', 'year')
    repl.length.should == 1
    repl.first.amount.should == 4
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2011-05-26'), ['ns1'],['ns2'], 'ns3', 'year')
    repl.length.should == 2
    repl.first.amount.should == 4
    repl.last.amount.should == 1
  end

  after(:each) do
    Statistic.delete_all
  end
  
end

describe Statistic, 'write and read ns3s' do


  before(:each) do
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'next_ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
  end
  
  it 'should filter ns3s' do
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns1'],['ns2'], ['ns3'], 'day')
    repl.length.should == 1
    repl.first.amount.should == 1
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns1'],['ns2'], nil, 'day')
    repl.length.should == 1
    repl.first.amount.should == 2
  end

  after(:each) do
    Statistic.delete_all
  end 
  
end

describe Statistic, 'write and read search types' do

  before(:each) do
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns11', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns12', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
  end
  
  it 'should filter search types' do
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns11'],['ns2'], ['ns3'], 'day')
    repl.length.should == 1
    repl.first.amount.should == 1
    repl = Statistic.find_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns11', 'ns12'],['ns2'], ['ns3'], 'day')
    repl.length.should == 2
    repl.first.amount.should == 1
    repl.last.amount.should == 1
  end
  
  after(:each) do
    Statistic.delete_all
  end
  
end

describe Statistic, 'calculate mean values' do

  before(:each) do
    Statistic.new({:ns2 => 'type2', :ns1 => 'ns12', :ns3 => 'ns32', :year => 2010, :month => 5,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'type2', :ns1 => 'ns12', :ns3 => 'ns32', :year => 2010, :month => 5,:day => 30}).increment_all!
  end
  
 
  it 'should calculate one mean value per ns1' do
    repl = Statistic.find_mean_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns11', 'ns12'],['type2'], ['ns32'])
    repl.length.should == 2
    repl.first[:mean].should == 0
    repl.last[:mean].should == 1
  end

  it 'should calculate one mean value per ns2' do
    repl = Statistic.find_mean_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns1'],['ns2'], ['ns31','ns32'])
    repl.length.should == 2
  end

  it 'should calculate one mean value per ns3' do
    repl = Statistic.find_mean_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-26'), ['ns1'],['ns2'], ['ns31','ns32'])
    repl.length.should == 2
  end

 it 'should calculate mean value for a given date rage' do
    repl = Statistic.find_mean_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-29'), ['ns12'],['type2'], ['ns32'])
    repl.length.should == 1
    repl.first[:mean].should == 0.25
    repl = Statistic.find_mean_by_date_range(Date.parse('2010-05-26'), Date.parse('2010-05-30'), ['ns12'],['type2'], ['ns32'])
    repl.length.should == 1
    repl.first[:mean].should == 0.4
  end
  
  after(:each) do
    Statistic.delete_all
  end

end
