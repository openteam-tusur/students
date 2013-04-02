class StudentsController < ApplicationController
  helper_method :search, :student, :students

  def index
  end

  def show
  end

  private

  def students
    @students = Contingent.instance.students(search)
  end

  def student
    Contingent.instance.find_student_by_study_id(params[:id])
  end

  def search
    @search ||= Search.new(params[:search])
  end

end
