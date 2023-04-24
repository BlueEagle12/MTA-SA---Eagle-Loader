function isStringTrue (str)
	return (str == 'true')
end


streamTimes = {}
streamTimeObj = {}

function setModelStreamTime(model,sIn,sOut)
	streamTimes[model] = {sIn,sOut}
end


function isTimeBetween(startTimeHour, startTimeMinute, endTimeHour, endTimeMinute)
    local currentHour, currentMinute = getTime()

    local startTotalMinutes = startTimeHour * 60 + startTimeMinute
    local endTotalMinutes = endTimeHour * 60 + endTimeMinute
    local currentTotalMinutes = currentHour * 60 + currentMinute

    if startTotalMinutes <= endTotalMinutes then
        return currentTotalMinutes >= startTotalMinutes and currentTotalMinutes <= endTotalMinutes
    else
        return currentTotalMinutes >= startTotalMinutes or currentTotalMinutes <= endTotalMinutes
    end
end

setTimer(function()
    local hours = getTime()
	for _,obj in pairs(getElementsByType('object')) do
		if streamTimes[getElementModel(obj)] then
			local sIn,sOut = unpack(streamTimes[getElementModel(obj)])
			
			if isTimeBetween(sIn,0,sOut,0) then
				if not (streamTimeObj[obj] == 1) then
					streamTimeObj[obj] = 1
					setObjectScale(obj,1)
					if streamingDistances[getElementModel(obj)] then
						engineSetModelLODDistance (getElementModel(obj),streamingDistances[getElementModel(obj)])
					else
						engineResetModelLODDistance(getElementModel(obj))
					end
				end
			else
				if not (streamTimeObj[obj] == 2) then
					streamTimeObj[obj] = 2
					setObjectScale(obj,0)
					engineSetModelLODDistance (getElementModel(obj),0)
				end
			end
		end
	end
end, 500, 0)