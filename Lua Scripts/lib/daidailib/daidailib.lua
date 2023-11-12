require "lib.daidailib.Config.Config"
json = require "lib.daidailib.Main.json"
json1 = require "lib.daidailib.Main.pretty.json"

----------
--share function
----------

----错误记录
function LOG(message)
    local dir = filesystem.stand_dir() .. "Sakura.log"
    local file = io.open(dir, "a+")
    file:write(os.date("[%Y-%m-%d %H:%M:%S]") .. " " .. message .. "\n")
    file:close()
end
function ERROR_LOG(error_message)
    LOG("|ERROR| " .. error_message)
    util.toast("|ERROR| " .. "\n" .. error_message)
    util.stop_script()
end

----播放音频
--来自https://github.com/calamity-inc/Soup-Lua-Bindings/blob/main/LUA_API.md
--似乎无法停止
function PlaySound(dir)--dir-指向绝对文件(local dir = filesystem.scripts_dir() .. '\\daidaiScript\\audio\\payphone.wav')
    local fr = soup.FileReader(dir)
    local wav = soup.audWav(fr)
    local dev = soup.audDevice.getDefault()--选择默认音频驱动
    local devname = dev:getName()--获取播放驱动名
    local pb = dev:open(wav.channels)
    local mix = soup.audMixer()

    mix.stop_playback_when_done = false
    mix:setOutput(pb)
    mix:playSound(wav)
    while pb:isPlaying() do util.yield(10) end
end

----通知
function request_streamed_texture(textureDict)
	util.spoof_script("main_persistent", function()
		GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(textureDict, false)
	end)
end
if filesystem.exists(filesystem.resources_dir() .. "/SakuraImg/Textures.ytd") then
	util.register_file(filesystem.resources_dir() .. "/SakuraImg/Textures.ytd")
	request_streamed_texture("Textures")
else
	ERROR_LOG("未找到所需文件: Textures.ytd")
end
function notification(format, colour, title)
    local titled = title or "通知"
	local msg = string.format(format)
	HUD.THEFEED_SET_BACKGROUND_COLOR_FOR_NEXT_POST(colour or HudColour.blue)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST(msg)
	HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT("Textures", "logo", true, 4, "Sakura", "~b~"..titled)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, false)
end

----newTimer
function newTimer()
	local self = {start = util.current_time_millis()}
	local function reset()
		self.start = util.current_time_millis()
	end
	local function elapsed()
		return util.current_time_millis() - self.start
	end
	return
	{
		reset = reset,
		elapsed = elapsed
	}
end
timer = newTimer()

----声音create
function Sound_new(name, reference)----原函数名Sound.new
    local inst = setmetatable({}, Sound)
    inst.name = name
    inst.reference = reference
    return inst
end

----new.colour()
new = {}
function new_colour(R, G, B, A) ----原函数名new.colour()
    return {r = R / 255, g = G / 255, b = B / 255, a = A}
end
function new.delay(MS, S, MIN)
    return {ms = MS, s = S, min = MIN}
end

----创建效果
Effect = {asset = "", name = "", scale = 1.0}
Effect.__index = Effect
function Effect.new(asset, name, scale)
	local inst = setmetatable({}, Effect)
	inst.name = name
	inst.asset = asset
	inst.scale = scale
	return inst
end





--请求模型
function request_model(hash, timeout)
    STREAMING.REQUEST_MODEL(hash)
    local end_time = os.time() + (timeout or 5)
    while not STREAMING.HAS_MODEL_LOADED(hash) and end_time >= os.time() do
        STREAMING.REQUEST_MODEL(hash)
        util.yield()
    end
    return STREAMING.HAS_MODEL_LOADED(hash)
end
function request_models(...)--模型表
	local arg = {...}
	for _, model in ipairs(arg) do
		STREAMING.REQUEST_MODEL(model)
        local end_time = os.time() + 5
		while not STREAMING.HAS_MODEL_LOADED(model) and end_time >= os.time() do
            STREAMING.REQUEST_MODEL(model)
			util.yield()
		end
	end
end
----请求效果
function request_ptfx_asset(asset)
    STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
		STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
		util.yield()
	end
    GRAPHICS.USE_PARTICLE_FX_ASSET(asset)
end
--请求纹理
function request_streamed_texture_dict(textureDict)
    GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(textureDict, false)
    while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(textureDict) do
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(textureDict, false)
        util.yield()
    end
end
--请求控制
function request_control(entity, timeout)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    local end_time = os.time() + (timeout or 5)
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and end_time >= os.time() do
        local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        util.yield()
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end
--请求动作
function request_anim_dict(dict)
    STREAMING.REQUEST_ANIM_DICT(dict)
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
end
--请求武器效果
function request_weapon_asset(hash)
    WEAPON.REQUEST_WEAPON_ASSET(hash, 31, false)
	while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
        WEAPON.REQUEST_WEAPON_ASSET(hash, 31, false)
        util.yield() 
    end
end



----创建PED
function create_ped(pedtype, hash, x, y, z, head)
    request_model(hash)
    local ped =  PED.CREATE_PED(pedtype, hash, 0, 0, 0, head, true, false)
    ENTITY.SET_ENTITY_COORDS(ped, x, y, z, false, false, false, false)
    return ped
end
----创建载具
function create_vehicle(hash, x, y, z, head)
    request_model(hash)
    local veh =  VEHICLE.CREATE_VEHICLE(hash, 0, 0, 0, head, true, true, false)
    ENTITY.SET_ENTITY_COORDS(veh, x, y, z, false, false, false, false)
    return veh
end
----创建物体
function create_object(hash, x, y, z)
    request_model(hash)
    local obj =  OBJECT.CREATE_OBJECT(hash, 0, 0, 0, true, false, true)
    ENTITY.SET_ENTITY_COORDS(obj, x, y, z, false, false, false, false)
    return obj
end

----文件写入
function filewrite(filepath, method, content)
    local file = io.open(filepath, method)--"w+"文件不存在即创建
    file:write(content)
    file:close()
end
----读取文件
function fileread(filepath, method, rtype)
    if filesystem.exists(filepath) then
        local file = io.open(filepath, method)
        local data = file:read(rtype)--'*all'从当前位置读取整个文件
        file:close()
        return data
    end
end
----读取文件名
function read_filename(dir)
    local filename = {}
    for i, path in ipairs(filesystem.list_files(dir)) do
        local name = path:sub(path:rfind("\\")+1, path:rfind(".")-1)--仅获取文件名(不包含扩展名)
        local ext = path:match(".+%.(%w+)$")--仅扩展名
        --local filedir, fullname, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")--filedir = 路径, name = 文件名(包含扩展名), ext = 仅扩展名
        filename[#filename + 1] = name
    end
    if #filename == 0 then
        filename = {""}
    end
    return filename
end

----更改模型
function change_model(player, hash)
	request_model(hash)
	PLAYER.SET_PLAYER_MODEL(player, hash)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end

----个人传送
function teleport(x, y, z)
    PED.SET_PED_COORDS_KEEP_VEHICLE(PLAYER.PLAYER_PED_ID(), x, y, z)
end

----驾驶载具
function drive_vehicle(vehicle)
    if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
        if ENTITY.DOES_ENTITY_EXIST(driver) and not PED.IS_PED_A_PLAYER(driver) then
            request_control(driver)
            entities.delete(driver)
        end
        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, -1)
    end
end

----显示按键
function show_button()--函数位于首部
    HUD.HIDE_HUD_COMPONENT_THIS_FRAME(6)
    HUD.HIDE_HUD_COMPONENT_THIS_FRAME(7)
    HUD.HIDE_HUD_COMPONENT_THIS_FRAME(8)
    HUD.HIDE_HUD_COMPONENT_THIS_FRAME(9)
    memory.write_int(memory.script_global(1645739+1121), 1)
    sf.CLEAR_ALL()
    sf.TOGGLE_MOUSE_BUTTONS(false)
    return sf;
end
function show_button2()--函数位于尾部
    sf.DRAW_INSTRUCTIONAL_BUTTONS()
    sf:draw_fullscreen()
end

----其他置顶
--冷静(静止)PED
function calm_ped(ped, toggle)
    if ENTITY.IS_ENTITY_A_PED(ped) == 0 then return end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, toggle)
    PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, not toggle)
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 17, toggle)
end

----获取距离
function Get_Distance(pos1, pos2, useZ)
    local distance = MISC.GET_DISTANCE_BETWEEN_COORDS(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z, useZ)
    --local distance = math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x) + (pos1.y-pos2.y)*(pos1.y-pos2.y) + (pos1.z-pos2.z)*(pos1.z-pos2.z))--平方根计算距离
    return distance
end
----获取地面坐标
function waypoint_coord(waypoint)
    local boolpara, posz = util.get_ground_z(waypoint.x, waypoint.y)
    local esliposz = 0
    while not boolpara and esliposz <= 100 do
        boolpara, posz = util.get_ground_z(waypoint.x, waypoint.y)
        esliposz = esliposz + 1
        util.yield()
    end
    if boolpara then
        waypoint.z = posz
    end
    return waypoint.x, waypoint.y, posz
end

----设置实体面对实体
function set_entity_face_entity(entity, target, usePitch)
    local pos1 = ENTITY.GET_ENTITY_COORDS(entity, false)
    local pos2 = ENTITY.GET_ENTITY_COORDS(target, false)
    local rel = v3.new(pos2)
    rel:sub(pos1)
    local rot = rel:toRot()
    if not usePitch then
        ENTITY.SET_ENTITY_HEADING(entity, rot.z)
    else
        ENTITY.SET_ENTITY_ROTATION(entity, rot.x, rot.y, rot.z, 2, 0)
    end
end

----获取瞄准实体信息
function get_entity_info(ent)
    local info = {}
    local ent_types = {"nil","PED", "载具", "物体"}
    if ENTITY.DOES_ENTITY_EXIST(ent) then
        info["hash"] = ENTITY.GET_ENTITY_MODEL(ent)
        info["health"] = ENTITY.GET_ENTITY_HEALTH(ent)
        info["type"] = ENTITY.GET_ENTITY_TYPE(ent)
        info["type_name"] = ent_types[ENTITY.GET_ENTITY_TYPE(ent)+1]
        info["speed"] = math.floor(ENTITY.GET_ENTITY_SPEED(ent))
        return info
    end
    return 0
end
-----获取瞄准实体句柄
function get_entity_player_is_aiming_at(player)
	if not PLAYER.IS_PLAYER_FREE_AIMING(player) then
		return 0
	end
    local aimed_entity = memory.alloc_int()
	if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(player, aimed_entity) then
		entity = memory.read_int(aimed_entity)
	end
	if ENTITY.DOES_ENTITY_EXIST(entity) and ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity, false) then --如果实体在载具,则返回载具信息
		entity = PED.GET_VEHICLE_PED_IS_IN(entity, false)
	end
	return entity
end

----绘制文字
function draw_string(s, x, y, scale, font)--font=4无法显示中文,系统英语可显示斜体云字体
	HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
	HUD.SET_TEXT_FONT(font or 1)
	HUD.SET_TEXT_SCALE(scale, scale)
	HUD.SET_TEXT_DROP_SHADOW()
	HUD.SET_TEXT_WRAP(0.0, 1.0)
	HUD.SET_TEXT_DROPSHADOW(1, 0, 0, 0, 0)
	HUD.SET_TEXT_OUTLINE()
	HUD.SET_TEXT_EDGE(1, 0, 0, 0, 0)
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(s)
	HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y)
end

----附加
function attach_to_player(hash, bone, x, y, z, xrot, yrot, zrot)           
    local user_ped = PLAYER.PLAYER_PED_ID()
    hash = util.joaat(hash)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do		
        util.yield()
    end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    local object = OBJECT.CREATE_OBJECT(hash, 0.0,0.0,0, true, true, false)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(object, user_ped, PED.GET_PED_BONE_INDEX(PLAYER.PLAYER_PED_ID(), bone), x, y, z, xrot, yrot, zrot, false, false, false, false, 0, true, 0) 
end

----判断实体在水上
function is_entity_on_water(ent)
    local ht = memory.alloc(4)
    local pos = ENTITY.GET_ENTITY_COORDS(ent)
    return WATER.GET_WATER_HEIGHT(pos.x, pos.y, pos.z, ht)--(ENTITY.IS_ENTITY_IN_WATER(ent)判断实体是否在水中/水上返回false)
end


----随机字符串
function random_string(length)
    local name = ""
    local string = "abcdefghijklmnopqrstuvwxyzABCEDFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for i = 1, length do 
        name = name .. string[math.random(#string)]  
    end
    return name
end
----字符串转变为 table表
function StrToTable(str)
    if type(str) ~= "string" then
        return
    end
    return json.decode(str)
end
----table表转字符串
function ToStringEx(value)
    if type(value)=='table' then
        return TableToStr(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
        return tostring(value)
    end
end
function TableToStr(t)
    if t == nil then return "" end
    local retstr= "{"
    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
            signal = ""
        end
        if key == i then
            retstr = retstr..signal..ToStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
                else
                    retstr = retstr..signal..key.."="..ToStringEx(value)
                end
            end
        end
        i = i+1
    end
    retstr = retstr.."}"
    return retstr
end
------------------------------------------------------------------------------------------------------


































----从银行取出钱
function bank_to_wallet()
    local bankCash = MONEY.NETWORK_GET_VC_BANK_BALANCE()
    if bankCash > 0 then
        NETSHOPPING1._NET_GAMESERVER_TRANSFER_BANK_TO_WALLET(0, bankCash)
        util.toast("取出 "..bankCash.."$ 到钱包")
    else
        util.toast("余额不足,交易失败")
    end
end
----将钱存入银行
function wallet_to_bank()
    local walletCash = MONEY.NETWORK_GET_VC_WALLET_BALANCE(0)
    if walletCash > 0 then
        NETSHOPPING1._NET_GAMESERVER_TRANSFER_WALLET_TO_BANK(0, walletCash)
        util.toast("存入 "..walletCash.."$ 到银行")
    else
        util.toast("余额不足,交易失败")
    end
end
----自动存款
function auto_deposit()
    local walletCash = MONEY.NETWORK_GET_VC_WALLET_BALANCE(0)
    if walletCash > 0 then
        NETSHOPPING1._NET_GAMESERVER_TRANSFER_WALLET_TO_BANK(0, walletCash)
        util.toast("已将"..walletCash.."$存入银行")
    end
end




----水体漩涡
function water_vortex()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(),false)
    WATER.SET_DEEP_OCEAN_SCALER(0.0)
    WATER.MODIFY_WATER(pos.x, pos.y, -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x+2, pos.y, -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x, pos.y+2, -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x-2, pos.y, -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x, pos.y-2, -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x+math.random(4,10), pos.y, -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x, pos.y+math.random(4,10), -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x-math.random(4,10), pos.y, -500000.0, 0.2)
    WATER.MODIFY_WATER(pos.x, pos.y-math.random(4,10), -500000.0, 0.2)
end


----升级载具
function upgrade_vehicle(vehicle)
    for i = 0, 49 do
        local num = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
        VEHICLE.SET_VEHICLE_MOD(vehicle, i, num - 1, true)
    end
end

----通往天堂
function To_Heaven()
    if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then 
        util.toast("请先进入载具")
        return
    end
    if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then 
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        local jesus_hash = util.joaat("u_m_m_jesus_01")--耶稣
        local jesus_ped = create_ped(26, jesus_hash, pos.x, pos.y, pos.z, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(jesus_ped, true)

        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, 0)
        PED.SET_PED_INTO_VEHICLE(jesus_ped, vehicle, -1)
        ENTITY.SET_ENTITY_COLLISION(vehicle, false, false)
        local vel = {x = 0, y = 0, z = 10000}
        VEHICLE.SET_VEHICLE_GRAVITY(vehicle, false)
        ENTITY.SET_ENTITY_VELOCITY(vehicle, vel.x, vel.y, vel.z)
        util.yield(5000)
        ENTITY.SET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID(), 0, 0)
    end
end

----蜘蛛侠飞行
local cur_pitch = 0
local cur_yaw = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID())
function superman_fly(on)
    local c = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
    superman = on 
    if superman then
        ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
        camera = CAM.CREATE_CAM_WITH_PARAMS('DEFAULT_SCRIPTED_CAMERA', c.x, c.y, c.z, 0.0, 0.0, 0.0, 120, true, 0)
        CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
        request_anim_dict('skydive@freefall')
        TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), 'skydive@freefall', 'free_forward', 1.0, 1.0, -1, 3, 0.5, false, false, false)
    else 
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID()) 
        if support_ent ~= 0 then 
            entities.delete(support_ent)
        end
        if camera ~= 0 then 
            CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
            CAM.DESTROY_CAM(camera, false) 
            camera = 0
        end
        ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
    end
    while superman do
        local rotate_lr = -2*PAD.GET_CONTROL_NORMAL(1, 1)
        local rotate_ud =  -2*PAD.GET_CONTROL_NORMAL(2, 2)
        local lateral = PAD.GET_CONTROL_NORMAL(30, 30)
        if math.abs(cur_pitch) >= 120 then 
            rotate_lr = -rotate_lr
        end
    
        local c = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)

        cur_pitch += rotate_ud * 2
        cur_yaw += rotate_lr * 2
    
        local jump = PAD.IS_CONTROL_PRESSED(0, 55)
        local shift = PAD.IS_CONTROL_PRESSED(0, 21)
        if math.abs(cur_pitch) >= 360 then 
            cur_pitch = 0
        end
        if math.abs(cur_yaw) >= 360 then 
            cur_yaw = 0
        end
    
        if support_ent ~= 0 and ENTITY.DOES_ENTITY_EXIST(support_ent) then 
            local rot = ENTITY.GET_ENTITY_ROTATION(support_ent, 1)
            ENTITY.SET_ENTITY_ROTATION(support_ent, cur_pitch, 0.0, cur_yaw, 1, true)
            ENTITY.SET_ENTITY_MAX_SPEED(support_ent, 600)
            local forward_control = PAD.IS_CONTROL_PRESSED(0, 32)
            local backward_control = PAD.IS_CONTROL_PRESSED(0, 33) 
            local vel = ENTITY.GET_ENTITY_SPEED_VECTOR(support_ent, true)

            local side_speed = vel.x
            if math.abs(side_speed) > 5 then 
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, -side_speed, 0, 0, true, true, true, true)
            end
            if forward_control then
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, 600, 0, true, true, true, true)
            end
            if backward_control then
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, -600, 0, true, true, true, true)
            end
            if jump then 
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, 0, 600 / 2, true, true, true, true)
            end
            if shift then 
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, 0, -600 / 2, true, true, true, true)
            end
            if lateral then 
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, lateral*600, 0, 0.0, true, true, true, true)
            end

            CAM.HARD_ATTACH_CAM_TO_ENTITY(camera, PLAYER.PLAYER_PED_ID(), 0.0, 0.0, 0.0, 0.0, -5.0, .0, true)
        else
            support_ent = create_object(util.joaat('IG_RoosterMcCraw'), c.x, c.y, c.z)
            ENTITY.SET_ENTITY_ROTATION(support_ent, -90, 90, 90, 0)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), support_ent, 90, 0, 0, 0, 0, 0, 0, true, false, false, true, 0, true, 0)
        end
        util.yield()
    end
end



----死亡之眼
function dead_eye()
    if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
        MISC.SET_TIME_SCALE(0.2)
        GRAPHICS.SET_TIMECYCLE_MODIFIER("LostTimeFlash")
    else
        MISC.SET_TIME_SCALE(1)
        GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
    end
end

----3D环绕灯
function veh_circle_light()
    local red = math.random(0, 255)
    local green = math.random(0, 255)
    local blue = math.random(0, 255)
    local vmod = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
    VEHICLE.SET_VEHICLE_NEON_COLOUR(vmod, red, green, blue)
    VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, 2, true)
    --VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vmod, 8)--载具大灯
    for i = 0, 1 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, i, false)
    end
    VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, 3, false)
    util.yield(100)
    VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, 0, true)
    for i = 1, 3 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, i, false)
    end
    util.yield(100)
    for i = 0, 2 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, i, false)
    end
    VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, 3, true)
    util.yield(100)
    for i = 2, 3 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, i, false)
    end
    VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, 0, false)
    VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, 1, true)
    util.yield(100)
end

----骑乘玩家1
function ride_player1(pid,on)
    if on then
        if PLAYER.PLAYER_PED_ID() == PLAYER.GET_PLAYER_PED(pid) then return end
        ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), PLAYER.GET_PLAYER_PED(pid), 0, -0.058, 0.197, 0.595, 2.0, 1.0,1, true, true, true, false, 0, true)
        request_anim_dict("anim@heists@heist_safehouse_intro@phone_couch@male")
        TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "anim@heists@heist_safehouse_intro@phone_couch@male", "phone_couch_male_idle", 3.0, 2.0, -1, 3, 1.0, false, false, false)
    else
        ENTITY.DETACH_ENTITY(PLAYER.GET_PLAYER_PED(pid), false, false)
        ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), false, false)
        TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
    end
end
--骑乘玩家2
function ride_player2(pid,on)
    if on then
        if PLAYER.PLAYER_PED_ID() == PLAYER.GET_PLAYER_PED(pid) then return end
        ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), PLAYER.GET_PLAYER_PED(pid), 0, -0.058, 0.197, 0.595, 2.0, 1.0,1, true, true, true, false, 0, true)
        request_anim_dict("timetable@jimmy@mics3_ig_15@")
        TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "timetable@jimmy@mics3_ig_15@", "idle_a_tracy", 3.0, 2.0, -1, 3, 1.0, false, false, false)
    else
        ENTITY.DETACH_ENTITY(PLAYER.GET_PLAYER_PED(pid), false, false)
        ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), false, false)
        TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
    end
end


----降落到玩家
function landing_on_player(pid)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), 0, -100, 100)
    local pos1 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid), false)
    ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, false, false, false, false)
    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), util.joaat("gadget_parachute"), 1, 0)
    while true do
        local mypos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
        local distance = Get_Distance(pos1, mypos, true)
        if distance < 123 then
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PLAYER.PLAYER_PED_ID())
            return
        end
        util.yield()
    end
end

----设置导航点
function set_waypoint(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid), false)
    HUD.SET_NEW_WAYPOINT(pos.x, pos.y)
end


----保存玩家信息
local SaveProfile = {
	name = "",
	rid = "",
	crew = "",
	ip = "",
}
SaveProfile.__pairs = function(tbl)--更改排序
	local k = {"name", "rid", "crew", "ip"}
	local i = 0
	local iter = function()
		i = i + 1
		if tbl[k[i]] == nil then return nil end
		return k[i], tbl[k[i]]
	end
	return iter
end
function get_player_crew(pid)
    local crew = {}
    local networkHandle = memory.alloc(104)
    local clanDesc = memory.alloc(280)
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(pid, networkHandle, 13)
    if NETWORK.NETWORK_IS_HANDLE_VALID(networkHandle, 13) and NETWORK.NETWORK_CLAN_PLAYER_GET_DESC(clanDesc, 35, networkHandle) then
        crew.icon = memory.read_int(clanDesc)
        crew.name = memory.read_string(clanDesc + 0x08)
        crew.tag = memory.read_string(clanDesc + 0x88)
        crew.rank = memory.read_string(clanDesc + 0xB0)
        crew.motto = players.clan_get_motto(pid)
        crew.alt_badge = memory.read_byte(clanDesc + 0xA0) ~= 0 and "On" or "Off"
    end
    return crew
end
function save_player_info(pid)
    local info = setmetatable({}, SaveProfile)
    info.name = PLAYER.GET_PLAYER_NAME(pid)
    info.rid = players.get_rockstar_id(pid)
    info.crew = get_player_crew(pid)
    info.ip = intToIp(players.get_connect_ip(pid))

    local content = json1.stringify(info, nil, 4)
    local dir = filesystem.scripts_dir() .. 'daidaiScript/profiles/'..info.name..".json"
    filewrite(dir, "w+", content or 0)
    notification("~y~~bold~信息已保存", HudColour.blue)
end



----集束炸弹
function cluster_bomb(pid)
    local playerPed = PLAYER.GET_PLAYER_PED(pid)
    if playerPed ~= 0 then
        local playerPos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
        local maxExplosions = 1200 -- 最大爆炸次数
        local explosionRadius = 0.001 -- 初始爆炸半径
        local explosionRadiusStep = 0.03 -- 每次爆炸的爆炸半径增加
        
        -- 从多个方向引发爆炸
        for i = 1, maxExplosions do
            -- 每次爆炸前的延迟
            util.yield(0.000001)
            
            -- 计算每个方向的随机角度
            local angle = math.rad(math.random(0, 360))
            
            -- 根据角度和半径计算爆炸位置
            local offsetX = math.cos(angle) * explosionRadius
            local offsetY = math.sin(angle) * explosionRadius
            local explosionPos = v3(playerPos.x + offsetX, playerPos.y + offsetY, playerPos.z)
            
            FIRE.ADD_EXPLOSION(explosionPos.x, explosionPos.y, explosionPos.z, 0, 100, true, false, 0, false)
            
            -- 增加爆炸半径
            explosionRadius = explosionRadius + explosionRadiusStep
        end
        util.yield(0.001)
    end
end

----屠杀载具
function massacre_vehicle(pid)
    local playerVehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(pid), false)
    if playerVehicle ~= nil then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
        local forceMultiplier = 999999.0
        request_control(playerVehicle)
        for i = 1, 1000 do
            local forceX = math.random(-forceMultiplier, forceMultiplier)
            local forceY = math.random(-forceMultiplier, forceMultiplier)
            local forceZ = -forceMultiplier
            --entity.apply_force_to_entity(playerVehicle, 1, pos.x, pos.y, pos.z, forceX, forceY, forceZ, true, true)
            ENTITY.APPLY_FORCE_TO_ENTITY(playerVehicle, 1, pos.x, pos.y, pos.z, forceX, forceY, forceZ, 0, true, true, true, false, true)
            util.yield(1)
        end
        util.yield(1)
    end
end

----鱼雨
local fish_tab = {}
function fish_rain()
    local hashes = {util.joaat('a_c_fish'), util.joaat('a_c_stingray')}
    local fish_hash = hashes[math.random(#hashes)]
    local c = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
    c.x = c.x + math.random(-30, 30)
    c.y = c.y + math.random(-30, 30)
    c.z = c.z + 50
    fish_tab[#fish_tab + 1] = create_ped(28, fish_hash, c.x, c.y, c.z, math.random(270))
    ENTITY.SET_ENTITY_HEALTH(fish_tab[#fish_tab + 1], 0.0, 1)
    ENTITY.APPLY_FORCE_TO_ENTITY(fish_tab[#fish_tab + 1], 1, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0, false, false, true, false, true)
    if #fish_tab > 40 then
        entities.delete(fish_tab[1])
        table.remove(fish_tab, 1)
    end
    util.yield(200)
end

----反向驾驶
function force_npc_reverse_travel()
    for entities.get_all_peds_as_handles() as ped do
        if not PED.IS_PED_A_PLAYER(ped) then 
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, true)
            if veh ~= 0 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1) == ped then 
                request_control(ped)
                TASK.SET_DRIVE_TASK_DRIVING_STYLE(ped, 1471)
            end
        end
    end
end

----911事件
function attacks_911()
    local pos = {x = -914.1707, y = -1164.9396, z=250}
    local plane_hash = util.joaat('jet')
    request_model(plane_hash)
    local plane = create_vehicle(plane_hash, pos.x, pos.y, pos.z, -68)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(plane)
    VEHICLE.SET_VEHICLE_ENGINE_ON(plane, true, true, false)
    VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
    VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(plane, 0.0)
    for i=1, 5 do 
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 150.0)
        util.yield(1000)
    end
end

----消防车攻击
function firefighter_thread(ped, p_ped, truck)
    TASK.SET_TASK_VEHICLE_CHASE_BEHAVIOR_FLAG(ped, 1, true)
    TASK.SET_TASK_VEHICLE_CHASE_IDEAL_PURSUIT_DISTANCE(ped, 10.0)
    while ped do
        if not ENTITY.DOES_ENTITY_EXIST(truck) or not ENTITY.DOES_ENTITY_EXIST(ped) or ENTITY.GET_ENTITY_HEALTH(truck) == 0 then 
            return
        end
        local ped_c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(p_ped, math.random(-5,5), math.random(-5,5), 0.0)
        local c = ENTITY.GET_ENTITY_COORDS(truck)
        if MISC.GET_DISTANCE_BETWEEN_COORDS(ped_c.x, ped_c.y, ped_c.z, c.x, c.y, c.z) >= 10 then 
            ENTITY.SET_ENTITY_COORDS(truck, ped_c.x, ped_c.y, ped_c.z)
            ENTITY.SET_ENTITY_HEADING(truck, ENTITY.GET_ENTITY_HEADING(p_ped) + 90)
        end
        TASK.TASK_VEHICLE_SHOOT_AT_PED(ped, p_ped, 1.0)
        util.yield(3000)
    end
end
function Firetruck_attack(pid)
    local v_hash = util.joaat('firetruk')
    local p_hash = util.joaat("S_M_Y_Fireman_01")
    local p_ped = PLAYER.GET_PLAYER_PED(pid)
    local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(p_ped, math.random(-5,5), math.random(-5,5), 0.0)     
    local truck = create_vehicle(v_hash, c.x, c.y, c.z, ENTITY.GET_ENTITY_HEADING(p_ped))
    VEHICLE.SET_VEHICLE_SIREN(truck, true)
    ENTITY.SET_ENTITY_HEADING(truck, ENTITY.GET_ENTITY_HEADING(p_ped) + 90)
    VEHICLE.SET_VEHICLE_ENGINE_ON(truck, true, true, false)
    VEHICLE.SET_VEHICLE_WEAPON_CAN_TARGET_OBJECTS(truck, true)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED(truck, 2)
    local ped = create_ped(1, p_hash, c.x, c.y, c.z, ENTITY.GET_ENTITY_HEADING(p_ped))
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true)
    PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false)
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)            
    TASK.TASK_COMBAT_PED(ped, p_ped, 0, 16)
    PED.SET_PED_INTO_VEHICLE(ped, truck, -1)
    TASK.SET_TASK_VEHICLE_CHASE_BEHAVIOR_FLAG(ped, 1, true)
    TASK.SET_TASK_VEHICLE_CHASE_IDEAL_PURSUIT_DISTANCE(ped, 10.0)
    TASK.TASK_VEHICLE_CHASE(ped, p_ped)
    firefighter_thread(ped, p_ped, truck)
    ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
    ENTITY.SET_ENTITY_INVINCIBLE(truck, true)
end






----派遣警车
function spawn_police_car(pid)
    local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local offset = get_random_offset_from_entity(targetPed, 50.0, 60.0)
    local outCoords = v3.new()
    local outHeading = memory.alloc(4)
    if PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(offset.x, offset.y, offset.z, outCoords, outHeading, 1, 3.0, 0) then
        local vehicleHash <const> = util.joaat("police3")
        local pedHash <const> = util.joaat("s_m_y_cop_01")
        request_model(vehicleHash); request_model(pedHash)

        local pos = ENTITY.GET_ENTITY_COORDS(targetPed, false)
        local vehicle = entities.create_vehicle(vehicleHash, pos, 0.0)
        if not ENTITY.DOES_ENTITY_EXIST(vehicle) then return end
        ENTITY.SET_ENTITY_COORDS(vehicle, outCoords.x, outCoords.y, outCoords.z, false, false, false, false)
        ENTITY.SET_ENTITY_HEADING(vehicle, memory.read_float(outHeading))
        VEHICLE.SET_VEHICLE_SIREN(vehicle, true)
        AUDIO.BLIP_SIREN(vehicle)
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
        ENTITY.SET_ENTITY_INVINCIBLE(vehicle, true)

        local pSequence = memory.alloc_int()
        TASK.OPEN_SEQUENCE_TASK(pSequence)
        TASK.TASK_COMBAT_PED(0, targetPed, 0, 16)
        TASK.TASK_GO_TO_ENTITY(0, targetPed, 6000, 10.0, 3.0, 0.0, 0)
        TASK.SET_SEQUENCE_TO_REPEAT(memory.read_int(pSequence), true)
        TASK.CLOSE_SEQUENCE_TASK(memory.read_int(pSequence))

        for seat = -1, 0 do
            local cop = entities.create_ped(5, pedHash, outCoords, 0.0)
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(cop, true, false)
            set_decor_flag(cop, DecorFlag_isAttacker)
            PED.SET_PED_INTO_VEHICLE(cop, vehicle, seat)
            PED.SET_PED_RANDOM_COMPONENT_VARIATION(cop, 0)
            local weapon <const> = (seat == -1) and "weapon_pistol" or "weapon_pumpshotgun"
            WEAPON.GIVE_WEAPON_TO_PED(cop, util.joaat(weapon), -1, false, true)
            PED.SET_PED_COMBAT_ATTRIBUTES(cop, 1, true)
            PED.SET_PED_AS_COP(cop, true)
            ENTITY.SET_ENTITY_INVINCIBLE(cop, true)
            TASK.TASK_PERFORM_SEQUENCE(cop, memory.read_int(pSequence))
        end

        TASK.CLEAR_SEQUENCE_TASK(pSequence)
        AUDIO.PLAY_POLICE_REPORT("SCRIPTED_SCANNER_REPORT_FRANLIN_0_KIDNAP", 0.0)
    end
end

----分离载具零件
function detach_vehicle_parts(pid)
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(pid), false)
    request_control(vehicle)
    local doors = VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(vehicle)
    VEHICLE.POP_OUT_VEHICLE_WINDSCREEN(vehicle)
    for i= 0, doors do
        VEHICLE.SET_VEHICLE_DOOR_BROKEN(vehicle, i, false)
    end
    for i = 0, 5 do
        entities.detach_wheel(entities.handle_to_pointer(vehicle), i)
    end
end


----猴王
function monkey_king()
    local monkey = 0xA8683715 --猴子
    local monkeyKING = 0xC2D06F53 --猴王
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, -2, 0)
    change_model(PLAYER.PLAYER_ID(), monkeyKING)
    for i = 1, 5 do
        local ped = create_ped(28, monkey, pos.x, pos.y, pos.z, 72)
        join_group(ped)
    end
end


----彩弹枪
function Paintball_gun()
    if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
        local entity = get_entity_player_is_aiming_at(PLAYER.PLAYER_ID())
        if entity ~= NULL and ENTITY.IS_ENTITY_A_VEHICLE(entity) and request_control(entity) then
            local primary, secundary = random_colour(), random_colour()
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(entity, primary.r, primary.g, primary.b)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(entity, secundary.r, secundary.g, secundary.b)
        end
    end
end


----速度表
local gears = {} --挡位图标
for i= 0, 7 do 
    gears[i] = directx.create_texture(filesystem.resources_dir() .. '\\SakuraImg\\speedometer\\' .. '/gear_' .. tostring(i) .. '.png')
end
local speed_nums = {} --速度值图标
for i= 0, 9 do 
    speed_nums[i] = directx.create_texture(filesystem.resources_dir() .. '\\SakuraImg\\speedometer\\' .. '/mph_' .. tostring(i) .. '.png')
end
local gauge_bg = directx.create_texture(filesystem.resources_dir() .. '\\SakuraImg\\speedometer\\' .. '/dial.png')--主体图标
local needle = directx.create_texture(filesystem.resources_dir() .. '\\SakuraImg\\speedometer\\' .. '/needle.png')--指针图标
local kph_label = directx.create_texture(filesystem.resources_dir() .. '\\SakuraImg\\speedometer\\' .. '/kph_label.png') --单位

local carposX = 0.84
local carposY = 0.75
function speedometer_X(x)
    carposX = x / 100
end
function speedometer_Y(y)
    carposY = y / 100
end
function speedometer()
    local car_ptr = entities.get_user_vehicle_as_pointer(false)
    local car = entities.pointer_to_handle(car_ptr)
    if car_ptr ~= 0 then
        local rpm = entities.get_rpm(car_ptr)--每分钟转数
        local max_rotation = math.rad(0.501 * 180) -- 针可以达到的最大旋转角度（弧度）

        ----根据汽车的速度和最大速度计算打捆针的旋转
        local needle_rotation = (rpm / 1)/1.485  - 0.170
        local gear = entities.get_current_gear(car_ptr)
        directx.draw_texture(gauge_bg, 0.08, 0.08, 0.5, 0.5, carposX, carposY - 0.004, 0, 1.0, 1.0, 1.0, 1.0)
        directx.draw_texture(needle, 0.08, 0.08, 0.5, 0.5, carposX, carposY, needle_rotation, 1.0, 1.0, 1.0, 0.5)
        if gear < 8 then--gtav 载具默认最高挡位7,但第三方辅助可以修改其值,即造成got nil
            directx.draw_texture(gears[gear], 0.08, 0.08, 0.5, 0.5, carposX - 0.0001, carposY - 0.005, 0, 1, 1, 1, 1)
        else
            directx.draw_texture(gears[7], 0.08, 0.08, 0.5, 0.5, carposX - 0.0001, carposY - 0.005, 0, 1, 1, 1, 1)
        end

        ----速度
        local speed = math.ceil(ENTITY.GET_ENTITY_SPEED(car) * 3.6)
        local speed_str = tostring(speed)
        local cur_speed_num_offset = 0
        for i=1, #speed_str do
            directx.draw_texture(speed_nums[tonumber(speed_str:sub(i,i))] , 0.06, 0.06, 0.5, 0.5, (carposX) + cur_speed_num_offset, carposY + 0.1, 0, 1.0, 1.0, 1.0, 1)
            cur_speed_num_offset += 0.06 / 2
        end

        --速度单位
        cur_speed_num_offset += 0.011
        directx.draw_texture(kph_label, 0.06, 0.06, 0.5, 0.5, (carposX) + cur_speed_num_offset, carposY + 0.13, 0, 1.0, 1.0, 1.0, 1)
    end
end


