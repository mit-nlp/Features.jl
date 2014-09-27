# -------------------------------------------------------------------------------------------------------------------------
# HTK Types
# -------------------------------------------------------------------------------------------------------------------------
type HTKFile
  fn       :: String
  nsamples :: Uint32
  period   :: Uint32
  bps      :: Uint16
  kind     :: Uint16
end

type HTKIterator
  file   :: HTKFile
  stream :: IOStream
end

type HTKFullIterator 
  file   :: HTKFile
end

type HTKState
  findex :: Uint32
  frame  :: Vector{Float32}
end

type HTKFullState
  stream :: IOStream
  findex :: Uint32
  frame  :: Vector{Float32}
end

function HTKFile(fn :: String)
  # Read the header
  f = open(fn, "r")
  nsamples = swap4(read(f, Uint32))
  period   = swap4(read(f, Uint32))
  bps      = swap2(read(f, Uint16))
  kind     = swap2(read(f, Uint16))
  close(f)

  return HTKFile(fn, nsamples, period, bps, kind)
end

dims(itr :: HTKFile)   = int(itr.bps / 4)
length(itr :: HTKFile) = itr.nsamples
findex(itr :: HTKFile, t :: Float32) = int(max(1, min(round(t / (itr.period / 10000000.0)) + 1, itr.nsamples)))
time(itr :: HTKFile, f :: Int) = round(f * itr.period / 10000000.0)

dims(si :: HTKState)     = length(si.frame)
dims(si :: HTKFullState) = length(si.frame)

open(htk :: HTKFile)     = HTKIterator(htk, open(htk.fn, "r"))  # Requires explicit close
features(htk :: HTKFile) = HTKFullIterator(htk)                 # Use this only if you intend to walk through all the features

function readHTKFrame(f, vec)
  for k = 1:length(vec)
    vec[k] = reinterpret(Float32, swap4(read(f, Uint32)))
  end
  return vec
end

# -------------------------------------------------------------------------------------------------------------------------
# HTKIterator methods
# -------------------------------------------------------------------------------------------------------------------------
function start(itr :: HTKIterator) 
  seekstart(itr.stream)
  seek(itr.stream, 12) # seek past the header
  return HTKState(0x00000000, zeros(dims(itr.file)))
end

close(itr :: HTKIterator) = close(itr.stream)

function done(itr :: HTKIterator, state :: HTKState)
  if state.findex == itr.file.nsamples
    return true
  end
  return false
end

function next(itr :: HTKIterator, state :: HTKState) 
  state.findex += 1
  return (readHTKFrame(itr.stream, state.frame), state)
end

# -------------------------------------------------------------------------------------------------------------------------
# HTKFullIterator methods
# -------------------------------------------------------------------------------------------------------------------------
function start(itr :: HTKFullIterator) 
  stream = open(itr.file.fn, "r")
  seek(stream, 12)
  return HTKFullState(stream, 0x00000000, zeros(dims(itr.file)))
end

close(itr :: HTKFullIterator) = close(itr.stream)

function done(itr :: HTKFullIterator, state :: HTKFullState)
  if state.findex == itr.file.nsamples
    close(state.stream)
    return true
  end
  return false
end

function next(itr :: HTKFullIterator, state :: HTKFullState) 
  state.findex += 1
  return (readHTKFrame(state.stream, state.frame), state)
end

