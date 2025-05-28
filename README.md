# random_seeding
deterministic random seeding intended for love2d

## add to a project
download the randomSeeding folder (liscense is included in folder) and add ```local RandomSeeding = require("randomSeeding");``` to wherever you will use it in your project

## Utilization
create a seed object by calling ```local randomSeed = RandomSeeding.new(low, high);``` where 'low' and 'high' are numbers (they are the lower and higher 32 bits of the 64 bit seed used for generating the numbers, if not called in function they will both default to 0 and pront a warning about it in the console).

add a sub seed object to the seed object by calling ```randomSeed:newSubSeed(name);``` where 'name' is a string that will be used to index the sub seed whenever it wants to be used (note that trying to create a new sub seed using the name of one that already exists will cause an error)

get a random number from the seed object by calling ```randomSeed:getRandomFromSubSeed(name, ...);``` where 'name' is an index to a sub seed previously created with :newSubSeed (note that trying to call :getRandomFromSubSeed or any other function that expects a sub seeds index will cause an error), the other given arguments will act as the arguments to any normal random call: if no arguments are given then it will return a random number [0, 1), if 1 value is given, then it will return an integer [1, arg], if 2 values are given then it will return a random integer [arg1, arg2]
get a normally distributed random number with by calling ```randomSeed:getRandomNormalFromSubSeed(name, ...);``` where 'name' is an index to a sub seed previously created with :newSubSeed, the other given arguments will act as the arguments to any normal randomNormal call: arg1 is the standard devialtion and defaults to 1, arg2 is the mean and defaults to 0.

call ```randomSeed:activateSubSeed(name);``` where 'name' is an index to a sub seed previously created with :newSubSeed will set the seed and state of the current love2d math.random to that of the sub seed. This allows for getting random numbers through ```love.math.random();``` like so:
```lua
RandomSeeding = require("randomSeeding");

local randomSeed = RandomSeeding.new(1820572, 12894);
randomSeed:newSubSeed("Item Prices"):

randomSeed:activateSeed("Item Prices"); -- activate the sub seed

for k, v in pairs(items) do
  v:generateRandomPrice(); -- calls a function inside of the object that calls love.math.random()
  -- this allows the randomness to be seeded without changing any code inside of the 'item' object despite it containing the random call
end

randomSeed:deactivateSeed("Item Prices"); -- deactivate the sub seed
```
note that ```randomSeed:deactivateSeed(name);``` MUST be called after the activation in order to bring the random function call back to normal. attempting to call :ativate on a sub seed while it is already active will cause an error.
you are allowed to activate multiple sub seeds consecutively without consequence; so long as they are deactivated in the reverse order that they were activated in (deactivating them out of order will cause an error) like so:
```lua
RandomSeeding = require("randomSeeding");

local randomSeed = RandomSeeding.new(1820572, 12894);
randomSeed:newSubSeed("A"):
randomSeed:newSubSeed("B"):
randomSeed:newSubSeed("C"):
randomSeed:newSubSeed("D"):
randomSeed:newSubSeed("E"):
randomSeed:newSubSeed("F"):

-- thi IS allowed as they are deactivated in the reverse order they were activated in
randomSeed:activate("A"); --   A
randomSeed:activate("B"); --   AB
randomSeed:activate("C"); --   ABC
randomSeed:deactivate("C"); -- AB
randomSeed:deactivate("B"); -- A
randomSeed:deactivate("A"); --

-- this is also allowed as the sub seeds are activated and deactivated in reference to the order the were activated in
randomSeed:activate("A"); --   A
randomSeed:activate("B"); --   AB
randomSeed:activate("C"); --   ABC
randomSeed:deactivate("C"); -- AB
randomSeed:deactivate("B"); -- A
randomSeed:activate("D"); --   AD
randomSeed:activate("E"); --   ADE
randomSeed:deactivate("E"); -- AD
randomSeed:activate("F"); --   ADF
randomSeed:deactivate("F"); -- AD
randomSeed:deactivate("D"); -- A
randomSeed:deactivate("A"); --

-- this is NOT allowed as the activations and deactivations are called out of order
randomSeed:activate("A"); --   A
randomSeed:activate("B"); --   AB
randomSeed:activate("C"); --   ABC
randomSeed:deactivate("A"); -- ABC-A * error
randomSeed:deactivate("B");
randomSeed:deactivate("C");
```

## Extra notes
you are unable to call :getRandomFromSubSeed or :getRandomNormalFromSubSeed if the sub seed is active, this will cause an error
