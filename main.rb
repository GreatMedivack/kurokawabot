require 'telegram/bot'
require 'ap'
token = ''

require 'sqlite3'

@db = SQLite3::Database.new 'database.db'

emoji = {
		money: "\u{1F4B0}", 
		calendar: "\u{1F4C5}", 
		cup: "\u{1F3C6}",
		mark: "\u{25AA}",
		person: "\u{1F46E}",
		kiss: "\u{1F618}",
		phone: "\u{1F4F1}",
		gun: "\u{1F52B}",
		department: "\u{1F52F}",
		cheburek: "\u{1F473}",
		ok_condition: "\u{1F44D}",
		bad_condition: "\u{1F480}"
}

MONTHS = [nil, "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]

RIFLE_COLUMNS = [:id, :title, :condition, :user_id, :comment]
USER_COLUMNS = [:id, :name, :chat_id, :phone, :command, :object_id, :subject_id, :registred]
DONATE_COLUMS = [:id, :user_id, :sum, :created_at]
VALID_COMMANDS = ['/help', '/changename', '/donate']
ADMIN_ID = 98141300

main_menu =	[[
	        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Внести донат', callback_data: 'addDonate'),
	        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Расходы', callback_data: 'addExpense'),
	        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Объявление', callback_data: 'addDonate'),
	        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Привязать ствол', callback_data: 'linkRifle')
		]]
menu = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: main_menu)

user_menu = [['Топ донатеров'], ['Профиль', 'Мой донат']]
markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: user_menu, one_time_keyboard: false, resize_keyboard: true)
next_step = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [['Далее']], one_time_keyboard: true, resize_keyboard: true)
done = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [['Готово']], one_time_keyboard: true, resize_keyboard: true)

def user_not_exist?(id)
	(@db.execute "select * from users where chat_id = ?", id).empty?
end

def get_user_info(user_id)
	data = @db.execute(<<-SQL
		select users.name, users.phone, rifles.title, rifles.condition, departments.title 
		from ((users 
		left join rifles on users.rifle_id = rifles.id) 
		inner join departments on users.department_id = departments.id) 
		where users.id=#{user_id};
	SQL
	).first
	get_hash(data, [ :name, :phone, :rifle_title, :rifle_status, :department ])
end

def get_user(user_id)
	data = @db.execute("select * from users where id = ?", user_id).first
	get_hash(data, USER_COLUMNS)
end

def clear_command(user_id)
	@db.execute "update users set command=? where id=?", nil, user_id
end

def users_btns(command)
	btns = @db.execute("select * from users").map { |user| get_hash(user, USER_COLUMNS)}
		.map {|user| Telegram::Bot::Types::InlineKeyboardButton.new(text: user[:name], callback_data: "#{command}_#{user[:id]}")}
	Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)	
end

def rifles_btns(command)
	btns = @db.execute("select * from rifles").map { |rifle| get_hash(rifle, RIFLE_COLUMNS)}
		.map {|rifle| Telegram::Bot::Types::InlineKeyboardButton.new(text: rifle[:title], callback_data: "#{command}_#{rifle[:id]}")}
	btns << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Отвязать', callback_data: "#{command}_0")
	Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)	
end

def get_top_donaters
	data_m = @db.execute <<-SQL
		select max(donate), user, month
	    from (select sum(sum) as donate, users.name as user, strftime("%m-%Y", created_at) as month, users.id as id
	    from donations
	    inner join users on donations.user_id = users.id
	    group by strftime("%m-%Y", created_at), user_id)
	    group by month
	    order by month desc
	    ;
	SQL

	data_a = @db.execute <<-SQL
		select users.name, sum(sum) as donate 
		from donations 
		inner join users on donations.user_id = users.id 
		group by user_id order 
		by donate desc limit 5
		;
	SQL
	donate_m = data_m.map {|donate| get_hash(donate, [:sum, :name, :month])}
	donate_a = data_a.map {|donate| get_hash(donate, [:name, :sum])}
	[donate_m, donate_a]
end

def phone_format(number)
	"+#{number[0]} (#{number[1..3]}) #{number[4..6]}-#{number[7..8]}-#{number[9..10]}"
end

def get_hash(data, model)
	data ? model.map.with_index {|x, i| [x, data[i]]}.to_h : {}
end

def add_donate(user_id, sum)
	@db.execute "insert into donations (user_id, sum, created_at) values ( ?, ?, ? )", user_id, sum, Time.now.strftime("%Y-%m-%d")
end

def get_user_donations(user_id)
	data = @db.execute "select * from donations where user_id= ? order by created_at desc limit 9 ", user_id
	donations_list = data.map {|donate| get_hash(donate, DONATE_COLUMS)}
	donation_sum = @db.execute("select sum(sum) from donations where user_id = ?", user_id).flatten.first
	[donations_list, donation_sum]
