local strings = {
	RM_HEADING1 = "Mounts zu verwenden",
	RM_HEADING2 = "Haustiere zu benutzen",
}

if GetString(RM_HEADING1):len() == 0 then
	for key,value in pairs(strings) do
		SafeAddVersion(key, 1)
		ZO_CreateStringId(key, value)
	end
end