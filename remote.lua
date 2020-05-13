
include("../common/lua/utils.lua");
include("../common/lua/sockets.lua");
include("../common/lua/messaging.lua");
include("../common/lua/chetch_messaging.lua");
include("../common/lua/serviceclient.lua");
include("../common/lua/admservice.lua");
include("../common/lua/restapi.lua");
include("../common/lua/chetch_api.lua");

local utils = Utils();

function BBMSClient(serviceName)
	
	if not serviceName then
		serviceName = "BBMS";
	end

	local self = utils.inherit({
	}, ADMServiceClient(serviceName));

	self.activityTimeout =  6*60*60*1000;

	return self;
end

local lastTraceMessage;
function trace(s, area)
	print(s);
	if area == "sending" then
		layout.data1.text = s;
	elseif area == "receiving" then
		layout.data2.text = s;
	else
		layout.output.text = s;
	end
	
	lastTraceMessage = s;
end

--local client = BBMSClient("TESTADMS");
local client = BBMSClient();
client.attachTraceHandler(trace);
client.attachADMReadyHandler(function(admReady, admState)
			if admReady then
				layout.cstate.text = "No ADM: " ..admState ;
			else
				layout.cstate.text = "ADM: " ..admState ;
			end
		end
	);

client.attachErrorHandler(function(err)
			layout.cstate.text = "C_ERR: " .. err;
		end
	);


-- API Config
local apiUtil = ChetchAPI(settings.network_api_endpoint);
apiUtil.attachInitialisedHandler(function(inst)
		--inst.network.ip;
		if inst.network and inst.network.lan_ip and inst.services and inst.services["Chetch Messaging"] then
			local port = inst.services["Chetch Messaging"].endpoint_port;
			local ip = inst.network.lan_ip;
			trace("Chetch API returns " .. ip ..":".. port);
			if client.ip ~= ip or client.port ~= port then
				trace("Attempting to connect client " .. ip ..":".. port);
				client.connect(ip, port);
			end
		end
	end
)
apiUtil.attachErrorHandler(function(err)
		layout.cstate.text = "A_ERR: " .. err;
	end);
-- Events

events.create = function()
	print("Create called");
end

events.focus = function()

	utils.assignCommands(actions, "Volume_Up,Volume_Down,On/Off,Mute", function(cmd)
			if client.admReady then
				client.sendADMCommand("irt1", cmd);
			else
				trace("Client not ready for " .. cmd);
			end
		end
	);

	--updateCMIPAndPort();
	trace("Ok testtestxxx. ..");
	apiUtil.init();

	if client.ip then
		client.connect();
	end	
end

events.blur = function()
	print("Blur called")
end

-- Actions
actions.command1 = function ()
	getEndpointThenConnect();
end

actions.command2 = function ()
	client.close();
end

actions.command3 = function ()
	if client.isConnected() then
		client.requestServerStatus();
	else
		trace("Client not ready to send");
	end
end

actions.command4 = function ()
	if client.admReady then
		client.admStatus();
	else
		trace("Client not ready to send");
	end
end