----导弹雷达
function Missile_radar()
    for k, obj in pairs(entities.get_all_objects_as_handles()) do
        if is_entity_a_projectile(ENTITY.GET_ENTITY_MODEL(obj)) then
            if HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then
                local proj_blip = HUD.ADD_BLIP_FOR_ENTITY(obj)
                HUD.SET_BLIP_SPRITE(proj_blip, 443)
                HUD.SET_BLIP_COLOUR(proj_blip, 75)
            end
        end
    end
end
----载具识别
function Vehicle_identify()
    local contact = directx.create_texture(filesystem.scripts_dir() .. '\\daidaiScript\\' .. '\\flightredux\\'.. 'contact.png')
    for k,veh in pairs(entities.get_all_vehicles_as_handles()) do
        local mdl = ENTITY.GET_ENTITY_MODEL(veh)
        if ENTITY.GET_ENTITY_HEALTH(veh) > 0 then
            local c = ENTITY.GET_ENTITY_COORDS(veh)
            local draw_pos = world_to_screen_coords(c.x, c.y, c.z)
            directx.draw_texture(contact, 0.005, 0.005, 0.5, 0.5, draw_pos.x, draw_pos.y, 0, 0, 100, 0, 100)
        end
    end
end


----召回载具
function recall_vehicle()
    local lastcar = PLAYER.GET_PLAYERS_LAST_VEHICLE()
    if lastcar ~= 0 then
        local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0.0, 5.0, 0.0)
        local pedhash = -67533719
        request_model(pedhash)
        local tesla_ped = entities.create_ped(32, pedhash, coords, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
        ENTITY.SET_ENTITY_VISIBLE(tesla_ped, false, false)--不可见NPC
        local tesla_blip = HUD.ADD_BLIP_FOR_ENTITY(lastcar)
        HUD.SET_BLIP_COLOUR(tesla_blip, 7)
        PED.SET_PED_INTO_VEHICLE(tesla_ped, lastcar, -1)
        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(tesla_ped, lastcar, coords['x'], coords['y'], coords['z'], 50, 786996, 5)
        while tesla_ped do
            if PED.IS_PED_GETTING_INTO_A_VEHICLE(PLAYER.PLAYER_PED_ID()) then
                local veh = PED.GET_VEHICLE_PED_IS_ENTERING(PLAYER.PLAYER_PED_ID())
                if veh == lastcar then
                    entities.delete(tesla_ped)
                    util.remove_blip(tesla_blip) 
                    break
                end
            end
            util.yield()
        end
    end
end


----读取外观
function read_appearance()
    local path = filesystem.scripts_dir() .. 'daidaiScript/Outfits/A-test.txt'

    local data = fileread(path, 'r', '*all')
    if data ~= "" then
        filewrite(path, "w+", "")
    end

    for i = 0, 11 do
        local index = PED.GET_PED_DRAWABLE_VARIATION(PLAYER.PLAYER_PED_ID(), i)--drawableId
        local texture = PED.GET_PED_TEXTURE_VARIATION(PLAYER.PLAYER_PED_ID(), i)--textureId

        local kk = "DRAWABLE "..i..": "..index..","..texture.."\n"
        filewrite(path, "a+", kk)
    end

    for i = 0, 9 do
        local index = PED.GET_PED_PROP_INDEX(PLAYER.PLAYER_PED_ID(), i)--drawableId
        local texture = PED.GET_PED_PROP_TEXTURE_INDEX(PLAYER.PLAYER_PED_ID(), i)--textureId

        local kk = "PROPS "..i..": "..index..","..texture.."\n"
        filewrite(path, "a+", kk)
    end
    util.toast("读写完成")
end


----空中行走
function walk_on_air(on)
    walkonair = on
    if walkonair then
        while walkonair do
            --显示按键
            show_button()
            sf.SET_DATA_SLOT(0,PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(0, 38, true), '向上')
            sf.SET_DATA_SLOT(1,PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(0, 44, true), '向下')
            sf.DRAW_INSTRUCTIONAL_BUTTONS()
            sf:draw_fullscreen()
            --清除火焰(生成的实体被炮击可能存在火焰)
            local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
            FIRE.STOP_FIRE_IN_RANGE(pos.x, pos.y, pos.z, 500)
            FIRE.STOP_ENTITY_FIRE(PLAYER.PLAYER_PED_ID()) 

            if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) then
                if air_block == 0 or not ENTITY.DOES_ENTITY_EXIST(air_block) then
                    local hash = 1352775717
                    local c = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
                    airb_ht = c['z']-1.4
                    air_block = create_object(hash, c['x'], c['y'], airb_ht)
                    ENTITY.SET_ENTITY_INVINCIBLE(air_block,true)
                    ENTITY.SET_ENTITY_ALPHA(air_block, 0)
                    ENTITY.SET_ENTITY_VISIBLE(air_block, false, 0)
                end
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
                local box_pos = ENTITY.GET_ENTITY_COORDS(air_block, false)
                if MISC.GET_DISTANCE_BETWEEN_COORDS(pos.x, pos.y, pos.z, box_pos['x'], box_pos['y'], box_pos['z'], true) > 1.4 then
                    ENTITY.SET_ENTITY_COORDS(air_block, pos.x, pos.y, pos.z-1.4, false, false, false)
                    ENTITY.SET_ENTITY_HEADING(air_block, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
                end
                if PAD.IS_CONTROL_PRESSED(0, 38) then--E
                    airb_ht = airb_ht + 0.1
                    ENTITY.SET_ENTITY_COORDS(air_block, pos.x, pos.y, airb_ht, false, false, false)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, airb_ht + 1.5, true, false, false)
                    ENTITY.SET_ENTITY_HEADING(air_block, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
                end
                if PAD.IS_CONTROL_PRESSED(0, 44) then--Q
                    airb_ht = airb_ht - 0.1
                    ENTITY.SET_ENTITY_COORDS(air_block, pos.x, pos.y, airb_ht, false, false, false)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, airb_ht + 1.5, true, false, false)
                    ENTITY.SET_ENTITY_HEADING(air_block, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
                end
            end
            util.yield()
        end
    else
        if ENTITY.DOES_ENTITY_EXIST(air_block) then
            entities.delete(air_block)
        end
    end
end


----丝滑移动
function Silky_movement(on)
    movement_toggle = on
    if on then
        while movement_toggle do
            local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
            local head = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID())

            if not ENTITY.DOES_ENTITY_EXIST(movement_dow) then--防止人物掉落的动作
                local hash = -1272257643
                request_model(hash)
                movement_dow = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, 0, 0, 0, true, false, false)
                ENTITY.SET_ENTITY_ALPHA(movement_dow, 0)
                ENTITY.SET_ENTITY_VISIBLE(movement_dow, false, 0)
            end
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(movement_dow, pos.x, pos.y, pos.z-1.08, false, false, false)


            local rot = CAM.GET_GAMEPLAY_CAM_ROT(5)--控制视野
            ENTITY.SET_ENTITY_ROTATION(PLAYER.PLAYER_PED_ID(), 0, 0, rot.z, 5, true)


            ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)

            if PAD.IS_CONTROL_PRESSED(0,32) then--前进
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, 1, 0)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, true, false, false)
                ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
            elseif PAD.IS_CONTROL_PRESSED(0,33) then--后退
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, -1, 0)
                            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, true, false, false)
                ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
            end
            if PAD.IS_CONTROL_PRESSED(0,34) then--左
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), -1, 0, 0)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, true, false, false)
            elseif PAD.IS_CONTROL_PRESSED(0,35) then--右
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 1, 0, 0)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, true, false, false)
            end
            if PAD.IS_CONTROL_PRESSED(0,21) then--上
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos['x'], pos['y'], pos['z']+1, true, false, false)
                ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
            elseif PAD.IS_CONTROL_PRESSED(0,36) then--下
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos['x'], pos['y'], pos['z']-1, true, false, false)
                ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
            end
            util.yield()
        end
    else
        ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
        entities.delete(movement_dow)
    end
end

----导航到最近的加油站
function GetClosestGasStation()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
	local coord
	local distance
	for _, v in ipairs(gasStations) do
		local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(v[1], v[2], v[3], pos.x, pos.y, pos.z, true)
		if not distance or (distance and distance > dist) then
			distance = dist
			coord = v
		end
	end
	return coord
end


----世界轰炸
function World_Bombing()
    local allveh = entities.get_all_vehicles_as_handles()
	local allpeds = entities.get_all_peds_as_handles()
	local allobj = entities.get_all_objects_as_handles()
	util.yield(100)
	local vel, velo = {}, {}
	velo.x = 0.0
	velo.y = 0.0
	velo.z = 1000.00
    local myveh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), false)
	for i = 1, #allpeds do
		if not PED.IS_PED_A_PLAYER(allpeds[i]) then
			vel.x = math.random(1000.0, 10000.0)
			vel.y = math.random(1000.0, 10000.0)
			vel.z = math.random(1000.0, 7500.0)
			ENTITY.FREEZE_ENTITY_POSITION(allpeds[i], false)
            ENTITY.APPLY_FORCE_TO_ENTITY(allpeds[i], 5, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 0, 1, 1, 1, 0, 1)
			ENTITY.SET_ENTITY_VELOCITY(allpeds[i], vel.x, vel.y, vel.z)
		end
	end
	for y = 1, #allveh do
		if allveh[y] ~= myveh then
			vel.x = math.random(1000.0, 10000.0)
			vel.y = math.random(1000.0, 10000.0)
			vel.z = math.random(1000.0, 7500.0)
			ENTITY.FREEZE_ENTITY_POSITION(allveh[y], false)
			VEHICLE.SET_VEHICLE_GRAVITY(allveh[y], false)
			ENTITY.SET_ENTITY_VELOCITY(allveh[y], velo.x, velo.y, velo.z)
			util.yield(25)
			ENTITY.SET_ENTITY_VELOCITY(allveh[y], vel.x, vel.y, vel.z)
		end
	end
	for x = 1, #allobj do
		vel.x = math.random(1000.0, 10000.0)
		vel.y = math.random(1000.0, 10000.0)
		vel.z = math.random(1000.0, 7500.0)
		ENTITY.FREEZE_ENTITY_POSITION(allobj[x], false)
		ENTITY.SET_ENTITY_VELOCITY(allobj[x], vel.x, vel.y, vel.z)
	end
end

----驾驶购物车
function drive_shopping_cart()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
    local veh = create_vehicle(1353120668, pos.x, pos.y, pos.z, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
    ENTITY.SET_ENTITY_ALPHA(veh, 0, false)
    ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
    VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), veh, -1)

    local obj_hash = util.joaat("prop_rub_trolley02a")
    local obj = create_object(obj_hash, pos.x, pos.y, pos.z)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(obj, veh, 0, 0, 0, 0, 0, 0, 0, true, false, false, false, 0, true, 0)
end


--冲浪
function surf()
    if not is_entity_on_water(PLAYER.PLAYER_PED_ID()) then
        notification("~y~~bold~不在水上:)", HudColour.blue)
        return
    end
    local veh_hash = -311022263 --载具
    local surfboard_hash = 59140280 --冲浪板
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    request_model(veh_hash,surfboard_hash)
    local ped = PED.CLONE_PED(PLAYER.PLAYER_PED_ID(), true, false, true)
    local veh =  VEHICLE.CREATE_VEHICLE(veh_hash, pos.x, pos.y, pos.z, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()), true, true, false)
    local surfboard = OBJECT.CREATE_OBJECT(surfboard_hash, pos.x, pos.y, pos.z, true, false, true)
    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), veh, -1)
    ENTITY.SET_ENTITY_VISIBLE(veh, false, false)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(surfboard, veh, 0, 0, 0, 0, 270, 0, 0, true, false, false, true, 0, true, 0)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, surfboard, 0, 0, -1, 0, 90, -90, 0, true, false, false, true, 0, true, 0)
    
    --VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 4)--禁止下车
    ENTITY.SET_ENTITY_INVINCIBLE(veh,true)
    ENTITY.SET_ENTITY_ALPHA(PLAYER.PLAYER_PED_ID(), 0, false)
    calm_ped(ped, true)
    while ped do
        local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), false)
        if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) and ENTITY.DOES_ENTITY_EXIST(veh) and ENTITY.DOES_ENTITY_EXIST(surfboard) then--下车删除
            entities.delete(veh)
            entities.delete(ped)
            entities.delete(surfboard)
            return
        elseif car ~= veh and ENTITY.DOES_ENTITY_EXIST(veh) and ENTITY.DOES_ENTITY_EXIST(surfboard) then--换车删除
            entities.delete(veh)
            entities.delete(ped)
            entities.delete(surfboard)
            return
        end

        TASK.TASK_STAND_STILL(ped, 10000)--设置PED静止(防止PED做出一些行为)
        util.yield()
    end
end


-------mod_uses
vehicle_uses = 0
ped_uses = 0
pickup_uses = 0
player_uses = 0
object_uses = 0
robustmode = false
function mod_uses(type, incr)
    if incr < 0 and is_loading then
        --"不增加使用类型的 var " .. type .. " by " .. incr .. "- script is loading"
        return
    end
    --"递增使用 var 类型 " .. type .. " by " .. incr
    if type == "vehicle" then
        if vehicle_uses <= 0 and incr < 0 then
            return
        end
        vehicle_uses = vehicle_uses + incr
    elseif type == "pickup" then
        if pickup_uses <= 0 and incr < 0 then
            return
        end
        pickup_uses = pickup_uses + incr
    elseif type == "ped" then
        if ped_uses <= 0 and incr < 0 then
            return
        end
        ped_uses = ped_uses + incr
    elseif type == "player" then
        if player_uses <= 0 and incr < 0 then
            return
        end
        player_uses = player_uses + incr
    elseif type == "object" then
        if object_uses <= 0 and incr < 0 then
            return
        end
        object_uses = object_uses + incr
    end
end

----从相机获取偏移量
function get_offset_from_gameplay_camera(distance)
	local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
	local direction = v3.toDir(cam_rot)
	local destination = {
	  x = cam_pos.x + direction.x * distance,
	  y = cam_pos.y + direction.y * distance,
	  z = cam_pos.z + direction.z * distance
	}
	return destination
end

----光线投影绘制
function raycast_gameplay_cam(flag, distance)
    local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
    local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(2)
    local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
    local direction = toDirection(CAM.GET_GAMEPLAY_CAM_ROT(0))
    local destination =
    {
        x = cam_pos.x + direction.x * distance,
        y = cam_pos.y + direction.y * distance,
        z = cam_pos.z + direction.z * distance
    }
    SHAPETEST.GET_SHAPE_TEST_RESULT(
        SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            cam_pos.x,
            cam_pos.y,
            cam_pos.z,
            destination.x,
            destination.y,
            destination.z,
            flag,
            -1,
            1
        ), ptr1, ptr2, ptr3, ptr4)
    local p1 = memory.read_int(ptr1)
    local p2 = memory.read_vector3(ptr2)
    local p3 = memory.read_vector3(ptr3)
    local p4 = memory.read_int(ptr4)
    return {p1, p2, p3, p4}
end


----获取模型尺寸
function get_model_size(hash)
    local minptr = memory.alloc(24)
    local maxptr = memory.alloc(24)
    MISC.GET_MODEL_DIMENSIONS(hash, minptr, maxptr)
    min = memory.read_vector3(minptr)
    max = memory.read_vector3(maxptr)
    local size = {}
    size['x'] = max['x'] - min['x']
    size['y'] = max['y'] - min['y']
    size['z'] = max['z'] - min['z']
    size['max'] = math.max(size['x'], size['y'], size['z'])
    return size
end

----删除实体
function delete_object(model)
    local hash = util.joaat(model)
    for k, object in pairs(entities.get_all_objects_as_handles()) do
        if ENTITY.GET_ENTITY_MODEL(object) == hash then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false) 
            entities.delete(object)
        end
    end
end

----UFO引力
function UFO_gravitation(pid)
    local coords = players.get_position(pid)
    coords.z = coords.z + 63
    local ufoModel = MISC.GET_HASH_KEY("p_spinning_anus_s")
    local ufo = entities.create_object(ufoModel, coords)
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(player, false)

    if PED.IS_PED_IN_VEHICLE(player, vehicle, false) then
        request_control(vehicle)
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid), false)
        VEHICLE.BRING_VEHICLE_TO_HALT(vehicle, 0.0, 1, false)
        FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 83, 100.0, false, true, 0.0)
        util.yield(1000)
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, false, true, true)
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 65, 0.0, 0.0, 0.0, 1, false, true, true, true, true)
        util.yield(6000)
        entities.delete(ufo)
    else
        entities.delete(ufo)
        util.toast("目标不在车辆中") 
    end
end



----RGB随机颜色
function random_colour()
	local colour = {a = 255}
	colour.r = math.random(0,255)
	colour.g = math.random(0,255)
	colour.b = math.random(0,255)
	return colour
end
----渐变RGB颜色
function gradient_colour(timer, frequency)
    local colour = {a = 255}
    local curtime = timer / 1000 
    colour.r = math.floor( math.sin( curtime * frequency + 0 ) * 127 + 128 )
    colour.g = math.floor( math.sin( curtime * frequency + 2 ) * 127 + 128 )
    colour.b = math.floor( math.sin( curtime * frequency + 4 ) * 127 + 128 )
    return colour
end


----加入组/保镖
function join_group(ped)
    if not PED.IS_PED_IN_GROUP(ped) then
        PED.SET_PED_AS_GROUP_MEMBER(ped, PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID()))
        PED.SET_PED_NEVER_LEAVES_GROUP(ped, true)
    end
    PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, util.joaat("rgFM_HateEveryOne"))
    PED.SET_GROUP_SEPARATION_RANGE(PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID()), 9999.0)
    PED.SET_GROUP_FORMATION_SPACING(PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID()), 1.0, 0.9, 3.0)
    PED.SET_GROUP_FORMATION(PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID()), 0)
end

----自定义传送
function Custom_teleport()
    local label = util.register_label("输入坐标(x,y,z),以','分开")
	local input = get_input_from_screen_keyboard(label, 15, "")
    if input == "" then return end
    local tab = string.split(input,",")
    for i = 1, 3 do
        tab[i] = tonumber(tab[i])
        if type(tab[i]) ~= "number" or #tab ~= 3 then
            util.toast("格式错误")
            return 
        end
    end
    teleport(tab[1], tab[2], tab[3])
end

----驾驶超级游艇
function super_yacht()
    if not is_entity_on_water(PLAYER.PLAYER_PED_ID()) then
        notification("~y~~bold~不在水上:D", HudColour.blue)
        return
    end
    local CoreSpawnPoint = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, 0, 0)
    local CoreSpawnHeading = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID())
    local CoreHash = util.joaat("kosatka")
    request_model(CoreHash)
    local Core = entities.create_vehicle(CoreHash, CoreSpawnPoint, CoreSpawnHeading)
    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), Core, -1)
    ENTITY.SET_ENTITY_VISIBLE(Core, false, false)
    local YachtHash = util.joaat("prop_cj_big_boat")
    request_model(YachtHash)
    local Yacht = entities.create_object(YachtHash, CoreSpawnPoint, CoreSpawnHeading)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(Yacht, Core, 0, 0, 0, 0, 0, 0, 0, true, false, false, true, 0, true, 0)
    ENTITY.SET_ENTITY_COLLISION(Yacht, true, false)
    ENTITY.SET_ENTITY_COLLISION(Core, false, false)
end


----神风炮
function create_shooting_target(x, y, z)
    local hash = 510628364
    local target = create_object(hash, x, y, z)--靶子
    ENTITY.SET_ENTITY_VISIBLE(target, true, false)--可见
    ENTITY.SET_ENTITY_COLLISION(target, false)--碰撞
    ENTITY.FREEZE_ENTITY_POSITION(target, true)--冻结
    return target
end
local JetSquadronRealNames = {"Lazer","raiju", "molotok", "pyro", "strikeforce", "seabreeze" , "howard", "besra", "starling", "rogue", "Stunt", "alphaz1", "nimbus", "luxor2", "mogul", "streamer216", "vestra", "cuban800", "dodo", "velum", "mammatus", "duster", "microlight"}
function Kamikaze_Gun()
    local pos = v3.new()
    if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), pos) and not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) then
        local PH_hash = 1267718013
        request_model(PH_hash)
        local PH = OBJECT.CREATE_OBJECT(PH_hash, pos.x, pos.y, pos.z + 0.1, true, false, true)--创建光标
        ENTITY.SET_ENTITY_ROTATION(PH, 0, 0, 90, 2, true)
        ENTITY.SET_ENTITY_VISIBLE(PH, false, false)--不可见
        ENTITY.SET_ENTITY_COLLISION(PH, false)--碰撞
        ENTITY.FREEZE_ENTITY_POSITION(PH, true)--冻结

        local target = create_shooting_target(pos.x, pos.y, pos.z)--目标靶

        local Ppedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_PED_ID())
        local randomPlane = util.joaat(JetSquadronRealNames[math.random(1, #JetSquadronRealNames)])
        request_model(randomPlane)
        local Offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PH, math.random(-200, 200), math.random(-200, 200), math.random(100, 500))
        local Kamikaze = entities.create_vehicle(randomPlane, Offset, math.random(-180, 180))--创建飞机
        local KamikazeCam = CAM.CREATE_CAMERA(26379945, true)

        util.create_tick_handler(function()
            --防止碰撞
            local distance = Get_Distance(ENTITY.GET_ENTITY_COORDS(target, false), ENTITY.GET_ENTITY_COORDS(Kamikaze, false), true)
            if distance > 7 then ENTITY.SET_ENTITY_COLLISION(Kamikaze, false, true) else ENTITY.SET_ENTITY_COLLISION(Kamikaze, true, true) end

            if ENTITY.DOES_ENTITY_EXIST(Kamikaze) then--禁止执行中重复生成模型
                PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
            else
                PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
            end
            set_entity_face_entity(Kamikaze, PH, true)
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(Kamikaze, 1, 0, 1.5, 0.0, true, true, true, true)
            CAM.RENDER_SCRIPT_CAMS(true, false, 3000, 1, 0, 0)
            CAM.SHAKE_CAM(KamikazeCam, "DRUNK_SHAKE", 1)
            GRAPHICS.ANIMPOSTFX_PLAY("MP_corona_switch_supermod", 0, true)
            GRAPHICS.ANIMPOSTFX_PLAY("MP_OrbitalCannon", 0, true)

            if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(Kamikaze) then--判断实体是否与任何物体碰撞
                local KamikazeOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Kamikaze,  math.random(-5, 5),  math.random(-5, 5),  math.random(-5, 5))
                FIRE.ADD_EXPLOSION(KamikazeOffset.x, KamikazeOffset.y, KamikazeOffset.z, 59, 1, true, false, 1.0, false)
                AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "DLC_XM_Explosions_Orbital_Cannon", Kamikaze, 0, true, 0)

                util.yield(1500)
                --还原相机
                CAM.RENDER_SCRIPT_CAMS(false, false, 3000, 1, 0, 0);
                CAM.DESTROY_CAM(KamikazeCam, true)
                GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon", 0, true)
                GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon", 0, true)
                GRAPHICS.ANIMPOSTFX_STOP("MP_corona_switch_supermod", 0, true)
                GRAPHICS.ANIMPOSTFX_STOP("MP_corona_switch_supermod", 0, true)
                entities.delete(Kamikaze)
                entities.delete(PH)
                entities.delete(target)
                return false
            end
        end)
        CAM.HARD_ATTACH_CAM_TO_ENTITY(KamikazeCam, Kamikaze, -10, 0, 0, 0, -10, 6, true)
        local cause = VEHICLE.GET_VEHICLE_CAUSE_OF_DESTRUCTION(Kamikaze)
        VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(Kamikaze, true)
        VEHICLE.SET_VEHICLE_ENGINE_ON(Kamikaze, true, true, 0)
        KamikazePilot = PED.CREATE_RANDOM_PED_AS_DRIVER(Kamikaze, 1)
        VEHICLE.CONTROL_LANDING_GEAR(Kamikaze, 3)
    end
end

--发送神风炮
function Send_Kamikaze_Gun(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
    local randomPlane = util.joaat(JetSquadronRealNames[math.random(1, #JetSquadronRealNames)])
    request_model(randomPlane)
    local Offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), math.random(-200, 200), math.random(-200, 200), math.random(100, 500))
    local Kamikaze = entities.create_vehicle(randomPlane, Offset, math.random(-180, 180))--创建飞机
    local KamikazeCam = CAM.CREATE_CAMERA(26379945, true)

    util.create_tick_handler(function()
        --防止碰撞
        local distance = Get_Distance(ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid), false), ENTITY.GET_ENTITY_COORDS(Kamikaze, false), true)
        if distance > 7 then ENTITY.SET_ENTITY_COLLISION(Kamikaze, false, true) else ENTITY.SET_ENTITY_COLLISION(Kamikaze, true, true) end

        set_entity_face_entity(Kamikaze, PLAYER.GET_PLAYER_PED(pid), true)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(Kamikaze, 1, 0, 1.5, 0.0, true, true, true, true)
        CAM.RENDER_SCRIPT_CAMS(true, false, 3000, 1, 0, 0)
        CAM.SHAKE_CAM(KamikazeCam, "DRUNK_SHAKE", 1)
        GRAPHICS.ANIMPOSTFX_PLAY("MP_corona_switch_supermod", 0, true)
        GRAPHICS.ANIMPOSTFX_PLAY("MP_OrbitalCannon", 0, true)

        if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(Kamikaze) then--判断实体是否与任何物体碰撞
            local KamikazeOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Kamikaze,  math.random(-5, 5),  math.random(-5, 5),  math.random(-5, 5))
            FIRE.ADD_EXPLOSION(KamikazeOffset.x, KamikazeOffset.y, KamikazeOffset.z, 59, 1, true, false, 1.0, false)
            AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "DLC_XM_Explosions_Orbital_Cannon", Kamikaze, 0, true, 0)

            util.yield(1500)
            CAM.RENDER_SCRIPT_CAMS(false, false, 3000, 1, 0, 0);
            CAM.DESTROY_CAM(KamikazeCam, true)
            GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon", 0, true)
            GRAPHICS.ANIMPOSTFX_STOP("MP_OrbitalCannon", 0, true)
            GRAPHICS.ANIMPOSTFX_STOP("MP_corona_switch_supermod", 0, true)
            GRAPHICS.ANIMPOSTFX_STOP("MP_corona_switch_supermod", 0, true)
            entities.delete(Kamikaze)
            return false
        end
    end)
    CAM.HARD_ATTACH_CAM_TO_ENTITY(KamikazeCam, Kamikaze, -10, 0, 0, 0, -10, 6, true)
    local cause = VEHICLE.GET_VEHICLE_CAUSE_OF_DESTRUCTION(Kamikaze)
    VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(Kamikaze, true)
    VEHICLE.SET_VEHICLE_ENGINE_ON(Kamikaze, true, true, 0)
    KamikazePilot = PED.CREATE_RANDOM_PED_AS_DRIVER(Kamikaze, 1)
    VEHICLE.CONTROL_LANDING_GEAR(Kamikaze, 3)
end


----玩家栏
function player_bar()
    local posx = 0.01
    local posy = 0.005

    for pid = 0, 32 do
        if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
            local name = PLAYER.GET_PLAYER_NAME(pid)
            local infotags = " ["
            local infocolor = "~w~";local infocolor2 = "~o~"
            local network = memory.alloc(13*4)
            NETWORK.NETWORK_HANDLE_FROM_PLAYER(pid,network,13)
        --标签
            if players.get_host() == pid then
                infotags = infotags .. "H"
                infocolor = "~y~"
            end
            if players.get_script_host() == pid then
                infotags = infotags .. "S"
                infocolor = "~b~"
            end
            if players.is_marked_as_modder(pid) then
                infotags = infotags .. "M"
                infocolor = "~r~"
            end
            if players.is_godmode(pid) then 
                infotags = infotags .. "G"
            end
            if players.is_in_interior(pid) then
                infotags = infotags .. "I"
                infocolor = "~g~"
            end
            if NETWORK.NETWORK_IS_FRIEND(network) then
                infotags = infotags .. "F"
                infocolor = "~q~"
            end

            if PLAYER.PLAYER_ID() == pid then
                infocolor = "~b~"
            end

            if infotags == " [" then
                infotags = ""
            else
                infotags = infotags.."]"
            end

            draw_string(infocolor..name..infocolor2..infotags, posx, posy, 0.4, 4)

            posx = posx + (#name + #infotags)/400 + 0.04
            
            if posx > 0.93 then
                posy = posy + 0.02
                posx = 0.01
            end
        end
    end
end


----删除枪
function delete_gun()
    if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
        local entity = get_entity_player_is_aiming_at(PLAYER.PLAYER_ID())
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        if ENTITY.DOES_ENTITY_EXIST(entity) and ENTITY.IS_AN_ENTITY(entity) and not PED.IS_PED_A_PLAYER(entity) then
            entities.delete(entity)
        end
    end
end


----喇叭爆炸
function horn_bomb()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), false)
    if AUDIO.IS_HORN_ACTIVE(vehicle) then
        local coords = ENTITY.GET_ENTITY_COORDS(vehicle)
        local shootCoords = v3.new(coords)
        for i = 1, 3 do
            local rot = ENTITY.GET_ENTITY_ROTATION(vehicle, 2):toDir()
            local vel = ENTITY.GET_ENTITY_VELOCITY(vehicle)
            v3.mul(rot, 25 + math.abs(vel.x))
            v3.add(shootCoords, rot)
            FIRE.ADD_OWNED_EXPLOSION(VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1), shootCoords.x + math.random(-2, 2), shootCoords.y + math.random(-2, 2), shootCoords.z, 10, 100,true, false, 0.1)
            util.yield()
        end
    end
end


----推动玩家
function Driving_Player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(player, false)
        local glitch_hash = util.joaat("prop_shuttering03")
        request_model(glitch_hash)
        ENTITY.APPLY_FORCE_TO_ENTITY(PLAYER.GET_PLAYER_PED(pid), 3, 50, 50, 0, 0.0, 0.0, 0.0, 0, false, false, true, false, false)
        local dumb_object_front = entities.create_object(glitch_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), 0, 1, 0))
        local dumb_object_back = entities.create_object(glitch_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), 0, 0, 0))
        ENTITY.SET_ENTITY_VISIBLE(dumb_object_front, false)
        ENTITY.SET_ENTITY_VISIBLE(dumb_object_back, false)
        util.yield()
        entities.delete(dumb_object_front)
        entities.delete(dumb_object_back)
        util.yield()
    end
end



----仓鼠球
function Hamster_Ball(pid)
    local hash = 1768956181
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), 0, 0, -1)
    local obj = {}
    for i = 1, 18 do
        obj[i] = create_object(hash, pos.x, pos.y, pos.z)
        ENTITY.SET_ENTITY_ROTATION(obj[i], 0, 0, i * 10 , 1, true)
    end
end

----粉碎机
function shredder(pid)
    local hash = util.joaat('sr_mp_spec_races_take_flight_sign')
    for i=-3, 5 do 
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), 0, i, 2)
        local crusher = create_object(hash, pos.x, pos.y, pos.z)
        ENTITY.SET_ENTITY_ROTATION(crusher, 0, 180, ENTITY.GET_ENTITY_HEADING(PLAYER.GET_PLAYER_PED(pid)) + 90, 2)
    end
end

----升天电梯
function biker_lift(on,pid)
    biker_toggled = on
    if biker_toggled then
        local hash = -1342281820
        request_model(hash)
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
        pos.z = pos.z - 10
        send_biker = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, pos.x, pos.y, pos.z, true, false, true)
        while biker_toggled do
            local pos2 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(send_biker, pos2.x, pos2.y, pos.z, false, false, false, false)
            pos.z = pos.z + 0.1
            util.yield(10)
            local pos3 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
            local hight = pos3.z
            if pos.z > hight then
                ENTITY.APPLY_FORCE_TO_ENTITY(PLAYER.GET_PLAYER_PED(pid), 3, 50, 50, 0, 0.0, 0.0, 0.0, 0, false, false, true, false, false)
                ENTITY.APPLY_FORCE_TO_ENTITY(PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(pid), false), 3, 50, 50, 0, 0.0, 0.0, 0.0, 0, false, false, true, false, false)
                pos.z = hight - 10
            end
        end
    else
        entities.delete(send_biker)
    end
end


----极限跳跃
function extreme_jump(index)
    if index == 1 then
        SpawnHeight = 250
    elseif index == 2 then
        SpawnHeight = 500
    elseif index == 3 then
        SpawnHeight = 1000
    end

    local pedm = PLAYER.PLAYER_PED_ID()
    local PlaneHash = 368211810
    local CarHash = 1455990255
    request_model(PlaneHash)
    request_model(CarHash)
    local heading = ENTITY.GET_ENTITY_HEADING(pedm)
    local PlaneSpawnLoc = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, 0, 0, SpawnHeight)
    local CarSpawnLoc = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, 0, 0, SpawnHeight + 4) --104
    
    local Plane = entities.create_vehicle(PlaneHash, PlaneSpawnLoc, heading)
    ENTITY.SET_ENTITY_INVINCIBLE(Plane, true)
    if PED.IS_PED_IN_ANY_VEHICLE(pedm, true) then
        Car = entities.get_user_vehicle_as_handle()
        ENTITY.SET_ENTITY_HEADING(Car, heading + 180)
        ENTITY.SET_ENTITY_VELOCITY(Car, 0, 100, 0)
    else 
        Car = entities.create_vehicle(CarHash, CarSpawnLoc, 0)
        ENTITY.SET_ENTITY_HEADING(Car, heading + 180)
        PED.SET_PED_INTO_VEHICLE(pedm, Car, -1)
    end
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(Plane, 1, 0, 100, 0, true, true, true, true)
    ENTITY.SET_ENTITY_COORDS(Car, CarSpawnLoc.x, CarSpawnLoc.y, CarSpawnLoc.z, false, false, false, false)
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(Car, 1, 0, -100, 0, true, true, true, true)

    local Timer = 350
    util.create_tick_handler(function()
        Timer = Timer - 1
        util.draw_centred_text("开仓倒计时 : " .. Timer)
        if Timer < 0 then
            VEHICLE.SET_VEHICLE_DOOR_OPEN(Plane, 2, false, false)
            return false
        end
    end)
end


----飞机撞向花园银行
function planetobank()
    local pos = {x = -914.1707, y = -1164.9396, z=250}
    local plane = create_vehicle(util.joaat('jet'), pos.x, pos.y, pos.z, -68)
    VEHICLE.SET_VEHICLE_ENGINE_ON(plane, true, true, false)
    VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
    VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(plane, 0.0)
    for i=1, 5 do 
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 150.0)
        util.yield(1000)
    end
end

----生成怪兽军队
function Create_Monster_Army(pid)
    local player_Yule_army = {}
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
    pos.y = pos.y - 5
    pos.z = pos.z + 1
    local Yule = util.joaat("U_M_M_YuleMonster")
    request_model(Yule)
    for i = 1, 48 do
        player_Yule_army[i] = entities.create_ped(28, Yule, pos, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(player_Yule_army[i], true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(player_Yule_army[i], true)
        PED.SET_PED_COMPONENT_VARIATION(player_Yule_army[i], 0, 0, 1, 0)
        TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(player_Yule_army[i], ped, 0, -0.3, 0, 7.0, -1, 10, true)
        WEAPON.GIVE_WEAPON_TO_PED(player_Yule_army[i], util.joaat('WEAPON_CANDYCANE'),  9999, true, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(player_Yule_army[i], 20, true)
        PED.SET_PED_SHOOT_RATE(player_Yule_army[i], 1000)
        util.yield()
    end 
end

----炸弹车
function bomb_car()
    local hash = util.joaat("speedo2")
    request_model(hash)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, 0, 0)
    local heading = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID())
    local spawnedCar = entities.create_vehicle(hash, pos, heading)
    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), spawnedCar, -1) 
    util.toast('~o~按下鼠标右键引爆载具')
    util.create_tick_handler(function()
        VEHICLE.START_VEHICLE_HORN(spawnedCar, 300, 1330140418, false)
        util.yield(500)
    end)
    while spawnedCar do
        ENTITY.SET_ENTITY_INVINCIBLE(spawnedCar, false)
        if PAD.IS_CONTROL_PRESSED(0, 68) then
            local Bomboffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(spawnedCar, 0, 0, 0)
            FIRE.ADD_EXPLOSION(Bomboffset.x, Bomboffset.y, Bomboffset.z, 59, 1, true, false, 1.0, false)
            util.yield(1000)
            entities.delete(spawnedCar)
            break
        end
        util.yield()
    end
end




----猫猫炸弹
function cat_bomb(pid)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)
    coords.x = coords['x']
    coords.y = coords['y']
    coords.z = coords['z']
    hash = util.joaat("a_c_cat_01")
    request_model(hash)
    for i=1, 30 do
        local cat = entities.create_ped(28, hash, coords, math.random(0, 270))
        local rand_x = math.random(-10, 10)*5
        local rand_y = math.random(-10, 10)*5
        local rand_z = math.random(-10, 10)*5
        ENTITY.SET_ENTITY_INVINCIBLE(cat, true)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(cat, 1, rand_x, rand_y, rand_z, true, false, true, true)
        AUDIO.PLAY_PAIN(cat, 7, 0)
    end
end


