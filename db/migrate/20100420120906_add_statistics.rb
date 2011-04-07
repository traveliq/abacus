class AddStatistics < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE statistics (
      id int(11) NOT NULL AUTO_INCREMENT,
      ns1 varchar(50) NOT NULL,
      ns2 varchar(50) NOT NULL,
      ns3 varchar(50) DEFAULT NULL,
      year smallint(4) DEFAULT NULL,
      month smallint(2) ZEROFILL DEFAULT NULL,
      day smallint(2)   ZEROFILL DEFAULT NULL,
      amount float DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `item_type` (`ns1`,`ns2`,`ns3`,`year`,`month`,`day`)
      )'
  end

  def self.down
    drop_table :statistics
  end
end