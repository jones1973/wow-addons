assert(LibStub, "LibDataBroker-1.1 requires LibStub")
assert(LibStub:GetLibrary("CallbackHandler-1.0", true), "LibDataBroker-1.1 requires CallbackHandler-1.0")

local lib, oldminor = LibStub:NewLibrary("LibDataBroker-1.1", 4)
if not lib then return end
oldminor = oldminor or 0

lib.callbacks = lib.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(lib)
lib.attributestorage, lib.namestorage, lib.proxystorage = lib.attributestorage or {}, lib.namestorage or {}, lib.proxystorage or {}
local attributestorage, namestorage, proxystorage = lib.attributestorage, lib.namestorage, lib.proxystorage

if oldminor < 2 then
    lib.domt = {
        __metatable = "access denied",
        __index = function(self, key) return attributestorage[self] and attributestorage[self][key] end,
    }
end

if oldminor < 3 then
    lib.domt.__newindex = function(self, key, value)
        if not attributestorage[self] then attributestorage[self] = {} end
        if attributestorage[self][key] == value then return end
        attributestorage[self][key] = value
        local name = namestorage[self]
        if not name then return end
        lib.callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, self)
        lib.callbacks:Fire("LibDataBroker_AttributeChanged_"..name, name, key, value, self)
        lib.callbacks:Fire("LibDataBroker_AttributeChanged_"..name.."_"..key, name, key, value, self)
        lib.callbacks:Fire("LibDataBroker_AttributeChanged__"..key, name, key, value, self)
    end
end

if oldminor < 4 then
    function lib:NewDataObject(name, dataobj)
        if proxystorage[name] then return end
        if dataobj then
            assert(type(dataobj) == "table", "Invalid dataobj, must be nil or a table")
            attributestorage[dataobj] = nil
        end
        dataobj = dataobj or {}
        local proxy = setmetatable({}, lib.domt)
        proxystorage[name] = proxy
        namestorage[proxy] = name
        attributestorage[proxy] = dataobj
        lib.callbacks:Fire("LibDataBroker_DataObjectCreated", name, proxy)
        return proxy
    end

    function lib:DataObjectIterator() return pairs(proxystorage) end
    function lib:GetDataObjectByName(dataobjectname) return proxystorage[dataobjectname] end
    function lib:GetNameByDataObject(dataobject)
        if proxystorage[dataobject] then return dataobject end
        return namestorage[dataobject]
    end
end