----绘制玩家模型
local cur_rot = 0
local cur_focused_player = nil
local cur_clone = 0
function create_player_clone(pid)
    local new_ped = PED.CLONE_PED(PLAYER.GET_PLAYER_PED(pid), false, false, true)
    ENTITY.FREEZE_ENTITY_POSITION(new_ped, true)
    ENTITY.SET_ENTITY_INVINCIBLE(new_ped, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(new_ped, true)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(new_ped, true)
    ENTITY.SET_ENTITY_COORDS(new_ped, 0, 0, -50, true, true, true, false)
    ENTITY.SET_ENTITY_ALPHA(new_ped, 200, false)
    ENTITY.SET_ENTITY_COLLISION(new_ped, false, true)
    return new_ped
end
function Draw_player_model()
    local focused = players.get_focused()
    if (focused[1] ~= nil and focused[2] == nil) and menu.is_open() then
        local pid = focused[1]
        if pid ~= cur_focused_player then
            if cur_clone ~= 0 then
                entities.delete(cur_clone)
            end
            cur_focused_player = pid
            cur_clone = create_player_clone(pid)
        end
        local offset = get_offset_from_gameplay_camera(3.0)--从相机获取偏移量
        ENTITY.SET_ENTITY_COORDS(cur_clone, offset.x, offset.y, offset.z-1, true, true, true, false)
        ENTITY.SET_ENTITY_ROTATION(cur_clone, 0, 0, cur_rot, 0, true)
        util.draw_box(v3.new(offset.x, offset.y, offset.z + 0.1), v3.new(0, 0, cur_rot), v3.new(1, 1, 2), 255, 255, 255, 50)
        if cur_rot >= 360 then
            cur_rot = 0 
        else 
            cur_rot += 1
        end
    else
        if cur_focused_player ~= nil then
            entities.delete(cur_clone)
            cur_clone = 0
            cur_focused_player = nil
        end
    end
end




----娱乐粒子效果
local selptfx = {a= "core",b= "ent_dst_gen_gobstop",c ="5"}
function ptfx_fun()
    local targets = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
    local tar1 = ENTITY.GET_ENTITY_COORDS(targets, true)
    request_ptfx_asset(selptfx.a)
    GRAPHICS.USE_PARTICLE_FX_ASSET(selptfx.a)
    GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(selptfx.b, tar1.x, tar1.y, tar1.z, 0, 0, 0, selptfx.c, true, true, false)
    util.yield(200)
end
function sel_ptfx_fun(value)
    local ptfx = funptfx[value]
    selptfx.c = ptfx[3]--size
    selptfx.b = ptfx[2]--eff
    selptfx.a = ptfx[1]--ptfx
end

----粒子效果轰炸
local ptfxx = {lib = 'scr_rcbarry2', sel = 'scr_clown_appears'}
function p_eff_bomb(pid)
    local targets = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local tar1 = ENTITY.GET_ENTITY_COORDS(targets, true)
    request_ptfx_asset(ptfxx.lib)
    GRAPHICS.USE_PARTICLE_FX_ASSET(ptfxx.lib)
    GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(ptfxx.sel, tar1.x, tar1.y, tar1.z + 1, 0, 0, 0, 5, true, true, true)
end
function sel_p_eff_bomb(value)
    ptfxx.sel = Fxha[value]
    ptfxx.lib = 'core'
end


----预设服装
function load_cloth_from_file(filepath)
    local file = io.open(filepath, "r")
    if file then
        local data = json.decode(file:read("*a"))
        file:close()
        return data
    else
        ERROR_LOG("无法读取文件" .. filepath .. "'")
    end
end
function load_clothes(directory)
    local loaded_cloth = {}
    for i, filepath in ipairs(filesystem.list_files(directory)) do
        local _, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if not filesystem.is_dir(filepath) and ext == "json" then
            table.insert(loaded_cloth, load_cloth_from_file(filepath))
        end
    end
    return loaded_cloth
end
function Preset_outfits()
    local outfit_folder = filesystem.scripts_dir() .. "daidaiScript\\Outfits"

    outs_folfer = menu.action(my_cloth, "打开文件夹", {}, "", function()
        util.open_folder(outfit_folder)
    end)
    outs_div = menu.divider(my_cloth, "衣柜")

    presetclothes = load_clothes(outfit_folder)
    for _, cloth in pairs(presetclothes) do
        cloth.name = menu.action(my_cloth, cloth.name.."["..cloth.type.."]", {}, "", function()
            if cloth.type == "女性" then--mp_f_freemode_01
                change_model(PLAYER.PLAYER_ID(), MISC.GET_HASH_KEY("mp_f_freemode_01"))
                menu.trigger_commands("mpfemale")
                --change_model(PLAYER.PLAYER_ID(), MISC.GET_HASH_KEY("mp_f_freemode_01"))
            else
                change_model(PLAYER.PLAYER_ID(), MISC.GET_HASH_KEY("mp_m_freemode_01"))
                menu.trigger_commands("mpmale")
                --change_model(PLAYER.PLAYER_ID(), MISC.GET_HASH_KEY("mp_m_freemode_01"))
            end
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 0, cloth.Head, cloth.Head_Variation, 0)--头部
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 1, cloth.Mask, cloth.Mask_Variation, 0)--面具
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 2, cloth.Hair, 0, 0)--发型
            PED1._SET_PED_HAIR_COLOR(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), cloth.Hair_Colour, cloth.highlight_Color)--发型颜色
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 3, cloth.Gloves_Torso, cloth.Gloves_Torso_Variation, 0)--手套/躯干
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 4, cloth.Pants, cloth.Pants_Variation, 0)--裤子
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 5, cloth.Parachute_Bag, cloth.Parachute_Bag_Variation, 0)--降落伞/背包
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 6, cloth.Shoes, cloth.Shoes_Variation, 0)--鞋子
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 7, cloth.Accessories, cloth.Accessories_Variation, 0)--配件
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 8, cloth.Top_2, cloth.Top_2_Variation, 0)--上身2
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 9, cloth.Top_3, cloth.Top_3_Variation, 0)--上身3
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 10, cloth.Decals, cloth.Decals_Variation, 0)--贴花
            PED.SET_PED_COMPONENT_VARIATION(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 11, cloth.Top, cloth.Top_Variation, 0)--上身

            PED.SET_PED_PROP_INDEX(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 0, cloth.Hat, cloth.Hat_Variation, 0)--帽子
            PED.SET_PED_PROP_INDEX(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 1, cloth.Glasses, cloth.Glasses_Variation, 0)--眼镜
            PED.SET_PED_PROP_INDEX(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 2, cloth.Earwear, cloth.Earwear_Variation, 0)--耳饰
            PED.SET_PED_PROP_INDEX(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 6, cloth.Watch, cloth.Watch_Variation, 0)--手表
            PED.SET_PED_PROP_INDEX(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), 7, cloth.Bracelet, cloth.Bracelet_Variation, 0)--手链

        end)
    end
end
function endPreset_outfits()
    menu.delete(outs_folfer)
    menu.delete(outs_div)
    for _, cloth in pairs(presetclothes) do
        if cloth.name then
            menu.delete(cloth.name)
        end
    end
end





----传送到他的载具
function tp_p_car(pid)
    if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.GET_PLAYER_PED(pid)) then
        local player_veh = PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED(pid))
        local hash = ENTITY.GET_ENTITY_MODEL(player_veh)
        local seat_count = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(hash)
        for i = 0, seat_count - 1 do
            if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
                PED.SET_PED_INTO_VEHICLE(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()), player_veh, i)
                break
            end
        end
    else
        util.toast("玩家不在载具")
    end
end


----缩小NPC
function shrink_peds(on)
    if on then	
        local peds = entities.get_all_peds_as_handles()
        for i = 1, #peds do
            if not PED.IS_PED_A_PLAYER(peds[i]) then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(peds[i])
                PED.SET_PED_CONFIG_FLAG(peds[i], 223, true)
            end
        end
    else
        local peds = entities.get_all_peds_as_handles()
        for i = 1, #peds do
            if not PED.IS_PED_A_PLAYER(peds[i]) then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(peds[i])
                PED.SET_PED_CONFIG_FLAG(peds[i], 223, false)
            end
        end
    end
end

----黑人爆炸
function niggers_bomb(pid)
    local targetPlayerPed = PLAYER.GET_PLAYER_PED(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(targetPlayerPed, true)
    local model = MISC.GET_HASH_KEY("Player_One")
    for i = 0, 25 do
        create_ped(1, model, pos.x, pos.y, pos.z, 0)
    end
    FIRE.ADD_OWNED_EXPLOSION(targetPlayerPed, pos.x, pos.y, pos.z, 2, 50, true, false, 0.0)
end



----避免事故
function aa_thread()
    local player_cur_car = entities.get_user_vehicle_as_handle()
    if player_cur_car ~= 0 then
        local c = ENTITY.GET_ENTITY_COORDS(player_cur_car, true)
        local size = get_model_size(ENTITY.GET_ENTITY_MODEL(player_cur_car))
        for i= 1, 3 do
            if i == 1 then
                aad = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_cur_car, -size['x'], size['y']+0.1, size['z']/2)
            elseif i == 2 then
                aad = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_cur_car, 0.0, size['y']+0.1, size['z']/2)
            else
                aad = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_cur_car, size['x'], size['y']+0.1, size['z']/2)
            end
            if ENTITY.GET_ENTITY_SPEED(player_cur_car) > 10 then
                local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
                SHAPETEST.GET_SHAPE_TEST_RESULT(SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(c.x,c.y,c.z,aad.x,aad.y,aad.z,-1,player_cur_car,4), ptr1, ptr2, ptr3, ptr4)
                local p1 = memory.read_int(ptr1)
                local p2 = memory.read_vector3(ptr2)
                local p3 = memory.read_vector3(ptr3)
                local p4 = memory.read_int(ptr4)
                local results = {p1, p2, p3, p4}
                if results[1] ~= 0 then
                    ENTITY.SET_ENTITY_VELOCITY(player_cur_car, 0.0, 0.0, 0.0)
                end
            end
        end
    end
end



----载具引擎快速开启
function fastoncar()
    local localped = PLAYER.PLAYER_PED_ID()
    if PED.IS_PED_GETTING_INTO_A_VEHICLE(localped) then
        local veh = PED.GET_VEHICLE_PED_IS_ENTERING(localped)
        if not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(veh) then
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, 1000)
            VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
        end
        if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 then
            VEHICLE.SET_HELI_BLADES_FULL_SPEED(veh)
        end
    end
end

----自动锁门
function auto_locked(toggled)
    auto_lock_door = toggled
    if auto_lock_door then 
        while auto_lock_door do
            if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), true) then
                local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
                request_control(car)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(car, 2)
                if PAD.IS_CONTROL_PRESSED(0 , 23) then 
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
                end
            else
                local lastcar = PLAYER.GET_PLAYERS_LAST_VEHICLE()
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(lastcar, 1)
            end
            util.yield()
        end
    else
        local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        local lastcar = PLAYER.GET_PLAYERS_LAST_VEHICLE()
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(car, 1)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(lastcar, 1)
    end
end

----解锁正在进入的载具
function unlockcar()
    local localPed = PLAYER.PLAYER_PED_ID()
    local veh = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(localPed)
    if PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
        local v = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(v, 1)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(v, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(v, PLAYER.PLAYER_ID(), false)
        ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
        util.yield()
    else
        if veh ~= 0 then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                for i = 1, 20 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    util.yield(100)
                end
            end
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                util.toast("未取得控制权")
            else
                util.toast("获得控制权")
            end
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 1)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(veh, false)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, PLAYER.PLAYER_ID(), false)
            VEHICLE.SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(veh, false)
        end
    end
end

----给予所有武器
function give_all_weapon(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        for _, weapon in pairs(weapon_list) do 
            WEAPON.GIVE_WEAPON_TO_PED(PLAYER.GET_PLAYER_PED(pid), weapon.hash, 9999, false, false)
        end
    end
end
----移除玩家武器
function remove_all_weapon(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        for _, weapon in pairs(weapon_list) do 
            WEAPON.REMOVE_WEAPON_FROM_PED(PLAYER.GET_PLAYER_PED(pid), weapon.hash)
        end
    end
end
----重型狙击枪攻击
function Heavy_gun_to_player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
        local hash = util.joaat("weapon_heavysniper")
        request_weapon_asset(hash)
        WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 5, pos.x, pos.y, pos.z, 200, false, hash, 0, true, false, 2500.0)
    end
end
----烟花攻击
function firework_to_player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
        local hash = util.joaat("weapon_firework")
        request_weapon_asset(hash)
        WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 3.0, pos.x, pos.y, pos.z - 2.0, 200, false, hash, 0, true, false, 2500.0)
    end
end
----原子波攻击
function atom_waves_to_player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
        local hash = util.joaat("weapon_raypistol")
        request_weapon_asset(hash)
        WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 3.0, pos.x, pos.y, pos.z - 2.0, 200, false, hash, 0, true, false, 2500.0)
    end
end
----燃烧弹攻击
function Incendiary_to_player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
        local hash = util.joaat("weapon_molotov")
        request_weapon_asset(hash)
        WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z - 2.0, 200, false, hash, 0, true, false, 2500.0)
    end
end
----电磁脉冲攻击
function ElectroMagnetic_Pulse_to_player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
        local hash = util.joaat("weapon_emplauncher")
        request_weapon_asset(hash)
        WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z - 2.0, 200, false, hash, 0, true, false, 2500.0)
    end
end

----弹飞玩家
function Bounce_Flying_Player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local poopy_butt = util.joaat("adder")
        local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(player)
        pos.z = pos.z - 10
        request_model(poopy_butt)
        local vehicle = entities.create_vehicle(poopy_butt, pos, 0)
        ENTITY.SET_ENTITY_VISIBLE(vehicle, false)
        util.yield(250)
        if vehicle ~= 0 then
            ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 100, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
            util.yield(250)
            entities.delete(vehicle)
        end
    end
end

----烟花发射玩家
function firework_send_player(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), false)
        local hash = util.joaat("weapon_firework")
        request_weapon_asset(hash)
        WEAPON.GIVE_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), hash, 120, true, false)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 3.0, pos.x, pos.y, pos.z - 2.0, 200, false, hash, 0, true, false, 2500.0)

        local poopy_butt = util.joaat("adder")
        local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(player)
        pos.z = pos.z - 10
        request_model(poopy_butt)
        local vehicle = entities.create_vehicle(poopy_butt, pos, 0)
        ENTITY.SET_ENTITY_VISIBLE(vehicle, false)
        if vehicle ~= 0 then
            ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 100, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
            util.yield(100)
            entities.delete(vehicle)
        end
    end
end


----空袭飞机
air_strike_state = 0
local hash_plane = util.joaat("weapon_airstrike_rocket")
function air_strike_plane()
    local control = Config.controls.airstrikeaircraft
    if air_strike_state == 0 then
        notification("~y~~bold~空袭飞机可用于飞机和直升机", HudColour.blue)
        local msg = "按 ~%s~ 以使用空袭飞机"
        util.show_corner_help(msg:format("INPUT_VEH_HORN"))
        air_strike_state = 1
    end
    if PED.IS_PED_IN_FLYING_VEHICLE(PLAYER.PLAYER_PED_ID()) and PAD.IS_CONTROL_PRESSED(2, control) and
        timer.elapsed() > 800 then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        local vehPos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
        local groundZ = get_ground_z(vehPos)
        local startTime = newTimer()
        util.create_tick_handler(function()
            util.yield(500)
            if vehPos.z - groundZ < 10.0 then
                return false
            end
            local pos = get_random_offset_in_range(vehPos, 0.0, 5.0)
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z - 3.0,pos.x, pos.y, groundZ,200,true,hash_plane,PLAYER.PLAYER_PED_ID(), true, false, 1000.0)
            return startTime.elapsed() < 5000
        end)
        timer.reset()
    end
end


----烟花枪
function Firework_Gun()
    if WEAPON.GET_SELECTED_PED_WEAPON(PLAYER.PLAYER_PED_ID()) == 2138347493 and not ENTITY.DOES_ENTITY_EXIST(firework) then
        PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) then
            local hash = util.joaat("w_lr_firework_rocket")
            request_model(hash)
            local player_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0.0, 0.5, 0.5)
            local dir = {}
            local c2 = {}
            c2 = get_offset_from_gameplay_camera(15)
            dir.x = (c2.x - player_pos.x) * 15
            dir.y = (c2.y - player_pos.y) * 15
            dir.z = (c2.z - player_pos.z) * 15

            firework = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, player_pos.x, player_pos.y, player_pos.z, true, false, false)
            local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(firework, 1, dir.x, dir.y, dir.z, false, false, false, false)
            ENTITY.SET_ENTITY_ROTATION(firework, cam_rot.x, cam_rot.y, cam_rot.z, 0, true)
            ENTITY.SET_ENTITY_HAS_GRAVITY(firework, false)

            request_ptfx_asset("scr_rcpaparazzo1")
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_rcpaparazzo1")
            local effect = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY("scr_mich4_firework_trail_spawn", firework, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false, 0, 0, 0, 0)
            GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(effect, 255, 255, 255, 0)
            local timer = 150
            while not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(firework) and timer > 0 do
                if WEAPON.GET_SELECTED_PED_WEAPON(PLAYER.PLAYER_PED_ID()) == 2138347493 then
                    PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
                end
                timer = timer - 1
                util.yield()
            end
            if timer <= 0 or ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(firework) then
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(effect, false)
                local fireworkPos = ENTITY.GET_ENTITY_COORDS(firework, true)
                entities.delete(firework)
                for i = 1, 10 do
                    local model = util.joaat("adder")
                    request_model(model)
                    local vehicle = entities.create_vehicle(model, fireworkPos, 0)
                    ENTITY.SET_ENTITY_COLLISION(vehicle, false, true)
                    ENTITY.SET_ENTITY_ROTATION(vehicle, math.random(-180.0, 180.0), math.random(-180.0, 180.0), math.random(-180.0, 180.0), 0, true)
                    VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 25)
                    util.yield(250)
                    ENTITY.SET_ENTITY_COLLISION(vehicle, true, true)
                end
            end
        end
    end
end




----抓钩枪
function grappling_gun()
    if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) and PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) then
        local raycast_coord = raycast_gameplay_cam(-1, 10000.0)
        if raycast_coord[1] == 1 then
            local lastdist = nil
            TASK.TASK_SKY_DIVE(PLAYER.PLAYER_PED_ID())
            while true do
                if PAD.IS_CONTROL_JUST_PRESSED(45, 45) then 
                    break
                end
                if raycast_coord[4] ~= 0 and ENTITY.GET_ENTITY_TYPE(raycast_coord[4]) >= 1 and ENTITY.GET_ENTITY_TYPE(raycast_coord[4]) < 3 then
                    ggc1 = ENTITY.GET_ENTITY_COORDS(raycast_coord[4], true)
                else
                    ggc1 = raycast_coord[2]
                end
                local c2 = players.get_position(PLAYER.PLAYER_ID())
                local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(ggc1['x'], ggc1['y'], ggc1['z'], c2['x'], c2['y'], c2['z'], true)
                -- safety
                if not lastdist or dist < lastdist then 
                    lastdist = dist
                else
                    break
                end
                if ENTITY.IS_ENTITY_DEAD(PLAYER.PLAYER_PED_ID()) then
                    break
                end
                if dist >= 10 then
                    local dir = {}
                    dir['x'] = (ggc1['x'] - c2['x']) * dist
                    dir['y'] = (ggc1['y'] - c2['y']) * dist
                    dir['z'] = (ggc1['z'] - c2['z']) * dist
                    ENTITY.SET_ENTITY_VELOCITY(PLAYER.PLAYER_PED_ID(), dir['x'], dir['y'], dir['z'])
                end
                util.yield()
            end
        end
    end
end



----货运直升机
local spawnedVehicles = {}
local currentCargobob = 0
function spawn_cargobob_with_magnet()
    STREAMING.REQUEST_MODEL(util.joaat("cargobob"))
    local playerPos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
    local heading = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID())
    local spawnPos = { x = playerPos.x, y = playerPos.y, z = playerPos.z + 5.0 }
    if ENTITY.DOES_ENTITY_EXIST(currentCargobob) then
        entities.delete(currentCargobob)
    end
    local cargobob = entities.create_vehicle(util.joaat("cargobob"), spawnPos, heading)
    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(cargobob, 1.0)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(cargobob)
    VEHICLE.CREATE_PICK_UP_ROPE_FOR_CARGOBOB(cargobob, 1)
    currentCargobob = cargobob
    local playerPed = PLAYER.PLAYER_PED_ID()
    PED.SET_PED_INTO_VEHICLE(playerPed, cargobob, -1)
    table.insert(spawnedVehicles, cargobob)
    return cargobob
end
local currentSkylift = 0
function spawn_skylift()
    STREAMING.REQUEST_MODEL(util.joaat("skylift"))
    local playerPed = PLAYER.PLAYER_PED_ID()
    local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    local heading = ENTITY.GET_ENTITY_HEADING(playerPed)
    local spawnPos = { x = playerPos.x, y = playerPos.y, z = playerPos.z + 5.0 }
    if ENTITY.DOES_ENTITY_EXIST(currentSkylift) then
        entities.delete(currentSkylift)
    end
    local skylift = entities.create_vehicle(util.joaat("skylift"), spawnPos, heading)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(skylift)
    currentSkylift = skylift
    PED.SET_PED_INTO_VEHICLE(playerPed, skylift, -1)
    table.insert(spawnedVehicles, skylift)
    return skylift
end
function attach_vehicle_to_skylift()
    if ENTITY.DOES_ENTITY_EXIST(currentSkylift) then
        local skyliftPos = ENTITY.GET_ENTITY_COORDS(currentSkylift, true)
        local radius = 10.0
        local vehicle = VEHICLE.GET_CLOSEST_VEHICLE(skyliftPos.x, skyliftPos.y, skyliftPos.z, radius, 0, 70)
        if vehicle ~= 0 then
            ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle, currentSkylift, 0, 0.0, -3.5, -2.0, 0.0, 0.0, 0.0, true, true, true, false, 0, true, 0)
            if ENTITY.IS_ENTITY_ATTACHED(vehicle) then
                attachedVehicle = vehicle
            end
        end
    end
end
function detach_vehicle_from_skylift(vehicle)
    if ENTITY.IS_ENTITY_ATTACHED(vehicle) then
        ENTITY.DETACH_ENTITY(vehicle, true, true)
    end
end

----神风敢死队
function kamikaze_dare(index,pid)
    local vehicles = {"Lazer", "Mammatus",  "Cuban800"}
    local plane = vehicles[index]
    local hash  = util.joaat(plane)
    request_model(hash)
    local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = get_random_offset_from_entity(targetPed, 20.0, 20.0)
    pos.z = pos.z + 30.0
    local plane = entities.create_vehicle(hash, pos, 0.0)
    set_entity_face_entity(plane, targetPed, true)
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(plane, 150.0)
    VEHICLE.CONTROL_LANDING_GEAR(plane, 3)
    util.yield(1000)
    entities.delete(plane)
end
----撞击玩家
function Impact_player(index,pid)
    local vehicles = {"insurgent2", "phantom2", "adder"}
    local vehicleName = vehicles[index]
    local vehicleHash = util.joaat(vehicleName)
    request_model(vehicleHash)
    local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coord = get_random_offset_from_entity(targetPed, 12.0, 12.0)
    local vehicle = entities.create_vehicle(vehicleHash, coord, 0.0)
    set_entity_face_entity(vehicle, targetPed, false)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 2)
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100.0)
    util.yield(1000)
    entities.delete(vehicle)
end

----黑洞
local blackHoleType = 1
blackHolePos = {x = 0, y = 0, z = 0}
tableBlackHole = {"吸引", "排斥",}
local pushStrength = 1
local pushToX = 1
local pushToY = 1
local pushToZ = 1
function black_hole_type(a)
    blackHoleType = a
end
function black_hole_Sth(a)
    pushStrength = a
end
function black_hole_posuser()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()))
    menu.set_value(blackHolePosX, math.floor(pos.x))--向下取整
    menu.set_value(blackHolePosY, math.floor(pos.y))
    menu.set_value(blackHolePosZ, math.floor(pos.z))
    blackHolePos.x = pos.x
    blackHolePos.y = pos.y
    blackHolePos.z = pos.z
end
function black_hole_posx(a)
    blackHolePos.x = a
end
function black_hole_posy(a)
    blackHolePos.y = a
end
function black_hole_posz(a)
    blackHolePos.z = a
end
function black_hole()
    local blackHolepeds = entities.get_all_peds_as_handles()
    local blackHoleVehicle = entities.get_all_vehicles_as_handles()

    for i, ped in ipairs(blackHolepeds) do
        if ped ~= PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID()) then
            blackHoleVehicle[#blackHoleVehicle+1] = ped
        end
    end

    for index, value in ipairs(blackHoleVehicle) do
        vehiclePos = ENTITY.GET_ENTITY_COORDS(value)
        if ENTITY.DOES_ENTITY_EXIST(value) == true then
            if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(value) == false then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(value)
            end
            if blackHoleType == 1 then
                if blackHolePos.x > vehiclePos.x then
                    pushToX = pushStrength
                elseif blackHolePos.x < vehiclePos.x then
                    pushToX = -pushStrength
                end
                if blackHolePos.y > vehiclePos.y then
                    pushToY = pushStrength
                elseif blackHolePos.y < vehiclePos.y then
                    pushToY = -pushStrength
                end
                if blackHolePos.z > vehiclePos.z then
                    pushToZ = pushStrength
                elseif blackHolePos.z < vehiclePos.z then
                    pushToZ = -pushStrength
                end
                ENTITY.APPLY_FORCE_TO_ENTITY(value, 1, pushToX, pushToY, pushToZ, 0, 0, 0, 0, false, true, true, false)
            elseif blackHoleType == 2 then
                if blackHolePos.x > vehiclePos.x then
                    pushToX = -pushStrength
                elseif blackHolePos.x < vehiclePos.x then
                    pushToX = pushStrength
                end
                if blackHolePos.y > vehiclePos.y then
                    pushToY = -pushStrength
                elseif blackHolePos.y < vehiclePos.y then
                    pushToY = pushStrength
                end
                if blackHolePos.z > vehiclePos.z then
                    pushToZ = -pushStrength
                elseif blackHolePos.z < vehiclePos.z then
                    pushToZ = pushStrength
                end
                ENTITY.APPLY_FORCE_TO_ENTITY(value, 1, pushToX, pushToY, pushToZ, 0, 0, 0, 0, false, true, true, false)
            end
        end
    end
end


----洛奇斯怪兽mk2
function lochness_mk2()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    local monster = MISC.GET_HASH_KEY("h4_prop_h4_loch_monster")--怪兽
    local oppressor = MISC.GET_HASH_KEY("oppressor2")--mk2
    local obj = create_object(monster, pos.x, pos.y, pos.z)
    local veh = create_vehicle(oppressor, pos.x, pos.y, pos.z, 0)
    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), veh, -1)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(obj, veh, 0, -0.25, -1.0, 1.0, 0.0, 0.0, -90.0, true, false, false, false, 0, true, 0)
end


----无碰撞
local noclip_speed = 1
function no_clip_speed(value)
    noclip_speed = value
end
function no_clip(on)
    no_clipd = on
    if no_clipd then
        while no_clipd do
            if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
                if veh ~= 0 then
                    ENTITY.FREEZE_ENTITY_POSITION(veh, true)
                    ENTITY.SET_ENTITY_COLLISION(veh, false, false)
        
                    local rot = CAM.GET_GAMEPLAY_CAM_ROT(5)
                    ENTITY.SET_ENTITY_ROTATION(veh, rot.x, rot.y, rot.z, 5, true)
        
                    if util.is_key_down(0x57) then -- W
                        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0, 1 * noclip_speed, 0)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pos.x, pos.y, pos.z, false, false, false)
                    elseif util.is_key_down(0x53) then -- S
                        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0, -1 * noclip_speed, 0)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pos.x, pos.y, pos.z, false, false, false)
                    end
                    if util.is_key_down(0x41) then -- A
                        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, -1 * noclip_speed, 0, 0)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pos.x, pos.y, pos.z, false, false, false)
                    elseif util.is_key_down(0x44) then -- D
                        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 1 * noclip_speed, 0, 0)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pos.x, pos.y, pos.z, false, false, false)
                    end
                    -- left shift
                    if util.is_key_down(0x10) then
                        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0, 0, 1 * noclip_speed)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pos.x, pos.y, pos.z, false, false, false)
                    end
                    -- left control
                    if util.is_key_down(0x11) then
                        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0, 0, -1 * noclip_speed)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pos.x, pos.y, pos.z, false, false, false)
                    end
                end
            else
                local ped = PLAYER.PLAYER_PED_ID()
                ENTITY.FREEZE_ENTITY_POSITION(ped, true)
                ENTITY.SET_ENTITY_COLLISION(ped, false, false)
        
                local rot = CAM.GET_GAMEPLAY_CAM_ROT(5)
                ENTITY.SET_ENTITY_ROTATION(ped, rot.x, rot.y, rot.z, 5, true)
        
                if util.is_key_down(0x57) then -- W
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 1 * noclip_speed, 0)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, pos.x, pos.y, pos.z, false, false, false)
                elseif util.is_key_down(0x53) then -- S
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, -1 * noclip_speed, 0)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, pos.x, pos.y, pos.z, false, false, false)
                end
                if util.is_key_down(0x41) then -- A
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, -1 * noclip_speed, 0, 0)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, pos.x, pos.y, pos.z, false, false, false)
                elseif util.is_key_down(0x44) then -- D
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 1 * noclip_speed, 0, 0)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, pos.x, pos.y, pos.z, false, false, false)
                end
                -- left shift
                if util.is_key_down(0x10) then
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 0, 1 * noclip_speed)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, pos.x, pos.y, pos.z, false, false, false)
                end
                -- left control
                if util.is_key_down(0x11) then
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 0, -1 * noclip_speed)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, pos.x, pos.y, pos.z, false, false, false)
                end
            end
            util.yield()
        end
    else
        if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
            if veh ~= 0 then
                ENTITY.FREEZE_ENTITY_POSITION(veh, false)
                ENTITY.SET_ENTITY_COLLISION(veh, true, true)
            end
        else
            local ped = PLAYER.PLAYER_PED_ID()
            ENTITY.FREEZE_ENTITY_POSITION(ped, false)
            ENTITY.SET_ENTITY_COLLISION(ped, true, true)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
        end
    end
end


----NPC在玩家面前自杀
function do_ped_suicide(ped)
    request_control_of_entity_once(ped)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
    WEAPON.GIVE_WEAPON_TO_PED(ped, util.joaat("weapon_pistol"), 1, false, true)
    WEAPON.SET_CURRENT_PED_WEAPON(ped, util.joaat("weapon_pistol"), true)
    request_anim_dict("mp_suicide")
    util.yield(1000)
    local start_time = os.time()
    -- either wait till the ped is standing still, or 3 seconds, whichever is first
    while ENTITY.GET_ENTITY_SPEED(ped) > 1 and os.time() - start_time < 3 do 
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, "mp_suicide", "pistol", 8.0, 8.0, -1, 2, 0.0, false, false, false)
    util.yield(800)
    ENTITY.SET_ENTITY_HEALTH(ped, 0.0, 0)
    util.yield(10000)
    entities.delete(ped)
end
function npc_suicide(index,pid)
    local plyr = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(plyr, 0.0, 1.0, 0.0)
    local ped = 0
    if index == 1 then
        ped = PED.CLONE_PED(plyr, true, false, true)
        ENTITY.SET_ENTITY_COORDS(ped, c.x, c.y, c.z)
        ENTITY.SET_ENTITY_HEADING(ped, ENTITY.GET_ENTITY_HEADING(plyr) + 180)
    else
        local hash = traumatize_option_hashes[index]
        request_model(hash)
        ped = entities.create_ped(3, hash, c, ENTITY.GET_ENTITY_HEADING(plyr) + 180)
    end
    do_ped_suicide(ped)
end


----附加实体枪
local seleted_attach_ent = 'vigilante'
function create_attach_ent(hash, x, y, z, target_ent)
    if STREAMING.IS_MODEL_A_PED(hash) then
        local ent = create_ped(1, hash, x, y, z+20, ENTITY.GET_ENTITY_HEADING(target_ent))
        calm_ped(ent, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(ent, target_ent--[[ 主实体 ]], 0--[[ boneindex ]], 0, 0, 0, 0, 0, 0, true, false, false, true, 0, true, 0)
    elseif STREAMING.IS_MODEL_A_VEHICLE(hash) then
        local ent = create_vehicle(hash, x, y, z+20, ENTITY.GET_ENTITY_HEADING(target_ent))
        ENTITY.ATTACH_ENTITY_TO_ENTITY(ent, target_ent--[[ 主实体 ]], 0--[[ boneindex ]], 0, 0, 0, 0, 0, 0, true, false, false, true, 0, true, 0)
    elseif STREAMING.IS_MODEL_VALID(hash) then
        local ent = create_object(hash, x, y, z+20)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(ent, target_ent--[[ 主实体 ]], 0--[[ boneindex ]], 0, 0, 0, 0, 0, 0, true, false, false, true, 0, true, 0)
    end
end
function selete_attach_entity_gun(value)
    seleted_attach_ent = Objl[value]
end
function attach_entity_gun()
    local pos = v3.new()
    local target = memory.alloc(8)
    if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), pos) then
        if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), target) then
            local target_ent = memory.read_int(target)
            if STREAMING.IS_MODEL_A_PED(ENTITY.GET_ENTITY_MODEL(target_ent)) and PED.IS_PED_IN_ANY_VEHICLE(target_ent) then
                target_ent = PED.GET_VEHICLE_PED_IS_IN(target_ent, false)
            end
            local hash = MISC.GET_HASH_KEY(seleted_attach_ent)
            create_attach_ent(hash, pos.x, pos.y, pos.z, target_ent)
        end
    end
end

----定点打击
function targeted_strike()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local wpos = HUD.GET_BLIP_INFO_ID_COORD(HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID()))
        for i = 1, 30 do
            SE_add_owned_explosion(GetLocalPed(), wpos.x, wpos.y, wpos.z + 30 - i, 29, 10, true, false, 1)
            FIRE.ADD_EXPLOSION(wpos.x, wpos.y, wpos.z + 30 - i, 29, 10, true, false, 0, false)
            FIRE.ADD_EXPLOSION(wpos.x, wpos.y, wpos.z + 30 - i, 59, 10, true, false, 0, false)
           util.yield(30)
        end
    end
end
----定点循环轰炸
function executeNuke(pos)
    for a = 0, 100, 4 do
        FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z + a, 8, 10.0, true, false, 1.0, false)
        util.yield(50)
    end
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 82, 10.0, true, false, 1.0, false)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z , 82, 10.0, true, false, 1.0, false)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 82, 10.0, true, false, 1.0, false)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 82, 10.0, true, false, 1.0, false)
end
function targeted_loop_strike()
    local waypointPos = HUD.GET_BLIP_INFO_ID_COORD(HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID()))
    if waypointPos then
        local hash = util.joaat('w_arena_airmissile_01a')
        request_model(hash)
        waypointPos.z = waypointPos.z + 30
        local bomb = entities.create_object(hash, waypointPos)
        waypointPos.z = waypointPos.z - 30
        ENTITY.SET_ENTITY_ROTATION(bomb, -90, 0, 0,  2, true)
        ENTITY.APPLY_FORCE_TO_ENTITY(bomb, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0, true, false, true, false, true)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        while not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(bomb) do
            util.yield_once()
        end
        entities.delete(bomb)
        executeNuke(waypointPos)
    end
end

----指示灯
function pilot_lamp()
    if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
        show_button()
        sf.SET_DATA_SLOT(0,PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(0, 35, true), '右转灯')
        sf.SET_DATA_SLOT(1,PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(0, 130, true), '双闪灯')
        sf.SET_DATA_SLOT(2,PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(0, 34, true), '左转灯')
        show_button2()
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        local left = PAD.IS_CONTROL_PRESSED(0, 34)--174[A]
        local right = PAD.IS_CONTROL_PRESSED(0, 35)--175[D]
        local rear = PAD.IS_CONTROL_PRESSED(0, 130)--173[S]
        if left and not right and not rear then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, true)
        elseif right and not left and not rear then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, true)
        elseif rear and not left and not right then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, true)
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, true)
        else
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, false)
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, false)
        end
    end
end


----载具附加
function vehicle_attach(index,pid)
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
    local player_cur_car = entities.get_user_vehicle_as_handle()
    if car ~= 0 then
        request_control(car)
        pluto_switch index do
            case 1: 
                ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), car, 0, 0.0, -0.20, 2.00, 1.0, 1.0,1, true, true, true, false, 0, true, 0)
                break 
            case 2: 
                if player_cur_car ~= 0 and car ~= player_cur_car then
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(car, player_cur_car, 0, 0.0, -5.00, 0.00, 1.0, 1.0,1, true, true, true, false, 0, true, 0)
                end
                break
            case 3: 
                if player_cur_car ~= 0 and car ~= player_cur_car then
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(player_cur_car, car, 0, 0.0, -5.00, 0.00, 1.0, 1.0,1, true, true, true, false, 0, true, 0)
                end
                break
            case 4: 
                ENTITY.DETACH_ENTITY(car, false, false)
                if player_cur_car ~= 0 then
                    ENTITY.DETACH_ENTITY(player_cur_car, false, false)
                end
                ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), false, false)
                break
        end
    end
end

----传送到标记点
function tp_waypoint()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local waypoint = HUD.GET_BLIP_INFO_ID_COORD(HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID()))
        local x,y,z = waypoint_coord(waypoint)
        teleport(x, y, z)
    end
end

