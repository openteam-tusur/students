# encoding: utf-8
require 'singleton'

class Contingent
  include Singleton

  def login
    call "LogOn", Settings[:auth] unless logged_in?
  end

  def logged_in?
    Rails.cache.fetch(:logged_in?, :expires_in => 10.minutes) do
      call "isLogin"
    end
  end

  def students(search)
    filter = {
      "GroupName" => search.group,
      "LastName" => search.lastname,
      "FirstName" => search.firstname,
      "MiddleName" => search.patronymic
    }
    filter.delete_if { |key, value|  value.blank? }
    return [] if filter.empty?
    filter["StudentStateId"] = search.learns_yes? ? 1 : 2
    find_students(filter).map { | hash | student_from hash }
  end

  def student(id)
    student_from find_student(id)
  end

private
  def client
    @client ||= Savon::Client.new do | wsdl, http |
      wsdl.endpoint = endpoint
      wsdl.namespace = namespace
    end
  end


  def endpoint
    @endpoint ||= Settings['contingent.endpoint']
  end

  def namespace
    @namespace ||= Settings['contingent.namespace']
  end

  def call(method, params={})
    raw_response(method, params).to_hash[:"#{method.underscore}_response"][:"#{method.underscore}_result"]
  end


  def raw_response(method, params)
    client.request method, :xmlns => namespace do
      soap.version = 2
      soap.body = params
    end
  end

  def find_students(params)
    Rails.cache.fetch(params.to_s, :expires_in => 23.hours) do
      login
      response = call("GetStudentsByCriteria", "studentCriteria" => params) || {}
      result = response[:student_dto] || []
      result = [result] if result.is_a? Hash
      result
    end
  end

  def find_student(id)
    Rails.cache.fetch("id:#{id}", :expires_in => 23.hours) do
      login
      call "GetStudentById", :studentId => id
    end
  end

  def student_from(hash)
    Student.new(
      :study_id => hash[:study_id],
      :firstname => hash[:first_name],
      :patronymic => hash[:middle_name],
      :lastname => hash[:last_name],
      :born_on => hash[:birth_date],
      :subfaculty => subfaculty_from(hash),
      :faculty => faculty_from(hash),
      :year => hash[:group][:course],
      :group => hash[:group][:group_name],
      :learns => hash[:student_state][:name] == "Активный" ? :yes: :no,
      :in_gpo => hash[:gpo]? "yes": "no",
    )
  end

  def subfaculty_from(hash)
    Subfaculty.new(
      :name => hash[:education][:sub_faculty][:sub_faculty_name],
      :abbr => hash[:education][:sub_faculty][:short_name],
    )
  end

  def faculty_from(hash)
    Faculty.new(
      :name => hash[:education][:faculty][:faculty_name],
      :abbr => hash[:education][:faculty][:short_name],
    )
  end

end
