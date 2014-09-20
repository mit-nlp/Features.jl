# -------------------------------------------------------------------------------------------------------------------------
# SegmentedFile
# -------------------------------------------------------------------------------------------------------------------------
immutable SegmentedFile
  fn     :: String
  names  :: Vector{String}
  starts :: Vector{Float32}
  ends   :: Vector{Float32}
end

function mask(sf :: SegmentedFile; filter :: Function = (name, start, fin, file) -> true)
  htk = HTKFeatures(sf.fn)
  m   = [ false for i = 1:htk.nsamples ]
  n   = 0
  for i = 1:length(sf.starts)
    if filter(sf.names[i], sf.starts[i], sf.ends[i], sf.fn)
      for k = findex(htk, sf.starts[i]):findex(htk, sf.ends[i])
        m[k] = true
        n += 1
      end
    end
  end
  return m, n
end

# -------------------------------------------------------------------------------------------------------------------------
# Analist reader
# -------------------------------------------------------------------------------------------------------------------------
function analist(fn :: String; dir = ".", sample_rate = 8000.0)
  f = open(fn, "r")

  ret    = SegmentedFile[]
  prior  = ""
  starts = Float32[]
  ends   = Float32[]
  names  = String[]

  for l in eachline(f)
    ana = split(chop(l), r"\s+")
    if prior != ana[4] && prior != ""
      push!(ret, SegmentedFile("$dir/$prior", names, starts, ends))
      starts = Float32[]
      ends   = Float32[]
      names  = String[]
    end
    push!(starts, float32(ana[2]) / sample_rate)
    push!(ends, float32(ana[3]) / sample_rate)
    push!(names, ana[1])
    prior = ana[4]
  end

  if prior != ""
    push!(ret, SegmentedFile("$dir/$prior", names, starts, ends))
  end

  close(f)
  ret
end

# -------------------------------------------------------------------------------------------------------------------------
# Mark reader
# -------------------------------------------------------------------------------------------------------------------------
function marks(fn :: String; dir = ".")
  f = open(fn, "r")

  ret    = SegmentedFile[]
  prior  = ""
  starts = Float32[]
  ends   = Float32[]
  names  = String[]

  for l in eachline(f)
    ana = split(chop(l), r"\s+")
    if prior != ana[4] && prior != ""
      push!(ret, SegmentedFile("$dir/$prior", names, starts, ends))
      starts = Float32[]
      ends   = Float32[]
      names  = String[]
    end
    push!(starts, float32(ana[2]))
    push!(ends, float32(ana[3]))
    push!(names, ana[1])
    prior = ana[4]
  end

  if prior != ""
    push!(ret, SegmentedFile("$dir/$prior", names, starts, ends))
  end

  close(f)
  ret
end
