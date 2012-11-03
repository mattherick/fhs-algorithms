class TasksController < ApplicationController
  
  def index
  end
  
  def task_1
    @task_1a = Book.task_1a
    @task_1b = User.task_1b
    @task_1c = User.task_1c
  end

  def task_2
    @users = User.joins(:ratings).where("`BX-Book-Ratings`.`Book-Rating` > 0")
      .order("`BX-Book-Ratings`.`Book-Rating`").uniq.limit(50)
    
    @rel_fq = {} # relative frequency = relative Haeufigkeit
    @users.each do |user|
      (1..10).each do |i|
        @rel_fq[user.id] ||= []
        # relative Haeufigkeit, zB (Anzahl der 1en)/10
        count_per_rating = user.ratings_except0.where("`BX-Book-Ratings`.`Book-Rating` = #{i}").count
        @rel_fq[user.id] << count_per_rating/user.ratings_except0.count.to_f
      end
    end
  end
  
end