local strings = {
	RM_HEADING1 = "Mounts to use",
	RM_HEADING2 = "Pets to use",
}

if GetString(RM_HEADING1):len() == 0 then
	for key,value in pairs(strings) do
		SafeAddVersion(key, 1)
		ZO_CreateStringId(key, value)
	end
end