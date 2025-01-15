# pgNetworks
convert geographic data like address coordinates or other points of interest and lines like road networks or utility trenches into a graph data model for routing and analytics purposes.

## what we're doing here:

1. Get Data
   1. Download
   2. Filter for road network
   3. Filter for POI
   4. Load to Postgres
      1. Vertex Data Model
      2. Linestring staging table

2. Preliminary Processing
   1. join vertices to edges
   2. snap the joint vertices into the edge linestring
   3. segmentize the linestrings
   4. calculate the vertices' cardinality

2. Create Graph
   1. Dissolve edges over nodes with degree 2 and
   2. join the original geometries

3. Create ancillary functions 
   1. selector structures for parallel processing

4. Model demo usecases
   2. routing scenarios modeled as materialized views
   3. tbd
   
## what we get:

- a proximity sorted inventory of point data
- a logical network that allows for graph data operations like routing or nearest neighbour searches
- a geometrical network that allows cartographic visualization and ad hoc spatial analysis with access to the graph data model

## Overview:

### folder database


### folder etl


### folder data
