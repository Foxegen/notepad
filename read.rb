if Gem.win_platform?
  Encoding.default_external = Encoding.find(Encoding.locale_charmap)
  Encoding.default_internal = __ENCODING__

  [STDIN, STDOUT].each do |io|
    io.set_encoding(Encoding.default_external, Encoding.default_internal)
  end
end

require_relative 'post'
require_relative 'memo'
require_relative 'link'
require_relative 'task'

require 'optparse'

options = {}

OptionParser.new do |opt|
  opt.banner = 'Usage: read.rb [options]'

  opt.on('-h', 'Prints this help') do
    puts opt
    exit
  end

  opt.on('--type POST_TYPE', 'какой тип постов показывать (по умолчанию любой)') { |o| options[:type] = o}
  opt.on('--id POST_ID', 'если задан id — показываем подробно только этот пост') { |o| options[:id] = o}
  opt.on('--limit NUMBER', 'сколько последних постов показать (по умолчанию все)') { |o| options[:limit] = o}
end.parse!

result = Post.find(options[:limit], options[:type], options[:id])

if result.is_a? Post
  puts "Запись #{result.class.name}, id = #{options[:id]}"

  result.to_strings.each do |line|
    puts line
  end

else # покажем таблицу результатов
  id_size = 0
  text_size = 0
  url_size = 0
  due_date_size = false

  # Наполняем переменные size
  result.each do |row|
    if row[0].size > id_size
      id_size = row[0].size
    end

    if !row[3].nil? && row[3].split("\n").join(" ").size > text_size
      text_size = row[3].split("\n").join(" ").size
    end

    if !row[4].nil? && row[4].size > url_size
      url_size = row[4].size
    end

    unless row[5].nil?
      due_date_size = true
    end
  end

  # Ограничение для text_size
  text_size = 40 if text_size > 40

  # Выводим поля таблицы
  print "| id " + " "*(id_size - 4) + "| @type |  @created_at" + " "* 14
  print "|" if text_size == 0 && url_size == 0 && !due_date_size

  # Исключаем отсутвие поля @text
  unless text_size == 0

    if text_size < 5
      print "| @text "

      # Добавляем "|", если после поля @text нет других полей
      print "|" if url_size == 0 && !due_date_size
    else
      print "| @text " + " "*(text_size - 5)

      # Добавляем "|", если после поля @text нет других полей
      print "|" if url_size == 0 && !due_date_size
    end
  end

  # Исключаем отсутвие поля @url
  unless url_size == 0

    if url_size < 4
      print "| @url "

      # Добавляем "|", если после поля @url нет других полей
      print "|" unless due_date_size
    else
      print "| @url " + " "*(url_size - 4)

      # Добавляем "|", если после поля @url нет других полей
      print "|" unless due_date_size
    end
  end

  # Исключаем отсутствие @due_date
  if due_date_size
    print "| @due_date  |"
  end


  # Выводим данные таблицы
  result.each do |row|
    puts

    print "| #{row[0]}  |"
    print " #{row[1]}  |"
    print " #{row[2]} |"

    # Исключаем отсутствие @text
    unless text_size == 0

      # Выводим значение, когда отсутствует поле text у row и все поля text меньше, чем заголовок @text
      if row[3].nil? && text_size < 5
        print " "* 7 + "|"
      # Выводим значение, когда все поля text меньше, чем заголовок @text
      elsif text_size < 5
        print " #{row[3].split("\n").join(" ")} " + " "*(5 - row[3].size) + "|"
      # Выводим значение, когда отсутствует поле text у row
      elsif row[3].nil?
        print "  " + " "*text_size + "|"
      # Выводим значение, когда хотя бы одно поле text больше, чем заголовок @text или равно ему
      else
        print " #{row[3].split("\n").join(" ")[0..40]} " + " "*(text_size - row[3].size) + "|"
      end
    end

    # Исключаем отсутствие @url
    unless url_size == 0

      # Выводим значение, когда отсутствует поле url у row и все поля url меньше, чем заголовок @url
      if row[4].nil? && url_size < 4
        print " "* 6 + "|"
      # Выводим значение, когда все поля url меньше, чем заголовок @url
      elsif url_size < 4
        print " #{row[4]} " + " "*(4 - row[4].size) + "|"
      # Выводим значение, когда отсутствует поле url у row
      elsif row[4].nil?
        print "  " + " "*url_size + "|"
      # Выводим значение, когда хотя бы одно поле url больше, чем заголовок @url или равно ему
      else
        print " #{row[4]} " + " "*(url_size - row[4].size) + "|"
      end
    end

    # Исключаем отсутствие @due_date
    if due_date_size

      # Выводим значение, когда отсутствует поле due_date у row
      if row[5].nil?
        print " "* 12 + "|"
      # Выводим поле due_date
      else
        print " #{row[5]} |"
      end
    end
  end
end

puts