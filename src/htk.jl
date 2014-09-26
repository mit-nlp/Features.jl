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
  frame  :: Vector{Float32}
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

finalizer(hs :: HTKState, hs -> close(hs.stream))
dims(itr :: HTKFeatures)   = int(itr.bps / 4)
dims(si :: HTKState)       = length(si.frame)
length(itr :: HTKFeatures) = itr.nsamples
findex(itr :: HTKFeatures, t :: Float32) = int(max(1, min(round(t / (itr.period / 10000000.0)) + 1, itr.nsamples)))
time(itr :: HTKFeatures, f :: Int) = round(f * itr.period / 10000000.0)

function start(itr :: HTKFeatures) 
  f = open(itr.fn, "r")
  seek(f, 12) # seek past the header
  return HTKState(f, 0x00000000, zeros(dims(itr)))
end

open(itr :: HTKFeatures) = start(itr)
close(state :: HTKState) = close(state.stream)

function done(itr :: HTKFeatures, state :: HTKState)
  if state.findex == itr.nsamples
    close(state.stream)
    return true
  end
  return false
end

function next(itr :: HTKFeatures, state :: HTKState) 
  state.findex += 1
  return (readHTKFrame(state.stream, state.frame), state)
end

function readHTKFrame(f, vec)
  for k = 1:length(vec)
    vec[k] = reinterpret(Float32, swap4(read(f, Uint32)))
  end
  return vec
end

