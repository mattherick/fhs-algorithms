require "GSL"
require 'statsample'
require 'csv'

class User < ActiveRecord::Base
  set_table_name "BX-Users"
  set_primary_key "User-ID"
  
  has_many :ratings, :foreign_key => "User-ID"
  has_many :books, :through => :ratings, :foreign_key => ["User-ID", "ISBN"]
  
  include GSL
  # Task 2
  def ratings_except0
    ratings.where("`Book-Rating` > 0")
  end

  # Task 2 SQL (50 Benutzer mit den meisten Bewertungen)
  def self.users2
    User.joins(:ratings).where("`BX-Book-Ratings`.`Book-Rating` > 0")
      .group("`BX-Users`.`User-ID`")
      .order("count(`BX-Book-Ratings`.`Book-Rating`) DESC").limit(50)
  end

  
  # Task 6
  def self.task_6
    { :pearson => pearson }#, :spearman => spearman }
  end

  def self.pearson
    user = user_with_most_ratings

    result = {}
    users.each do |user2|
      next if user2.id == user.id

      ratings = Rating.where("User-ID" => user.id, :ISBN => user2.ratings.map(&:ISBN)).map(&:"Book-Rating")
      ratings2 = Rating.where("User-ID" => user2.id, :ISBN => user.ratings.map(&:ISBN)).map(&:"Book-Rating")
 
      sxy = sxy(ratings, ratings2)
      sxsy = sxsy(ratings, ratings2)
      result[user2.id] = (sxy.zero? || sxsy.zero?) ? 0.0 : (sxy / sxsy)
    end
    result
  end
  
  def self.spearman
    user = user_with_most_ratings
    
    result = {}
    users.each do |user2|
      next if user2.id == user.id
      
      ratings = ratings_as_vector(user, user2)
      ratings2 = ratings_as_vector(user2, user)

      spearman = Statsample::Bivariate.spearman(ratings, ratings2)
      result[user2.id] = (spearman.zero? || spearman.nan?) ? 0.0 : spearman
    end
    result
  end

  # User.find("1903").arithmetic_avg
  # User.find("2033").arithmetic_avg
  # User.find("2766").arithmetic_avg
  def arithmetic_avg
    array = ratings.map(&:"Book-Rating")
    array.sum.to_f / array.length
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

  def self.arithmetic_avg array
    array.sum.to_f / array.length
  end

  def self.sxy ratings, ratings2
    raise if ratings.length != ratings2.length
    sum = 0
    avg = arithmetic_avg ratings
    avg2 = arithmetic_avg ratings2
    ratings.each_with_index do |rating, i|
      sum += ((rating - avg) * (ratings2[i] - avg2))
    end
    sum
  end

  def self.sxsy ratings, ratings2
    avg = arithmetic_avg ratings
    avg2 = arithmetic_avg ratings2
    sum = 0
    ratings.each do |rating|
      sum += (rating - avg)**2
    end
    sum2 = 0
    ratings2.each do |rating|
      sum2 += (rating - avg2)**2
    end
    Math.sqrt(sum) * Math.sqrt(sum2)
  end
  
  def self.users
    User.joins(:ratings).where("`BX-Book-Ratings`.`Book-Rating` > 0")
    .where(
      "BX-Book-Ratings.ISBN" => user_with_most_ratings.ratings.map(&:ISBN)
    ).group("`BX-Users`.`User-ID`").having("count(`BX-Book-Ratings`.`Book-Rating`) >= 200")
  end
  
  def self.ratings_as_vector(user, user2)
    Rating.where("User-ID" => user.id, :ISBN => user2.ratings.map(&:ISBN)).map(&:"Book-Rating").to_scale
  end

  def self.user_with_most_ratings
    # SELECT `BX-Users`.`User-ID`, COUNT(  `BX-Book-Ratings`.`Book-Rating` ) 
    # FROM  `BX-Book-Ratings` 
    # INNER JOIN  `BX-Users` ON  `BX-Book-Ratings`.`User-ID` =  `BX-Users`.`User-ID` 
    # WHERE (
    # `BX-Book-Ratings`.`Book-Rating` >0
    # )
    # GROUP BY  `BX-Users`.`User-ID` 
    # ORDER BY COUNT(  `BX-Book-Ratings`.`Book-Rating` ) DESC 
    # LIMIT 1
    User.joins(:ratings).where("`BX-Book-Ratings`.`Book-Rating` > 0")
      .group("`BX-Users`.`User-ID`")
      .order("count(`BX-Book-Ratings`.`Book-Rating`) DESC")
      .limit(1).first
  end

  def self.random
    user = User.find(16795)
    user.ratings.where(:ISBN => same_ratings).each do |rating|
      puts rating.ISBN
      puts "old: " + rating.send("Book-Rating").to_s
      puts "new: " + rand(1..10).to_s
    end
  end

  def self.slope_one
    user = User.find(16795)
    user_data = {}
    user_data[user_with_most_ratings.id] = {}
    user_with_most_ratings.ratings.where(:ISBN => same_books).each do |rating|
      user_data[user_with_most_ratings.id][rating.ISBN] = {}
      user_data[user_with_most_ratings.id][rating.ISBN] = rating.send("Book-Rating")
    end

    user_data2 = {}
    isbns = same_books - same_ratings
    user.ratings.where(:ISBN => isbns).each do |rating|
      user_data2[rating.ISBN] = {}
      user_data2[rating.ISBN] = rating.send("Book-Rating")
    end

    slope_one = SlopeOne.new
    slope_one.insert(user_data)
    puts slope_one.predict(user_data2).inspect
  end

  def self.same_books
    user = User.find(16795)
    array = user_with_most_ratings.ratings_except0.map(&:ISBN) + user.ratings_except0.map(&:ISBN)
    dup = array.select{|element| array.count(element) > 1 }
    dup.uniq.slice(0,50)
  end

  def self.same_ratings
    user = User.find(16795)
    books_with_same_ratings = []
    same_books.each do |isbn|
      rating = user_with_most_ratings.ratings_except0.where(:ISBN => isbn).first.send("Book-Rating")
      if rating == user.ratings_except0.where(:ISBN => isbn).first.send("Book-Rating")
        books_with_same_ratings << isbn
      end
    end
    books_with_same_ratings
  end

end

# Schema
# CREATE TABLE `BX-Users` (
#   `User-ID` int(11) NOT NULL default '0',
#   `Location` varchar(250) default NULL,
#   `Age` int(11) default NULL,
#   PRIMARY KEY  (`User-ID`)
# ) ENGINE=InnoDB;

