require 'progress_bar'

namespace :reports do

  desc 'Генерация списка групп студентов с номерами зачётных книжек'
  task record_books: :environment do
    groups_list = Contingent.instance.groups
    array = Hashie::Mash.new(groups: groups_list)

    pb = ProgressBar.new(groups_list.count)

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
      select{ |group| group.education.is_active }.
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
