require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StatisticsController, 'routes' do
  it 'should create on post' do
    assert_routing({ :method => 'post', :path => '/statistics' }, { :controller => "statistics", :action => "create" })
  end
end

describe StatisticsController, 'create' do

  it 'should return 404 if params are missing' do
    post :create, :ns1 => 'ns1', :ns2 => 'ns2'
    response.code.should eql '404'
  end

  it 'should return 100 if params are complete' do
    post :create, :ns1 => 'ns1', :ns2 => 'ns2', :ns3 => 'ns3'
    response.code.should eql '200'
  end

  it 'should create and increment the right statistics with minimal params' do
    stats = mock(Statistic)
    stats.should_receive(:increment_all!).once
    Statistic.should_receive(:new).with({:ns1 => 'ns1', :ns2 => 'ns2', :ns3 => 'ns3', :amount => 1, :year => nil, :month => nil, :day => nil}).once.and_return(stats)
    post :create, :ns1 => 'ns1', :ns2 => 'ns2', :ns3 => 'ns3'
  end

  it 'should create and increment the right statistics with maximum params' do
    stats = mock(Statistic)
    stats.should_receive(:increment_all!).once
    Statistic.should_receive(:new).with({:ns1 => 'ns1', :ns2 => 'ns2', :ns3 => 'ns3', :amount => '3', :year => '2011', :month => '2', :day => '8'}).once.and_return(stats)
    post :create, :ns1 => 'ns1', :ns2 => 'ns2', :ns3 => 'ns3', :amount => 3, :year => '2011', :month => '2', :day => '8'
  end

end

describe StatisticsController, 'date range filling' do

  it 'should fill dates with single conditions' do
    ActiveRecord::Base.connection.execute('truncate statistics')
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'ns2', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 29}).increment_all!
    get :index, :ns2 => ['ns2'], :ns1 => ['ns1'], :ns3 => ['ns3'], :date_since => '2010-5-25', :date_till => '2010-5-30', :granularity => 'day'
    JSON.parse(response.body).length.should == 6
  end

  it 'should fill dates with multipe ns2s' do
    ActiveRecord::Base.connection.execute('truncate statistics')
    Statistic.new({:ns2 => 'ns21', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'ns21', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 29}).increment_all!
    Statistic.new({:ns2 => 'ns22', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 26}).increment_all!
    Statistic.new({:ns2 => 'ns22', :ns1 => 'ns1', :ns3 => 'ns3', :year => 2010, :month => 5,:day => 29}).increment_all!
    get :index, :ns2 => ['ns2'], :ns1 => ['ns1'], :ns3 => ['ns3'], :date_since => '2010-5-25', :date_till => '2010-5-30', :granularity => 'day'
    JSON.parse(response.body).length.should == 6
  end

end

describe StatisticsController, 'check params' do

  it 'should check for exitence of params' do
    post 'create'
    response.code.should eql '404'
  end

end

describe StatisticsController, 'create' do

  it 'should be in the routes' do
     params_from(:post, "/statistics").should == {:controller => "statistics", :action => "create"}
  end

  it 'should call new on Statistic with the attributes' do
    Statistic.should_receive(:new).and_return(mock_model(Statistic, :increment_all! => true))
    post 'create', :ns1 => 'lalala', :ns2 => 'lalala', :ns3 => 'lalala'
  end
  
  it 'should call increment all for the new Statistic instance' do
    stat = mock_model(Statistic)
    stat.should_receive(:increment_all!).once
    Statistic.should_receive(:new).and_return(stat)
    post 'create', :ns1 => 'lalala', :ns2 => 'lalala', :ns3 => 'lalala'
  end
end
