/ DOOM Engine Resources
/ https://doomwiki.org/wiki/WAD
/ http://www.gamers.org/dhs/helpdocs/dmsp1666.html

setd:{[d] ((set) .) each (enlist each key[t]),'(enlist each value[t])}

cdr:{(-1*count[x]-1)#x}

/ Size of binary byte structs
s_lump:16
s_thing:10
s_linedef:14
s_sidedef:30
s_vertex:4
s_seg:12
s_ssector:4
s_node:28
s_sector:26

/
 * Read and convert bytes
 * @param {bytes} x - data
 * @param {int} y - offset into data
 * @param {int} z - (optional) number of bytes to convert
\
r_int:{0x0 sv reverse x[y + til 4]}
r_short:{0x0 sv reverse x[y + til 2]}
r_ushort:{0x0 sv (0x0000,reverse x[y + til 2])}
r_chars:{"c"$x[y+ til z]}

r_d:`s`us`i`c!(r_short;r_ushort;r_int;r_chars);
r_o:`s`us`i!2 2 4;

w:read1`:./doom1.wad

ident:"c"$w[til 4];
dirsize:r_int[w;4];
dirloc:r_int[w;8];
dirdata:w dirloc + til dirsize * s_lump

r_dir:{[dd;offset]
 (r_int[dd;offset]; r_int[dd;offset+4]; r_chars[dd;offset+8;8])}[dirdata;]

lumps:r_dir each s_lump * til dirsize;
lumps:`lumploc xasc flip `lumploc`lumpsize`lumpname!flip lumps;

/
 * Apply a generic data conversion to a bytes list according to a "spec" e.g.
 * the spec (`s;`s;(`c;8)) converts two shorts and an 8 byte character array.
 * @param {list} spec - a list of datatypes (keys in the r_d dict), optionally can
 *  include a nested list with data type and data size (e.g. in case of chars)
 * @param {bytes} dd - the bytes to convert
 * @param {int} offset - offset into dd
\
r_any:{[spec;dd;offset]
 funcs:r_d each first each spec;
 offsets:-1 _ offset + (+\) 0,{$[1=count[x];r_o[x];last x]} each spec;
 nchars:{$[1=count[x];::;last x]} each spec;
 funcs .' (count[spec]#enlist[enlist[dd]]),'{x where not null x} each offsets,'nchars}

r_many:{[ufunc;usize;cols_;w;start;size]
 r:flip cols_!flip ufunc[w;] each start + usize * til size div usize;
 / Make an id primary key
 `id xkey update id:i from r}

r_thing:r_any[`s`s`us`us`us;]
r_things:r_many[r_thing;s_thing;`x`y`angle`type_`flags]

r_linedef:r_any[7#`us;]
r_linedefs:r_many[r_linedef;s_linedef;`v1`v2`flags`type_`sector_tag`rsidedef`lsidedef;]

r_sidedef:r_any[(`s;`s;(`c;8);(`c;8);(`c;8);`us);]
r_sidedefs:r_many[r_sidedef;s_sidedef;`xoffset`yoffset`upper_texture`lower_texture`middle_texture`sector;]

r_vertex:r_any[2#`s;]
r_vertices:r_many[r_vertex;s_vertex;`x`y;]

r_seg:r_any[`us`us`s`us`s`s;]
r_segs:r_many[r_seg;s_seg;`v1`v2`angle`linedef`direction`offset;]

r_ssector:r_any[2#`s;]
r_ssectors:r_many[r_ssector;s_ssector;`numlines`firstline;]

r_node:r_any[14#`s;]
r_nodes:r_many[r_node;s_node;`x`y`dx`dy`bb1top`bb1bottom`bb1left`bb1right`bb2top`bb2bottom`bb2left`bb2right`lchild`rchild;]

r_sector:r_any[(`s;`s;(`c;8);(`c;8);`s;`us;`us)]
r_sectors:r_many[r_sector;s_sector;`floorheight`ceilheight`floortexture`ceiltexture`lightlevel`special`tag;]

r_level:{[w;lumps;name]
 idx:first exec i from lumps where lumpname like (name,"*");
 cols_:`things`linedefs`sidedefs`vertices`segs`ssectors`nodes`sectors;
 / Lookup the r_<lumpname> function and apply it with starting offset and size
 / Assumes lumps are laid out according to cols_
 call_lump_func:{[w;lumps;lumpname;idx] (`.[`$"r_",string lumpname])[w;lumps[idx]`lumploc;lumps[idx]`lumpsize]};
 cols_!call_lump_func[w;lumps;] .' cols_,'1 + idx + til count cols_}

\l sdl2.q


/
 * R_ClipSolidWallSegment
 * test case: recur_solidsegs[2 7;recur_solidsegs[1 3;recur_solidsegs[6 10;solidsegs]]]
\
recur_solidsegs:{[newrange;solidsegs_]
  if[0=count[solidsegs_];:solidsegs_];
  first_:newrange[0];
  start:first[solidsegs_];

  / recur until we reach an open range
  if[start[1]<first_-1;:enlist[first[solidsegs_]], .z.s[newrange;cdr solidsegs_]];

  last_:newrange[1];

  / new range starts before next
  if[first_<start[0];
    / new range is entirely visible
    if[last_<start[0]-1;:enlist[newrange],solidsegs_];
    / extend next range backward to the start of this one
    next_:first[solidsegs_];
    :enlist[(first_;next_[1])],cdr solidsegs_
  ];

  / new range is fully enclosed by next
  if[last_<=start[1];:solidsegs_]

  / new range starts in next but ends after
  .z.s[(start[0];last_);cdr solidsegs_]
 }

render_clip_solid:{[seg]
 x:`long$seg[`x1]+viewwidth%2;
 y:`long$seg[`x2]+viewwidth%2;
 solidsegs::recur_solidsegs[(x,y);solidsegs];
//  0N!"called clip_solid ",string[x], " ", string[y];
 h:select `long$linedef.frontsector.ceilheight, `long$linedef.frontsector.floorheight from seg;
 {sdl_render_draw_line[x;z;y;z]}[x;y] each value h;
 }

render_clip_pass:{[seg]
 x:`long$seg[`x1]+viewwidth%2;
 y:`long$seg[`x2]+viewwidth%2;
//  0N!"called clip_pass ",string[x], " ", string[y];
 h:select `long$linedef.frontsector.ceilheight, `long$linedef.frontsector.floorheight from seg;
 {sdl_render_draw_line[x;z;y;z]}[x;y] each value h;
 }

render_add_line:{
//  0N!"called add_line ",string each x;
 back:select linedef.backsector.ceilheight, linedef.backsector.floorheight from segs[x];
 $[(back[`ceilheight]<=frontsector[`floorheight]) or (back[`floorheight]>=frontsector[`ceilheight]);
  render_clip_solid[segs[x]];
  $[(back[`ceilheight]<>frontsector[`ceilheight]) or (back[`floorheight]<>frontsector[`floorheight]);
   render_clip_pass[segs[x]];::]];
 }

render_sector:{
//  0N!"called sector";
 sub:ssectors[x];
 frontsector::select from sectors[sub`sector];
 render_add_line each value[sub`firstline] + til[sub`numlines];
 }

/ https://math.stackexchange.com/a/274728
point_on_side:{[x;y;node]
 x1:node`x;
 x2:node`dx;
 y1:node`y;
 y2:node`dy;
 0<(x-x1)*(y2-y1)-(y-y1)*(x2-x1)
 }

render_bsp_node:{[nodes;bspnum]
 if[bspnum=0;:0N];
//  0N!"called with ",string bspnum;
 $[bspnum<=0; / Negative bspnum means it is a leaf
  $[bspnum=-1;render_sector[0];render_sector[1h + 32767h + bspnum]]; / Negate short
  .z.s[nodes] each (nodes[`int$bspnum]`lchild;nodes[`int$bspnum]`rchild)]
  // .z.s[nodes;nodes[`int$bspnum]`frontchild]]
  }

t:r_level[w;lumps;"E1M1"];
setd[t];

ssectors:update `segs$`long$firstline from ssectors;
linedefs:update `vertices$v1, `vertices$v2 from linedefs;
segs:update `vertices$v1, `vertices$v2, `linedefs$linedef from segs;
sidedefs:update `sectors$sector from sidedefs;
ssectors:update `segs$`long$firstline from ssectors;

/ Replace the NF_SUBSECTOR macro (0x8000) with 0Nj to allow casting the column
linedefs:update
 lsidedef:`sidedefs$lsidedef:?[lsidedef<count[sidedefs];lsidedef;0Nj],
 rsidedef:`sidedefs$rsidedef:?[rsidedef<count[sidedefs];rsidedef;0Nj]
 from linedefs;

ML_TWOSIDED:0b vs 4i;

linedefs:update two_sided:{any ML_TWOSIDED & (0b vs x)} each flags from linedefs;

/ Add front and backsectors to linedefs
linedefs:update frontsector:rsidedef.sector, backsector:lsidedef.sector from linedefs

/ Add sidedef to segs
segs:update sidedef:`sidedefs$?[direction=0;linedef.rsidedef;linedef.lsidedef] from segs
segs:update bsidedef:`sidedefs$?[direction=1;linedef.rsidedef;linedef.lsidedef] from segs
segs:update bsidedef:0Nj from segs where not linedef.two_sided

/ Add sector reference into ssectors table
/ See p_setup.c:P_GroupLines()
map_ssectors:{seg:segs[x`firstline]; sidedefs[seg`sidedef]`sector}
ssectors:`id xkey flip (flip 0!ssectors),enlist[`sector]!enlist map_ssectors each 0!ssectors;

