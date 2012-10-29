class User < ActiveRecord::Base
  set_table_name "BX-Users"
  set_primary_key "User-ID"
  
  has_many :ratings, :foreign_key => "User-ID"
  has_many :books, :through => :ratings, :foreign_key => ["User-ID", "ISBN"]
  
  # Task 3
  # Find the most similar user to user "276688" with respect to his/her ratings calculated using 
  # Pearson correlation, Spearman correlation, Cosine similarity 
  # (calculate the values only based on mutually rated values). 
  # Evaluate only users that have at least 7 ratings with user "276688" in common.
  def self.task3
    User.joins(:ratings).where(
      "BX-Book-Ratings.ISBN" => User.find(276688).ratings.map(&:ISBN)
    ).group("`BX-Users`.`User-ID`").having("count(`BX-Book-Ratings`.`Book-Rating`) >= 7")
  end

  # Task 2
  # Calculate 𝑥 , 𝑠𝑥 of Users "1903", "2033", and "2766". Compare the values? 
  # What do these values tell us?
  def self.task2
      
  end

  # User.find("1903").arithmetic_avg
  # User.find("2033").arithmetic_avg
  # User.find("2766").arithmetic_avg
  def arithmetic_avg
    ratings.map(&:"Book-Rating").sum.to_f / ratings.count
  end

  # User.find("1903").sx
  # User.find("2033").sx
  # User.find("2766").sx
  def sx
    sum = 0
    ratings.map(&:"Book-Rating").each do |rating|
      sum += (rating - arithmetic_avg)**2
    end
    Math.sqrt(sum/(ratings.count-1))
  end
end

# Schema
# CREATE TABLE `BX-Users` (
#   `User-ID` int(11) NOT NULL default '0',
#   `Location` varchar(250) default NULL,
#   `Age` int(11) default NULL,
#   PRIMARY KEY  (`User-ID`)
# ) ENGINE=InnoDB;

