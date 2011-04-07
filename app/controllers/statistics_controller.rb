class StatisticsController < ApplicationController
  
  before_filter :check_post_params, :only => :create
  
  def index
    stats = Statistic.find_by_date_range(Date.parse(params[:date_since]), Date.parse(params[:date_till]), params[:ns1], params[:ns2], params[:ns3], params[:granularity])
    hashes = stats.map{|s| s.to_hash}
    render :json => hashes.to_json
  end
  
  def mean
    stats = Statistic.find_mean_by_date_range(Date.parse(params[:date_since]), Date.parse(params[:date_till]), params[:ns1], params[:ns2], params[:ns3], params[:granularity])
    render :json => stats.to_json
  end

  def create
    params_to_fetch = [:ns1, :ns2, :ns3, :year, :month, :day, :amount]
    attributes = params_to_fetch.inject({}) do |acc, key|
      acc[key] = params[key]
      acc
    end
    attributes[:amount] ||= 1
    stat = Statistic.new(attributes)
    stat.increment_all!

    render :json => {:status => :ok}
  end

  private

  def check_post_params
    if !(params[:ns1] && params[:ns2] && params[:ns3])
      render :status => :not_found and return
    end
  end

end
