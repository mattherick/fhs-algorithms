class User < ActiveRecord::Base
  set_table_name "BX-Users"
  set_primary_key "User-ID"
  
  has_many :ratings, :foreign_key => "User-ID"
  has_many :books, :through => :ratings, :foreign_key => ["User-ID", "ISBN"]
  
  # just for testing sql query!!
  def self.test
    User.joins(:ratings).where(
      "BX-Book-Ratings.ISBN" => User.find(276688).ratings.map(&:ISBN)
    ).group(`BX-Users.User-ID`)#.having("count(`BX-Book-Ratings.Book-Rating`) >= 7") # group and having?? does not work yet!
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

