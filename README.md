# kamin_slocknar-varning
Varnar när kaminen håller på att slockna.

Det här behöver du:

1 Temperatursensor som tål höga temperaturer, tex fibaro door sensor med DS18B20. 


Installation (domoticz):


Skapa användarvariabler: 

KaminTrigger , Integer (Heltal)

KaminLastTemp, Float (flyttal)


Skapa mapp:

sudo mkdir -p /usr/local/lib/lua/5.2/

kopiera in bakseeda.lua till denna mapp. 


Öppna domoticz -> Händelsesystem/events

Skapa nytt .lua script som "Device".

Klistra in allt från fireplace.lua i editorn. 

Ändra parametrarna högst upp till dina egna enheter. 
