-- Scripts based on device changed
local b = require("bakseeda")

commandArray = {}

local tempKamin             = 'Temperatur Kamin'               -- Namnet på temperaturgivaren
local usrKaminLastTemp      = 'KaminLastTemp'
local usrKaminTrigger       = 'KaminTrigger'
local tempTriggerDec        = 0.175                            -- temperatursänkning i % innan varning triggas 0.175 = 17.5%
local tempTriggerInc        = 0.40                             -- temperaturökning innan trigger återaktiveras 0.4 = 40% av temperatursänkningen som krävs för att trigga varningen

if (devicechanged[tempKamin]) then
    -- values
    local kaminTemp = tonumber(otherdevices_svalues[tempKamin])
    local tempDiff = kaminTemp * tempTriggerDec * -1
    local vKaminLastTemp = b.getVar(usrKaminLastTemp)
    local KaminTrigger = b.getVar(usrKaminTrigger)
    
    -- Påminn om att kaminen håller på att slockna
    if ((kaminTemp - vKaminLastTemp) < tempDiff) then
        if (KaminTrigger == 1) then
            commandArray['SendNotification']='Kaminen håller på att slockna!#Dags att lägga in mer ved.#0'
            b.setVar(usrKaminTrigger, 0, 0)
            print("Kaminens temperatur har sjunkit med "..vKaminLastTemp - kaminTemp.."c. Dags att lägga i mer ved.")
        end
        b.setVar(usrKaminLastTemp, kaminTemp , 1)
    end
    
    -- återaktivera trigger
    if ((vKaminLastTemp - kaminTemp) < (tempTriggerInc * tempDiff)) then
        b.setVar(usrKaminTrigger, 1, 0)
        b.setVar(usrKaminLastTemp, kaminTemp , 1)
        print("Kaminens temperatur har ökat med "..kaminTemp - vKaminLastTemp.."c. Sparar värde till systemet och aktiverar trigger.")
    end
end
return commandArray
