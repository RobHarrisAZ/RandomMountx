local strings = {
	RM_HEADING1 = "Лошади для использования",
	RM_HEADING2 = "Домашние животные использовать",
}

if GetString(RM_HEADING1):len() == 0 then
	for key,value in pairs(strings) do
		SafeAddVersion(key, 1)
		ZO_CreateStringId(key, value)
	end
end