----骑乘动物
function riding_animals(index)
    local ranimal_hashes = {util.joaat("a_c_deer"), util.joaat("a_c_boar"), util.joaat("a_c_cow")}
    local hash = ranimal_hashes[index]
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
    local animal = create_ped(8, hash, pos.x, pos.y, pos.z, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
    ENTITY.SET_ENTITY_INVINCIBLE(animal, true)
    ENTITY.FREEZE_ENTITY_POSITION(animal, true)
    ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
    local m_z_off = 0 
    local f_z_off = 0
    pluto_switch index do 
        case 1: 
            m_z_off = 0.3 
            f_z_off = 0.15
            break
        case 2:
            m_z_off = 0.4
            f_z_off = 0.3
            break
        case 3:
            m_z_off = 0.2 
            f_z_off = 0.1 
            break
    end
    if ENTITY.GET_ENTITY_MODEL(PLAYER.PLAYER_PED_ID()) == util.joaat("mp_f_freemode_01") then 
        z_off = f_z_off
    else
        z_off = m_z_off
    end
    ENTITY.ATTACH_ENTITY_TO_ENTITY(PLAYER.PLAYER_PED_ID(), animal, PED.GET_PED_BONE_INDEX(animal, 24816), -0.3, 0.0, z_off, 0.0, 0.0, 90.0, false, false, false, true, 2, true)
    request_anim_dict("rcmjosh2")
    TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "rcmjosh2", "josh_sitting_loop", 8.0, 1, -1, 2, 1.0, false, false, false)
    ENTITY.FREEZE_ENTITY_POSITION(animal, false)
    ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
    while ENTITY.DOES_ENTITY_EXIST(animal) do
        -- 离开
        if PAD.IS_CONTROL_JUST_PRESSED(23, 23) then --F
            ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID())
            entities.delete_by_handle(animal)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
            animal = 0
        end
        -- 移动
        if not ENTITY.IS_ENTITY_IN_AIR(animal) then 
            if PAD.IS_CONTROL_PRESSED(0, 32) then 
                local side_move = PAD.GET_CONTROL_NORMAL(146, 146)
                local fwd = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(animal, side_move*10.0, 8.0, 0.0)
                TASK.TASK_LOOK_AT_COORD(animal, fwd.x, fwd.y, fwd.z, 0, 0, 2)
                TASK.TASK_GO_STRAIGHT_TO_COORD(animal, fwd.x, fwd.y, fwd.z, 20.0, -1, ENTITY.GET_ENTITY_HEADING(animal), 0.5)
            end
        end
        util.yield()
    end
end

----原力
function atom_force(toggled)
    atom_force_toggle = toggled
    if atom_force_toggle then
        local notif_format = string.format("按 ~%s~ 和 ~%s~ 来使用原力", "INPUT_ATTACK", "INPUT_AIM")
        util.show_corner_help(notif_format)
        local effect = Effect.new("scr_ie_tw", "scr_impexp_tw_take_zone")
        local colour = {r = 0.5, g = 0.0, b = 0.5, a = 1.0}
        request_fx_asset(effect.asset)
        GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
        GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(colour.r, colour.g, colour.b)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(effect.name, PLAYER.PLAYER_PED_ID(), 0.0, 0.0, -0.9,1.0, 1.0,1, 1.0, false, false, false)
    end
    while atom_force_toggle do
        PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_ID(), true)
        PAD.DISABLE_CONTROL_ACTION(0, 25, true)
        PAD.DISABLE_CONTROL_ACTION(0, 68, true)
        PAD.DISABLE_CONTROL_ACTION(0, 91, true)
        local entities = get_ped_nearby_vehicles(PLAYER.PLAYER_PED_ID())
        for _, vehicle in ipairs(entities) do
            if not (PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) and PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) == vehicle) then
                if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) and
                    request_control_once(vehicle) then
                    ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 0.5, 1.0, 1.0,1, 0, false, false, true, false, false)
                elseif PAD.IS_DISABLED_CONTROL_PRESSED(0, 25) and
                    request_control_once(vehicle) then
                    ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, -70.0,1.0, 1.0,1, 0, false, false, true, false, false)
                end
            end
        end
        util.yield()
    end
end

----死亡日志
local DeathlogDir = filesystem.store_dir() .. 'SakuraLog\\Death Log'
filesystem.mkdirs(DeathlogDir)
local Death_Log = filesystem.store_dir() .. 'SakuraLog\\Death Log\\Death_Log.txt'
function add_deathlog(time, name, weapon)
    local file, errmsg = io.open(Death_Log, "a+")
    if not file then
        return false
    end
    file:write(time..' '..name..' 类型: '..weapon..'\n')
    file:close()
    return input, true
end
function death_log()
    if PED.IS_PED_DEAD_OR_DYING(PLAYER.PLAYER_PED_ID()) then
        local killer = PED.GET_PED_SOURCE_OF_DEATH(PLAYER.PLAYER_PED_ID())
        local ts = os.time()
        local time = os.date('%Y-%m-%d %H:%M:%S', ts)
        if killer == PLAYER.PLAYER_PED_ID() then
            local pid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(killer)
            local pname = PLAYER.GET_PLAYER_NAME(pid)
            add_deathlog("["..time.."]", "玩家: "..pname, '自杀')
            util.yield(12000)
            return 
        end
        if STREAMING.IS_MODEL_A_PED(ENTITY.GET_ENTITY_MODEL(killer)) then
            local pid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(killer)
            local pname = PLAYER.GET_PLAYER_NAME(pid)
            if pname != nil then
                add_deathlog("["..time.."]", "玩家: "..pname, '武器')
            end
            util.toast('被'..pname..'使用武器击杀')
            util.yield(12000)
        elseif STREAMING.IS_MODEL_A_VEHICLE(ENTITY.GET_ENTITY_MODEL(killer)) then
            local vehowner = entities.get_owner(entities.handle_to_pointer(killer))
            local pname = PLAYER.GET_PLAYER_NAME(vehowner)
            if pname != nil then
                add_deathlog("["..time.."]", "玩家: "..pname, '载具')
            end
            util.toast('被'..pname..'使用载具击杀')
            util.yield(12000)
        end
    end
end
function open_dea_log()
    util.open_folder(DeathlogDir)
end
function clear_dea_log()
    io.remove(Death_Log)
    notification("~y~~bold~清除完成", math.random(0, 200))
end



--PED笼子
local pedset_def = 'u_m_m_jesus_01'
function Delcar(vic, spec, pid)
    if PED.IS_PED_IN_ANY_VEHICLE(vic) ==true then
        local tarcar = PED.GET_VEHICLE_PED_IS_IN(vic, true)
        GetControl(tarcar, spec, pid)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(tarcar)
        entities.delete(tarcar)
    end
end
function SetPedCoor(pedS, tarx, tary, tarz)
    ENTITY.SET_ENTITY_COORDS(pedS, tarx, tary, tarz, false, true, true, false)
end
function Teabagtime(p1, p2, p3, p4, p5, p6, p7, p8)
    util.create_tick_handler (function ()
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p1, 'LES1A_DHAC', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p2, 'TUSCO_AHAD', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p3, 'LES1A_DHAC', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p4, 'TUSCO_AHAD', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p5, 'LES1A_DHAC', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p6, 'TUSCO_AHAD', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p7, 'LES1A_DHAC', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(p8, 'TUSCO_AHAD', 'LESTER', 'SPEECH_PARAMS_FORCE_SHOUTED', 1)
        util.yield(100)
    end)
end
function Jesuslovesyou(ped_tab)
    util.create_tick_handler (function ()
        for _, pi in ipairs(ped_tab) do
            AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(pi, 'BUMP', 'JESSE', 'SPEECH_PARAMS_FORCE', 1)
            util.yield(250)
        end
    end)
end
function Trevortime(ped_tab)
    util.create_tick_handler (function ()
        for _, pi in ipairs(ped_tab) do
            AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(pi, 'TR2_ABAJ', 'TREVOR', 'SPEECH_PARAMS_FORCE', 1)
            util.yield(100)
        end
    end)
end
function Fuckyou(ped_tab)
    util.create_tick_handler (function ()
        for _, pi in ipairs(ped_tab) do
            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(pi, 'GENERIC_FUCK_YOU', 'SPEECH_PARAMS_FORCE', 1)
            util.yield(100)
        end
    end)
end
function Provoke(ped_tab)
    util.create_tick_handler (function ()
        for _, pi in ipairs(ped_tab) do
            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(pi, 'Provoke_Trespass', 'Speech_Params_Force_Shouted_Critical', 1)
            util.yield(100)
        end

    end)
end
function Insulthigh(ped_tab)
    util.create_tick_handler (function ()
        for _, pi in ipairs(ped_tab) do
            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(pi, 'Generic_Insult_High', 'SPEECH_PARAMS_FORCE', 1)
            util.yield(100)
        end
    end)
end
function Warcry(ped_tab)
    util.create_tick_handler (function ()
        for _, pi in ipairs(ped_tab) do
            AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(pi, 'GENERIC_WAR_CRY', 'SPEECH_PARAMS_FORCE', 1)
            util.yield(100)
        end

    end)
end
function Pedspawn(pedhash, tar1)
    request_model(pedhash)
    local pedS = entities.create_ped(1, pedhash, tar1, 0)
    ENTITY.SET_ENTITY_INVINCIBLE(pedS, true)
    ENTITY.FREEZE_ENTITY_POSITION(pedS, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pedS, true)
    PED.SET_PED_CAN_LOSE_PROPS_ON_DAMAGE(pedS, false)
    if pedhash == util.joaat('ig_lestercrest') then
        PED.SET_PED_PROP_INDEX(pedS, 1)
    end
    return pedS
end
function Runanim(ent, animdict, anim)
    TASK.TASK_PLAY_ANIM(ent, animdict, anim, 1.0, 1.0, -1, 3, 0.5, false, false, false)
    while ENTITY.IS_ENTITY_PLAYING_ANIM(ent, animdict, anim, 3) ==false do
        TASK.TASK_PLAY_ANIM(ent, animdict, anim, 1.0, 1.0, -1, 3, 0.5, false, false, false)
        util.yield()
    end
end
function PFP(pedm, playerm)--Ped Facing Player adapted from PhoenixScript
    local ppos = ENTITY.GET_ENTITY_COORDS(playerm)
    local pmpos = ENTITY.GET_ENTITY_COORDS(pedm)
    local hx = ppos.x - pmpos.x
    local hy = ppos.y - pmpos.y
    local head = MISC.GET_HEADING_FROM_VECTOR_2D(hx, hy)
    return ENTITY.SET_ENTITY_HEADING(pedm, head)
end
function DelEnt(ped_tab)
    for _, Pedm in ipairs(ped_tab) do
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(Pedm)
        entities.delete(Pedm)
    end
end
function Stopsound()
    for i = 0, 99 do
        AUDIO.STOP_SOUND(i)
    end
end
function IPM(targets, tar1, pname, cage_table, pid)
    local tar2 = ENTITY.GET_ENTITY_COORDS(targets)
    local disbet = SYSTEM.VDIST2(tar2.x, tar2.y, tar2.z, tar1.x, tar1.y, tar1.z)
    if disbet < 0.5  then
        util.yield(800)
    elseif disbet >= 0.5  then
        DelEnt(cage_table[pid])
        cage_table[pid] = false
        Stopsound()
    end
end
function select_ped_cage(index)
    pedset_def = pedset_tab[index]
end
function auto_ped_cage(pid)
    local targets = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local tar1 = ENTITY.GET_ENTITY_COORDS(targets, true)
    local pname = PLAYER.GET_PLAYER_NAME(pid)
    if not ped_cage_table[pid] then
        local peds = {}
        local pedhash = util.joaat(pedset_def)
        local ped_tab = {'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'}
        for _, spawned_ped in ipairs(ped_tab) do
            spawned_ped = Pedspawn(pedhash, tar1)
            table.insert(peds,  spawned_ped)
        end
        SetPedCoor(peds[1], tar1.x, tar1.y - 0.5, tar1.z - 1.0)
        SetPedCoor(peds[2], tar1.x - 0.5, tar1.y - 0.5, tar1.z - 1.0)
        SetPedCoor(peds[3], tar1.x - 0.5, tar1.y, tar1.z - 1.0)
        SetPedCoor(peds[4], tar1.x - 0.5, tar1.y + 0.5, tar1.z - 1.0)
        SetPedCoor(peds[5], tar1.x, tar1.y + 0.5, tar1.z - 1.0)
        SetPedCoor(peds[6], tar1.x + 0.5, tar1.y + 0.5, tar1.z - 1.0)
        SetPedCoor(peds[7], tar1.x + 0.5, tar1.y, tar1.z - 1.0)
        SetPedCoor(peds[8], tar1.x + 0.5, tar1.y - 0.5, tar1.z - 1.0)
        if pedhash == util.joaat('IG_LesterCrest')  then
            Teabagtime(peds[1], peds[2], peds[3], peds[4], peds[5], peds[6], peds[7], peds[8])
        elseif pedhash == util.joaat('player_two') then
            Trevortime(peds)
        elseif pedhash == util.joaat('u_m_m_jesus_01') then
            Jesuslovesyou(peds)  
        elseif pedhash ~= util.joaat('IG_LesterCrest') or util.joaat('player_two') then
            if GENERIC_AUDIO.DOES_CONTEXT_EXIST_FOR_THIS_PED(peds[1], 'GENERIC_FUCK_YOU') ==true then 
                Fuckyou(peds)
            elseif GENERIC_AUDIO.DOES_CONTEXT_EXIST_FOR_THIS_PED(peds[1], 'Provoke_Trespass') then 
                Provoke(peds)
            elseif GENERIC_AUDIO.DOES_CONTEXT_EXIST_FOR_THIS_PED(peds[1], 'Generic_Insult_High') then 
                Insulthigh(peds)
            elseif GENERIC_AUDIO.DOES_CONTEXT_EXIST_FOR_THIS_PED(peds[1], 'GENERIC_WAR_CRY') then 
                Warcry(peds)
            end
        end
        request_anim_dict('rcmpaparazzo_2')
        request_anim_dict('mp_player_int_upperfinger')
        request_anim_dict('misscarsteal2peeing')
        request_anim_dict('mp_player_int_upperpeace_sign')
        local ped_anim = {peds[2], peds[3], peds[4], peds[5], peds[6], peds[7], peds[8]}
        for _, Pedanim in ipairs(ped_anim) do
            if pedhash == util.joaat('player_two') then
                Runanim(Pedanim, 'misscarsteal2peeing','peeing_loop')
                local tre = PED.GET_PED_BONE_INDEX(Pedanim, 0x2e28)
                request_ptfx_asset('core')
                GRAPHICS.USE_PARTICLE_FX_ASSET('core')
                GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("ent_amb_peeing", Pedanim, 0, 0, 0, -90, 0, 0, tre, 2, false, false, false, 0, 0, 0, 0)
            elseif pedhash == util.joaat('u_m_m_jesus_01') then
                Runanim(peds[1], 'mp_player_int_upperpeace_sign', 'mp_player_int_peace_sign')
                Runanim(Pedanim, 'mp_player_int_upperpeace_sign', 'mp_player_int_peace_sign')
            else
                Runanim(Pedanim, 'mp_player_int_upperfinger', 'mp_player_int_finger_02_fp')
                Runanim(peds[1], 'rcmpaparazzo_2', 'shag_loop_a')
            end
        end
        for _, Pedm in ipairs(peds) do
            PFP(Pedm, targets)
        end
        ped_cage_table[pid] = peds
    end
    while ped_cage_table[pid] do
        if players.exists(pid) then
            IPM(targets, tar1, pname, ped_cage_table, pid)
        end
    end
end


----物体笼子
local objcageset = 'prop_mineshaft_door'   
function select_obj_cage(index)
    objcageset = objsetcage[index]
end
function ObjFrezSpawn(hsel, tar1)
    local objHash = hsel
  local objfS =  OBJECT.CREATE_OBJECT(objHash, tar1.x, tar1.y, tar1.z, true, true, true)
  ENTITY.FREEZE_ENTITY_POSITION(objfS, true)
  return objfS
end
function SetObjCo(objS, tarx, tary, tarz)
    ENTITY.SET_ENTITY_COORDS(objS, tarx, tary, tarz, false, true, true, false)
end
function auto_obj_cage(pid)
    local targets = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local tar1 = ENTITY.GET_ENTITY_COORDS(targets, true)
    local pname = PLAYER.GET_PLAYER_NAME(pid)
    if not obj_table[pid] then
        local objs = {}
        local spec = menu.get_value(menu.ref_by_rel_path(menu.player_root(pid), "Spectate>Nuts Method"))
        Delcar(targets, spec, pid)
        local hsel = util.joaat(objcageset)
        request_model(hsel)
        local obj_tab = {'o1', 'o2', 'o3', 'o4', 'o5', 'o6', 'o7', 'o8'}
        for _, spawned_obj in ipairs(obj_tab) do
            spawned_obj =  ObjFrezSpawn(hsel, tar1)
            table.insert(objs,  spawned_obj)
        end
        obj_table[pid] = objs
        SetObjCo(objs[1], tar1.x, tar1.y - 0.5, tar1.z - 1.0)
        SetObjCo(objs[2], tar1.x - 0.5, tar1.y - 0.5, tar1.z - 1.0)
        SetObjCo(objs[3], tar1.x - 0.5, tar1.y, tar1.z - 1.0)
        SetObjCo(objs[4], tar1.x - 0.5, tar1.y + 0.5, tar1.z - 1.0)
        SetObjCo(objs[5], tar1.x, tar1.y + 0.5, tar1.z - 1.0)
        SetObjCo(objs[6], tar1.x + 0.5, tar1.y + 0.5, tar1.z - 1.0)
        SetObjCo(objs[7], tar1.x + 0.5, tar1.y, tar1.z - 1.0)
        SetObjCo(objs[8], tar1.x + 0.5, tar1.y - 0.5, tar1.z - 1.0)
        ENTITY.SET_ENTITY_ROTATION(objs[1], 0, 0, 180, 1, true)
        ENTITY.SET_ENTITY_ROTATION(objs[2], 0, 0, 135, 1, true)
        ENTITY.SET_ENTITY_ROTATION(objs[3], 0, 0, 90, 1, true)
        ENTITY.SET_ENTITY_ROTATION(objs[4], 0, 0, 45, 1, true)
        ENTITY.SET_ENTITY_ROTATION(objs[6], 0, 0, 315, 1, true)
        ENTITY.SET_ENTITY_ROTATION(objs[7], 0, 0, 270, 1, true)
        ENTITY.SET_ENTITY_ROTATION(objs[8], 0, 0, 225, 1, true)
        for _, horn in ipairs(objs) do
            AUDIO.PLAY_SOUND_FROM_ENTITY(-1, 'Alarm_Interior', horn, 'DLC_H3_FM_FIB_Raid_Sounds', 0, 0)
        end
    end
    while obj_table[pid] do
        if players.exists(pid) then
            IPM(targets, tar1, pname, obj_table, pid)
        end
    end
end







----飞机护航
function escort()
    local heading = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID())
    local hashJet = util.joaat("Lazer")
    local hashTarget = 1082797888 --:1082797888
    request_model(hashJet)
    request_model(hashTarget)

--CREATE_PED_INSIDE_VEHICLE
    local ped = PLAYER.PLAYER_PED_ID()
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 0, 200)

    local aJetpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, -50, -50, 200) --200
    local bJetpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 50, -50, 200)
    local cJetpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, -50, -100, 200)
    local dJetpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 50, -100, 200)
    local aJetAimpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, -20, 0, 0)
    local bJetAimpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 20, 0, 0)
    local cJetAimpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, -40, -40, 0) --200
    local dJetAimpos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 40, -40, 0) --200

    if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) then
        PlayerJet = entities.create_vehicle(hashJet, pos, heading)
        
        aTarget = entities.create_object(hashTarget, aJetAimpos)--obj
        bTarget = entities.create_object(hashTarget, bJetAimpos)
        cTarget = entities.create_object(hashTarget, cJetAimpos)
        dTarget = entities.create_object(hashTarget, dJetAimpos)
        ENTITY.SET_ENTITY_COLLISION(aTarget, false, false)
        ENTITY.SET_ENTITY_VISIBLE(aTarget, false, false)
        ENTITY.SET_ENTITY_COLLISION(bTarget, false, false)
        ENTITY.SET_ENTITY_VISIBLE(bTarget, false, false)
        ENTITY.SET_ENTITY_COLLISION(cTarget, false, false)
        ENTITY.SET_ENTITY_VISIBLE(cTarget, false, false)
        ENTITY.SET_ENTITY_COLLISION(dTarget, false, false)
        ENTITY.SET_ENTITY_VISIBLE(dTarget, false, false)

        PED.SET_PED_INTO_VEHICLE(ped, PlayerJet, -1)
        VEHICLE.CONTROL_LANDING_GEAR(PlayerJet, 3)--控制起落架
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(PlayerJet, 1, 0, 100, 0, true, true, true, true)

        JetA = entities.create_vehicle(hashJet, aJetpos, heading)--创建飞机
        JetB = entities.create_vehicle(hashJet, bJetpos, heading)
        JetC = entities.create_vehicle(hashJet, cJetpos, heading)
        JetD = entities.create_vehicle(hashJet, dJetpos, heading)

        PilotA = PED.CREATE_RANDOM_PED_AS_DRIVER(JetA, 1)--创建驾驶飞机的PED
        VEHICLE.SET_VEHICLE_ENGINE_ON(JetA, true, true, 0)
        
        PilotB = PED.CREATE_RANDOM_PED_AS_DRIVER(JetB, 1)
        VEHICLE.SET_VEHICLE_ENGINE_ON(JetB, true, true, 0)
        
        PilotC = PED.CREATE_RANDOM_PED_AS_DRIVER(JetC, 1)
        VEHICLE.SET_VEHICLE_ENGINE_ON(JetC, true, true, 0)
        
        PilotD = PED.CREATE_RANDOM_PED_AS_DRIVER(JetD, 1)
        VEHICLE.SET_VEHICLE_ENGINE_ON(JetD, true, true, 0)
        join_group(PilotA);join_group(PilotB);join_group(PilotC);join_group(PilotD)

        ENTITY.SET_ENTITY_INVINCIBLE(PlayerJet, true)
        ENTITY.SET_ENTITY_INVINCIBLE(JetA, true)
        ENTITY.SET_ENTITY_INVINCIBLE(JetB, true)
        ENTITY.SET_ENTITY_INVINCIBLE(JetC, true)
        ENTITY.SET_ENTITY_INVINCIBLE(JetD, true)
    end

    set_entity_face_entity(JetA, aTarget, true)
    set_entity_face_entity(JetB, bTarget, true)
    set_entity_face_entity(JetC, cTarget, true)
    set_entity_face_entity(JetD, dTarget, true)

    local aJetRealLoc = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(JetA, 0, 0, 0)
    local bJetRealLoc = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(JetB, 0, 0, 0)
    local cJetRealLoc = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(JetC, 0, 0, 0)
    local dJetRealLoc = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(JetD, 0, 0, 0)

    local aDistance = MISC.GET_DISTANCE_BETWEEN_COORDS(aJetRealLoc['x'], aJetRealLoc['y'], aJetRealLoc['z'], aJetAimpos['x'], aJetAimpos['y'], aJetAimpos['z'], true)
    local bDistance = MISC.GET_DISTANCE_BETWEEN_COORDS(bJetRealLoc['x'], bJetRealLoc['y'], bJetRealLoc['z'], bJetAimpos['x'], bJetAimpos['y'], bJetAimpos['z'], true)
    local cDistance = MISC.GET_DISTANCE_BETWEEN_COORDS(cJetRealLoc['x'], cJetRealLoc['y'], cJetRealLoc['z'], cJetAimpos['x'], cJetAimpos['y'], cJetAimpos['z'], true)
    local dDistance = MISC.GET_DISTANCE_BETWEEN_COORDS(dJetRealLoc['x'], dJetRealLoc['y'], dJetRealLoc['z'], dJetAimpos['x'], dJetAimpos['y'], dJetAimpos['z'], true)
    if aDistance < 40 then
        aJetSpeed = -0.8
    else
        aJetSpeed = 0.5
    end
    if bDistance < 40 then
        bJetSpeed = -0.8
    else
        bJetSpeed = 0.5
    end
    if cDistance < 40 then
        cJetSpeed = -0.8
    else
        cJetSpeed = 0.5
    end
    if dDistance < 40 then
        dJetSpeed = -0.8
    else
        dJetSpeed = 0.5
    end

    if not PED.IS_PED_ON_FOOT(ped) then
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(JetA, 1, 0, aJetSpeed, 0, true, true, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(aTarget, aJetAimpos.x, aJetAimpos.y, aJetAimpos.z, false, false, false)

        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(JetB, 1, 0, bJetSpeed, 0, true, true, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(bTarget, bJetAimpos.x, bJetAimpos.y, bJetAimpos.z, false, false, false)

        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(JetC, 1, 0, cJetSpeed, 0, true, true, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(cTarget, cJetAimpos.x, cJetAimpos.y, cJetAimpos.z, false, false, false)

        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(JetD, 1, 0, dJetSpeed, 0, true, true, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(dTarget, dJetAimpos.x, dJetAimpos.y, dJetAimpos.z, false, false, false)
    end
end







----消防栓大喷水
function firefighting(pid)
    local objects = {}
    for i = 1, 11 do
        local coords = players.get_position(pid)
        objects[#objects + 1] = entities.create_object(200846641, v3.new(coords.x + math.random(-5, 5), coords.y + math.random(-5, 5), coords.z))
        util.yield()
    end
    util.yield(500)
    for i, obj in ipairs(objects) do
        local objcoords = ENTITY.GET_ENTITY_COORDS(obj)
        FIRE.ADD_EXPLOSION(objcoords.x, objcoords.y, objcoords.z, 64, 100, true, true, 0.5, true)
    end
    util.yield(13000)
    for i = 1, #objects do
        entities.delete(objects[i])
    end
end


--intToIp
function intToIp(num)
    ip = ""
    local int16 = string.format("%x", num)
    for i = 1, #int16 do
      if 0 == math.fmod(i, 2) then
        if ip ~= "" then
          ip = ip .. "." .. var_int
        else
          ip = var_int
        end
      else
        var_int = tostring(tonumber(string.sub(int16, i, i + 1), 16))
      end
    end
    return ip
end

----涂鸦枪
local graffiti_radius = 5--半径
local graffiti_brightness = 100--亮度
local graffiti_colors = {r = 0, g = 0, b = 1, a = 0}--颜色
function graffiti_bright(value)
    graffiti_brightness = value
end
function graffiti_radiu(value)
    graffiti_radius = value
end
function graffiti_color(value)
    graffiti_colors = value 
end
function Graffiti_weapon(toggled)
    Graffiti = toggled
    local light_num = {}
    while Graffiti do
        local pos = v3.new()
        if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), pos) and not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) then
            light_num[#light_num + 1] = pos
        end
        for i = 1, #light_num do
            GRAPHICS.DRAW_LIGHT_WITH_RANGE(light_num[i].x, light_num[i].y, light_num[i].z, graffiti_colors.r * 255, graffiti_colors.g * 255, graffiti_colors.b * 255, graffiti_radius / 10, graffiti_brightness)
        end
        util.yield()
    end
end

----鲨鱼枪
function Shark_gun()
    local pos = v3.new()
	if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), pos) then
        local hash = 0x06C3F072
        local NPC = create_ped(26, hash, pos.x, pos.y, pos.z, 0)
        ENTITY.FREEZE_ENTITY_POSITION(NPC, true)
        ENTITY.SET_ENTITY_ROTATION(NPC, 90, 0, 0, 1, true)
        FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 4, 100, true, false, 1, false)
        FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 13, 1, true, false, 0, false)
    end
end
--鲨鱼吃掉玩家
function Shark_eating(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
    local hash = 0x06C3F072
    local NPC = create_ped(26, hash, pos.x, pos.y, pos.z, 0)
    ENTITY.FREEZE_ENTITY_POSITION(NPC, true)
    ENTITY.SET_ENTITY_ROTATION(NPC, 90, 0, 0, 1, true)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 4, 100, true, false, 1, false)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 13, 1, true, false, 0, false)
end


----NPC杀
function NPC_kill(pid)
    local hash = util.joaat("mp_m_weapexp_01")
    request_model(hash)
    for i = 1, 10 do
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
        pos.x = pos.x + math.random(-20, 20 + i)--获取随机数
        pos.y = pos.y + math.random(-20, 20)
        
        local Peds = PED.CREATE_PED(4, hash, pos.x, pos.y, pos.z, 1.0, true, false)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(Peds, 0x476BF155, 0, true)
        ENTITY.SET_ENTITY_HEALTH(Peds, 410, 0)
        PED.SET_PED_COMBAT_ABILITY(Peds, 2)
        PED.SET_PED_COMBAT_ATTRIBUTES(Peds, 5, true)
        TASK.TASK_COMBAT_PED(Peds, PLAYER.GET_PLAYER_PED(pid), 1, 16)
        PED.SET_PED_RELATIONSHIP_GROUP_HASH(Peds, 0x84DCFAAD)
        local posped = ENTITY.GET_ENTITY_COORDS(Peds)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(posped.x, posped.y, posped.z, posped.x, posped.y, posped.z + 0.1, 0, 0, 453432689, PLAYER.GET_PLAYER_PED(pid), false, true, 100)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)   
    end
end


----移除尸体
function Remove_dead_body()
    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
        if ENTITY.IS_ENTITY_DEAD(ped, true) then
            request_control(ped)
            entities.delete(ped)
        end
    end
end
----移除丧尸
function Remove_zombies()
    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
        if ENTITY.GET_ENTITY_MODEL(ped) == -1404353274 then
            request_control(ped)
            entities.delete(ped)
        end
    end
end
----NPC无视玩家
function NPC_Ignore_player()
    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
        calm_ped(ped, true)
    end
    PLAYER.SET_POLICE_IGNORE_PLAYER(PLAYER.PLAYER_ID(), true)
    PLAYER.SET_EVERYONE_IGNORE_PLAYER(PLAYER.PLAYER_ID(), true)
    PLAYER.SET_PLAYER_CAN_BE_HASSLED_BY_GANGS(PLAYER.PLAYER_ID(), false)
    PLAYER.SET_IGNORE_LOW_PRIORITY_SHOCKING_EVENTS(PLAYER.PLAYER_ID(), true)
end



----伪装
local disguise_object = 0
function player_disguise_select(index)
    disguise_object = index
end
local object = 0
function player_disguise(state)
    disguise_state = state
    if disguise_state then
        ENTITY.SET_ENTITY_ALPHA(PLAYER.PLAYER_PED_ID(), 0, false)
        while disguise_state do
            if disguise_objectt ~= disguise_object and ENTITY.DOES_ENTITY_EXIST(object) then
                entities.delete(object)
            end
            disguise_objectt = disguise_object
            object_hash = util.joaat(disguise_objects[disguise_objectt])
            player_pos = players.get_position(PLAYER.PLAYER_ID())
            if object == nil or not ENTITY.DOES_ENTITY_EXIST(object) then
                object = entities.create_object(object_hash, player_pos)
            end
            ENTITY.SET_ENTITY_COLLISION(object, false, false)
            player_rot = ENTITY.GET_ENTITY_ROTATION(PLAYER.PLAYER_PED_ID(), 5)
            ENTITY.SET_ENTITY_COORDS(object, player_pos.x, player_pos.y, player_pos.z - 1, false, false, false, false)
            ENTITY.SET_ENTITY_ROTATION(object, 0, 0, player_rot.z, 1, true)
            util.yield()
        end
    else
        entities.delete(object)
        ENTITY.SET_ENTITY_ALPHA(PLAYER.PLAYER_PED_ID(), 255, false)
    end
end




----列车选项
function get_closest_train()
    local vehicles = entities.get_all_vehicles_as_handles()
    for k, veh in pairs(vehicles) do
        if ENTITY.GET_ENTITY_MODEL(veh) == 1030400667 then
            request_control(veh)
            return veh
        end
    end
    util.toast("找不到附近的火车")
    return 0
end
function spawn_train(variation, pos)
    local trainmodels = {util.joaat("metrotrain"), util.joaat("freight"), util.joaat("freightcar"), util.joaat("freightcont1"), util.joaat("freightcont2"), util.joaat("freightgrain"), util.joaat("tankercar")}
    for _, model in ipairs(trainmodels) do
        request_model(model)
    end
    local train = VEHICLE.CREATE_MISSION_TRAIN(variation, pos.x, pos.y, pos.z, 0)
    local posTrain = ENTITY.GET_ENTITY_COORDS(train)
    local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netid)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, false)
    util.toast(string.format("火车生成于 (%.1f, %.1f, %.1f)", posTrain.x, posTrain.y, posTrain.z))
end









----冻结选项
frozen_vehicles = {}
function update_frozen_vehicles()
    for _, frozen_vehicle in pairs(frozen_vehicles) do
        if ENTITY.DOES_ENTITY_EXIST(frozen_vehicle.vehicle) then
            ENTITY.FREEZE_ENTITY_POSITION(frozen_vehicle.vehicle, true)
        end
    end
end
function refresh_frozen_vehicles_menu_list()
    menu.delete(frozen_vehicles_menu_list)
    frozen_vehicles_menu_list = menu.list(vf, "已冻结的载具")
    for index, frozen_vehicle in pairs(frozen_vehicles) do
        menu.action(frozen_vehicles_menu_list, frozen_vehicle.name, {"unfreeze"..index}, "点击解冻载具", function()
            table.remove(frozen_vehicles, index)
            ENTITY.FREEZE_ENTITY_POSITION(frozen_vehicle.vehicle, false)
            refresh_frozen_vehicles_menu_list()
        end)
    end
end
function add_frozen_vehicle(vehicle)
    for index, frozen_vehicle in pairs(frozen_vehicles) do
        if frozen_vehicle.vehicle == vehicle then
            return
        end
    end
    local model = ENTITY.GET_ENTITY_MODEL(vehicle)
    local name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
    table.insert(frozen_vehicles, {name=name,vehicle=vehicle})
    refresh_frozen_vehicles_menu_list()
    update_frozen_vehicles()
end




--保存配置
function save_config()
    local dir = filesystem.scripts_dir() .. "lib/daidailib/Config/Config.lua"
    notification("~y~~bold~配置已保存", HudColour.blue)
    local config_txt = 
        "--[Lua配置]"..
        "\nconfig_active1 = "..menu.get_value(host_sequence)..         ------------主机序列
            "\nconfig_active1_x = "..menu.get_value(host_sequence_x)..       ------------主机序列x坐标
            "\nconfig_active1_y = "..menu.get_value(host_sequence_y)..       ------------主机序列y坐标
        "\nconfig_active2 = "..menu.get_value(show_time)..             ------------显示时间
        "\nconfig_active3 = "..menu.get_value(script_name)..           ------------显示脚本名称
        "\nconfig_active4 = "..menu.get_value(numfps)..                -----------显示fps
        "\nconfig_active5 = "..menu.get_value(show_entityinfo)..       -----------实体池信息
        "\nconfig_active6 = "..menu.get_value(players_info)..          -----------绘制玩家信息
            "\nconfig_active6_x = "..menu.get_value(infoverlay_x)..          -----------玩家信息x坐标
            "\nconfig_active6_y = "..menu.get_value(infoverlay_y)..          -----------玩家信息y坐标
        "\nconfig_active7 = "..menu.get_value(auto_kick_adBot)..       -----------自动踢出广告机
        "\nconfig_active8 = "..menu.get_value(players_bar)             -----------玩家栏
    local file = io.open(dir, 'w')
    file:write(config_txt)
    file:close()
end


----循环清理实体
function loop_clear_entity()
    for i, entity in pairs(entities.get_all_vehicles_as_handles()) do
        request_control(entity)
        entities.delete(entity) 
    end
    for i, entity in pairs(entities.get_all_peds_as_handles()) do
        request_control(entity)
        entities.delete(entity) 
    end
    for i, entity in pairs(entities.get_all_objects_as_handles()) do
        request_control(entity)
        entities.delete(entity) 
    end
end


----世界重力
function request_control_of_table_once(tbl)
    for index, entity in ipairs(tbl) do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    end
end
function World_gravity(option_index)
    gravity_current_index = option_index
    if option_index ~= 1 then
        while gravity_current_index == option_index do
            request_control_of_table_once(entities.get_all_vehicles_as_handles())
            request_control_of_table_once(entities.get_all_objects_as_handles())
            request_control_of_table_once(entities.get_all_peds_as_handles())
            request_control_of_table_once(entities.get_all_pickups_as_handles())
            MISC.SET_GRAVITY_LEVEL(option_index - 1)
            util.yield()
        end
    else
        MISC.SET_GRAVITY_LEVEL(option_index - 1)
    end
end



----自动翻转
function vehicle_automatically()
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
    local rotation = CAM.GET_GAMEPLAY_CAM_ROT(2)
    local heading = v3.getHeading(v3.new(rotation))
    local vehicle_distance_to_ground = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(player_vehicle)
    local am_i_on_ground = vehicle_distance_to_ground < 2 --and true or false
    local speed = ENTITY.GET_ENTITY_SPEED(player_vehicle)
    if not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(player_vehicle) and ENTITY.IS_ENTITY_UPSIDEDOWN(player_vehicle) and am_i_on_ground then
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(player_vehicle, 5.0)
        ENTITY.SET_ENTITY_HEADING(player_vehicle, heading)
        util.yield()
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(player_vehicle, speed)
    end
end