/ L1 start: 1056 -3616
rot:3.14159265359 % 6
pi:3.14159265359
twopi:2 * pi
viewx:1056
viewy:-3616
viewangle:0
clipangle:1
viewwidth:640
focallen:(viewwidth%2)%tan[clipangle]
forwardmove:(25,50)
solidsegs:()

reset_solidsegs:{
  solidsegs::((-0W; -1);(viewwidth; 0W))
 }

update_segs:{
 / Add angle to segs
 segs::update span:a1-a2 from update a1:atan each (v1.y-viewy) % (v1.x-viewx),
  a2:atan each (v2.y-viewy) % (v2.x-viewx) from segs;
 / Add x to segs
 segs::update x1:?[x1_<x2_;x1_;x2_], x2:?[x1_<x2_;x2_;x1_] from
  update x1_:focallen*tan[a1-viewangle], x2_:focallen*tan[a2-viewangle] from segs;
 }

// point_to_angle:{[x,y]
//   x:-viewx;
//   y:-viewy;
//   atan each (v2.y-viewy) % (v2.x-viewx)
// }

check_bbox2:{[top;bottom;left;right]
  $[viewx<=left&viewy>=top;[top,right,bottom,left];
    viewx<right&viewy>=top;[top,right,top,left];
    viewx>=right&viewy>=top;[bottom,right,top,left];
    viewx<=left&viewy>bottom;[top,left,bottom,left];
    viewx>=right&viewy>bottom;[bottom,right,top,right];
    viewx<=left&viewy<=bottom;[top,left,bottom,right];
    viewx<right&viewy<=bottom;[bottom,left,bottom,right];
    viewx>=right&viewy<=bottom;[bottom,left,top,right];
    [-1,-1,-1,-1]
  ]
 }

