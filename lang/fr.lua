local strings = {
	RM_HEADING1 = "Se monte à utiliser",
	RM_HEADING2 = "Animaux à utiliser",
}

if GetString(RM_HEADING1):len() == 0 then
	for key,value in pairs(strings) do
		SafeAddVersion(key, 1)
		ZO_CreateStringId(key, value)
	end
end