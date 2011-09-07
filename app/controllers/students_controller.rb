class StudentsController < ApplicationController
  respond_to :html, :json, :xml
  def index
    @student_search = StudentSearch.new(params[:student_search] || {})
    respond_with @students = @student_search.students
  end

  def show
    respond_with @student =  Student.find(params[:id])
  end

  def check
    student_search = StudentSearch.new :lastname   => params[:lastname],
                                       :firstname  => params[:firstname],
                                       :patronymic => params[:patronymic],
                                       :group      => params[:group]

    students = student_search.students.select{ |student| student.born_on.to_date.to_s == params[:born_on] }

    render :text => students.one? ? students.first.study_id : nil
  end

end
