class Book < ActiveRecord::Base  
  set_table_name "BX-Books"
  set_primary_key "ISBN"
  
  has_many :ratings, :foreign_key => "ISBN"
  has_many :users, :through => :ratings, :foreign_key => ["User-ID", "ISBN"]

  # Task 1
  # Calculate 𝑥 ,𝑥 and 𝑥 0.25 of the ratings of books "0316095648", "0971880107", and "0446610038". 
  # What is the message of those values?
  def self.task1
      
  end

  # Book.find("0316095648").arithmetic_avg
  # Book.find("0971880107").arithmetic_avg
  # Book.find("0446610038").arithmetic_avg
  def arithmetic_avg
    ratings.map(&:'Book-Rating').sum.to_f / ratings.count
  end

  # Book.find("0316095648").median
  # Book.find("0971880107").median
  # Book.find("0446610038").median
  def median
    ratings_array = ratings.map(&:'Book-Rating').sort!
    
    if ratings_array.count % 2 == 0 # even
      i = ratings_array.count/2
      median = (ratings_array[i-1] + ratings_array[i])/2
    else # odd
      i = (ratings_array.count-1)/2
      median = ratings_array[i]
    end
    median
  end

  # Book.find("0316095648").quantil
  # Book.find("0971880107").quantil
  # Book.find("0446610038").quantil
  def quantil(p=0.25)
    ratings_array = ratings.map(&:'Book-Rating').sort!
    np = ratings_array.count * p
    
    if np.integer?  # 𝑛𝑝 ∈ ℕ
      quantil = (ratings_array[np-1] + ratings_array[np])/2
    else # 𝑛𝑝 ∉ ℕ
      quantil = ratings_array[np.to_i]
    end
    quantil
  end

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