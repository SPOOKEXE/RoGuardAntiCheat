
local API_URL = 'http://127.0.0.1:5100'
local API_KEY = ''

type HttpMethods = 'POST' | 'GET'
type RequestAsyncResponse = {
	Success : boolean,
	StatusCode : number,
	StatusMessage : string,
	Headers : {}?,
	Body : {}?,
}

local HttpService = game:GetService("HttpService")

local function RequestAPIAsync( path : string, method : HttpMethods, body : {}? ) : any?
	if not HttpService.HttpEnabled then
		warn('HttpService.HttpEnabled must be enabled for the GuildsAPI to work.')
		return nil
	end

	local success, err = pcall(function()
		return HttpService:RequestAsync({
			Url = API_URL..path,
			Method = method,
			Headers = { ["Content-Type"] = "application/json", ["X-API-KEY"] = API_KEY },
			Body = body and HttpService:JSONEncode(body),
		})
	end)

	if success then
		local value, _ = string.gsub(err['Body'], "'", '"')
		return value
	end

	warn(err)
	return nil
end

-- // Module // --
local Module = {}

function Module.SetAPIUrl( api_url : string )
	API_URL = api_url
end

function Module.SetAPIKey( api_key : string )
	API_KEY = api_key
end

function Module.HealthCheck() : boolean?
	return RequestAPIAsync('/health', 'GET', nil)
end

function Module.IsRankPermissionsValid( permissions : {}? ) : boolean?
	return RequestAPIAsync('/is-rank-permissions-valid', 'POST', {permissions=permissions})
end

function Module.IsGuildNameAvailable( name : string ) : boolean?
	return RequestAPIAsync('/is-guild-name-available', 'POST', {name=name})
end

