function findid(id::String, ID::Array{String,1})
  c = 0
  for i = 1:length(ID)
    if ID[i] == id
      c = i
      break
    end
  end
  return c
end
