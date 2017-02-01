-----------------------------------------------------------------------------
--	b.lua: A module with various functions aimed for Domoticz
--	Author: BakSeeDa (บักสีดา)
--	Homepage: https://www.domoticz.com/forum/memberlist.php?mode=viewprofile&u=7064
--	Version: 1.0.2
-----------------------------------------------------------------------------
--	This module is free software: you can redistribute it and/or modify
--	it under the terms of the GNU General Public License as published by
--	the Free Software Foundation, either version 3 of the License, or
--	(at your option) any later version.

--	This module is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--	GNU General Public License for more details.

--	You should have received a copy of the GNU General Public License
--	along with this module. If not, see <http://www.gnu.org/licenses/>.
-----------------------------------------------------------------------------
--
--	REQUIREMENTS:
--		Domoticz running on Raspberry Pi.
--
--	CHANGELOG
--		1.0.2 Minor changes.
--		1.0.1 Check for localhost configuration in uservariable GCalHostAndPort
--		1.0.0 First release.
--		0.1.0	Added this information header.
-----------------------------------------------------------------------------

local b = {}             -- Public namespace
local b_private = {}     -- Private namespace

local EMPTYSTRING = "Empty String"
local NOTHINGTOSAY = "Inget att säga" -- You may translate this into your own language
b.debug = 3 -- initial default
b.debugPre = "debugPre NOT SET: "
b.localhost = uservariables["GCalHostAndPort"] or "localhost:8080"

function b.DEBUG(level,s)
  if (level <= b.debug) then print(b.debugPre ..": "..s) end
end

function b.timedifference(s)
	year = string.sub(s, 1, 4)
	month = string.sub(s, 6, 7)
	day = string.sub(s, 9, 10)
	hour = string.sub(s, 12, 13)
	minutes = string.sub(s, 15, 16)
	seconds = string.sub(s, 18, 19)
	t1 = os.time()
	t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
	difference = os.difftime (t1, t2)
	return difference
 end

-- Return a Unix Timestamp
function normalize(a)
    local m,d,y,h,mi,n=a:match("(%d+)/(%d+)/(%d+)%s+(%d+):(%d+)%s+(%w+)")
    if n=="PM" then h=h+12 end
    return string.format("%04d%02d%02d%02d%02d",y,m,d,h,mi)
end

function b.setVar(uservariablename, uservariablevalue, uservariabletype)
  -- uservariabletype:  0 = Integer, 1 = Float, 2 = String, 3 = Date in format DD/MM/YYYY, 4 = Time in 24 hr format HH:MM
	uservariabletype = uservariabletype or 2 -- Defaults to 2
	if (uservariablename ~= nil) then
    if (uservariablevalue == nil or uservariablevalue == "") then
      if (uservariabletype == 0) then uservariablevalue = 0
      elseif (uservariabletype == 1) then uservariablevalue = 0.0
      elseif (uservariabletype == 2) then uservariablevalue = EMPTYSTRING -- Empty strings are problematic in an URL
      elseif (uservariabletype == 3) then uservariablevalue = os.date ("%x")
      elseif (uservariabletype == 4) then uservariablevalue = os.date ("%H:%M")
      else
        b.DEBUG(1,"Invalid uservariabletype passed to setVar function")
        return
      end
    end
    if (uservariables[uservariablename] == nil) then
      --print("Create a new User Variable: "..uservariablename.." Value: " ..uservariablevalue.." Type: " ..uservariabletype)
      b.OpenURL("http://"..b.localhost.."/json.htm?type=command&param=saveuservariable&vname="..uservariablename.."&vtype="..uservariabletype.."&vvalue="..b.urlencode(uservariablevalue))
      --print("http://"..b.localhost.."/json.htm?type=command&param=saveuservariable&vname="..uservariablename.."&vtype="..uservariabletype.."&vvalue="..b.urlencode(uservariablevalue))
    else
      --print("The User Variable "..uservariablename.." already exists, just update it")
      commandArray["Variable:"..uservariablename] = tostring(uservariablevalue)
    end
  end
end

function b.getVar(uservariablename)
  local v
  v = uservariables[uservariablename]
  if v == EMPTYSTRING then -- Newly created string variable that needs to be set to ""
    commandArray["Variable:"..uservariablename] = ""
    v = ""
  end
	return v
end

local DISARMED = "Disarmed"
function b.homeAwake()
	return (otherdevices_svalues["Z1 Alarm"] == DISARMED and true or false)
end

function b.getSecurityState()
	return otherdevices_svalues["Z1 Alarm"]
end

function b.urlencode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w ])",
		function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
	end
	return str
end

function b.runcommand(command)
	--b.DEBUG(3, "Running command: " .. command)
	h=io.popen(command)
	response=h:read("*a")
	h:close()
	return(response)
end