end

def set_user_command(command, user_id)
	@db.execute "update users set command=? where id=?", 
											command,
											user_id  
end

def set_user_object(obj_id, user_id)
	@db.execute "update users set object_id=? where id=?", 
											obj_id,
											user_id
end

def set_user_subject(obj_id, user_id)
	@db.execute "update users set subject_id=? where id=?", 
											obj_id,
											user_id
end

def reset_command(user_id)
	@db.execute "update users set command=?, subject_id=?, object_id=? where id=?", 
											nil, nil, nil,
											user_id
end

def parse_month(date)
	res = date.split('-')
	"#{MONTHS[res[0].to_i]} #{res[1]} год"

end

def delete_last_donate
	@db.execute "DELETE FROM donations WHERE id = (SELECT MAX(id) FROM donations)"
end

Telegram::Bot::Client.run(token) do |bot|
	bot.listen do |message|
		  user = get_hash(@db.execute("select * from users where chat_id = ?", message.from.id).first, USER_COLUMNS)
		  if user.empty? and message.text != '/start'
			bot.api.send_message(chat_id: message.from.id, text: 'Я тебя не знаю! набери /start для начала') 
		 	next
		  end

		  case message
		  when Telegram::Bot::Types::CallbackQuery
		  	puts "type callback"

########### КОЛЛБЭКИ
			ap message.data


			if message.data == 'linkRifle'
				bot.api.edit_message_text(message_id: message.message.message_id, chat_id: message.from.id, text: 'Выбери пользователя', reply_markup: users_btns("linkUserToRifle"))
				next
			end

			if message.data =~ /linkRifleToUser_\d+/
				rifle_id = message.data.slice(/\d+/)
				user = get_user(user[:id])
				@db.execute "update users set rifle_id=? where id=?", rifle_id, user[:object_id]
				bot.api.edit_message_text(message_id: message.message.message_id, chat_id: message.from.id, text: 'Властвуй :3', reply_markup: menu)
				bot.api.send_message(chat_id: message.from.id, text: 'Оружие привязано') 
				reset_command(user[:id])
				next
			end

			if message.data =~ /linkUserToRifle_\d+/
				user_id = message.data.slice(/\d+/)
				set_user_object(user_id, user[:id])
				bot.api.edit_message_text(message_id: message.message.message_id, chat_id: message.from.id, text: 'Выбери пушку', reply_markup: rifles_btns("linkRifleToUser"))
			next
			end

			if message.data =~ /addUserDonate_\d+/
				user_id = message.data.slice(/\d+/)
				set_user_object(user_id, user[:id])
				bot.api.edit_message_text(message_id: message.message.message_id, chat_id: message.from.id, text: 'Властвуй :3', reply_markup: menu)
				bot.api.send_message(chat_id: message.from.id, text: 'Введи сумму:') 
			next
			end

			if message.data == 'addDonate'
				set_user_command(message.data, user[:id])
				bot.api.edit_message_text(message_id: message.message.message_id, chat_id: message.from.id, text: 'Выбери пользователя', reply_markup: users_btns("addUserDonate"))
				next
			end

		  when Telegram::Bot::Types::InlineQuery
		  	puts "type inline query"

		  when Telegram::Bot::Types::Message
		  	puts "type message"
		  	next if message.chat.id == -34153783	

