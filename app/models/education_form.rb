# encoding: utf-8

class EducationForm < Model
  extend Enumerize
  attribute :kind

  enumerize :kind, :in => %w[full-time part-time postal]

  EDUCATION_FORMS = {
    'Очная'           => EducationForm.new(:kind => 'full-time'),
    'Очно-заочная'    => EducationForm.new(:kind => 'part-time'),
    'Заочная'         => EducationForm.new(:kind => 'postal'),
  }

  def to_s
    kind.text
  end

  def self.find_by(params)
    EDUCATION_FORMS[params[:caption]] or raise "Cann't find education by caption '#{params[:caption]}'"
  end

  def self.from(hash)
    find_by :caption => hash[:edu_form_name]
  end
end