----保护球
local bigasscircle = util.joaat("ar_prop_ar_neon_gate4x_04a")
function Protect_ball(on)
    if on then
        STREAMING.REQUEST_MODEL(bigasscircle)
        while not STREAMING.HAS_MODEL_LOADED(bigasscircle) do
            STREAMING.REQUEST_MODEL(bigasscircle)
            util.yield()
        end
        c1 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c2 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c3 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c4 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c5 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c6 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c7 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c8 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c9 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c10 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c11 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c12 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c13 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c14 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c15 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c16 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c17 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c18 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        c19 = entities.create_object(bigasscircle, v3(-75.14637, -818.67236, 326.1751))
        ENTITY.FREEZE_ENTITY_POSITION(c1, true)
        ENTITY.FREEZE_ENTITY_POSITION(c2, true)
        ENTITY.FREEZE_ENTITY_POSITION(c3, true)
        ENTITY.FREEZE_ENTITY_POSITION(c4, true)
        ENTITY.FREEZE_ENTITY_POSITION(c5, true)
        ENTITY.FREEZE_ENTITY_POSITION(c6, true)
        ENTITY.FREEZE_ENTITY_POSITION(c7, true)
        ENTITY.FREEZE_ENTITY_POSITION(c8, true)
        ENTITY.FREEZE_ENTITY_POSITION(c9, true)
        ENTITY.FREEZE_ENTITY_POSITION(c10, true)
        ENTITY.FREEZE_ENTITY_POSITION(c11, true)
        ENTITY.FREEZE_ENTITY_POSITION(c12, true)
        ENTITY.FREEZE_ENTITY_POSITION(c13, true)
        ENTITY.FREEZE_ENTITY_POSITION(c14, true)
        ENTITY.FREEZE_ENTITY_POSITION(c15, true)
        ENTITY.FREEZE_ENTITY_POSITION(c16, true)
        ENTITY.FREEZE_ENTITY_POSITION(c17, true)
        ENTITY.FREEZE_ENTITY_POSITION(c18, true)
        ENTITY.FREEZE_ENTITY_POSITION(c19, true)
        ENTITY.SET_ENTITY_ROTATION(c2, 0.0, 0.0, 10.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c3, 0.0, 0.0, 20.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c4, 0.0, 0.0, 30.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c5, 0.0, 0.0, 40.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c6, 0.0, 0.0, 50.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c7, 0.0, 0.0, 60.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c8, 0.0, 0.0, 70.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c9, 0.0, 0.0, 80.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c10, 0.0, 0.0, 90.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c11, 0.0, 0.0, 100.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c12, 0.0, 0.0, 110.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c13, 0.0, 0.0, 120.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c14, 0.0, 0.0, 130.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c15, 0.0, 0.0, 140.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c16, 0.0, 0.0, 150.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c18, 0.0, 0.0, 160.0, 1, true)
        ENTITY.SET_ENTITY_ROTATION(c19, 0.0, 0.0, 170.0, 1, true)
        ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), -75.14637, -818.67236, 326.1751)
    else
        entities.delete(c1)
        entities.delete(c2)
        entities.delete(c3)
        entities.delete(c4)
        entities.delete(c5)
        entities.delete(c6)
        entities.delete(c7)
        entities.delete(c8)
        entities.delete(c9)
        entities.delete(c10)
        entities.delete(c11)
        entities.delete(c12)
        entities.delete(c13)
        entities.delete(c14)
        entities.delete(c15)
        entities.delete(c16)
        entities.delete(c17)
        entities.delete(c18)
        entities.delete(c19)     
    end
end



--射击效果
ShootEffect ={scale = 0,rotation = nil}
ShootEffect.__index = ShootEffect
setmetatable(ShootEffect, Effect)
function ShootEffect_new(asset, name, scale, rotation)
	tbl = setmetatable({}, ShootEffect)
	tbl.name = name
	tbl.asset = asset
	tbl.scale = scale or 1.0
	tbl.rotation = rotation or v3.new()
	return tbl
end
shootingEffects = {
	ShootEffect_new("scr_rcbarry2", "muz_clown", 0.8, v3.new(90, 0.0, 0.0)),
	ShootEffect_new("scr_rcbarry2", "scr_clown_bul", 0.3, v3.new(180.0, 0.0, 0.0))
}
local selectedshootOpt = 1
function Shoot_effect_option(index)
    selectedshootOpt = index
end
function Shoot_effect()
    local effect = shootingEffects[selectedshootOpt]
	if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
		GRAPHICS1.REQUEST_NAMED_PTFX_ASSET(effect.asset)

	elseif PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(PLAYER.PLAYER_PED_ID(), 0)
		local boneId = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(weapon, "gun_muzzle")
		GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
		GRAPHICS.START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
			effect.name,
			weapon,
			0.0, 0.0, 0.0,
			effect.rotation.x, effect.rotation.y, effect.rotation.z,
			boneId,
			effect.scale,
			false, false, false
		)
	end
end



--命中效果
local HitEffect = {colorCanChange = false}
HitEffect.__index = HitEffect
setmetatable(HitEffect, Effect)
function HitEffect.new(asset, name, colorCanChange)
	local inst = setmetatable({}, HitEffect)
	inst.name = name
	inst.asset = asset
	inst.colorCanChange = colorCanChange or false
	return inst
end
hitEffects = {
	HitEffect.new("scr_rcbarry2", "scr_exp_clown"),
	HitEffect.new("scr_rcbarry2", "scr_clown_appears"),
	HitEffect.new("scr_rcpaparazzo1", "scr_mich4_firework_trailburst_spawn", true),
	HitEffect.new("scr_indep_fireworks", "scr_indep_firework_starburst", true),
	HitEffect.new("scr_indep_fireworks", "scr_indep_firework_fountain", true),
	HitEffect.new("scr_rcbarry1", "scr_alien_disintegrate"),
	HitEffect.new("scr_rcbarry2", "scr_clown_bul"),
	HitEffect.new("proj_indep_firework", "scr_indep_firework_grd_burst"),
	HitEffect.new("scr_rcbarry2", "muz_clown"),
}
local selectedhitOpt = 1
function set_effectColour(colour)
    hiteffectColour = colour
end
function hit_effect_option(opt)
    selectedhitOpt = opt
end
function Hit_effect()
    local effect = hitEffects[selectedhitOpt]
    if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
        return STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
    end
    local hitCoords = v3.new()
    if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), hitCoords) then
        local raycastResult = get_raycast_result(1000.0)
        local rot = raycastResult.surfaceNormal:toRot()
        GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
        if effect.colorCanChange then
            GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(hiteffectColour.r, hiteffectColour.g, hiteffectColour.b)
        end
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
            effect.name,
            hitCoords.x, hitCoords.y, hitCoords.z,
            rot.x - 90.0, rot.y, rot.z,
            1.0, 
            false, false, false, false
        )
    end
end




------防笼子
function Cage_proof()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
    for _, hash in ipairs(cageModels) do
        local obj = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(pos.x, pos.y, pos.z, 8.0, hash, false, false, false)
        if obj ~= 0 and ENTITY.DOES_ENTITY_EXIST(obj) then
            local ownerId = get_entity_owner(obj)
            util.toast("笼子模型来自 ".. PLAYER.GET_PLAYER_NAME(ownerID))
            request_control(obj)
            entities.delete(obj)
        end
    end
end


----崩溃function
function CreateVehicle(Hash, Pos, Heading, Invincible)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_vehicle(Hash, Pos, Heading)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    if Invincible then
        ENTITY.SET_ENTITY_INVINCIBLE(SpawnedVehicle, true)
    end
    return SpawnedVehicle
end
function CreatePed(index, Hash, Pos, Heading)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_ped(index, Hash, Pos, Heading)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    return SpawnedVehicle
end
function CreateObject(Hash, Pos, static)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_object(Hash, Pos)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    if static then
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicle, true)
    end
    return SpawnedVehicle
end


----道具草崩溃
function prop_grass(pid)
    for i = 1, 30 do
        local ped = PLAYER.GET_PLAYER_PED(pid)
        if ped ~= 0 then
            local hash = util.joaat("prop_tall_grass_ba")
            local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
            local obj = create_object(hash, pos.x, pos.y, pos.z)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(obj, pos.x, pos.y, pos.z, false, true, true)
            util.yield(500)
            entities.delete(obj)
        end
    end
end

----PED崩溃
function PED_crash(pid)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), 0, 3, 0)
    local ped = create_ped(26,util.joaat("a_c_rat"),pos.x, pos.y, pos.z, 0)
    local plane = create_vehicle(0x9c5e5644, pos.x, pos.y, pos.z, 0)
    PED.SET_PED_INTO_VEHICLE(ped, plane, -1)
    ENTITY.FREEZE_ENTITY_POSITION(plane,true)
    TASK.TASK_OPEN_VEHICLE_DOOR(ped, plane, 9999, -1, 2)
    TASK.TASK_LEAVE_VEHICLE(ped, plane, 0)
    util.yield(50)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 0, 1, true, false, 0, false)
    entities.delete(ped)
end

----无效绳索崩溃
function Invalid_rope(pid)
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED(pid)
    local Pos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local cargobob = create_vehicle(0XFCFCB68B, Pos.x, Pos.y, Pos.z, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
    local cargobobPos = ENTITY.GET_ENTITY_COORDS(cargobob, true)
    local vehicle = create_vehicle(0X187D938D, Pos.x, Pos.y, Pos.z, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
    local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
    local newRope = PHYSICS.ADD_ROPE(Pos.x, Pos.y, Pos.z, 0, 0, 10, 1, 1, 0, 1, 1, false, false, false, 1.0, false, 0)
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, cargobob, vehicle, cargobobPos.x, cargobobPos.y, cargobobPos.z, vehiclePos.x, vehiclePos.y, vehiclePos.z, 2, false, false, 0, 0, "Center", "Center")
end

----新鬼崩
function new_guibeng(pid)
    local model_array = {util.joaat("boattrailer"),util.joaat("trailersmall"),util.joaat("raketrailer"),}
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
    local fuck_ped = CreatePed(26 , util.joaat("ig_kaylee"), pos, 0)
    ENTITY.SET_ENTITY_VISIBLE(fuck_ped, false)
    for i = 1, 3, 1 do
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(fuck_ped, pos.x, pos.y, pos.z)
        for spawn, value in pairs(model_array) do
            local vels = {}
            vels[spawn] = CreateVehicle(value, pos, 0)
            for attach, value in pairs(vels) do
                ENTITY.ATTACH_ENTITY_BONE_TO_ENTITY_BONE_Y_FORWARD(value, fuck_ped, 0, 0, true, true)
            end
        end
        util.yield(100)
        FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 4, 100, true, false, 1, false)
    end
end

----大自然全局崩溃
function nature()
    local user = PLAYER.PLAYER_ID()
    local user_ped = PLAYER.PLAYER_PED_ID()
    local model = util.joaat("h4_prop_bush_mang_ad") -- special op object so you dont have to be near them :D
        util.yield(100)
        ENTITY.SET_ENTITY_VISIBLE(user_ped, false)
        for i = 0, 110 do
            PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user, model)
            PED.SET_PED_COMPONENT_VARIATION(user_ped, 5, i, 0, 0)
            util.yield(25)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
        end
        for i = 1, 5 do
            util.spoof_script("freemode", SYSTEM.WAIT) -- preventing wasted screen
        end
        ENTITY.SET_ENTITY_HEALTH(user_ped, 0, 0) -- killing ped because it will still crash others until you die (clearing tasks doesnt seem to do much)
        local pos = players.get_position(user)
        NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos.x, pos.y, pos.z, 0, false, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(user_ped, true)
end

-----全局顶崩
function unknown()
    for pid = 0, 32 do
        local spped = PLAYER.PLAYER_PED_ID()
        local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(spped, true)
        local TTPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local TTPos = ENTITY.GET_ENTITY_COORDS(TTPed, true)
        SelfPlayerPos.x = SelfPlayerPos.x + 10
        TTPos.x = TTPos.x + 10
        local carc = CreateObject(util.joaat("apa_prop_flag_china"), TTPos, ENTITY.GET_ENTITY_HEADING(spped), true)
        local carcPos = ENTITY.GET_ENTITY_COORDS(carc, true)
        local pedc = CreatePed(26, util.joaat("A_C_HEN"), TTPos, 0)
        local pedcPos = ENTITY.GET_ENTITY_COORDS(carc, true)
        local ropec = PHYSICS.ADD_ROPE(TTPos.x, TTPos.y, TTPos.z, 0, 0, 0, 1, 1, 0.00300000000000000000000000000000000000000000000001, 1, 1, true, true, true, 1.0, true, 0)
        PHYSICS.ATTACH_ENTITIES_TO_ROPE(ropec,carc,pedc,carcPos.x, carcPos.y, carcPos.z ,pedcPos.x, pedcPos.y, pedcPos.z,2, false, false, 0, 0, "Center","Center")
        util.yield(3500)
        PHYSICS.DELETE_CHILD_ROPE(ropec)
        entities.delete(pedc)
    end
end


----火人
local looped_ptfxs = {}
local trail_bones = {0xffa, 0xfa11, 0x83c, 0x512d, 0x796e, 0xb3fe, 0x3fcf, 0x58b7, 0xbb0}
function fireself(on)
    if on then 
        request_ptfx_asset("core")
        for _, bone in pairs(trail_bones) do
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            local bone_id = PED.GET_PED_BONE_INDEX(PLAYER.PLAYER_PED_ID(), bone)
            local fx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("fire_wrecked_plane_cockpit", PLAYER.PLAYER_PED_ID(), 0.0, 0.0, 0.0, 0.0, 0.0, 90.0, bone_id, 0.5, false, false, false, 0, 0, 0, 0)
            looped_ptfxs[#looped_ptfxs+1] = fx
            GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, 100, 100, 100, 0)
        end
    else
        for _, p in pairs(looped_ptfxs) do
            GRAPHICS.REMOVE_PARTICLE_FX(p, false)
            GRAPHICS.STOP_PARTICLE_FX_LOOPED(p, false)
        end
    end
end

---MK-2拦截
function get_player_vehicle_in_control(pid, opts)
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos1 = ENTITY.GET_ENTITY_COORDS(target_ped)
    local pos2 = ENTITY.GET_ENTITY_COORDS(my_ped)
    local dist = SYSTEM.VDIST2(pos1.x, pos1.y, 0, pos2.x, pos2.y, 0)
    local was_spectating = NETWORK.NETWORK_IS_IN_SPECTATOR_MODE()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, true)
    if opts and opts.near_only and vehicle == 0 then
        return 0
    end
    if vehicle == 0 and target_ped ~= my_ped and dist > 1500 and not was_spectating then
        show_busyspinner("AUTO_SPECTATE")
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, target_ped)
        local loop = (opts and opts.loops ~= nil) and opts.loops or 30
        while vehicle == 0 and loop > 0 do
            util.yield(100)
            vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, true)
            loop = loop - 1
        end
        HUD.BUSYSPINNER_OFF()
    end
    if vehicle > 0 then
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
            return vehicle
        end
        local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(vehicle)
        local has_control_ent = false
        local loops = 15
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)
        while not has_control_ent do
            has_control_ent = NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            loops = loops - 1
            util.yield(15)
            if loops <= 0 then
                break
            end
        end
    end
    if not was_spectating then
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(false, target_ped)
    end
    return vehicle
end
function control_vehicle(pid, callback, opts)
    local vehicle = get_player_vehicle_in_control(pid, opts)
    if vehicle > 0 then
        callback(vehicle)
    elseif opts == nil or opts.silent ~= true then
        _lang.toast("PLAYER_OUT_OF_RANGE")
    end
end
function notify(msg)
    util.toast(msg)
end
function ExplodeThem(pos)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 0, 1.0, false, true, 0.0, false)
end
function is_player_friend(pId)
    local pHandle = memory.alloc(104)
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(pId, pHandle, 13)
    local isFriend = NETWORK.NETWORK_IS_HANDLE_VALID(pHandle, 13) and NETWORK.NETWORK_IS_FRIEND(pHandle)
    return isFriend
end
function oppKarma()
    while oppressorKarma do
        for i, pid in pairs(players.list(true, true, true)) do
            if not oppressorFriendKarma and is_player_friend(pid) then
                pid = pid+1
            elseif not oppressorYourselfKarma and pid == PLAYER.PLAYER_ID() then
                pid = pid+1
            end
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            if PED.IS_PED_IN_MODEL(target_ped, 2069146067) then
                if selectedKarmaMK2 == "[Remove]" or selectedKarmaMK2 == nil then
                    control_vehicle(pid, function(vehicle)
                        entities.delete(vehicle)
                        util.yield(100)
                    end)
                elseif selectedKarmaMK2 == "[Kill]" then
                    ExplodeThem(ENTITY.GET_ENTITY_COORDS(target_ped))
                elseif selectedKarmaMK2 == "[Remove + Kill]" then
                    control_vehicle(pid, function(vehicle)
                        entities.delete(vehicle)
                    end)
                    util.yield(100)
                    ExplodeThem(ENTITY.GET_ENTITY_COORDS(target_ped))
                end
                notify("检测到马克兔 "..players.get_name(pid).." 报应启用")
            end
            util.yield(10)
        end
        util.yield(2000)
    end
end

----过渡传送
function transit_tp()
    if not HUD.IS_WAYPOINT_ACTIVE() then
        util.toast("请先在地图上标点")
        return
    end
    local waypoint = HUD.GET_BLIP_INFO_ID_COORD(HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID()))
    local vehicle = PED.GET_VEHICLE_PED_IS_USING(PLAYER.PLAYER_PED_ID())
    local ground = false
    repeat
        ground, waypoint.z = util.get_ground_z(waypoint.x, waypoint.y)
        util.yield()
    until ground
    if vehicle != 0 then
        ENTITY.SET_ENTITY_VISIBLE(vehicle, false)
    end
    STREAMING.SWITCH_TO_MULTI_FIRSTPART(PLAYER.PLAYER_PED_ID(), 8, 1)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("PM_WAIT")
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(4)
    repeat
        util.yield()
    until STREAMING.IS_SWITCH_TO_MULTI_FIRSTPART_FINISHED()
    if vehicle == 0 then
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), waypoint.x, waypoint.y, waypoint.z, false, false, false)
    else
        ENTITY.SET_ENTITY_VISIBLE(vehicle, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(vehicle, waypoint.x, waypoint.y, waypoint.z, false, false, false)
    end
    STREAMING.SWITCH_TO_MULTI_SECONDPART(PLAYER.PLAYER_PED_ID())
    STREAMING.ALLOW_PLAYER_SWITCH_OUTRO() 
    repeat
        util.yield()
    until not STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()
    if vehicle == 0 then
        NETWORK.NETWORK_FADE_IN_ENTITY(PLAYER.PLAYER_PED_ID(), true, true)
    else
        NETWORK.NETWORK_FADE_IN_ENTITY(vehicle, true, true)
        NETWORK.NETWORK_FADE_IN_ENTITY(PLAYER.PLAYER_PED_ID(), true, true)
        ENTITY.SET_ENTITY_VISIBLE(vehicle, true)
    end
    HUD.BUSYSPINNER_OFF()
end


----随机位置
function random_position()
    local pos = {x = math.random(-1794,2940), y = math.random(-3026,6298), z = math.random(0,800)}
    local x, y, z= waypoint_coord(pos)
    ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), x, y, z, false, false, false, false)
end

-----跳过下水道切割
function IS_HELP_MSG_DISPLAYED(label) -- Credit goes to jerry123#4508
    HUD.BEGIN_TEXT_COMMAND_IS_THIS_HELP_MESSAGE_BEING_DISPLAYED(label)
    return HUD.END_TEXT_COMMAND_IS_THIS_HELP_MESSAGE_BEING_DISPLAYED(0)
end
-----删除排水管
function DELETE_OBJECT_BY_HASH(hash)
    for _, ent in pairs(entities.get_all_objects_as_handles()) do
        if ENTITY.GET_ENTITY_MODEL(ent) == hash then
            entities.delete(ent)
        end
    end
end

function BlockSyncs(pid, callback)
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "on")
        end
    end
    util.yield(10)
    callback()
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "off")
        end
    end
end
function RqModel (hash)
    STREAMING.REQUEST_MODEL(hash)
    local count = 0
    util.toast("正在请求模型...")
    while not STREAMING.HAS_MODEL_LOADED(hash) and count < 100 do
        STREAMING.REQUEST_MODEL(hash)
        count = count + 1
        util.yield(10)
    end
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        util.toast("已尝试1秒,无法加载此指定模型!")
    end
end

--aio崩溃
local getEntityCoords = ENTITY.GET_ENTITY_COORDS
local getPlayerPed = PLAYER.GET_PLAYER_PED
function aaaio(pid)
    if players.exists(pid) then
        local user = PLAYER.PLAYER_ID()
        local user_ped = PLAYER.PLAYER_PED_ID()
        local pos = players.get_position(user)
            BlockSyncs(pid, function() 
                util.yield(100)
                PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), 0xFBF7D21F)
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
                TASK.TASK_PARACHUTE_TO_TARGET(user_ped, pos.x, pos.y, pos.z)
                util.yield()
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
                util.yield(250)
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
                PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
                util.yield(1000)
                for i = 1, 5 do
                    util.spoof_script("freemode", SYSTEM.WAIT)
                end
                ENTITY.SET_ENTITY_HEALTH(user_ped, 0, 0)
                NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos.x,pos.y,pos.z, 0, false, false, 0)
            end)
    end
    if players.exists(pid) then
        local time = util.current_time_millis() + 2000
            while time > util.current_time_millis() do
                local pos=ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
                for i = 1, 10 do
                    AUDIO.PLAY_SOUND_FROM_COORD(-1,"10s",pos.x,pos.y,pos.z,"MP_MISSION_COUNTDOWN_SOUNDSET",true, 70, false)
                end
                util.yield(0)
            end
    end 
    if players.exists(pid) then
        local time = util.current_time_millis() + 2000
            while time > util.current_time_millis() do
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
                for i = 1, 20 do
                    AUDIO.PLAY_SOUND_FROM_COORD(-1, 'Event_Message_Purple', pos.x, pos.y, pos.z, 'GTAO_FM_Events_Soundset', true, 1000, false)
                    AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', pos.x, pos.y, pos.z, 'GTAO_FM_Events_Soundset', true, 1000, false)
                end
                util.yield()
            end	
    end
    if players.exists(pid) then
        local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(TPP, true)
        pos.z = pos.z + 10
        veh = entities.get_all_vehicles_as_handles()
        
        for i = 1, #veh do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh[i])
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh[i], pos.x,pos.y,pos.z, ENTITY.GET_ENTITY_HEADING(TPP), 10)
            TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 18, 999)
            TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 16, 999)
        end
    end
    if players.exists(pid) then
        local hashes = {1492612435, 3517794615, 3889340782, 3253274834}
        local vehicles = {}
        for i = 1, 4 do
            util.create_thread(function()
                RqModel(hashes[i])
                local pcoords = getEntityCoords(getPlayerPed(pid))
                local veh =  VEHICLE.CREATE_VEHICLE(hashes[i], pcoords.x, pcoords.y, pcoords.z, math.random(0, 360), true, true, false)
                for a = 1, 20 do NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh) end
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                for j = 0, 49 do
                    local mod = VEHICLE.GET_NUM_VEHICLE_MODS(veh, j) - 1
                    VEHICLE.SET_VEHICLE_MOD(veh, j, mod, true)
                    VEHICLE.TOGGLE_VEHICLE_MOD(veh, mod, true)
                end
                for j = 0, 20 do
                    if VEHICLE.DOES_EXTRA_EXIST(veh, j) then VEHICLE.SET_VEHICLE_EXTRA(veh, j, true) end
                end
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
                VEHICLE.SET_VEHICLE_WINDOW_TINT(veh, 1)
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(veh, 1)
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, " ")
                for ai = 1, 50 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    pcoords = getEntityCoords(getPlayerPed(pid))
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pcoords.x, pcoords.y, pcoords.z, false, false, false)
                    util.yield()
                end
                vehicles[#vehicles+1] = veh
            end)
        end
    end
    if players.exists(pid) then	
            for pedp_crash = 2 , 6 do
        pedp = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        pos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        dune = CreateVehicle(410882957,pos,ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(dune, true)
        dune1 = CreateVehicle(2971866336,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(dune1, true)
        barracks = CreateVehicle(3602674979,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(barracks, true)
        barracks1 = CreateVehicle(444583674,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(barracks1, true)
        dunecar = CreateVehicle(2971866336,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(dunecar, true)
        dunecar1 = CreateVehicle(3602674979,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(dunecar1, true)
        dunecar2 = CreateVehicle(444583674,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(dunecar2, true)
        barracks3 = CreateVehicle(4244420235,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(barracks3, true)
        barracks31 = CreateVehicle(3602674979,pos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(barracks31, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(barracks3, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(barracks31, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(barracks, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(barracks1, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(dune, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(dune1, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(dunecar1, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(dunecar2, dunecar, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(dunecar, pedp, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
        util.yield(5000)
        for i = 0, 100  do
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(dunecar, pos.x, pos.y, pos.z, false, true, true)
                util.yield(10)
            end
            util.yield(2000)
            entities.delete(dune)
            entities.delete(dune1)
            entities.delete(barracks)
            entities.delete(barracks1)
            entities.delete(dunecar)
            entities.delete(dunecar1)
            entities.delete(dunecar2)
            entities.delete(barracks3)
            entities.delete(barracks31)
        end
    end
end

--大自然崩溃
function naturecrashv1(pid)
    local user = PLAYER.PLAYER_ID()
    local user_ped = PLAYER.PLAYER_PED_ID()
    local pos = players.get_position(user)
    BlockSyncs(pid, function()
        util.yield(100)
        menu.trigger_commands("invisibility on")
            for i = 0, 110 do
                PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user, 0xFBF7D21F)
                PED.SET_PED_COMPONENT_VARIATION(user_ped, 5, i, 0, 0)
                util.yield(50)
                PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
            end
        util.yield(250)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT)
            end
        ENTITY.SET_ENTITY_HEALTH(user_ped, 0, 0)
        NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos.x, pos.y, pos.z, 0, false, false, 0)
        PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
        menu.trigger_commands("invisibility off")
    end)
end
--OX崩溃
function OXcrashgg(pid)
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local PED1 = CreatePed(26,util.joaat("cs_beverly"),TargetPlayerPos, 0)
    ENTITY.SET_ENTITY_VISIBLE(PED1, false, 0)
    util.yield(100)
        WEAPON.GIVE_WEAPON_TO_PED(PED1,-270015777,80,true,true)
    util.yield(1000)
        FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, 2, 50, true, false, 0.0) 
    util.yield(10000)
        entities.delete(PED1)
        if players.exists(pid) then
            util.toast("未能移除玩家,正在使用cs_fabien模型")
            local PED2 = CreatePed(26,util.joaat("cs_fabien"),TargetPlayerPos, 0)
            ENTITY.SET_ENTITY_VISIBLE(PED2, false, 0)
                util.yield(100)
            WEAPON.GIVE_WEAPON_TO_PED(PED2,-270015777,80,true,true)
                util.yield(1000)
            FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, 2, 50, true, false, 0.0)
                util.yield(5000)
            entities.delete(PED2)
        end
    if players.exists(pid) then
        util.toast("未能移除玩家,正在使用cs_manuel模型")
        local PED3 = CreatePed(26,util.joaat("cs_manuel"),TargetPlayerPos, 0)
        ENTITY.SET_ENTITY_VISIBLE(PED3, false, 0)
            util.yield(100)
        WEAPON.GIVE_WEAPON_TO_PED(PED3,-270015777,80,true,true)
            util.yield(1000)
        FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, 2, 50, true, false, 0.0)
            util.yield(5000)
        entities.delete(PED3)
    end
    if players.exists(pid) then
        util.toast("未能移除玩家,正在使用cs_taostranslator模型")
        local PED4 = CreatePed(26,util.joaat("cs_taostranslator"),TargetPlayerPos, 0)
        ENTITY.SET_ENTITY_VISIBLE(PED4, false, 0)
            util.yield(100)
        WEAPON.GIVE_WEAPON_TO_PED(PED4,-270015777,80,true,true)
            util.yield(1000)
        FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, 2, 50, true, false, 0.0)
            util.yield(5000)
        entities.delete(PED4)
    end
    if players.exists(pid) then
        util.toast("未能移除玩家,正在使用cs_taostranslator2模型")
        local PED5 = CreatePed(26,util.joaat("cs_taostranslator2"),TargetPlayerPos, 0)
        ENTITY.SET_ENTITY_VISIBLE(PED5, false, 0)
            util.yield(100)
        WEAPON.GIVE_WEAPON_TO_PED(PED5,-270015777,80,true,true)
            util.yield(1000)
        FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, 2, 50, true, false, 0.0)
            util.yield(5000)
        entities.delete(PED5)
    end
    if players.exists(pid) then
        util.toast("未能移除玩家,正在使用cs_tenniscoach模型")
        local PED6 = CreatePed(26,util.joaat("cs_tenniscoach"),TargetPlayerPos, 0)
        ENTITY.SET_ENTITY_VISIBLE(PED6, false, 0)
            util.yield(100)
        WEAPON.GIVE_WEAPON_TO_PED(PED6,-270015777,80,true,true)
            util.yield(1000)
        FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, 2, 50, true, false, 0.0)
            util.yield(5000)
        entities.delete(PED6)
    end
    if players.exists(pid) then
        util.toast("未能移除玩家,正在使用cs_wade模型")
        local PED7 = CreatePed(26,util.joaat("cs_wade"),TargetPlayerPos, 0)
        ENTITY.SET_ENTITY_VISIBLE(PED7, false, 0)
            util.yield(100)
        WEAPON.GIVE_WEAPON_TO_PED(PED7,-270015777,80,true,true)
            util.yield(1000)
        FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, 2, 50, true, false, 0.0)
            util.yield(5000)
        entities.delete(PED7)
    end
    util.yield(2000)
    if not players.exists(pid) then
        util.toast("成功移除玩家")
    end
end
----北域崩溃
function Northern_crash(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    local michael = util.joaat("player_zero")
    request_model(michael)
    local ped = entities.create_ped(0, michael, pos, 0)
    PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 6, 0)
    PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 5, 0)
    util.yield()
    ENTITY.SET_ENTITY_COORDS(ped, pos.x, pos.y, pos.z, true, false, false, true)
    util.yield(500)
    entities.delete(ped)
end
----回弹崩溃
function Rebound_crash(pid)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = players.get_position(pid)
    local mdl = util.joaat("mp_m_freemode_01")
    local veh_mdl = util.joaat("taxi")
    request_model(veh_mdl)
    request_model(mdl)
        for i = 1, 10 do
            local veh = entities.create_vehicle(veh_mdl, pos, 0)
            local jesus = entities.create_ped(2, mdl, pos, 0)
            PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
            util.yield(100)
            TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
            util.yield(1000)
            entities.delete(jesus)
            entities.delete(veh)
        end  
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
end
----黄昏崩溃
function nightfull_crash(pid)
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local mdl = util.joaat("cs_taostranslator2")
    while not STREAMING.HAS_MODEL_LOADED(mdl) do
        STREAMING.REQUEST_MODEL(mdl)
        util.yield(5)
    end
    local ped = {}
    for i = 1, 10 do 
        local coord = ENTITY.GET_ENTITY_COORDS(player, true)
        local pedcoord = ENTITY.GET_ENTITY_COORDS(ped[i], false)
        ped[i] = entities.create_ped(0, mdl, coord, 0)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped[i], 0xB1CA77B1, 0, true)
        WEAPON.SET_PED_GADGET(ped[i], 0xB1CA77B1, true)
        ENTITY.SET_ENTITY_VISIBLE(ped[i], true)
        util.yield(25)
    end
    util.yield(2500)
    for i = 1, 10 do
        entities.delete(ped[i])
        util.yield(25)
    end
end
----Inshallah crash
function Inshallah_crash(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    local PED1  = CreatePed(28,-1011537562,pos,0)
    local PED2  = CreatePed(28,-541762431,pos,0)
    WEAPON.GIVE_WEAPON_TO_PED(PED1,-1813897027,1,true,true)
    WEAPON.GIVE_WEAPON_TO_PED(PED2,-1813897027,1,true,true)
    util.yield(1000)
    TASK.TASK_THROW_PROJECTILE(PED1,pos.x,pos.y,pos.z,0,0)
    TASK.TASK_THROW_PROJECTILE(PED2,pos.x,pos.y,pos.z,0,0)
end
--碎片崩溃
function v1_frag(pid)
    BlockSyncs(pid, function()
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        entities.delete(object)
        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)))
        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
        util.yield(1000)
        entities.delete(object)
    end)
end
----悲伤的耶稣崩溃
function Jesus_crash(pid)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = players.get_position(pid)
    local mdl = util.joaat("u_m_m_jesus_01")
    local veh_mdl = util.joaat("oppressor")
    util.request_model(veh_mdl)
    util.request_model(mdl)
        for i = 1, 10 do
            if not players.exists(pid) then
                return
            end
            local veh = entities.create_vehicle(veh_mdl, pos, 0)
            local jesus = entities.create_ped(2, mdl, pos, 0)
            PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
            util.yield(100)
            TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
            util.yield(1000)
            entities.delete(jesus)
            entities.delete(veh)
        end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
end
--Memoir超级崩溃/v3
function Memoir(pid)
    PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),0xE5022D03)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID()))
        util.yield(20)
    local p_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID()),p_pos.x,p_pos.y,p_pos.z,false,true,true)
    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID()), 0xFBAB5776, 1000, false)
    TASK.TASK_PARACHUTE_TO_TARGET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID()),-1087,-3012,13.94)
        util.yield(500)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID()))
        util.yield(1000)
    PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID())
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID()))
end
---鬼崩
function guibeng(pid)
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
    local Spawned_tr3 = CreateVehicle(util.joaat("tr3"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()), true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_tr3, PLAYER.PLAYER_PED_ID(), 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
    ENTITY.SET_ENTITY_VISIBLE(Spawned_tr3, false, 0)
    local Spawned_chernobog = CreateVehicle(util.joaat("chernobog"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()), true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_chernobog, PLAYER.PLAYER_PED_ID(), 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
    ENTITY.SET_ENTITY_VISIBLE(Spawned_chernobog, false, 0)
    local Spawned_avenger = CreateVehicle(util.joaat("avenger"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()), true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_avenger, PLAYER.PLAYER_PED_ID(), 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0, true, 0)
    ENTITY.SET_ENTITY_VISIBLE(Spawned_avenger, false, 0)
    for i = 0, 100 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, true, false, false)
        util.yield(10 * math.random())
        ENTITY.SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), SelfPlayerPos.x, SelfPlayerPos.y, SelfPlayerPos.z, true, false, false)
        util.yield(10 * math.random())
    end
end




----苦力怕小丑(MC里的爬行者)
function request_fx_asset(asset)
	STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
	while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
		util.yield()
	end
end
function request_control_once(entity)
	if not NETWORK.NETWORK_IS_IN_SESSION() then
		return true
	end
	local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
	return NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
end
function get_random_offset_from_entity(entity, minDistance, maxDistance)
	local pos = ENTITY.GET_ENTITY_COORDS(entity, false)
	return get_random_offset_in_range(pos, minDistance, maxDistance)
end
function get_random_offset_in_range(coords, minDistance, maxDistance)
	local radius = random_float(minDistance, maxDistance)
	local angle = random_float(0, 2 * math.pi)
	local delta = v3.new(math.cos(angle), math.sin(angle), 0.0)
	delta:mul(radius)
	coords:add(delta)
	return coords
end
function random_float(min, max)
	return min + math.random() * (max - min)
end
function creep(pid)
    local hash <const> = util.joaat("s_m_y_clown_01")
		local explosion <const> = Effect.new("scr_rcbarry2", "scr_exp_clown")
		local appears <const> = Effect.new("scr_rcbarry2",  "scr_clown_appears")
		request_model(hash)
		local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
		local pos = ENTITY.GET_ENTITY_COORDS(player, false)
		local coord = get_random_offset_from_entity(player, 5.0, 8.0)
		coord.z = coord.z - 1.0
		local ped = entities.create_ped(0, hash, coord, 0.0)
		request_fx_asset(appears.asset)
		GRAPHICS.USE_PARTICLE_FX_ASSET(appears.asset)
		GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(
			appears.name,
			ped,
			0.0, 0.0, -1.0,
			0.0, 0.0, 0.0,
			0.5, false, false, false
		)
		set_entity_face_entity(ped, player, false)
		PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
		TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, pos.x, pos.y, pos.z, 5.0, 0, false, 0, 0.0)
		local dest = pos
		PED.SET_PED_KEEP_TASK(ped, true)
		AUDIO.STOP_PED_SPEAKING(ped, true)
		util.create_tick_handler(function()
			local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
			local targetPos = players.get_position(pid)
			if not ENTITY.DOES_ENTITY_EXIST(ped) or PED.IS_PED_FATALLY_INJURED(ped) then
				return false
			elseif pos:distance(targetPos) > 150 and
			request_control(ped) then
				entities.delete(ped)
				return false
			elseif pos:distance(targetPos) < 3.0 and request_control(ped) then
				request_fx_asset(explosion.asset)
				GRAPHICS.USE_PARTICLE_FX_ASSET(explosion.asset)
				GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
					explosion.name,
					pos.x, pos.y, pos.z,
					0.0, 0.0, 0.0,
					1.0,
					false, false, false, false
				)
				FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 0, 1.0, true, true, 1.0, false)
				ENTITY.SET_ENTITY_VISIBLE(ped, false, false)
				entities.delete(ped)
				return false
			elseif targetPos:distance(dest) > 3.0 and request_control_once(ped) then
				dest = targetPos
				TASK.TASK_GO_TO_COORD_ANY_MEANS(ped, targetPos.x, targetPos.y, targetPos.z, 5.0, 0, false, 0, 0.0)
			end
		end)
end


------------------载具枪
Preview = {handle = 0, modelHash = 0}
Preview.__index = Preview
function Preview.new(modelHash)
	local self = setmetatable({}, Preview)
	self.modelHash = modelHash
	return self
end
function Preview:create(pos, heading)
	if self:exists() then return end
	self.handle = VEHICLE.CREATE_VEHICLE(self.modelHash, pos.x, pos.y, pos.z, heading, false, false, false)
	ENTITY.SET_ENTITY_ALPHA(self.handle, 153, true)
	ENTITY.SET_ENTITY_COLLISION(self.handle, false, false)
	ENTITY.SET_CAN_CLIMB_ON_ENTITY(self.handle, false)
end
function Preview:setRotation(rot)
	ENTITY.SET_ENTITY_ROTATION(self.handle, rot.x, rot.y, rot.z, 0, true)
end
function Preview:setCoords(pos)
	ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.handle, pos.x, pos.y, pos.z, false, false, false)
end
function Preview:destroy()
	entities.delete(self.handle)
	self.handle = 0
end
function Preview:setOnGround()
	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.handle, 1.0)
end
function Preview:exists()
	return self.handle ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.handle)
end

