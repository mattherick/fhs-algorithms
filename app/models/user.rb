class User < ActiveRecord::Base
  set_table_name "BX-Users"
  set_primary_key "User-ID"
  
  has_many :ratings, :foreign_key => "User-ID"
  has_many :books, :through => :ratings, :foreign_key => ["User-ID", "ISBN"]
  
  # just for testing sql query!!
  def self.test
    User.joins(:ratings).where("BX-Book-Ratings.ISBN" => User.find(276688).ratings.map(&:ISBN))
    #.group('BX-Users.User-ID').having('count(BX-Book-Ratings) > 7') # group and having?? does not work yet!
  end
end

# Schema
# CREATE TABLE `BX-Users` (
#   `User-ID` int(11) NOT NULL default '0',
#   `Location` varchar(250) default NULL,
#   `Age` int(11) default NULL,
#   PRIMARY KEY  (`User-ID`)
# ) ENGINE=InnoDB;