check_bbox:{
  / backside
  bb2:select bb2top, bb2bottom, bb2left, bb2right from nodes;
  edgepts:`y1`x1`y2`x2!flip .'[check_bbox2;value each bb2];
  angle:select a1:-1*viewangle + atan each (y1-viewy) % (x1-viewx),
    a2:-1*viewangle + atan each (y2-viewy) % (x2-viewx) from edgepts;
  angle: update span:a1-a2 from angle;
  update bail1:span>=pi, bail2:a1>span+2*clipangle, bail3:-1*a2>span+2*clipangle,
    a1:min[(a1;clipangle)], a2:max[(a2;-1*clipangle)] from angle;
  flip update x1:focallen*tan[a1], x2:focallen*tan[a2] from angle
 }

update_nodes:{
 / Calculate backside to current position
 nodes::nodes,'flip enlist[`backside]!enlist[value point_on_side[viewx;viewy;] each nodes];
 nodes::update frontchild:lchild|backside*rchild from nodes;
//  nodes::update lchild:$[lchild=0;-0;lchild], rchild:$[rchild=0;-0;rchild] from nodes;
 }

render_frame:{
 0N!viewangle,viewx,viewy;
 sdl_render_clear[];
 render_bsp_node[nodes;x];
 sdl_render_present[];
 }

render_loop_:{
 e:sdl_poll_event[];
 if[0=e;::];
 if[1=e;viewy+:forwardmove[0]*sin(viewangle);viewx+:forwardmove[0]*cos(viewangle)];
 if[2=e;viewangle::(viewangle+rot) mod twopi];
 if[3=e;viewy-:forwardmove[0]*sin(viewangle);viewx-:forwardmove[0]*cos(viewangle)];
 if[4=e;viewangle::(viewangle-rot) mod twopi];
 update_segs[];
 update_nodes[];
 reset_solidsegs[];
 render_frame[-1+count[nodes]]
 }

\c 40 120

render_loop:{while[1;render_loop_[]]}