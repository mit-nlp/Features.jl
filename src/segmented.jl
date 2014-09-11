# -------------------------------------------------------------------------------------------------------------------------
# SegmentedFeatures Iterator
# -------------------------------------------------------------------------------------------------------------------------
type SegmentIterator
  data
  start :: Int
  fin   :: Int
end

start(si :: SegmentIterator) = si.start
done(si :: SegmentIterator, state :: Int) = state == si.fin ? true : false
next(si :: SegmentIterator, state :: Int) = (data[state], state + 1)

# -------------------------------------------------------------------------------------------------------------------------
# SegmentedFeatures Iterator
# -------------------------------------------------------------------------------------------------------------------------
type SegmentedFeatures
  open   :: Function
  close  :: Function
  findex :: Function
  starts :: Vector{Float32}
  ends   :: Vector{Float32}
end

type SFState
  data
  index :: Int
end

function SegmentedFeatures(open :: Function, close :: Function, findex :: Function, segs = Vector{(Float32, Float32)})
  SegmentedFeatures(open, close, [ x[1] for x in segs ], [ x[2] for x in segs ])
end

length(sf :: SegmentedFeatures) = length(sf.starts)

function start(sf :: SegmentedFeatures)
  SFState(sf.open(), 0)
end

function done(sf :: SegmentedFeatures, state :: SFState)
  if state.index == length(sf)
    sf.close(state.data)
    return true
  end
  return false
end

function next(sf :: SegmentedFeatures, state :: SFState)
  state.index += 1
  return (SegmentIterator(state.data, sf.findex(sf.starts[state.index]), sf.findex(sf.ends[state.index])), state)
end

# -------------------------------------------------------------------------------------------------------------------------
# Analist reader
# -------------------------------------------------------------------------------------------------------------------------
function analist(fn :: String, dir = ".", sample_rate = 8000)
  f = open(fn, "r")

  ret    = SegmentedFeatures[]
  prior  = ""
  starts = Float32[]
  ends   = Float32[]
  for l in eachline(f)
    ana = split(chop(l), r"\s+")
    if prior != ana[4]
      htkf = HTKFeatures("$dir/$prior")
      push!(ret, SegmentedFeatures(() -> open(htkf), f -> close(f), t -> findex(htkf, t), starts, ends))
      starts = Float32[]
      ends   = Float32[]
    end
    push!(starts, float32(ana[2]) / sample_rate)
    push!(ends, float32(ana[3]) / sample_rate)
  end
  htkf = HTKFeatures("$dir/$prior")
  push!(ret, SegmentedFeatures(() -> open(HTKFeatures(prior)), f -> close(f), t -> findex(htkf, t), starts, ends))

  close(f)
end