local modelHash = util.joaat("adder")
local preview = Preview.new(modelHash)
local setIntoVehicle = false
local maxDist = 100.0
local minDist = 15.0
local distancePerc = 0.0
local currentDistance = minDist
function get_veh_distance()
	if PAD.IS_CONTROL_JUST_PRESSED(2, 241) and distancePerc < 1.0 then
		distancePerc = distancePerc + 0.25
		timer.reset()
	elseif PAD.IS_CONTROL_JUST_PRESSED(2, 242) and distancePerc > 0.0 then
		distancePerc = distancePerc - 0.25
		timer.reset()
	end
	local distance = interpolate(minDist, maxDist, distancePerc)
	local duration <const> = 200 -- `ms`
	if currentDistance ~= distance and timer.elapsed() <= duration then
		currentDistance = interpolate(currentDistance, distance, timer.elapsed() / duration)
	end
	return currentDistance
end
function Instructional_add_control_group(index, name)
	local button = PAD.GET_CONTROL_GROUP_INSTRUCTIONAL_BUTTONS_STRING(2, index, true)
    Instructional:add_data_slot(index, name, button)
end
function Vehicle_gun_opt(opt)
    local vehicle = Objvehicles[opt]
    modelHash = util.joaat(vehicle)
end
function Vehicle_gun_into(toggle)
    setIntoVehicle = toggle
end
function Vehicle_gun()
    request_model(modelHash)
    local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    local distance = get_veh_distance()
    local raycast = get_raycast_result(distance + 5.0, TraceFlag.world)
    local coords = raycast.didHit and raycast.endCoords or get_offset_from_cam(distance)
    if not Config.general.disablepreview and
    PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
        if not preview:exists() then
            preview.modelHash = modelHash
            preview:create(coords, camRot.z)
        else
            preview:setCoords(coords)
            preview:setRotation(camRot)
            if raycast.didHit then preview:setOnGround() end
        end
        if Instructional:begin() then
            Instructional_add_control_group(29, "FM_AE_SORT_2")
            Instructional:set_background_colour(0, 0, 0, 80)
            Instructional:draw()
        end
    elseif preview:exists() then preview:destroy() end
    if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
        local veh = VEHICLE.CREATE_VEHICLE(modelHash, coords.x, coords.y, coords.z, camRot.z, true, true, false)
        NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.VEH_TO_NET(veh), true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, coords.x, coords.y, coords.z, false, false, false)
        ENTITY.SET_ENTITY_ROTATION(veh, camRot.x, camRot.y, camRot.z, 0, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 200.0)
        if not setIntoVehicle then
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 2)
        else
            VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, true)
            PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), veh, -1)
        end
    end
end
function Vehicle_gun_stop()
    if preview:exists() then 
        preview:destroy() 
    end
end





----超级跳
function get_offset_from_camera(distance)
    local cam_rot = CAM.GET_FINAL_RENDERED_CAM_ROT(0)
    local cam_pos = CAM.GET_FINAL_RENDERED_CAM_COORD()
    local direction = rotation_to_direction(cam_rot)
    local destination =
    {
        x = cam_pos.x + direction.x * distance,
        y = cam_pos.y + direction.y * distance,
        z = cam_pos.z + direction.z * distance
    }
    return destination
end
function rotation_to_direction(rotation)
        local adjusted_rotation =
        {
            x = (math.pi / 180) * rotation.x,
            y = (math.pi / 180) * rotation.y,
            z = (math.pi / 180) * rotation.z
        }
        local direction =
        {
            x = -math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
            y =  math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
            z =  math.sin(adjusted_rotation.x)
        }
        return direction
    end
    local function get_offset_from_camera(distance)
        local cam_rot = CAM.GET_FINAL_RENDERED_CAM_ROT(0)
        local cam_pos = CAM.GET_FINAL_RENDERED_CAM_COORD()
        local direction = rotation_to_direction(cam_rot)
        local destination =
        {
            x = cam_pos.x + direction.x * distance,
            y = cam_pos.y + direction.y * distance,
            z = cam_pos.z + direction.z * distance
        }
        return destination
end


----死亡警告
function dead_warning()
    if ENTITY.IS_ENTITY_DEAD(PLAYER.PLAYER_PED_ID()) then
        local string = "~o~不玩原神\n死了趴-~o~"..PLAYER.GET_PLAYER_NAME(PLAYER.PLAYER_ID())
        local scaleform_movie = GRAPHICS.REQUEST_SCALEFORM_MOVIE("MP_BIG_MESSAGE_FREEMODE")
        GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform_movie, "SHOW_SHARD_WASTED_MP_MESSAGE")
        GRAPHICS.DRAW_SCALEFORM_MOVIE(scaleform_movie, 0.5, 0.5, 1, 1, 255, 225, 255, 255)
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(string)
        GRAPHICS.END_SCALEFORM_MOVIE_METHOD(scaleform_movie)
    end
end

---载具跳跃
function get_vehicle_player_is_in(player)
	local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
	if PED.IS_PED_IN_ANY_VEHICLE(targetPed, false) then
		return PED.GET_VEHICLE_PED_IS_IN(targetPed, false)
	end
	return 0
end

--发送崔佛
function addBlipForEntity(entity, blipSprite, colour)
	local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)
	HUD.SET_BLIP_SPRITE(blip, blipSprite)
	HUD.SET_BLIP_COLOUR(blip, colour)
	HUD.SHOW_HEIGHT_ON_BLIP(blip, false)
	HUD.SET_BLIP_ROTATION(blip, SYSTEM.CEIL(ENTITY.GET_ENTITY_HEADING(entity)))
	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(entity, false)
	util.create_thread(function()
		while not ENTITY.IS_ENTITY_DEAD(entity) do
			local heading = ENTITY.GET_ENTITY_HEADING(entity)
			HUD.SET_BLIP_ROTATION(blip, SYSTEM.CEIL(heading))
			util.yield()
			if ENTITY.IS_ENTITY_DEAD(entity) or ENTITY.IS_ENTITY_DEAD(entity) or not ENTITY.DOES_ENTITY_EXIST(entity) or VEHICLE.GET_VEHICLE_ENGINE_HEALTH(entity) <= 0 then
				util.remove_blip(blip)
				util.yield()
			end
		end
	end)
	return blip
end
function getOffsetFromEntityGivenDistance(entity, distance)
	local pos = ENTITY.GET_ENTITY_COORDS(entity, 0)
	local theta = (math.random() + math.random(0, 1)) * math.pi --returns a random angle between 0 and 2pi (exclusive)
	local coords = vect.new(pos.x + distance * math.cos(theta),pos.y + distance * math.sin(theta),pos.z)
	return coords
end
function send_Angry_Trevor(pid)
    local vehicleHash = util.joaat("bodhi2")
    local pedHash = -1686040670
    request_models(vehicleHash, pedHash)
    local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(targetPed)
    local vehicle = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
    if not ENTITY.DOES_ENTITY_EXIST(vehicle) then
        return
    end
    local offset = getOffsetFromEntityGivenDistance(vehicle, 50.0)
    local outCoords = v3.new()
    local outHeading = memory.alloc()
    if PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(offset.x, offset.y, offset.z, outCoords, outHeading, 1, 3.0, 0) then
        ENTITY.SET_ENTITY_COORDS(vehicle, v3.getX(outCoords), v3.getY(outCoords), v3.getZ(outCoords))
        ENTITY.SET_ENTITY_HEADING(vehicle, memory.read_float(outHeading))
        VEHICLE.SET_VEHICLE_SIREN(vehicle, true)
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
        for seat = -1, -1 do
            local cop = entities.create_ped(2, pedHash, outCoords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
            addBlipForEntity(vehicle, 724, 17)
            PED.SET_PED_INTO_VEHICLE(cop, vehicle, seat)
            TASK.TASK_COMBAT_PED(cop, targetPed, 0, 16)
            PED.SET_PED_KEEP_TASK(cop, true)
            VEHICLE.SET_VEHICLE_COLOURS(vehicle, 32, 32)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vehicle, true)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle,-1, 3)
            PED.SET_PED_COMBAT_ATTRIBUTES(cop, 46, true)
            PED.SET_PED_COMBAT_ATTRIBUTES(cop, 3, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(cop, true)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, "Betty 32")
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(vehicle, 50)
            ENTITY.SET_ENTITY_INVINCIBLE(cop, true)
            ENTITY.SET_ENTITY_INVINCIBLE(vehicle, true)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle, 0)
            PED.SET_PED_NEVER_LEAVES_GROUP(cop, true)
            TASK.TASK_VEHICLE_MISSION_PED_TARGET(cop, vehicle, targetPed, 6, 100, 0, 0, 0, true)
        end
        for seat2 = 0, 0 do --2nd invisible trevor to insult the player due to gta being gta - and the fact that an npc cant have 2 tasks AFAIK
            local trev = entities.create_ped(2, pedHash, outCoords, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
            PED.SET_PED_INTO_VEHICLE(trev, vehicle, seat2)
            PED.SET_PED_COMBAT_ATTRIBUTES(trev, 3, false)
            PED.SET_PED_COMBAT_ATTRIBUTES(trev, 46, true)
            ENTITY.SET_ENTITY_VISIBLE(trev, false, 0)
            TASK.TASK_COMBAT_PED(trev, targetPed, 0, 16)
            ENTITY.SET_ENTITY_INVINCIBLE(trev, true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(trev, true)
        end
    end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
end




-------骑牛
function set_ped_apathy(ped, value)
    PED.SET_PED_CONFIG_FLAG(ped, 208, value)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, value)
    ENTITY.SET_ENTITY_INVINCIBLE(ped, value)
end
function ride_cow(state)
    if state then
        local player_heading = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID())
        local player_coords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())

        vehicle_for_cow_rider = create_vehicle(1641462412, player_coords.x, player_coords.y, player_coords.z, player_heading)
        ENTITY.SET_ENTITY_VISIBLE(vehicle_for_cow_rider, false, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(vehicle_for_cow_rider, true)
        cow_for_cow_rider = create_ped(29, 4244282910, player_coords.x, player_coords.y, player_coords.z, player_heading)
    
        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle_for_cow_rider, -1)

        local bone = PED.GET_PED_BONE_INDEX(cow_for_cow_rider, 0x796e)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(cow_for_cow_rider, vehicle_for_cow_rider, bone, 0, -1, 0.5, 0, 0, 0, true, false, false, false, 1, true, 0)

        set_ped_apathy(cow_for_cow_rider, true)
    else
        entities.delete(vehicle_for_cow_rider)
        entities.delete(cow_for_cow_rider)
    end
end


----珍珠烟花
function Pearl_fireworks()
    local animlib = 'anim@mp_fireworks'
    local anim_name = 'place_firework_3_box'
    request_anim_dict(animlib)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0.0, 0.52, 0.0)
    ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
    TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), animlib, anim_name, -1, -8.0, 3000, 0, 0, false, false, false)
    util.yield(1500)
    local box = create_object(-879052345, pos.x, pos.y, pos.z)
    local box_pos = ENTITY.GET_ENTITY_COORDS(box)
    OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(box)
    ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
    ENTITY.FREEZE_ENTITY_POSITION(box, true)
    util.yield(5000)

    local effect = "scr_indep_fireworks"
    local effect_name = "scr_indep_firework_fountain"
    request_ptfx_asset(effect)
    --第一阶段
    for i = 1, 20 do
        local c = math.ceil(i / 5) / 100 --4级(逐步修改烟花尺寸)
        GRAPHICS.USE_PARTICLE_FX_ASSET(effect)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(effect_name, box, 0, 0, 0.2, 0, 180, 0, c, true, true, true)
        GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(226 / 255, 17 / 255, 12 / 255)
        util.yield(100)
    end
    --第二阶段
    local end_time = os.time() + 10
    while end_time >= os.time() do
        GRAPHICS.USE_PARTICLE_FX_ASSET(effect)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(effect_name, box, 0, 0, 0.2, 0, 180, 0, 0.08, true, true, true)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(effect_name, box, 0, 0, 0.2, 0, 180, 0, 0.08, true, true, true)
        GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255)
        util.yield(100)
    end
    util.yield(8000)
    entities.delete(box)
end

--烟花桶
local placed_firework_boxes = {}
function anfangyanhua()
    local animlib = 'anim@mp_fireworks'
    local anim_name = 'place_firework_3_box'
    request_anim_dict(animlib)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0.0, 0.52, 0.0)
    local ped = PLAYER.PLAYER_PED_ID()
    ENTITY.FREEZE_ENTITY_POSITION(ped, true)
    TASK.TASK_PLAY_ANIM(ped, animlib, anim_name, -1, -8.0, 3000, 0, 0, false, false, false)
    util.yield(1500)
    local firework_box = entities.create_object(util.joaat('ind_prop_firework_03'), pos, true, false, false)
    local firework_box_pos = ENTITY.GET_ENTITY_COORDS(firework_box)
    OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(firework_box)
    ENTITY.FREEZE_ENTITY_POSITION(ped, false)
    util.yield(1000)
    ENTITY.FREEZE_ENTITY_POSITION(firework_box, true)
    placed_firework_boxes[#placed_firework_boxes + 1] = firework_box
end
function yanhuafashe()
    if #placed_firework_boxes == 0 then 
        util.toast("请先安放烟花!")
        return 
    end
    local ptfx_asset = "scr_indep_fireworks"
    local effect_name = "scr_indep_firework_trailburst"
    request_ptfx_asset(ptfx_asset)
    util.toast("烟花发射wow")
    for i = 1, 50 do
        for k, box in pairs(placed_firework_boxes) do 
            GRAPHICS.USE_PARTICLE_FX_ASSET(ptfx_asset)
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_ENTITY(effect_name, box, 0, 0, 0, 0, 180, 0, 1, true, true, true)
            GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255)
            util.yield(100)
        end
    end
    for k, box in pairs(placed_firework_boxes) do 
        entities.delete(box)
    end
    placed_firework_boxes = {}
end


----------女武神导弹
function nvwushen(toggle)
gUsingValkRocket = toggle
    if gUsingValkRocket then
        local rocket = 0
        local cam = 0
        local blip = 0
        local init = false
        local draw_rect = function(x, y, z, w)
            GRAPHICS.DRAW_RECT(x, y, z, w, 255, 255, 255, 255, false)
        end
        while gUsingValkRocket do
            util.yield_once()
            if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) and not init then
                init = true
                timer.reset()
            elseif init then
                if not ENTITY.DOES_ENTITY_EXIST(rocket) then
                    local offset = get_offset_from_cam(10)
                    rocket = entities.create_object(util.joaat("w_lr_rpg_rocket"), offset)
                    ENTITY.SET_ENTITY_INVINCIBLE(rocket, true)
                    ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(rocket, true, 1)
                    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.OBJ_TO_NET(rocket), true)
                    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(NETWORK.OBJ_TO_NET(rocket), false)
                    ENTITY.SET_ENTITY_RECORDS_COLLISIONS(rocket, true)
                    ENTITY.SET_ENTITY_HAS_GRAVITY(rocket, false)
                    CAM.DESTROY_ALL_CAMS(true)
                    cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
                    CAM.SET_CAM_NEAR_CLIP(cam, 0.01)
                    CAM.SET_CAM_NEAR_DOF(cam, 0.01)
                    GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
                    GRAPHICS.SET_TIMECYCLE_MODIFIER("CAMERA_secuirity")
                    CAM1.HARD_ATTACH_CAM_TO_ENTITY(cam, rocket, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true)
                    CAM.SET_CAM_ACTIVE(cam, true)
                    CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
                    PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
                    ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
                else
                    local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
                    local coords = ENTITY.GET_ENTITY_COORDS(rocket, false)
                    local force = rot:toDir()
                    force:mul(40.0)
                    ENTITY.SET_ENTITY_ROTATION(rocket, rot.x, rot.y, rot.z, 0, true)
                    STREAMING.SET_FOCUS_POS_AND_VEL(coords.x, coords.y, coords.z, rot.x, rot.y, rot.z)
                    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(rocket, 1, force.x, force.y, force.z, false, false, false, false)
                    HUD.HIDE_HUD_AND_RADAR_THIS_FRAME()
                    PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), true)
                    ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), true)
                    HUD1.HUD_SUPPRESS_WEAPON_WHEEL_RESULTS_THIS_FRAME()
                    draw_rect(0.5, 0.5 - 0.025, 0.050, 0.002)
                    draw_rect(0.5, 0.5 + 0.025, 0.050, 0.002)
                    draw_rect(0.5 - 0.025, 0.5, 0.002, 0.052)
                    draw_rect(0.5 + 0.025, 0.5, 0.002, 0.052)
                    draw_rect(0.5 + 0.050, 0.5, 0.050, 0.002)
                    draw_rect(0.5 - 0.050, 0.5, 0.050, 0.002)
                    draw_rect(0.5, 0.500 + 0.05, 0.002, 0.05)
                    draw_rect(0.5, 0.500 - 0.05, 0.002, 0.05)
                    local maxTime = 7000 -- `ms`
                    local length = 0.5 - 0.5 * (timer.elapsed() / maxTime) -- timer length
                    local perc = length / 0.5
                    local color = get_blended_colour(perc) -- timer color
                    GRAPHICS.DRAW_RECT(0.25, 0.5, 0.03, 0.5, 255, 255, 255, 120, false)
                    GRAPHICS.DRAW_RECT(0.25, 0.75 - length / 2, 0.03, length, color.r, color.g, color.b, color.a, false)
                    if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(rocket) or length <= 0 then
                        local impactCoord = ENTITY.GET_ENTITY_COORDS(rocket, false)
                        FIRE.ADD_EXPLOSION(impactCoord.x, impactCoord.y, impactCoord.z, 32, 1.0, true, false, 0.4, false)
                        entities.delete(rocket)
                        CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
                        GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
                        STREAMING.CLEAR_FOCUS()
                        CAM.DESTROY_CAM(cam, true)
                        PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
                        ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
                        rocket = 0
                        init = false
                    end
                end
            end
        end
        if rocket and ENTITY.DOES_ENTITY_EXIST(rocket) then
            local impactCoord = ENTITY.GET_ENTITY_COORDS(rocket, false)
            FIRE.ADD_EXPLOSION(impactCoord.x, impactCoord.y, impactCoord.z, 32, 1.0, true, false, 0.4, false)
            entities.delete(rocket)
            STREAMING.CLEAR_FOCUS()
            CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
            CAM.DESTROY_CAM(cam, true)
            GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
            ENTITY.FREEZE_ENTITY_POSITION(PLAYER.PLAYER_PED_ID(), false)
            PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_PED_ID(), false)
            if HUD.DOES_BLIP_EXIST(blip) then util.remove_blip(blip) end
            HUD.UNLOCK_MINIMAP_ANGLE()
            HUD.UNLOCK_MINIMAP_POSITION()
        end
    end
end

-------载具变色
function requestweapon(...)
	local arg = {...}
	for _, model in ipairs(arg) do
		WEAPON.REQUEST_WEAPON_ASSET(model, 31, 26)
		while not WEAPON.HAS_WEAPON_ASSET_LOADED(model) do
			util.yield()
		end
	end
end
function RGBNeonKit(pedm)
    local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, false)
    for i = 0, 3 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, i, true)
    end
end
local rgb_cus = 100
function colorspeed(c)
    rgb_cus = 10000/c
end
function zjbs()
    if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), true) ~= 0 then
        local vmod = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
        RGBNeonKit(PLAYER.PLAYER_PED_ID())
        local red = math.random(0, 255)
        local green = math.random(0, 255)
        local blue = math.random(0, 255)
        VEHICLE.SET_VEHICLE_NEON_COLOUR(vmod, red, green, blue)
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vmod, red, green, blue)
        VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vmod, red, green, blue)
        util.yield(rgb_cus)
       end
    end
local qzdrgb_cus = 100
function qzdcolorspeed(c)
    qzdrgb_cus = 10000/c
end
function qzd()
    local color = {
            {64, 1},
            {73, 2},
            {51, 3}, 
            {92, 4}, 
            {89, 5}, 
            {88, 6}, 
            {38, 7}, 
            {39 , 8}, 
            {137, 9}, 
            {135, 10}, 
            {145, 11},
            {142, 12} 
        }
    if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID()) ~= 0 then
        local vmod = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
        RGBNeonKit(PLAYER.PLAYER_PED_ID())
        local rcolor = math.random(1, 12)
        VEHICLE.TOGGLE_VEHICLE_MOD(vmod, 22, true)
        VEHICLE.SET_VEHICLE_NEON_INDEX_COLOUR(vmod, color[rcolor][1])
        VEHICLE.SET_VEHICLE_COLOURS(vmod, color[rcolor][1], color[rcolor][1])
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vmod, 0, color[rcolor][1])
        VEHICLE.SET_VEHICLE_EXTRA_COLOUR_5(vmod, color[rcolor][1])
        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vmod, color[rcolor][2])
        util.yield(qzdrgb_cus)
    end
end

----B-11攻击
local B11plane = {}
function B11_attack(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid), false)
    local drive_ped = {}
    if ENTITY.DOES_ENTITY_EXIST(B11plane[1]) then return end
    for i = 1, 30 do
        B11plane[i] = create_vehicle(1692272545, pos.x+math.random(-100, 100), pos.y+math.random(-100, 100), pos.z+200, math.random(0, 360))

        ENTITY.SET_ENTITY_INVINCIBLE(B11plane[i],true)
        ENTITY.SET_ENTITY_COLLISION(B11plane[i], false, true)

        local blip = HUD.ADD_BLIP_FOR_ENTITY(B11plane[i])
        HUD.SET_BLIP_COLOUR(blip, 1)--设置颜色

        drive_ped[i] = PED.CREATE_RANDOM_PED_AS_DRIVER(B11plane[i], 1)
        VEHICLE.SET_VEHICLE_ENGINE_ON(drive_ped[i], true, true, 0)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(B11plane[i], 100 / 3.6)

        TASK.TASK_COMBAT_PED(drive_ped[i], PLAYER.GET_PLAYER_PED(pid), 0, 16)
    end
end


------轰炸区
active_bowling_balls = 0
function bomb_shower_tick_handler(ent)
    local start_time = os.clock()
    active_bowling_balls = active_bowling_balls + 1
        util.create_tick_handler(function()
            if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(ent) or os.clock() - start_time > 10 or not ENTITY.DOES_ENTITY_EXIST(ent) then
                if ENTITY.DOES_ENTITY_EXIST(ent) then 
                    local c = ENTITY.GET_ENTITY_COORDS(ent)
                    FIRE.ADD_EXPLOSION(c.x, c.y, c.z, 17, 100.0, true, false, 0.0)
                    entities.delete(ent)
                end
                if active_bowling_balls > 0 then 
                    active_bowling_balls = active_bowling_balls - 1
                end
                util.stop_thread()
            end
        end)
end


------------RGB
custom_rgb = true
rgb_thread = util.create_thread(function (thr)
    local r = 255
    local g = 0
    local b = 0
    rgb = {255, 0, 0}
    while true do
        if not custom_rgb then
            if r > 0 and g < 255 and b == 0 then
                r = r - 1
                g = g + 1
            elseif r == 0 and g > 0 and b < 255 then
                g = g - 1
                b = b + 1
            elseif r < 255 and b > 0 then
                r = r + 1
                b = b - 1
            end

            rgb[1] = r
            rgb[2] = g
            rgb[3] = b
        else
            rgb = {custom_r, custom_g, custom_b}
        end
        util.yield()
    end
end)
    


-----悲伤的耶稣
function dispatch_griefer_jesus(target)
    griefer_jesus = util.create_thread(function(thr)
        util.toast("悲伤耶稣派来了!")
        request_model(-835930287)
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(target)
        coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)
        coords.x = coords['x']
        coords.y = coords['y']
        coords.z = coords['z']
        local jesus = entities.create_ped(1, -835930287, coords, 90.0)
        ENTITY.SET_ENTITY_INVINCIBLE(jesus, true)
        PED.SET_PED_HEARING_RANGE(jesus, 9999)
	    PED.SET_PED_CONFIG_FLAG(jesus, 281, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(jesus, 5, true)
	    PED.SET_PED_COMBAT_ATTRIBUTES(jesus, 46, true)
        PED.SET_PED_CAN_RAGDOLL(jesus, false)
        WEAPON.GIVE_WEAPON_TO_PED(jesus, util.joaat("WEAPON_RAILGUN"), 9999, true, true)
        TASK.TASK_GO_TO_ENTITY(jesus, target_ped, -1, -1, 100.0, 0.0, 0)
    	TASK.TASK_COMBAT_PED(jesus, target_ped, 0, 16)
        PED.SET_PED_ACCURACY(jesus, 100.0)
        PED.SET_PED_COMBAT_ABILITY(jesus, 2)
        while true do
            local player_coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)
            local jesus_coords = ENTITY.GET_ENTITY_COORDS(jesus, false)
            local dist =  MISC.GET_DISTANCE_BETWEEN_COORDS(player_coords['x'], player_coords['y'], player_coords['z'], jesus_coords['x'], jesus_coords['y'], jesus_coords['z'], false)
            if dist > 100 then
                local behind = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, -3.0, 0.0, 0.0)
                ENTITY.SET_ENTITY_COORDS(jesus, behind['x'], behind['y'], behind['z'], false, false, false, false)
            end
            -- if jesus disappears we can just make another lmao
            if not ENTITY.DOES_ENTITY_EXIST(jesus) then
                util.toast("耶稣显然不再存在。或许已被玩家清除。")
                util.stop_thread()
            end
            local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(target)
            if not players.exists(target) then
                util.toast("玩家目标已丢失。悲伤的耶稣线正在停止")
                util.stop_thread()
            else
                TASK.TASK_COMBAT_PED(jesus, target_ped, 0, 16)
            end
            util.yield()
        end
    end)
end

-----发送攻击者
function send_attacker(hash, pid)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(target_ped, false)
    local attacker = create_ped(28, hash, pos.x, pos.y, pos.z, math.random(0, 270))
    ENTITY.SET_ENTITY_INVINCIBLE(attacker, true)
    TASK.TASK_COMBAT_PED(attacker, target_ped, 0, 16)
    PED.SET_PED_ACCURACY(attacker, 100.0)
    PED.SET_PED_COMBAT_ABILITY(attacker, 2)
    PED.SET_PED_AS_ENEMY(attacker, true)
    PED.SET_PED_FLEE_ATTRIBUTES(attacker, 0, false)
    PED.SET_PED_COMBAT_ATTRIBUTES(attacker, 46, true)
end
function send_aircraft_attacker(vhash, phash, pid)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, 1.0, 0.0, 500.0)
    request_model(vhash)
    request_model(phash)
    coords.x = coords.x + 2
    coords.y = coords.y + 2
    local aircraft = entities.create_vehicle(vhash, coords, 0.0)
    VEHICLE.CONTROL_LANDING_GEAR(aircraft, 3)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(aircraft)
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(aircraft, VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(aircraft))
    ENTITY.SET_ENTITY_INVINCIBLE(aircraft, true)
    for i= -1, VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(vhash) - 2 do
        local ped = entities.create_ped(28, phash, coords, 30.0)
        TASK.TASK_PLANE_MISSION(ped, aircraft, 0, target_ped, 0, 0, 0, 6, 0.0, 0, 0.0, 50.0, 40.0)
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
        PED.SET_PED_INTO_VEHICLE(ped, aircraft, i)
        TASK.TASK_COMBAT_PED(ped, target_ped, 0, 16)
        PED.SET_PED_ACCURACY(ped, 100.0)
        PED.SET_PED_COMBAT_ABILITY(ped, 2)
    end
end



-----生成实体垃圾
function spam_entity_on_player(ped, hash)
    request_model(hash)
    for i=1, 30 do
        rand_coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, math.random(-1,1), math.random(-1,1), math.random(-1,1))
        rand_coords.x = rand_coords['x']
        rand_coords.y = rand_coords['y']
        rand_coords.z = rand_coords['z']
        obj = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, rand_coords['x'], rand_coords['y'], rand_coords['z'], true, false, false)
        grav_factor = 1.0
        ENTITY.SET_ENTITY_HAS_GRAVITY(obj, true)
        OBJECT.SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(obj, true)
    end
end



----陨落的飞机
function start_angryplanes_thread()
    local v_hashes = {util.joaat('lazer'), util.joaat('jet'), util.joaat('cargoplane'), util.joaat('titan'), util.joaat('luxor'), util.joaat('seabreeze'), util.joaat('vestra'), util.joaat('volatol'), util.joaat('tula'), util.joaat('buzzard'), util.joaat('avenger')}
    local angry_planes_tar = PLAYER.PLAYER_PED_ID()
    local radius = 200
    local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(angry_planes_tar, math.random(-radius, radius), math.random(-radius, radius), math.random(600, 800))
    local pick = v_hashes[math.random(1, #v_hashes)]
    request_model(pick)
    local aircraft = entities.create_vehicle(pick, c, math.random(0, 270))
    set_entity_face_entity(aircraft, angry_planes_tar, true)
    VEHICLE.SET_VEHICLE_ENGINE_ON(aircraft, true, true, false)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(aircraft)
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(aircraft, VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(aircraft)+1000.0)
    VEHICLE.SET_VEHICLE_OUT_OF_CONTROL(aircraft, true, true)
    util.yield(5000)
end

----墨西哥乐队
function dispatch_mariachi(target)
    mariachi_thr = util.create_thread(function()
        local men = {}
        local player_ped
        local pos_offsets = {-1.0, 0.0, 1.0}
        local p_hash = -927261102
        local pos
        request_model(p_hash)
        player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(target)
        for i=1, 3 do
            local spawn_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped, pos_offsets[i], 1.0, 0.0)
            local ped = entities.create_ped(1, p_hash, spawn_pos, 0.0)
            local flag = entities.create_object(util.joaat("prop_flag_mexico"), spawn_pos, 0)
            ENTITY.SET_ENTITY_HEADING(ped, ENTITY.GET_ENTITY_HEADING(player_ped)+180)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(flag, ped, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true, 0)
            ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(ped, true, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(ped, "WORLD_HUMAN_MUSICIAN", 0, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
            PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false)
            PED.SET_PED_CAN_RAGDOLL(ped, false)
            ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
            men[#men + 1] = ped
        end
    end)
end

------生成实体
function spawn_object_in_front_of_ped(ped, hash, ang, room, zoff, setonground)
    coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, room, zoff)
    request_model(hash)
    hdng = ENTITY.GET_ENTITY_HEADING(ped)
    new = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, coords['x'], coords['y'], coords['z'], true, false, false)
    ENTITY.SET_ENTITY_HEADING(new, hdng+ang)
    if setonground then
        OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(new)
    end
    return new
end


-----撒尿
function peeloop_player(pid,on)
    if on then
        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local bone_index = PED.GET_PED_BONE_INDEX(player_ped, 0x2e28)
        request_ptfx_asset_peeloop("core")
        GRAPHICS.USE_PARTICLE_FX_ASSET("core")
        ptfx_id = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("ent_amb_peeing", player_ped, 0, 0, 0, -90, 0, 0, bone_index, 2, false, false, false, 0, 0, 0, 0)
    else
        GRAPHICS.REMOVE_PARTICLE_FX(ptfx_id, true)
    end
end


------防笼子
function get_condensed_player_name(player)
	local condensed = "<C>" .. PLAYER.GET_PLAYER_NAME(player) .. "</C>"
	if players.get_boss(player) ~= -1  then
		local colour = players.get_org_colour(player)
		local hudColour = get_hud_colour_from_org_colour(colour)
		return string.format("~HC_%d~%s~s~", hudColour, condensed)
	end
	return condensed
end
function get_net_obj(entity)
	local pEntity = entities.handle_to_pointer(entity)
	return pEntity ~= NULL and memory.read_long(pEntity + 0xD0) or NULL
end
function get_entity_owner(entity)
	local net_obj = get_net_obj(entity)
	return net_obj ~= NULL and memory.read_byte(net_obj + 0x49) or -1
end

-----自闭模式
function chickenmode(on_toggle)
    local BlockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Enabled")
    local UnblockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Disabled")
    local BlockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Enabled")
    local UnblockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Disabled")
    if on_toggle then
        util.toast("开启自闭模式")
        menu.trigger_commands("desyncall on")
        menu.trigger_command(BlockIncSyncs)
        menu.trigger_command(BlockNetEvents)
        menu.trigger_commands("anticrashcamera on")
    else
        util.toast("关闭自闭模式")
        menu.trigger_commands("desyncall off")
        menu.trigger_command(UnblockIncSyncs)
        menu.trigger_command(UnblockNetEvents)
        menu.trigger_commands("anticrashcamera off")
    end
end

----拦截效果
function blockcrasheffect()
    local coords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID() , false)
    GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(coords.x, coords.y, coords.z, 400)
    GRAPHICS.REMOVE_PARTICLE_FX_FROM_ENTITY(PLAYER.PLAYER_PED_ID())
end
function blockfireeffect()
    local coords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID() , false)
    FIRE.STOP_FIRE_IN_RANGE(coords.x, coords.y, coords.z, 100)
    FIRE.STOP_ENTITY_FIRE(PLAYER.PLAYER_PED_ID())
end

----派遣劫匪
function sendmugger_npc(pid)--gpbd_fm_1(全局名)
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        util.toast("当前劫匪活动还未结束哦")
    else
        local global = 1853988       --https://github.com/YimMenu/YimMenu/blob/master/src/core/scr_globals.hpp
        local bits_addr = memory.script_global(global + (PLAYER.PLAYER_ID() * 862 + 1) + 140)
            memory.write_int(bits_addr, SetBit(memory.read_int(bits_addr), 0))
            write_global.int(global + (PLAYER.PLAYER_ID() * 862 + 1) + 141, pid)
        util.toast("劫匪已出动")
    end
end
----拦截劫匪
function block_mugger()
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local sender = memory.read_int(memory.script_local("am_gang_call", 286))
        local target = memory.read_int(memory.script_local("am_gang_call", 287)) --返回玩家PID
        
        local netId = memory.read_int(memory.script_local("am_gang_call", 62 + 10 + (0 * 7 + 1)))
        if NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netId) and target == PLAYER.PLAYER_ID() then
            local mugger = NETWORK.NET_TO_PED(netId)
            entities.delete(mugger)
            util.toast("劫匪来自: " .. PLAYER.GET_PLAYER_NAME(sender))
        end
    end
end
-----劫匪检测
function show_mugger()
	if NETWORK.NETWORK_IS_SESSION_ACTIVE() and NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local netId	= memory.read_int(memory.script_local("am_gang_call", 62 + 10 + (0 * 7 + 1)))
        if NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netId) and not ENTITY.IS_ENTITY_DEAD(NETWORK.NET_TO_PED(netId), false) then
            local mugger = NETWORK.NET_TO_PED(netId)
            draw_bounding_box(mugger, true, {r = 255, g = 0, b = 0, a = 80})
        end
	end
end




-----一拳超人
function supermanpersonl()
	local pWeapon = memory.alloc_int()
	WEAPON.GET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), pWeapon, 1)
	local weaponHash = memory.read_int(pWeapon)
	if WEAPON.IS_PED_ARMED(PLAYER.PLAYER_PED_ID(), 1) or weaponHash == util.joaat("weapon_unarmed") then
		local pImpactCoords = v3.new()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
		if WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), pImpactCoords) then
			set_explosion_proof(PLAYER.PLAYER_PED_ID(), true)
			util.yield_once()
			FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z - 1.0, 29, 5.0, false, true, 0.3, true)
		elseif not FIRE.IS_EXPLOSION_IN_SPHERE(29, pos.x, pos.y, pos.z, 2.0) then
			set_explosion_proof(PLAYER.PLAYER_PED_ID(), false)
		end
	end
end



-------核弹枪
mutually_exclusive_weapons  = {}
function toDirection(rotation) 
	local adjusted_rotation = { 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = {
		x = - math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
		y =   math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
		z =   math.sin(adjusted_rotation.x)
	}
	return direction
end
function direction()
    local c1 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, 5, 0)
    local res = raycast_gameplay_cam(-1, 1000)
    local c2
    if res[1] ~= 0 then
        c2 = res[2]
    else
        c2 = get_offset_from_gameplay_camera(1000)
    end
    c2.x = (c2.x - c1.x) * 1000
    c2.y = (c2.y - c1.y) * 1000
    c2.z = (c2.z - c1.z) * 1000
    return c2, c1
end
function nukegunmode()
    if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
        WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(-1312131151, false)
        util.create_thread(function()
            local hash = util.joaat('w_arena_airmissile_01a')
            request_model(hash)
            local cam_rot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
            local dir, pos = direction()
            local bomb = entities.create_object(hash, pos)
            ENTITY.APPLY_FORCE_TO_ENTITY(bomb, 0, dir.x, dir.y, dir.z, 0.0, 0.0, 0.0, 0, true, false, true, false, true)
            ENTITY.SET_ENTITY_ROTATION(bomb, cam_rot.x, cam_rot.y, cam_rot.z, 1, true)
            while not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(bomb) do
                util.yield()
            end
            local nukePos = ENTITY.GET_ENTITY_COORDS(bomb, true)
            entities.delete(bomb)
            executeNuke(nukePos)
        end)
    end
end




------杀死敌人
function get_peds_in_player_range(player, radius)
	local peds = {}
	local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
	local pos = players.get_position(player)
	for _, ped in ipairs(entities.get_all_peds_as_handles()) do
		if ped ~= playerPed and not PED.IS_PED_FATALLY_INJURED(ped) then
			local pedPos = ENTITY.GET_ENTITY_COORDS(ped, true)
			if pos:distance(pedPos) <= radius then table.insert(peds, ped) end
		end
	end
	return peds
end

