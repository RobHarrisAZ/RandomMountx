local strings = {
	RM_HEADING1 = "使用するマウント",
	RM_HEADING2 = "ペットを使用する",
}

if GetString(RM_HEADING1):len() == 0 then
	for key,value in pairs(strings) do
		SafeAddVersion(key, 1)
		ZO_CreateStringId(key, value)
	end
end