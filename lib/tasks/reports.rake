require 'csv'
require 'progress_bar'
require 'roo'

namespace :reports do

  desc 'Сбор данных о приказах о зачислении и отчислении должников за проживание в общежитиях'
  task hostel_debtors: :environment do
    xlsx = Roo::Spreadsheet.open('./PVZ-2020-12-10.xlsx')
    debtors = []
    orders = []
    pb = ProgressBar.new(xlsx.last_row - 1)
    xlsx.each_row_streaming(offset: 1) do |row|
      debtor = Hashie::Mash.new({
        index: row[0].value,
        fullname: row[1].value,
        hostel: row[2].value,
        group: row[3].value.to_s,
        faculty: row[4].value,
        end_year: row[5].value,
        begin_order_number: nil,
        begin_order_date: nil,
        begin_order_kind: nil,
        end_order_number: nil,
        end_order_date: nil,
        end_order_kind: nil,
      })

      surname, name, patronymic, patronymic_postfix = debtor.fullname.squish.split(/\s/)

      request_collection = {
        lastname: surname,
        firstname: name,
        patronymic: [patronymic, patronymic_postfix].compact.join(' '),
        include_inactive: '1'
      }

      if debtor.group =~ /аспирант/i
        infos = Aspirant.collection(request_collection)

        info = infos.find do |item|
          item.orders.find do |order|
            order.title =~ /Об отчислении/i && order.date =~ /\d{2}\.\d{2}\.#{debtor.end_year}/
          end
        end

        if info.present?
          order = info.orders.find{ |item| item.title =~ /О зачислении/i }
          debtor.begin_order_number = order.numb
          debtor.begin_order_date = order.date
          debtor.begin_order_kind = order.title

          order = info.orders.find{ |item| item.title =~ /Об отчислении/i }
          debtor.end_order_number = order.numb
          debtor.end_order_date = order.date
          debtor.end_order_kind = order.title
        end
      else
        infos = Contingent.instance.students(
          Search.new(
            request_collection.merge!(group: debtor.group, include_inactive: true)
          )
        )

        if infos.many?
          ap debtor.fullname
          ap debtor.group
          ap infos.map{ |item|
            [
              item.name,
              item.student_state,
              item.group.number
            ]
          }
        end

        info = infos.first

        if info.orders_data.any?
          orders << Hashie::Mash.new({
            debtor: debtor,
            orders: info.orders_data
          })

          info.orders_data.each do |order_info|
            if order_info.title =~ /О зачислении в число студентов|Зачисление переводом из другого ВУЗа/i
              debtor.begin_order_number = order_info.numb
              debtor.begin_order_date = order_info.date
              debtor.begin_order_kind = order_info.title

              break
            end
          end

          info.orders_data.reverse.each do |order_info|
            if order_info.title =~ /Окончание ВУЗа|Отчисление/i
              debtor.end_order_number = order_info.numb
              debtor.end_order_date = order_info.date
              debtor.end_order_kind = order_info.title

              break
            end
          end

        else
          ap request_collection
          ap debtor.fullname
          ap info.orders_data
        end
      end
      debtors << debtor

      ap debtor

      pb.increment!
    end

    CSV.open(%(hostel-debtors-#{Date.today}.csv), 'wb', col_sep: ';') do |csv|
      csv << [
        '№',
        'ФИО',
        '№ общ.',
        'группа',
        'факультет',
        'год отчисления',
        'номер приказа о зачислении',
        'дата приказа о зачислении',
        'наименование приказа о зачислении',
        'номер приказа об отчислении',
        'дата приказа об отчислении',
        'наименование приказа об отчислении',
      ]
      debtors.each_with_index do |debtor, index|
        csv << [
          (index + 1),
          debtor.fullname,
          debtor.hostel,
          debtor.group,
          debtor.faculty,
          debtor.end_year,
          debtor.begin_order_number,
          debtor.begin_order_date,
          debtor.begin_order_kind,
          debtor.end_order_number,
          debtor.end_order_date,
          debtor.end_order_kind,
        ]
      end
    end
  end

  desc 'Дубли активных бакалавров и магистров по ФИО и дате рождения'
  task doubles: :environment do
    unless Rails.env.production?
      puts 'run this task with'
      puts 'RAILS_ENV=production'
      puts 'exit...'
      exit(1)
    end

    # bundle exec rake tmp:cache:clear

    groups = Contingent.instance.groups.
      map{ |group| Hashie::Mash.new group }.
      select{ |group| group.education.is_active }

    pb = ProgressBar.new(groups.count)
    students = []

    groups.each do |group|
      params = {
        group: group.group_name,
        include_inactive: false,
        include_aspirants: false,
      }
      search = Search.new(params)
      students_in_group = Contingent.instance.students(search)

      students << students_in_group
      pb.increment!
    end

    students.flatten!.reverse!

    students = students.group_by{ |student|
      [%(#{student.lastname} #{student.firstname}), student.born_on].join(', ')
    }.select{ |_, v| v.many? }

    CSV.open(%(active-doubles-#{Date.today}.csv), 'wb', col_sep: ';') do |csv|
      students.each do |name, items|
        items.each do |item|
          csv << [
            name.split(',').first.squish,
            item.born_on,
            item.education.faculty.abbr,
            %('#{item.group}),
            item.speciality.kind,
          ]
        end
      end
    end
  end

  desc 'Количество студентов 1 курса по факультетам'
  task first_year_count: :environment do
    groups = Contingent.instance.groups.
      map{ |group| Hashie::Mash.new group }.
      select{ |group| group.education.is_active && group.course.to_i <= group.years_count.to_i }.
      sort_by(&:group_name)

    groups.group_by{ |g| g.education.faculty.short_name }.each do |abbr, grps|
      count = 0
      grps.each do |group|
        next if group.course != '1'
        params = { group: group.group_name }
        search = Search.new(params)
        students = Contingent.instance.students(search)
        count += students.count
      end
      ap %(#{abbr}: #{count})
    end
  end

  desc 'Группы с количеством бюджета/ПВЗ и признаком последнего курса'
  task groups_statistics: :environment do
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
    border_center_style = wb.styles.add_style(
      {
        b: true,
        alignment: {
          vertical: :center,
          horizontal: :center,
          wrap_text: true
        },
        border: { style: :thin, color: '00' }
      }
    )
    worksheet_title = %(Статистика по группам, #{I18n.l Time.zone.now, format: '%d.%m.%Y %H:%M'})
    ws = wb.add_worksheet name: worksheet_title.split(',').last.squish.gsub(':', '-')

    header = [
      'Группа',
      'Курс',
      'Факультет',
      'Кафедра',
      'Лет обучения',
      'Выпуск',
      'Бюджет',
      'ПВЗ',
      'Всего студентов',
    ]

    alpha_table = {}
    (('A'...'Z').zip(1...26)).each { |elem| alpha_table[elem[1]] = elem[0] }

    index = 1
    ws.add_row [
      worksheet_title
    ], types: [:string], style: border_center_style
    ws.merge_cells %(A#{index}:#{alpha_table[header.count]}#{index})

    cells_types = []
    header.count.times{ cells_types << :string }

    index += 1
    ws.add_row header,
      types: cells_types, style: border_style

    pb = ProgressBar.new(groups.count)

    grouped_groups = groups.group_by{ |group|
      speciality = group.education.speciality
      [
        speciality.speciality_code,
        speciality.speciality_name
      ].join(' ')
    }.sort_by{ |speciality, _|
      code = speciality.split(' ').first
      sign = code
      if code =~ /\./
        part = code.split('.')
        sign = [part.second, part.first, part.third].join
      else
        sign = ['99', code].join
      end

      sign
    }

    grouped_groups.each do |speciality, grps|
      index += 1
      ws.add_row [
        speciality
      ], types: [:string], style: border_center_style
      ws.merge_cells %(A#{index}:#{alpha_table[header.count]}#{index})
      grps.each do |group|
        if group.course.to_i > group.years_count.to_i
          pb.increment!
          next
        end

        params = { group: group.group_name }
        search = Search.new(params)
        students = Contingent.instance.students(search)

        if students.blank?
          pb.increment!
          next
        end

        budget, paid = students.partition{ |student| student.financing == 'Бюджет' }
        index += 1
        ws.add_row [
          group.group_name,
          group.course,
          (group.education.faculty.short_name rescue ''),
          (group.education.sub_faculty.short_name rescue ''),
          group.years_count,
          group.course.to_i == group.years_count.to_i ? 'Да' : 'Нет',
          budget.count,
          paid.count,
          students.count
        ], types: cells_types,
        style: border_style

        pb.increment!
      end
    end

    report.serialize(Rails.root.join(%(groups-statistics-#{Date.today}.xlsx)))
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

    json = nil # uncomment this if need force update groups
    # or run
    # bundle exec rake tmp:cache:clear

    if json.blank?
      active_groups = []

      ap 'Собираем группы бакалавров, специалистов и магистров из контингента'

      groups_list = Contingent.instance.groups.
        map{ |group| Hashie::Mash.new group }

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
    groups_list = Contingent.instance.groups.
      map{ |group| Hashie::Mash.new group }.
      select{ |group| group.education.is_active && group.course.to_i <= group.years_count.to_i }

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

end
