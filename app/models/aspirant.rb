class Aspirant
  def self.collection(params)
    params = {
      'op' => 'GetGraduatesByCriteria'
    }.merge(search_params(params))

    @response = RestClient::Request.execute(
      method: :get,
      url: Settings['aspirants.url'],
      user: Settings['aspirants.login'],
      password: Settings['aspirants.pass'],
      timeout: 120.seconds,
      headers: {
        params: params
      }
    ) do |response, _request, _result|
      json = begin
               JSON.load(response.body)
             rescue
               []
             end

      case params['op']
      when 'GetGraduatesByCriteria'
        json.select { |item|
          item.try(:[], 'Status').try(:[], 'DictionaryId') == '10'
        }.map { |item|
          Hashie::Mash.new transform_to_contingent_responce(item)
        }
      when 'GetAllActiveGraduateGroups'
        json.map { |hash|
          hash.deep_transform_keys{ |key| key.underscore.to_sym }
        }
      end
    end
  end

  private

  def self.search_params(params)
    {
      'op'          => params[:op],
      'GroupNumber' => params[:group],
      'LastName'    => params[:lastname],
      'FirstName'   => params[:firstname],
      'MiddleName'  => params[:patronymic]
    }.delete_if { |_, value| value.blank? }
  end

  def self.transform_to_contingent_responce(item)
    {
      study_id: nil,
      person_id: item['PersonId'],
      begin_study: I18n.l(Time.zone.parse(item['EduBeginDate'])),
      born_on: I18n.l(Time.zone.parse(item['BirthDate'])),
      citizenship: item['Citizenship']['Name'],
      firstname: item['FirstName'],
      lastname: item['LastName'],
      patronymic: item['MiddleName'],
      gender: item['Sex'].gsub('М', 'мужской').gsub('Ж', 'женский'),
      financing: item['FinanceType'].to_s.gsub('1', 'Бюджет').gsub('2', 'ПВЗ'),
      learns: true,
      education: {
        params: {
          edu_id: nil,
          edu_form: {
            edu_form_id: item['EduForm'].try(:[], 'EduFormId'),
            edu_form_name: item['EduForm'].try(:[], 'EduFormName')
          },
          sub_faculty: {
            sub_faculty_id: item['ChairCard'].try(:[], 'SubFacultyId'),
            sub_faculty_name: item['ChairCard'].try(:[], 'SubFacultyName'),
            short_name: item['ChairCard'].try(:[], 'ShortName')
          },
          faculty: {
            faculty_id: item['Group'].try(:[], 'Education').try(:[], 'Faculty').try(:[], 'FacultyId'),
            faculty_name: item['Group'].try(:[], 'Education').try(:[], 'Faculty').try(:[], 'FacultyName'),
            short_name: item['Group'].try(:[], 'Education').try(:[], 'Faculty').try(:[], 'ShortName')
          },
          speciality: {
            speciality_id: item['SpecialityCard'].try(:[], 'SpecialityId'),
            speciality_code: item['SpecialityCard'].try(:[], 'SpecialityCode'),
            speciality_name: item['SpecialityCard'].try(:[], 'SpecialityDirName'),
            speciality_dir_code: item['DirectionCode'],
            speciality_dir_name: item['SpecialityCard'].try(:[], 'SpecialityName'),
            speciality_type_name: 'аспирантура'
          },
          is_active: true,
          group_id: item['Group'].try(:[], 'GroupId'),
          group_name: item['Group'].try(:[], 'GroupName'),
          year_forming: item['Group'].try(:[], 'YearForming'),
          course: item['Group'].try(:[], 'Course'),
          semestre: item['Group'].try(:[], 'Semestre'),
          years_count: item['Group'].try(:[], 'EduYearsCount')
        }
      },
      group: {
        number: item['Group'].try(:[], 'GroupName'),
        course: item['Group'].try(:[], 'Course'),
        year_forming: item['Group'].try(:[], 'YearForming'),
        education_form: {
          kind: item['Group'].
            try(:[], 'Education').
            try(:[], 'EduForm').
            try(:[], 'EduFormName').
            gsub('Очная', 'full-time').
            gsub('Заочная', 'postal')
        },
        speciality: {
          code: item['SpecialityCard'].try(:[], 'SpecialityCode'),
          name: item['SpecialityCard'].try(:[], 'SpecialityDirName'),
          kind: 'аспирантура',
        },
        subfaculty: {
          name: item['ChairCard'].try(:[], 'SubFacultyName'),
          abbr: item['ChairCard'].try(:[], 'ShortName'),
          faculty: {
            name: item['Group'].try(:[], 'Education').try(:[], 'Faculty').try(:[], 'FacultyName'),
            abbr: item['Group'].try(:[], 'Education').try(:[], 'Faculty').try(:[], 'ShortName')
          }
        }
      }
    }
  end
end
