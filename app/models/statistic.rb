class Statistic < ActiveRecord::Base

  validates_presence_of :ns2, :ns1, :amount, :ns3, :year, :month, :day

  class << self
    
    # retrieve statistical date
    # date_since, date_till : the date range
    # ns1s : ['city_region', 'flight', 'car']
    # ns2s : ['searches', 'bookings']
    # ns3 : ['ns31', 'ns32'] or nil (nil means sums of all)
    # granularity : 'day', 'month' or 'year'
    def find_by_date_range(date_since, date_till, ns1s, ns2s, ns3s, granularity)
      raise ArgumentError, 'Please specify at least one ns1' if (!ns1s || ns1s.empty?)
      raise ArgumentError, 'Please specify at least one ns2' if (!ns2s || ns2s.empty?)
      raise ArgumentError, 'Please specify the granularity' unless granularity
      q = "select * from statistics WHERE #{[date_sql(date_since, date_till, granularity), ns3_sql(ns3s), ns1s_sql(ns1s), granularity_rules[granularity], ns2s_sql(ns2s)].join(" AND ")}"
      stats_from_db = self.find_by_sql(q)
      date_range = (date_since..date_till).map{|d| [d.year, d.month, d.day]}
      if granularity == 'month' || granularity == 'year'
        date_range = date_range.map{|d| d[2] = 0; d}.uniq
      end
      if granularity == 'year'
        date_range = date_range.map{|d| d[1] = 0; d}.uniq
      end
      stats = []
      ns1s.each do |ns1|
        ns2s.each do |ns2|
          (ns3s ? ns3s : ['0']).each do |ns3|
            date_range.each do |date|
              year, month, day = date
              existing = stats_from_db.find do |s|
                s.ns1 == ns1 &&
                s.ns2 == ns2 &&
                s.ns3 == ns3 &&
                s.year == year &&
                s.month == month &&
                s.day == day
              end
              if existing
                stats << existing
              else
                stats << Statistic.new({:ns1 => ns1, :ns2 => ns2, :ns3 => ns3, :year => year, :month => month, :day => day, :amount => 0.0})
              end
            end
          end
        end
      end
      
      stats
    end
 
   #works only on granularity days 
   def find_mean_by_date_range(date_since, date_till, ns1s, ns2s, ns3s)
      raise ArgumentError, 'Please specify at least one search type' if (!ns1s || ns1s.empty?)
      granularity_counter = (date_till - date_since).to_i + 1
      q = "SELECT ns2, ns1, ns3, (SUM(amount) / #{granularity_counter}) from statistics 
      WHERE #{[date_sql(date_since, date_till, 'day'), ns3_sql(ns3s), ns1s_sql(ns1s), granularity_rules['day'], ns2s_sql(ns2s)].join(" AND ")} GROUP BY
      ns3, ns1, ns2"
      stats_from_db = ActiveRecord::Base.connection.execute(q)
      stats_array = []
      stats_from_db.each do |stat|
        stats_array << stat
      end
      stats = []
      stats_hash = stats_array.inject({}) do |hash,row|
        hash[row[0 .. 2].to_s] = {:ns2 => row[0], :ns1 => row[1], :ns3 => row[2], :mean => row[3].to_f }
        hash
      end
      (ns3s ? ns3s : ['0']).sort.each do |ns3|
        ns1s.sort.each do |ns1|
          ns2s.sort.each do |ns2|
            if stat = stats_hash["#{ns2}#{ns1}#{ns3}"]
              stats << stat
            else
              stats <<  {:ns2 => ns2, :ns1 => ns1, :ns3 => ns3, :mean => 0.0 }
            end
          end
        end
      end
       stats
   end

   def  ns3_sql(ns3s)
      ns3s ? "ns3 IN (#{ns3s.map{|t| "'#{t}'"}.join(', ')})" : "ns3 = '0'"
    end
    
    def ns1s_sql(ns1s)
      "ns1 IN (#{ns1s.map{|t| "'#{t}'"}.join(', ')})"
    end
    
    def  ns2s_sql(ns2s)
      "ns2 IN (#{ns2s.map{|t| "'#{t}'"}.join(', ')})"
    end

    def granularity_rules      
      {
        'day' =>   '(day != 0 AND month != 0)',
        'month' => '(day = 0 AND month != 0)',
        'year' =>  '(day = 0 AND month = 0)'
      }
    end

    def date_sql(date_since, date_till,granularity)
      # include month '00' and day '00' according to granularity
      date_start = [
        date_since.year, 
        ['year'         ].include?(granularity) ? '00' : date_since.month.to_s.rjust(2, '0'), 
        ['year', 'month'].include?(granularity) ? '00' : date_since.day.to_s.rjust(2, '0')
      ].join('')
      date_end = [date_till.year, date_till.month.to_s.rjust(2, '0'), date_till.day.to_s.rjust(2, '0')].join('')

      date_sql = "(concat(year, month, day) >= #{date_start} AND concat(year, month, day) <= #{date_end})"
    end

    def increment!(attributes, amount)
      attributes_clean = attributes
      attributes_clean.delete(:amount)
      values = attributes_clean.values.map{|v| v.nil? ? '0': "'#{v}'"}
      q = "INSERT INTO statistics 
          (#{attributes_clean.keys.map(&:to_s).join(',')}, amount)
          VALUES (#{values.join(',')}, #{amount})
          ON DUPLICATE KEY UPDATE
          amount = amount + #{amount}"
      stats = ActiveRecord::Base.connection.execute(q) 
    end

  end

  def to_json(args)
    to_hash.to_json(args)
  end
  
  def to_hash
    {
      :ns2 => ns2,
      :ns1 => ns1,
      :amount => amount,
      :ns3 => (ns3 != '0') ? ns3 : nil,
      :year => year,
      :month => (month != 0) ? month : nil,
      :day => (day != 0) ? day : nil,
    }
  end
   
  def add_dates
    t = Time.now
    self.year  ||= t.year
    self.month ||= t.month
    self.day   ||= t.day
  end
  
  def increment_all!
    self.add_dates
    [[], [:ns3]].each do |ns3_attributes_to_nil|
      [[], [:day], [:month, :day]].each do |time_attributes_to_nil|
        attributes_to_nil =  time_attributes_to_nil + ns3_attributes_to_nil
        inc_attributes = self.attributes.symbolize_keys
        attributes_to_nil.each {|a| inc_attributes[a] = nil }
        self.class.increment!(inc_attributes, self.amount || 1)
      end
    end
  end

end