-----子弹类型
function zidanleixing()
	for id, data in pairs(weapon_stuff) do
        local name = data[1]
        local weapon_name = data[2]
        local a = false
        menu.toggle(weapon_thing, name, {}, "", function(toggle)
            a = toggle
            while a do
                local weapon = util.joaat(weapon_name)
                projectile = weapon
                while not WEAPON.HAS_WEAPON_ASSET_LOADED(projectile) do
                    WEAPON.REQUEST_WEAPON_ASSET(projectile, 31, false)
                    util.yield(10)
                end
                local inst = v3.new()
                if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
                    if not WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), inst) then
                        v3.set(inst,CAM.GET_FINAL_RENDERED_CAM_ROT(2))
                        local tmp = v3.toDir(inst)
                        v3.set(inst, v3.get(tmp))
                        v3.mul(inst, 1000)
                        v3.set(tmp, CAM.GET_FINAL_RENDERED_CAM_COORD())
                        v3.add(inst, tmp)
                    end
                    local x, y, z = v3.get(inst)
                    local wpEnt = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(PLAYER.PLAYER_PED_ID(), 0)
                    local wpCoords = ENTITY1._GET_ENTITY_BONE_POSITION_2(wpEnt, ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(wpEnt, "gun_muzzle"))
                    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(wpCoords.x, wpCoords.y, wpCoords.z, x, y, z, 1, true, weapon, PLAYER.PLAYER_PED_ID(), true, false, 1000)
                end
                util.yield()
            end
            local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
            MISC.CLEAR_AREA_OF_PROJECTILES(pos.x, pos.y, pos.z, 999999, 0)
        end)
    end
end


---------举手
function juqishoulai()
    if PAD.IS_CONTROL_PRESSED(1, 323) then
        request_anim_dict("random@mugging3")
        if not ENTITY.IS_ENTITY_PLAYING_ANIM(PLAYER.PLAYER_PED_ID(), "random@mugging3", "handsup_standing_base", 3) then
            WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.PLAYER_PED_ID(), MISC.GET_HASH_KEY("WEAPON_UNARMED"), true)
            TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), "random@mugging3", "handsup_standing_base", 3, 3, -1, 51, 0, false, false, false)
            STREAMING.REMOVE_ANIM_DICT("random@mugging3")
            PED.SET_ENABLE_HANDCUFFS(PLAYER.PLAYER_PED_ID(), true)
        end
    end
    if PAD.IS_CONTROL_RELEASED(1, 323) and ENTITY.IS_ENTITY_PLAYING_ANIM(PLAYER.PLAYER_PED_ID(), "random@mugging3", "handsup_standing_base", 3) then
        TASK.CLEAR_PED_SECONDARY_TASK(PLAYER.PLAYER_PED_ID())
        PED.SET_ENABLE_HANDCUFFS(PLAYER.PLAYER_PED_ID(), false)
    end
end

----太空步
function Space_walk(on)
    if PAD.IS_CONTROL_PRESSED(0, 32)  or PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35) then
        local f = ENTITY.GET_ENTITY_FORWARD_VECTOR(PLAYER.PLAYER_PED_ID())
        f['x'] = -f['x']
        f['y'] = -f['y']
        f['z'] = -f['z']
        ENTITY.SET_ENTITY_VELOCITY(PLAYER.PLAYER_PED_ID(), f['x'], f['y']*3, 0.0)
    end
end
----表演
function Performing_actions(index)
    local animDictionary = {"anim@arena@celeb@flat@solo@no_props@","anim@arena@celeb@flat@solo@no_props@","anim@mp_player_intcelebrationfemale@karate_chops"}
    local animationName = {"cap_a_player_a","flip_a_player_a","karate_chops"}
    request_anim_dict(animDictionary[index])
    TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), animDictionary[index], animationName[index], 8.0, 8.0, 5000, 1, 0, true, true, true)
end
----忍者跑
function renzhepao(on)
    if on then
        local renzhe = "missfbi1"
        local pao = "ledge_loop"
        request_anim_dict(renzhe)
        TASK.TASK_PLAY_ANIM(PLAYER.PLAYER_PED_ID(), renzhe, pao, 3, 3, -1, 51, 0, false, false, false)
        PED.SET_ENABLE_HANDCUFFS(PLAYER.PLAYER_PED_ID(),on)
    else
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
        PED.SET_ENABLE_HANDCUFFS(PLAYER.PLAYER_PED_ID(),off)
    end
end


--------匿名杀死所有人
function kill_player(pid)
    local entity = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, true)
    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'] + 2, 7, 1000, false, true, 0)
end
function nimingsharen()
    for k,v in pairs(players.list(false, true, true)) do
        kill_player(v)
        util.yield()
    end
end

-----显示时间
function daidaishijian(state)
    timeos = state
    if timeos then
        while timeos do
            draw_string(string.format(os.date('~bold~~italic~~o~%Y-%m-%d ~b~%H:%M:%S', os.time())), 0.43,0.05, 0.47,5)
            util.yield()
        end
    end 
end


--普通笼子
function ptlz(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    local hash = util.joaat("prop_gold_cont_01")
    request_model(hash)
	pos.z = pos.z-0.9
	local object1 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, true)																	
	ENTITY.FREEZE_ENTITY_POSITION(object1, true)
end


--七度空间
function qdkj(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local hash = 1089807209
    request_model(hash)
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - 1, pos.y, pos.z - .5, true, true, false) -- front
	local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + 1, pos.y, pos.z - .5, true, true, false) -- back
	local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + 1, pos.z - .5, true, true, false) -- left
	local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - 1, pos.z - .5, true, true, false) -- right
	local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false) -- above
	ENTITY.FREEZE_ENTITY_POSITION(cage_object, true)
	ENTITY.FREEZE_ENTITY_POSITION(cage_object2, true)
	ENTITY.FREEZE_ENTITY_POSITION(cage_object3, true)
	ENTITY.FREEZE_ENTITY_POSITION(cage_object4, true)
	ENTITY.FREEZE_ENTITY_POSITION(cage_object5, true)
	util.yield(15)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end
--钱笼子
function zdlz(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local hash = util.joaat("bkr_prop_moneypack_03a")
    request_model(hash)
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z, true, true, false) -- front
	local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z, true, true, false) -- back
	local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z, true, true, false) -- left
	local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z, true, true, false) -- right
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z + .25, true, true, false) -- front
	local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z + .25, true, true, false) -- back
	local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z + .25, true, true, false) -- left
	local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z + .25, true, true, false) -- right
	local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false) -- above
	util.yield(15)
	local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object, 0)
	rot.y = 90
	ENTITY.SET_ENTITY_ROTATION(cage_object, rot.x,rot.y,rot.z, 1,true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end
--垃圾箱
function yylz(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local hash = 684586828
	request_model(hash)
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)
	local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + 1, true, true, false)
	util.yield(15)
	local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object, 0)
	rot.y = 90
	ENTITY.SET_ENTITY_ROTATION(cage_object, rot.x,rot.y,rot.z, 1,true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end
--小车车
function cclz(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    local hash = 4022605402
    request_model(hash)
    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
    util.yield(15)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end
--圣诞快乐
function sdkl1(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local hash = 238789712
    request_model(hash)
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
	util.yield(15)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end
--圣诞快乐pro
function sdkl2(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local hash = util.joaat("ch_prop_tree_02a")
    request_model(hash)
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false) -- front
	local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false) -- back
	local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false) -- left
	local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false) -- right
	local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false) -- above
	util.yield(15)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end
--圣诞快乐promax
function sdkl3(pid)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	local hash = util.joaat("ch_prop_tree_03a")
    request_model(hash)
	local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false) -- front
	local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false) -- back
	local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false) -- left
	local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false) -- right
	local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false) -- above
	util.yield()
	local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object, 0)
	rot.y = 90
	ENTITY.SET_ENTITY_ROTATION(cage_object, rot.x,rot.y,rot.z, 1, true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end
--电击笼
function powercage(pid)
    local number_of_cages = 6
    local elec_box = util.joaat("prop_elecbox_12")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    pos.z = pos.z - 0.5
    request_model(elec_box)
    local temp_v3 = v3.new(0, 0, 0)
    for i = 1, number_of_cages do
        local angle = (i / number_of_cages) * 360
        temp_v3.z = angle
        local obj_pos = temp_v3:toDir()
        obj_pos:mul(2.5)
        obj_pos:add(pos)
        for offs_z = 1, 5 do
            local electric_cage = entities.create_object(elec_box, obj_pos)
            ENTITY.SET_ENTITY_ROTATION(electric_cage, 90.0, 0.0, angle, 1, true)
            obj_pos.z = obj_pos.z + 0.75
            ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
        end
    end
end
--竞技管
function jjglz(pid)
   local hash = util.joaat("stt_prop_stunt_tube_s")
	request_model(hash)
	local pos = players.get_position(pid)
	local obj = entities.create_object(hash, pos)
	local rot = ENTITY.GET_ENTITY_ROTATION(obj, 2)
	ENTITY.SET_ENTITY_ROTATION(obj, rot.x, 90.0, rot.z, 1, true)
	STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end

--英国女王笼子
function gueencage(pid)
    local number_of_cages = 6
    local coffin_hash = util.joaat("prop_coffin_02b")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    request_model(coffin_hash)
    local temp_v3 = v3.new(0, 0, 0)
    for i = 1, number_of_cages do
        local angle = (i / number_of_cages) * 360
        temp_v3.z = angle
        local obj_pos = temp_v3:toDir()
        obj_pos:mul(0.8)
        obj_pos:add(pos)
        obj_pos.z = obj_pos.z + 0.1
       local coffin = entities.create_object(coffin_hash, obj_pos)
       ENTITY.SET_ENTITY_ROTATION(coffin, 90.0, 0.0, angle, 1, true)
       ENTITY.FREEZE_ENTITY_POSITION(coffin, true)
    end
end
--运输集装箱
function chestcage(pid)
    local container_hash = util.joaat("prop_container_ld_pu")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    request_model(container_hash)
    pos.z = pos.z - 1
    local container = entities.create_object(container_hash, pos, 0)
    ENTITY.FREEZE_ENTITY_POSITION(container, true)
end
--载具笼子
function vehcagelol(pid)
    local container_hash = util.joaat("boxville3")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    request_model(container_hash)
    local container = entities.create_vehicle(container_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 2.0, 0.0), ENTITY.GET_ENTITY_HEADING(ped))
    ENTITY.SET_ENTITY_VISIBLE(container, false)
    ENTITY.FREEZE_ENTITY_POSITION(container, true)
end
--燃气笼
function gascage(pid)
    local gas_cage_hash = util.joaat("prop_gascage01")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    request_model(gas_cage_hash)
    pos.z = pos.z - 1
    local gas_cage = entities.create_object(gas_cage_hash, pos, 0)
    pos.z = pos.z + 1
    local gas_cage2 = entities.create_object(gas_cage_hash, pos, 0)
    ENTITY.FREEZE_ENTITY_POSITION(gas_cage, true)
    ENTITY.FREEZE_ENTITY_POSITION(gas_cage2, true)
end

---------发送垃圾
function tpTableToPlayer(tbl, pid)
    if NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
        local c = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
        for _, v in pairs(tbl) do
            if (not PED.IS_PED_A_PLAYER(v)) then
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(v, c.x, c.y, c.z, false, false, false)
            end
        end
    end
end
function TpAllPeds(player)
    local pedHandles = entities.get_all_peds_as_handles()
    tpTableToPlayer(pedHandles, player)
end
function TpAllVehs(player)
    local vehHandles = entities.get_all_vehicles_as_handles()
    tpTableToPlayer(vehHandles, player)
end
function TpAllObjects(player)
    local objHandles = entities.get_all_objects_as_handles()
    tpTableToPlayer(objHandles, player)
end
function TpAllPickups(player)
    local pickupHandles = entities.get_all_pickups_as_handles()
    tpTableToPlayer(pickupHandles, player)
end

---------给予爆炸子弹
function GetTableFromV3Instance(v3int)
    local tbl = {x = v3.getX(v3int), y = v3.getY(v3int), z = v3.getZ(v3int)}
    return tbl
end
function SE_add_owned_explosion(ped, x, y, z, exptype, dmgscale, isheard, isinvis, camshake)
    FIRE.ADD_OWNED_EXPLOSION(ped, x, y, z, exptype, dmgscale, isheard, isinvis, camshake)
end

------------喷射
function request_ptfx_asset_peeloop(asset)
    STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
        util.yield()
    end
end


function orbital(pid) 
    for i = 0, 30 do 
        pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
        for j = -2, 2 do 
            for k = -2, 2 do 
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
                FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), pos.x + j, pos.y + j, pos.z + (30 - i), 29, 999999.99, true, false, 8)
            end
        end
        util.yield(20)
    end
end

----火箭雨v1
function rain_rockets(pid)
    local user_ped = PLAYER.PLAYER_PED_ID()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    local hash = util.joaat("weapon_airstrike_rocket")
    if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
        WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
    end
    pos.x = pos.x + math.random(-10,10)
    pos.y = pos.y + math.random(-10,10)
    local ground_ptr = memory.alloc(32)
    MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, ground_ptr, false, false)
    pos.z = memory.read_float(ground_ptr)
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z+50, pos.x, pos.y, pos.z, 200, true, hash, owner, true, false, 2500.0)
    util.yield(200)
end
----子弹雨
function rain_bullet(pid)
    local hash = MISC.GET_HASH_KEY("weapon_machinepistol")
    if not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) then
        WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
    end
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid))
    pos.z = pos.z + 10.0
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z-10, 10000.00, true, hash,0, true, false, 10000.0)
    pos.y = pos.y + 10.0
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x, pos.y-10, pos.z-10, 10000.00, true, hash,0, true, false, 10000.0)
    pos.x = pos.x + 10.0
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z, pos.x-10, pos.y-10, pos.z-10, 10000.00, true, hash,0, true, false, 10000.0)
end


--------------自定义假R*警告
function custom_alert(l1) -- totally not skidded from lancescript
    poptime = os.time()
    while true do
        if PAD.IS_CONTROL_JUST_RELEASED(18, 18) then
            if os.time() - poptime > 0.1 then
                break
            end
        end
        native_invoker.begin_call()
        native_invoker.push_arg_string("ALERT")
        native_invoker.push_arg_string("JL_INVITE_ND")
        native_invoker.push_arg_int(2)
        native_invoker.push_arg_string("")
        native_invoker.push_arg_bool(true)
        native_invoker.push_arg_int(-1)
        native_invoker.push_arg_int(-1)
        native_invoker.push_arg_string(l1)
        native_invoker.push_arg_int(0)
        native_invoker.push_arg_bool(true)
        native_invoker.push_arg_int(0)
        native_invoker.end_call("701919482C74B5AB")
        util.yield()
    end
end

----请求纳米无人机
function RequestNanoDrone()
    local global = 1963795 --RequestNanoDrone --https://github.com/4d72526f626f74/MrRobot/blob/main/MrRobot/utils/script_globals
    local address = memory.script_global(global)
    memory.write_int(address, memory.read_int(address) | 0x1C00000)
    --https://github.com/4d72526f626f74/MrRobot/blob/3186d22dbcf5093f72e8a8a6a479bf37e858e616/MrRobot/modules/online#L723
end


----自动加入游戏
function autoaccept()
    local message_hash = HUD.GET_WARNING_SCREEN_MESSAGE_HASH()
    local paused = HUD.IS_PAUSE_MENU_ACTIVE()
    for invite_string as hash do
        if message_hash == MISC.GET_HASH_KEY(hash) and not paused then
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1.0)
            yield(25)
        end
    end
end
----自动获取主机
function autogethost()
    if not (players.get_host() == PLAYER.PLAYER_ID()) and not util.is_session_transition_active() then
        if not (PLAYER.GET_PLAYER_NAME(players.get_host()) == "**Invalid**") then
            menu.trigger_commands("kick "..PLAYER.GET_PLAYER_NAME(players.get_host()))
            util.yield(200)
        end
    end
    if players.get_name(PLAYER.PLAYER_ID()) == players.get_name(players.get_host()) then
        util.toast("获得主机,已禁用自动获取主机")
        menu.set_value(auto_host, false)
    end
end


-------------作弊者检测
function get_transition_state(pid)
    return memory.read_int(memory.script_global(((2689235 + 1) + (pid * 453)) + 230))
end
function get_interior_player_is_in(pid)
    return memory.read_int(memory.script_global(((2689235 + 1) + (pid * 453)) + 243)) 
end
function GetSpawnState(pid)
    return memory.read_int(memory.script_global(((2657589 + 1) + (pid * 466)) + 232)) -- Global_2657589[PLAYER::PLAYER_ID() /*466*/].f_232
end
function GetInteriorPlayerIsIn(pid)
    return memory.read_int(memory.script_global(((2657589 + 1) + (pid * 466)) + 245)) -- Global_2657589[bVar0 /*466*/].f_245)
end
--玩家无敌检测
function god_detection()
    for _, pid in players.list(false, true, true) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        for _, id in interior_stuff do
            if players.is_godmode(pid) and not players.is_in_interior(pid) and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and GetSpawnState(pid) == 99 and GetInteriorPlayerIsIn(pid) == id then
                util.draw_debug_text(players.get_name(pid) .. " 是无敌模式")
                break
            end
        end
    end 
end
--载具无敌检测
function car_god_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            for i, interior in ipairs(interior_stuff) do
                if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(player_veh) and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(pid) == 99 and get_interior_player_is_in(pid) == interior then
                    util.draw_debug_text(players.get_name(pid) .. "载具处于无敌模式")
                    break
                end
            end
        end
    end  
end
--未发布载具检测
function unreleased_car_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(pid)
        for i, name in ipairs(unreleased_vehicles) do
            if modelHash == util.joaat(name) then
                util.draw_debug_text(players.get_name(pid) .. "正在驾驶未发布的车辆")
            end
        end
    end
end
--无法获得武器检测
function cantgetweapon_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        for i, hash in ipairs(modded_weapons) do
            local weapon_hash = util.joaat(hash)
            if WEAPON.HAS_PED_GOT_WEAPON(ped, weapon_hash, false) and WEAPON.IS_PED_ARMED(ped, 7) then
                util.draw_debug_text(players.get_name(pid) .. "正在使用无法获得武器")
                break
            end
        end
    end
end
--无法获得载具检测
function cantgetvar_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(pid)
        for i, name in ipairs(modded_vehicles) do
            if modelHash == util.joaat(name) then
                util.draw_debug_text(players.get_name(pid) .. " 正在驾驶无法获得的载具,很有可能是作弊者")
                break
            end
        end
    end
end
--室内使用武器检测
function usingweapon_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if players.is_in_interior(pid) and WEAPON.IS_PED_ARMED(player, 7) then
            util.draw_debug_text(players.get_name(pid) .. " 正在室内使用武器,极大可能是作弊者")
            break
        end
    end
end
--超级驾驶检测
function supercar_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local veh_speed = (ENTITY.GET_ENTITY_SPEED(vehicle)* 2.236936)
        local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
        if class ~= 15 and class ~= 16 and veh_speed >= 180 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1) and (players.get_vehicle_model(pid) ~= util.joaat("oppressor") or players.get_vehicle_model(pid) ~= util.joaat("oppressor2")) then
            util.toast(players.get_name(pid) .. " 正在使用超级驾驶")
            break
        end
    end
end
--超级跑检测
function superrun_detection()
    for _, pid in ipairs(players.list(true, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local ped_speed = (ENTITY.GET_ENTITY_SPEED(ped)* 2.236936)
        if not util.is_session_transition_active() and get_interior_player_is_in(pid) == 0 and get_transition_state(pid) ~= 0 
        and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_IN_ANY_VEHICLE(ped, false)
        and not TASK.IS_PED_STILL(ped) and not PED.IS_PED_JUMPING(ped) and not ENTITY.IS_ENTITY_IN_AIR(ped) and not PED.IS_PED_CLIMBING(ped) and not PED.IS_PED_VAULTING(ped)
        and v3.distance(ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false), players.get_position(pid)) <= 300.0 and ped_speed > 25 then -- fastest run speed is about 18ish mph but using 25 to give it some headroom to prevent false positives
            util.toast(players.get_name(pid) .. " 是超级跑")
            break
        end
    end
end
--观看检测
function lookingyou_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local cam_dist = v3.distance(players.get_position(PLAYER.PLAYER_ID()), players.get_cam_pos(pid))
        local ped_dist = v3.distance(players.get_position(PLAYER.PLAYER_ID()), players.get_position(pid))
        if cam_dist < 20.0 and not PED.IS_PED_DEAD_OR_DYING(ped) and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and pid != PLAYER.PLAYER_ID() or players.get_spectate_target(pid) == PLAYER.PLAYER_ID() then
            yield(1000)
            if ped_dist > 35.0 or players.get_spectate_target(pid) == PLAYER.PLAYER_ID() then
                if players.get_name(pid) != "UndiscoveredPlayer" and not PED.IS_PED_DEAD_OR_DYING(ped) then
                    util.toast(players.get_name(pid) .. " 正在观看你")
                    break
                end
            end
        end
    end
end
--传送检测
function tp_detection()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_DEAD_OR_DYING(ped) then
            local oldpos = players.get_position(pid)
            util.yield(1000)
            local currentpos = players.get_position(pid)
            for i, interior in ipairs(interior_stuff) do
                if v3.distance(oldpos, currentpos) > 500 and oldpos.x ~= currentpos.x and oldpos.y ~= currentpos.y and oldpos.z ~= currentpos.z 
                and get_transition_state(pid) ~= 0 and get_interior_player_is_in(pid) == interior and PLAYER.IS_PLAYER_PLAYING(pid) and players.exists(pid) then
                    util.toast(players.get_name(pid) .. " 刚刚进行了传送")
                end
            end
        end
    end
end
--改装武器检测
function modified_weapon_detection()
for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        for i, hash in ipairs(modded_weapons) do
            local weapon_hash = util.joaat(hash)
            if WEAPON.HAS_PED_GOT_WEAPON(ped, weapon_hash, false) and (WEAPON.IS_PED_ARMED(ped, 7) or TASK.GET_IS_TASK_ACTIVE(ped, 8) or TASK.GET_IS_TASK_ACTIVE(ped, 9)) then
                util.toast(players.get_name(pid) .. " 使用修改过的武器 " .. "(" .. hash .. ")")
                break
            end
        end
    end
end
--改装载具检测
function modified_vehicles_detection()
for _, pid in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(pid)
        for i, name in ipairs(modded_vehicles) do
            if modelHash == util.joaat(name) then
                util.draw_debug_text(players.get_name(pid) .. " 正在驾驶改装载具")
                break
            end
        end
    end
end


function roundDecimals(float, decimals)
    decimals = 10 ^ decimals
    return math.floor(float * decimals) / decimals
end

----部分载具功能
--引擎控制
function toggle_player_vehicle_engine(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. "不在车里:D")
    else
        local is_running = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(player_vehicle)
        if request_control(player_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(player_vehicle, not is_running, true, true)
            util.toast(players.get_name(pid) .. "发动机已切换")
        else
            util.toast("无法控制车辆.")
        end
    end
end
--摧毁引擎
function break_player_vehicle_engine(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. "不在车里:D")
    else
        if request_control(player_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(player_vehicle, -10.0)
            util.toast(players.get_name(pid) .. "他的引擎坏了")
        else
            util.toast("无法控制他们的车辆")
        end
    end
end
--向前推进
function boost_player_vehicle_forward(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. "不在车里:D")
    else
        request_control(player_vehicle)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_vehicle, 1, 0.0, 1000.0, 0.0, true, true, true, true)
        util.toast(players.get_name(pid) .. "车辆猛冲")
    end
end
--停止车辆
function stop_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. "不在车里:D")
    else
        request_control(player_vehicle)
        VEHICLE.BRING_VEHICLE_TO_HALT(player_vehicle, 0.0, 1, false)
        util.toast(players.get_name(pid) .. "车辆停止")
    end
end
--倒置车辆
function flip_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. "不在车里:D")
    else
        request_control(player_vehicle)
        local heading = ENTITY.GET_ENTITY_HEADING(player_vehicle)
        ENTITY.SET_ENTITY_ROTATION(player_vehicle, 0, 180, -heading, 1, true)
        util.toast(players.get_name(pid) .. "车辆翻转")
    end
end
--车辆翻转180度
function turn_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. "不在车里:D")
    else
        request_control(player_vehicle)
        local heading = ENTITY.GET_ENTITY_HEADING(player_vehicle)
        local alter_heading = heading >= 180 and heading-180 or heading+180
        ENTITY.SET_ENTITY_ROTATION(player_vehicle, 0, 0, alter_heading, 2, true)
        util.toast(players.get_name(pid) .. "车辆转弯")
    end
end
--修复载具
function repair_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " 不在车里:D")
    else
        if request_control(player_vehicle) then
            VEHICLE.SET_VEHICLE_FIXED(player_vehicle)
            util.toast(players.get_name(pid) .. "修理完成")
        else
            util.toast("无法控制车辆")
        end
    end
end
-----弹飞载具
function launch_up_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " 不在车中:D")
    else
        if request_control(player_vehicle) then
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_vehicle, 1, 0.0, 0.0, 1000.0, true, true, true, true)
            util.toast(players.get_name(pid) .. "'已发射.")
        else
            util.toast("无法控制车辆")
        end
    end
end

----鬼畜载具
function Demon_veh(pid,toggle)
    glitchVeh = toggle
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
    local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
    local veh_model = players.get_vehicle_model(pid)
    local ped_hash = util.joaat("a_m_m_acult_01")
    local object_hash = util.joaat("prop_ld_ferris_wheel")
    request_model(ped_hash)
    request_model(object_hash)
    
    while glitchVeh do
        if v3.distance(ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false), players.get_position(pid)) > 1000.0 and v3.distance(pos, players.get_cam_pos(PLAYER.PLAYER_ID())) > 1000.0 then
            util.toast("距离玩家太远了:/")
            menu.set_value(glitchVehCmd, false);
            break 
        end
        if not PED.IS_PED_IN_VEHICLE(ped, player_veh, false) then 
            util.toast("玩家不在车里")
            menu.set_value(glitchVehCmd, false);
            break 
        end
        if not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
            util.toast("车上没空位了")
            menu.set_value(glitchVehCmd, false);
            break 
        end
        local seat_count = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(veh_model)
        local glitch_obj = entities.create_object(object_hash, pos)
        local glitched_ped = entities.create_ped(26, ped_hash, pos, 0)
        local things = {glitched_ped, glitch_obj}
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(glitch_obj)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(glitched_ped)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(glitch_obj, glitched_ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true, 0)
        for i, spawned_objects in ipairs(things) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(spawned_objects)
            ENTITY.SET_ENTITY_VISIBLE(spawned_objects, false)
            ENTITY.SET_ENTITY_INVINCIBLE(spawned_objects, true)
        end
        for i = 0, seat_count -1 do
            if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
                local emptyseat = i
                for l = 1, 25 do
                    PED.SET_PED_INTO_VEHICLE(glitched_ped, player_veh, emptyseat)
                    ENTITY.SET_ENTITY_COLLISION(glitch_obj, true, true)
                    util.yield()
                end
            end
        end
        if glitched_ped ~= nil then
            entities.delete(glitched_ped) 
        end
        if glitch_obj ~= nil then 
            entities.delete(glitch_obj)
        end
    end
end




--喇叭加速
function horn_boost(pid)
    local ped = PLAYER.GET_PLAYER_PED(pid)
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    request_control(veh)
    VEHICLE.SET_VEHICLE_MOD(veh, 14, - 1, false)
    if AUDIO.IS_HORN_ACTIVE(veh) then
        VEHICLE.SET_VEHICLE_ALARM(veh, false)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0.0, 1.0, 0.0, true, true, true, true)
    end
end
---喇叭跳跳车
function car_jump(pid)
    local ped = PLAYER.GET_PLAYER_PED(pid)
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    request_control(veh)
    VEHICLE.SET_VEHICLE_MOD(veh, 14, - 1, false)
    if AUDIO.IS_HORN_ACTIVE(veh) then
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0.0, 0.0, 0.7, true, true, true, true) -- alternatively, VEHICLE.SET_VEHICLE_FORWARD_SPEED(...) -- not tested
    end
end

---喇叭传送
function horn_tp(on)
    horn_boost_tpd = on
    if horn_boost_tpd then
        local msg = "按 ~%s~ 使用传送"
        util.show_corner_help(msg:format("INPUT_VEH_HORN"))
        while horn_boost_tpd do
            if PAD.IS_CONTROL_PRESSED(0, 46) then
                tp_closest_vehicle()
                util.yield(200)
            end
            util.yield()
        end
    end
end




----玩家自检
function is_player_modder(pid)
    local suffix = players.is_marked_as_modder(pid) and "已触发作弊者检测" or " 尚未触发作弊者检测"
    chat.send_message(players.get_name(pid) .. suffix, true, true, false)
end


----现实时间
local irlTime = false
local setClockCommand = menu.ref_by_path('World>Atmosphere>Clock>Time', 37)
local smoothTransitionCommand = menu.ref_by_path('World>Atmosphere>Clock>Smooth Transition', 37)
function Real_world_time(toggle)
    irlTime = toggle
    if menu.get_value(smoothTransitionCommand) 
	then 
		menu.trigger_command(smoothTransitionCommand) 
end
    util.create_tick_handler(function()
        		menu.trigger_command(setClockCommand, os.date('%H:%M:%S'))
        return irlTime
    end)
end



----全局电磁脉冲
function veh_EMP()
    for k, pid in pairs(players.list(true, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
        FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 65, 999, false, true, 0)
    end
end 

----升级载具
function upgrade_vehicle(vehicle)
    for i = 0, 49 do
        local num = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
        VEHICLE.SET_VEHICLE_MOD(vehicle, i, num - 1, true)
    end
end


----加速垫
function jiasudian(pid)
    local coords = players.get_position(pid)
    coords.z = coords.z - 0.3
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local heading = ENTITY.GET_ENTITY_HEADING(player)
    local heading = heading + 80
    local boostpad = entities.create_object(3287988974, coords)
    ENTITY.SET_ENTITY_HEADING(boostpad, heading)
end
function sigejiasudian(pid)
    local coords = players.get_position(pid)
    coords.z = coords.z - 0.3
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local heading = ENTITY.GET_ENTITY_HEADING(player)
    local boostpad = entities.create_object(-388593496, coords)
    ENTITY.SET_ENTITY_HEADING(boostpad, heading)
end
function jiansudai(pid)
    local coords = players.get_position(pid)
    coords.z = coords.z - 0.6
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local heading = ENTITY.GET_ENTITY_HEADING(player)
    local heading = heading + 80
    local boostpad = entities.create_object(-227275508, coords)
    ENTITY.SET_ENTITY_HEADING(boostpad, heading)
end


---主机崩
function hostcrash(pid)
    local self_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
    menu.trigger_commands("tpmazehelipad")
    ENTITY.SET_ENTITY_COORDS(self_ped, -6170, 10837, 40, true, false, false)
    util.yield(1000)
    menu.trigger_commands("tpmazehelipad")
end


-------射出npc
local replayInterface1 = memory.read_long(memory.rip(memory.scan("48 8D 0D ? ? ? ? 48 8B D7 E8 ? ? ? ? 48 8D 0D ? ? ? ? 8A D8 E8 ? ? ? ? 84 DB 75 13 48 8D 0D") + 3))
local pedInterface1 = memory.read_long(replayInterface1 + 0x0018)
function shechuNPC()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
	local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then 
		pedspawn = PED.CREATE_RANDOM_PED(pos.x, pos.y, pos.z)
		ENTITY.SET_ENTITY_ROTATION(pedspawn, rot.x, rot.y, rot.z, 1, false)
		ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(pedspawn, 1, 0, 1000, 0, false, true, true, true)
	end
    local pedamount = memory.read_int(pedInterface1 + 0x0110)
    if pedamount > 240 then
        Normal_clearance()
    end
end


------------传送载具
function get_ground_z(coords)
    local start_time = os.time()
    while true do
        if os.time() - start_time >= 5 then
            return nil
        end
        local success, est = util.get_ground_z(coords['x'], coords['y'], coords['z']+2000)
        if success then
            return est
        end
        util.yield()
    end
end
function get_waypoint_coords()
    local coords = HUD.GET_BLIP_COORDS(HUD.GET_FIRST_BLIP_INFO_ID(8))
    if coords['x'] == 0 and coords['y'] == 0 and coords['z'] == 0 then
        return nil
    else
        local estimate = get_ground_z(coords)
        if estimate then
            coords['z'] = estimate
        end
        return coords
    end
end
function tp_player_car_to_coords(pid, coord)
    local name = PLAYER.GET_PLAYER_NAME(pid)
    if robustmode then
        menu.trigger_commands("spectate" .. name .. " on")
        util.yield(1000)
    end
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
    if car ~= 0 then
        request_control(car)
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(car) then
            for i=1, 3 do
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(car, coord['x'], coord['y'], coord['z'], false, false, false)
            end
        end
    end
end
function tpcartome(pid)
    tp_player_car_to_coords(pid, ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true))
end
function tocartopoint(pid)
    local c = get_waypoint_coords()
    if c ~= nil then
        tp_player_car_to_coords(pid, c)
    end
end
function tptomaze(pid)
    local c = {}
    c.x = -75.261375
    c.y = -818.674
    c.z = 326.17517
    tp_player_car_to_coords(pid, c)
end
function tptounderwater(pid)
    local c = {}
    c.x = 4497.2207
    c.y = 8028.3086
    c.z = -32.635174
    tp_player_car_to_coords(pid, c)
end
function tptohighair(pid)
    local c = {}
    c.x = -75
    c.y = -818
    c.z = 2400
    tp_player_car_to_coords(pid, c)
end
function tolsc(pid)
    local c = {}
    c.x = -353.84512
    c.y = -135.59108
    c.z = 39.009624
    tp_player_car_to_coords(pid, c)
end
function tpscp(pid)
    local c = {}
    c.x = 1642.8401
    c.y = 2570.7695
    c.z = 45.564854
    tp_player_car_to_coords(pid, c)
end
function tocell(pid)
    local c = {}
    c.x = 1737.1896
    c.y = 2634.897
    c.z = 45.56497
    tp_player_car_to_coords(pid, c)
end


---------载具随机升级
function control_vehicle(pid, callback, opts)
    local vehicle = get_player_vehicle_in_control(pid, opts)
    if vehicle > 0 then
        callback(vehicle)
    elseif opts == nil or opts.silent ~= true then
        util.toast("玩家不在车内或不在范围内。")
    end
end
function randomupdatcar(pid)
    control_vehicle(pid, function(vehicle)
        VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
        for x = 0, 49 do
            local max = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, x)
            VEHICLE.SET_VEHICLE_MOD(vehicle, x, math.random(-1, max))
        end
        VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, math.random(-1,5))
        for x = 17, 22 do
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, math.random() > 0.5)
        end
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, math.random(0, 255), math.random(0, 255), math.random(0, 255))
        VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, math.random(0, 255), math.random(0, 255), math.random(0, 255))
    end)
end

--------旋转的陀螺
function request_control_of_entity_once(ent)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) and util.is_session_started() then
        local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(ent)
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
    end
end
function carspin(pid)
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
    if car ~= 0 then
        request_control_of_entity_once(car)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(car, 4, 0.0, 0.0, 300.0, 0, true, true, false, true, true, true)
    end
end


-------电磁脉冲
function caremp(pid)
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
    if car ~= 0 then
        local c = ENTITY.GET_ENTITY_COORDS(car)
        FIRE.ADD_EXPLOSION(c.x, c.y, c.z, 83, 100.0, false, true, 0.0)
    end
end




----删除玩家载具
function deleplayercar(pid)
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local player_veh = PED.GET_VEHICLE_PED_IS_USING(player)
    if not PED.IS_PED_IN_ANY_VEHICLE(player, true) then
        util.toast("玩家不在载具哦")
        return
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(player_veh)
    util.yield(500)
    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(player_veh) then
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(player_veh, false, false)
        entities.delete(player_veh)
    else
        util.toast("无法控制此玩家载具. :/")
    end
end
----禁用载具
function disable_vehicle(pid)
    if PLAYER.GET_PLAYER_PED(pid) ~= 0 then
        if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.GET_PLAYER_PED(pid)) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(pid), false)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED(pid))
        else
            local veh2 = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(PLAYER.GET_PLAYER_PED(pid))
            entities.delete(veh2)
        end
    end
end
----禁用驾驶
function disable_drive(toggled, pid)
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED(pid), false)
    request_control(vehicle)
    VEHICLE.SET_VEHICLE_UNDRIVEABLE(vehicle, toggled)
end


--声音崩溃V1
function soundcrashv1(pid)
local time = util.current_time_millis() + 2000
        while time > util.current_time_millis() do
            local pos=ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
            for i = 1, 10 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1,"10s",pos.x,pos.y,pos.z,"MP_MISSION_COUNTDOWN_SOUNDSET",true, 70, false)
            end
            util.yield(0)
        end
    end 

--声音崩溃V2
function soundcrashv2(pid)
local time = util.current_time_millis() + 2000
        while time > util.current_time_millis() do
            local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
            for i = 1, 20 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, 'Event_Message_Purple', pos.x, pos.y, pos.z, 'GTAO_FM_Events_Soundset', true, 1000, false)
                AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', pos.x, pos.y, pos.z, 'GTAO_FM_Events_Soundset', true, 1000, false)
            end
            util.yield()
        end	
    end


------踢出载具v1
function kickcar(pid)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
        DECORATOR.DECOR_REGISTER("Player_Vehicle", 3)
        DECORATOR.DECOR_SET_INT(player_veh,"Player_Vehicle", 0)
    else
        util.toast("玩家不在车内哦")
    end
end


--------吊射炮
function diaoshepao(asset)
    local request_time = os.time()
    STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end

------自动驾驶
function get_blip_coords(blipId)
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(blipId)
    if blip ~= 0 then return HUD.GET_BLIP_COORDS(blip) end
    return v3(0, 0, 0)
end


function player_toggle_loop(root, pid, menu_name, command_names, help_text, callback)
    return menu.toggle_loop(root, menu_name, command_names, help_text, function()
        if not players.exists(pid) then util.stop_thread() end
    callback()
    end)
end

------自动加血
function autoBloodReture()
    local health = ENTITY.GET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID())
    if ENTITY.GET_ENTITY_MAX_HEALTH(PLAYER.PLAYER_PED_ID()) == health then return end
    ENTITY.SET_ENTITY_HEALTH(PLAYER.PLAYER_PED_ID(), health + 5, 0)
    util.yield(255)
end

