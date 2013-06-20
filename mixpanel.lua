local json = require 'json'

local M = {}

-- Group: tools
local function _b64enc( data )
	-- character table string
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	return ( (data:gsub( '.', function( x )
		local r,b='', x:byte()
		for i=8,1,-1 do r=r .. ( b % 2 ^ i - b % 2 ^ ( i - 1 ) > 0 and '1' or '0' ) end
		return r;
	end ) ..'0000' ):gsub( '%d%d%d?%d?%d?%d?', function( x )
		if ( #x < 6 ) then return '' end
		local c = 0
		for i = 1, 6 do c = c + ( x:sub( i, i ) == '1' and 2 ^ ( 6 - i ) or 0 ) end
		return b:sub( c+1, c+1 )
	end) .. ( { '', '==', '=' } )[ #data %3 + 1] )
end

local function _b64dec( data )
	-- character table string
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	data = string.gsub( data, '[^'..b..'=]', '' )
	return ( data:gsub( '.', function( x )
		if ( x == '=' ) then return '' end
		local r,f = '', ( b:find( x ) - 1 )
		for i = 6, 1, -1 do r = r .. ( f % 2 ^ i - f % 2 ^ ( i - 1 ) > 0 and '1' or '0' ) end
		return r;
	end ):gsub( '%d%d%d?%d?%d?%d?%d?%d?', function( x )
		if ( #x ~= 8 ) then return '' end
		local c = 0
		for i = 1, 8 do c = c + ( x:sub( i, i ) == '1' and 2 ^ ( 8 - i ) or 0 ) end
		return string.char( c )
	end ))
end

local function _urlencode( str )
	if str then
		str = string.gsub ( str, "\n", "\r\n" )
		str = string.gsub ( str, "([^%w ])", function ( c )
			return string.format ( "%%%02X", string.byte( c ) )
		end )
		str = string.gsub ( str, " ", "+" )
	end
	return str
end

local function print_r ( t ) 
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if ( print_r_cache[ tostring(t) ] ) then
			print( indent .. "*" .. tostring(t) )
		else
			print_r_cache[ tostring(t) ]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",--[[string.len(pos)+]] 4 ))
						print(indent..string.rep(" ",--[[string.len(pos)+6]] 4 ) .."}")
					elseif (type(val)=="string") then
						print(indent.."[".. tostring( pos ) ..'] => "'..val..'"')
					else
						print(indent.."[" .. tostring( pos ) .."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t," ")
		print("}")
	else
		sub_print_r(t," ")
	end
end

local function _log( ... )
	for i = 1,select('#', ...) do
		local val = select(i, ...)
		if type(val) == 'string' then
			print(val)
		else
			print_r(val)
		end
	end
end


local function _extend( dest, src )
	for k, val in pairs(src) do
		dest[k] = val
	end
end

M.API_TOKEN = nil
M.SERVER_URL = 'https://api.mixpanel.com'
M.EVENT_DISTINCT_ID = nil
M.listener = nil
M.defaultProperties = {}
M.superProperties = {}

local function networkListener( event )
	M.defaultProperties['$wifi'] = event.isReachableViaWiFi
end

local function defaultPropertiesTable( )

	local ret = {
		mp_lib = 'coronasdk',
		lib_version = '1.0',
		['$os'] = system.getInfo('platformName'),
		['$model'] = system.getInfo('model'),
		mp_device_model = system.getInfo('model'),
		['$os_version'] = system.getInfo('platformVersion'),
		['$screen_height'] = display.pixelHeight,
		['$screen_width'] = display.pixelWidth,
	}

	if ret['$os'] == 'Android' then
		ret['$os'] = 'android'
		ret['$screen_dpi'] = system.getInfo('androidDisplayXDpi')
		ret['$app_version'] = system.getInfo('androidAppVersionCode')

	elseif M.defaultProperties['$os'] == 'iPhone OS' then
		ret['$manufacturer'] = 'Apple'
		ret['$ios_ifa'] = system.getInfo('iosAdvertisingIdentifier')
		ret['$ios_device_model'] = system.getInfo('architectureInfo')

	end
	return ret
end

local function defaultDistinctId()
	if system.getInfo('platformName') == 'iPhone OS' then
		return system.getInfo('iosAdvertisingIdentifier')
	else
		return system.getInfo('deviceID')
	end
end

function M.initMixpanel( apiToken )
	assert( type( apiToken ) == 'string' and apiToken ~= '', 'API Token not provided' )

	M.API_TOKEN = apiToken
	M.defaultProperties = defaultPropertiesTable()
	M.distinctId = defaultDistinctId()

	if network.canDetectNetworkStatusChanges then
		network.setStatusListener( 'api.mixpanel.com', networkListener)
	end
end

local function encodeApiData(data)
	local b64string = ''
	local jsonstring = json.encode(data)

	if jsonstring then
		b64string = _b64enc( jsonstring )
		b64string = _urlencode( b64string )
	end
	return b64string
end

local function postRequestListener( e )
	if e.isError then
		_log('error while sending data to mixpanel ')
	end
	if e.status ~= 200 then
		_log('error while sending data to mixpanel ')
	end
end

local function _postRequest( endpoint, body )
	local url = M.SERVER_URL .. endpoint
	local params = {
		headers = {
			['Accept-Encoding'] = 'gzip',
			['Content-Type'] = 'application/x-www-form-urlencoded'
		},
		body = body
	}

	network.request( url, 'POST', postRequestListener, params )
end

local function _postEvent(event)
	local postBody = 'ip=1&data=' .. encodeApiData(data)
	_postRequest( '/track/', postBody )
end

function M.registerSuperProperties( properties )
	_extend(M.superProperties, properties)
end

function M.registerSuperPropertiesOnce( properties )
	for key, val in pairs(properties) do
		if M.superProperties[key] == nil then
			M.superProperties[key] = value
		end
	end
end

function M.unregisterSuperProperty( property )
	if M.superProperties[property] then
		M.superProperties[property] = nil
	end
end

function M.clearSuperProperties()
	M.superProperties = {}
end

function M.reset()
	M.distinctId = defaultDistinctId()
	M.superProperties = {}
	M.nameTag = nil
end

function M.track(...)
	assert(M.API_TOKEN ~= nil, 'You need to call mixpanel.initMixpanel before tracking')

	local event = nil
	local properties = nil
	if select('#', ...) == 0 then
		_log(' mixpanel track called with empty event parameter. Using "mp_event"')
		event = 'mp_event'
	end

	if select('#', ...) >= 1 then
		event = select(1, ...)
	end

	if select('#', ...) >= 2 then
		properties = select(2, ...)
	end

	local p = {}
	p.token = M.API_TOKEN
	p.time = os.time()
	if M.nameTag then p.mp_name_tag = M.nameTag end
	if M.distinctId then p.distinct_id = M.distinct_id end
	_extend( p, M.defaultProperties )
	_extend( p, M.superProperties )
	local e = {
		event = event,
		properties = p,
	}
	_postEvent(e)
end



return M