function Module.GetGuildInfoFromGuildId( guild_id : number ) : {}?
	local response = RequestAPIAsync('/get-guild-info-from-guild-id', 'POST', {guild_id=guild_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildInfoFromUserId( user_id : number ) : {}?
	local response = RequestAPIAsync('/get-guild-info-from-user-id', 'POST', {user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.UpdateGuildDisplayInfo( guild_id : number, description : string, accessibility : number, emblem : number ) : boolean?
	local response = RequestAPIAsync('/update-guild-display-info', 'POST', {guild_id=guild_id, description=description, accessibility=accessibility, emblem=emblem})
	return response and HttpService:JSONDecode(response)
end

function Module.GetUserRankInGuild( guild_id : number, user_id : number ) : {}?
	local response = RequestAPIAsync('/get-user-rank-in-guild', 'POST', {guild_id=guild_id, user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildRankById( rank_id : number ) : {}?
	local response = RequestAPIAsync('/get-guild-rank-by-id', 'POST', {rank_id=rank_id})
	return response and HttpService:JSONDecode(response)
end

function Module.AddUserIdToGuild( guild_id : number, user_id : number )
	local response = RequestAPIAsync('/add-user-id-to-guild', 'POST', {guild_id=guild_id,user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.SetUserIdRankInGuild( guild_id : number, user_id : number, rank_id : number )
	local response = RequestAPIAsync('/set-user-id-rank-in-guild', 'POST', {guild_id=guild_id, user_id=user_id, rank_id=rank_id})
	return response and HttpService:JSONDecode(response)
end

function Module.ChangeGuildRankPermissions( guild_id : number, rank_id : number, permissions : {} ) : boolean?
	local response = RequestAPIAsync('/change-guild-rank-permissions', 'POST', {guild_id=guild_id, rank_id=rank_id, permissions=permissions})
	return response and HttpService:JSONDecode(response)
end

function Module.CreateRankInGuild( guild_id : number, name : string ) : {}?
	local response = RequestAPIAsync('/create-rank-in-guild', 'POST', {guild_id=guild_id, name=name})
	return response and HttpService:JSONDecode(response)
end

function Module.RemoveRankInGuild( guild_id : number, rank_id : number ) : boolean?
	local response = RequestAPIAsync('/remove-rank-in-guild', 'POST', {guild_id=guild_id, rank_id=rank_id})
	return response and HttpService:JSONDecode(response)
end

function Module.SetDefaultRankInGuild( guild_id : number, rank_id : number ) : boolean?
	local response = RequestAPIAsync('/set-default-rank-in-guild', 'POST', {guild_id=guild_id, rank_id=rank_id})
	return response and HttpService:JSONDecode(response)
end

function Module.KickUserIdFromGuild( guild_id : number, user_id : number ) : boolean?
	local response = RequestAPIAsync('/kick-user-id-from-guild', 'POST', {guild_id=guild_id, user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.DeleteGuild( guild_id : number ) : boolean?
	local response = RequestAPIAsync('/delete-guild', 'POST', {guild_id=guild_id})
	return response and HttpService:JSONDecode(response)
end

function Module.IsUserInGuild( user_id : number, guild_id : number ) : boolean?
	local response = RequestAPIAsync('/is-user-in-guild-of-id', 'POST', {guild_id=guild_id, user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.TransferGuildOwnership( guild_id : number, user_id : number ) : boolean?
	local response = RequestAPIAsync('/transfer-guild-ownership', 'POST', {guild_id=guild_id, user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildBannedUserIds( guild_id : number ) : {number}?
	local response = RequestAPIAsync('/get-guild-banned-user-ids', 'POST', {guild_id=guild_id})
	return response and HttpService:JSONDecode(response)
end

function Module.BanUserIdFromGuild( guild_id : number, user_id : number ) : boolean?
	local response = RequestAPIAsync('/ban-user-id-from-guild', 'POST', {guild_id=guild_id, user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.UnbanUserIdFromGuild( guild_id : number, user_id : number ) : boolean?
	local response = RequestAPIAsync('/unban-user-id-from-guild', 'POST', {guild_id=guild_id, user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildChatMessageFromId( message_id : number ) : {}?
	local response = RequestAPIAsync('/get-guild-chat-message-from-id', 'POST', {message_id=message_id})
	return response and HttpService:JSONDecode(response)
end

function Module.CreateGuildChatMessage( guild_id : number, user_id : number, message : string ) : boolean?
	local response = RequestAPIAsync('/create-guild-chat-message', 'POST', {guild_id=guild_id, user_id=user_id, message=message})
	return response and HttpService:JSONDecode(response)
end

function Module.RemoveGuildChatMessage( message_id : number ) : boolean?
	local response = RequestAPIAsync('/remove-guild-chat-message', 'POST', {message_id=message_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildChatMessages( guild_id : number, offset : number, limit : number, include_deleted : boolean ) : { {} }?
	local response = RequestAPIAsync('/get-guild-chat-messages', 'POST', {guild_id=guild_id, offset=offset, limit=limit, include_deleted=include_deleted})
	return response and HttpService:JSONDecode(response)
end

function Module.CreateGuildAuditLog( guild_id : number, user_id : number, action : number, args : {any} ) : boolean?
	local response = RequestAPIAsync('/create-guild-audit-log', 'POST', {guild_id=guild_id,user_id=user_id,action=action,args=args})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildAuditLogs( guild_id : number, offset : number, limit : number ) : { {} }?
	local response = RequestAPIAsync('/get-guild-audit-logs', 'POST', {guild_id=guild_id, offset=offset, limit=limit})
	return response and HttpService:JSONDecode(response)
end

function Module.GetFullGuildInfoFromGuildId( guild_id : number ) : {}?
	local response = RequestAPIAsync('/get-full-guild-info-from-guild-id', 'POST', {guild_id=guild_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetFullGuildInfoFromUserId( user_id : number ) : {}?
	local response = RequestAPIAsync('/get-full-guild-info-from-user-id', 'POST', {user_id=user_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildRanks( guild_id : number ) : {}?
	local response = RequestAPIAsync('/get-guild-ranks', 'POST', {guild_id=guild_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetGuildMembers( guild_id : number ) : {}?
	local response = RequestAPIAsync('/get-guild-members', 'POST', {guild_id=guild_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetCreatedGuilds( offset : number, limit : number ) : { {} }?
	local response = RequestAPIAsync('/get-created-guilds', 'POST', {offset=offset, limit=limit})
	return response and HttpService:JSONDecode(response)
end

function Module.DoesGuildHaveRankOfId( guild_id : number, rank_id : number ) : boolean
	local response = RequestAPIAsync('/does-guild-have-rank-of-id', 'POST', {guild_id=guild_id, rank_id=rank_id})
	return response and HttpService:JSONDecode(response)
end

function Module.GetCreatedGuildsFull( offset : number, limit : number ) : { {} }?
	local response = RequestAPIAsync('/get-created-guilds-full', 'POST', {offset=offset, limit=limit})
	return response and HttpService:JSONDecode(response)
end

function Module.CreateGuild( user_id : number, name : string, description : string, emblem : number ) : {}?
	local response = RequestAPIAsync('/create-guild', 'POST', {user_id=user_id, name=name, description=description, emblem=emblem})
	return response and HttpService:JSONDecode(response)
end

function Module.IncrementOnlineCount( guild_id : number, value : number ) : boolean
	assert( value == 1 or value == -1, 'You must set the increment to -1 or 1.' )
	local response = RequestAPIAsync('/increment-online-count', 'POST', {guild_id=guild_id, value=value})
	return response and HttpService:JSONDecode(response)
end

function Module.ChangeGuildRankName( guild_id : number, rank_id : number, name : string ) : boolean?
	local response = RequestAPIAsync('/change-guild-rank-name', 'POST', {guild_id=guild_id, rank_id=rank_id, name=name})
	return response and HttpService:JSONDecode(response)
end

return Module