-------在掩体后时补充生命值
function healthincover()
    if PED.IS_PED_IN_COVER(PLAYER.PLAYER_PED_ID(), false) then
		PLAYER1._SET_PLAYER_HEALTH_RECHARGE_LIMIT(PLAYER.PLAYER_ID(), 1.0)
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), 15.0)
	else
		PLAYER1._SET_PLAYER_HEALTH_RECHARGE_LIMIT(PLAYER.PLAYER_ID(), 0.5)
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), 1.0)
	end
end

---------好友列表
function get_friend_count()
    native_invoker.begin_call();native_invoker.end_call("203F1CFD823B27A4");
    return native_invoker.get_return_value_int();
end
function get_frined_name(friendIndex)
    native_invoker.begin_call();native_invoker.push_arg_int(friendIndex);native_invoker.end_call("4164F227D052E293");return native_invoker.get_return_value_string();
end
function gen_fren_funcs(name)
	local balls = menu.list(frendlist,name, {}, "")
    if balls then
        menu.divider(balls ,name)
        menu.action(balls,"加入战局", {}, "",function()
            menu.trigger_commands("join "..name)
        end)
        menu.action(balls,"观看玩家", {}, "",function()
            menu.trigger_commands("namespectate "..name)
        end)
        menu.action(balls,"邀请玩家", {}, "",function()
            menu.trigger_commands("invite "..name)
        end)
        menu.action(balls,"玩家档案", {}, "",function()
            menu.trigger_commands("nameprofile "..name)
        end)
        menu.readonly(balls, "复制昵称: ", name)
    end
end


------导弹
obj_pp = {"prop_cs_dildo_01", "prop_ld_bomb_01", "prop_sam_01"}
opt_pp = {"小导弹", "中导弹", "大导弹", "移除导弹"}
function dd02(index, value, click_type)
    pluto_switch index do
        case 1:
            attach_to_player("prop_cs_dildo_01", 57597, -0.1, 0.15, 0, 0, 90, 90)
            break
        case 2:
            attach_to_player("prop_ld_bomb_01", 57597, -0.1, 0.6, 0, 0, 180, 180)
            break
        case 3:
            attach_to_player("prop_sam_01", 57597, -0.1, 1.7, 0, 0, 180, 180)
            break
        case 4:
            for k, model in pairs(obj_pp) do 
                delete_object(model)
            end
            break
    end
end

-------喷火
function firewingscale(value)
    fireWings3Settings.scale = value / 10
end
function firewingcolour(colour)
    fireWings3Settings.colour = colour
end
fireBreathSettings = {
    scale = 0.3,
    colour = {r = 1, g = 127 / 255, b = 127 / 255, a = 1},
    on = false,
    y = { value = 0.12, still = 0.12, walk =  0.22, sprint = 0.32, sneak = 0.35 },
    z = { value = 0.58, still = 0.58, walk =  0.45, sprint = 0.38, sneak = 0.35 },
}
function transitionValue(value, target, step)
    if value == target then return value end
    return value + step * ( value > target and -1 or 1 )
end
function fireBreathSettings:changePos(movementType)
    self.z.value = transitionValue(self.z.value, self.z[movementType], 0.01)
    self.y.value = transitionValue(self.y.value, self.y[movementType], 0.01)
end
function firebreathxxx(toggle)
    if toggle then
        request_ptfx_asset('weap_xs_vehicle_weapons')
        GRAPHICS.USE_PARTICLE_FX_ASSET('weap_xs_vehicle_weapons')
        fireBreathSettings.ptfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE('muz_xs_turret_flamethrower_looping', PLAYER.PLAYER_PED_ID(), 0, 0.12, 0.58, 30, 0, 0, 0x8b93, fireBreathSettings.scale, false, false, false, 0, 0, 0, 0)
        GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fireBreathSettings.ptfx, fireBreathSettings.colour.r, fireBreathSettings.colour.g, fireBreathSettings.colour.b, false)
    else
        GRAPHICS.STOP_PARTICLE_FX_LOOPED(fireBreathSettings.ptfx, false)
        GRAPHICS.REMOVE_PARTICLE_FX(fireBreathSettings.ptfx, true)
        STREAMING.REMOVE_NAMED_PTFX_ASSET('weap_xs_vehicle_weapons')
    end
end
function firebreathscale(value)
    fireBreathSettings.scale = value / 10
    GRAPHICS.SET_PARTICLE_FX_LOOPED_SCALE(fireBreathSettings.ptfx, fireBreathSettings.scale)
end
function firebreathcolour(colour)
    fireBreathSettings.colour = colour
    GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fireBreathSettings.ptfx, fireBreathSettings.colour.r, fireBreathSettings.colour.g, fireBreathSettings.colour.b, false)
end




----循环爆炸所有人
function getTotalDelayabcd(delayTable)
    return (delayTable.ms + (delayTable.s * 1000) + (delayTable.min * 1000 * 60))
end


----射击
function getTotalDelay(delayTable)
    return (delayTable.ms + (delayTable.s * 1000) + (delayTable.min * 1000 * 60))
end

----瞄准惩罚
local yeetMultiplier = 1000
local yeetRange = 1000
local stormDelay = new.delay(1, 0, 0) 
expSettings = {
    camShake = 0, invisible = false, audible = true, noDamage = false, owned = false, blamed = false, blamedPlayer = false, expType = 0,
    colour = new_colour(255, 0, 255 )
}
function explosion(pos, expSettings)
    if expSettings.currentFx then
        if expSettings.currentFx.exp then
            FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, expSettings.currentFx.exp, 10, expSettings.audible, true, 0, expSettings.noDamage)
            FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 1, 10, false, true, expSettings.camShake, expSettings.noDamage)
        else
            FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 1, 10, false, true, expSettings.camShake, expSettings.noDamage)
        end
        if not expSettings.invisible then
            addFx(pos, expSettings.currentFx, expSettings.colour)
        end
    else
        FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, expSettings.expType, 10, expSettings.audible, expSettings.invisible, expSettings.camShake, expSettings.noDamage)
    end
end


----爆炸
function explodePlayer(ped, loop, expSettings)
    pos = ENTITY.GET_ENTITY_COORDS(ped)
    blamedPlayer = PLAYER.PLAYER_PED_ID()
    if expSettings.blamedPlayer and expSettings.blamed then
        blamedPlayer = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(expSettings.blamedPlayer)
    elseif expSettings.blamed then
        playerList = players.list(true, true, true)
        blamedPlayer = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerList[math.random(1, #playerList)])
    end
    if not loop and PED.IS_PED_IN_ANY_VEHICLE(ped, true) then
        for i = 0, 50, 1 do --50 explosions to account for most armored vehicles
            if expSettings.owned or expSettings.blamed then
                ownedExplosion(blamedPlayer, pos, expSettings)
            else
                explosion(pos, expSettings)
            end
            util.yield(10)
        end
    elseif expSettings.owned or expSettings.blamed then
        ownedExplosion(blamedPlayer, pos, expSettings)
    else
        explosion(pos, expSettings)
    end
    util.yield(10)
end


----瞄准惩罚
function getNonWhitelistedPlayers(whitelistListTable, whitelistGroups, whitelistedName)
    playerList = players.list(whitelistGroups.user, whitelistGroups.friends, whitelistGroups.strangers)
    notWhitelisted = {}
    for i = 1, #playerList do
        if not whitelistListTable[playerList[i]] and not (players.get_name(playerList[i]) == whitelistedName) then
            notWhitelisted[#notWhitelisted + 1] = playerList[i]
        end
    end
    return notWhitelisted
end
whitelistGroups = {user = true, friends = true, strangers  = true}
whitelistListTable = {}
whitelistedName = false
karma = {}
function isAnyPlayerTargetingEntity(playerPed)
    local playerList = getNonWhitelistedPlayers(whitelistListTable, whitelistGroups, whitelistedName)
    for k, playerPid in pairs(playerList) do
        if PLAYER.IS_PLAYER_TARGETTING_ENTITY(playerPid, playerPed) or PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(playerPid, playerPed) then
            karma[playerPed] = {
                pid = playerPid,
                ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerPid)
            }
            return true
        end
    end
    karma[playerPed] = nil
    return false
end

----瞄准惩罚
function playerIsTargetingEntity(playerPed)
    local playerList = getNonWhitelistedPlayers(whitelistListTable, whitelistGroups, whitelistedName)
    for k, playerPid in pairs(playerList) do
        if PLAYER.IS_PLAYER_TARGETTING_ENTITY(playerPid, playerPed) or PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(playerPid, playerPed) then
            karma[playerPed] = {
                pid = playerPid,
                ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerPid)
            }
            return true
        end
    end
    karma[playerPed] = nil
    return false
end


----轨迹
local effect = Effect.new("scr_rcpaparazzo1", "scr_mich4_firework_sparkle_spawn")
local effects = {}
function removeFxs(effects)
	for _, effect in ipairs(effects) do
		GRAPHICS.STOP_PARTICLE_FX_LOOPED(effect, 0)
		GRAPHICS.REMOVE_PARTICLE_FX(effect, 0)
	end
end
function locus_color(newColour)
    locus_colour = newColour
end
function Character_locus()
    if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
        STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
        return
    end
    if timer.elapsed() >= 1000 then
        removeFxs(effects); effects = {}
        timer.reset()
    end
    if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), true) then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        local minimum, maximum = v3.new(), v3.new()
        MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minimum, maximum)
        local offsets = {v3(minimum.x, minimum.y, 0.0), v3(maximum.x, minimum.y, 0.0)}
        for _, offset in ipairs(offsets) do
            GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
            local fx =
            GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(
                effect.name,
                vehicle,
                offset.x,
                offset.y,
                0.0,
                0.0,
                0.0,
                0.0,
                0.7, --scale
                false, false, false,
                0, 0, 0, 0
            )
            GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, locus_colour.r, locus_colour.g, locus_colour.b, 0)
            table.insert(effects, fx)
        end
    elseif ENTITY.DOES_ENTITY_EXIST(PLAYER.PLAYER_PED_ID()) then
        for _, boneId in ipairs(bones) do
            GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
            local fx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
                effect.name,
                PLAYER.PLAYER_PED_ID(),
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                PED.GET_PED_BONE_INDEX(PLAYER.PLAYER_PED_ID(), boneId),
                0.7, --scale
                false, false, false,
                0, 0, 0, 0
            )
            GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, locus_colour.r, locus_colour.g, locus_colour.b, 0)
            table.insert(effects, fx)
        end
    end
end
function stop_Character_locus()
    removeFxs(effects)
    effects = {}
end



--------激光眼
function request_ptfx_asset_lasereyes(asset)
    local request_time = os.time()
    STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end
function laser_eyes()
    local weaponHash = util.joaat("weapon_heavysniper_mk2")
    local dictionary = "weap_xs_weapons"
    local ptfx_name = "bullet_tracer_xs_sr"
    local camRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
    if PAD.IS_CONTROL_PRESSED(0, 51) then
        local inst = v3.new()
        v3.set(inst,CAM.GET_FINAL_RENDERED_CAM_ROT(2))
        local tmp = v3.toDir(inst)
        v3.set(inst, v3.get(tmp))
        v3.mul(inst, 1000)
        v3.set(tmp, CAM.GET_FINAL_RENDERED_CAM_COORD())
        v3.add(inst, tmp)
        camAim_x, camAim_y, camAim_z = v3.get(inst)
        local ped_model = ENTITY.GET_ENTITY_MODEL(PLAYER.PLAYER_PED_ID())
        local left_eye_id = 0
        local right_eye_id = 0
        pluto_switch ped_model do 
            case 1885233650:
            case -1667301416:
                left_eye_id = 25260
                right_eye_id = 27474
                break
            case 225514697:
            default:
                left_eye_id = 5956
                right_eye_id = 6468
        end
        local boneCoord_L = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(PLAYER.PLAYER_PED_ID(), PED.GET_PED_BONE_INDEX(PLAYER.PLAYER_PED_ID(), left_eye_id))
        local boneCoord_R = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(PLAYER.PLAYER_PED_ID(), PED.GET_PED_BONE_INDEX(PLAYER.PLAYER_PED_ID(), right_eye_id))
        if ped_model == util.joaat("mp_f_freemode_01") then 
            boneCoord_L.z += 0.02
            boneCoord_R.z += 0.02
        end
        camRot.x += -90
        request_ptfx_asset_lasereyes(dictionary)
        GRAPHICS.USE_PARTICLE_FX_ASSET(dictionary)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(ptfx_name, boneCoord_L.x, boneCoord_L.y, boneCoord_L.z, camRot.x, camRot.y, camRot.z, 2, 0, 0, 0, false)
        GRAPHICS.USE_PARTICLE_FX_ASSET(dictionary)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(ptfx_name, boneCoord_R.x, boneCoord_R.y, boneCoord_R.z, camRot.x, camRot.y, camRot.z, 2, 0, 0, 0, false)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(boneCoord_L.x, boneCoord_L.y, boneCoord_L.z, camAim_x, camAim_y, camAim_z, 100, true, weaponHash, PLAYER.PLAYER_PED_ID(), false, true, 100, PLAYER.PLAYER_PED_ID(), 0)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(boneCoord_R.x, boneCoord_R.y, boneCoord_R.z, camAim_x, camAim_y, camAim_z, 100, true, weaponHash, PLAYER.PLAYER_PED_ID(), false, true, 100, PLAYER.PLAYER_PED_ID(), 0)
    end
end





--------原力
function get_ped_nearby_vehicles(ped, maxVehicles)
	maxVehicles = maxVehicles or 16
	local pVehicleList = memory.alloc((maxVehicles + 1) * 8)
	memory.write_int(pVehicleList, maxVehicles)
	local vehiclesList = {}
	for i = 1, PED.GET_PED_NEARBY_VEHICLES(ped, pVehicleList) do
		vehiclesList[i] = memory.read_int(pVehicleList + i*8)
	end
	return vehiclesList
end



-------背藏武器
function attachweapon(spawnweapon)
	if (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 416676503) or (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 690389602) then
		ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x192A), 0.15, 0, 0.13, 270, 0, 0, false, true, false, false, 1, true, 0)
	end
	if (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == -728555052) or (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == -1609580060) then
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_bat")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), 0.3, -0.18, -0.15, 0, 300, 0, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_crowbar")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x192A), 0.2, 0, 0.13, 0, 270, 90, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_battleaxe")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), 0.2, -0.18, -0.1, 0, 300, 0, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_golfclub")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), 0.2, -0.18, -0.1, 0, 300, 0, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_hatchet")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), 0.2, -0.18, -0.1, 0, 300, 0, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_poolcue")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), -0.2, -0.18, 0.1, 0, 120, 0, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_stone_hatchet")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), 0.2, -0.18, -0.1, 0, 300, 0, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_knuckle")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x192A), 0.2, 0, 0.13, 0, 270, 90, false, true, false, false, 1, true, 0)
		end
		if not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_bat"))  and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_crowbar")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_battleaxe"))and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_golfclub")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_hatchet")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_poolcue")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_stone_hatchet")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_knuckle")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x192A), 0, 0, 0.13, 0, 90, 270, false, true, false, false, 1, true, 0)
		end
	end
	if (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 1548507267) or (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == -37788308) or (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 1595662460) then	
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_petrolcan")) or (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_hazardcan")) or (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_fertilizercan")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), 0, -0.18, -0, 0, 90, 0, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_proxmine")) or (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_stickybomb")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x192A), 0.2, 0, 0.13, 0, 0, 270, false, true, false, false, 1, true, 0)
		end
		if (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_fireextinguisher")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x192A), 0, -0.05, 0.13, 0, 270, 90, false, true, false, false, 1, true, 0)
		end
		if not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_petrolcan")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_hazardcan")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_fertilizercan")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_proxmine")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_stickybomb")) and not (HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped()) == util.joaat("weapon_fireextinguisher")) then
			ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x192A), 0.2, 0, 0.13, 0, 270, 270, false, true, false, false, 1, true, 0)
		end
	end
	if not (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 416676503) and not (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 690389602) and not (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == -728555052) and not (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == -1609580060) and not (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 1548507267) and not (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == -37788308) and not (WEAPON.GET_WEAPONTYPE_GROUP(HUD1._HUD_WEAPON_WHEEL_GET_SELECTED_HASH(plyped())) == 1595662460) then
		ENTITY.ATTACH_ENTITY_TO_ENTITY(spawnweapon, plyped(), PED.GET_PED_BONE_INDEX(plyped(), 0x60F2), 0, -0.18, 0, 180, 220, 0, false, true, false, false, 1, true, 0)
	end
end
function plyped()
	return PLAYER.PLAYER_PED_ID()
end





------地毯飞行
function flynotification123(format, colour, ...)
	assert(type(format) == "string", "msg must be a string, got " .. type(format))
	local msg = string.format(format, ...)
	HUD1._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(colour or self.defaultColour)
	util.BEGIN_TEXT_COMMAND_THEFEED_POST("~BLIP_INFO_ICON~ " .. msg)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER_WITH_TOKENS(true, true)
end

local state = 0
local format0 = "按 ~%s~ ~%s~ ~%s~ ~%s~ 来使用地毯式骑行"
local format1 = "按 ~%s~ 以移动得更快"
function carpetridexx()
    if state == 0 then
		local objHash = util.joaat("p_cs_beachtowel_01_s")
		request_model(objHash)
        request_anim_dict("rcmcollect_paperleadinout@")
		local localPed = PLAYER.PLAYER_PED_ID()
		local pos = ENTITY.GET_ENTITY_COORDS(localPed, false)
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(localPed)
		object = entities.create_object(objHash, pos)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(localPed, object, 0, 0, -0.2, 1.0, 1.0, 1.0,1, false, true, false, false, 0, true, 0)
		ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(object, false, false)
		TASK.TASK_PLAY_ANIM(localPed, "rcmcollect_paperleadinout@", "meditiate_idle", 8.0, -8.0, -1, 1, 0.0, false, false, false)
        flynotification123(format0 .. ".\n" .. format1 .. '.', HudColour.black, "INPUT_MOVE_UP_ONLY", "INPUT_MOVE_DOWN_ONLY", "INPUT_VEH_JUMP", "INPUT_DUCK", "INPUT_VEH_MOVE_UP_ONLY")
		state = 1
	elseif state == 1 then
		HUD.DISPLAY_SNIPER_SCOPE_THIS_FRAME()
		local objPos = ENTITY.GET_ENTITY_COORDS(object, false)
		local camrot = CAM.GET_GAMEPLAY_CAM_ROT(0)
		ENTITY.SET_ENTITY_ROTATION(object, 0, 0, camrot.z, 0, true)
		local forwardV = ENTITY.GET_ENTITY_FORWARD_VECTOR(PLAYER.PLAYER_PED_ID())
		forwardV.z = 0.0
		local delta = v3.new(0, 0, 0)
		local speed = 0.2
		if PAD.IS_CONTROL_PRESSED(0, 61) then
			speed = 1.5
		end
		if PAD.IS_CONTROL_PRESSED(0, 32) then
			delta = v3.new(forwardV)
			delta:mul(speed)
		end
		if PAD.IS_CONTROL_PRESSED(0, 130)  then
			delta = v3.new(forwardV)
			delta:mul(-speed)
		end
		if PAD.IS_DISABLED_CONTROL_PRESSED(0, 22) then
			delta.z = speed
		end
		if PAD.IS_CONTROL_PRESSED(0, 36) then
			delta.z = -speed
		end
		local newPos = v3.new(objPos)
		newPos:add(delta)
		ENTITY.SET_ENTITY_COORDS(object, newPos.x,newPos.y,newPos.z, false, false, false, false)
	end
end
function carpetridexx1()
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
    ENTITY.DETACH_ENTITY(PLAYER.PLAYER_PED_ID(), true, false)
    if ENTITY.DOES_ENTITY_EXIST(object) then
        ENTITY.SET_ENTITY_VISIBLE(object, false, false)
        entities.delete(object)
    end
    state = 0
end




-----CARGO崩溃
function CARGO()
    for pid = 0, 31 do
        local cspped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local TPpos = ENTITY.GET_ENTITY_COORDS(cspped, true)
        local cargobob = CreateVehicle(0XFCFCB68B, TPpos, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()), true)
        local cargobobPos = ENTITY.GET_ENTITY_COORDS(cargobob, true)
        local veh = CreateVehicle(0X187D938D, TPpos, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()), true)
        local vehPos = ENTITY.GET_ENTITY_COORDS(veh, true)
        local newRope = PHYSICS.ADD_ROPE(TPpos.x, TPpos.y, TPpos.z, 0, 0, 10, 1, 1, 0, 1, 1, false, false, false, 1.0, false, 0)
        PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, cargobob, veh, cargobobPos.x, cargobobPos.y, cargobobPos.z, vehPos.x, vehPos.y, vehPos.z, 2, false, false, 0, 0, "Center", "Center")
        util.yield(2500)
        entities.delete(cargobob)
        entities.delete(veh)
        PHYSICS.DELETE_CHILD_ROPE(newRope)
    end
end


--------磁力枪
function get_vehicles_in_player_range(player, radius)
	local vehicles = {}
	local pos = players.get_position(player)
	for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
		local vehPos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
		if pos:distance(vehPos) <= radius then table.insert(vehicles, vehicle) end
	end
	return vehicles
end
local colour = {r = 0, g = 255, b = 255, a = 255}
function draw_marker(type, pos, scale, colour, textureDict, textureName)
	textureDict = textureDict
	textureName = textureName or 0
	GRAPHICS.DRAW_MARKER(
		type,
		pos.x, pos.y, pos.z,
		0.0, 0.0, 0.0,
		0.0, 0.0, 0.0,
		scale, scale, scale,
		colour.r, colour.g, colour.b, colour.a,
		false, false, 0, true, textureDict, textureName, false
	)
end
function rainbow_colour(colour)
	if colour.r > 0 and colour.b == 0 then
		colour.r = colour.r - 1
		colour.g = colour.g + 1
	end

	if colour.g > 0 and colour.r == 0 then
		colour.g = colour.g - 1
		colour.b = colour.b + 1
	end

	if colour.b > 0 and colour.g == 0 then
		colour.r = colour.r + 1
		colour.b = colour.b - 1
	end
end
selectedOpt = 1
function ciliqiang()
    if not PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then return end
	local numVehicles = 0
	local offset = get_offset_from_cam(30.0)
	local vehicles <const> = get_vehicles_in_player_range(PLAYER.PLAYER_ID(), 70.0)
    rainbow_colour(colour)
    draw_marker(28, offset, 0.4, colour)

	for _, vehicle in ipairs(vehicles) do
		if PED.GET_VEHICLE_PED_IS_USING(PLAYER.PLAYER_PED_ID()) ~= vehicle and
		numVehicles < 20 and request_control_once(vehicle) then
			numVehicles = numVehicles + 1
			local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
			local vect = v3.new(offset)
			vect:sub(vehiclePos)
			if selectedOpt == 1 then
				ENTITY.SET_ENTITY_VELOCITY(vehicle, vect.x,vect.y,vect.z)

			elseif selectedOpt == 2 then
				vect:mul(0.5)
				ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, vect.x,vect.y,vect.z, 0.0, 0.0, 0.5, 0, false, false, true, false, false)
			end
		end
	end
end
function szclq(index)
    selectedOpt = index
end






------空袭枪
function kxq()
    local hash <const> = util.joaat("weapon_airstrike_rocket")
	WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
	local raycastResult = get_raycast_result(1000.0)
	if raycastResult.didHit and PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local pos = raycastResult.endCoords
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
			pos.x, pos.y, pos.z + 35.0,
			pos.x, pos.y, pos.z,
			200,
			true,
			hash,
			PLAYER.PLAYER_PED_ID(), true, false, 2500.0
		)
	end
end


-----传送枪
local function write_vector3(address, vector)
	memory.write_float(address + 0x0, vector.x)
	memory.write_float(address + 0x4, vector.y)
	memory.write_float(address + 0x8, vector.z)
end
local function set_entity_coords(entity, coords)
	local fwEntity = entities.handle_to_pointer(entity)
	local CNavigation = memory.read_long(fwEntity + 0x30)
	if CNavigation ~= 0 then
		write_vector3(CNavigation + 0x50, coords)
		write_vector3(fwEntity + 0x90, coords)
	end
end
function csq()
    local raycastResult = get_raycast_result(1000.0)
	if  raycastResult.didHit and PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
		local coords = raycastResult.endCoords
		if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
			coords.z = coords.z + 1.0
			set_entity_coords(PLAYER.PLAYER_PED_ID(), coords)
		else
			local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
			local speed = ENTITY.GET_ENTITY_SPEED(vehicle)
			ENTITY.SET_ENTITY_COORDS(vehicle, coords.x, coords.y, coords.z, false, false, false, false)
			ENTITY.SET_ENTITY_HEADING(vehicle, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
			VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, speed + 3.0)
		end
	end
end

----偷车枪
function steal_car_gun()
    if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
        local ent = get_entity_player_is_aiming_at(PLAYER.PLAYER_ID())
        if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
            if PED.IS_PED_A_PLAYER(driver) then
                local pid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(driver)
                menu.trigger_commands("vehkick".. players.get_name(pid))
            elseif ENTITY.DOES_ENTITY_EXIST(driver) and not PED.IS_PED_A_PLAYER(driver) then
                request_control(driver)
                entities.delete(driver)
            end
            PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ent, -1)
        end
    end
end


------翻滚换弹
function fghd()
    if TASK.GET_IS_TASK_ACTIVE(PLAYER.PLAYER_PED_ID(), 4) and PAD.IS_CONTROL_PRESSED(2, 22) and not PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
        util.yield(900)
        WEAPON.REFILL_AMMO_INSTANTLY(PLAYER.PLAYER_PED_ID())
    end
end


-------手指枪
function shouzhiqiang()
    for id, data in pairs(weapon_stuff) do
        local name = data[1]
        local weapon_name = data[2]
        local projectile = util.joaat(weapon_name)
        request_weapon_asset(projectile)
        menu.toggle(finger_thing, name, {}, "", function(state)
            finger_gund = state
            while finger_gund do
                if memory.read_int(memory.script_global(4521801 + 930)) == 3 then
                    memory.write_int(memory.script_global(4521801 + 935), NETWORK.GET_NETWORK_TIME())
                    local inst = v3.new()
                    v3.set(inst,CAM.GET_FINAL_RENDERED_CAM_ROT(2))
                    local tmp = v3.toDir(inst)
                    v3.set(inst, v3.get(tmp))
                    v3.mul(inst, 1000)
                    v3.set(tmp, CAM.GET_FINAL_RENDERED_CAM_COORD())
                    v3.add(inst, tmp)
                    local x, y, z = v3.get(inst)
                    local fingerPos = PED.GET_PED_BONE_COORDS(PLAYER.PLAYER_PED_ID(), 0xff9, 1.0, 0, 0)
                    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(fingerPos.x, fingerPos.y, fingerPos.z, x, y, z, 1, true, projectile, 0, true, false, 500.0, PLAYER.PLAYER_PED_ID(), 0)
                end
                util.yield(100)
            end
            local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
            MISC.CLEAR_AREA_OF_PROJECTILES(pos.x, pos.y, pos.z, 999999, 0)
        end)
    end
end




function get_offset_from_cam(dist)
	local rot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
	local pos = CAM.GET_FINAL_RENDERED_CAM_COORD()
	local dir = rot:toDir()
	dir:mul(dist)
	local offset = v3.new(pos)
	offset:add(dir)
	return offset
end
function get_raycast_result(dist, flag)
	local result = {}
	flag = flag or TraceFlag.everything
	local didHit = memory.alloc(1)
	local endCoords = v3.new()
	local normal = v3.new()
	local hitEntity = memory.alloc_int()
	local camPos = CAM.GET_FINAL_RENDERED_CAM_COORD()
	local offset = get_offset_from_cam(dist)
	local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
		camPos.x, camPos.y, camPos.z,
		offset.x, offset.y, offset.z,
		flag,
		PLAYER.PLAYER_PED_ID(), 7
	)
	SHAPETEST.GET_SHAPE_TEST_RESULT(handle, didHit, endCoords, normal, hitEntity)
	result.didHit = memory.read_byte(didHit) ~= 0
	result.endCoords = endCoords
	result.surfaceNormal = normal
	result.hitEntity = memory.read_int(hitEntity)
	return result
end
function draw_line(start, to, colour)
	GRAPHICS.DRAW_LINE(start.x,start.y,start.z, to.x,to.y,to.z, colour.r, colour.g, colour.b, colour.a)
end
function draw_rect(pos0, pos1, pos2, pos3, colour)
	GRAPHICS.DRAW_POLY(pos0.x, pos0.y, pos0.z, pos1.x, pos1.y, pos1.z, pos3.x, pos3.y, pos3.z, colour.r, colour.g, colour.b, colour.a)
	GRAPHICS.DRAW_POLY(pos3.x, pos3.y, pos3.z, pos2.x, pos2.y, pos2.z, pos0.x, pos0.y, pos0.z, colour.r, colour.g, colour.b, colour.a)
end
function draw_bounding_box(entity, showPoly, colour)
	if not ENTITY.DOES_ENTITY_EXIST(entity) then
		return
	end
	colour = colour or {r = 255, g = 0, b = 0, a = 255}
	local min = v3.new()
	local max = v3.new()
	MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(entity), min, max)
	min:abs(); max:abs()
	local upperLeftRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, -max.y, max.z)
	local upperRightRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, -max.y, max.z)
	local lowerLeftRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, -max.y, -min.z)
	local lowerRightRear = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, -max.y, -min.z)
	draw_line(upperLeftRear, upperRightRear, colour)
	draw_line(lowerLeftRear, lowerRightRear, colour)
	draw_line(upperLeftRear, lowerLeftRear, colour)
	draw_line(upperRightRear, lowerRightRear, colour)
	local upperLeftFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, min.y, max.z)
	local upperRightFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, min.y, max.z)
	local lowerLeftFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, min.y, -min.z)
	local lowerRightFront = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, min.y, -min.z)
	draw_line(upperLeftFront, upperRightFront, colour)
	draw_line(lowerLeftFront, lowerRightFront, colour)
	draw_line(upperLeftFront, lowerLeftFront, colour)
	draw_line(upperRightFront, lowerRightFront, colour)
	draw_line(upperLeftRear, upperLeftFront, colour)
	draw_line(upperRightRear, upperRightFront, colour)
	draw_line(lowerLeftRear, lowerLeftFront, colour)
	draw_line(lowerRightRear, lowerRightFront, colour)
	if type(showPoly) ~= "boolean" or showPoly then
		draw_rect(lowerLeftRear, upperLeftRear, lowerLeftFront, upperLeftFront, colour)
		draw_rect(upperRightRear, lowerRightRear, upperRightFront, lowerRightFront, colour)
		draw_rect(lowerLeftFront, upperLeftFront, lowerRightFront, upperRightFront, colour)
		draw_rect(upperLeftRear, lowerLeftRear, upperRightRear, lowerRightRear, colour)
		draw_rect(upperRightRear, upperRightFront, upperLeftRear, upperLeftFront, colour)
		draw_rect(lowerRightFront, lowerRightRear, lowerLeftFront, lowerLeftRear, colour)
	end
end

----神指
local targetEntity = NULL
local explosionProof = false
function is_player_pointing()
	return read_global.int(4521801 + 930) == 3
end
function godfinger()
   ------准星
    HUD.SET_TEXT_SCALE(1.0,0.5)
    HUD.SET_TEXT_FONT(0)
    HUD.SET_TEXT_CENTRE(1)
    HUD.SET_TEXT_OUTLINE(0)
    HUD.SET_TEXT_COLOUR(255, 255, 255, 180)
    util.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("·")
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.49997,0.478,0)
  ------神指
    if is_player_pointing() then
		write_global.int(4521801 + 935, NETWORK.GET_NETWORK_TIME())
		if not ENTITY.DOES_ENTITY_EXIST(targetEntity) then
			local flag = TraceFlag.peds | TraceFlag.vehicles | TraceFlag.pedsSimpleCollision | TraceFlag.objects
			local raycastResult = get_raycast_result(500.0, flag)
			if raycastResult.didHit and ENTITY.DOES_ENTITY_EXIST(raycastResult.hitEntity) then
				targetEntity = raycastResult.hitEntity
			end
		else
			local myPos = players.get_position(PLAYER.PLAYER_ID())
			local entityPos = ENTITY.GET_ENTITY_COORDS(targetEntity, true)
			local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
			local distance = myPos:distance(entityPos)
			if distance > 30.0 then distance = 30.0
			elseif distance < 10.0 then distance = 10.0 end
			local targetPos = v3.new(camDir)
			targetPos:mul(distance)
			targetPos:add(myPos)
			local direction = v3.new(targetPos)
			direction:sub(entityPos)
			direction:normalise()
			if ENTITY.IS_ENTITY_A_PED(targetEntity) then
				direction:mul(5.0)
				local explosionPos = v3.new(entityPos)
				explosionPos:sub(direction)
				draw_bounding_box(targetEntity, false, {r = 255, g = 255, b = 255, a = 255})
				set_explosion_proof(PLAYER.PLAYER_PED_ID(), true)
				explosionProof = true
				FIRE.ADD_EXPLOSION(explosionPos.x, explosionPos.y, explosionPos.z, 29, 25.0, false, true, 0.0, true)
			else
				local vel = v3.new(direction)
				local magnitude = entityPos:distance(targetPos)
				vel:mul(magnitude)
				draw_bounding_box(targetEntity, true, {r = 255, g = 255, b = 255, a = 80})
				request_control_once(targetEntity)
				ENTITY.SET_ENTITY_VELOCITY(targetEntity, vel.x, vel.y, vel.z)
			end
		end
	elseif targetEntity ~= NULL then
		timer.reset()
		targetEntity = NULL
	elseif explosionProof and timer.elapsed() > 500 then
		explosionProof = false
		set_explosion_proof(PLAYER.PLAYER_PED_ID(), false)
    end
end



----切碎
function Finely_chopped(pid)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)
    coords.z = coords['z']+2.5
    local hash = util.joaat("buzzard")
    request_model(hash)
    local heli = entities.create_vehicle(hash, coords, ENTITY.GET_ENTITY_HEADING(target_ped))
    VEHICLE.SET_VEHICLE_ENGINE_ON(heli, true, true, false)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(heli)
    ENTITY.SET_ENTITY_INVINCIBLE(heli, true)
    ENTITY.FREEZE_ENTITY_POSITION(heli, true)
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(heli, true, true)
    ENTITY.SET_ENTITY_ROTATION(heli, 180, 0.0, ENTITY.GET_ENTITY_HEADING(target_ped), 1, true)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(heli, coords.x, coords.y, coords.z, true, false, false)
    VEHICLE.SET_VEHICLE_ENGINE_ON(heli, true, true, true)
    util.yield(3000)
    entities.delete(heli)
end


----儿童锁
function Child_Lock(on,pid)
    usingChildLock = on
    if not usingChildLock then return end
    while usingChildLock and NETWORK.NETWORK_IS_PLAYER_ACTIVE(pid) and not util.is_session_transition_active() do
        local vehicle = get_vehicle_player_is_in(pid)
        if ENTITY.DOES_ENTITY_EXIST(vehicle) and request_control_once(vehicle) then
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 4)
        end
        util.yield_once()
    end
    local vehicle = get_vehicle_player_is_in(pid)
    if ENTITY.DOES_ENTITY_EXIST(vehicle) and request_control(vehicle, 1000) then
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
    end
end


----火箭人
function Rocket_Man()
    PED.SET_PED_TO_RAGDOLL(PLAYER.PLAYER_PED_ID(), 2500, 0, 0, false, false, false)
    local forces = {10, 15, 20, 20, 20, 10, 10, 10, 10, 10, 10}
    local delays = {1000, 900, 800, 700, 600, 500, 400, 300, 200, 175, 125}
    for i = 1, #forces do
        ENTITY.APPLY_FORCE_TO_ENTITY(PLAYER.PLAYER_PED_ID(), 3, 0.0, 0.0, forces[i], 0.0, 0.0, 0.0, 0, false, false, true, false, false)
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
        request_ptfx_asset("cut_xm3")
        GRAPHICS.USE_PARTICLE_FX_ASSET("cut_xm3")
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("cut_xm3_rpg_explosion", pos.x, pos.y, pos.z-0.5, 0, 0, 0, 1.0, true, true, true)
        AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Bomb_Countdown_Beep", PLAYER.PLAYER_PED_ID(), "DLC_MPSUM2_ULP2_Rogue_Drones", true, 0)
        util.yield(delays[i])
    end
    for i = 1, 2 do
        local delay = util.current_time_millis() + 500
        repeat
            ENTITY.APPLY_FORCE_TO_ENTITY(PLAYER.PLAYER_PED_ID(), 3, 0.0, 0.0, 10, 0.0, 0.0, 0.0, 0, false, false, true, false, false)
            pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
            request_ptfx_asset("cut_xm3")
            GRAPHICS.USE_PARTICLE_FX_ASSET("cut_xm3")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("cut_xm3_rpg_explosion", pos.x, pos.y, pos.z-0.5, 0, 0, 0, 1.0, true, true, true)
            AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Bomb_Countdown_Beep", PLAYER.PLAYER_PED_ID(), "DLC_MPSUM2_ULP2_Rogue_Drones", true, 0)
            util.yield(i == 1 and 100 or 10)
        until delay <= util.current_time_millis()
    end
    AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Bomb_Detonate", PLAYER.PLAYER_PED_ID(), "DLC_MPSUM2_ULP2_Rogue_Drones", true, 0)
    pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    request_ptfx_asset("scr_xm_orbital")
    GRAPHICS.USE_PARTICLE_FX_ASSET("scr_xm_orbital")
    GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_xm_orbital_blast", pos.x, pos.y, pos.z, 0, 180, 0, 1.0, true, true, true)
    STREAMING.REMOVE_NAMED_PTFX_ASSET("cut_xm3")
    STREAMING.REMOVE_NAMED_PTFX_ASSET("scr_xm_orbital")
end


