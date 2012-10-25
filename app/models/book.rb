class Book < ActiveRecord::Base  
  set_table_name "BX-Books"
  set_primary_key "ISBN"
  
  has_many :ratings, :foreign_key => "ISBN"
  has_many :users, :through => :ratings, :foreign_key => ["User-ID", "ISBN"]
end

# Schema
# `ISBN` varchar(13) binary NOT NULL default '',
# `Book-Title` varchar(255) default NULL,
# `Book-Author` varchar(255) default NULL,
# `Year-Of-Publication` int(10) unsigned default NULL,
# `Publisher` varchar(255) default NULL,
# `Image-URL-S` varchar(255) binary default NULL,
# `Image-URL-M` varchar(255) binary default NULL,
# `Image-URL-L` varchar(255) binary default NULL,
# PRIMARY KEY  (`ISBN`)