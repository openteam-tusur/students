class StudentsController < ApplicationController
  def index
    @student_search = StudentSearch.new(params[:student_search] || {})
    @students = @student_search.students
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @students }
    end
  end

  def show
    @student =  Student.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @student }
    end
  end

end
