class Rating < ActiveRecord::Base  
  set_table_name "BX-Book-Ratings"
  
  set_primary_key "ISBN"
  set_primary_key "User-ID"

  belongs_to :book, :foreign_key => "ISBN"
  belongs_to :user, :foreign_key => "User-ID"
end

# Schema
# CREATE TABLE `BX-Book-Ratings` (
#   `User-ID` int(11) NOT NULL default '0',
#   `ISBN` varchar(13) NOT NULL default '',
#   `Book-Rating` int(11) NOT NULL default '0',
#   PRIMARY KEY  (`User-ID`,`ISBN`)
# ) ENGINE=InnoDB;