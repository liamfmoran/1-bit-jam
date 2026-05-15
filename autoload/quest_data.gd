extends Node

var quest_leaf = {'Source':'',
'Faction':'',
'Destination':'',
'Reward':'',
'Time Limit':''}

var quests = {}

func get_possible_quests(current_station):
	var possible_quests = []
	for i in quests: 
		if i['Source'] == current_station:
			possible_quests.append(i)

	return possible_quests
