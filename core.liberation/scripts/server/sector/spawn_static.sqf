params ["_sector", "_count"];

if (_count == 0) exitWith {};
if (_count > 1) then {
	sleep 3;
	[_sector, _count - 1] spawn spawn_static;
};

// LK_MOD
private _static_class = selectRandom opfor_statics;
private _spawn_pos = [];

if (_static_class isKindOf "StaticMortar" && GRLIB_LAMBS_enabled ) then {
	for "_i" from 1 to 10 do {
		_spawn_pos = [markerPos _sector, 500, 2000, 3, 0, 1, 0, [], []] call BIS_fnc_findSafePos;
		 if (([_spawn_pos, 250, GRLIB_side_friendly] call F_getUnitsCount == 0) && ([300, _spawn_pos] call F_getNearestSector) == "") exitWith {};
		 _spawn_pos = [];
		 sleep 0.5;
	};
};

if (_spawn_pos isEqualTo []) then {
	private _radius = GRLIB_capture_size - 20;
	if (_sector in sectors_bigtown) then { _radius = _radius * 1.4 };

	_spawn_pos = (markerPos _sector) getPos [_radius, floor random 360];
	if (surfaceIsWater _spawn_pos) exitWith {};
	_spawn_pos set [2, 0.5];
};

// Create Static
// private _vehicle = createVehicle [selectRandom opfor_statics, _spawn_pos, [], 0, "None"];
private _vehicle = createVehicle [_static_class, _spawn_pos, [], 0, "None"];
_vehicle addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
_vehicle setVariable ["R3F_LOG_disabled", true, true];
_vehicle setVariable ["GRLIB_vehicle_owner", "server", true];
_vehicle setVariable ["GRLIB_vehicle_reward", true, true];
[_vehicle] call F_aceLockVehicle;
sleep 1;

// Crew
private _grp = [_vehicle, GRLIB_side_enemy] call F_forceCrew;
if (_static_class isKindOf "StaticMortar" && GRLIB_LAMBS_enabled ) then {
	[_grp] call lambs_wp_fnc_taskArtilleryRegister;
};
sleep 1;

// Spotters
// LK_MOD
if (!(_static_class isKindOf "StaticMortar") || !GRLIB_LAMBS_enabled ) then {
	_unit = _grp createUnit [opfor_spotter, _vehicle, [], 3, "None"];
	[_unit] joinSilent _grp;
	_unit addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
	[_unit] call set_unit_subskills;
	sleep 0.5;
	_unit = _grp createUnit [opfor_spotter, _vehicle, [], 3, "None"];
	[_unit] joinSilent _grp;
	_unit addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
	[_unit] call set_unit_subskills;
};

diag_log format [ "Spawn Static Weapon (%1) on sector %2 at %3", typeOf _vehicle, _sector, time ];

if (!(_static_class isKindOf "StaticMortar") || !GRLIB_LAMBS_enabled ) then {
_spawn_pos = getPos _vehicle;
[_grp, _spawn_pos, 75] spawn patrol_ai;
};

private _hc = [] call F_lessLoadedHC;
if (isDedicated && !isNull _hc) then {
	_grp setGroupOwner (owner _hc);
};

// Cleanup
waitUntil {
	sleep 30;
	if (_static_class isKindOf "StaticMortar" && GRLIB_LAMBS_enabled ) then {
		([_vehicle, 200, GRLIB_side_friendly] call F_getUnitsCount == 0 && !(_sector in (active_sectors + A3W_sectors_in_use)));
	} else {
		([_vehicle, GRLIB_sector_size, GRLIB_side_friendly] call F_getUnitsCount == 0 && !(_sector in (active_sectors + A3W_sectors_in_use)));
	};
};
if (!isNull _vehicle) then { deleteVehicle _vehicle };
{ deleteVehicle _x } forEach (units _grp);
deleteGroup _grp;