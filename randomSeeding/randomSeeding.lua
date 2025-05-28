local RandomSeeding = {};
RandomSeeding.__index = RandomSeeding;

function RandomSeeding.new(lower, upper)
  local instance = setmetatable({}, RandomSeeding);

  if not lower or not upper then
    print("WARNING: random seed was created missing a lower or upper value for its seed, defaulted to 0");
  end

  lower = lower or 0;
  upper = upper or 0;

  instance.baseGenerator = love.math.newRandomGenerator(lower, upper);

  instance.activationOrder = {}; -- keep track of the activating order

  instance.subSeeds = {}; -- sub seeding

  return instance;
end

function RandomSeeding:newSubSeed(name)
  assert(self.subSeeds[name] == nil, "tried to create a new sub seed that already exists: " .. name);
  
  local low  = self.baseGenerator:random(0, 4294967295); -- [0 - 2^32-1]
  local high = self.baseGenerator:random(0, 4294967295);

  self.subSeeds[name] = {
    generator = love.math.newRandomGenerator(low, high);
    active = false;

    holdingLow = nil;
    holdingHigh = nil;
    holdingState = nil;
  };
end

function RandomSeeding:getRandomFromSubSeed(name, ...)
  assert(self.subSeeds[name], "tried to generate random number from a sub seed that does not exist: " .. name);
  assert(self.subSeeds[name].active == false, "tried to generate random number from a sub seed that is currently active: " .. name);

  return self.subSeeds[name].generator:random(...);
end

function RandomSeeding:activateSubSeed(name)
  assert(self.subSeeds[name], "tried to activate a sub seed that does not exist: " .. name);
  assert(self.subSeeds[name].active == false, "tried to activate a sub seed that is already active: " .. name);

  table.insert(self.activationOrder, 1, name); -- add this activation to the order

  local saveLow, saveHigh = love.math.getRandomSeed();
  local saveState = love.math.getRandomState();

  love.math.setRandomSeed(self.subSeeds[name].generator:getSeed());
  love.math.setRandomState(self.subSeeds[name].generator:getState());

  -- save previous random information
  self.subSeeds[name].holdingLow = saveLow;
  self.subSeeds[name].holdingHigh = saveHigh;
  self.subSeeds[name].holdingState = saveState;
  self.subSeeds[name].active = true;
end

function RandomSeeding:deactivateSubSeed(name)
  assert(self.subSeeds[name], "tried to deactivate a sub seed that does not exist: " .. name);
  assert(self.subSeeds[name].active == true, "tried to deactivate a sub seed that was not active: " .. name);
  assert(self.activationOrder[1] == name, "tried to deactivate a sub seed that was not the most recent sub seed to be activated: " .. name);

  -- set random information to the previously kept information
  love.math.setRandomSeed(self.subSeeds[name].holdingLow, self.subSeeds[name].holdingHigh);
  love.math.setRandomSeed(self.subSeeds[name].holdingState);

  local low, high = love.math.getRandomSeed();
  local thisLow, thisHight = self.subSeeds[name].generator:getSeed();
  local state = love.math.getRandomState();

  -- ensure the random info lines up properly
  assert(thisLow == low and thisHigh == high, "seed bytes did not align with the currently saved seed");

  -- update the random state for the sub seed
  self.subSeeds[name].generator:setState(state);

  -- reset holding random info (just to be sure)
  self.subSeeds[name].holdingLow = nil;
  self.subSeeds[name].holdingHigh = nil;
  self.subSeeds[name].holdingState = nil;

  table.remove(self.activationOrder, 1); -- remove this random seed from the activation order
end

-- check if seed was forgotten to deactivate a sub seed
-- not very necessary as in a normal setting, the seed would end up being activated twice cause an error in the :activate function
-- but if wanted this will return true if there IS a leak
function RandomSeeding:checkLeak()
  return #self.activationOrder ~= 0;
end

return RandomSeeding;