function b.blinkLight(light, times)
	times = times or 2
	local cmd1 = 'Off'
	local cmd2 = 'On'
	local pause = 0
	if (otherdevices[light] == 'Off') then
		cmd1 = 'On'
		cmd2 = 'Off'
	end	
	for i = 1, times do
		commandArray[#commandArray + 1]={[light]=cmd1..' AFTER '..pause }
		pause = pause + 3
		commandArray[#commandArray + 1]={[light]=cmd2..' AFTER '..pause }
		pause = pause + 3
	end
end

function b.OpenURL(url)
	-- The commandArray also supports nested tables to send the same command type multiple times.
	-- To do this, give the command a numeric index
	commandArray[#commandArray + 1]={['OpenURL']=url }
end

function b.AutoRemote(arMessage, deliverTo)
	local url
	if ((deliverTo == "") or (deliverTo == nil) or (deliverTo == "Narva2") or (deliverTo == "Default")) then deliverTo = uservariables["SpeakTo"] end
	if (deliverTo == "Default") then -- Use LAN access to device for inhouse Speaker
		local ip = "192.168.10.6"
		url = "http://" .. ip .. ":1817/?message=" .. b.urlencode(arMessage) .. "&password=" .. b.getVar("ARPassw") .. "&sender=Vera"
	elseif (otherdevices['Internet'] == 'On') then -- We have Internet access, use GCM Server for delivery
		url = "https://autoremotejoaomgcd.appspot.com/sendmessage?key="
		url = url .. (deliverTo == "MastersCellPhone" and b.getVar("ARKey1") or (deliverTo == "SonsCellPhone" and b.getVar("ARKey2") or (deliverTo == "Uth" and b.getVar("ARKey4") or b.getVar("ARKey3")))) .. "&message=" .. b.urlencode(arMessage) .. "&password=" .. b.getVar("ARPassw") .. "&sender=Vera"
	else -- No Internet access so delivery is not possible
		return
  end
	b.OpenURL(url)
end

function b.speak(speakMessage, deliverTo, canSpeakAtNight)
	speakMessage = speakMessage or NOTHINGTOSAY
	canSpeakAtNight = canSpeakAtNight or 0
	if ((deliverTo == "") or (deliverTo == nil)) then deliverTo = b.getVar("RecDef") end
	if ((not b.homeAwake()) and canSpeakAtNight == 0) or ((otherdevices["Mobiltelefon JMC"] == "Off") and deliverTo == "SonsCellPhone" and canSpeakAtNight == 0) then
		return -- Not a good time to speak unless canSpeakAtNight flag was specified
	end
	b.AutoRemote("SpeakIt=:=" .. speakMessage, deliverTo)
	--if ((deliverTo == "Default") and (getMultiSwitch(22, 3) == "1")) then -- Using bluetooth
	--  AutoRemote("SpeakIt=:=" .. speakMessage, "MastersCellPhone")
	--end
end

function b.smsEncode(str)
	-- Convert to GSM 03.38 character set and URL-encode
	local utf8Chars={"%%","\n"," ",'"',"&",",","%.","/",":",";","<","=",">","?","¡","£","#","¥","§","Ä","Å","à","ä","å","Æ","Ç","É","è","é","ì","Ñ","ñ","ò","ö","Ø","Ö","Ü","ù","ü","ß", "\\", "*", "'", "%(", "%)", "@", "%+", "%$", "%[", "%]", "%^", "{", "|",  "}", "~"}
	local gsmChars={"%%25","%%0D","%%20","%%22","%%26","%%2C","%%2E","%%2F","%%3A","%%3B","%%3C","%%3D","%%3E","%%3F","%%A1","%%A3","%%A4","%%A5","%%A7","%%C4","%%C5","%%E0","%%E4","%%E5","%%C6","%%C7","%%C9","%%E8","%%E9","%%EC","%%D1","%%F1","%%F2","%%F6","%%D8","%%D6","%%DC","%%F9","%%FC","%%DF","%%5C","%%2A","%%27","%%28","%%29","%%40","%%2B","%%24","%%5B","%%5D","%%5E","%%7B","%%7C","%%7D","%%7E"}
	for i = 1, #utf8Chars, 1 do
		str = string.gsub(str, utf8Chars[i], gsmChars[i])
	end
	return str 
end

-- SMS messages are sent by making HTTP calls through the Clickatell API
function b.sendSMS(SMSText, PhoneNumber)
	if ((PhoneNumber == "") or (PhoneNumber == nil)) then PhoneNumber = uservariables["SMS-Away"] end
	b.OpenURL("https://api.clickatell.com/http/sendmsg?user="..uservariables["ClickatellAPIUser"].."&password="..uservariables["ClickatellAPIPassw"].."&api_id="..uservariables["ClickatellAPIId"].."&from=+"..uservariables["ClickatellSender"].."&to="..PhoneNumber.."&text=".. b.smsEncode(SMSText))
end

-- Notifications are sent by making HTTP calls through the NMA API
function b.sendNotification(event, description, priority)
	priority = priority or 0
	b.OpenURL("https://www.notifymyandroid.com/publicapi/notify?apikey="..uservariables["NMAapikey"].."&application=Domoticz&event="..b.urlencode(event).."&description="..b.urlencode(description).."&priority="..priority)
end

return b