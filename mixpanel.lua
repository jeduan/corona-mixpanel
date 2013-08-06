local json = require 'json'
local mime = require 'mime'
local log = require 'vendor.log.log'

local M = {}

-- Group: tools
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

local function _extend( dest, src )
	for k, val in pairs(src) do
		dest[k] = val
	end
end

M.API_TOKEN = nil
M.SERVER_URL = 'https://api.mixpanel.com'
M.EVENT_DISTINCT_ID = nil
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
		b64string = mime.b64( jsonstring )
		b64string = _urlencode( b64string )
	end
	return b64string
end

local function postRequestListener( e )
	if e.isError then
		log('error while sending data to mixpanel ')
	end
	if e.status ~= 200 then
		log('error while sending data to mixpanel ')
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
	local postBody = 'ip=1&data=' .. encodeApiData(event)
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
		log(' mixpanel track called with empty event parameter. Using "mp_event"')
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
	if properties then
		_extend( p, properties )
	end
	local e = {
		event = event,
		properties = p,
	}
	_postEvent(e)
end



return M
