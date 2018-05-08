class StudentsController < ApplicationController
  helper_method :search, :student, :students

  def index
  end

  def show
  end

  private

  def students
    @students = if search.include_aspirants?
                    Aspirant.collection(params[:search])
                  else
                    Contingent.instance.students(search)
                  end
  end

  def student
    Contingent.instance.find_student_by_study_id(params[:id])
  end

  def search
    @search ||= Search.new(params[:search])
  end

end
