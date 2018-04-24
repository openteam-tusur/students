class Aspirant
  def self.collection(params)
    @response = RestClient::Request.execute(
      method: :get,
      url: Settings['aspirants.url'],
      user: Settings['aspirants.login'],
      password: Settings['aspirants.pass'],
      timeout: 120.seconds,
      headers: {
        params: {
          'op' => 'GetGraduatesByCriteria'
        }.merge(search_params(params))
      }
    ) do |response, _request, _result|
      json = begin
               JSON.load(response.body)
             rescue
               []
             end

      json.select { |item| item.try(:[], 'Status').try(:[], 'DictionaryId') == '10' }
          .map { |item| transform_to_contingent_responce(item) }
    end
  end

  private

  def self.search_params(params)
    {
      'GroupNumber'      => params[:group],
      'LastName'         => params[:lastname],
      'FirstName'        => params[:firstname],
      'MiddleName'       => params[:patronymic]
    }
  end

  def self.transform_to_contingent_responce(item)
    {
      person_id: item['PersonId'],
      begin_study: I18n.l(Time.zone.parse(item['EduBeginDate'])),
      born_on: I18n.l(Time.zone.parse(item['BirthDate'])),
      citizenship: item['Citizenship']['Name'],
      firstname: item['FirstName'],
      lastname: item['LastName'],
      patronymic: item['MiddleName']
    }
  end
end
