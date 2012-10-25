class TasksController < ApplicationController
  
  def index
  end
  
  def first
    # Task1 a
    @book1 = Book.find("0316095648")
    @book2 = Book.find("0971880107")
    @book3 = Book.find("0446610038")
    
    # Task1 b
    @user1 = User.find(1903)
    @user2 = User.find(2033)
    @user3 = User.find(2766)
    
    # Task1 c
    # Find the most similar user to user "276688" with respect to his/her ratings 
    # calculated using Pearson correlation, Spearman correlation, Cosine similarity 
    # (calculate the values only based on mutually rated values). Evaluate only users 
    # that have at least 7 ratings with user "276688" in common.
  end
  
end