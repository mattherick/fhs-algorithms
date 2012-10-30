class TasksController < ApplicationController
  
  def index
  end
  
  def task_1
    @task_1a = Book.task_1a
  end
  
end