########### ПРЯМЫЕ КОМАНДЫ

		  	if message.text == '/start'
		  		@db.execute "insert into users (chat_id) values ( ? )", message.from.id if user.empty?
		    	bot.api.send_message(chat_id: message.from.id, text: 'Необходимо пройти первичную регистрацию', reply_markup: next_step) if user[:phone].nil? or user[:name].nil?
		    	next
		  	end

		  	if message.text == '/userMenu'
		    	bot.api.send_message(chat_id: message.from.id, text: 'Необходимо пройти первичную регистрацию', reply_markup: markup)
		  		next
		  	end

		  	if message.text == '/adminMenu'
		    	bot.api.send_message(chat_id: message.from.id, text: 'Властвуй :3', reply_markup: menu)
		    	next
		  	end

		  	if message.text == '/delLast'
		  		delete_last_donate
		    	bot.api.send_message(chat_id: message.from.id, text: 'Последний донат удален')
		    	next
		  	end

		  	if message.text == 'Мой донат'
		  		donations = get_user_donations(user[:id])
		  		msg = ''
		  		donations[0].each_with_index do |donate, index|
		  			msg += "#{index + 1}.\t\t\t\t#{donate[:created_at]}\t\t\t\t#{emoji[:money]}#{donate[:sum]}р.\n"
		  		end
		  		if msg.empty?
		  			msg = 'Из-за таких, как ты у нас нет шаров!' 
		  		else
		  			msg += "\nЗа все время вдоначено #{emoji[:money]}#{donations[1]}\n"
		  		end
		    	bot.api.send_message(chat_id: message.from.id, text: msg)
		    	next
		  	end

		  	if message.text == 'Профиль'
		  		user_info = get_user_info(user[:id])
		  		msg = "#{emoji[:cheburek]}Позывной: #{user_info[:name]}\n"
		  		msg += "#{emoji[:phone]}Телефон: #{phone_format(user_info[:phone])}\n"
		  		msg += "#{emoji[:gun]}Оружие: #{user_info[:rifle_title] ||= 'не закреплено' }"
		  		if user_info[:rifle_status].nil?
		  		msg += "\n"
		  		else
		  		msg += "\t[состояние:#{user_info[:rifle_status] == 1 ? emoji[:ok_condition] : emoji[:bad_condition]}]\n"
		  		end
		  		msg += "#{emoji[:department]}Отеделение: #{user_info[:department]}"
		    	bot.api.send_message(chat_id: message.from.id, text: msg)
		    	next
		  	end

		  	if message.text == 'Топ донатеров'
		  		data = get_top_donaters
		  		msg = ''
		  		msg += "\n#{emoji[:calendar]}ТОП по месяцам\n"
		  		data[0].each_with_index do |donate, index|
		  			msg += "\t#{emoji[:mark]}#{parse_month(donate[:month])}\n\t\t\t#{emoji[:person]}#{donate[:name]}\t\t\t\t(#{emoji[:money]}#{donate[:sum]}р.)\n"
		  		end
		  		msg += "\n#{emoji[:cup]}ТОП общий\n"
		  		data[1].each_with_index do |donate, index|
		  			msg += "\t\t#{index + 1}. #{donate[:name]}\t\t\t\t(#{emoji[:money]}#{donate[:sum]}р.)\n"
		  		end
		    	bot.api.send_message(chat_id: message.from.id, text: msg)
		  		next
		  	end

########### КООМАНДЫ

		  	if user[:command] == 'changeName'

		  		if not message.text =~ /[а-я А-Я]+/
		    		bot.api.send_message(chat_id: message.from.id, text: 'Допустима только кириллица! \0')
		  			next
		  		end
		  		@db.execute "update users set name=? where id=?", 
		  													message.text,
		  													user[:id]  
		  		if user[:name].nil?
		    		bot.api.send_message(chat_id: message.from.id, text: 'Позывной принят', reply_markup: next_step) 
				else
		    		bot.api.send_message(chat_id: message.from.id, text: 'Имя изменено')
		    	end
		    	clear_command user[:id]		
		    	next
		  	end

		  	if user[:command] == 'changePhone'

		  		if message.text.gsub(/\D/,'').size != 11
		    		bot.api.send_message(chat_id: message.from.id, text: 'В формате +7 ХХХ ХХХ ХХ ХХ')
		  			next
		  		end
		  		@db.execute "update users set phone=? where id=?", 
		  													message.text,
		  													user[:id]  
		  		if user[:phone].nil?
		    		bot.api.send_message(chat_id: message.from.id, text: 'Телефон принят', reply_markup: done) 
		    	else
		    		bot.api.send_message(chat_id: message.from.id, text: 'Телефон изменен')
		    	end
		    	clear_command user[:id]	
		    	next
			end

			if user[:command] == 'addDonate' and user[:object_id] != nil
				add_donate(user[:object_id], message.text.to_i)
				object = get_user(user[:object_id])
				reset_command(user[:id])
				bot.api.send_message(chat_id: message.from.id, text: "#{object[:name]} задонатил #{message.text}р. \n Нажми \/delLast что-бы удалить последний донат") 
				bot.api.send_message(chat_id: object[:chat_id], text: "#{object[:name]}, спасибо за взнос!#{emoji[:kiss]}") 
				next
			end

########### ИНИЦИАЛИЗАЦИЯ ПОЛЬЗОВАТЕЛЯ

		  	unless user[:name]
		    	bot.api.send_message(chat_id: message.from.id, text: 'Укажи свой позывной')
		    	set_user_command('changeName', user[:id])
		  		next
		  	end 

		  	unless user[:phone]
		    	bot.api.send_message(chat_id: message.from.id, text: 'Укажи свой телефон')
		    	set_user_command('changePhone', user[:id])
		    	next
		  	end

		  	if message.text == 'Готово' and user[:registred] == 0
		    	bot.api.send_message(chat_id: message.from.id, text: 'Регистрация завершена', reply_markup: markup)
		    	@db.execute "update users set registred=? where id=?", 1, user[:id]
		    	next
		  	end

		end
	end
end