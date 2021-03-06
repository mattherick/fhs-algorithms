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

  def self.generate_csv
    rel_fq, existing_ratings, new_ratings = {}, {}, {} # relative frequency = relative Haeufigkeit
    users2.each do |user|
      (1..10).each do |i|
        rel_fq[user.id] ||= []
        # relative Haeufigkeit, zB (Anzahl der 1en)/10
        count_per_rating = user.ratings_except0.where("`BX-Book-Ratings`.`Book-Rating` = #{i}").count
        rel_fq[user.id] << count_per_rating/user.ratings_except0.count.to_f
      end
      # existing ratings
      user.ratings_except0.each do |rating|
        existing_ratings[rating.ISBN] ||= {}
        existing_ratings[rating.ISBN][user.id] = rating.send("Book-Rating")
      end

      # generates new rating if it doesn't exists
      Book.all.each do |book|
        new_ratings[book.ISBN] ||= []
        existing = existing_ratings[book.ISBN][user.id] rescue nil
        new_ratings[book.ISBN] << (existing || generate_rating(user, rel_fq))
      end
    end

    CSV.open("generated_rating.csv", "w") do |csv|
      csv << [""] + users2.map(&:id)
      new_ratings.each do |isbn, ratings|
        csv << [isbn] + ratings
      end
    end
  end

  def self.generate_rating user, fq
    # geschaetzte verteilung errechnet durch relative haeufigkeit 
    # 0 - 0.1    = 1
    # 0.1 - 0.4  = 2
    # 0.4 - 0.4  = 3
    # 0.4 - 0.5  = 4
    # 0.5 - 1    = 5
    random = rand(0.0..1.0) # random float between 0-1

    fq[user.id].each_with_index do |value, i|
      value = value + fq[user.id][i-1] if i != 0

      if i == 0 && random > 0.0 && random <= value
        return 1
      elsif i == 9 && random > value && random <= 1.0
        return 10
      elsif random > fq[user.id][i-1] && random <= value
        return i+1
      end
    end
  end

  def self.pearson_matrix
    ratings = {}
    CSV.foreach(open("generated_rating.csv"), {headers: true}) do |row|
      # row[0] = isbn
      # row[1] = user1
      # row[2] = user2
      (1..50).each do |i|
        ratings[i] ||= []
        ratings[i] << row[i].to_i
      end
    end
    CSV.open("pearson_matrix.csv", "w") do |csv|
      csv << [""] + users2.map(&:id)
      ratings.each do |userid1, ratings_arr1|
        pearson_co = []
        ratings.each do |userid2, ratings_arr2|
          sxy = sxy(ratings_arr1, ratings_arr2) rescue 0
          sxsy = sxsy(ratings_arr1, ratings_arr2) rescue 0
          pearson_co << ((sxy.zero? || sxsy.zero?) ? 0.0 : (sxy / sxsy))
        end
        csv << [users2.map(&:id)[userid1-1]] + pearson_co
      end
    end
  end
  
  # Task 1b
  # Calculate x, sx of Users "1903", "2033", and "2766". Compare the values? 
  # What do these values tell us?
  def self.task_1b
    @task_1b = []
    user1 = User.find("1903")
    user2 = User.find("2033")
    user3 = User.find("2766")
    user1 = { :id => user1.id,
               :arithmetic_avg => user1.arithmetic_avg, 
               :sx =>  user1.sx
             }
    user2 = { :id => user2.id,
               :arithmetic_avg => user2.arithmetic_avg, 
               :sx =>  user2.sx
             }
    user3 = { :id => user3.id,
               :arithmetic_avg => user3.arithmetic_avg, 
               :sx =>  user3.sx
             }
    @task_1b << user1
    @task_1b << user2
    @task_1b << user3
  end
  
  # Task 1c
  # Find the most similar user to user "276688" with respect to his/her ratings calculated using 
  # Pearson correlation, Spearman correlation, Cosine similarity 
  # (calculate the values only based on mutually rated values). 
  # Evaluate only users that have at least 7 ratings with user "276688" in common.
  def self.task_1c
    { :pearson => pearson, :spearman => spearman, :cosine => cosine }
  end

  def self.pearson
    user = User.find(276688)

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
    user = User.find(276688)
    
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
  
  def self.cosine
    user = User.find(276688)
    
    result = {}
    users.each do |user2|
      next if user2.id == user.id
      
      ratings = ratings_as_vector(user, user2)
      ratings2 = ratings_as_vector(user2, user)
      
      cosine = calculate_similarity(ratings, ratings2)
      
      result[user2.id] = (cosine.zero? || cosine.nan?) ? 0.0 : cosine
    end
    result
  end
  
  def self.calculate_similarity ratings, ratings2
    dp = dot_product ratings, ratings2
    nv = (normalize ratings) * (normalize ratings2)
    dp.to_f/nv.to_f
  end
  
  def self.dot_product ratings, ratings2
    sum = 0.0
    ratings.each_with_index do | rating, i|
      sum += rating * ratings2[i]
    end
    sum
  end
  
  def self.normalize ratings 
    sum = 0.0
    ratings.each do |rating| 
      sum += rating**2
    end
    Math.sqrt sum
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
    User.joins(:ratings).where(
      "BX-Book-Ratings.ISBN" => User.find(276688).ratings.map(&:ISBN)
    ).group("`BX-Users`.`User-ID`").having("count(`BX-Book-Ratings`.`Book-Rating`) >= 7")
  end
  
  def self.ratings_as_vector(user, user2)
    Rating.where("User-ID" => user.id, :ISBN => user2.ratings.map(&:ISBN)).map(&:"Book-Rating").to_scale
  end

end

# Schema
# CREATE TABLE `BX-Users` (
#   `User-ID` int(11) NOT NULL default '0',
#   `Location` varchar(250) default NULL,
#   `Age` int(11) default NULL,
#   PRIMARY KEY  (`User-ID`)
# ) ENGINE=InnoDB;

