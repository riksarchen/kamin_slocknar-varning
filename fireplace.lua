-- Scripts based on device changed
local b = require("bakseeda")

commandArray = {}

local tempKamin             = 'Temperatur Kamin'               -- Namnet på temperaturgivaren
local usrKaminLastTemp      = 'KaminLastTemp'
local usrKaminTrigger       = 'KaminTrigger'
local kaminTemp             = 0
local tempDiff              = 0
local tempTriggerDec        = 0.175                            -- temperatursänkning i % innan varning triggas 0.175 = 17.5%
local tempTriggerInc        = 0.40                             -- temperaturökning innan trigger återaktiveras 0.4 = 40% av temperatursänkningen som krävs för att trigga varningen

if (devicechanged[tempKamin]) then
    -- values
    kaminTemp = tonumber(otherdevices_svalues[tempKamin])
    tempDiff = kaminTemp * tempTriggerDec * -1
    
    -- Påminn om att kaminen håller på att slockna
    if ((kaminTemp - b.getVar(usrKaminLastTemp)) < tempDiff) then
        if (b.getVar(usrKaminTrigger) == 1) then
            commandArray['SendNotification']='Kaminen håller på att slockna!#Dags att lägga in mer ved.#0'
            b.setVar(usrKaminTrigger, 0, 0)
            print("Kaminens temperatur har sjunkit med "..b.getVar(usrKaminLastTemp) - kaminTemp.."c. Dags att lägga i mer ved.")
        end
        b.setVar(usrKaminLastTemp, kaminTemp , 1)
    end
    
    -- återaktivera trigger
    if ((b.getVar(usrKaminLastTemp) - kaminTemp) < (tempTriggerInc * tempDiff)) then
        b.setVar(usrKaminTrigger, 1, 0)
        b.setVar(usrKaminLastTemp, kaminTemp , 1)
        print("Kaminens temperatur har ökat med "..kaminTemp - b.getVar(usrKaminLastTemp).."c. Sparar värde till systemet och aktiverar trigger.")
    end
end
return commandArray
