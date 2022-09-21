--[[ ibar
 *	The MIT License (MIT)
 *
 *	Copyright (c) 2014 Vicrelant
 *	
 *	Permission is hereby granted, free of charge, to any person obtaining a copy
 *	of this software and associated documentation files (the "Software"), to 
 *	deal in the Software without restriction, including without limitation the 
 *	rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
 *	sell copies of the Software, and to permit persons to whom the Software is 
 *	furnished to do so, subject to the following conditions:
 *	
 *	The above copyright notice and this permission notice shall be included in 
 *	all copies or substantial portions of the Software.
 *	
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 *	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 *	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 *	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 *	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 *	DEALINGS IN THE SOFTWARE.
]]--
--[[ Checker
* Ashita - Copyright (c) 2014 - 2017 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'Vicrelant (check function from atom0s\'s checker addon ported by Almavivaconte)';
_addon.name     = 'ibar';
_addon.version  = '3.0.3';

require 'common'

	  mb_data = {};
	arraySize = 0;

	jobs = {
		[1]  = 'WAR',
		[2]  = 'MNK',
		[3]  = 'WHM',
		[4]  = 'BLM',
		[5]  = 'RDM',
		[6]  = 'THF',
		[7]  = 'PLD',
		[8]  = 'DRK',
		[9]  = 'BST',
		[10] = 'BRD',
		[11] = 'RNG',
		[12] = 'SAM',
		[13] = 'NIN',
		[14] = 'DRG',
		[15] = 'SMN',
		[16] = 'BLU',
		[17] = 'COR',
		[18] = 'PUP',
		[19] = 'DNC',
		[20] = 'SCH',
		[21] = 'GEO',
		[22] = 'RUN'
	};
	
---------------------------------------------------------------------------------------------------
-- desc: Default ibar configuration table.
---------------------------------------------------------------------------------------------------
local default_config =
{
    font =
    {
        name        = 'Arial',
        size        = 10,
        color		= '255,255,255,255',
        position    = { 130, 0 },
        bgcolor     = '200,0,0,0',
        bgvisible   = true,
		bold		= true
    },
	layout =
	{
		player = '$zone $name  [$level]  [$position] - $ecompass',
		target = '$target  [$job / $level / $aggro]  Weak[$weak]  [$position]',
		npc = '$target [$position] [ID: $id / Index: $m_index]'
	}
};
local checked_once = false;
local ibar_config = default_config;
local moblvl = '';
local lvlraw = '';
local typeraw = '';
local mobrange = '';
local currIndex = '';
local passthrough_check = false;
local check_blocked = false;
local conditions =
{
    { 0xAA, 'HE,HD'},
    { 0xAB, 'HE' },
    { 0xAC, 'HE,LD' },
    { 0xAD, 'HD' },
    { 0xAE, '' },
    { 0xAF, 'LD' },
    { 0xB0, 'LE,HD' },
    { 0xB1, 'LE' },
    { 0xB2, 'LE,LD' },
};
---------------------------------------------------------------------------------------------------
-- Check Type Table
---------------------------------------------------------------------------------------------------
local checktype = 
{
    { 0x40, 'TW' },
    { 0x41, 'EEP' },
    { 0x42, 'EP' },
    { 0x43, 'DC' },
    { 0x44, 'EM' },
    { 0x45, 'T' },
    { 0x46, 'VT' },
    { 0x47, 'IT' }
};

local function check_unblocker()
    check_blocked = false;
end

local function check_blocker()
    check_blocked = true;
    ashita.timer.once(.2, check_unblocker);
end
local function SendCheckPacket(mobIndex)
    local mobId = AshitaCore:GetDataManager():GetEntity():GetServerId(mobIndex);
    local checkPacket = struct.pack('LLHHBBBB', 0, mobId, mobIndex, 0x00, 0x00, 0x00, 0x00, 0x00):totable();
    AddOutgoingPacket(0xDD, checkPacket);
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	ibar_config = ashita.settings.load_merged(_addon.path .. 'settings/ibar.json', ibar_config);

	local a,r,g,b = ibar_config.font.color:match("([^,]+),([^,]+),([^,]+),([^,]+)");
	local fcolor = math.d3dcolor(a,r,g,b);
	local a,r,g,b = ibar_config.font.bgcolor:match("([^,]+),([^,]+),([^,]+),([^,]+)");
	local bcolor = math.d3dcolor(a,r,g,b);
	
	local f = AshitaCore:GetFontManager():Create( '__ibar_addon' );
    f:SetBold( ibar_config.font.bold );
    f:SetColor( fcolor );
    f:SetFontFamily( ibar_config.font.name );
	f:SetFontHeight( ibar_config.font.size );
    f:SetPositionX( ibar_config.font.position[1] );
	f:SetPositionY( ibar_config.font.position[2] );
	f:SetText( '' );
    f:SetVisibility( false );
	f:GetBackground():SetColor( bcolor );
    f:GetBackground():SetVisibility( ibar_config.font.bgvisible );
	
	local ZoneID	= AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	
	local _, mb_data = pcall(require, 'data.' .. tostring(ZoneID));
    if (mb_data == nil or type(mb_data) ~= 'table') then
        mb_data = { };
    end
	
	arraySize = table.getn(mb_data);
end );

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
	local f = AshitaCore:GetFontManager():Get( '__ibar_addon' );
	ibar_config.font.position = { f:GetPositionX(), f:GetPositionY() };
	
	ashita.settings.save(_addon.path .. 'settings/ibar.json', ibar_config);
	
	AshitaCore:GetFontManager():Delete( '__ibar_addon' );
end );

