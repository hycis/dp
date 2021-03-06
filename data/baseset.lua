------------------------------------------------------------------------
--[[ BaseSet ]]--
-- Base class inherited by DataSet and Batch.
------------------------------------------------------------------------
local BaseSet = torch.class("dp.BaseSet")
BaseSet.isBaseSet = true

function BaseSet:__init(config)
   assert(type(config) == 'table', "Constructor requires key-value arguments")
   local args, which_set, inputs, targets
      = xlua.unpack(
      {config},
      'BaseSet', 
      'Base class inherited by DataSet and Batch.',
      {arg='which_set', type='string',
       help='"train", "valid" or "test" set'},
      {arg='inputs', type='dp.View | table of dp.Views', 
       help='Sample inputs to a model. These can be Views or '..
       'a table of Views (in which case these are converted '..
       'to a ListView', req=true},
      {arg='targets', type='dp.View | table of dp.Views', 
       help='Sample targets to a model. These can be Views or '..
       'a table of Views (in which case these are converted '..
       'to a ListView. The indices of examples must be '..
       'in both inputs and targets must be aligned.'}
   )
   self:setWhichSet(which_set)
   if inputs then self:setInputs(inputs) end
   if targets then self:setTargets(targets) end
end

function BaseSet:setWhichSet(which_set)
   self._which_set = which_set
end

function BaseSet:whichSet()
   return self._which_set
end

function BaseSet:isTrain()
   return (self._which_set == 'train')
end

function BaseSet:setInputs(inputs)
   if not torch.typename(inputs) and type(inputs) == 'table' then
      --if list, make CompositeTensor
      inputs = dp.CompositeTensor{components=inputs}
   end
   assert(inputs.isView, 
      "Error : invalid inputs. Expecting type dp.View")
   self._inputs = inputs
end

function BaseSet:setTargets(targets)
   if not torch.typename(targets) and type(targets) == 'table' then
      --if list, make CompositeTensor
      targets = dp.CompositeTensor{components=targets}
   end
   assert(targets.isView,
      "Error : invalid targets. Expecting type dp.View")
   self._targets = targets
end

-- Returns the number of samples in the BaseSet.
function BaseSet:nSample()
   return self._inputs:nSample()
end

--Returns input dp.View
function BaseSet:inputs()
   return self._inputs
end

--Returns target dp.View
function BaseSet:targets()
   return self._targets
end

--Preprocesses are applied to DataViews
function BaseSet:preprocess(config)
   config = config or {}
   assert(torch.type(config) == 'table' and not config[1], 
      "Constructor requires key-value arguments")
   local args, input_preprocess, target_preprocess, can_fit
      = xlua.unpack(
         {config},
         'BaseSet:preprocess',
         'Preprocesses the BaseSet.',
         {arg='input_preprocess', type='dp.Preprocess', 
          help='Preprocess applied to the input View of the BaseSet'},
         {arg='target_preprocess', type='dp.Preprocess',
          help='Preprocess applied to the target View of the BaseSet'},
         {arg='can_fit', type='boolean',
          help='Allows measuring of statistics on the View ' .. 
          'of BaseSet to initialize the preprocess. Should normally ' .. 
          'only be done on the training set. Default is to fit the ' ..
          'training set.'}
   )
   assert(input_preprocess or target_preprocess, 
      "Error: no preprocess (neither input nor target) provided)")
   if can_fit == nil then
      can_fit = self:isTrain()
   end
   --TODO support multi-input/target preprocessing
   if input_preprocess and input_preprocess.isPreprocess then
      input_preprocess:apply(self._inputs, can_fit)
   end
   if target_preprocess and target_preprocess.isPreprocess then
      target_preprocess:apply(self._targets, can_fit)
   end
end
