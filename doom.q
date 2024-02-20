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
s_mappatch:10

/
 * Read and convert bytes
 * @param {bytes} x - data
 * @param {int} y - offset into data
 * @param {int} z - (optional) number of bytes to convert
\
r_int:{0x0 sv reverse x[y + til 4]}
r_short:{0x0 sv reverse x[y + til 2]}
r_ushort:{0x0 sv (0x0000,reverse x[y + til 2])}
r_uint8:{0x0 sv (3#0x0),1#x[y]}
r_chars:{"c"$x[y+ til z]}

r_d:`i8`s`us`i`c!(r_uint8;r_short;r_ushort;r_int;r_chars);
r_o:`i8`s`us`i!1 2 2 4;

w:read1`:./doom1.wad

ident:"c"$w[til 4];
dirsize:r_int[w;4];
dirloc:r_int[w;8];
dirdata:w dirloc + til dirsize * s_lump

/ Extract the directory
/ https://doomwiki.org/wiki/WAD#Directory
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

r_many_:{[ufunc;usize;cols_;w;start;size]
 r:flip cols_!flip ufunc[w;] each start + usize * til size div usize}

r_many:{[ufunc;usize;cols_;w;start;size]
 r:r_many_[ufunc;usize;cols_;w;start;size];
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
/ seg angle is the angle b/w v1 and v2
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

/ maptextures
/ https://doomwiki.org/wiki/TEXTURE1_and_TEXTURE2
tex_loc:exec first lumploc from lumps where lumpname like "TEXTURE1";
numtex:r_int[w;tex_loc];
texoffset:tex_loc + r_int[w] each (tex_loc + 4 * 1 + til numtex);
maptextures:flip `name`masked`width`height`columndirectory`patchcount!flip r_any[((`c;8);`i;`s;`s;`i;`us);w] each texoffset;
maptextures:maptextures,'(flip enlist[`texoffset]!enlist texoffset);
maptextures:update id:i from maptextures;

/ mappatches
r_patch:r_any[5#`s;]
mappatches:{
  t:r_many_[r_patch;s_mappatch;`originx`originy`patch`stepdir`colormap;w;22+x`texoffset;s_mappatch*x`patchcount];
  update maptexure:x`id from t} each maptextures
mappatches:(,/) mappatches

/ pnames
/ https://doomwiki.org/wiki/PNAMES
pnames_loc:exec first lumploc from lumps where lumpname like "PNAMES*";
numpatches:r_int[w;pnames_loc];
pnames:r_many_[r_any[enlist[(`c;8)];];8;enlist `pname;w;4+pnames_loc;8*numpatches];

/ For some reason there is a pname that's not in lumps?
pnames:select from pnames where pname in lumps`lumpname;

/ posts
/ https://doomwiki.org/wiki/Picture_format
r_posts:{[pnameidx]
  r_patch_header:r_any[4#`s;];
  patchloc:first exec lumploc from lumps where lumpname like pnames[pnameidx]`pname;
  header:r_patch_header[w;patchloc];
  columnofs:patchloc + r_int[w] each patchloc + 8 + 4 * til first header;
  r_post:r_any[3#`i8;];
  post:flip `topdelta`length`unused!flip r_post[w;] each columnofs;
  post:post,'flip enlist[`columnofs]!enlist[columnofs];
  data:{x[`length]#_[3+x`columnofs;w]} each post;
  post,'flip `patch`data!(count[data]#pnameidx;data)
 }

posts:(,/)r_posts each til count pnames

/ palettes
/ https://doomwiki.org/wiki/PLAYPAL
playpal_loc:first exec lumploc from lumps where lumpname like "PLAYPAL*";
r_playpal:r_any[3#`i8;]
playpal:r_many[r_playpal;3;`r`g`b;w;playpal_loc;3*256] / just take first palette for now


\l sdl2.q


/ L1 start: 1056 -3616
rot:3.14159265359 % 6
pi:3.14159265359
twopi:2 * pi
ang90:pi%2
viewx:1056
viewy:-3616
viewangle:0
clipangle:1
viewwidth:640
viewheight:480
focallen:(viewwidth%2)%tan[clipangle]
forwardmove:(25,50)
solidsegs:()

/
 * R_ClipSolidWallSegment
 * Use global vars to track the clip range as it simplifies implementation
 * test case: recur_solidsegs_[2 7;recur_solidsegs_[1 3;recur_solidsegs_[6 10;solidsegs]]]
\
rs_last_clip_start:-1;
rs_last_clip_end:-1;
recur_solidsegs_:{[newrange;solidsegs_]
  if[0=count[solidsegs_];:solidsegs_];
  newstart:newrange[0];
  next_:first[solidsegs_];

  / recur until we reach an open range
  if[next_[1]<newstart-1;:enlist[first[solidsegs_]], .z.s[newrange;cdr solidsegs_]];

  newend:newrange[1];

  / new range starts before next
  if[newstart<next_[0];
    / take max in case of extension of previous clip range (last line)
    rs_last_clip_start::max[(rs_last_clip_start;newstart)];
    / new range ends before next starts i.e. is entirely visible
    if[newend<next_[0]-1;
      rs_last_clip_end::newend;
      :enlist[newrange],solidsegs_];
    / extend next range backward to the start of this one
    rs_last_clip_end::next_[0];
    :enlist[(newstart;next_[1])],cdr solidsegs_
  ];

  / new range is fully enclosed by next
  if[newend<=next_[1];:solidsegs_];

  / new range starts in next but ends after
  rs_last_clip_start::next_[1];
  .z.s[(next_[0];newend);cdr solidsegs_]
 }

/ Insert new clip range and return range clipped
recur_solidsegs:{[newrange]
  rs_last_clip_start::-1;
  rs_last_clip_end::-1;
  solidsegs::recur_solidsegs_[newrange;solidsegs];
  (rs_last_clip_start;rs_last_clip_end)
 }

colfunc:{[top;bottom;x;post]
  post_:value each (`long$) each playpal each (`long$) each post;
  zip:(top+til[min[(count[post_];bottom)]]),'post_;
  / need to add palette lookup
  (sdl_render_draw_point[x] .) each zip;
 }

render_seg_loop:{[x1;x2;top;bottom]
  r:x1 + til[x2-x1];
  / just using random posts right now
  (colfunc[top;bottom] .) each r,'enlist each posts[r]`data;
 }

render_clip_solid:{[seg]
 x1:`long$seg[`x1]+viewwidth%2;
 x2:`long$seg[`x2]+viewwidth%2;
 recur_solidsegs[(x1,x2)];
//  0N!"called clip_solid ",string[x], " ", string[y];
 h:select top:viewheight-`long$linedef.frontsector.ceilheight, bottom:viewheight-`long$linedef.frontsector.floorheight from seg;
//  sdl_render_draw_line[x;z;y;z];
 render_seg_loop[x1;x2;h`top;h`bottom];
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

/ Convert segs angle
segs:update angle:pi*?[angle>0;angle%32767;1+angle%-32768] from segs;

/ Add sector reference into ssectors table
/ See p_setup.c:P_GroupLines()
map_ssectors:{seg:segs[x`firstline]; sidedefs[seg`sidedef]`sector}
ssectors:`id xkey flip (flip 0!ssectors),enlist[`sector]!enlist map_ssectors each 0!ssectors;

reset_solidsegs:{
  solidsegs::((-0W; -1);(viewwidth; 0W))
 }

update_segs:{
 / Add angle to segs
 / rw_normalangle: 90 + the seg angle
 / distangle: the sine angle that determines distance to seg v1
 / rw_centerangle: angle at which center of seg meets the viewplane
 segs::update span:a1-a2 from update
  rw_normalangle:angle + ang90,
  a1:atan each (v1.y-viewy) % (v1.x-viewx),
  a2:atan each (v2.y-viewy) % (v2.x-viewx) from segs;
 segs::update
  rw_centerangle:ang90+viewangle-rw_normalangle,
  distangle:ang90 - min[(ang90;abs[rw_normalangle - a1])],
  hyp:(v1.x-viewx)%cos[a1] from segs;
 segs::update
  rw_offset:sidedef.xoffset+offset+hyp*sin[rw_normalangle - a1],
  rw_distance:hyp*sin[distangle] from segs;
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
 move:0b;
 if[0=e;::];
 if[1=e;viewy+:forwardmove[0]*sin(viewangle);viewx+:forwardmove[0]*cos(viewangle);move:1b];
 if[2=e;viewangle::(viewangle+rot) mod twopi;move:1b];
 if[3=e;viewy-:forwardmove[0]*sin(viewangle);viewx-:forwardmove[0]*cos(viewangle);move:1b];
 if[4=e;viewangle::(viewangle-rot) mod twopi;move:1b];
 if[move=0b;:0b];
 update_segs[];
 update_nodes[];
 reset_solidsegs[];
 render_frame[-1+count[nodes]]
 }

\c 40 160

render_loop:{while[1;render_loop_[]]}