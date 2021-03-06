------------------------------------------------------------------------
--[[ Batch ]]--
-- BaseSet subclass
-- State of a mini-batch to be fed into a model and criterion.
-- A batch of examples sampled from a dataset.
-- Serializable
------------------------------------------------------------------------
local Batch, parent = torch.class("dp.Batch", "dp.BaseSet")
Batch.isBatch = true

function Batch:__init(config)
   assert(type(config) == 'table', "Constructor requires key-value arguments")
   local args, epoch_size = xlua.unpack(
      {config},
      'Batch', 
      'State of a mini-batch to be fed into a model and criterion.',
      {arg='epoch_size', type='number',
       help='number of samples in original dataset'}
   )
   self._epoch_size = epoch_size
   parent.__init(self, config)
end

function Batch:setup(config)
   assert(type(config) == 'table', "Setup requires key-value arguments")
   local args, epoch_size
   args, self._batch_iter, self._batch_size, self._n_sample, 
      self._grad_type, self._indices, epoch_size
      = xlua.unpack(
      {config},
      'Batch:setup', 
      'post-construction setup. Usually performed by Sampler.',
      {arg='batch_iter', type='number',
       help='Count of the number of examples seen so far. Used to '..
       'update progress bar. Shouldn\'t be larger than epoch_size.'}, 
      {arg='batch_size', type='number',
       help='Maximum number of examples in batch.'},
      {arg='grad_type', type='string',
       help='Type of output gradient : cuda | float | double'},
      {arg='indices', type='torch.Tensor', 
       help='indices of the examples in the original dataset.'},
      {arg='epoch_size', type='number',
       help='number of samples in epoch dataset.'}
   )
   self._epoch_size = epoch_size or self._epoch_size
end

function Batch:batchSize()
   return self._batch_size
end

function Batch:epochSize()
   return self._epoch_size
end

function Batch:batchIter()
   return self._batch_iter
end

function Batch:indices()
   return self._indices
end

-- generate a carry table to be passed along through forward/backward
function Batch:carry()
   return {
      nSample=self:nSample(), 
      epochSize=self._epoch_size,
      batchIter=self._batch_iter, 
      targets=self:targets() -- this is necessary for SoftmaxTree
   }
end
