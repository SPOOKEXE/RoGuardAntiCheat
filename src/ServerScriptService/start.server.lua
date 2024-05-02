local ServerStorage = game:GetService("ServerStorage")

local AntiCheatModule = require(ServerStorage:WaitForChild('RoGuardAC'))
AntiCheatModule.Init({})
AntiCheatModule.Start()
