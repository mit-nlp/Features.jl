# -------------------------------------------------------------------------------------------------------------------------
# HTKFeatures Iterator
# -------------------------------------------------------------------------------------------------------------------------
type HTKFeatures
  fn       :: String
  nsamples :: Uint32
  period   :: Uint32
  bps      :: Uint16
  kind     :: Uint16
end

type HTKState
  stream :: IOStream
  findex :: Uint32
end

function HTKFeatures(fn :: String)
  # Read the header
  f = open(fn, "r")
  nsamples = swap4(read(f, Uint32))
  period   = swap4(read(f, Uint32))
  bps      = swap2(read(f, Uint16))
  kind     = swap2(read(f, Uint16))
  close(f)

  return HTKFeatures(fn, nsamples, period, bps, kind)
end

dims(itr::HTKFeatures)   = itr.bps / 4
length(itr::HTKFeatures) = itr.nsamples

function start(itr::HTKFeatures) 
  f = open(fn, "r")
  seek(f, 12) # seek past the header
  return HTKState(f, 0x00000000)
end

function done(itr :: HTKFeatures, state :: HTKState)
  if state.findex == itr.nsamples
    close(state.stream)
    return true
  end
  return false
end

function next(itr :: HTKFeatures, state :: HTKState) 
  itr.findex += 1
  return (readHTKFrame(itr.stream, dims(itr)), nothing)
end

function readHTKFrame(f, dims)
  vec = Float32[]
  for k = 1:dims
    push!(vec, reinterpret(Float32, swap4(read(f, Uint32))))
  end
  return vec
end
