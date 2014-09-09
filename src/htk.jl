# -------------------------------------------------------------------------------------------------------------------------
# HTKFeatures Iterator
# -------------------------------------------------------------------------------------------------------------------------
type HTKFeatures
  stream :: IOStream
  nsamples :: Uint32
  period :: Uint32
  bps :: Uint16
  kind :: Uint16
  findex :: Uint32
  # HTKFeatures(f::IOStream, nsamples::Uint32, period::Uint32, bps::Uint16, kind::Uint16, fi) = new(f, nsamples, period, bps, kind, convert(Uint32, fi))
end

function HTKFeatures(fn :: String)
  f = open(fn, "r")
  nsamples = swap4(read(f, Uint32))
  period   = swap4(read(f, Uint32))
  bps      = swap2(read(f, Uint16))
  kind     = swap2(read(f, Uint16))
  return HTKFeatures(f, nsamples, period, bps, kind, 0x00000000)
end

length(itr::HTKFeatures) = itr.nsamples
start(itr::HTKFeatures) = HTKFeatures(itr.stream, itr.nsamples, itr.period, itr.bps, itr.kind, 0x00000000)

function done(itr::HTKFeatures, nada)
  if itr.findex == itr.nsamples
    close(itr.stream)
    return true
  end
  return false
end

function next(itr::HTKFeatures, nada) 
  itr.findex += 1
  return (readHTKFrame(itr.stream, itr.bps), nothing)
end

function readHTKFrame(f, bps)
  vec = Float32[]
  for k = 1:(bps/4)
    push!(vec, reinterpret(Float32, swap4(read(f, Uint32))))
  end
  return vec
end
