print("Short hash", potatOS.build)
print("Full hash", potatOS.full_build)
local mfst = potatOS.registry.get "potatOS.current_manifest"
if mfst then
	print("Counter", mfst.build)
	print("Built at (local time)", os.date("%Y-%m-%d %X", mfst.timestamp))
	print("Downloaded from", mfst.manifest_URL)
	local verified = mfst.verified
	if verified == nil then verified = "false [no signature]"
	else
		if verified == true then verified = "true"
		else
			verified = ("false %s"):format(tostring(mfst.verification_error))
		end
	end
	print("Signature verified", verified)
else
	print "Manifest not found in registry. Extended data unavailable."
end