---------------------------------------------------------------------------------------------------
-- func: Render
-- desc: Called when our addon is rendered.
---------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    local f         = AshitaCore:GetFontManager():Get( '__ibar_addon' );
	local Entity	= AshitaCore:GetDataManager():GetEntity();
    local party     = AshitaCore:GetDataManager():GetParty();
	local player	= AshitaCore:GetDataManager():GetPlayer();
	local target    = AshitaCore:GetDataManager():GetTarget();
	local ZoneName	= AshitaCore:GetResourceManager():GetString('areas', party:GetMemberZone(0));
	
	-- disable view if no player
	if (player:GetMainJobLevel() == 0) then
		f:SetVisibility(false);
		return;
	end
	
	f:SetVisibility(true);
	
	ibar_config = ashita.settings.load_merged(_addon.path .. 'settings/ibar.json', ibar_config);
	
	-- obtain values from json configuration.
	
	local s_target = ibar_config.layout.player;
	
	local name = string.find(s_target,'$name');
	local zone = string.find(s_target,'$zone');
	local z_id = string.find(s_target,'$z_id');
	local mlvl = string.find(s_target,'$level');
	local gpos = string.find(s_target,'$position');
	local ecom = string.find(s_target,'$ecompass');
	local scom = string.find(s_target,'$scompass');
	local p_hp = string.find(s_target,'$hpp');
	local m_id = string.find(s_target,'$id');
	local m_ix = string.find(s_target,'$m_index');
	
	-- obtain player position.
	local pX = string.format('%2.3f',Entity:GetLocalX(party:GetMemberTargetIndex(0)));
	local pY = string.format('%2.3f',Entity:GetLocalY(party:GetMemberTargetIndex(0)));
	local pZ = string.format('%2.3f',Entity:GetLocalZ(party:GetMemberTargetIndex(0)));
	local pH = string.format('%2.3f',Entity:GetLocalYaw(party:GetMemberTargetIndex(0)));
	
	local sResult = '';
	local eResult = '';
	
	if (ecom ~= nil or scom ~= nil) then
		local degrees = pH * (180 / math.pi) + 90;
		
		if (degrees > 360) then
			degrees = degrees - 360;
		elseif (degrees < 0) then
			degrees = degrees + 360;
		end
		
		sResult = math.floor(degrees);
		
		if (337 < degrees or 23 >= degrees) then
            eResult = string.format('|cff787878|N|r');
            sResult = 'N';
        elseif (23 < degrees and 68 >= degrees) then
            eResult = string.format('|cFFFFFFFF|NE|r');
            sResult = 'NE';
        elseif (68 < degrees and 113 >= degrees) then
            eResult = string.format('|cff2cf0e8|E|r');
            sResult = 'E';
        elseif (113 < degrees and 158 >= degrees) then
            eResult = string.format('|cff49ff49|SE|r');
            sResult = 'SE';
        elseif (158 < degrees and 203 >= degrees) then
            eResult = string.format('|cffffc900|S|r');
            sResult = 'S';
        elseif (203 < degrees and 248 >= degrees) then
            eResult = string.format('|cffcd18cd|SW|r');
            sResult = 'SW';
        elseif (248 < degrees and 293 >= degrees) then
            eResult = string.format('|cff4949ff|W|r');
            sResult = 'W';
        elseif (293 < degrees and 337 >= degrees) then
            eResult = string.format('|cffff1900|NW|r');
            sResult = 'NW';
        end
	end
	
	-- attempt to display player information.
	-- check if player selected and or nothing selected.
	
	if (target:GetTargetEntityPointer() == nil or target:GetTargetName() == '' or target:GetTargetServerId() == 0 or
		target:GetTargetServerId() == party:GetMemberServerId(0)) then
		checked_once = false;
		-- player does not have a sub-job unlocked.
		if (player:GetSubJobLevel() == 0) then
			
			if (name ~= nil) then s_target = string.gsub(s_target,'$name',party:GetMemberName(0)); end
			if (z_id ~= nil) then s_target = string.gsub(s_target,'$z_id',party:GetMemberZone(0)); end
			if (zone ~= nil) then s_target = string.gsub(s_target,'$zone',ZoneName); end
			if (p_hp ~= nil) then s_target = string.gsub(s_target,'$hpp',party:GetMemberHPP(0)); end
			if (m_id ~= nil) then s_target = string.gsub(s_target,'$id',target:GetTargetServerId()); end
			if (m_ix ~= nil) then s_target = string.gsub(s_target,'$m_index',target:GetTargetIndex()); end
			
			if (mlvl ~= nil) then
				s_target = string.gsub(s_target,'$level',
				jobs[player:GetMainJob()] ..
				player:GetMainJobLevel());
			end
			
			if (gpos ~= nil) then s_target = string.gsub(s_target,'$position',pX .. ', ' .. pY .. ', ' .. pZ); end
			if (ecom ~= nil) then s_target = string.gsub(s_target,'$ecompass',eResult); end
			if (scom ~= nil) then s_target = string.gsub(s_target,'$scompass',sResult); end
			
			f:SetText(string.format(s_target));
			return;
		
		--	player has sub-job unlocked.
		elseif (player:GetSubJobLevel() > 0) then
			
			if (name ~= nil) then s_target = string.gsub(s_target,'$name',party:GetMemberName(0)); end
			if (z_id ~= nil) then s_target = string.gsub(s_target,'$z_id',party:GetMemberZone(0)); end
			if (zone ~= nil) then s_target = string.gsub(s_target,'$zone',ZoneName); end
			if (p_hp ~= nil) then s_target = string.gsub(s_target,'$hpp',party:GetMemberHPP(0)); end
			if (m_id ~= nil) then s_target = string.gsub(s_target,'$id',target:GetTargetServerId()); end
			if (m_ix ~= nil) then s_target = string.gsub(s_target,'$m_index',target:GetTargetIndex()); end
			
			if (party:GetMemberZone(0) ~= 285) then
				if (mlvl ~= nil) then
					s_target = string.gsub(s_target,'$level',
					jobs[player:GetMainJob()] ..
					player:GetMainJobLevel() .. '/' ..
					jobs[player:GetSubJob()] ..
					player:GetSubJobLevel());
				end
			elseif (party:GetMemberZone(0) == 285) then
				if (mlvl ~= nil) then
					s_target = string.gsub(s_target,'$level',
					tostring(jobs[player:GetMainJob()]));
				end
			end
			
			if (gpos ~= nil) then s_target = string.gsub(s_target,'$position',pX .. ', ' .. pY .. ', ' .. pZ); end
			if (ecom ~= nil) then s_target = string.gsub(s_target,'$ecompass',eResult); end
			if (scom ~= nil) then s_target = string.gsub(s_target,'$scompass',sResult); end
			

			f:SetText(string.format(s_target));
			return;
		end
	end
	
	local m_target = ibar_config.layout.target;
	
		  name = string.find(m_target,'$target');
		  zone = string.find(m_target,'$zone');
		  mlvl = string.find(m_target,'$level');
		  gpos = string.find(m_target,'$position');
		  m_id = string.find(m_target,'$id');
		  m_ix = string.find(m_target,'$m_index');
	local flag = string.find(m_target,'$aggro');
	local mjob = string.find(m_target,'$job');
	local weak = string.find(m_target,'$weak');
	local m_hp = string.find(m_target,'$hpp');
    
	
	-- attempt to obtain target information.
	if (target:GetTargetServerId() ~= nil) then
		for i = 1, arraySize do
			if (tonumber(mb_data[i].id) == target:GetTargetServerId()) then
				if (mb_data[i].sj == mb_data[i].mj) then
					
					local tentity = GetEntity(target:GetTargetIndex());
					pX = string.format('%2.3f',tentity.Movement.LocalPosition.X);
					pY = string.format('%2.3f',tentity.Movement.LocalPosition.Y);
					pZ = string.format('%2.3f',tentity.Movement.LocalPosition.Z);
                    
                    mobrange = mb_data[i].mlvl;
                    
                    if target:GetTargetIndex() ~= currIndex and not check_blocked then
                        passthrough_check = false;
                        SendCheckPacket(target:GetTargetIndex())
                        check_blocker()
                        if string.contains(mb_data[i].aggro, "HP") then
                            AshitaCore:GetChatManager():QueueCommand("/ac var set Undead 1", 1);
                        else
                            AshitaCore:GetChatManager():QueueCommand("/ac var set Undead 0", 1);
                        end
                    end            
                    
					if (name ~= nil) then m_target = string.gsub(m_target,'$target',tentity.Name); end
					if (zone ~= nil) then m_target = string.gsub(m_target,'$zone',ZoneName); end
					if (m_id ~= nil) then m_target = string.gsub(m_target,'$id',target:GetTargetServerId()); end
					if (m_ix ~= nil) then m_target = string.gsub(m_target,'$m_index',target:GetTargetIndex()); end
					if (mjob ~= nil) then m_target = string.gsub(m_target,'$job',jobs[tonumber(mb_data[i].mj)]); end
					--if moblvl ~= '' then m_target = string.gsub(m_target,'$mlevel','(' .. moblvl .. ')'); else m_target = string.gsub (m_target, '$mlevel',''); end
                    if (mlvl ~= nil) then m_target = string.gsub(m_target,'$level',mobrange .. moblvl); end
					if (gpos ~= nil) then m_target = string.gsub(m_target,'$position', pX .. ',' .. pY .. ',' .. pZ); end
					if (weak ~= nil) then m_target = string.gsub(m_target,'$weak',mb_data[i].weak); end
					if (m_hp ~= nil) then m_target = string.gsub(m_target,'$hpp',tentity.HealthPercent); end
					
					if (flag ~= nil) then
						if (mb_data[i].links == 'Y') then
							m_target = string.gsub(m_target,'$aggro',mb_data[i].aggro .. ',L');
						else
							m_target = string.gsub(m_target,'$aggro',mb_data[i].aggro);
						end
					end
                    
                        
					
                    
					f:SetText(string.format(m_target));
					return;
				
				else
				
					local tentity = GetEntity(target:GetTargetIndex());
					pX = string.format('%2.3f',tentity.Movement.LocalPosition.X);
					pY = string.format('%2.3f',tentity.Movement.LocalPosition.Y);
					pZ = string.format('%2.3f',tentity.Movement.LocalPosition.Z);
					
                    mobrange = mb_data[i].mlvl;
                    
                    if target:GetTargetIndex() ~= currIndex and not check_blocked then
                        passthrough_check = false;
                        SendCheckPacket(target:GetTargetIndex())
                        check_blocker()
                        if string.contains(mb_data[i].aggro, "HP") then
                            AshitaCore:GetChatManager():QueueCommand("/ac var set Undead 1", 1);
                        else
                            AshitaCore:GetChatManager():QueueCommand("/ac var set Undead 0", 1);
                        end
                    end             
                    
					if (name ~= nil) then m_target = string.gsub(m_target,'$target',tentity.Name); end
					if (zone ~= nil) then m_target = string.gsub(m_target,'$zone',ZoneName); end
					if (m_id ~= nil) then m_target = string.gsub(m_target,'$id',target:GetTargetServerId()); end
					if (m_ix ~= nil) then m_target = string.gsub(m_target,'$m_index',target:GetTargetIndex()); end
					--if moblvl ~= '' then m_target = string.gsub(m_target,'$mlevel', '(' .. moblvl .. ')'); else m_target = string.gsub (m_target, '$mlevel', ''); end
                    if (mlvl ~= nil) then m_target = string.gsub(m_target,'$level',mobrange .. moblvl); end
					if (gpos ~= nil) then m_target = string.gsub(m_target,'$position', pX .. ',' .. pY .. ',' .. pZ); end
					if (weak ~= nil) then m_target = string.gsub(m_target,'$weak',mb_data[i].weak); end
					if (m_hp ~= nil) then m_target = string.gsub(m_target,'$hpp',tentity.HealthPercent);  end
					
					if (mjob ~= nil) then
						m_target = string.gsub(m_target,'$job',
						jobs[tonumber(mb_data[i].mj)] .. '/' ..
						jobs[tonumber(mb_data[i].sj)]);
					end
					
					if (flag ~= nil) then
						if (mb_data[i].links == 'Y') then
							m_target = string.gsub(m_target,'$aggro',mb_data[i].aggro .. ',L');
						else
							m_target = string.gsub(m_target,'$aggro',mb_data[i].aggro);
						end
					end
					
					f:SetText(string.format(m_target));
					return;
				
				end
			end
		end
		
		m_target = ibar_config.layout.npc;
		
		m_id = string.find(m_target,'$id');
		m_ix = string.find(m_target,'$m_index');
		gpos = string.find(m_target,'$position');
		n_hp = string.find(m_target,'$hpp');
		
		local tentity = GetEntity(target:GetTargetIndex());
		if (tentity ~= nil) then
			pX = string.format('%2.3f',tentity.Movement.LocalPosition.X);
			pY = string.format('%2.3f',tentity.Movement.LocalPosition.Y);
			pZ = string.format('%2.3f',tentity.Movement.LocalPosition.Z);
            
            
            tindex = target:GetTargetIndex() <= 1023;
            
            if target:GetTargetIndex() ~= currIndex then
                checked_once = false;
                moblvl = "";
            end
            
            if not checked_once and tindex then
                passthrough_check = false;
                SendCheckPacket(target:GetTargetIndex());
                checked_once = true;
                currIndex = target:GetTargetIndex();
                AshitaCore:GetChatManager():QueueCommand("/ac var set Undead 0", 1);
            end 
			
            --f moblvl ~= "" then mlvl = moblvl; else mlvl = nil; end
            
			if (name ~= nil) then m_target = string.gsub(m_target,'$target',tentity.Name); end
			if (m_id ~= nil) then m_target = string.gsub(m_target,'$id',target:GetTargetServerId()); end
			if (m_ix ~= nil) then m_target = string.gsub(m_target,'$m_index',target:GetTargetIndex()); end
            if (moblvl ~= "") then m_target = string.gsub(m_target,'$level',"[" .. moblvl .. "]"); else m_target = string.gsub(m_target,'$level',""); end
			if (gpos ~= nil) then m_target = string.gsub(m_target,'$position', pX .. ',' .. pY .. ',' .. pZ); end
			if (n_hp ~= nil) then m_target = string.gsub(m_target,'$hpp',tentity.HealthPercent); end
			
			f:SetText(string.format(m_target));
			return;
		else
			f:SetText('');
            AshitaCore:GetChatManager():QueueCommand("/ac var set Undead 0", 1);
		end
	end
