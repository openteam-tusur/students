class StudentsController < ApplicationController
  respond_to :html, :json

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

    if students.one?
      student = students.first
      render :text => [student.study_id, student.subfaculty.abbr].join(":")
    else
      render :text => nil
    end
  end

end
