using Features
using Base.Test

# Helpers
function dlm_print(s)
  println(join(map(f -> @sprintf("%-7.5f", f), s), " "))
end

function within(a, b; tolerance = 0.001)
  reduce((x, y) -> x && y, (a - b) .< tolerance)
end

# HTK testing
for fn in readdir("data")
  if ismatch(r"^.*\.cep$", fn)
    features = HTKFeatures("data/$fn")
    X        = zeros(int32(features.bps / 4))
    X2       = zeros(int32(features.bps / 4))
    for f in features
      X  += f
      X2 += f .* f
    end
    mean = X / features.nsamples
    std  = (X2 / features.nsamples) - (mean .* mean)
    println("---------------------------------------------------")
    println("processed:                 $fn")
    println("number of features read:   $(features.nsamples)")
    println("number of dimensions read: $(features.bps / 4)")
    @test within(mean, zeros(int32(features.bps / 4)), tolerance = 0.001)
    @test within(std, ones(int32(features.bps / 4)), tolerance = 0.001)
  end
end

# TODO: Stack testing
# TODO: Bunch testing
