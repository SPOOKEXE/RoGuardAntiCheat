local ServerStorage = game:GetService("ServerStorage")

local AntiCheatModule = require(ServerStorage:WaitForChild('RoGuard'))
AntiCheatModule.Init({})
AntiCheatModule.Start()
