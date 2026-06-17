args=commandArgs(TRUE)

csvfile = args[1]
fps = 10
loc_per_bin = 3000
max_dist = 2  # build_graph()
min_length = 6  # get_tips()
max_dist_shrink = 18  # match_tips()
max_dist_growth = 6


require(data.table)
require(RANN)
require(igraph)
require(ggplot2)
require(clue)

build_graph = function(sub_dt, max_dist = 2) {
  coords = as.matrix(sub_dt[, .(x, y)])
  nn = nn2(coords, searchtype = "radius", radius = max_dist)
  idx_mat = nn$nn.idx
  dist_mat = nn$nn.dists
  n = nrow(coords)
  from = rep(1:n, times = ncol(idx_mat))
  to = as.vector(idx_mat)
  dist = as.vector(dist_mat)
  valid = (to > 0) & (to != from)
  from = from[valid]
  to = to[valid]
  dist = dist[valid]
  keep = from < to
  edges = data.table(from = from[keep],
                     to = to[keep],
                     dist = dist[keep])
  g = graph_from_data_frame(edges, directed = FALSE)
  g
}

get_tips = function(g, coords, min_length = 6) {
  deg = degree(g)
  tips = which(deg == 1)
  adj_list = adjacent_vertices(g, V(g))
  
  tip_pos = list()
  tip_dir = list()
  
  for (t in tips) {
    visited = logical(vcount(g))
    visited[t] = TRUE
    path = c(t)
    current = t
    
    repeat {
      nb = adj_list[[current]]
      nb = as.integer(nb)
      nb = nb[!visited[nb]]
      if (length(nb) != 1)
        break
      current = nb
      visited[current] = TRUE
      path = c(path, current)
    }
    
    if (length(path) >= 3) {  
      p = coords[path, , drop = FALSE]
      
      d = sum(sqrt(diff(p[,1])^2 + diff(p[,2])^2))
      
      if (d >= min_length) {
        tip_pos[[length(tip_pos)+1]] = coords[t, ]
        
        k = min(5, nrow(p))
        p_local = p[1:k, , drop = FALSE]
        pc = prcomp(p_local, center = TRUE, scale. = FALSE)
        vec = pc$rotation[,1]
        ref = p[2, ] - p[1, ]
        if (sum(vec * ref) < 0) {
          vec = -vec
        }
        vec = vec / sqrt(sum(vec^2)) 
        
        tip_dir[[length(tip_dir)+1]] = vec
      }
    }
  }
  
  if (length(tip_pos) == 0) {
    return(NULL)
  }
  
  list(
    pos = do.call(rbind, tip_pos),
    dir = do.call(rbind, tip_dir)
  )
}

match_tips = function(prev, curr, max_dist = 5) {
  if (nrow(prev) == 0 | nrow(curr) == 0)
    return(NULL)
  dmat = as.matrix(dist(rbind(prev, curr)))
  dmat = dmat[1:nrow(prev), (nrow(prev) + 1):(nrow(prev) + nrow(curr))]
  nr = nrow(dmat)
  nc = ncol(dmat)
  if (nr > nc) {
    pad = matrix(max_dist, nrow = nr, ncol = nr - nc)
    dmat = cbind(dmat, pad)
  } else if (nc > nr) {
    pad = matrix(max_dist, nrow = nc - nr, ncol = nc)
    dmat = rbind(dmat, pad)
  }
  require(clue)
  assignment = as.integer(solve_LSAP(dmat))
  matches = data.table(prev_idx = 1:length(assignment),
                       curr_idx = assignment)
  matches = matches[matches$curr_idx <= ncol(dmat), ]
  matches$dist = dmat[cbind(matches$prev_idx, matches$curr_idx)]
  matches = matches[matches$dist < max_dist, ]
  matches
}

dt = fread(csvfile)
if(colnames(dt)[2]=="f"){
  dt = dt[, .(f, x, y)]
  colnames(dt)=c("frame", "x", "y")
}else{
  dt = dt[, .(frame, x, y)]
}
setorder(dt, frame)
dt[, loc_id := .I]
dt[, loc_bin := ceiling(loc_id / loc_per_bin)]
bins = split(dt, dt$loc_bin)

tip_list = list()
bin_time = numeric(length(bins))

for (i in seq_along(bins)) {
  sub_dt = bins[[i]]
  g = build_graph(sub_dt, max_dist)
  coords = as.matrix(sub_dt[, .(x, y)])
  tips = get_tips(g, coords, min_length)
  tip_list[[i]] = tips
  bin_time[i] = median(sub_dt$frame) / fps
}


  growth_rates = c()
  shrink_rates = c()
  growth_time = c()
  shrink_time = c()
  
  for (i in 2:length(tip_list)) {
    prev = tip_list[[i - 1]]
    curr = tip_list[[i]]
    
    if (is.null(prev) | is.null(curr)) next
    
    m = match_tips(prev$pos, curr$pos, max_dist_shrink)
    if (is.null(m)) next
    if(dim(m)[1]<=0) next
    
    m = m[!duplicated(m$prev_idx), ]
    
    dt_sec = (bin_time[i] - bin_time[i - 1])
    
    for (j in 1:nrow(m)) {
      p_idx = m$prev_idx[j]
      c_idx = m$curr_idx[j]
      
      disp = curr$pos[c_idx, ] - prev$pos[p_idx, ]
      dir = prev$dir[p_idx, ]
      
      signed_disp = sum(disp * dir) 
      
      rate = signed_disp / dt_sec
      
      if (rate > 0) {
        if(m$dist[j] < max_dist_growth){
          growth_rates = c(growth_rates, rate)
          growth_time = c(growth_time, bin_time[i])
        }
      } else {
        shrink_rates = c(shrink_rates, abs(rate))
        shrink_time = c(shrink_time, bin_time[i])
      }
    }
  }
  


print(paste("Mean growth rate is",mean(growth_rates),"pixel/s."))
print(paste("Median growth rate is",median(growth_rates),"pixel/s."))
print(paste("Mean shrink rate is",mean(shrink_rates),"pixel/s."))
print(paste("Median shrink rate is",median(shrink_rates),"pixel/s."))


ggplot(data.frame(rate = growth_rates), aes(rate)) +
  geom_histogram(bins = 50) +
  theme_minimal() +
  xlab("Growth rate (pixel/s)")

ggplot(data.frame(t = growth_time, r = growth_rates), aes(t, r)) +
  geom_point(alpha = 0.3) +
  geom_smooth() +
  theme_minimal()

ggplot(data.frame(rate = shrink_rates), aes(rate)) +
  geom_histogram(bins = 50) +
  theme_minimal() +
  xlab("Shrink rate (pixel/s)")

ggplot(data.frame(t = shrink_time, r = shrink_rates), aes(t, r)) +
  geom_point(alpha = 0.3) +
  geom_smooth() +
  theme_minimal()
