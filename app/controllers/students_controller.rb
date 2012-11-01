class StudentsController < ApplicationController
  respond_to :html, :json

  def index
    @search = Search.new(params[:search] || params)
    respond_with @students = Contingent.instance.students(@search.attributes)
  end

  def show
    respond_with @student = Contingent.instance.students(:study_id => params[:id]).first
  end

  def check
    students = Contingent.students(params).select{ |student| student.born_on.to_date.to_s == params[:born_on] }

    if students.one?
      student = students.first
      render :text => [student.study_id, student.subfaculty.abbr].join(":")
    else
      render :text => nil
    end
  end

end