end );

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet, data, blocked)
    -- Check for zone-in packets..
    if (id == 0x0A) then
        -- Are we zoning into a mog house..
        if (struct.unpack('b', packet, 0x80 + 1) == 1) then
            return false;
        end
    
        -- Pull the zone id from the packet..
        local zoneId = struct.unpack('H', packet, 0x30 + 1);
        if (zoneId == 0) then
            zoneId = struct.unpack('H', packet, 0x42 + 1);
        end
		
        -- Update our mob list..
		--mb_data = require('data.' .. tostring(zoneId));
		_, mb_data = pcall(require, 'data.' .. tostring(zoneId));
        if (mb_data == nil or type(mb_data) ~= 'table') then
            mb_data = { };
        end
		
		arraySize = table.getn(mb_data);
    end
    
    if (id == 0x0029) then
        currIndex = struct.unpack('H', data, 0x16 + 1);
        local p = struct.unpack('l', packet, 0x0C + 1); -- Monster Level
        local v = struct.unpack('L', packet, 0x10 + 1); -- Check Type
        local m = struct.unpack('H', packet, 0x18 + 1); -- Defense and Evasion

        local ctype = nil;
        local ccond = nil;

        -- Obtain the check type and condition string..
        for k, vv in pairs(checktype) do
            if (vv[1] == v) then
                ctype = vv[2];
            end
        end
        for k, vv in pairs(conditions) do
            if (vv[1] == m) then
                ccond = vv[2];
            end
        end

        -- Check for impossible to gauge..
        if (m == 0xF9) then
            ctype = '';
            ccond = '';
        end

        -- Ensure a check type and condition was found..
        if (ctype == nil or ccond == nil) then
            return false;
        end

        --Obtain the target entity..
        local target = struct.unpack('H', data, 0x16 + 1);
        local entity = GetEntity(target);
        if (entity == nil) then
            return false;
        end

        -- Print out based on NM or not..
        if (m == 0xF9) then
            moblvl = "(NM)";
            lvlraw = "(NM)";
            typeraw = "";
        else
            lvlraw = tostring(p);
            typeraw = ctype;
            moblvl = " (" .. tostring(p) .. " " .. ctype;
            if ccond ~= '' then
                moblvl = moblvl .. " " .. ccond .. ") ";
            else
                moblvl = moblvl .. ") ";
            end
        end
        
        if passthrough_check then
            local conditions_full =
            {
                { 0xAA, '\31\200(\31\130High Evasion, High Defense\31\200)'},
                { 0xAB, '\31\200(\31\130High Evasion\31\200)' },
                { 0xAC, '\31\200(\31\130High Evasion, Low Defense\31\200)' },
                { 0xAD, '\31\200(\31\130High Defense\31\200)' },
                { 0xAE, '' },
                { 0xAF, '\31\200(\31\130Low Defense\31\200)' },
                { 0xB0, '\31\200(\31\130Low Evasion, High Defense\31\200)' },
                { 0xB1, '\31\200(\31\130Low Evasion\31\200)' },
                { 0xB2, '\31\200(\31\130Low Evasion, Low Defense\31\200)' },
            };
            local checktype_full = 
            {
                { 0x40, '\30\02too weak to be worthwhile' },
                { 0x41, '\30\02like incredibly easy prey' },
                { 0x42, '\30\02like easy prey' },
                { 0x43, '\30\102like a decent challenge' },
                { 0x44, '\30\08like an even match' },
                { 0x45, '\30\68tough' },
                { 0x46, '\30\76very tough' },
                { 0x47, '\30\76incredibly tough' }
            };
            for k, vv in pairs(checktype_full) do
                if (vv[1] == v) then
                    ctype = vv[2];
                end
            end
            for k, vv in pairs(conditions_full) do
                if (vv[1] == m) then
                    ccond = vv[2];
                end
            end
            local timestamp = os.date(string.format('\31\%c[%s]\30\01 ', 200, '%H:%M:%S'));
            if moblvl == "(NM)" then
                print(timestamp .. string.format('\31\130%s \30\82%s\31\130 \31\200(Lv. ???) \30\05Impossible to gauge!', entity.Name, string.char(0x81, 0xA8)));
            else
                print(timestamp .. string.format('\31\130%s \30\82%s\31\130 \31\200(Lv. \30\82%d\31\200) \31\130Seems %s\31\130. %s', entity.Name, string.char(0x81, 0xA8), p, ctype, ccond));
            end
            passthrough_check = false;
        end
        
        return true;
    end
    
    return false;
end );

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	-- Action or Equipment Changed packet
	if (id == 0xDD) then
        passthrough_check = true;
    end
	return false;
end);

ashita.register_event('outgoing_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    if string.contains(message, "%%level%%") then
        if lvlraw ~= "(NM)" then
            return ashita.regex.replace(message, "%%level%%", "(Lv." .. lvlraw .. " " .. typeraw .. ")")
        else
            return ashita.regex.replace(message, "%%level%%", "")
        end
    end
    return false;
end);