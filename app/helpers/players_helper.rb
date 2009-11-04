module PlayersHelper

	def show_avatar(player, size = :small)
		res = ''
		if player.avatar
			res += link_to(image_tag(player.avatar.public_filename(size)),
				user_player_path(player.user, player))
		else
			size_string = size == :small ? '50x50' : '100x100'
			res += link_to(image_tag('/avatars/default.jpg', :size => size_string),
				user_player_path(player.user, player))
		end
		res
	end

	def show_short_player_info(player)
		res = link_to_player_team(player)
		if res.length > 0 and player.date_of_birth
			res += ', '
		end
		res += player_year_of_birth(player)
		res
	end

	def link_to_player(player)
		link_to player.full_name, user_player_path(player.user, player)
	end

	def link_to_player_team(player)
		res = ''
		if player.team
			res += link_to player.team.name, user_team_path(player.user, player.team)
		end
		res
	end

	def player_year_of_birth(player)
		res = ''
		if player.date_of_birth
				res += player.date_of_birth.year.to_s
		end
		res
	end

end