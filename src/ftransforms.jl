# Transforming iterators

# -------------------------------------------------------------------------------------------------------------------------
# StackedVector Iterator
# -------------------------------------------------------------------------------------------------------------------------
type StackedFeatures{T}
  featureStream :: T
  window :: Uint32
  buffer :: Array{Vector{Float32}}
end

function StackedFeatures(f, window)
  buf = Vector{Float32}[ next(f, nothing)[1] for i = 1:window ] # TODO: check for short vectors
  return StackedFeatures(f, convert(Uint32, window), buf)
end

start(itr::StackedFeatures) = nothing

function done(itr::StackedFeatures, nada) 
  if done(itr.featureStream, nada)
    return true
  elseif length(itr.buffer) < itr.window
    return true
  else
    return false
  end
end

function next(itr::StackedFeatures, nada)
  itr.buffer = itr.buffer[2:end]
  push!(itr.buffer, next(itr.featureStream, nada)[1])
  @assert length(itr.buffer) == itr.window
  vec = Float32[]
  for i = 1:length(itr.buffer)
    vec = vcat(vec, itr.buffer[i])
  end
  return (vec, nothing)
end

# -------------------------------------------------------------------------------------------------------------------------
# Bunched Iterator
# -------------------------------------------------------------------------------------------------------------------------
type BunchedFeatures{T}
  featureStream :: T
  size :: Uint32
end
BunchedFeatures{T}(f::T, size) = BunchedFeatures{T}(f, convert(Uint32, size))

start(itr::BunchedFeatures) = nothing

function done(itr::BunchedFeatures, nada) 
  if done(itr.featureStream, nada)
    return true
  end
  return false
end

function next(itr::BunchedFeatures, nada)
  j = 0
  buffer = Float64[]
  while (!done(itr.featureStream, nothing) && j < itr.size)
    buffer = vcat(buffer, Float64[ convert(Float64, x) for x in next(itr.featureStream, nothing)[1] ])
    j += 1
  end
  return (reshape(buffer, (j, int(length(buffer) / j)))', nothing)
end
