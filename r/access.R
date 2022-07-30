# For each census tract, compute the population that doesn't have access 

library("sf")

compute_percent_uncovered = function(census_tract, match_inds, isos) {
  # if no intersections for that census tract then tract completely uncovered
  if (!length(match_inds)) {
    return (1)
  }

  union = st_union(isos[match_inds,])
  diff = st_difference(census_tract, union)
  # if diff is empty then the census tract is completely covered
  if (!nrow(diff)) {
    return (0)
  }
  percent = as.numeric(st_area(diff)) / as.numeric(st_area(census_tract))
}


# load census data
tracts = readRDS("../data/tract_population.rds")
tracts = tracts[sample(nrow(tracts), 100),]

# load isochrones
iso_120 = readRDS("test_iso_120_min.rds") # from compute all isos branch

# projection
tracts = st_transform(tracts, crs=5070)
iso_120 = st_transform(iso_120, crs=5070)

matches = st_intersects(tracts, iso_120)
percents = c()
for (i in 1:nrow(tracts)) {
  percent = compute_percent_uncovered(tracts[i,], matches[[i]], iso_120)
  print(percent) # just because its slow
  percents = c(percents, percent)
}
