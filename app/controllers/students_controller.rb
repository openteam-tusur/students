class StudentsController < ApplicationController
  respond_to :html, :json
  before_filter :set_search

  def index
    respond_with @students = Contingent.instance.students(@search)
  end

  def show
    @search.include_inactive = 1
    respond_with @student = Contingent.instance.students(@search).first
  end

  def check
    students = Contingent.instance.students(@search).select{ |student| student.born_on == @search }

    if students.one?
      student = students.first
      render :text => [student.study_id, student.subfaculty.abbr].join(":")
    else
      render :text => nil
    end
  end

  private

  def set_search
    @search = Search.new(params[:search] || params)
  end

end
