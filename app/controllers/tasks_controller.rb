class TasksController < ApplicationController
  
  def index
  end
  
  def task_1
    @task_1a = Book.task_1a
    @task_1b = User.task_1b
    @task_1c = User.task_1c
  end
  
end