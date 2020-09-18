include("../common/lua/utils.lua");
include("../common/lua/sockets.lua");
include("../common/lua/messaging.lua");
include("../common/lua/chetch_messaging.lua");
include("../common/lua/serviceclient.lua");
include("../common/lua/admservice.lua");
include("../common/lua/restapi.lua");
include("../common/lua/chetch_api.lua");

local utils = Utils();

-- CLIENT CONFIG
function BBMSClient(serviceName)
	
	if not serviceName then
		serviceName = "BBMS";
	end

	local self = utils.inherit({
	}, ADMServiceClient(serviceName));

	self.activityTimeout =  6*60*60*1000;

	return self;
end
local client = BBMSClient(settings.media_service_name);
client.attachTraceHandler(trace);
client.attachServiceReadyHandler(function(serviceReady)
			if serviceReady then
				notificationBar("We good to go...", "info");
			else
				notificationBar("Not ready...", "warning");
			end
		end
	);

-- this handles 'infrastructure' errors like failing to connect.  It does not handle
-- error messages sent from the service itself ... see below for that handler
client.attachErrorHandler(function(err)
			handleError(err, "critical", "client");
		end
	);

client.attachReceiveErrorHandler(function(msg)
			utils.showDialog(msg.getValue());
		end
	);

-- API Config
local apiUtil = ChetchAPI(settings.network_api_endpoint);
apiUtil.attachInitialisedHandler(function(inst)
		if inst.network and inst.network.lan_ip and inst.services and inst.services["Chetch Messaging"] then
			settings.messaging_ip = inst.network.lan_ip;
			settings.messaging_port = inst.services["Chetch Messaging"].endpoint_port;
			
			if client.ip ~= settings.messaging_ip or client.port ~= tonumber(settings.messaging_port) then
				notificationBar("Network change so connecting client", "warning");
				print("WARNING AAARGGGHGGHGH ... network change");
				showDialog("Network change errekkk");
				client.connect(settings.messaging_ip, tonumber(settings.messaging_port));
			end
		end
	end
)
apiUtil.attachErrorHandler(function(err, errCode)
		handleError(err, errCode, "api");
	end);


-- Functions
function handleError(err, errCode, source)
	local level = "error"; --TODO: determine this based on errCode and source
	notificationBar(source .." (".. errCode .. "): ".. err, level);
	print("----------------!!!!ERROR!!!!: " .. err);
end

local nbColours = { info="#333333", warning="#e5b902", error="red"};

function notificationBar(msg, type)
	layout.notification.text = msg;
	if nbColours[type] then
		layout.notification.color = nbColours[type];
	end
end

local soundAreas = {"inside","outside"};
local selectedSoundArea;
local selectedDeviceID;

function selectArea(area)
	selectedSoundArea = area;
	if selectedSoundArea == "inside" then
		selectedDeviceID = "lght1";
	else
		selectedDeviceID = "lght2";
	end
end
-- Events

events.create = function()
	selectArea("inside");
end

events.focus = function()

	utils.assignCommands(actions, "Volume_Down,Volume_Up,On/Off,Mute/Unmute,AuxOpt,Bluetooth,AUX", function(cmd)
			if client.serviceReady then
				print("Sending adm command ".. cmd .. " to device " .. selectedDeviceID);
				client.sendADMCommand(selectedDeviceID, cmd);
			else
				utils.showDialog("Cannot execute command as service is not ready.");
			end
		end
	);

	apiUtil.init();
	if client.ip then
		client.connect();
		notificationBar("Connecting from memory...", "info");
	elseif settings.messaging_ip and settings.messaging_port then
		client.connect(settings.messaging_ip, tonumber(settings.messaging_port));
		notificationBar("Connecting from settings...", "info");
	else
		notificationBar("Contacting server...", "info");
	end	
	
	utils.toggleGroup(soundAreas, selectArea);
	layout[selectedSoundArea].checked = true;
end

events.blur = function()
	print("Blur called")
end

-- Actions