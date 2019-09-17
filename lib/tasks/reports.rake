require 'progress_bar'

namespace :reports do

  desc 'Группы с количеством бюджета/ПВЗ и признаком последнего курса'
  task groups_with_last_course: :environment do
    groups = Contingent.instance.groups.
      map{ |group| Hashie::Mash.new group }.
      select{ |group| group.education.is_active && group.course.to_i <= group.years_count.to_i }.
      sort_by(&:group_name)

    report = Axlsx::Package.new
    wb = report.workbook
    border_style = wb.styles.add_style(
      {
        alignment: {
          vertical: :center,
          wrap_text: true
        },
        border: { style: :thin, color: '00' }
      }
    )
    ws = wb.add_worksheet
    cells_types = []
    7.times{ cells_types << :string }
    ws.add_row [
      'Группа',
      'Курс',
      'Лет обучения',
      'Выпуск',
      'Бюджет',
      'ПВЗ',
      'Всего студентов',
    ], types: cells_types,
    style: border_style

    pb = ProgressBar.new(groups.count)

    groups.each do |group|
      if group.course.to_i > group.years_count.to_i
        pb.increment!
        next
      end

      params = { group: group.group_name }
      search ||= Search.new(params)
      students = Contingent.instance.students(search)

      if students.blank?
        pb.increment!
        next
      end
      budget, paid = students.partition{ |student| student.financing == 'Бюджет' }
      ws.add_row [
        group.group_name,
        group.course,
        group.years_count,
        group.course.to_i == group.years_count.to_i ? 'Да' : 'Нет',
        budget.count,
        paid.count,
        students.count
      ], types: cells_types,
      style: border_style

      pb.increment!
    end

    report.serialize(Rails.root.join(%(groups-with-last-course-#{Date.today}.xlsx)))
  end

  desc 'Вычисление разницы актуальных групп в контингенте и на портале'
  task active_groups: :environment do

    unless Rails.env.production?
      puts 'run this task with'
      puts 'RAILS_ENV=production'
      puts 'exit...'
      exit(1)
    end

    json = Rails.cache.read('active-groups')

    # json = nil # uncomment this if need force update groups
    # or run
    # bundle exec rake tmp:cache:clear

    if json.blank?
      active_groups = []

      ap 'Собираем группы бакалавров, специалистов и магистров из контингента'

      groups_list = Contingent.instance.groups

      pb = ProgressBar.new(groups_list.count)

      groups_list.each do |group|
        faculty_abbr = group[:education].try(:[], :faculty).try(:[], :short_name)

        if faculty_abbr =~ /АФ|ДепОбр|ФДО/
          # АФ     - Академический факультет
          # ДепОбр - Департамент образования
          # ФДО    - Факультет дистанционного обучения

          pb.increment!

          next
        end

        if group[:group_name] =~ /(_+|инд)$/
          # 1А6_, з-54Э__, 878-М1_, з-54У-инд и т.д.

          pb.increment!

          next
        end

        students_list = Contingent.instance.students(
          Search.new(
            group: group[:group_name],
            include_inactive: false
          )
        )

        if students_list.any?
          active_groups.push({
            number: group[:group_name],
            students_count: students_list.count
          })
        end

        pb.increment!
      end

      ap 'Собираем группы аспирантов из контингента'

      groups_list = Aspirant.collection({ op: 'GetAllActiveGraduateGroups' })

      pb = ProgressBar.new(groups_list.count)

      groups_list.each do |group|
        students_list = Aspirant.collection(
          group: group[:group_name]
        )

        if students_list.any?
          active_groups.push({
            number: group[:group_name],
            students_count: students_list.count
          })
        end

        pb.increment!
      end

      Rails.cache.write('active-groups', active_groups.to_json)
    else
      active_groups = JSON.load(json)
    end

    contingent_numbers = active_groups.map{ |hash| hash['number'] || hash[:number] }.sort

    ap 'Забираем группы актуальных и черновиков планов на портале'
    edu_numbers = JSON.load(RestClient.get("#{Settings['edu.url']}/api/v2/group_infos"))['groups'] rescue []

    ap 'Группы, которые есть только в контингенте'
    ap (contingent_numbers - edu_numbers)

    ap 'Группы, которые есть только на портале'
    ap (edu_numbers - contingent_numbers)
  end

  desc 'Генерация списка групп студентов с номерами зачётных книжек'
  task record_books: :environment do
    groups_list = Contingent.instance.groups
    array = Hashie::Mash.new(groups: groups_list)

    report = Axlsx::Package.new
    wb = report.workbook
    setup = { paper_width: '210mm', paper_height: '297mm',
              fit_to_width: 1, fit_to_height: 10_000 }
    margins = { left: 0.4, right: 0.4, top: 0.4, bottom: 0.4 }

    center_style = wb.styles.add_style(
      {
        alignment: {
          horizontal: :center,
          vertical: :center,
          wrap_text: true
        }
      }
    )

    center_bold_style = wb.styles.add_style(
      {
        alignment: {
          horizontal: :center,
          vertical: :center,
          wrap_text: true
        },
        b: true
      }
    )

    groups_list = array.
      groups.
      select{ |group| group.education.is_active }

    pb = ProgressBar.new(groups_list.count)

    groups_list = groups_list.
      sort_by{ |group| group.education.faculty.faculty_name }.
      group_by{ |group| group.education.faculty.faculty_name }

    groups_list.each do |faculty, groups|
      index = 0
      ws = wb.add_worksheet name: groups.first.education.faculty.short_name,
        page_setup: setup,
        page_margins: margins

      index += 1

      ws.add_row [
        faculty
      ], types: [:string], style: center_bold_style
      ws.merge_cells %(A#{index}:B#{index})

      groups.sort_by(&:group_name).each do |group|
        index += 1

        ws.add_row [
          group.group_name
        ], types: [:string], style: center_style
        ws.merge_cells %(A#{index}:B#{index})

        students_list = Contingent.instance.students(
          Search.new(group: group.group_name)
        )

        if students_list.any?
          hashie = Hashie::Mash.new(students: students_list)

          hashie.students.sort_by{ |student|
            [
              student.lastname,
              student.firstname,
              student.patronymic
            ].delete_if(&:blank?).join(' ')
          }.each do |student|
            index += 1

            ws.add_row [
              [
                student.lastname,
                student.firstname,
                student.patronymic
              ].delete_if(&:blank?).join(' '),
              student.zach_number
            ], types: [:string, :string]
          end
        else
          index += 1

          ws.add_row [
            'нет данных'
          ], types: [:string], style: center_style
          ws.merge_cells %(A#{index}:B#{index})
        end

        pb.increment!
      end
    end

    report.serialize(Rails.root.join(%(record-books-#{Date.today}.xlsx)))
  end

  desc 'Генерация списка групп с количеством студентов'
  task groups_with_count: :environment do
    groups_list = Contingent.instance.groups
    array = Hashie::Mash.new(groups: groups_list)

    report = Axlsx::Package.new
    wb = report.workbook
    setup = { paper_width: '210mm', paper_height: '297mm',
              fit_to_width: 1, fit_to_height: 10_000 }
    margins = { left: 0.4, right: 0.4, top: 0.4, bottom: 0.4 }

    center_bold_style = wb.styles.add_style(
      {
        alignment: {
          horizontal: :center,
          vertical: :center,
          wrap_text: true
        },
        b: true,
        border: { style: :thin, color: '00' }
      }
    )

    border_style = wb.styles.add_style(
      {
        alignment: {
          vertical: :center,
          wrap_text: true
        },
        border: { style: :thin, color: '00' }
      }
    )

    groups_list = array.
      groups.
      select{ |group|
        #%W[РКФ РТФ ФВС ФЭТ].include?(group.education.faculty.short_name) &&
        %W[бакалавриат инженерия магистратура].include?(group.education.speciality.speciality_type_name) &&
        group.education.is_active
      }

    pb = ProgressBar.new(groups_list.count)

    groups_list = groups_list.
      sort_by{ |group| group.education.faculty.faculty_name }.
      group_by{ |group| group.education.faculty.faculty_name }

    groups_list.each do |faculty, groups|
      index = 0
      ws = wb.add_worksheet name: groups.first.education.faculty.short_name,
        page_setup: setup,
        page_margins: margins

      index += 1

      ws.add_row [
        faculty
      ], types: [:string], style: center_bold_style
      ws.merge_cells %(A#{index}:G#{index})

      index += 1

      ws.add_row [
        'Номер',
        'Уровень',
        'Направление',
        'Кафедра',
        'Бюджет',
        'ПВЗ',
        'Всего'
      ], types: [:string, :string, :string],
      style: border_style

      groups.sort_by{ |group|
        [
          group.education.speciality.speciality_code,
          group.group_name
        ]
      }.each do |group|

        #if group.course != '1'
          #pb.increment!
          #next
        #end

        students_list = Contingent.instance.students(
          Search.new(group: group.group_name)
        )

        if students_list.any?
          index += 1

          ws.add_row [
            group.group_name,
            group.education.speciality.speciality_type_name,
            %(#{group.education.speciality.speciality_code} #{group.education.speciality.speciality_name}),
            group.education.sub_faculty.short_name,
            students_list.select{ |student| student.financing == 'Бюджет' }.count,
            students_list.reject{ |student| student.financing == 'Бюджет' }.count,
            students_list.count
          ], types: [:string, :string, :string],
          style: border_style
        end

        pb.increment!
      end
    end

    report.serialize(Rails.root.join(%(groups-with-count-#{Date.today}.xlsx)))
  end

end
